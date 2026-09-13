#!/usr/bin/env python3
"""Controls for check_published_cvars.py that can fail.

The fixture pair in tools/fixtures/published_cvars/ is hand-written and depends
on neither ktp_cvar.sma nor the live doc. A test that built the doc side from
the source it compares against would pass by construction. This one starts from
two independent statements that agree, proves they pass, then breaks one thing
at a time and requires the check to name what broke.

    python3 tools/test_check_published_cvars.py

Exits 0 when every control behaves, 1 otherwise.
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from check_published_cvars import evaluate  # noqa: E402

FIX = os.path.join(HERE, "fixtures", "published_cvars")
SMA_PATH = os.path.join(FIX, "ktp_cvar.sma")
DOC_PATH = os.path.join(FIX, "cvar_list.md")
SMA = open(SMA_PATH, encoding="utf-8").read()
DOC = open(DOC_PATH, encoding="utf-8").read()

failures: list[str] = []
ran = 0


def once(text: str, old: str, new: str, label: str) -> str | None:
    """Apply a mutation that must match exactly once, or record the control as blind."""
    n = text.count(old)
    if n != 1:
        failures.append(f"{label}: fixture text {old!r} matched {n} times — the mutation is blind")
        return None
    return text.replace(old, new)


def expect_problem(label: str, sma: str | None, doc: str | None, needle: str) -> None:
    global ran
    ran += 1
    if sma is None or doc is None:
        return
    problems, _ = evaluate(sma, doc)
    if not any(needle in p for p in problems):
        failures.append(f"{label}: expected a problem containing {needle!r}, got {problems}")


def expect_clean(label: str, sma: str | None, doc: str | None) -> None:
    global ran
    ran += 1
    if sma is None or doc is None:
        return
    problems, _ = evaluate(sma, doc)
    if problems:
        failures.append(f"{label}: expected no problems, got {problems}")


def run_cli(doc_text: str) -> int:
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "doc.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write(doc_text)
        return subprocess.run(
            [sys.executable, os.path.join(HERE, "check_published_cvars.py"),
             "--sma", SMA_PATH, "--offline", path],
            capture_output=True, text=True).returncode


def main() -> int:
    global ran
    # The baseline. If this fails, every "expected a problem" below proves nothing.
    expect_clean("correct fixture pair", SMA, DOC)
    _, summary = evaluate(SMA, DOC)
    if "8 values compared" not in summary:
        failures.append(f"summary {summary!r}: not every fixture cvar reached the value compare")

    # Equal decimals spelled differently are not drift.
    expect_clean("3.0 respelled 3", SMA, once(DOC, "**3.0**", "**3**", "respell"))

    # --- The doc side is wrong --------------------------------------------------
    expect_problem("ex_interp floor 0.01 -> 0.009 (the incident this check exists for)",
                   SMA, once(DOC, "**0.01** - **0.05**", "**0.009** - **0.05**", "floor"),
                   "WRONG VALUE: ex_interp")
    expect_problem("range bounds published in reverse order",
                   SMA, once(DOC, "**0.01** - **0.05**", "**0.05** - **0.01**", "order"),
                   "WRONG VALUE: ex_interp")
    expect_problem("fixed value 0 -> 1",
                   SMA, once(DOC, "| `r_fullbright` | `0` |", "| `r_fullbright` | `1` |", "fixed"),
                   "WRONG VALUE: r_fullbright")
    expect_problem("locked range published with the wrong value",
                   SMA, once(DOC, "| `rate` | `100000` |", "| `rate` | `100001` |", "rate"),
                   "WRONG VALUE: rate")
    expect_problem("row removed",
                   SMA, once(DOC, "| `r_fullbright` | `0` | Maximum brightness in local games only |\n",
                             "", "remove"),
                   "ENFORCED BUT NOT PUBLISHED: r_fullbright")
    moved = once(DOC, "| `lightgamma` | **1.809** - **3.0** | 2.5 | Lighting gamma value |\n", "", "move")
    moved = moved and once(moved, "| `r_fullbright` | `0` |",
                           "| `lightgamma` | `1.809` | Lighting gamma |\n| `r_fullbright` | `0` |", "move")
    expect_problem("range cvar published as a fixed value", SMA, moved or None,
                   "WRONG TABLE: lightgamma")

    # --- Behaviour a numeric compare cannot see ---------------------------------
    expect_problem("m_pitch: inverted value dropped",
                   SMA, once(DOC, "`0.022` or `-0.022`", "`0.022`", "pitch value"),
                   "WRONG VALUE: m_pitch")
    expect_problem("m_pitch: inverted-pitch prose dropped",
                   SMA, once(DOC, " **Inverted-mouse players set `-0.022`**.", "", "pitch prose"),
                   "BEHAVIOUR NOT PUBLISHED: m_pitch")
    expect_problem("hud_takesshots: competitive-only prose dropped",
                   SMA, once(DOC, "Enforced in **competitive matches only** (`.ktp`, `.ktpOT`).",
                             "Screenshot at map end.", "hud prose"),
                   "BEHAVIOUR NOT PUBLISHED: hud_takesshots")

    # --- The source side changed ------------------------------------------------
    expect_problem("enforced floor changed without the doc",
                   once(SMA, '"0.01"', '"0.009"', "sma floor"), DOC, "WRONG VALUE: ex_interp")
    expect_problem("a new special-cased index nobody modelled",
                   once(SMA, "#define M_PITCH_INDEX 2\n", "#define M_PITCH_INDEX 2\n#define CL_BOB_INDEX 5\n",
                        "new index"), DOC, "UNMODELLED SPECIAL CASE: #define CL_BOB_INDEX")
    expect_problem("m_pitch stops accepting the negative",
                   once(SMA, "equal(s_VALUE, inverse_p) || ", "", "sma pitch"), DOC,
                   "STALE BEHAVIOUR: fn_checkvalues()")
    expect_problem("hud_takesshots stops reading the competitive flag",
                   once(SMA, 'get_cvar_pointer("ktp_match_competitive")', "0", "sma hud"), DOC,
                   "STALE BEHAVIOUR: fn_enforce_cvar()")
    expect_problem("M_PITCH_INDEX points at the wrong cvar",
                   once(SMA, "#define M_PITCH_INDEX 2", "#define M_PITCH_INDEX 3", "sma index"), DOC,
                   "STALE BEHAVIOUR: M_PITCH_INDEX 3")

    # --- A parser that matches nothing must not read as agreement ---------------
    expect_problem("doc with no tables", SMA, "# Nothing here\n", "parsed zero enforced cvars")

    # --- The exit code, since CI gates on it rather than on evaluate() ----------
    ran += 2
    if run_cli(DOC) != 0:
        failures.append("CLI exits non-zero on the correct fixture pair")
    bad = DOC.replace("**0.01** - **0.05**", "**0.009** - **0.05**")
    if bad == DOC or run_cli(bad) != 1:
        failures.append("CLI does not exit 1 on a mutated value")

    if failures:
        print(f"FAIL — {len(failures)} of {ran} controls did not behave:\n")
        for f in failures:
            print(f"  {f}")
        return 1
    print(f"OK — {ran} controls behave (correct pair passes, every mutation is named).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
