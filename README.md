# KTP Cvar Checker

**Version 7.28** - Priority-based client cvar enforcement for competitive Day of Defeat servers.

Pure enforcement anti-cheat that monitors 38 client cvars using periodic queries through KTPAMXX's `client_cvar_changed` callback. Automatically corrects violations with optional Discord alerts. No punishments — just auto-correction and logging.

Originally based on SubStream's "Force CAL Open Settings" (fcos).

## Architecture

```
KTP Cvar Checker: queries cvars periodically
     |  Priority (15 cvars: netcode + visual-cheat): 1 cvar every 0.3s
     |  Standard (23 cvars): 1 cvar every 1.0s
     v
Game Client: responds with current cvar value
     v
KTP-ReHLDS: pfnClientCvarChanged callback
     v
KTPAMXX: client_cvar_changed forward
     v
KTP Cvar Checker: validates, enforces, logs, Discord alert
```

## Detection Speed

| Type | Count | Interval | Worst-Case Detection |
|------|-------|----------|---------------------|
| Priority cvars | 15 | 1 per 0.3s | ~4.5 seconds |
| Standard cvars | 23 | 1 per 1.0s | ~23 seconds |
| Initial check | All 38 | 1 per 0.3s, starts 1.0s after connect, priority-first | priority ≤ ~5.5s, full ~12.4s |

Performance: ~4.3 queries/sec per player (the engine processes ~1 cvar callback per client frame).

## Features

- **Priority-based monitoring** — Netcode + visual-cheat cvars (fullbright/picmip class) cycle every ~4.5 seconds
- **Automatic correction** — Forces correct values immediately on violation
- **Discord notifications** — Grouped violations per player with 5-second batching window
- **cl_filterstuffcmd detection** — Warns players after 3 failed enforcement attempts
- **Silent-client tripwire** — A client answering no cvar queries at all (the total-query-blocking bypass) trips an audit log line + Discord alert after ~69s of total silence; alert-only, never a kick. Residual: a client selectively blocking only some cvar names is not covered (per-cvar staleness counters are the follow-up if that class ever appears)
- **Dynamic hud_takesshots** — Only enforced during competitive matches (`.ktp`, `.ktpOT`)
- **Manual check** — `/cvar` command triggers full parallel query
- **Complete audit trail** — AMX logs with SteamID, name, IP, cvar, values

## Monitored Cvars (38 total)

**Priority (15):** `m_pitch`, `cl_pitchdown`, `cl_pitchup`, `cl_updaterate`, `cl_cmdrate`, `rate`, `ex_interp`, plus the visual-cheat set: `r_fullbright`, `r_lightmap`, `r_luminance`, `gl_monolights`, `gl_nocolors`, `gl_overbright`, `gl_picmip`, `r_drawentities`

**Standard (23):** Remaining graphics, audio, movement, and gameplay cvars — see source for full list.

**Range cvars (7):** `lightgamma` (1.809-3), `cl_bob` (0-0.011), `cl_updaterate` (100-120), `cl_cmdrate` (100-1000), `rate` (locked 100000), `ex_interp` (0.009-0.05), `fps_max` (60-750).

## Requirements

- **KTPAMXX** — Custom AMX Mod X with `client_cvar_changed` forward
- **KTP-ReHLDS** — Custom ReHLDS with `pfnClientCvarChanged` callback
- Not compatible with standard AMX Mod X or ReHLDS

## Installation

1. Compile: `amxxpc ktp_cvar.sma -oktp_cvar.amxx`
2. Copy `ktp_cvar.amxx` to `addons/ktpamx/plugins/`
3. Add to `plugins.ini`
4. Configure `discord.ini` for Discord alerts (optional, shared with other KTP plugins)
5. Restart server or change map

## Configuration

| Cvar | Default | Description |
|------|---------|-------------|
| `ktp_cvar_discord` | `1` | Enable/disable Discord violation alerts |
| `ktp_cvar_silent_queries` | `300` | Consecutive unanswered queries before the silent-client tripwire fires (~69s at the steady ~4.3 q/s cadence; past the 60s engine timeout so dead connections drop first). `0` disables |
| `ktp_cvar_silent_grace` | `60.0` | Seconds after putinserver before the tripwire may fire (still-loading clients answer queued queries late) |

Discord integration uses the shared `discord.ini` config. See [KTP Discord Relay](https://github.com/afraznein/DiscordRelay) for setup.

## Related Projects

- [KTP-ReHLDS](https://github.com/afraznein/KTPReHLDS) — Engine with pfnClientCvarChanged callback
- [KTPAMXX](https://github.com/afraznein/KTPAMXX) — AMX Mod X with client_cvar_changed forward
- [KTP Discord Relay](https://github.com/afraznein/DiscordRelay) — HTTP proxy for Discord

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Credits

- **Nein_** ([@afraznein](https://github.com/afraznein)) — KTPAMXX integration, pure enforcement redesign
- **SubStream** — Original Force CAL Open Settings ([AlliedMods thread](http://forums.alliedmods.net/showthread.php?t=25927))

## License

GPL v2 — See [LICENSE](LICENSE).
