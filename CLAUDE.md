# KTPCvarChecker - Claude Code Context

**REQUIRED: Before writing or modifying any code in this repo, invoke the `plugin-dev` skill** (`.claude/skills/plugin-dev/SKILL.md`). It carries the cvar-tier/array bookkeeping rules and deploy workflow; do not edit the .sma without it loaded.

## Compile Command
To compile this plugin, use:
```bash
wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPCvarChecker' && bash compile.sh"
```

This will:
1. Compile `ktp_cvar.sma` using KTPAMXX compiler
2. Output to `compiled/ktp_cvar.amxx`
3. Auto-stage to `N:\Nein_\KTP Git Projects\KTP DoD Server\serverfiles\dod\addons\ktpamx\plugins\`

## Project Structure
- `ktp_cvar.sma` - Main plugin source
- `compile.sh` - WSL compile script
- `compiled/` - Compiled .amxx output

## Purpose
Real-time client cvar enforcement plugin. Uses KTPAMXX's `client_cvar_changed` forward to detect when clients respond to cvar queries and validates values against allowed ranges.

## Before enforcing a cvar

- **A cvar the client lacks passes forever.** The DoD client answers a query for a cvar it does not
  register with `Bad CVAR request`, and that reply parses to `0.0`. A rule of `0` then matches on every
  client, so the cvar looks enforced while nothing is checked and no log line ever says otherwise.
  **Prove the cvar exists before enforcing it** — a client answering with a real value, or corrections in
  the fleet logs next to a control cvar that is corrected. `fastsprites`, `gl_nobind`, `gl_nocolors`,
  `gl_playermip` and `r_luminance` were enforced this way until 7.40; `tools/check_cvar_tables.py`
  refuses them, and `cl_nopred`/`cl_nodelta`, if they come back.
- **A name in the client binary is not proof the cvar is registered.** `cl_nodelta`'s literal is in the
  DoD client and it still answers `Bad CVAR request`. So `gl_clear`, `s_show`, `cl_showevents`,
  `gl_d3dflip` and `gl_monolights` — still enforced, names present in the binary — are unproven either
  way until a query answers with a value.
- **`cl_lc` / `cl_lw` are observed, not enforced** (enforcement removed in 7.25, observation added in
  7.33). They are read from userinfo and logged as `LAGCOMP_OFF` / `LAGCOMP_CHANGED`; a player at `0` is
  never corrected. A log line about them is not a missed enforcement.
- **Judge `ex_interp` against the effective packet interval, never a literal.** The engine floors a
  sub-10 `cl_updaterate` to 0.1 s and clamps into `[1/sv_maxupdaterate, 1/sv_minupdaterate]`; compare
  against that, not the `1/cl_updaterate` the client asked for. Keep the tolerance at float-error scale:
  at `1e-4`, values under the floor passed on tolerance alone. `tools/check_interp_pairing.py` holds both.

## Detection Flow
```
KTP-ReHLDS: client responds to cvar query
     ↓
pfnClientCvarChanged callback
     ↓
KTPAMXX: client_cvar_changed forward
     ↓
KTPCvarChecker: validates and enforces
```

## Published-list check (`tools/check_published_cvars.py`)

It compares cvar **names** between `gs_cvars[]` and the published list, in both directions. Values are
only printed, never compared, so **a wrong published number passes**. It also can't see behaviour the
page has to state in words — a cvar accepted with more than one value (`m_pitch` in either sign), or one
enforced only in competitive modes (`ktp_match_competitive`). Check those by reading `gs_calvalues[]`,
`gs_altvalues[]` and the enforcement path against the page.

To read `PLUGIN_VERSION` out of a built `ktp_cvar.amxx`, see KTPAMXX `CLAUDE.md` § Identifying deployed
artifacts — `strings` on the file returns nothing.

## Server Deployment

Deploy compiled plugin to production servers using Python/Paramiko.

**Remote Path:** `~/dod-{port}/serverfiles/dod/addons/ktpamx/plugins/ktp_cvar.amxx`

See `N:\Nein_\KTP Git Projects\CLAUDE.md` for paramiko SSH documentation.

## Related Projects
- `N:\Nein_\KTP Git Projects\KTPAMXX` - Custom AMX Mod X fork (compiler source)
- `N:\Nein_\KTP Git Projects\KTPhlsdk` - SDK headers with pfnClientCvarChanged
- `N:\Nein_\KTP Git Projects\KTP DoD Server` - Test server with staged plugins

## Key Files to Update on Version Bump
1. `ktp_cvar.sma` - `#define PLUGIN_VERSION`
2. Update any CHANGELOG.md or README.md if present
