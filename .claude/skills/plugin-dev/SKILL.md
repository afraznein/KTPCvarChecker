---
name: plugin-dev
description: Use BEFORE writing or modifying any KTPCvarChecker Pawn code — cvar-tier/array bookkeeping rules, per-player vs. global state pitfalls, dual-dispatch dedup, and the compile/review/stage/verify workflow. Also use when planning a change, to know which invariants it touches.
---

# KTPCvarChecker Development

This plugin runs real-time client cvar enforcement on a production fleet (24
instances) with active competitive players. Follow every rule below; when a
rule and your instinct disagree, the rule wins — each one was paid for with a
production incident or a confirmed review finding.

## Hard safety rules
- **NEVER restart game servers** or issue LinuxGSM control commands without the
  operator's explicit permission in the current conversation.
- Deploys are staged as `ktp_cvar.amxx.new` in each instance's plugins dir and
  swap at the 03:00 ET nightly restart. Never hot-swap the live `.amxx`.
- Run the `ktp-code-review` agent on any nontrivial change BEFORE compiling for
  deploy — including anything touching the cvar tier lists or Discord batching.

## Architecture constraints
- **Extension mode / no Metamod**: detection flow is KTP-ReHLDS
  `pfnClientCvarChanged` → KTPAMXX `client_cvar_changed` forward → this plugin
  validates against `gs_cvars` and corrects. Never add a fakemeta dependency.
- **Every response is dispatched twice** by the engine: once to the
  `query_client_cvar` callback (`fn_querycvar`) and again to the
  `client_cvar_changed` forward, for the same event. The plugin dedups this
  (querycvar marks handled, the forward consumes and skips) — if you add a new
  response-handling path, it needs the same dedup or you'll double-validate
  (functionally harmless but silently doubles per-player work fleet-wide).
- **`ktp_match_competitive` is KTPMatchHandler's state, and this plugin cannot
  tell when it goes stale.** `hud_takesshots` enforcement is gated on it, engine
  cvars survive a changelevel, and extension mode never reloads plugins — so any
  MatchHandler teardown path that misses the reset leaves the flag latched, and
  this plugin then enforces competitive-only rules on pub play indefinitely. From
  here a latched `1` is indistinguishable from a live match. Anyone asking "why is
  this pub server enforcing match settings" will start in this plugin and find
  nothing wrong; the answer is upstream.
- **Slot recycle**: `client_putinserver` must explicitly clear ALL per-slot
  state (enforcement-attempt counts, defer bitmasks, the echo-suppression slot,
  liveness counters, in-progress-check flags) rather than relying on the
  previous occupant's `client_disconnected` having done it. A new connection
  can beat disconnect cleanup.

## Known residuals — don't re-report, but don't make worse
- **`gs_enforcing_cvar` echo-suppression** is one name-slot per player
  (accepted in 7.29): a multi-cvar violation burst can double-enforce because
  only one in-flight cvar name is suppressed at a time per player. Real fix
  would be a per-cvar bitmask — only worth it if duplicate corrections are
  actually reported in the field.
- **Discord violation batching uses a single GLOBAL buffer**
  (`g_discordPlayerId`/`g_discordPlayerName`/`g_discordCvarNames[]` etc.,
  around `buffer_discord_violation()`), not one buffer per player. Two players
  triggering violations in the same 5s window evict and fragment each other's
  embed — this is a confirmed bug (not an accepted residual) and the common
  case at match start, not an edge case. If you touch the Discord batching
  path, fix this properly: convert to `MAX_PLAYERS`-sized parallel arrays,
  mirroring the existing per-player pattern used for
  `gi_enforce_attempts`/`g_deferPending`. Don't leave it as a single buffer.
