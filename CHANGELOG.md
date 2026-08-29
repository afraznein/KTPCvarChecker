# Changelog

All notable changes to KTP Cvar Checker will be documented in this file.

## [Unreleased]

### Removed — stale tracked plugin binary

`ktp_cvar.amxx` sat in the repo root at **7.7**, last touched 2025-12-21, while
source is 7.31 — twenty-four versions behind. Installation step 2 said "Copy
`ktp_cvar.amxx`", which resolves to that stale root binary whenever step 1's
compile is skipped or fails.

Build output belongs in the gitignored `compiled/` dir. Removed; installation now
uses `compile.sh` (matching the rest of the stack, replacing a raw `amxxpc`
invocation) and deploys `compiled/ktp_cvar.amxx`. A `/*.amxx` rule prevents
recurrence.

### Documentation

README corrections, all verified against `ktp_cvar.sma`. The monitored set was
re-checked item-by-item: 37 total, 15 priority + 22 standard, and the two lists
are exact complements — the 7.30 `cl_mousegrab` removal and its index shifts are
correctly reflected everywhere.

- The 22 standard cvars are now spelled out instead of deferred to "see source
  for full list". The priority list was already enumerated, so a player asking
  "what do you enforce?" had to read the source for half the answer.
- Added the `ktp_cvar_silent_tier_secs` row (default `90.0`, `0` disables). It
  was registered and consumed but named nowhere in the README, so the per-tier
  tripwire could not be tuned or disabled from the docs.
- Documented that `<configsdir>/ktp_cvar.cfg` is `exec`'d at plugin init — an
  operator-owned file that silently sources server cvars had no doc pointer.
- Installation now includes the language file. `compile.sh` stages only the
  plugin, so a clean install per the old steps printed raw `%L` keys.
- Requirements name `ktp_discord.inc` / `ktp_version_reporter.inc`; both live in
  the KTPAMXX include tree, not this repo.
- `/cvar` is registered for `say_team` too. Dropped "parallel" — the sweep chains
  one query per tick by design (the engine handles ~1 cvar callback per frame).

## [7.34] - 2026-08-29

### Added — netcode observation (log-only, nothing new enforced)

`rate` and `cl_updaterate` are now read from userinfo alongside the 7.33
`cl_lc`/`cl_lw` sample, and a mid-session edit to either logs `NETOBS_CHANGED`
off the same `client_infochanged` forward. The query rotation would eventually
notice, but only after up to a full cycle; the userinfo path is instant and
costs no queries.

These two are worth watching because the engine does not treat them as
preferences. In `SV_UserinfoChanged`, `rate` becomes `cl->netchan.rate` (clamped
to `MIN_RATE`/`MAX_RATE`) and `cl_updaterate` becomes `cl->next_messageinterval`
(with only a floor of 10 applied on this path). They are the client's bandwidth
cap and packet cadence, which is exactly what a `choke`/`drops` investigation
needs correlated against.

A once-per-map `NETOBS_SAMPLER_OK` liveness line ships for the same reason
7.33's does: silence from an exceptions-only check is indistinguishable from
silence from a check that is not running.

### Not included — the paired ex_interp check, and why

An earlier draft of this version added `NETOBS_INTERP_LOW`, warning when
`ex_interp` was below `1/cl_updaterate`. It was removed before release for two
independent reasons, recorded here so it is not re-attempted the same way:

- **`ex_interp` is not a transmitted userinfo field.** The engine's
  `g_info_important_fields` table (`rehlds/engine/info.cpp`) is exactly `name`,
  `model`, `topcolor`, `bottomcolor`, `rate`, `cl_updaterate`, `cl_lw`, `cl_lc`,
  `*hltv`, `*sid`, `_vgui_menus`. `get_user_info(id, "ex_interp", ...)` therefore
  returns empty for every player, the guard would treat it as unset, and the
  check would never have fired — a feature that looks shipped and does nothing.
  Reading it requires the cvar query path, where it already lives as a monitored
  range cvar.
- **The behavioural claim was not ours to make.** The draft asserted that such a
  client extrapolates. Whether the client clamps `ex_interp` up to the packet
  interval internally is client-side behaviour, and the client is closed source —
  we can observe the requested value but cannot verify what it does with it.

The underlying observation still stands and is worth a follow-up: the enforced
ranges are `cl_updaterate` 100-120 and `ex_interp` 0.009-0.05, so a client can
satisfy both rules with a ratio that is inconsistent, because every cvar here is
validated in isolation and nothing compares two of them.

### Notes

An absent userinfo key parses as `0`, and `0` here would read as a real and
alarming value rather than "not supplied", so the reader returns false on an
absent `rate`/`cl_updaterate` rather than caching a zero. Same trap 7.33
documented.

No enforced value, range, or tier changed. The monitored set is still 37, still
15 priority + 22 standard.

## [7.33] - 2026-08-26

### Added
- **cl_lc / cl_lw observation — log-only, deliberately NOT enforcement.** The
  v7.25 removal of both from enforcement stands: either flag at 0 is a strict
  self-handicap on the shooter, and permitting it was a player-facing decision.
  What changed is visibility. The engine skips lag compensation entirely when
  either flag is 0 (`SV_SetupMove` returns before any rewind), and an **absent**
  userinfo key parses as 0 (`SV_ExtractFromUserinfo`), so a player can be
  playing with zero lag compensation on their own shots without ever touching a
  cvar — a leading candidate for recurring "not hittable / inconsistent"
  reports. The plugin now reads both flags straight from userinfo (the same
  string the engine parses — no `query_client_cvar` traffic, no tier-array
  changes) once at monitoring start, and re-reads on `client_infochanged`,
  logging only on an actual transition.
- Log events, all structured key=value in the house style:
  - `LAGCOMP_OFF` — initial sample found lc/lw not both 1
  - `LAGCOMP_CHANGED` — a sampled player's flags flipped mid-session (includes
    `prev_lc`/`prev_lw`; a flip back to 1/1 logs too — the transition is the
    signal)
  - `LAGCOMP_SAMPLER_OK` — once per map **load**, from the first sampled
    player, whatever their values. An exceptions-only feature that silently
    breaks is indistinguishable from a fleet with no exceptions; this line is
    the liveness proof. Keyed on a `plugin_init`-reset bool, not the map name:
    halftime and every OT round changelevel to the *same* map, and
    extension-mode globals survive the changelevel, so a name compare would be
    silent for exactly the halves that matter.
