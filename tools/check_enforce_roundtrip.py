#!/usr/bin/env python3
"""Regression gate for the v7.38 enforcement write-back.

THE DEFECT. fn_enforce_cvar used to push a correction to the client as
`client_cmd(id, "%s %.3f", name, bound)`. AMXX's formatter (amxmodx/format.cpp,
AddFloat) TRUNCATES each digit -- `val = (int)(fval / tmp)` with no rounding --
so a bound whose float32 sits just under its decimal value loses its last
digit: 0.01f is 0.0099999998 and went out as "0.009"; 0.009f is 0.0089999996
and went out as "0.008". The client re-reported the truncated string, it
failed the same bound it had just been corrected to, and after
MAX_ENFORCE_ATTEMPTS the player was announced fleet-wide as blocking
enforcement. 100 of 285 FILTERSTUFF_BLOCKED lines on the fleet named ex_interp.

It is also FPU-dependent. KTPAMXX is built -m32 with no -mfpmath=sse, so the
formatter runs on x87 with 64-bit intermediates, and there `tmp *= 0.1`
accumulates differently: 0.5 prints as "0.499" and 89 as "88.999" -- values
that are EXACT in float32 and print correctly under SSE. A core rebuild is
enough to move a bound from "safe" to "loops", which is why this gate models
both.

THE FIX. The write-back is the bound's own table string, verbatim. Identical
strings parse to identical floats, so the bare compare is exact at any
magnitude and no tolerance is needed anywhere. That makes the round trip an
identity, and this gate's job is to keep it one.

  Part 1 reads the SHIPPED SOURCE: every client_cmd in fn_enforce_cvar sends a
  string drawn from gs_calvalues[] / gs_altvalues[] / inverse_p, the function
  has no float to format except the player's own value, and the ceiling flag
  reaches it from fn_checkaltallowed.

  Part 2 runs EVERY bound in both tables through the round trip under the
  mechanism Part 1 found in the source, on both FPU models, and asserts each
  reparses to satisfy its own bound. The formatter model is pinned to three
  measured outputs first (0.01 -> "0.009", 0.5 -> "0.500" on SSE and "0.499"
  on x87) so a model that cannot reproduce production cannot vouch for it.
  It prints the full table either way, so the answer to "which bounds loop
  today" is one CI log away.

Mutation: revert the write-back to `%.3f` and Part 1 fails on the format, and
Part 2 fails on every bound whose float32 rounds down. Both, independently.

    python3 tools/check_enforce_roundtrip.py [--sma ktp_cvar.sma]

Exits 0 when every check passes, 1 otherwise.
"""
from __future__ import annotations

import argparse
import math
import os
import re
import struct
import sys
from fractions import Fraction

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_interp_pairing import body_of, strip_comments  # noqa: E402

failures: list[str] = []
checks_run = 0


def check(ok: bool, label: str, detail: str = "") -> None:
    global checks_run
    checks_run += 1
    if not ok:
        failures.append(f"{label}{': ' + detail if detail else ''}")


# ===========================================================================
# Formatter model
# ===========================================================================

def f32(s: str) -> float:
    """AMXX floatstr(): (float)atof(s). struct does the same two-step rounding."""
    return struct.unpack("f", struct.pack("f", float(s)))[0]


def rnd(x: Fraction, bits: int) -> Fraction:
    """Nearest value with a `bits`-bit significand, ties to even."""
    if x == 0:
        return x
    sign = -1 if x < 0 else 1
    x = abs(x)
    e = math.floor(math.log2(x.numerator) - math.log2(x.denominator))
    while Fraction(2) ** e > x:
        e -= 1
    while Fraction(2) ** (e + 1) <= x:
        e += 1
    scale = Fraction(2) ** (e - (bits - 1))
    q = x / scale
    n = q.numerator // q.denominator
    rem = q - n
    if rem > Fraction(1, 2) or (rem == Fraction(1, 2) and n % 2 == 1):
        n += 1
    return sign * n * scale


