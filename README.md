# KTP Cvar Checker

**Version 7.36** - Priority-based client cvar enforcement for competitive Day of Defeat servers.

Pure enforcement anti-cheat that monitors 37 client cvars using periodic queries through KTPAMXX's `client_cvar_changed` callback. Automatically corrects violations with optional Discord alerts. No punishments — just auto-correction and logging.

Originally based on SubStream's "Force CAL Open Settings" (fcos).

## Architecture

```
KTP Cvar Checker: queries cvars periodically
     |  Priority (15 cvars: netcode + visual-cheat): 1 cvar every 0.3s
     |  Standard (22 cvars): 1 cvar every 1.0s
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
| Standard cvars | 22 | 1 per 1.0s | ~22 seconds |
| Initial check | All 37 | 1 per 0.3s, starts 1.0s after connect, priority-first | priority ≤ ~5.5s, full ~12.1s |

Performance: ~4.3 queries/sec per player (the engine processes ~1 cvar callback per client frame).

## Features

- **Priority-based monitoring** — Netcode + visual-cheat cvars (fullbright/picmip class) cycle every ~4.5 seconds
- **Automatic correction** — Forces correct values immediately on violation
- **Discord notifications** — Grouped violations per player with 5-second batching window
- **cl_filterstuffcmd detection** — Warns players after 3 failed enforcement attempts
- **Silent-client tripwire** — A client answering no cvar queries at all trips an audit alert after ~69s of total silence, and a client selectively blocking one rotation TIER (e.g. only the 0.3s visual tier) trips a tier-silence alert after ~90s (v7.29). Both alert-only, never a kick. Remaining residual: blocking a single cvar NAME while answering the rest of its tier is not individually tracked (per-name staleness counters if that class ever appears)
- **Dynamic hud_takesshots** — Only enforced during competitive matches (`.ktp`, `.ktpOT`)
- **Lag-comp flag observation (v7.33)** — `cl_lc`/`cl_lw` are read from userinfo (never queried, never enforced — the v7.25 permitting decision stands) and logged only on exception or transition: `LAGCOMP_OFF`, `LAGCOMP_CHANGED`, plus a once-per-map-load `LAGCOMP_SAMPLER_OK` liveness line. The engine skips lag compensation entirely when either flag is 0 — and an absent userinfo key reads as 0 — so an affected player must lead by their full ping; the log makes that population visible without re-enforcing
- **Netcode observation (v7.34)** — `rate` and `cl_updaterate` are read from userinfo (never queried, never enforced) and logged on change as `NETOBS_CHANGED`, with a once-per-map `NETOBS_SAMPLER_OK` liveness line. The engine assigns these to `cl->netchan.rate` and `cl->next_messageinterval` — the client's bandwidth cap and packet cadence. The logged value is what the client **requested**; the engine clamps `rate` and floors `cl_updaterate` at 10 before either applies. Note `ex_interp` cannot be observed this way: it is not a transmitted userinfo field, so it is reachable only via the cvar query path where it is already monitored
- **Deferred userinfo sampling (v7.36)** — `client_infochanged` itself reads nothing: reading userinfo inside that forward advances KTP-ReHLDS's 4-slot rotating info-value buffer while AMXX core still holds a pointer into it for the player's name, and enough reads corrupt every plugin's `get_user_name()` view of the player. The forward only marks the slot; the 0.3s priority rotation performs the actual reads, so a mid-session edit logs within one tick rather than immediately. The permanent close for the corruption class is core-side (KTPAMXX#84, which copies the name before the forward); this deferral keeps the plugin safe on older cores and out of the shared read budget after it
- **Interp pairing check (v7.35)** — `NETOBS_INTERP_LOW` when `ex_interp` is below `1/cl_updaterate`, `NETOBS_INTERP_OK` on recovery. The enforced ranges (`cl_updaterate` 100-120, `ex_interp` 0.009-0.05) let a client satisfy both rules while the pair is inconsistent, because every cvar is otherwise validated in isolation. Costs no extra queries — `ex_interp` is already a priority cvar — and only transitions log
- **Observe-only cvars (v7.35)** — `cl_nopred`, `cl_cmdbackup`, `cl_nodelta` queried once at settle and logged as `NETOBS_CVAR`. Held outside `gs_cvars` on purpose: they are observed, never enforced, and never counted toward the silent-client tripwire
- **Manual check** — `/cvar` (say or say_team) triggers a full 37-cvar sweep, priority-first (~12.1s)
- **Complete audit trail** — AMX logs with SteamID, name, IP, cvar, values

## Monitored Cvars (37 total)

**Priority (15):** `m_pitch`, `cl_pitchdown`, `cl_pitchup`, `cl_updaterate`, `cl_cmdrate`, `rate`, `ex_interp`, plus the visual-cheat set: `r_fullbright`, `r_lightmap`, `r_luminance`, `gl_monolights`, `gl_nocolors`, `gl_overbright`, `gl_picmip`, `r_drawentities`

**Standard (22):** `cl_bobcycle`, `cl_bobup`, `cl_showevents`, `fastsprites`, `gl_clear`, `gl_d3dflip`, `gl_nobind`, `gl_playermip`, `hud_takesshots`, `r_drawviewmodel`, `r_dynamic`, `s_show`, `cl_pitchspeed`, `cl_yawspeed`, `cl_anglespeedkey`, `m_side`, `r_glowshellfreq`, `r_traceglow`, `texgamma`, `lightgamma`, `cl_bob`, `fps_max`

**Range cvars (7):** `lightgamma` (1.809-3), `cl_bob` (0-0.011), `cl_updaterate` (100-120), `cl_cmdrate` (100-1000), `rate` (locked 100000), `ex_interp` (0.009-0.05), `fps_max` (60-750).

## Requirements

- **KTPAMXX** — Custom AMX Mod X with `client_cvar_changed` forward
- **KTP-ReHLDS** — Custom ReHLDS with `pfnClientCvarChanged` callback
- **Shared includes** — `ktp_discord.inc` and `ktp_version_reporter.inc` from the KTPAMXX include tree (not in this repo)
- Not compatible with standard AMX Mod X or ReHLDS

## Installation

1. Build: `bash compile.sh` (uses the KTPAMXX compiler and writes to `compiled/`)
2. Copy `compiled/ktp_cvar.amxx` to `addons/ktpamx/plugins/`. The repo ships no
   prebuilt `.amxx`; build output is gitignored so a stale binary can't be
   mistaken for the current one.
3. Copy `data/lang/ktp_cvar.txt` to `addons/ktpamx/data/lang/` — `compile.sh` stages only the
   plugin, and without the dictionary the startup banner prints raw `%L` keys
4. Add to `plugins.ini`
5. Configure `discord.ini` for Discord alerts (optional, shared with other KTP plugins)
6. Restart server or change map

## Configuration

| Cvar | Default | Description |
|------|---------|-------------|
| `ktp_cvar_discord` | `1` | Enable/disable Discord violation alerts |
| `ktp_cvar_silent_queries` | `300` | Consecutive unanswered queries before the silent-client tripwire fires (~69s at the steady ~4.3 q/s cadence; past the 60s engine timeout so dead connections drop first). `0` disables |
| `ktp_cvar_silent_grace` | `60.0` | Seconds after putinserver before the tripwire may fire (still-loading clients answer queued queries late) |
| `ktp_cvar_silent_tier_secs` | `90.0` | Seconds of per-tier silence before the tier tripwire fires (30-query floor so it can't fire off a stall). `0` disables the tier tripwire; the global one keeps working |

If `<configsdir>/ktp_cvar.cfg` exists it is `exec`'d at plugin init, for server-side
overrides. Check it first when server cvar state looks unexplained.

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
