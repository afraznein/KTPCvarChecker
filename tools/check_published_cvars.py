#!/usr/bin/env python3
"""Fail if the published CVAR list and the enforced one disagree -- by name AND value.

The plugin enforces `gs_cvars[]` against `gs_calvalues[]` / `gs_altvalues[]`.
Players read the markdown in afraznein/KTP_Documentation. Nothing else connects
the two, so every enforcement change relies on somebody remembering to edit the
doc as well -- and a player corrected for a value the page never mentioned has
no way to find out why.

NAMES, in both directions. A cvar the plugin enforces but the doc omits is a
player who cannot comply; a cvar the doc demands but the plugin ignores is a
promise nobody keeps.

VALUES, as exact decimals ("3.0" equals "3"). An exact-value cvar must sit in a
fixed-value table with its one value; a range cvar in the range table with both
bounds in order -- or, when its floor equals its ceiling (`rate`), as a fixed
value. Names alone stayed green while the page published `ex_interp 0.009-0.05`
against an enforced floor of 0.01.

BEHAVIOUR a number cannot express is listed in BEHAVIOURS. Each entry must still
be special-cased in the source, so it cannot outlive the code, and its published
row must say it in words. A `#define *_INDEX` special case with no entry fails
the check instead of being skipped.

Not compared: the Quick Reference block and the Default column. They are
recommendations, not enforced bounds.

Exits 1 on any mismatch, 0 when they agree.

    python3 tools/check_published_cvars.py [--sma ktp_cvar.sma] [--offline FILE]
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import urllib.request
from dataclasses import dataclass
from fractions import Fraction

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_interp_pairing import body_of  # noqa: E402

DOC_URL = (
    "https://raw.githubusercontent.com/afraznein/KTP_Documentation/main/"
    "KTP%20Cvar%20List.md"
)

# The doc publishes these for players to tune themselves. They are deliberately
# NOT enforced, so their absence from the plugin is correct rather than drift --
# the one asymmetry this check must not flag.
PLAYER_TUNABLE_HEADING = re.compile(r"player[- ]tunable|adjustable|optional", re.I)
RANGE_HEADING = re.compile(r"\brange", re.I)


@dataclass(frozen=True)
class Behaviour:
    cvar: str
    function: str                 # the function that special-cases it
    tokens: tuple[str, ...]       # identifiers that must still appear in that function
    prose: tuple[str, ...]        # patterns the published row must match
    also_accepted: str | None     # a string constant accepted as a second value
    says: str


BEHAVIOURS = {
    "M_PITCH_INDEX": Behaviour(
        cvar="m_pitch",
        function="fn_checkvalues",
        tokens=("M_PITCH_INDEX", "inverse_p"),
        prose=(r"invert",),
        also_accepted="inverse_p",
        says="accepted at either sign, so the row must list both values and say inverted pitch is allowed",
    ),
    "HUD_TAKESSHOTS_INDEX": Behaviour(
        cvar="hud_takesshots",
        function="fn_enforce_cvar",
        tokens=("HUD_TAKESSHOTS_INDEX", "ktp_match_competitive"),
        prose=(r"competitive", r"\.ktp\b"),
        also_accepted=None,
        says="enforced only in competitive matches, so the row must say so and name the modes",
    ),
}


@dataclass(frozen=True)
class Row:
    name: str
    kind: str           # "fixed" | "range" | "tunable"
    values: tuple[str, ...]
    line: str


def table(src: str, name: str) -> list[str]:
    m = re.search(r"\b" + name + r"\s*\[[^\]]*\]\s*\[\s*\]\s*=\s*\{(.*?)\}", src, re.S)
    if not m:
        raise SystemExit(f"could not find {name}[] in the source")
    return re.findall(r'"([^"]*)"', re.sub(r"//[^\n]*", "", m.group(1)))


def parse_sma(src: str) -> dict[str, tuple[str, ...]]:
    """cvar -> (value,) for an exact cvar, (floor, ceiling) for a range cvar."""
    names, cal, alt = table(src, "gs_cvars"), table(src, "gs_calvalues"), table(src, "gs_altvalues")
    m = re.search(r"^#define\s+MIN_MAX_CVAR_START\s+(\d+)\b", src, re.M)
    if not m:
        raise SystemExit("could not find #define MIN_MAX_CVAR_START")
    start = int(m.group(1))
    if len(names) != len(cal):
        raise SystemExit(
            f"gs_cvars[] has {len(names)} entries but gs_calvalues[] has "
            f"{len(cal)} — the arrays are positional, so this is a real bug"
        )
    if len(alt) != len(names) - start:
        raise SystemExit(
            f"gs_altvalues[] has {len(alt)} entries for {len(names) - start} range cvars "
            f"(MIN_MAX_CVAR_START {start}) — ceilings would pair with the wrong cvar"
        )
    return {n: (cal[i],) if i < start else (cal[i], alt[i - start]) for i, n in enumerate(names)}


def parse_doc(markdown: str) -> list[Row]:
    rows: list[Row] = []
    kind = "fixed"
    for line in markdown.splitlines():
        if line.startswith("#"):
            if PLAYER_TUNABLE_HEADING.search(line):
                kind = "tunable"
            elif RANGE_HEADING.search(line):
                kind = "range"
            else:
                kind = "fixed"
            continue
        # | `cl_bob` | **0** - **0.01** | 0.005 | description |      (range)
        # | `m_pitch` | `0.022` or `-0.022` | description |          (fixed)
        m = re.match(r"\s*\|\s*`([a-z_][a-z0-9_]*)`\s*\|([^|]*)\|", line, re.I)
        if not m:
            continue
        cell = m.group(2)
        found = re.findall(r"\*\*([^*]+)\*\*", cell) if kind == "range" else re.findall(r"`([^`]*)`", cell)
        rows.append(Row(m.group(1), kind, tuple(v.strip() for v in found), line))
    return rows


def as_numbers(values) -> list[Fraction] | None:
    try:
        return [Fraction(v) for v in values]
    except (ValueError, ZeroDivisionError):
        return None


def evaluate(src: str, markdown: str) -> tuple[list[str], str]:
    """(problems, summary). No problems means the page and the source agree."""
    rules = parse_sma(src)
    names = table(src, "gs_cvars")
    rows = parse_doc(markdown)

    problems: list[str] = []
    enforced: dict[str, Row] = {}
    tunable: set[str] = set()
    for row in rows:
        if row.kind == "tunable":
            tunable.add(row.name)
            continue
        if row.name in enforced:
            problems.append(f"PUBLISHED TWICE: {row.name} has more than one enforced row")
        enforced[row.name] = row

    if not enforced:
        return (["parsed zero enforced cvars from the published doc — the table format "
                 "changed and this check is now blind. Fix the parser."], "")

    for c in sorted(set(rules) - set(enforced) - tunable):
        problems.append(f"ENFORCED BUT NOT PUBLISHED: {c} = {' - '.join(rules[c])} — players cannot comply")
    for c in sorted(set(enforced) - set(rules)):
        problems.append(f"PUBLISHED BUT NOT ENFORCED: {c} — the doc promises what nothing checks")
    for c in sorted(set(enforced) & tunable):
        problems.append(f"LISTED AS BOTH ENFORCED AND PLAYER-TUNABLE: {c}")

    # Behaviour: the source must still do it, and the page must still say it.
    indices = {m.group(1): int(m.group(2))
               for m in re.finditer(r"^#define\s+(\w+_INDEX)\s+(\d+)\b", src, re.M)}
    for d in sorted(set(indices) - set(BEHAVIOURS)):
        problems.append(f"UNMODELLED SPECIAL CASE: #define {d} marks a cvar the source treats "
                        "differently. Add a BEHAVIOURS entry naming what the page must say")
    accepted: dict[str, str] = {}
    for d, b in BEHAVIOURS.items():
        if d not in indices:
            problems.append(f"STALE BEHAVIOUR: #define {d} is gone — drop or rework the {b.cvar} entry")
            continue
        i = indices[d]
        if not (0 <= i < len(names)) or names[i] != b.cvar:
            got = names[i] if 0 <= i < len(names) else "<out of range>"
            problems.append(f"STALE BEHAVIOUR: {d} {i} names {got!r}, not {b.cvar!r}")
        body = body_of(src, b.function)
        gone = [t for t in b.tokens if t not in body]
        if gone:
            problems.append(f"STALE BEHAVIOUR: {b.function}() no longer mentions {gone} — "
                            f"{b.cvar} may not be special-cased any more")
        if b.also_accepted:
            m = re.search(r"\b" + b.also_accepted + r'\s*\[\s*\]\s*=\s*"([^"]*)"', src)
            if m:
                accepted[b.cvar] = m.group(1)
            else:
                problems.append(f"STALE BEHAVIOUR: {b.also_accepted} not found — "
                                f"{b.cvar}'s second value is unknown")
        row = enforced.get(b.cvar)
        if row:
            for pattern in b.prose:
                if not re.search(pattern, row.line, re.I):
                    problems.append(f"BEHAVIOUR NOT PUBLISHED: {b.cvar} is {b.says}; "
                                    f"its row does not match /{pattern}/")

    compared = 0
    for name, rule in rules.items():
        row = enforced.get(name)
        if row is None:
            continue
        compared += 1
        if len(rule) == 1:
            want_kind, want = "fixed", [rule[0]] + ([accepted[name]] if name in accepted else [])
        elif row.kind == "fixed" and as_numbers(rule) and len(set(as_numbers(rule))) == 1:
            want_kind, want = "fixed", [rule[0]]
        else:
            want_kind, want = "range", list(rule)

        if row.kind != want_kind:
            shape = "exact value" if len(rule) == 1 else "range"
            problems.append(f"WRONG TABLE: {name} is enforced as a {shape} ({' - '.join(rule)}) "
                            f"but published in the {row.kind}-value table")
            continue
        got_n, want_n = as_numbers(row.values), as_numbers(want)
        if got_n is None or want_n is None or not row.values:
            problems.append(f"UNREADABLE VALUE: {name} published {list(row.values)}, "
                            f"enforced {want}")
            continue
        # Alternatives are a set; a range is ordered, floor first.
        same = got_n == want_n if want_kind == "range" else sorted(got_n) == sorted(want_n)
        if not same:
            sep = " - " if want_kind == "range" else " or "
            problems.append(f"WRONG VALUE: {name} published {sep.join(row.values)}, "
                            f"ktp_cvar.sma enforces {sep.join(want)}")

    # Positive control: a cvar we know is enforced must be found in the doc.
    # Without this, a parser that silently matches nothing reports success.
    canary = "cl_updaterate"
    if canary in rules and canary not in (set(enforced) | tunable):
        problems.append(f"CONTROL: {canary} is enforced but absent from the doc — "
                        "either real drift or the doc parser is broken")

    summary = (f"plugin enforces {len(rules)} cvars; doc publishes {len(enforced)} enforced + "
               f"{len(tunable)} tunable; {compared} values compared, "
               f"{len(BEHAVIOURS)} behaviours checked")
    return problems, summary


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sma", default="ktp_cvar.sma")
    ap.add_argument("--offline", help="read the doc from a file instead of GitHub")
    args = ap.parse_args(argv)

    src = open(args.sma, encoding="utf-8", errors="replace").read()
    if args.offline:
        markdown = open(args.offline, encoding="utf-8").read()
    else:
        with urllib.request.urlopen(DOC_URL, timeout=20) as r:
            markdown = r.read().decode("utf-8")

    problems, summary = evaluate(src, markdown)
    if summary:
        print(summary)
    for p in problems:
        print(f"  {p}")
    print("\nOK — published and enforced lists agree, by name and value." if not problems
          else "\nMISMATCH")
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