def add_float(fval: float, prec: int, bits: int) -> str:
    """Transcription of AddFloat (amxmodx/format.cpp) for a non-negative value.

    `bits` is the significand width every intermediate is rounded to: 53 for
    SSE/x86-64 doubles, 64 for the x87 extended registers an -m32 build keeps
    values in. Validated against a C build of the real function in both modes.
    """
    F = lambda v: rnd(Fraction(v), bits)  # noqa: E731
    fv = F(fval)
    out: list[str] = []
    digits = int(math.log10(fval)) + 1 if fval > 0 else 1
    if digits < 1:
        digits = 1
    tmp = F(Fraction(10) ** (digits - 1))
    sig = 0
    while digits > 0:
        digits -= 1
        sig += 1
        if sig > 16:
            out.append("0")
        else:
            val = int(F(fv / tmp))
            out.append(str(val))
            fv = F(fv - F(val * tmp))
            tmp = F(tmp * Fraction(0.1))
    if prec:
        out.append(".")
    tmp = F(Fraction(10) ** prec)
    fv = F(fv * tmp)
    p = prec
    while p > 0:
        p -= 1
        sig += 1
        if sig > 16:
            out.append("0")
        else:
            tmp = F(tmp * Fraction(0.1))
            val = int(F(fv / tmp))
            out.append(str(val))
            fv = F(fv - F(val * tmp))
    return "".join(out)


FPU = {"double": 53, "x87": 64}


def model_controls() -> None:
    """Pin the model to what production actually printed. If these fail,
    nothing in the table below can be trusted."""
    check(add_float(f32("0.01"), 3, 53) == "0.009" and add_float(f32("0.01"), 3, 64) == "0.009",
          "CONTROL formatter model", "0.01 must print as 0.009 on both FPU models")
    check(add_float(f32("0.009"), 3, 53) == "0.008",
          "CONTROL formatter model", "0.009 must print as 0.008 (the post-7.22 loop)")
    check(add_float(f32("0.5"), 3, 53) == "0.500",
          "CONTROL formatter model (SSE)", "0.5 must print as 0.500 under 53-bit intermediates")
    check(add_float(f32("0.5"), 3, 64) == "0.499",
          "CONTROL formatter model (x87)", "0.5 must print as 0.499 under 64-bit intermediates")
    # A value the truncation cannot touch, so the model is not simply "subtract one".
    check(add_float(f32("0.8"), 3, 64) == "0.800",
          "CONTROL formatter model", "0.8 (float32 rounds UP) must survive")


# ===========================================================================
# Source
# ===========================================================================

def table(src: str, name: str) -> list[str]:
    m = re.search(name + r"\s*\[[^\]]*\]\s*\[\s*\]\s*=\s*\{(.*?)\}", src, re.S)
    if not m:
        raise SystemExit(f"FAIL: could not find {name}[] -- this gate is blind")
    return re.findall(r'"([^"]*)"', re.sub(r"//[^\n]*", "", m.group(1)))


def define(src: str, name: str) -> str:
    m = re.search(r"#define\s+" + name + r"\s+(\S+)", src)
    if not m:
        raise SystemExit(f"FAIL: #define {name} not found -- this gate is blind")
    return m.group(1)


FMT_SPEC = re.compile(r"%[-+ 0#]*\d*(?:\.(\d+))?([a-zA-Z])")


def writeback_mechanism(enforce: str) -> dict:
    """What fn_enforce_cvar sends. {'s', 'd', 'f'} plus the float precision."""
    calls = re.findall(r'client_cmd\s*\(\s*id\s*,\s*"([^"]*)"\s*,([^\n]*)\)', enforce)
    check(len(calls) > 0, "CONTROL fn_enforce_cvar",
          "no client_cmd(id, \"...\", ...) found -- the extractor is blind")
    mech: dict = {"convs": set(), "float_prec": None, "string_args": []}
    for fmt, args in calls:
        specs = FMT_SPEC.findall(fmt)
        check(len(specs) == 2 and specs[0][1] == "s", "write-back shape",
              f'expected "%s <value>" in client_cmd format "{fmt}"')
        if len(specs) < 2:
            continue
        prec, conv = specs[1]
        mech["convs"].add(conv)
        if conv == "f":
            mech["float_prec"] = int(prec) if prec else 6
        elif conv == "s":
            mech["string_args"].append(args.split(",")[-1].strip())
    return mech


