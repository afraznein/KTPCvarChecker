#!/usr/bin/env python3
"""Source invariants for the blocked-cvar bridge KTPMatchHandler consumes (v7.41).

KTPMatchHandler refuses `.ready` while this plugin reports a player as blocking an
enforced correction. It binds optionally -- a native filter plus LibraryExists plus
a running-plugin lookup by title -- so every way this side can drift makes the
refusal silently stop, with the handler still loading and nothing logged as wrong.
The names it looks up are therefore held here, along with the state the native
reports:

  * `plugin_natives` registers the library and the native, under the names the
    handler hardcodes, and `PLUGIN_NAME` is the title it searches for.
  * The native reads `gb_filterstuff_warned` through the same competitive-only
    gate enforcement uses (`fn_takesshots_exempt`), and fn_enforce_cvar still
    calls that gate. check_published_cvars.py checks the gate's own tokens.
  * The BLOCKED branch records the value to type next to the flag it sets.
  * The flag is cleared at exactly the three exits the contract names: connect,
    disconnect, and an in-range answer. A new reset elsewhere would end a block
    early; a removed one would hold it past the fix.
  * A map change (client_disconnected with drop false) carries blocked cvars to
    the same authid on the next putinserver; a real drop or a different player
    clears them. Without it halftime reopens .ready for the re-detection window.

Each rule carries a mutation that must fail it.

    python3 tools/check_blocked_bridge.py [--sma ktp_cvar.sma]
"""
from __future__ import annotations

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_interp_pairing import body_of, strip_comments  # noqa: E402

LIBRARY = "ktp_cvar_checker"
NATIVE = "ktp_cvar_get_blocked"
TITLE = "KTP Cvar Checker"
RESET_SITES = {"client_putinserver", "client_disconnected", "fn_reset_enforce_tracking"}


def problems(src: str) -> list[str]:
    out: list[str] = []
    code = strip_comments(src)

    lib = re.search(r'#define\s+KTP_CVAR_LIBRARY\s+"([^"]*)"', code)
    if not lib or lib.group(1) != LIBRARY:
        out.append(f'KTP_CVAR_LIBRARY must be "{LIBRARY}" (KTPMatchHandler checks that name)')
    title = re.search(r'#define\s+PLUGIN_NAME\s+"([^"]*)"', code)
    if not title or title.group(1) != TITLE:
        out.append(f'PLUGIN_NAME must be "{TITLE}" (KTPMatchHandler finds the plugin by title)')

    natives = body_of(src, "plugin_natives")
    if "register_library(KTP_CVAR_LIBRARY)" not in natives:
        out.append("plugin_natives() does not register_library(KTP_CVAR_LIBRARY)")
    reg = re.search(r'register_native\(\s*"' + NATIVE + r'"\s*,\s*"(\w+)"\s*\)', natives)
    if not reg:
        out.append(f'plugin_natives() does not register_native("{NATIVE}", ...)')
        handler = ""
    else:
        handler = body_of(src, reg.group(1))
        if not handler:
            out.append(f"native handler {reg.group(1)}() not found")

    if handler:
        if "gb_filterstuff_warned[id][i]" not in handler:
            out.append("the native no longer reads gb_filterstuff_warned")
        if "fn_takesshots_exempt(i)" not in handler:
            out.append("the native skips the competitive-only gate, so it can report a cvar "
                       "nothing is enforcing")
        if not re.search(r"set_string\(\s*2\s*,\s*gs_cvars\[i\]", handler):
            out.append("the native does not return the cvar name in param 2")
        if not re.search(r"set_string\(\s*4\s*,\s*gs_blockedRequired\[id\]\[i\]", handler):
            out.append("the native does not return the recorded value in param 4")

    enforce = body_of(src, "fn_enforce_cvar")
    if "fn_takesshots_exempt(cvar_index)" not in enforce:
        out.append("fn_enforce_cvar no longer calls fn_takesshots_exempt, so enforcement and "
                   "the native can disagree about hud_takesshots")
    blocked = re.search(r"if\s*\(\s*!gb_filterstuff_warned\[id\]\[cvar_index\]\s*\)\s*\{"
                        r"\s*gb_filterstuff_warned\[id\]\[cvar_index\]\s*=\s*true\s*"
                        r"copy\(\s*gs_blockedRequired\[id\]\[cvar_index\]\s*,[^,]+,\s*required\s*\)",
                        enforce)
    if not blocked:
        out.append("the BLOCKED branch does not record `required` into gs_blockedRequired "
                   "right after setting the flag")

    # Blocks survive a map change only for the same authid, and never a real drop.
    disc = body_of(src, "client_disconnected")
    if not re.search(r"if\s*\(\s*!drop\s*\)", disc):
        out.append("client_disconnected carries blocks without checking drop, so a real "
                   "disconnect no longer clears them")
    put = body_of(src, "client_putinserver")
    if 'containi(gs_blockCarryAuthid[id], "_ID_") != -1' not in disc:
        out.append("client_disconnected carries on a shared authid (STEAM_ID_LAN etc.), so a "
                   "different player could inherit the block")
    if "equal(authid, gs_blockCarryAuthid[id])" not in put:
        out.append("client_putinserver keeps blocks without matching the authid, so the next "
                   "occupant of the slot inherits them")
    for fn, body in (("client_disconnected", disc), ("client_putinserver", put)):
        if not re.search(r"if\s*\(\s*carry\s*&&\s*gb_filterstuff_warned\[id\]\[i\]\s*\)\s*continue", body):
            out.append(f"{fn} does not limit the carry to cvars that are actually blocked")
    if handler and "is_user_bot(id)" not in handler:
        out.append("the native reports bots, which never answer queries")

    sites = set()
    for m in re.finditer(r"gb_filterstuff_warned\[id\]\[\w+\]\s*=\s*false", code):
        fn = re.findall(r"^(?:stock|public)[^\n(]*?\b(\w+)\s*\(", code[:m.start()], re.M)
        sites.add(fn[-1] if fn else "<top level>")
    if sites != RESET_SITES:
        out.append(f"gb_filterstuff_warned is cleared in {sorted(sites)}; the bridge contract "
                   f"is exactly {sorted(RESET_SITES)}")
    return out


