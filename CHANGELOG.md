# Changelog

All notable changes to KTP Cvar Checker will be documented in this file.

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