- Relatedly, the buffered name/IP fields are only refreshed when a *new* batch
  window opens — repeat violations from the same player inside an open window
  don't re-copy from `gs_logname`/`gs_logip`, so a mid-window rename can show
  a stale name in the eventual embed. If you're already in this function
  fixing the per-player buffer, refresh name/IP unconditionally too (the
  values are already fetched fresh in `fn_enforce_cvar()` right before the
  call — it's a copy, not a new lookup).

## Cvar-tier array bookkeeping (high-friction, easy to get wrong)
Four hand-typed literal tables, positional and unchecked by the compiler:
- `gs_cvars[TOTAL_CVARS]` — every enforced cvar: exact-value cvars first, then
  the range cvars from `MIN_MAX_CVAR_START` to the end.
- `gs_calvalues[TOTAL_CVARS]` — the value (exact) or floor (range), same order.
- `gs_altvalues[ALT_VALUES_COUNT]` — the ceilings, one per range cvar, in range
  order (`ALT_VALUES_COUNT == TOTAL_CVARS - MIN_MAX_CVAR_START`).
- `gs_priority_cvars[PRIORITY_CVARS_COUNT]` — names of the 0.3s-tier cvars.

The standard (1.0s) tier is **not a list**. Since 7.32 `plugin_init` derives
`gi_standardCvarIdx[]` / `gi_standardCvarCount` as `gs_cvars` minus the
priority names, alongside `gb_isPriorityCvar[]`, `g_queryOrder[]` and
`gi_exInterpIdx`. There is no `gs_standard_cvars` and no
`STANDARD_CVARS_COUNT` — don't reintroduce either. A priority name that matches
nothing in `gs_cvars` logs `CVAR TIER MISMATCH` at init.

Adding, removing or retiering a cvar (7.13, 7.24, 7.25, 7.27, 7.30, 7.40) means:
1. Editing `gs_cvars` and `gs_calvalues` at the same position (and
   `gs_altvalues` for a range cvar); for a retier, only `gs_priority_cvars`.
2. Recomputing `TOTAL_CVARS`, `MIN_MAX_CVAR_START`, `ALT_VALUES_COUNT`,
   `PRIORITY_CVARS_COUNT`, and the position constants `HUD_TAKESSHOTS_INDEX` /
   `M_PITCH_INDEX` (shifted on most removals, by four at 7.40).
3. Updating the README monitored-cvar total, tier counts, name lists and timing
   table.

`tools/check_cvar_tables.py` (Source Invariants CI) fails on the shape errors:
table lengths vs their defines, a position constant naming the wrong cvar, a
priority name missing from `gs_cvars`, duplicates, a floor above its ceiling,
defer-bitmask overflow, README count/list drift, and any cvar on its
`ABSENT_ON_CLIENT` refusal list. It **cannot see a value moved to the wrong
position** — two entries swapped inside one table keep every count. The value
side is `tools/check_published_cvars.py` against the published page, so read
the `gs_cvars[i]` / `gs_calvalues[i]` pairing yourself on every edit. A
compile-time signal exists only for a table LONGER than its define
(`error 018`).

## Policy: think before enforcing a new cvar
Before adding ANY cvar to enforcement, establish its actual server/aim impact
first. `cl_mousegrab` was enforced to `1` for years on a MOSS-compatibility
rationale that never had real teeth — it's a client-only SDL pointer-grab
cvar the server never reads, and enforcing it pushed players toward exclusive-
fullscreen OpenGL, which is KTPAntiCheat's confirmed screenshot-blind capture
mode. Enforcement pressure that has no aim/netcode surface is pure friction
and can actively work against the anti-cheat. If a cvar's rationale is "looks
suspicious" rather than "changes what the server/client actually does",
don't add it — or be ready to justify it same as `cl_mousegrab` needed to be
un-justified.

The same scrutiny applies to the *value*, not just the choice to enforce.
Enforcing anything other than the engine's own default converts every untouched,
compliant client into a violation, so a deviation needs a specific exploit it
blocks — and that rationale has to survive the question "would an attacker simply
set this too?" The `r_glowshellfreq` case is the worked example on both counts.

## Pawn checklist (apply to every diff)
- **Never "tidy" the monitoring rotations' `set_task(..., "", 0, "b")` into
  `_, _`.** Passing Pawn's `_` placeholder for the `parameter[]`/`len` arguments
  makes `set_task` fail to register the `"b"` repeat — no error, no log line, and
  a plugin that loads and reports perfectly healthy. That is how the entire
  polling path stayed dead for many versions: the real-time
  `client_cvar_changed` forward kept catching mid-session changes, so violations
  kept reaching Discord while every player who *joined with* a bad value went
  undetected. The silent-client tripwire cannot catch it either — it counts
  unanswered queries, and a task that never fires sends none, so the counter
  never advances. The explicit arguments are the fix, not clutter.
- `charsmax(buf)` for every format/copy.
- Any new per-player state needs a slot-recycle clear in `client_putinserver`
  AND a `client_disconnected` clear — both, not either.
- Discord embeds: route user-supplied text through `ktp_discord_escape_json`.
- Comments: short, explain *why*, no ticket/finding IDs, never delete a
  tripwire fact while editing near it.

## Never run a destructive simulation inside the working tree
Verifying a fix often means simulating the failure — writing a fake `build.sh`, a
fake artifact, a fake staging dir. Do it in a **verified** scratch dir, never in
the repo:

```bash
T="$(mktemp -d)" || exit 1
[ -n "$T" ] && [ -d "$T" ] || exit 1   # verify BEFORE you cd — this is the whole rule
cd "$T" || exit 1
```

`cd "$T"` with an empty `$T` **silently succeeds and leaves you where you were** —
in the repo. A simulation that then writes `build.sh` overwrites the real one. On
2026-07-16 exactly that truncated a tracked 60-line upstream file to 2 lines and
dropped a junk `.so` into `build/`, where a `find | head -1` could have staged it.
It was caught only because `git status` showed a modification nobody made.

So: verify the scratch dir before `cd`, and **run `git status` after any test that
touches the filesystem** — an unexpected change is the tell. Prefer copying inputs
out to the scratch dir over running tools "in place".

## Workflow
1. **Version bump** (every shipped change): `#define PLUGIN_VERSION` in
   `ktp_cvar.sma` AND the header comment's `Current Version:` / `Release Date:`
   lines (they drifted apart at 7.35), new `CHANGELOG.md` section, README
   version header + the monitored-cvar count table if the tier lists changed.
2. **Compile**: `wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPCvarChecker' && bash compile.sh"`
   (outputs `compiled/ktp_cvar.amxx`, auto-stages to the KTP DoD Server test tree).
3. **Review**: `ktp-code-review` agent before any fleet stage.
4. **Fleet stage**: deploy as `ktp_cvar.amxx.new` via paramiko (see root
   CLAUDE.md § SSH); verify staged md5 on all 24 active instances.
5. **Post-activation verify** (after the nightly): 24/24 on the new md5, no
   leftover `.new`, and check `/tmp` for cores — `find /tmp -maxdepth 1 -name
   'core.*' -mtime -1` on every host. A game-tree core search proves nothing
   (matches only core.so/core.ini/core.wav).
