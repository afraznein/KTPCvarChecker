# KTP Cvar Checker

**Client-side cvar enforcement system for competitive Half-Life servers**

Originally based on SubStream's "Force CAL Open Settings" (fcos), heavily modified and optimized for KTP competitive infrastructure.

---

## 📋 Overview

KTP Cvar Checker is a two-plugin system that monitors and enforces client-side cvar values to prevent cheating and ensure fair competitive play. The system continuously checks player cvars and applies progressive punishments for violations.

---

## 🔧 Plugin Components

### **ktp_cvar.sma** - Core Enforcement Engine
**Version:** 5.2
**Purpose:** Real-time client cvar monitoring and enforcement

#### Key Features:
- **57 monitored cvars** covering graphics, audio, and gameplay settings
- **Real-time detection** via ReHLDS `RH_SV_CheckUserInfo` hook (when available)
- **Polling fallback** for standard HLDS/ReHLDS (7.5+ second intervals)
- **Progressive punishment system**:
  - Automatic cvar correction
  - Warning MOTD display
  - Name changes
  - Slaying
  - Kick/ban
- **Float precision handling** for accurate cvar value comparisons
- **Graceful platform degradation** (works on base AMX, better with ReHLDS)

#### Monitored Cvar Categories:
- **Graphics**: OpenGL settings (gl_*, r_*) to prevent wallhacks/brightening
- **Audio**: Sound settings to prevent audio advantage
- **Mouse**: m_pitch, m_side to prevent movement exploits
- **Network**: cl_updaterate, cl_cmdrate, rate for fair play
- **Special ranges**: lightgamma (1.7-3.0), ex_interp (0-0.04), fps_max (60-500)

#### How It Works:
1. **Initial Check**: 7.5 seconds after player connects
2. **Continuous Monitoring**:
   - **With ReHLDS**: Instant detection when player changes userinfo
   - **Without ReHLDS**: Random polling (15-60 second intervals)
3. **Violation Handling**:
   - Force correct value immediately
   - Log violation to AMX logs
   - Track attempt count
   - Apply configured punishments
4. **Special Cases**:
   - `m_pitch`: Allows both positive (0.022) and negative (-0.022) values
   - Range cvars (8 total): Allow values within min/max bounds

#### Configuration CVARs:
```
fcos_warn "1"                      // Enable warning MOTD
fcos_attempt_num_warn "5"          // Violations before warning
fcos_repeat_warning "1"            // Show warning repeatedly
fcos_change_name "0"               // Enable name change punishment
fcos_attempt_num_namechange "0"    // Violations before name change
fcos_slay "0"                      // Enable slay punishment
fcos_attempt_num_slay "0"          // Violations before slay
fcos_repeat_slaying "0"            // Slay repeatedly
fcos_kick_or_ban "0"               // 0=none, 1=kick, 2=ban
fcos_attempt_num_kickorban "0"     // Violations before kick/ban
fcos_ban_time "0"                  // Ban duration in minutes
fcos_use_amx_bans "0"              // Use amx_ban instead of banid
```

---

### **ktp_cvarconfig.sma** - Admin Configuration Interface
**Version:** 3.2
**Purpose:** In-game admin menu for configuring ktp_cvar settings

#### Key Features:
- **Interactive admin menu** (`/fcosconfig` or `amx_fcosconfig`)
- **Real-time configuration** without server restart
- **Persistent settings** saved to `ktp_cvar.cfg`
- **10 configurable options** per page
- **Preview before apply** to verify settings

#### Admin Commands:
- `/fcosconfig` - Open configuration menu (admin only)
- `amx_fcosconfig` - Console command variant

#### Menu Options:
1. Enable/disable warning MOTD
2. Set violation count for warnings
3. Enable repeat warnings
4. Enable name change punishment
5. Set violation count for name changes
6. Enable slay punishment
7. Set violation count for slays
8. Enable repeat slaying
9. Set kick/ban mode (0=off, 1=kick, 2=ban)
10. Set violation count for kick/ban
11. Set ban duration
12. Enable AMX bans

#### Configuration File:
Settings are saved to: `addons/amxmodx/configs/ktp_cvar.cfg`

Example:
```cfg
fcos_warn "1"
fcos_attempt_num_warn "5"
fcos_repeat_warning "1"
fcos_kick_or_ban "2"
fcos_attempt_num_kickorban "15"
fcos_ban_time "60"
```

---

## 🚀 Installation

### Requirements:
- AMX Mod X 1.9+ (1.10 recommended)
- Optional: ReHLDS for real-time detection
- Optional: ReAPI module (automatically detected)

### Installation Steps:

1. **Compile plugins**:
   ```bash
   amxxpc ktp_cvar.sma
   amxxpc ktp_cvarconfig.sma
   ```

2. **Copy to server**:
   ```
   addons/amxmodx/plugins/ktp_cvar.amxx
   addons/amxmodx/plugins/ktp_cvarconfig.amxx
   ```

3. **Enable in plugins.ini**:
   ```ini
   ktp_cvar.amxx
   ktp_cvarconfig.amxx
   ```

4. **Configure settings** (optional):
   - Create `addons/amxmodx/configs/ktp_cvar.cfg`
   - Or use `/fcosconfig` menu in-game

5. **Restart server**