def part1(src: str) -> dict:
    enforce = body_of(src, "fn_enforce_cvar", required=True)
    mech = writeback_mechanism(enforce)

    check("s" in mech["convs"], "write-back is a string",
          "no client_cmd in fn_enforce_cvar sends a %s value")
    check("f" not in mech["convs"] and "d" not in mech["convs"],
          "write-back formats a number",
          f"client_cmd conversions {sorted(mech['convs'])} -- a formatted float "
          "is the v7.38 defect; a formatted int is the same bug one core rebuild away")

    # The string must come from the tables, never be built. `required` is the
    # local that carries it; all three sources must feed it.
    for arg in mech["string_args"]:
        check(arg == "required", "write-back source", f"client_cmd sends `{arg}`, not `required`")
    for source in ("gs_calvalues[cvar_index]",
                   "gs_altvalues[cvar_index - MIN_MAX_CVAR_START]",
                   "inverse_p"):
        check(re.search(r"copy\(\s*required\s*,\s*charsmax\(required\)\s*,\s*"
                        + re.escape(source) + r"\s*\)", enforce) is not None,
              "required[] sources", f"`required` is never copied from {source}")

    # Structural: with the player's value as the ONLY Float in scope, no format
    # string in this function can render a bound as a float, whatever it says.
    sig = re.search(r"^stock\s+fn_enforce_cvar\s*\(([^)]*)\)", src, re.M)
    floats = re.findall(r"Float\s*:\s*(\w+)", sig.group(1)) if sig else []
    check(floats == ["valueFromPlayer"], "fn_enforce_cvar signature",
          f"Float parameters are {floats}; only the player's value may be a float here")
    check("calFloatValue" not in enforce, "fn_enforce_cvar",
          "calFloatValue is back in fn_enforce_cvar")
    check("valueFromPlayer" in enforce, "CONTROL identifier probe",
          "valueFromPlayer not found in fn_enforce_cvar -- the negative check above is blind")

    # The ceiling flag: fn_checkaltallowed's two branches must disagree.
    alt = body_of(src, "fn_checkaltallowed", required=True)
    check(re.search(r"<\s*calFloatValue\s*\)\s*\{[^}]*defer_enforcement\([^)]*,\s*false\s*\)", alt)
          is not None, "floor branch", "fn_checkaltallowed's `< floor` branch does not defer with ceiling=false")
    check(re.search(r">\s*altFloatValue\s*\)\s*\{[^}]*defer_enforcement\([^)]*,\s*true\s*\)", alt)
          is not None, "ceiling branch", "fn_checkaltallowed's `> ceiling` branch does not defer with ceiling=true")
    exact = body_of(src, "fn_checkvalues", required=True)
    check(re.search(r"defer_enforcement\([^)]*,\s*false\s*\)", exact) is not None,
          "exact branch", "fn_checkvalues does not defer with ceiling=false")
    # ... and the flag must actually reach the write-back, not just be stored.
    task = body_of(src, "task_deferred_enforce", required=True)
    check("g_deferCeiling" in task and re.search(r"fn_enforce_cvar\([^)]*ceiling\s*\)", task) is not None,
          "ceiling flag plumbing", "task_deferred_enforce does not pass the ceiling bit to fn_enforce_cvar")

    # Player-facing copies: the Discord buffer stores the string, and the log
    # template renders it as one. A %f here re-truncates what the write-back fixed.
    check(re.search(r"^new\s+g_discordCvarCorrected\s*\[", src, re.M) is not None,
          "Discord buffer", "g_discordCvarCorrected is not a string array")
    lang = os.path.join(os.path.dirname(os.path.abspath(ARGS.sma)), "data", "lang", "ktp_cvar.txt")
    try:
        entry = re.search(r"^FCOS_LANG_LOG_ENTRY\s*=\s*(.*)$", open(lang, encoding="utf-8").read(), re.M)
        check(entry is not None and entry.group(1).rstrip().endswith('"%s".'),
              "lang FCOS_LANG_LOG_ENTRY", "the KTP-value placeholder must be %s, not %f")
    except OSError as e:
        check(False, "lang file", f"{lang}: {e}")
    return mech


# ===========================================================================
# Round trip
# ===========================================================================

def emit(bound: str, mech: dict, bits: int, pitch: bool = False) -> str:
    """What the write-back sends for `bound` under `mech` on one FPU model."""
    # Pre-7.38 already sent m_pitch as a string (the one cvar somebody had
    # fixed by hand); model that so the table describes what actually shipped.
    pitch_string = any("M_PITCH" in a or a == "inverse_p" for a in mech["string_args"])
    if pitch and pitch_string:
        return bound
    if "f" in mech["convs"] or "d" in mech["convs"]:
        v = f32(bound)
        # The pre-7.38 shape: %d at and above 100, %.Nf below.
        if "d" in mech["convs"] and v >= 100.0:
            return str(math.floor(v))
        return add_float(abs(v), mech["float_prec"] or 6, bits)
    return bound


