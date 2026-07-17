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