---

## 📊 Platform Compatibility

### Base AMX ModX (HLDS)
- ✅ All cvar checks via polling
- ✅ Progressive punishment system
- ✅ Automatic cvar correction
- ⚠️ 7.5-60 second detection delay

### Standard ReHLDS
- ✅ Everything from Base AMX
- ✅ Same polling system as base

### KTP-ReHLDS + ReAPI
- ✅ Everything from above
- ✅ **Real-time detection** via `RH_SV_CheckUserInfo` hook
- ✅ Instant response when players change cvars
- ✅ No polling delay

---

## 🔍 Monitored Cvars

### Exact Value Checks (49 cvars):
```
ambient_fade, ambient_level, cl_bobcycle, cl_bobup, cl_fixtimerate,
cl_gaitestimation, fastsprites, gl_affinemodels, gl_alphamin, gl_clear,
gl_cull, gl_d3dflip, gl_dither, gl_keeptjunctions, gl_lightholes,
gl_monolights, gl_nobind, gl_nocolors, gl_overbright, gl_palette_tex,
gl_picmip, gl_playermip, r_bmodelinterp, r_drawentities, r_drawviewmodel,
r_dynamic, r_fullbright, r_glowshellfreq, r_lightmap, r_traceglow,
r_wadtextures, texgamma, r_luminance, s_show, cl_showevents,
cl_anglespeedkey, cl_lc, cl_lw, cl_upspeed, lookspring, lookstrafe,
cl_movespeedkey, m_pitch, m_side, cl_pitchdown, cl_pitchup,
cl_yawspeed, cl_pitchspeed, cl_mousegrab
```

### Range Value Checks (8 cvars):
```
lightgamma       (1.7 - 3.0)
cl_smoothtime    (0 - 0.1)
cl_bob           (0 - 0.011)
cl_updaterate    (100 - 120)
cl_cmdrate       (100 - 500)
rate             (100000 - 1000000)
ex_interp        (0 - 0.04)
fps_max          (60 - 500)
```

---

## 📝 Logging

All violations are logged to AMX logs:
```
L MM/DD/YYYY - HH:MM:SS: [KTP Cvar Checker] STEAMID:0:X:XXXXXX | PlayerName | 1.2.3.4 | Invalid cvar_name: 0.5 (Required: 1.0)
```

---

## 🎯 Usage Examples

### For Server Admins:

**Configure punishment system:**
1. Join server as admin
2. Type `/fcosconfig`
3. Select options from menu
4. Settings save automatically

**Manual configuration:**
Edit `addons/amxmodx/configs/ktp_cvar.cfg`:
```cfg
// Warn at 3 violations, kick at 10
fcos_warn "1"
fcos_attempt_num_warn "3"
fcos_kick_or_ban "1"
fcos_attempt_num_kickorban "10"
```

### For Players:

**Check if monitoring is active:**
- Console: `ktp_cvar_version`
- Should see: "KTP Cvar Checker version 5.2"

**If you get violations:**
- Check your config.cfg for restricted cvars
- Reset to defaults: `exec userconfig.cfg`
- Most violations auto-correct

---

## 🔧 Technical Details

### ReHLDS Integration:
```pawn
// Detects ReHLDS at runtime
if (is_rehlds()) {
    RegisterHookChain(RH_SV_CheckUserInfo, "OnUserInfoChange", false)
    // Real-time detection enabled
}
```

### Cvar Query System:
```pawn
// Queries 57 cvars at 0.15s intervals (8.55 seconds total)
// Then schedules next check at random 15-60 seconds
query_client_cvar(id, cvar_name, "callback")
```

### Float Precision:
```pawn
// Uses 0.00005 tolerance for float comparisons
if (floatabs(player_value - required_value) <= 0.00005) {
    // Value is acceptable
}
```

---

## 📜 Version History

### v5.2 (2025-10-31)
- Added ReHLDS real-time userinfo detection
- Optimized for AMX ModX 1.10
- Refactored code organization
- Added comprehensive constants

### v3.2 (2025-10-31) - ktp_cvarconfig
- Full code refactoring
- Modernized menu system
- Cached pcvar pointers
- Fixed file writing bugs

---

## 🔗 Related Projects

- **[KTP Match Handler](https://github.com/afraznein/KTPMatchHandler)** - Match management system
- **[KTP-ReHLDS](https://github.com/afraznein/KTP-ReHLDS)** - Enhanced ReHLDS with real-time hooks
- **[KTP-ReAPI](https://github.com/afraznein/KTP-ReAPI)** - ReAPI with KTP extensions

---

## 📝 Credits

**Current Maintainer:** Nein_
**Original Author:** SubStream (Force CAL Open Settings)
**Original Thread:** http://forums.alliedmods.net/showthread.php?t=25927

**License:** GPL v2

---

## 🤝 Contributing

This is part of the KTP competitive infrastructure. For issues or improvements:
- Test thoroughly before submitting changes
- Maintain backward compatibility
- Follow existing code style
- Document new features

---

## ⚠️ Notes

- **False positives possible** with unusual hardware/drivers
- **Test configuration** in non-competitive environment first
- **Ban carefully** - manual review recommended
- **Some cvars** are legitimate player preference (ex_interp range)
- **Network cvars** may vary based on connection quality