def satisfies(kind: str, emitted: str, bound: str, eps: float) -> bool:
    v, b = f32(emitted), f32(bound)
    if kind == "exact":
        diff = f32(repr(abs(v - b)))
        return diff <= eps or emitted == bound
    if kind == "floor":
        return not (v < b)
    return not (v > b)  # ceiling


def classify(kind: str, bound: str, ok_double: bool, ok_x87: bool, mech: dict,
             pitch: bool = False) -> str:
    if ok_double and ok_x87:
        if "f" not in mech["convs"] and "d" not in mech["convs"]:
            return "safe by construction (string, identity)"
        if pitch:
            return "safe by construction (string, identity -- the pre-7.38 m_pitch special case)"
        v = f32(bound)
        if "d" in mech["convs"] and v >= 100.0:
            return "safe by construction (integer write-back)"
        if Fraction(v) == Fraction(bound):
            return "safe by construction (exact in float32)"
        if kind == "ceiling":
            return "safe by construction (truncation never exceeds a ceiling)"
        return "safe by luck (float32 rounds up)"
    if ok_double and not ok_x87:
        return "LOOPS on x87 (the fleet core)"
    return "LOOPS"


def part2(src: str, mech: dict) -> None:
    names, cal = table(src, "gs_cvars"), table(src, "gs_calvalues")
    alt = table(src, "gs_altvalues")
    start = int(define(src, "MIN_MAX_CVAR_START"))
    check(len(names) == len(cal), "table lengths", f"gs_cvars {len(names)} vs gs_calvalues {len(cal)}")
    check(len(alt) == len(names) - start, "table lengths",
          f"gs_altvalues {len(alt)} vs range cvars {len(names) - start}")
    eps_m = re.search(r"FLOAT_PRECISION\s*=\s*([0-9.eE+-]+)", src)
    check(eps_m is not None, "FLOAT_PRECISION", "not found")
    eps = f32(eps_m.group(1)) if eps_m else 0.0
    pitch_i = int(define(src, "M_PITCH_INDEX"))
    inv = re.search(r'inverse_p\[\]\s*=\s*"([^"]+)"', src)
    check(inv is not None, "inverse_p", "not found")

    rows: list[tuple] = []
    for i, name in enumerate(names):
        rows.append((name, "floor" if i >= start else "exact", cal[i]))
        if i >= start:
            rows.append((name, "ceiling", alt[i - start]))
        if i == pitch_i and inv:
            rows.append((name, "exact", inv.group(1)))

    print(f"{'cvar':18} {'bound':8} {'string':>8} {'float32':>14} {'emit/double':>12} "
          f"{'emit/x87':>10} {'reparse':>10}  verdict")
    for name, kind, bound in rows:
        out, ok = {}, {}
        for fpu, bits in FPU.items():
            out[fpu] = emit(bound.lstrip("-"), mech, bits, pitch=(name == names[pitch_i]))
            if bound.startswith("-"):
                out[fpu] = "-" + out[fpu]
            ok[fpu] = satisfies(kind, out[fpu], bound, eps)
        verdict = classify(kind, bound, ok["double"], ok["x87"], mech,
                           pitch=(name == names[pitch_i]))
        print(f"{name:18} {kind:8} {bound:>8} {f32(bound):>14.10g} {out['double']:>12} "
              f"{out['x87']:>10} {f32(out['x87']):>10.6g}  {verdict}")
        check(ok["double"] and ok["x87"], f"round trip {name} {kind} {bound}",
              f"write-back emits {out} -- reparses outside its own bound")
        # A bound needing more than 3 decimals would be a second, separate
        # defect under any fixed-precision formatter. Report it if it ever appears.
        dec = bound.split(".")[1] if "." in bound else ""
        check(len(dec) <= 3, f"precision {name} {bound}",
              "more than 3 decimals -- unreachable by the old %.3f, and worth knowing")


def main() -> int:
    global ARGS
    ap = argparse.ArgumentParser()
    ap.add_argument("--sma", default="ktp_cvar.sma")
    ARGS = ap.parse_args()
    src = open(ARGS.sma, encoding="utf-8", errors="replace").read()

    model_controls()
    mech = part1(src)
    part2(src, mech)

    if failures:
        print(f"\nMISMATCH -- {len(failures)} of {checks_run} checks failed:\n")
        for f in failures:
            print(f"  {f}")
        return 1
    print(f"\nOK -- {checks_run} checks passed (write-back conversions: "
          f"{sorted(mech['convs'])}, read from {ARGS.sma}).")
    return 0


ARGS = None

if __name__ == "__main__":
    sys.exit(main())