- **Volume: a 1/1 player (the normal case) writes zero log lines.** Per-player
  connect logging was removed in 7.21 over disk-write volume; this feature
  keeps that property. A connect wave costs one line per affected player plus
  the single per-map-load sanity line. `LAGCOMP_CHANGED` is bounded by the
  engine itself: userinfo dispatches are throttled to at most one per client
  per second (`SV_UpdateUserInfo` pushes `sendinfo_time` a second out), and
  sub-second flips that land back where they started coalesce against the
  cached state to nothing — so a client deliberately toggling can sustain at
  most ~1 line/s, and cannot amplify.
- Caveat, so a quiet log is read correctly: the transition path rides the
  ReHLDS userinfo hookchain (`ktp_userinfo_hook`). With that cvar at 0,
  `LAGCOMP_CHANGED` goes silent while `LAGCOMP_SAMPLER_OK` keeps reporting
  healthy — the heartbeat proves the sampler, not the transition path.

## [7.32] - 2026-08-09

### Changed
- The standard-tier cvar list is now **derived** at init as `gs_cvars` minus
  `gs_priority_cvars`, replacing a hand-typed 22-entry array. Adding, removing or
  re-tiering a cvar meant replaying the edit into a second list by hand, with
  nothing checking the two agreed — a cvar dropped from the typed list would be
  enforced by neither tier and go silent with no error. The two lists did still
  agree when this was written (verified 22/22, both directions); the change is to
  make them unable to disagree.

### Added
- Init logs a `CVAR TIER MISMATCH` line if the derived count is short, which
  means a `gs_priority_cvars` entry matches no name in `gs_cvars` — a typo or a
  half-applied rename, previously invisible. The consequence is a **silent
  demotion**: the real cvar still gets enforced, but from the standard tier
  (~22s) instead of priority (~4.5s), and the priority rotation spends one of its
  15 slots querying a name no client has.


## [7.31] - 2026-07-18

Discord violation-batching correctness (no cvar-tier or enforcement changes).

### Changed
- Swapped the dead `<:ktp:…>` Discord emoji token for the current `<:KTP:1002382703020212245>` in the CVAR-violation embed title (the old one renders as raw text since 2026-07-17). Cosmetic; part of the fleet-wide emoji sweep.

### Fixed
- **Discord violation buffer is now per-player (CV-01).** The plugin batched violations for a grouped embed using a *single global* buffer (`g_discordPlayerName`/`g_discordCvarNames[]`/counts/etc.). Two players violating inside the same 5s `DISCORD_DELAY` window evicted each other: the second player's first violation flushed the first player's partial batch early and reset the buffer, so neither embed reflected the real set of violations. This is the common case at match start (everyone's cvars get swept and corrected at once), not an edge case. The buffer is now `MAX_PLAYERS`-sized parallel arrays indexed by slot (`g_discordPlayerName[MAX_PLAYERS+1]`, etc.), mirroring the existing per-player pattern used for enforcement/defer state. Slot reuse inside the window is still guarded by an authid re-check: if a recycled slot's buffered authid no longer matches the current occupant, the previous occupant's batch is flushed under *their* identity before the new one starts. `send_discord_violations` is now a thin task callback over an internal `flush_discord_violations(id)` that both disconnect and slot-reuse (`client_putinserver`) call directly, so a batch is never silently discarded.
- **Buffered name/IP refreshed on every violation (CV-02).** Previously the name/IP were copied into the buffer only when a *new* batch window opened; repeat violations from the same player inside an open window kept the name captured at batch start, so a mid-window rename showed a stale name in the eventual embed. Name/IP are now re-copied from `gs_logname`/`gs_logip` on every buffered violation (they're already fetched fresh by `fn_enforce_cvar` right before the call, so it's a copy, not a new lookup).

## [7.30] - 2026-07-11

Removed `cl_mousegrab` from enforcement (recurring player request; approved after a research pass).

### Changed
- **`cl_mousegrab` no longer enforced** — players may now run `cl_mousegrab 0` freely for comfortable windowed / multi-monitor play. It's a client-only SDL pointer-grab cvar: the server never reads it, and aim input comes from `m_rawinput`/cursor-recenter (not the grab), so it has **zero netcode/hitreg/aim surface**. It had been pinned to `1`, which confined windowed-mode players' cursor to the window (catching monitor corners, breaking on alt-tab + multi-monitor) and auto-corrected + chat-shamed anyone running `0`. The only retention rationale was MOSS compatibility — obsolete under KTPAntiCheat. Enforcing `1` also pushed players toward exclusive-fullscreen OpenGL, the AntiCheat's confirmed screenshot-blind mode, so enforcement actively worked *against* capturability. Edge cases (accidentally clicking out of the window mid-round) are pure self-handicaps — same class as the v7.25 `cl_lc`/`cl_lw` removal.
- Array bookkeeping (mirrors the v7.25 removal): `TOTAL_CVARS` 38→37, `MIN_MAX_CVAR_START` 31→30, `STANDARD_CVARS_COUNT` 23→22, `HUD_TAKESSHOTS_INDEX`/`M_PITCH_INDEX` shifted −1. Monitored set 38→37 (priority 15 unchanged; standard 23→22).

## [7.29] - 2026-07-08

Closes the selective-tier-blocking residual documented in 7.28.

### Added
- **Per-tier silence tripwire** - the 7.28 global counter resets on ANY response, so a client answering only one rotation tier (e.g. everything except the 0.3s priority tier, where the wallhack-relevant cvars live) never tripped it while that tier's cvars went unvalidated. Each tier now keeps its own unanswered counter, reset only by a response resolved to a cvar of that tier (full-list index mapped to tier at init). Time-primary threshold (`ktp_cvar_silent_tier_secs`, default 90s, 0 disables) with a 30-query minimum floor, same 60s join grace, latched once per streak per tier, and suppressed while the global total-silence alert is latched (total silence is the stronger signal). Emits `CVAR_TIER_SILENT` + a Discord audit embed naming the blocked tier. Alert-only. Remaining residual: per-NAME selective blocking within a tier.

## [7.28] - 2026-07-08

Closes CV-C1 from the 2026-07-06 assessment (the one bypass worth closing) plus the two hygiene items from the same review.

### Added

#### Silent-client liveness tripwire (CV-C1)
The plugin was completely blind to a client that simply never answers cvar queries: no callback fires, so there were zero logs, zero enforcement, zero tripwire — the single cleanest bypass of query-based checking. A per-player counter now tracks consecutive unanswered queries (incremented at every `query_client_cvar` site, reset by any response on either the query-callback or forward path). Crossing the threshold emits an audit log line (`event=CVAR_QUERY_SILENT sid=... name=... ip=... unanswered=... window_s=...`) and a Discord audit embed. **Alert-only** — matches the fleet's audit-first culture; no kick.

Threshold design:
- `ktp_cvar_silent_queries` (default **300**, `0` disables): at the steady cadence of 1 priority query/0.3s + 1 standard query/1.0s (~4.3 q/s), 300 consecutive unanswered queries ≈ **69 seconds of total silence** — over 15 full priority sweeps plus ~3 full standard sweeps with not one answer. Deliberately set past the 60s engine connection timeout so a genuinely dead connection is dropped by the engine before the tripwire fires; a query-blocking client keeps sending move packets, never times out, and always reaches the threshold.
- `ktp_cvar_silent_grace` (default **60.0** seconds after `putinserver`): a still-loading client's queries queue in the reliable channel and answer late — no alert inside the grace window.
- One alert per silent streak (latch clears on the first response or reconnect). Bots and HLTV never enter the query paths, so they can't trip it. Map changes re-fire `putinserver`, resetting counters and the grace anchor.

### Fixed

#### `putinserver` slot-recycle hardening
`client_putinserver` relied on the previous occupant's `client_disconnected` having cleared the per-player enforcement state. It now explicitly clears the enforcement-attempt/filterstuff-warned arrays, the defer bitmasks, the echo-suppression slot, and the new liveness state itself, and removes any tasks still keyed to the slot.

#### Steady-state responses validated twice
Every cvar response message is dispatched twice by the engine: once to the `query_client_cvar` callback (`fn_querycvar`) and immediately after to the `client_cvar_changed` forward (KTPReHLDS `SV_ParseCvarValue2` calls `pfnCvarValue2` then `pfnClientCvarChanged` back-to-back). At steady state both paths ran the trie lookup + validation — the defer bitmask made the duplicate harmless but ~2× the work. `fn_querycvar` now marks the response handled and the forward consumes the mark and skips. The dispatch order is deterministic (same engine call stack), so the dedup can't drop a genuine event; a stale mark (forward suppressed by AMXX's ingame guard) at worst skips one opportunistic validation that the next rotation query repeats. Echo-suppression semantics (`gs_enforcing_cvar`, the accepted 7.27 residual) are unchanged.