MUTATIONS = [
    ("library renamed", lambda s: s.replace(f'"{LIBRARY}"', '"ktp_cvar"')),
    ("title renamed", lambda s: s.replace(f'"{TITLE}"', '"KTP Cvar"')),
    ("native not registered", lambda s: s.replace(f'register_native("{NATIVE}"', 'register_native("x"')),
    ("native ignores the gate", lambda s: s.replace(" || fn_takesshots_exempt(i)", "")),
    ("enforcement bypasses the gate",
     lambda s: s.replace("if (fn_takesshots_exempt(cvar_index))", "if (false)")),
    ("BLOCKED branch stops recording",
     lambda s: re.sub(r"\n\s*copy\(gs_blockedRequired\[id\]\[cvar_index\][^\n]*", "", s)),
    ("real disconnect carries blocks", lambda s: s.replace("if (!drop) {", "if (true) {")),
    ("carry ignores authid",
     lambda s: s.replace("&& equal(authid, gs_blockCarryAuthid[id])", "")),
    ("carry keeps unblocked cvars",
     lambda s: s.replace("if (carry && gb_filterstuff_warned[id][i])\n\t\t\t\tcontinue", "if (carry)\n\t\t\t\tcontinue", 1)),
    ("native reports bots", lambda s: s.replace("|| is_user_bot(id) ", "")),
    ("carry keyed on shared authids",
     lambda s: s.replace('containi(gs_blockCarryAuthid[id], "_ID_") != -1', "false")),
    ("extra reset site",
     lambda s: s.replace("public cmd_manual_check(id) {",
                         "public cmd_manual_check(id) {\n\tgb_filterstuff_warned[id][0] = false")),
    ("reset site removed",
     lambda s: re.sub(r"(stock fn_reset_enforce_tracking\(id, cvar_index\) \{.*?)"
                      r"\n\s*gb_filterstuff_warned\[id\]\[cvar_index\] = false", r"\1", s, count=1,
                      flags=re.S)),
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sma", default="ktp_cvar.sma")
    args = ap.parse_args()
    src = open(args.sma, encoding="utf-8", errors="replace").read()

    failed = problems(src)
    for p in failed:
        print(f"FAIL: {p}")
    for label, mutate in MUTATIONS:
        mutated = mutate(src)
        if mutated == src:
            failed.append(f"CONTROL {label}: the mutation did not apply -- this rule is blind")
            print(f"FAIL: CONTROL {label}: mutation did not apply")
        elif not problems(mutated):
            failed.append(f"CONTROL {label}: the mutated source still passes")
            print(f"FAIL: CONTROL {label}: mutated source still passes")
    if failed:
        return 1
    print(f"OK -- blocked-cvar bridge invariants hold; {len(MUTATIONS)} mutation controls fail as expected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
