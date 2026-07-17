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
`gs_priority_cvars` (0.3s rotation) and `gs_standard_cvars` (1.0s rotation) are
two **hand-maintained literal lists** that must partition `gs_cvars` exactly —
nothing enforces this at compile time. `gb_isPriorityCvar[]` and
`g_queryOrder[]` ARE already derived programmatically from `gs_priority_cvars`
at `plugin_init` — that's the pattern to follow, not the one `gs_standard_cvars`
currently uses. Every promotion/demotion between tiers (has happened in 7.13,
7.24, 7.25, 7.27, 7.30) requires:
1. Editing BOTH literal lists (add to one, remove from the other).
2. Recomputing `TOTAL_CVARS`, `MIN_MAX_CVAR_START`, `STANDARD_CVARS_COUNT`, and
   any index constants that shift (`HUD_TAKESSHOTS_INDEX`, `M_PITCH_INDEX`
   have both shifted ±1 on past edits).
3. Updating the README monitored-cvar counts and table.
A cvar left in both lists double-queries and silently misattributes its tier
in `fn_note_tier_response`'s `gb_isPriorityCvar`-based accounting — no
compile-time signal. If you're adding tier-promotion logic anyway, prefer
deriving `gs_standard_cvars` from `gs_cvars` filtered by `gb_isPriorityCvar[]`
(same loop shape as `g_queryOrder`) over hand-typing a third list.

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

## Pawn checklist (apply to every diff)
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
   `ktp_cvar.sma`, new `CHANGELOG.md` section, README version header + the
   monitored-cvar count table if the tier lists changed.
2. **Compile**: `wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPCvarChecker' && bash compile.sh"`
   (outputs `compiled/ktp_cvar.amxx`, auto-stages to the KTP DoD Server test tree).
3. **Review**: `ktp-code-review` agent before any fleet stage.
4. **Fleet stage**: deploy as `ktp_cvar.amxx.new` via paramiko (see root
   CLAUDE.md § SSH); verify staged md5 on all 24 active instances.
5. **Post-activation verify** (after the nightly): 24/24 on the new md5, no
   leftover `.new`, and check `/tmp` for cores — `find /tmp -maxdepth 1 -name
   'core.*' -mtime -1` on every host. A game-tree core search proves nothing
   (matches only core.so/core.ini/core.wav).
