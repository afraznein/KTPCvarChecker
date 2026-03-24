# Changelog

All notable changes to KTP Cvar Checker will be documented in this file.

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
