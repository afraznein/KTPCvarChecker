# KTP Cvar Checker

**Version 7.16** - Priority-based client cvar enforcement for competitive Day of Defeat servers.

Pure enforcement anti-cheat that monitors 34 client cvars using periodic queries through KTPAMXX's `client_cvar_changed` callback. Automatically corrects violations with optional Discord alerts. No punishments — just auto-correction and logging.

Originally based on SubStream's "Force CAL Open Settings" (fcos).

## Architecture

```
KTP Cvar Checker: queries cvars periodically
     |  Priority (9 cvars): every 2 seconds
     |  Standard (25 cvars): rotated every 10 seconds (5 per check)
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
| Priority cvars | 9 | Every 2s | < 2 seconds |
| Standard cvars | 25 | 5 per 10s | ~50 seconds |
| Initial check | All 34 | Parallel batches of 8 | ~2 seconds |

Performance: ~5 queries/sec per player (~160 q/s for 32 players, ~0.4% CPU, ~8 KB/s network).

## Features

- **Priority-based monitoring** — Critical cvars (movement, network) checked every 2 seconds
- **Automatic correction** — Forces correct values immediately on violation
- **Discord notifications** — Grouped violations per player with 5-second batching window
- **cl_filterstuffcmd detection** — Warns players after 3 failed enforcement attempts
- **Dynamic hud_takesshots** — Only enforced during competitive matches (`.ktp`, `.ktpOT`)
- **Manual check** — `/cvar` command triggers full parallel query
- **Complete audit trail** — AMX logs with SteamID, name, IP, cvar, values

## Monitored Cvars (34 total)

**Priority (9):** `m_pitch`, `cl_pitchdown`, `cl_pitchup`, `cl_updaterate`, `cl_cmdrate`, `rate`, `ex_interp`, `cl_lc`, `cl_lw`

**Standard (25):** Graphics, audio, movement, and gameplay cvars — see source for full list.

**Range cvars (8):** `lightgamma` (1.81-3.0), `cl_smoothtime` (0-0.1), `cl_bob` (0-0.011), `cl_updaterate` (100-200), `cl_cmdrate` (100-500), `rate` (100k-1M), `ex_interp` (0-0.03), `fps_max` (60-750).

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
