#!/usr/bin/env python3
"""Regression gate for the v7.37 ex_interp pairing fixes.

WHAT THIS IS, AND WHAT IT IS NOT. This repo has no Pawn test harness -- there
is no way to execute `fn_netobs_eval_interp` outside a running AMXX server, and
building an .amxx to try is forbidden (a build churns an md5 pinned to a
review). So this gate does the two things that ARE possible without a runtime:

  Part 1 reads the SHIPPED SOURCE and asserts the fixes are present. This is
  real coverage: revert any one of them and this fails.

  Part 2 pins the ARITHMETIC the fix is supposed to implement, against a
  transcription of ReHLDS's SV_CheckUpdateRate. A transcription cannot prove
  the Pawn agrees with it -- Part 1 is what ties the Pawn to the intent, by
  requiring it to call the clamping helper rather than open-code a divide.
  Constants that both halves depend on (INTERP_EPSILON) are READ FROM THE .sma
  rather than retyped here, so at least those cannot drift apart silently.

Every source assertion carries a positive control, because a regex that stops
matching reports "clean" in exactly the same way as a codebase that is clean.

    python3 tools/check_interp_pairing.py [--sma ktp_cvar.sma]

Exits 0 when every check passes, 1 otherwise.
"""
from __future__ import annotations

import argparse
import re
import sys

# ---------------------------------------------------------------------------
# ReHLDS reference, rehlds/engine/sv_main.cpp. Quoted so a reader can audit the
# transcription in Part 2 without leaving this file.
#
#   SV_ExtractFromUserinfo:            SV_CheckUpdateRate(double *rate):
#     i = atoi(cl_updaterate)            if (*rate == 0.0) { *rate = 0.05; return; }
#     if (i >= 10)                       if (max <= 0.001f && max != 0.0f) max = 30.0
#         next_messageinterval = 1.0/i   if (min <= 0.001f && min != 0.0f) min = 1.0
#     else                               if (max != 0.0f && *rate < 1.0/max) *rate = 1.0/max
#         next_messageinterval = 0.1     if (min != 0.0f && *rate > 1.0/min) *rate = 1.0/min
#     ... SV_CheckUpdateRate(&next_messageinterval)
# ---------------------------------------------------------------------------

UPDATERATE_FLOOR_INTERVAL = 0.1   # engine's sub-10 cl_updaterate floor
SANITIZED_MAX = 30.0              # nonzero-but-tiny sv_maxupdaterate is repaired to this
SANITIZED_MIN = 1.0               # ... and sv_minupdaterate to this

failures: list[str] = []
checks_run = 0


def check(ok: bool, label: str, detail: str = "") -> None:
    global checks_run
    checks_run += 1
    if not ok:
        failures.append(f"{label}{': ' + detail if detail else ''}")


