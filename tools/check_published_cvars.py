#!/usr/bin/env python3
"""Fail if the published CVAR list and the enforced one disagree.

The plugin enforces `gs_cvars[]`. Players read the markdown in
afraznein/KTP_Documentation. Nothing has ever connected the two, so every
enforcement change since v7.24 has relied on somebody remembering to edit the
doc as well -- and a player kicked for a value the published list never
mentioned has no way to find out why.

Checks in BOTH directions. A cvar the plugin enforces but the doc omits is a
player who cannot comply; a cvar the doc demands but the plugin ignores is a
promise nobody keeps. The second is the easier one to miss.

Exits 1 on any mismatch, 0 when they agree.

    python3 tools/check_published_cvars.py [--sma ktp_cvar.sma] [--offline FILE]
"""
from __future__ import annotations

import argparse
import re
import sys
import urllib.request

DOC_URL = (
    "https://raw.githubusercontent.com/afraznein/KTP_Documentation/main/"
    "KTP%20Cvar%20List.md"
)

# The doc publishes these for players to tune themselves. They are deliberately
# NOT enforced, so their absence from the plugin is correct rather than drift --
# the one asymmetry this check must not flag.
PLAYER_TUNABLE_HEADING = re.compile(r"player[- ]tunable|adjustable|optional", re.I)


def parse_sma(path: str) -> dict[str, str]:
    """cvar name -> enforced value, read from gs_cvars[] / gs_calvalues[]."""
    src = open(path, encoding="utf-8", errors="replace").read()

    def block(name: str) -> list[str]:
        m = re.search(name + r"\s*\[[^\]]*\]\s*\[\s*\]\s*=\s*\{(.*?)\}", src, re.S)
        if not m:
            raise SystemExit(f"could not find {name}[] in {path}")
        body = re.sub(r"//[^\n]*", "", m.group(1))          # strip trailing comments
        return re.findall(r'"([^"]*)"', body)

    names, values = block("gs_cvars"), block("gs_calvalues")
    if len(names) != len(values):
        raise SystemExit(
            f"gs_cvars[] has {len(names)} entries but gs_calvalues[] has "
            f"{len(values)} — the arrays are positional, so this is a real bug"
        )
    return dict(zip(names, values))


def parse_doc(markdown: str) -> tuple[set[str], set[str]]:
    """(enforced cvars, player-tunable cvars) as published."""
    enforced: set[str] = set()
    tunable: set[str] = set()
    target = enforced

    for line in markdown.splitlines():
        if line.startswith("#"):
            target = tunable if PLAYER_TUNABLE_HEADING.search(line) else enforced
            continue
        # | `cl_bob` | `0` | description |
        m = re.match(r"\s*\|\s*`([a-z_][a-z0-9_]*)`\s*\|", line, re.I)
        if m:
            target.add(m.group(1))

    return enforced, tunable


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sma", default="ktp_cvar.sma")
    ap.add_argument("--offline", help="read the doc from a file instead of GitHub")
    args = ap.parse_args()

    plugin = parse_sma(args.sma)

    if args.offline:
        markdown = open(args.offline, encoding="utf-8").read()
    else:
        with urllib.request.urlopen(DOC_URL, timeout=20) as r:
            markdown = r.read().decode("utf-8")

    doc_enforced, doc_tunable = parse_doc(markdown)

    if not doc_enforced:
        print("FAIL: parsed zero cvars from the published doc — the table format "
              "changed and this check is now blind. Fix the parser.")
        return 1

    plugin_names = set(plugin)
    missing_from_doc = sorted(plugin_names - doc_enforced - doc_tunable)
    missing_from_plugin = sorted(doc_enforced - plugin_names)
    # A cvar in both the enforced doc table and the tunable one is contradictory.
    contradictory = sorted(doc_enforced & doc_tunable)

    print(f"plugin enforces {len(plugin_names)} cvars; "
          f"doc publishes {len(doc_enforced)} enforced + {len(doc_tunable)} tunable")

    ok = True
    if missing_from_doc:
        ok = False
        print("\nENFORCED BUT NOT PUBLISHED — players cannot comply with these:")
        for c in missing_from_doc:
            print(f"  {c} = {plugin[c]}")
    if missing_from_plugin:
        ok = False
        print("\nPUBLISHED BUT NOT ENFORCED — the doc promises what nothing checks:")
        for c in missing_from_plugin:
            print(f"  {c}")
    if contradictory:
        ok = False
        print("\nLISTED AS BOTH ENFORCED AND PLAYER-TUNABLE:")
        for c in contradictory:
            print(f"  {c}")

    # Positive control: a cvar we know is enforced must be found in the doc.
    # Without this, a parser that silently matches nothing reports success.
    canary = "cl_updaterate"
    if canary in plugin_names and canary not in (doc_enforced | doc_tunable):
        print(f"\nFAIL: control cvar {canary} is enforced but absent from the doc — "
              "either real drift or the doc parser is broken.")
        ok = False

    print("\nOK — published and enforced lists agree." if ok else "\nMISMATCH")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
