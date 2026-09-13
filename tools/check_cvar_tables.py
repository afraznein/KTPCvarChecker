#!/usr/bin/env python3
"""Positional-table invariants for ktp_cvar.sma.

gs_cvars[], gs_calvalues[] and gs_altvalues[] are parallel arrays, and several
#defines are positions inside them. Pawn ties none of it together: drop one
entry from one table and every later cvar is validated against its neighbour's
value, with no compile error. Every cvar removal so far has re-derived those
constants by hand.

It also refuses cvars the DoD client is known NOT to register. A query for one
answers "Bad CVAR request", the reply parses to 0.0, and a rule of 0 then
passes on every client forever -- the cvar looks enforced and enforces nothing.

The shape rules carry mutation controls: the checks are re-run on a copy of the
source with one thing broken, and must fail for that rule. What this does NOT
pin is values: two entries swapped inside one table keep every count and pass
here. Pinning values is the published-list compare's job, not this gate's.

    python3 tools/check_cvar_tables.py [--sma ktp_cvar.sma]

Exits 0 when every check passes, 1 otherwise.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from fractions import Fraction

# Proven absent on the DoD client: no bytes in hw.dll / client.dll, "Bad CVAR
# request" on every query, or zero corrections fleet-wide while control cvars
# in the same corpus were corrected. Re-adding one needs new evidence, not a
# deletion from this list.
ABSENT_ON_CLIENT = (
    "cl_nodelta",
    "cl_nopred",
    "fastsprites",
    "gl_nobind",
    "gl_nocolors",
    "gl_playermip",
    "r_luminance",
)

DEFINES = ("TOTAL_CVARS", "MIN_MAX_CVAR_START", "ALT_VALUES_COUNT",
           "PRIORITY_CVARS_COUNT", "OBSERVE_CVARS_COUNT",
           "HUD_TAKESSHOTS_INDEX", "M_PITCH_INDEX")

# The two special-cased positions, and the cvar each must name.
INDEX_NAMES = {"HUD_TAKESSHOTS_INDEX": "hud_takesshots", "M_PITCH_INDEX": "m_pitch"}


def table_span(src: str, name: str) -> tuple[int, int]:
    m = re.search(r"\b" + name + r"\s*\[[^\]]*\]\s*\[\s*\]\s*=\s*\{(.*?)\}", src, re.S)
    if not m:
        raise LookupError(f"{name}[] not found")
    return m.span(1)


def table(src: str, name: str) -> list[str]:
    a, b = table_span(src, name)
    return re.findall(r'"([^"]*)"', re.sub(r"//[^\n]*", "", src[a:b]))


def define(src: str, name: str) -> int:
    m = re.search(r"^#define\s+" + name + r"\s+(\d+)\b", src, re.M)
    if not m:
        raise LookupError(f"#define {name} not found")
    return int(m.group(1))


def readme_list(readme: str, label: str) -> tuple[int, list[str]] | None:
    m = re.search(r"\*\*" + label + r" \((\d+)\):\*\*([^\n]*)", readme)
    if not m:
        return None
    return int(m.group(1)), re.findall(r"`([a-z_][a-z0-9_]*)`", m.group(2))


def problems(src: str, readme: str) -> list[str]:
    out: list[str] = []
    try:
        d = {k: define(src, k) for k in DEFINES}
        names = table(src, "gs_cvars")
        cal = table(src, "gs_calvalues")
        alt = table(src, "gs_altvalues")
        prio = table(src, "gs_priority_cvars")
        observe = table(src, "gs_observe_cvars")
    except LookupError as e:
        return [f"parser blind: {e}"]

    total, start = d["TOTAL_CVARS"], d["MIN_MAX_CVAR_START"]

    if len(names) != total:
        out.append(f"gs_cvars has {len(names)} entries, TOTAL_CVARS is {total}")
    if len(cal) != total:
        out.append(f"gs_calvalues has {len(cal)} entries, TOTAL_CVARS is {total}")
    if len(alt) != d["ALT_VALUES_COUNT"]:
        out.append(f"gs_altvalues has {len(alt)} entries, ALT_VALUES_COUNT is {d['ALT_VALUES_COUNT']}")
    if d["ALT_VALUES_COUNT"] != total - start:
        out.append(f"ALT_VALUES_COUNT {d['ALT_VALUES_COUNT']} != TOTAL_CVARS - MIN_MAX_CVAR_START "
                   f"({total} - {start}) -- range cvars and their ceilings are misaligned")
    if len(prio) != d["PRIORITY_CVARS_COUNT"]:
        out.append(f"gs_priority_cvars has {len(prio)} entries, PRIORITY_CVARS_COUNT is "
                   f"{d['PRIORITY_CVARS_COUNT']}")
    if len(observe) != d["OBSERVE_CVARS_COUNT"]:
        out.append(f"gs_observe_cvars has {len(observe)} entries, OBSERVE_CVARS_COUNT is "
                   f"{d['OBSERVE_CVARS_COUNT']}")

    for label, lst in (("gs_cvars", names), ("gs_priority_cvars", prio)):
        dups = sorted({n for n in lst if lst.count(n) > 1})
        if dups:
            out.append(f"{label} lists {dups} more than once")
    stray = [n for n in prio if n not in names]
    if stray:
        out.append(f"gs_priority_cvars names {stray}, which gs_cvars does not -- "
                   "each is silently demoted and burns a priority slot")

    for define_name, cvar in INDEX_NAMES.items():
        i = d[define_name]
        got = names[i] if 0 <= i < len(names) else "<out of range>"
        if got != cvar:
            out.append(f"{define_name} {i} names {got!r}, not {cvar!r}")
        if i >= start:
            out.append(f"{define_name} {i} is inside the range block (MIN_MAX_CVAR_START {start})")

    # A shift that lands a ceiling on the wrong cvar usually inverts at least one pair.
    for k, ceiling in enumerate(alt):
        i = start + k
        if i >= len(names) or i >= len(cal):
            break
        try:
            if Fraction(cal[i]) > Fraction(ceiling):
                out.append(f"{names[i]}: floor {cal[i]} is above ceiling {ceiling}")
        except (ValueError, ZeroDivisionError):
            out.append(f"{names[i]}: bound {cal[i]!r} / {ceiling!r} is not a number")

    # The defer queue keeps one bit per cvar across two 32-bit cells, and one
    # bit per range cvar in g_deferCeiling.
    if total > 64:
        out.append(f"TOTAL_CVARS {total} overflows g_deferPending + g_deferPendingHi (64 bits)")
    if total - start > 32:
        out.append(f"{total - start} range cvars overflow g_deferCeiling (32 bits)")

    for label, lst in (("gs_cvars", names), ("gs_priority_cvars", prio),
                       ("gs_observe_cvars", observe)):
        bad = [n for n in lst if n in ABSENT_ON_CLIENT]
        if bad:
            out.append(f"{label} carries {bad}, which the DoD client does not register -- "
                       "a 'Bad CVAR request' reply parses to 0.0 and passes silently")

    # README states the tiers by count and by name; both drift on every edit.
    prio_set = set(prio)
    standard = [n for n in names if n not in prio_set]
    m = re.search(r"## Monitored Cvars \((\d+) total\)", readme)
    if not m:
        out.append("README: no '## Monitored Cvars (N total)' heading -- the README check is blind")
    elif int(m.group(1)) != total:
        out.append(f"README says {m.group(1)} monitored cvars, TOTAL_CVARS is {total}")
    for label, want in (("Priority", prio), ("Standard", standard), ("Range cvars", names[start:])):
        got = readme_list(readme, label)
        if got is None:
            out.append(f"README: no '**{label} (N):**' line -- the README check is blind")
            continue
        count, listed = got
        if count != len(want):
            out.append(f"README {label} count {count}, source has {len(want)}")
        if set(listed) != set(want):
            out.append(f"README {label} list differs: missing {sorted(set(want) - set(listed))}, "
                       f"extra {sorted(set(listed) - set(want))}")
    return out


# ---------------------------------------------------------------------------
# Mutation controls
# ---------------------------------------------------------------------------

def edit_table(src: str, name: str, fn) -> str:
    a, b = table_span(src, name)
    entries = fn(table(src, name))
    return src[:a] + "\n" + ", ".join(f'"{e}"' for e in entries) + "\n" + src[b:]


def bump_define(src: str, name: str, by: int) -> str:
    return re.sub(r"^(#define\s+" + name + r"\s+)(\d+)",
                  lambda m: m.group(1) + str(int(m.group(2)) + by), src, count=1, flags=re.M)


def controls(src: str, readme: str) -> list[str]:
    """Each mutation must fail for the rule it targets, not merely fail somewhere."""
    start = define(src, "MIN_MAX_CVAR_START")
    first_prio = table(src, "gs_priority_cvars")[0]

    def absent_readded(s: str) -> str:
        s = edit_table(s, "gs_cvars", lambda t: t[:start] + ["r_luminance"] + t[start:])
        s = edit_table(s, "gs_calvalues", lambda t: t[:start] + ["0"] + t[start:])
        s = bump_define(s, "TOTAL_CVARS", 1)
        return bump_define(s, "MIN_MAX_CVAR_START", 1)

    cases = [
        ("one gs_calvalues entry dropped", "gs_calvalues has",
         lambda s: src_edit(s, "gs_calvalues", lambda t: t[1:])),
        ("gs_cvars entry dropped with TOTAL_CVARS kept", "gs_cvars has",
         lambda s: src_edit(s, "gs_cvars", lambda t: t[:-1])),
        ("M_PITCH_INDEX off by one", "M_PITCH_INDEX",
         lambda s: bump_define(s, "M_PITCH_INDEX", 1)),
        ("HUD_TAKESSHOTS_INDEX off by one", "HUD_TAKESSHOTS_INDEX",
         lambda s: bump_define(s, "HUD_TAKESSHOTS_INDEX", -1)),
        ("MIN_MAX_CVAR_START off by one", "ALT_VALUES_COUNT",
         lambda s: bump_define(s, "MIN_MAX_CVAR_START", 1)),
        ("priority name typo", "gs_priority_cvars names",
         lambda s: src_edit(s, "gs_priority_cvars", lambda t: [t[0] + "x"] + t[1:])),
        ("absent cvar re-added with every constant kept consistent", "does not register",
         absent_readded),
        ("absent cvar in the observe-only table", "gs_observe_cvars carries",
         lambda s: src_edit(s, "gs_observe_cvars", lambda t: ["cl_nopred"] + t[1:])),
        ("duplicate cvar name, count kept", "more than once",
         lambda s: src_edit(s, "gs_cvars", lambda t: t[:1] + [t[0]] + t[2:])),
        ("range floor above its ceiling", "above ceiling",
         lambda s: src_edit(s, "gs_altvalues", lambda t: ["0"] + t[1:])),
    ]
    failed: list[str] = []
    for label, expect, mutate in cases:
        mutated = mutate(src)
        found = problems(mutated, readme) if mutated != src else []
        if mutated == src:
            failed.append(f"CONTROL {label}: mutation did not apply -- the control is blind")
        elif not any(expect in p for p in found):
            failed.append(f"CONTROL {label}: no problem mentioning {expect!r} (got {found})")

    def drop_first_listed(text: str, label: str) -> str:
        return re.sub(r"(\*\*" + label + r" \(\d+\):\*\* )`[a-z_0-9]+`, ", r"\1", text, count=1)

    readme_cases = [
        ("README priority name missing", "README Priority",
         readme.replace(f"`{first_prio}`, ", "", 1)),
        ("README standard name missing", "README Standard", drop_first_listed(readme, "Standard")),
        ("README total off by one", "monitored cvars",
         re.sub(r"(## Monitored Cvars \()(\d+)", lambda m: m.group(1) + str(int(m.group(2)) + 1),
                readme, count=1)),
    ]
    for label, expect, mutated in readme_cases:
        found = problems(src, mutated) if mutated != readme else []
        if mutated == readme:
            failed.append(f"CONTROL {label}: mutation did not apply -- the control is blind")
        elif not any(expect in p for p in found):
            failed.append(f"CONTROL {label}: no problem mentioning {expect!r} (got {found})")
    return failed


src_edit = edit_table


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sma", default="ktp_cvar.sma")
    args = ap.parse_args()
    src = open(args.sma, encoding="utf-8", errors="replace").read()
    readme_path = os.path.join(os.path.dirname(os.path.abspath(args.sma)), "README.md")
    try:
        readme = open(readme_path, encoding="utf-8", errors="replace").read()
    except OSError as e:
        print(f"FAIL: README not readable ({readme_path}: {e}) -- the README check is blind")
        return 1

    found = problems(src, readme)
    if not found:
        found = controls(src, readme)
    if found:
        print("MISMATCH:")
        for p in found:
            print(f"  {p}")
        return 1
    print(f"OK -- cvar tables consistent ({define(src, 'TOTAL_CVARS')} cvars, "
          f"range block from {define(src, 'MIN_MAX_CVAR_START')}), every mutation control fails.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