def body_of(src: str, fn: str, required: bool = False) -> str:
    """Source text of one `stock`/`public` function, brace-matched.

    Returns "" when the function is absent. Absence is a normal REGRESSION
    result (someone reverted the fix), not a broken parser — conflating the two
    sends a reader to debug the wrong thing. Only the control functions, which
    predate this gate and must always exist, pass required=True; those really
    do mean the extractor is broken.
    """
    m = re.search(r"^(?:stock|public)[^\n(]*\b" + re.escape(fn) + r"\s*\(", src, re.M)
    if not m:
        if required:
            raise SystemExit(f"FAIL: control function {fn}() not found — this "
                             "gate is blind. Fix the parser.")
        return ""
    i = src.index("{", m.end())
    depth = 0
    for j in range(i, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                return src[i:j + 1]
    raise SystemExit(f"FAIL: unbalanced braces in {fn}()")


# ===========================================================================
# Part 1 — the shipped source carries the fixes
# ===========================================================================

def part1(src: str) -> float:
    # --- Positive control for body_of(): a function that has always existed,
    # with a line we know is in it. If this fails, every result below is void.
    control = body_of(src, "fn_netobs_log", required=True)
    check("log_amx(" in control, "CONTROL body_of()",
          "fn_netobs_log() does not contain log_amx( — the extractor is broken")

    # --- Fix 2: INTERP_EPSILON closes the sub-0.1ms blind band.
    m = re.search(r"#define\s+INTERP_EPSILON\s+([0-9.eE+-]+)", src)
    check(m is not None, "INTERP_EPSILON", "#define not found")
    eps = float(m.group(1)) if m else float("nan")
    check(eps <= 1e-6, "INTERP_EPSILON too coarse",
          f"{eps:g} > 1e-6 — leaves a blind band above float error (~1e-9 here)")
    check(eps > 0.0, "INTERP_EPSILON must stay positive",
          f"{eps:g} — 0 would make the comparison bare float equality")

    # --- Fix 1: the evaluator uses the effective interval, not the request.
    ev = body_of(src, "fn_netobs_eval_interp")
    check("fn_netobs_effective_interval(" in ev, "eval uses effective interval",
          "fn_netobs_eval_interp() no longer calls fn_netobs_effective_interval()")
    check(not re.search(r"need\s*=\s*1\.0\s*/\s*float\(", ev),
          "eval open-codes the requested interval",
          "`need = 1.0 / float(updaterate)` is back — that is the v7.35 defect")

    # --- Fix 1, continued: the helper models BOTH clamp bounds and the floor.
    eff = body_of(src, "fn_netobs_effective_interval")
    check(eff != "", "clamp helper missing",
          "fn_netobs_effective_interval() is not in the source — the v7.37 fix "
          "has been reverted (this is a regression, not a parser fault)")
    check("sv_maxupdaterate" in eff, "clamp helper", "does not read sv_maxupdaterate")
    check("sv_minupdaterate" in eff, "clamp helper", "does not read sv_minupdaterate")
    check(re.search(r"updaterate\s*>=\s*10", eff) is not None,
          "clamp helper", "missing the engine's sub-10 floor (i >= 10)")
    check(str(UPDATERATE_FLOOR_INTERVAL) in eff, "clamp helper",
          f"missing the {UPDATERATE_FLOOR_INTERVAL}s floor interval")
    # A zero bound means "this side does not clamp" — dropping the guard would
    # divide by zero on a server that disables one bound.
    check(eff.count("!= 0.0") >= 2, "clamp helper",
          "lost the `cvar != 0.0` guards — 1.0/0.0 on a server with a bound disabled")

    # --- Fix 3: bot/HLTV guard, matching fn_loopquery.
    guard = r"is_user_bot\(id\)\s*\|\|\s*is_user_hltv\(id\)"
    obs = body_of(src, "fn_netobs_query_observed")
    check(re.search(guard, obs) is not None, "fn_netobs_query_observed",
          "missing the bot/HLTV guard that fn_loopquery carries")
    # Positive control: the guard's spelling is the one fn_loopquery really uses.
    loop = body_of(src, "fn_loopquery", required=True)
    check(re.search(guard, loop) is not None, "CONTROL guard spelling",
          "fn_loopquery does not match the guard regex — the pattern is wrong, "
          "so the check above proves nothing")

    # --- Version lockstep. The version is written in THREE places and #9 exists
    # because two of them drifted. README is the third and had no check at all.
    mv = re.search(r'#define\s+PLUGIN_VERSION\s+"([^"]+)"', src)
    mh = re.search(r"Current Version:\s*([0-9.]+)", src)
    check(mv is not None and mh is not None, "version strings", "one is missing")
    if mv and mh:
        check(mv.group(1) == mh.group(1), "version drift",
              f'PLUGIN_VERSION "{mv.group(1)}" vs .sma header "{mh.group(1)}"')

    return eps


def check_readme(src: str, path: str = "README.md") -> None:
    """README's version banner is the third copy — keep it in lockstep too."""
    mv = re.search(r'#define\s+PLUGIN_VERSION\s+"([^"]+)"', src)
    if not mv:
        return
    try:
        readme = open(path, encoding="utf-8", errors="replace").read()
    except FileNotFoundError:
        return
    mr = re.search(r"\*\*Version\s+([0-9.]+)\*\*", readme)
    check(mr is not None, "README version banner",
          "no `**Version N.NN**` line found — the lockstep check is blind")
    if mr:
        check(mr.group(1) == mv.group(1), "version drift",
              f'README "{mr.group(1)}" vs PLUGIN_VERSION "{mv.group(1)}"')


# ===========================================================================
# Part 2 — the arithmetic the fix implements
# ===========================================================================

def effective_interval(updaterate: int, sv_max: float, sv_min: float) -> float:
    """Transcription of SV_ExtractFromUserinfo + SV_CheckUpdateRate."""
    interval = 1.0 / updaterate if updaterate >= 10 else UPDATERATE_FLOOR_INTERVAL
    if sv_max != 0.0 and sv_max <= 0.001:
        sv_max = SANITIZED_MAX
    if sv_min != 0.0 and sv_min <= 0.001:
        sv_min = SANITIZED_MIN
    if sv_max != 0.0:
        interval = max(interval, 1.0 / sv_max)
    if sv_min != 0.0:
        interval = min(interval, 1.0 / sv_min)
    return interval


def part2(eps: float) -> None:
    # Measured on the fleet 2026-08-30, not assumed: every dod-*/dodserver.cfg
    # on Atlanta carries these, with sv_password as a positive control that the
    # grep was reading the files at all. sv_minupdaterate is 90, NOT the engine
    # default 10 — which is why the down-clamp below is load-bearing here.
    KTP_MAX, KTP_MIN = 120.0, 90.0

    def low(ex_interp: float, updaterate: int,
            sv_max: float = KTP_MAX, sv_min: float = KTP_MIN) -> bool:
        return ex_interp < effective_interval(updaterate, sv_max, sv_min) - eps

    # (label, expected_low, args) — `expected_low` is what the check SHOULD say.
    cases = [
        # THE REGRESSION. v7.35 divided by the request: 1/200 = 0.005, and
        # 0.006 > 0.005, so a genuinely-starved client logged nothing. The
        # engine serves it every 1/120 = 0.00833.
        ("uncorrected client, updaterate 200 / ex_interp 0.006", True,
         (0.006, 200)),
        # ... and the same client is fine once ex_interp clears the real interval.
        ("updaterate 200 / ex_interp 0.010", False, (0.010, 200)),

        # The v7.35 headline case must keep working: both cvars in range, pair
        # is not. 1/100 = 0.01 sits inside the clamp, so nothing moves.
        ("in-band pair, updaterate 100 / ex_interp 0.009", True, (0.009, 100)),
        ("in-band pair, updaterate 100 / ex_interp 0.011", False, (0.011, 100)),

        # Exactly at the boundary is OK, not LOW — that is what the epsilon is for.
        ("ex_interp exactly one interval at the cap", False, (1.0 / 120.0, 120)),

        # THE EPSILON. 0.05ms under one interval. 1e-4 excused this; 1e-6 does not.
        ("0.05ms under one interval", True, (1.0 / 120.0 - 5e-5, 120)),

        # THE OTHER HALF OF THE FIX: the down-clamp kills FALSE POSITIVES.
        # A client at cl_updaterate 20 requests a 0.05s interval, but
        # sv_minupdaterate 90 means the engine never sends slower than 1/90 =
        # 0.0111. v7.35 compared against 0.05 and called ex_interp 0.02 LOW;
        # it is not low, it is nearly twice the interval actually served.
        ("updaterate 20 / ex_interp 0.02 — down-clamped, NOT low", False,
         (0.02, 20)),
        # Sub-10 request: engine floors to 0.1s, then the same down-clamp
        # brings it to 1/90. Still not low.
        ("updaterate 5 floors to 0.1s, then down-clamps to 1/90", False,
         (0.02, 5)),
        # ... but genuinely under the served interval is still caught.
        ("updaterate 5 / ex_interp 0.009 is still LOW", True, (0.009, 5)),

        # A server that disables the cap clamps nothing, so the effective
        # interval IS the requested one and 0.006 is legitimately fine.
        ("no cap (sv_maxupdaterate 0), updaterate 200 / ex_interp 0.006", False,
         (0.006, 200, 0.0, KTP_MIN)),

        # Nonzero-but-tiny cap is repaired to 30, not honoured as-is (a literal
        # reading would give 1/0.0005 = 2000s). sv_minupdaterate is disabled
        # here on purpose: at the fleet's 90 the down-clamp to 1/90 would
        # override the repaired cap and the case would prove nothing about it.
        ("sv_maxupdaterate 0.0005 is repaired to 30, not honoured literally",
         True, (0.02, 200, 0.0005, 0.0)),
    ]

    for label, expected, args in cases:
        got = low(*args)
        check(got == expected, f"case: {label}",
              f"expected {'LOW' if expected else 'OK'}, got "
              f"{'LOW' if got else 'OK'}")

    # Control: with the OLD epsilon the blind-band case flips to OK. If this
    # does not flip, the case is not actually exercising the epsilon and the
    # test above would pass for the wrong reason.
    old = 1e-4
    blind = 1.0 / 120.0 - 5e-5
    check(not (blind < effective_interval(120, KTP_MAX, KTP_MIN) - old),
          "CONTROL epsilon sensitivity",
          "the 0.05ms case does not depend on INTERP_EPSILON at all")

    # Control: the two headline cases must actually DISAGREE with the v7.35
    # formula, or this whole fix is a no-op and the cases prove nothing.
    def v735_low(ex_interp: float, updaterate: int) -> bool:
        return ex_interp < 1.0 / updaterate - eps

    check(v735_low(0.006, 200) is False and low(0.006, 200) is True,
          "CONTROL fix changes the verdict (missed detection)",
          "v7.35 and v7.37 agree on updaterate 200 / 0.006 — the fix is a no-op")
    check(v735_low(0.02, 20) is True and low(0.02, 20) is False,
          "CONTROL fix changes the verdict (false positive)",
          "v7.35 and v7.37 agree on updaterate 20 / 0.02 — the fix is a no-op")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sma", default="ktp_cvar.sma")
    args = ap.parse_args()

    src = open(args.sma, encoding="utf-8", errors="replace").read()

    eps = part1(src)
    check_readme(src)
    part2(eps)

    if failures:
        print(f"MISMATCH — {len(failures)} of {checks_run} checks failed:\n")
        for f in failures:
            print(f"  {f}")
        return 1

    print(f"OK — {checks_run} checks passed "
          f"(INTERP_EPSILON = {eps:g}, read from {args.sma}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