## [7.27] - 2026-07-06

Detection-latency + batching fixes from the 2026-07-05 full-stack review (P1 #15 + P2 items).

### Changed

#### Visual-cheat cvars promoted to the priority tier (P1 #15)
`r_fullbright`, `r_lightmap`, `r_luminance`, `gl_monolights`, `gl_nocolors`, `gl_overbright`, `gl_picmip`, and `r_drawentities` moved from the standard rotation (one cvar per second → full cycle ~31s) into the priority rotation. A 31-second worst-case check interval left comfortable room for a scripted toggle-peek-revert (bind fullbright/picmip on, peek, revert before the next check). The priority interval tightens from 0.5s to 0.3s so the enlarged 15-cvar priority set still cycles in ~4.5s — netcode cvars go from a 3.5s to 4.5s cycle while the visual set drops from 31s to 4.5s. Standard rotation shrinks to 23 cvars (~23s cycle). Per-player query load rises from ~3.0/s to ~4.3/s (the engine processes ~1 callback per client frame; well within budget).

### Fixed

#### ~7.5-second zero-enforcement window on every (re)connect
The initial sweep didn't start until 7.5s after `client_putinserver` — repeatable by reconnecting. It now starts at 1.0s, and the sweep queries in a priority-first order (`g_queryOrder`) instead of array-declaration order, so the cvars that matter are checked within the first few seconds rather than potentially sitting at the tail of an ~11s sweep. Queries to a still-loading client queue in the reliable channel and answer once in-game.

#### `/cvar` re-entrancy
Spamming `/cvar` stacked concurrent query chains sharing the single per-player `gi_cvarnumID` counter. A per-player in-progress flag now rejects overlapping sweeps ("check already in progress"); cleared on completion and disconnect.

#### Discord violation batch keyed on SteamID, not slot
New-player detection in the 5-second Discord batch window compared only the slot id — a slot reused within the window (disconnect + fast rejoin) would append the new occupant's violations under the previous player's name/SteamID. Now also compares the stored SteamID (the KTPFileChecker 2.6 pattern; this was the last plugin carrying the slot-keyed variant).

### Docs
- In-file header changelog was stale at 7.22 — entries for 7.23–7.26 reconstructed from git history.

## [7.26] - 2026-04-29

### Fixed

#### `r_glowshellfreq` enforced value `0` → `2.2` (the actual DoD engine default)
Players with the natural game default (`r_glowshellfreq = 2.2`) were being kicked by the cvar checker as "non-compliant" — a false-positive class. The original v7.24 (2026-04-28) rationale claimed enforcing `0` would *"disable the entire glow-shell rendering path that ESPs hooked"*, but that reasoning broke twice:

1. **DoD genuinely uses glow shells on flag carriers** — it's a gameplay element shipped by the game designers. Forcing clients to `0` changed what players see vs. what the game intended (flag-carrier shimmer disappears).
2. **No actual security benefit.** An ESP-script attacker would simply set `r_glowshellfreq = 0` along with everyone else — the previous "0" enforcement neither blocked attackers nor matched legitimate players.

##### What v7.26 actually does
- `gs_calvalues[28]` flipped from `"0"` to `"2.2"` (matches engine default).
- Inline comment block updated: gl_picmip stays at 0 (still defeats picmip wallhack — real security), r_glowshellfreq moves to 2.2 (integrity check only, catches autoexec overrides), r_traceglow stays at 0 (which IS its engine default — was never the issue).

##### Behavior change for players
- **Players at `2.2` (the natural default)**: previously kicked, now compliant. ✅ Improvement.
- **Players at `0` (had set it manually to comply with the broken old rule)**: now kicked. They'll see the new expected value `2.2` in the kick reason and need to remove `r_glowshellfreq 0` from their autoexec / config. One-time friction; resolves itself.
- **Players who never touched it**: no action needed. Default is already 2.2.

##### Source-of-truth references
- KTP CHANGELOG v7.24 itself acknowledged *"Default `r_glowshellfreq=2.2` and `r_traceglow=0`"* — the default value was correctly identified at the time, but enforcement deviated from it for a since-rejected security rationale.
- `KTP_Documentation/KTP Cvar List.md` updated in lockstep — was previously documenting the enforced `0`, now documents `2.2` matching the engine default.
- `docs/CVAR_RECOMMENDATIONS_1000TICK.md` already correctly stated `r_glowshellfreq = 2.2` as the natural default in its 1000-tick research notes.

##### What this does NOT change
- Other anti-cheat measures unchanged. KTPCvarChecker still enforces 30 exact cvars + 7 range cvars covering keyboard-look defeat (cl_pitchspeed et al.), wallhack defeat (gl_picmip), and the rest of the curated set.
- The enforcement loop, priority-cvar scheduling, and Discord alert path are untouched.

---

## [7.25] - 2026-04-28

### Removed — cl_lc and cl_lw out of enforcement (player-asked, no exploit surface)

Both cvars dropped from `gs_cvars[]` and `gs_priority_cvars[]`. Player choice now. Settings persisted from a previous server connection are honored; KTPCvarChecker no longer overwrites them.

#### Why this is safe (deep audit findings)

Source-traced every reference to `cl->lc` and `cl->lw` in KTPReHLDS:

| File:Line | Use | Effect when flag = 0 |
|---|---|---|
| `sv_user.cpp:1209,1228` | `SV_GetTrueOrigin`/`MinMax` early-return | Game DLL gets CURRENT positions (no rewind) |
| `sv_user.cpp:1284,1492` | `SV_MoveOthers`/`SV_RestoreMove` skip | Lag-comp rewind path is bypassed |
| `sv_main.cpp:1343,1371` | `pfnUpdateClientData`/`GetWeaponData` | Client receives non-predicted weapon state |
| `sv_main.cpp:5104` | Per-update flag transmission | Weapon flags sent every frame instead of delta'd |
| `pr_cmds.cpp:1311` | Event playback skip | Local event prediction skipped |

**Every gate keys off the SHOOTER's flags, never the target's.** This means cl_lc=0 / cl_lw=0 is a strict self-handicap:

- The shooter must lead targets by their full latency (no rewind to compensate).
- Other players hitting the cl_lc=0 player still get rewound normally — they're a normal target.
- cl_lw=0 additionally disables client-side weapon prediction (animations + reload feel laggy at non-LAN ping).

**No exploit angles found:**
- Aimbot performance: with cl_lc=0, aimbots that track current position must lead, slightly degrading their effectiveness. Not a meaningful protection but also not an exploit angle the player gains.
- Wallhack/ESP: independent of cl_lc/cl_lw.
- Hit-reg manipulation: self-handicap means harder hits, never easier.
- Server CPU exploit: no — skip-rewind is cheaper than rewind, can't be weaponized.
- Info leak: cl_lw=0 receives more detailed weapon data, but only about YOUR OWN weapon. No other-player info exposed.
- KTPAntiCheat detection: searched the AC repo; zero references to cl_lc / cl_lw / lagcomp / weapon-prediction. AC rules don't depend on these values.

**Legitimate niche use case** (the player's likely angle): cl_lc=0 eliminates "shot through wall" / "behind cover and still died" complaints. With lag comp off, you only hit what you currently see, not what the server rewound. CPL/CAL-era CS 1.6 LAN players sometimes preferred this for "cleaner feel."

Documented trade-off in `KTP Cvar List.md`.

### Changed — cl_cmdrate upper bound 500 → 1000

`gs_altvalues[3]` raised from `"500"` to `"1000"`. Range becomes 100-1000.

#### Why

Player wants to test a new hit-reg formula at higher input resolution. Engine and bandwidth math support it:

- **Bandwidth at cl_cmdrate=1000:** ~60 KB/s (60 byte packets × 1000 pps). `rate=100000` = 100 KB/s, comfortable headroom.
- **CMD_MAXBACKUP=64** (sv_user.h:36) — hard cap on commands per packet, server drops client if exceeded. Doesn't directly limit cmdrate.
- **Server CPU:** KTP-ReHLDS already moved lag-comp from per-cmd to per-packet (~90% overhead reduction at high cmd rates per CHANGELOG line 183). 13 active players × 1000 cmd/s × ~10µs pmove ≈ 13% CPU on cmd processing. Fits comfortably on isolated SCHED_FIFO core.
- **Useful range:** `cl_cmdrate ≤ client_fps`. Setting cl_cmdrate above your fps wastes bandwidth (extra packets carry only backups). Most useful at cmdrate = client fps.

#### Trade-offs documented

- ✅ Tighter input timestamping (1ms windows at cmdrate=1000 vs 10ms at cmdrate=100)
- ✅ Faster reaction-time resolution
- ❌ More UDP packets visible on the wire — slightly more susceptible to packet loss in poor-network scenarios
- ❌ Higher server CPU per client (linear)

### Implementation

- `gs_cvars[]` indices 2,3 (cl_lc, cl_lw) removed. Subsequent indices shift down by 2.
- `gs_calvalues[]` matching entries removed.
- `gs_priority_cvars[]` cl_lc, cl_lw entries removed; `PRIORITY_CVARS_COUNT` 9 → 7.
- `HUD_TAKESSHOTS_INDEX` 16 → 14, `M_PITCH_INDEX` 17 → 15 (downstream constants shift).
- `MIN_MAX_CVAR_START` 33 → 31. Range cvars at logically the same positions, just renumbered.
- `TOTAL_CVARS` 40 → 38. `STANDARD_CVARS_COUNT` unchanged (cl_lc/cl_lw weren't in standard rotation).
- `gs_altvalues[3]` (cl_cmdrate upper bound) "500" → "1000".

Documentation: `KTP_Documentation/KTP Cvar List.md` updated — `cl_lc` and `cl_lw` rows removed from Network & Prediction; `cl_cmdrate` range updated to 100-1000; footer date bumped.

---

## [7.24] - 2026-04-28

### Added — Reverted v7.13 over-removal: 7 cvars re-added

A 2026-04-28 audit of the 25 cvars dropped from enforcement in v7.13 (2026-02-17) found 7 that were misclassified as "engine-limited values" or "not policed." They actually register with `pfnRegisterVariable(name, default, 0)` — flag `0` means no `FCVAR_SERVER`, no engine-side clamp. The client can set them to any value, and several have known competitive-anticheat impact.

Re-added cvars (all to standard rotation, exact-match enforcement = GoldSrc default):

| Cvar | Value | Family | Defeats |
|---|---|---|---|
| `cl_pitchspeed` | `225` | Keyboard-look | Alias-based no-recoil (vertical) |
| `cl_yawspeed` | `210` | Keyboard-look | Alias-based no-recoil (horizontal) |
| `cl_anglespeedkey` | `0.67` | Keyboard-look | Speed multiplier amplification |
| `m_side` | `0.8` | Mouse | Side-strafe sensitivity scaling |
| `gl_picmip` | `0` | Visual | Wall-texture-flattening wallhack class |
| `r_glowshellfreq` | `0` | Visual | Glow-shell ESP overlay (CS 1.6 lineage) |
| `r_traceglow` | `0` | Visual | Glow-shell trace-debug ESP companion |

### Why — keyboard-look cvars (alias-based no-recoil scripts)

Standard HL1 community pattern, not theoretical:

```
alias _norec1 "+lookdown; wait; -lookdown; alias norec _norec2"
alias _norec2 "wait; alias norec _norec1"
bind mouse1 "+attack; norec"
```

While `mouse1` is held, the alias loop pulses `+lookdown` every other tick. Each pulse moves the view down by `cl_pitchspeed × frametime` degrees. With `cl_pitchspeed=9999` and 1000fps, a single tick pulse rotates the view ~10° downward — enough to cancel the upward `punchangle` kick of full-auto weapons (BAR, MP44, MG42). Clamped values (`225`/`210`/`0.67`) make the per-tick correction too small to keep up with sustained recoil. `m_side` is added for completeness — same family, freely settable, default 0.8.

### Why — visual cvars (wallhack / ESP defenses)

- **`gl_picmip`** at high values (e.g. 16) reduces wall textures to solid-color blocks. Player models render with their own texture set, producing high-contrast silhouettes against terrain. Documented CS 1.6 wallhack, applies to DoD via shared engine. Modern client builds clamp 0-3 but not all do — defense-in-depth at the server side.
- **`r_glowshellfreq`** + **`r_traceglow`** historically used in CS 1.6 ESP scripts to render entity glow shells through walls. Default `r_glowshellfreq=2.2` and `r_traceglow=0`; we enforce both at 0 to disable the entire glow-shell rendering path that ESPs hooked.

### Why these were missed in v7.13

The v7.13 cleanup framed the keyboard-look trio as "engine-limited" alongside actually-clamped cvars (`cl_upspeed`, `cl_movespeedkey` — those have FCVAR_SERVER OR are clamped server-side via `sv_maxspeed`). The visual trio (`gl_picmip` / `r_glowshellfreq` / `r_traceglow`) was framed as "settings we don't police" — that was a classification mistake, not a defensible decision. ~~Mouse-aim cvars (`m_pitch`, `sensitivity`, `m_yaw`) were properly enforced~~ — **CORRECTED 2026-08-11: only `m_pitch` was ever enforced.** `sensitivity` and `m_yaw` appear nowhere in `gs_cvars[]`, were never in the v7.13 removal list, and no entry in this changelog ever adds or removes them — so far as the record shows they were never enforced at all. The keyboard-look companions and visual exploit cvars slipped through. 🔻 **This sentence had a real cost and is why it is struck rather than rewritten.** It is the belief that let the 2026-04-28 audit of the v7.13 removals stop at the 25 removed cvars without asking whether the mouse-aim family outside that set was covered — a false claim about coverage reading as coverage. Extending enforcement to those two is a separate decision (blind-audit item 5.4) and is NOT implied by this correction. Surfaced 2026-04-27 in CrankinHawg-suspicion analysis; live as anti-cheat regression for ~2.5 months.

### Other v7.13-removed cvars audited and confirmed safe to leave out (18)

`gl_affinemodels`, `gl_alphamin`, `gl_cull`, `gl_dither`, `gl_keeptjunctions`, `gl_lightholes`, `gl_palette_tex`, `gl_round_down` (8 visual nothings), `cl_fixtimerate`, `cl_gaitestimation` (self-harm only), `cl_upspeed`, `cl_movespeedkey` (server-side `sv_maxspeed`/consistency clamps cover these), `ambient_fade`, `ambient_level` (atmospheric audio), `lookspring`, `lookstrafe` (legacy mouselook settings), `r_bmodelinterp` (door interpolation), `r_wadtextures` (texture loading flag). Either no exploit surface, fully covered by server-side clamps, or already engine-clamped.

### Implementation

- Inserted into `gs_cvars[]` at indices 25-31, between `s_show` and `texgamma` (preserves `HUD_TAKESSHOTS_INDEX=16` and `M_PITCH_INDEX=17`).
- `MIN_MAX_CVAR_START` shifted `26 → 33`. Range cvars (`lightgamma`, `cl_bob`, `cl_updaterate`, etc.) keep their original ordering, just renumbered.
- `TOTAL_CVARS` `33 → 40`. `STANDARD_CVARS_COUNT` `24 → 31`.
- Standard rotation (1.0s/cvar), so each cvar is checked every ~31s. These are static cvars — an attacker can't pulse them between shots faster than the rotation catches them.

---

## [7.23] - 2026-04-25

### Added
- **Adopted `ktp_version_reporter` shared include** — plugin now registers with the fleet-wide `amx_ktp_versions` rcon command (ADMIN_RCON). Output reports name, version, build SHA, and build time alongside other KTP plugins. See KTPMatchHandler 0.10.116 for the canary release introducing the include.
- **`compile.sh` build-info generation** — git short SHA + UTC build time written to `build_info.inc` and baked into the .amxx so the rcon command can report what's actually deployed.

### Changed
- **Standardized version constants** — `gs_PLUGIN`/`gs_VERSION`/`gs_AUTHOR` `new const[]` array declarations replaced with `PLUGIN_NAME`/`PLUGIN_VERSION`/`PLUGIN_AUTHOR` `#define`s (matching every other KTP plugin's convention). All call sites updated; `gs_year` retained since it's a separate concept. No behavioral change.

### Fixed
- **`compile.sh` temp-dir nesting bug** — `cp -r src dst` accumulates nested `include/` dirs on re-runs when `dst` already exists. Pre-existing files survived from the first-ever run; new shared includes added later landed at `/tmp/ktpbuild/include/include/...` and were invisible to amxxpc. Added `rm -rf "$TEMP_BUILD"` before `mkdir`. Discovered while wiring `ktp_version_reporter`.

## [7.22] - 2026-03-24

### Enforcement Range Adjustments

**Changed:**
- **`rate` locked to exact 100000** — Was enforced as a range (100000-1000000). Now only `rate 100000` is accepted. Players with higher or lower rate values are auto-corrected.
- **`cl_updaterate` max lowered from 200 to 120** — Matches `sv_maxupdaterate 120` on all servers. Client.dll clamps to 102 anyway, so the effective ceiling is unchanged.
- **`ex_interp` range adjusted to 0.01-0.05** — Floor raised from 0 to 0.01 (1 update frame minimum buffer, prevents teleporting on any jitter). Max raised from 0.03 to 0.05 (accommodates SA/EU players with 140-160ms ping).

**Removed:**
- **`cl_smoothtime` enforcement removed** — Purely cosmetic cvar controlling own-character position smoothing. No competitive advantage; removing enforcement lets players choose their own smoothing preference (recommended 0.05 or 0 in Discord guide).
- **`lightgamma` floor adjusted from 1.81 to 1.809** — IEEE 754 float precision: `1.81` is stored as `1.80999994` and reported back as `1.809` by the engine. The old floor flagged correctly-set players as violations. `1.809` matches the engine's actual representation while still protecting against the <1.81 crash threshold.

---

## [7.21] - 2026-03-24

### Performance Optimizations

**Changed:**
- **Cvar name → index lookup via Trie** — `client_cvar_changed` and `fn_querycvar` used a 34-entry `equal()` linear scan on every callback (~43 callbacks/sec/player at steady state). Replaced with a `TrieGetCell` hash lookup — O(1) instead of O(n). Single highest-impact optimization.
- **m_pitch check uses integer index compare** — `fn_checkvalues` compared `equal(s_CVARNAME, gs_pitch)` (string walk) on every exact-cvar validation. Now compares `cvar_index == M_PITCH_INDEX` (single instruction).
- **hud_takesshots check uses integer index compare** — Same pattern in `fn_enforce_cvar`. `equal(s_CVARNAME, "hud_takesshots")` → `cvar_index == HUD_TAKESSHOTS_INDEX`.
- **Disconnect enforcement reset uses dirty flag** — The 34-iteration `gi_enforce_attempts`/`gb_filterstuff_warned` reset loop in `client_disconnected` now only runs if `gb_hasViolations[id]` is true. Most disconnecting players have zero violations, making the common case O(1).
- **Removed per-player `log_amx` on monitoring start** — Eliminated 24 `log_amx` disk writes per match connect wave (one per player × 24 players).

---

## [7.20] - 2026-03-13

### Discord Task Leak Fix + Cleanup

**Fixed:**
- **Discord task leak caused doubled notifications on player interleave** — `set_task(DISCORD_DELAY, "send_discord_violations")` used no task ID, so switching players created orphaned timer tasks that fired independently, sending duplicate Discord embeds. Now uses per-player task IDs (`id + TASK_DISCORD_SEND`) with proper `remove_task` on player switch and disconnect.
- **`task_deferred_enforce` accessed `g_deferPending` with invalid index on bounds-check failure** — Error path cleared bitmask arrays using the same `id` that just failed the `id < 1 || id > MAX_PLAYERS` bounds check, risking out-of-bounds array access. Now returns immediately without array access.
- **Chat/Discord announcements showed rate cvars with unnecessary decimals** — Network cvars (rate, cl_cmdrate, cl_updaterate) displayed as `100000.000` instead of `100000`. Now uses integer format for values >= 100, matching the enforcement path.
- **Stale comment on standard cvar rotation** — Comment said "every 10 seconds" but actual interval is 1.0s per `STANDARD_CHECK_INTERVAL`.

**Changed:**
- `fn_enforce_cvar` from `public` to `stock` — only called internally, never by the engine.

**Removed:**
- Unused `s_CALVALUE` parameter from `fn_enforce_cvar` — was passed through but never read inside the function.
- Dead `g_deferToAlt` array — only existed to reconstruct the removed `s_CALVALUE` parameter.

---

## [7.19] - 2026-03-12

### Deferred Enforcement Queue + Cleanup

**Fixed:**
- **Multiple simultaneous cvar violations dropped — only last enforced** — `defer_enforcement` used a single-slot per player: `remove_task` + `set_task(0.0)` overwrote the deferred data for each new violation, so only the last one was enforced. During initial 34-cvar scan or when multiple violations arrived in the same frame, earlier violations were silently lost. Replaced with per-cvar bitmask queue (`g_deferPending` + `g_deferPendingHi`) that accumulates all pending violations and processes them all in `task_deferred_enforce`.
- **`gi_cvarnum` global loop variable could be clobbered** — Used as the loop variable in `client_cvar_changed`, but being a global meant any reentrant or interleaved call path could clobber it. Replaced with a local `ci` variable.
- **`fn_loopquery` missing bot/HLTV guard** — If a bot or HLTV index somehow reached `fn_loopquery`, `query_client_cvar` would be called against a non-real client. Added `is_user_bot()` and `is_user_hltv()` checks.
- **`fn_msginitial` missing bounds check** — No `id < 1 || id > MAX_PLAYERS` guard, unlike all other task handlers. Added for consistency.
- **Hardcoded m_pitch values not using constants** — Enforcement path used `"-0.022"` and `"0.022"` string literals instead of `inverse_p` and `gs_calvalues[17]`. Now uses the defined constants.
- **Stale comments on monitoring intervals** — Function comments said "every 2 seconds" and "every 10 seconds" but actual intervals are 0.5s and 1.0s respectively. Fixed to match `PRIORITY_CHECK_INTERVAL` and `STANDARD_CHECK_INTERVAL` defines.
- **Discord description buffer too small** — 1024-byte buffer could truncate when 32 violations are buffered (~85 chars each). Increased to 2048 bytes.
- **`ktp_discord.inc` embed description truncated to 383 chars** — `escapedDesc[384]` local buffer in `ktp_discord_send_embed_audit` silently truncated descriptions beyond 383 chars. Now uses global `g_ktpDiscordEscapedBuf[2200]`. Payload buffer increased to 3072. (ktp_discord.inc v1.3.4)
- **Removed dead `QUERIES_PER_TICK` define** — Unused leftover from pre-rotation design.
- **`gs_altvalues` index guard in `task_deferred_enforce`** — Added `idx >= MIN_MAX_CVAR_START` check before accessing `gs_altvalues[idx - MIN_MAX_CVAR_START]` to prevent negative index if `g_deferToAlt` is unexpectedly true for an exact cvar.
- **Hardcoded m_pitch index 17 → `M_PITCH_INDEX` constant** — Explicit define prevents silent breakage if cvar array is reordered.

**Also recompiled:** KTPMatchHandler, KTPAdminAudit, KTPFileChecker, KTPHLTVRecorder (pick up ktp_discord.inc v1.3.4 buffer increase).

---

## [7.18] - 2026-03-12

### Enforcement Accuracy Fixes

**Fixed:**
- **Rate limiter dropped legitimate cvar events** — The 1-second per-player gate in `client_cvar_changed` silently swallowed real cvar change events if multiple cvars changed within the same second. Removed — deferred enforcement already prevents frame freezes, making the rate limit unnecessary and harmful.
- **Enforcement flag suppressed ALL cvar events** — `gb_enforcing_cvar` was a simple boolean that blocked the next `client_cvar_changed` callback regardless of which cvar it was for. If the enforcement response for cvar A arrived and a real change to cvar B happened in the same window, B was silently dropped. Changed to store the enforced cvar name and only skip events matching that specific cvar.
- **Uncached `get_cvar_num("ktp_match_competitive")` on every enforcement** — Called on every `fn_enforce_cvar` invocation for `hud_takesshots` checks. Now cached via `get_cvar_pointer` at init with lazy re-cache if KTPMatchHandler loads after CvarChecker.
- **Dead store in `fn_msginitial`** — `get_user_name()` result stored to `gs_logname` but never used in the function. Removed.
- **`bool:` tag mismatch on `equal()` return** — `new bool:is_pitch = equal(...)` caused compiler warning 213 since `equal()` returns untagged cell. Changed to untagged `new is_pitch`.

---

## [7.17] - 2026-02-25

### Range Cvar Correction Fix + Buffer Safety

**Fixed:**
- Range cvars (lightgamma, cl_updaterate, cl_cmdrate, rate, ex_interp, fps_max, etc.) always corrected to **minimum** even when player's value exceeded the **maximum**. Now correctly corrects to the nearest bound.
- Hardcoded buffer sizes in `get_configsdir()` (32 instead of 63) and `formatex()` (57 instead of 127) replaced with `charsmax()` to use actual buffer capacity
- Header comment version/date now matches `#define VERSION`

---

## [7.16] - 2026-02-20

### Index Out of Bounds Fix

**Fixed:**
- Runtime error 4 (index out of bounds) in `fn_loopquery` / `fn_query_parallel` when player ID equals `MAX_PLAYERS`

**Changed:**
- All player arrays from `[MAX_PLAYERS]` to `[MAX_PLAYERS + 1]` (off-by-one safety)

**Added:**
- Bounds checks (`id < 1 || id > MAX_PLAYERS`) on all functions receiving player ID parameter

---

## [7.15] - 2026-02-19

### Performance Fix: Deferred Enforcement

**Fixed:**
- `clc_cvarvalue2` opcode processing taking 160-185ms (froze entire server frame) — enforcement logic (`get_user_*`, `log_amx`, `client_print` broadcast) was running inside the opcode handler

**Changed:**
- Enforcement now deferred to next frame via `set_task(0.0)` — opcode handler returns immediately
- Monitoring tasks use offset task IDs (`id + 1000`, `id + 2000`) to avoid collisions
- One query per tick per rotation (engine only processes ~1 cvar callback per frame)
- Priority rotation: 1 cvar every 0.5s (full cycle: 4.5s for 9 cvars)
- Standard rotation: 1 cvar every 1.0s (full cycle: 25s for 25 cvars)

**Removed:**
- Debug `log_amx` calls in `fn_querycvar`, `fn_firstcomplete`, `fn_start_monitoring`

---

## [7.14] - 2026-02-18

### fps_max Range Update

**Changed:**
- `fps_max` max raised from 500 to 750

---

## [7.13] - 2026-02-17

### Cvar List Cleanup

**Removed:**
- 25 unnecessary cvars: rendering tweaks (`gl_affinemodels`, `gl_alphamin`, `gl_cull`, `gl_dither`, `gl_keeptjunctions`, `gl_lightholes`, `gl_palette_tex`, `gl_picmip`, `gl_round_down`), engine-limited values (`cl_fixtimerate`, `cl_gaitestimation`, `cl_upspeed`, `cl_anglespeedkey`, `cl_movespeedkey`, `cl_yawspeed`, `cl_pitchspeed`, `ambient_fade`, `ambient_level`), and settings we don't police (`lookspring`, `lookstrafe`, `m_side`, `r_bmodelinterp`, `r_glowshellfreq`, `r_traceglow`, `r_wadtextures`)
- Total enforced cvars reduced from 59 to 34 (26 exact + 8 range)

**Changed:**
- Priority cvar list updated: replaced `cl_yawspeed`, `cl_pitchspeed`, `lightgamma`, `cl_bob` with `cl_pitchdown`, `cl_pitchup`, `cl_lc`, `cl_lw`
- `cl_updaterate` max raised from 120 to 200 (matches `sv_maxupdaterate`)
- Startup message now uses `TOTAL_CVARS` constant instead of hardcoded count

---

## [7.12] - 2026-02-04

### Dynamic hud_takesshots Enforcement

**Changed:**
- `hud_takesshots` enforcement now only applies to competitive matches (`.ktp`, `.ktpOT`)
- Non-competitive modes (`.12man`, `.scrim`, `.draft`) no longer require `hud_takesshots 1`
- Uses `ktp_match_competitive` cvar from KTPMatchHandler to determine match type

---

## [7.11] - 2026-01-20

### Discord Notification Grouping

**Changed:**
- Group all cvar violations into single Discord embed per player (reduces spam)
- `ktp_cvar_discord` now defaults to 1 (enabled)

**Added:**
- Track repeat violations with count per cvar in grouped notification
- 5-second timed window before sending grouped notification

---

## [7.10] - 2026-01-13

### Discord Branding

**Changed:**
- Discord embed title now includes `:ktp:` emoji for consistent branding

---

## [7.9] - 2026-01-09

### Discord Toggle

**Added:**
- `ktp_cvar_discord` cvar (0/1) to disable Discord logging for cvar checker
- Default: 0 (disabled) to reduce Discord webhook spam
- Separate from global discord.ini - allows disabling cvar spam specifically

**Changed:**
- Startup message now shows Discord status

---

## [7.8] - 2025-12-31

### Debug Log Cleanup

**Removed:**
- `fn_msginitial()` debug logging (no longer needed)

---

## [7.7] - 2025-12-21

### Shared Discord Config

**Changed:**
- Now uses `ktp_discord.inc` for Discord integration
- Config now loaded from `discord.ini` (same as other KTP plugins)

**Removed:**
- `fcos_discord_enabled` cvar (replaced by shared config)
- `fcos_discord_webhook` cvar (replaced by shared config)
- Direct webhook code (replaced with relay pattern)

---

## [7.6] - 2025-12-20

### cl_filterstuffcmd Detection and Warning System

**Added:**
- Enforcement attempt tracking per player per cvar
- After 3 failed enforcement attempts, shows detailed warning message
- Warning explains `cl_filterstuffcmd` must be 0 and how to fix
- Announcement to all players when enforcement is blocked

**Changed:**
- Stops spamming chat after warning is shown once per cvar
- Resets tracking when player fixes the cvar value

---

## [7.5] - 2025-12-08

### Timing Fixes and Debug Improvements

**Fixed:**
- `fn_servermessage()` timing - Moved from `plugin_init()` to `plugin_cfg()` for proper execution order

**Added:**
- Debug logging in `fn_msginitial()` for troubleshooting
- Safety check with `is_user_connected()` before client prints

**Changed:**
- Initial check message now uses `print_chat` instead of `print_console` for better visibility
- Updated "KTPAMXX" branding to "KTP AMX" for consistent naming

---

## [7.4] - 2025-12-02

### Priority-Based Periodic Monitoring

**Added:**
- Periodic cvar query system - Actively queries cvars to trigger ReHLDS callback
- Priority cvar system - 9 critical cvars (m_pitch, cl_yawspeed, cl_pitchspeed, lightgamma, cl_bob, cl_updaterate, cl_cmdrate, rate, ex_interp) checked every 2 seconds
- Standard cvar rotation - 50 cvars rotated every 10 seconds (5 per check)

**Performance:**
- ~5 queries/sec per player (~160 q/s for 32 players)
- ~0.4% CPU usage
- ~8 KB/s network overhead
- Priority cvars detected in <2s, standard cvars in <100s (worst case)

**Clarified:**
- System is query-based, not truly "real-time" - Server must actively query cvars

---

## [7.3] - 2025-11-29

### Bug Fixes and Chat Announcements

**Fixed:**
- Cvar callback async bug - Now looks up cvar by name instead of relying on counter

**Added:**
- Chat announcements - All players see when a cvar is corrected

---

## [7.2] - 2025-11-28

### Cvar List Updates

**Added:**
- `gl_round_down` (value: 3)
- `hud_takesshots` (value: 1)

**Fixed:**
- `lightgamma` min changed from 1.7 to 1.81
- `ex_interp` max changed from 0.04 to 0.03

**Stats:**
- Total cvars: 59 (51 exact + 8 ranges)

---

## [7.1] - 2025-11-28

### Pure Enforcement + Discord

**Added:**
- `/cvar` command - Manual cvar check for all players
- Discord webhook logging - Optional real-time violation alerts via cURL
- `fcos_discord_enabled` cvar - Enable/disable Discord logging
- `fcos_discord_webhook` cvar - Discord webhook URL

**Removed:**
- All punishment cvars (warnings, name change, slay, kick, ban)
- All punishment logic - Pure enforcement only

**Stats:**
- Simplified to 443 lines (down from 1047 lines in v6.5)

---

## [7.0] - 2025-11-28

### MAJOR UPGRADE: Real-time Detection with KTPAMXX

**Added:**
- `client_cvar_changed()` forward - Real-time detection for ALL cvars via KTPAMXX

**Performance:**
- 100% real-time detection - No periodic polling overhead
- Instant detection - < 1 second response time for all cvars

**Requirements Changed:**
- Now requires KTPAMXX (Modified AMX Mod X with pfnClientCvarChanged callback)
- Now requires KTP-ReHLDS (Custom ReHLDS with client cvar callback support)

**Removed:**
- Backwards compatibility (no ReAPI support, no periodic polling)
- Kick/ban system - Enforcement only (no punishments)
- MOTD warnings - Console logging only
- Priority tier system - Not needed with real-time detection

---

## [6.5] and Earlier

See git history for older versions featuring:
- Backwards compatibility with standard AMX Mod X
- ReAPI support for cvar querying
- Punishment systems (warnings, kicks, bans)
- MOTD warning displays
- Priority tier detection system

---

## Credits

**Current Maintainer:**
- **Nein_** ([@afraznein](https://github.com/afraznein)) - KTPAMXX integration, pure enforcement redesign, Discord webhooks

**Original Author:**
- **SubStream** - Force CAL Open Settings (fcos)
- Original Thread: http://forums.alliedmods.net/showthread.php?t=25927
