# KTPCvarChecker - Claude Code Context

**REQUIRED: Before writing or modifying any code in this repo, invoke the `plugin-dev` skill** (`.claude/skills/plugin-dev/SKILL.md`). It carries the cvar-tier/array bookkeeping rules and deploy workflow; do not edit the .sma without it loaded.

**A design that ships as a document is NOT done** — every proposal in a docs-only PR becomes a
tracked board item in the same act (operator ruling 2026-09-14). See `DESIGN_DOCS_ARE_NOT_DONE.md`.

## Launch-time setup: the commit-sweep guard

Once per clone, before the first commit (linked worktrees share the setting):

```bash
git config core.hooksPath .githooks
```

The main checkout is shared by concurrent sessions, so its index is shared too: a bare `git commit` takes
whatever anyone else has staged, and `git commit -a` takes every modified tracked file. `.githooks/pre-commit`
refuses both in the main checkout whenever anything is staged. Commit by path instead:
`git commit -m "..." -- <paths>` builds a private index from just those paths (a new file still needs
`git add <path>` first). Linked worktrees have their own index and skip the check, so isolated work pays nothing.
Finishing a conflicted merge, revert or cherry-pick legitimately commits the index:
`KTP_COMMIT_SWEEP=1 git commit ...`. A hook already in `.git/hooks/pre-commit` still runs; the guard chains to it.
`core.hooksPath` would otherwise shadow `.git/hooks`, so `.githooks/pre-push` hands off to the pre-push gate
`scripts/install-hooks.sh` installs there.
Test: `sh .githooks/test-pre-commit.sh`.

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

⛔ **This repo carries NO map assets, and an audit figure says otherwise.** The 2026-09-11
`KTP Git Projects` disk audit kept `Defunct/KTPCvarChecker` on the grounds that it held "~50
untracked map assets". That directory was promoted to this repo (operator: *"KTPCvarChecker is not
defunct, so yes deliberate"*, 2026-10-05) and nothing map-shaped came with it — no `.bsp`, `.wad`,
`.res` or `.nav` anywhere in the tree.
🔑 **The figure was never verified and cannot be: the files were UNTRACKED, so no probe can tell
moved from copied from deleted.** ⛔ **Do not read their absence here as a loss, and do not re-quote
the count as measured.** The estate's actual map assets live in
`KTP DoD Server/serverfiles/dod/maps/` and a few at the project root — look there before concluding
anything about these.

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

It compares the published list against the source by **name**, in both directions, and by **value**:
each exact cvar's published value against `gs_calvalues[]`, each range cvar's bounds, in order, against
`gs_calvalues[]` / `gs_altvalues[]`, as exact decimals. It reads the doc **live from
`KTP_Documentation` `main`**, so a PR here is judged against the doc as merged, never against a doc branch.

Behaviour a number cannot express lives in its `BEHAVIOURS` table: `m_pitch` accepted at either sign,
`hud_takesshots` enforced only in competitive modes. Each entry must still be special-cased in the source,
and its published row must say so in words. A new `#define *_INDEX` special case with no entry fails the
check rather than being skipped. `tools/test_check_published_cvars.py` runs it on a hand-written fixture
pair, where a correct doc must pass and each single mutation must be named.

Still not compared: the Quick Reference block and the `Default` column. Those are recommendations,
not enforced bounds, so a recommended value outside the enforced range would pass.

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

## Lang file

`data/lang/ktp_cvar.txt` is the fleet's live file byte for byte, CRLF included. The distributor overwrites whole files, so a repo copy that drifts from the live one strips keys on all 24 servers when pushed; compare md5s before shipping it.
