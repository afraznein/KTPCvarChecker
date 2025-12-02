# KTP Cvar Checker

**Priority-based client-side cvar enforcement system for competitive Day of Defeat servers**

Pure enforcement anti-cheat system that monitors 59 client cvars using a priority-based query system to prevent graphics exploits, wallhacks, sound advantages, and movement cheats. Features periodic monitoring via KTPAMXX's `client_cvar_changed` callback, automatic correction, comprehensive logging, and optional Discord webhooks.

Originally based on SubStream's "Force CAL Open Settings" (fcos), heavily modified and optimized for KTP competitive infrastructure.

---

## 🎯 Purpose

Competitive first-person shooters require strict enforcement of client settings to prevent unfair advantages:
- ❌ Graphics exploits (r_fullbright, gl_* settings for wallhacks)
- ❌ Audio advantages (s_show to see sound origins)
- ❌ Movement exploits (m_pitch/m_side manipulation)
- ❌ Network advantages (cl_updaterate, rate manipulation)
- ❌ Manual admin monitoring is time-consuming and inconsistent
- ❌ Players can change cvars mid-match without detection

**KTP Cvar Checker enforces fair play automatically:**
- ✅ Monitors 59 critical cvars continuously
- ✅ **Priority-based detection** - Critical cvars checked every 2 seconds, others rotated every 10 seconds
- ✅ **Automatic cvar correction** on every violation
- ✅ **Complete audit trail** in AMX logs
- ✅ **Optional Discord webhooks** for violation alerts
- ✅ **Pure enforcement** - no punishments, just auto-correction
- ✅ **Low overhead** - ~5 queries/second per player (~0.4% CPU, ~8 KB/s network)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│  KTP Cvar Checker (AMX Plugin)                  │
│  - Periodically queries cvars via query_client_cvar() │
│    * Priority cvars: every 2 seconds (9 cvars)  │
│    * Standard cvars: rotating every 10s (50 cvars) │
└────────────────┬────────────────────────────────┘
                 │ svc_sendcvarvalue2 message
                 ↓
┌─────────────────────────────────────────────────┐
│  Game Client                                    │
│  - Receives cvar query from server              │
│  - Sends back current value                     │
└────────────────┬────────────────────────────────┘
                 │ clc_cvarvalue2 response packet
                 ↓
┌─────────────────────────────────────────────────┐
│  KTP-ReHLDS (Modified Engine)                   │
│  - SV_ParseCvarValue2() receives response       │
│  - Calls pfnClientCvarChanged callback          │
└────────────────┬────────────────────────────────┘
                 │ C++ callback
                 ↓
┌─────────────────────────────────────────────────┐
│  KTPAMXX (Modified AMX Mod X)                   │
│  - Receives pfnClientCvarChanged from ReHLDS    │
│  - Fires client_cvar_changed() forward to       │
│    loaded AMX plugins                           │
└────────────────┬────────────────────────────────┘
                 │ AMXX Forward
                 ↓
┌─────────────────────────────────────────────────┐
│  KTP Cvar Checker (AMX Plugin)                  │
│  - client_cvar_changed() callback triggered     │
│  - Rate limiting (1 check/sec per player)       │
│  - Validates cvar against whitelist (59 cvars)  │
│  - Detects: m_pitch is "0.05" (required: "0.022") │
│  - Forces correct value via client_cmd          │
│  - Logs violation to AMX logs                   │
│  - Sends Discord webhook (if enabled)           │
│  - Announces correction to all players          │
└─────────────────────────────────────────────────┘
```

**Detection Speed:**
- **Priority cvars (9)**: Checked every **2 seconds** (movement/network exploits)
- **Standard cvars (50)**: Rotated every **10 seconds** (5 cvars per check, full cycle ~100 seconds)
- **Initial check**: **~4 seconds** (parallel batches of 8 queries)
- **Rate limiting**: Max 1 validation per second per player (prevents callback spam)
- **Performance**: **~5 queries/second per player** (~160 q/s for 32 players)

---

## ✨ Key Features

### 🔍 Priority-Based Cvar Monitoring

**59 Monitored Cvars (9 Priority + 50 Standard):**

**Priority Cvars (checked every 2 seconds):**
```
m_pitch             (0.022 or -0.022 - prevents pitch hacks)
cl_yawspeed         (210 - prevents turn speed exploits)
cl_pitchspeed       (225 - prevents pitch speed exploits)
lightgamma          (range: 1.81-3.0 - prevents extreme brightness)
cl_bob              (range: 0-0.011 - prevents view bob exploits)
cl_updaterate       (range: 100-120 - network fairness)
cl_cmdrate          (range: 100-500 - command rate limits)
rate                (range: 100000-1000000 - connection rate)
ex_interp           (range: 0-0.03 - interpolation settings)
```

**Standard Cvars (rotated every 10 seconds):**

**Graphics Anti-Cheat (33 cvars):**
```
gl_affinemodels, gl_alphamin, gl_clear, gl_cull, gl_d3dflip,
gl_dither, gl_keeptjunctions, gl_lightholes, gl_monolights,
gl_nobind, gl_nocolors, gl_overbright, gl_palette_tex, gl_picmip,
gl_playermip, gl_round_down, r_bmodelinterp, r_drawentities,
r_drawviewmodel, r_dynamic, r_fullbright, r_glowshellfreq,
r_lightmap, r_traceglow, r_wadtextures, texgamma, r_luminance,
lightgamma (range: 1.81-3.0)
```

**Audio Anti-Cheat (2 cvars):**
```
s_show              (0 only - prevents sound origin visualization)
ambient_fade, ambient_level
```

**Movement Anti-Cheat (7 cvars):**
```
m_side              (0.8 - prevents strafe exploits)
cl_pitchdown        (89 - pitch down limit)
cl_pitchup          (89 - pitch up limit)
cl_anglespeedkey    (0.67 - angle speed key multiplier)
lookspring          (0 - look spring)
lookstrafe          (0 - look strafe)
cl_movespeedkey     (0.3 - movement speed key multiplier)
```

**Gameplay Settings (10 cvars):**
```
cl_bobcycle, cl_bobup, cl_smoothtime (range: 0-0.1),
cl_fixtimerate, cl_gaitestimation, fastsprites,
fps_max (range: 60-500), cl_lc, cl_lw, cl_upspeed,
cl_showevents, cl_mousegrab, hud_takesshots
```

### ⚡ Priority-Based Periodic Monitoring

**How It Works:**
```pawn
/**
 * Priority-based cvar monitoring system
 * Actively queries cvars on a schedule to trigger detection
 */

// Start monitoring after initial check (10 seconds after connect)
public fn_start_monitoring(id) {
    // Check priority cvars every 2 seconds
    set_task(PRIORITY_CHECK_INTERVAL, "fn_check_priority_cvars", id, _, _, "b")

    // Rotate through standard cvars every 10 seconds
    set_task(STANDARD_CHECK_INTERVAL, "fn_check_standard_cvars", id, _, _, "b")
}

// Query all 9 priority cvars
public fn_check_priority_cvars(id) {
    for (new i = 0; i < PRIORITY_CVARS_COUNT; i++) {
        query_client_cvar(id, gs_priority_cvars[i], "fn_querycvar")
    }
}

// Rotate through 5 standard cvars per check
public fn_check_standard_cvars(id) {
    for (new i = 0; i < 5; i++) {
        query_client_cvar(id, gs_standard_cvars[index], "fn_querycvar")
        index++
    }
    // Reset when reaching end of list
    if (index >= STANDARD_CVARS_COUNT) index = 0
}

// Callback fires when client responds (via KTPAMXX's client_cvar_changed)
public client_cvar_changed(id, const cvar[], const value[]) {
    // Validate and enforce if needed
    fn_validate_and_enforce(id, cvar, value)
}
```

**Performance Features:**
- ✅ **Priority-based queries** - Critical cvars checked more frequently
- ✅ **Efficient rotation** - Standard cvars spread across time
- ✅ **Callback-driven validation** - Uses KTPAMXX forward for responses
- ✅ **Rate-limited** - Max 1 validation/sec per player (prevents callback spam)
- ✅ **Recursion-safe** - Enforcement flag prevents infinite loops
- ✅ **Pre-converted values** - All expected values converted to floats once on init
- ✅ **Low overhead** - ~5 queries/sec per player, ~0.4% CPU usage

### 🔨 Automatic Enforcement

**Pure Enforcement Mode:**
```pawn
public fn_enforce_cvar(id, const cvar[], Float:player_value, Float:correct_value) {
    // Set enforcement flag to prevent recursion
    gb_enforcing_cvar[id] = true

    // Force correct value on client
    if (is_pitch && (player_value < 0.0))
        client_cmd(id, "m_pitch -0.022")
    else if (correct_value >= 100.0)
        client_cmd(id, "%s %d", cvar, floatround(correct_value))
    else
        client_cmd(id, "%s %.3f", cvar, correct_value)

    // Log violation
    log_amx("[KTP Cvar] %s | %s | %s | Invalid %s: %.3f (Required: %.3f)",
        steamid, name, ip, cvar, player_value, correct_value)

    // Send Discord webhook if enabled
    if (get_pcvar_num(gp_discord_enabled))
        fn_send_discord_webhook(...)
}
```

**Enforcement Features:**
- ✅ **Automatic correction** - Forces correct value immediately
- ✅ **No punishments** - Pure enforcement only (no warnings, kicks, bans)
- ✅ **Complete logging** - AMX logs include SteamID, name, IP, cvar, values
- ✅ **Discord webhooks** - Optional real-time violation alerts
- ✅ **Recursion prevention** - Enforcement flag prevents infinite loops

### 📊 Discord Webhook Integration

**Configuration:**
```cfg
// Enable Discord logging
fcos_discord_enabled "1"
fcos_discord_webhook "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"
```

**Webhook Payload (Discord Embed):**
```json
{
  "embeds": [{
    "title": "CVAR Violation Detected",
    "color": 15158332,
    "fields": [
      {"name": "Player", "value": "PlayerName", "inline": true},
      {"name": "SteamID", "value": "STEAM_0:1:12345", "inline": true},
      {"name": "IP", "value": "192.168.1.100", "inline": true},
      {"name": "Cvar", "value": "r_fullbright", "inline": true},
      {"name": "Player Value", "value": "1.000", "inline": true},
      {"name": "Correct Value", "value": "0.000", "inline": true}
    ],
    "footer": {"text": "Server Name"},
    "timestamp": "2025-11-28T14:32:15Z"
  }]
}
```

**Features:**
- ✅ **Rich embeds** - Color-coded violation alerts
- ✅ **Complete context** - Player info, server name, timestamp
- ✅ **Non-blocking** - Uses cURL in background (no lag)
- ✅ **Proper escaping** - JSON-safe string handling
- ✅ **ISO timestamps** - Discord-compatible time format

### 🎯 Smart Value Handling

**Float Precision:**
```pawn
// Uses 0.00005 tolerance for float comparisons
#define FLOAT_PRECISION 0.00005

if (floatabs(player_value - required_value) <= FLOAT_PRECISION) {
    // Value is acceptable
}
```

**Range Checks:**
```pawn
// lightgamma must be between 1.81 and 3.0
if (1.81 <= player_value <= 3.0) {
    // Valid
}

// ex_interp must be between 0 and 0.03
if (0.0 <= player_value <= 0.03) {
    // Valid
}
```

**Special Case - m_pitch:**
```pawn
// Allows both positive and negative (inverted mouse)
if (value == 0.022 || value == -0.022) {
    // Valid (inverted mouse is legitimate)
}
```

### 📝 Complete Audit Trail

**AMX Log Format:**
```
L 11/28/2025 - 14:32:15: [KTP Cvar Checker] STEAM_0:1:12345678 | PlayerName | 192.168.1.100 | Invalid r_fullbright: 1.000 (Required: 0.000)
L 11/28/2025 - 14:32:18: [KTP Cvar Checker] STEAM_0:1:12345678 | PlayerName | 192.168.1.100 | Invalid gl_overbright: 2.000 (Required: 0.000)
```

**Log Information:**
- ✅ Timestamp
- ✅ SteamID
- ✅ Player name
- ✅ IP address
- ✅ Cvar name and values (actual vs required)

---

## 🔧 Plugin Components

### ktp_cvar.sma - Core Enforcement Engine

**Version:** 7.4 (2025-12-02)
**File Size:** ~630 lines
**Purpose:** Priority-based client cvar monitoring using periodic queries + KTPAMXX's client_cvar_changed callback

**Key Functions:**
```pawn
public plugin_init()                     // Initialize plugin, register cvars/commands
public client_cvar_changed(id, cvar, val)// KTPAMXX forward - triggered by query responses
public client_putinserver(id)            // Start initial check on player connect
public fn_start_monitoring(id)           // Start periodic monitoring system
public fn_check_priority_cvars(id)       // Query 9 priority cvars (every 2s)
public fn_check_standard_cvars(id)       // Rotate through 50 standard cvars (every 10s)
public fn_loopquery(id)                  // Initial parallel batch queries
public fn_query_parallel(id)             // Send 8 queries simultaneously
public fn_querycvar(id, cvar, value)     // Callback for query responses
public fn_checkvalues(...)               // Validate exact value cvars
public fn_checkaltallowed(...)           // Validate range cvars
public fn_enforce_cvar(...)              // Force correct value + log + Discord + announce
public cmd_manual_check(id)              // /cvar command handler
public fn_send_discord_webhook(...)      // Send Discord embed
```

**Detection Methods:**
- **Priority monitoring**: 9 critical cvars queried every 2 seconds (movement/network)
- **Standard rotation**: 50 cvars rotated every 10 seconds (5 per check)
- **Initial check**: Parallel query batches (8 at a time, ~4 seconds total)
- **Manual check**: `/cvar` command triggers full parallel query check
- **Callback validation**: All responses validated via `client_cvar_changed()` forward

**Requirements:**
- **KTPAMXX** (Modified AMX Mod X with `client_cvar_changed` forward)
- **KTP-ReHLDS** (Modified ReHLDS with `pfnClientCvarChanged` callback)
- **No backwards compatibility** - Will not work on standard AMX/ReHLDS

---

## 🚀 Installation

### Prerequisites

- **KTPAMXX** - Modified AMX Mod X fork with `client_cvar_changed` forward
- **KTP-ReHLDS** - Modified ReHLDS with `pfnClientCvarChanged` callback implementation
- **⚠️ NOT compatible** with standard AMX Mod X or ReHLDS

### Step 1: Compile Plugin

```bash
# Navigate to AMX scripting directory
cd addons/amxmodx/scripting

# Compile plugin
amxxpc ktp_cvar.sma -oktp_cvar.amxx
```

### Step 2: Install Plugin

```bash
# Copy compiled plugin to plugins directory
cp ktp_cvar.amxx ../plugins/
```

### Step 3: Enable Plugin

Edit `addons/amxmodx/configs/plugins.ini`:
```ini
; KTP Cvar Checker - Anti-cheat enforcement system
ktp_cvar.amxx
```

### Step 4: Configure Settings (Optional)

Create `addons/amxmodx/configs/ktp_cvar.cfg`:
```cfg
// Discord webhook (optional)
fcos_discord_enabled "0"                         // 1 = enabled
fcos_discord_webhook ""                          // Your Discord webhook URL
```

### Step 5: Restart Server

```bash
# Restart server or reload plugin
amx_plugins reload ktp_cvar.amxx
```

### Step 6: Verify Installation

```
// In server console or player console
ktp_cvar_version

// Should output:
// KTP Cvar Checker version 7.3

// Check AMX logs on startup
// Should show:
// [KTP Cvar Checker] KTPAMXX REAL-TIME detection for ALL 59 cvars!
// [KTP Cvar Checker] Enforcement: Auto-correct + console logging + Discord webhooks
```

---

## 📋 Monitored Cvars Reference

### Exact Value Cvars (51)

| Cvar | Required | Purpose |
|------|----------|---------|
| `ambient_fade` | `100` | Ambient sound fade distance |
| `ambient_level` | `0.3` | Ambient sound level |
| `cl_bobcycle` | `0.8` | View bob cycle |
| `cl_bobup` | `0.5` | View bob up amount |
| `cl_fixtimerate` | `7.5` | Fixed timerate |
| `cl_gaitestimation` | `1` | Gait estimation |
| `fastsprites` | `0` | Standard sprite rendering |
| `gl_affinemodels` | `0` | Affine texture mapping |
| `gl_alphamin` | `0.25` | Minimum alpha value |
| `gl_clear` | `0` | Prevents transparent walls |
| `gl_cull` | `1` | Backface culling |
| `gl_d3dflip` | `0` | D3D flip |
| `gl_dither` | `1` | Dithering |
| `gl_keeptjunctions` | `1` | Keep T-junctions |
| `gl_lightholes` | `1` | Light holes |
| `gl_monolights` | `0` | Monochrome lights |
| `gl_nobind` | `0` | Texture binding |
| `gl_nocolors` | `0` | Color rendering |
| `gl_overbright` | `0` | Prevents brightness exploits |
| `gl_palette_tex` | `1` | Palette textures |
| `gl_picmip` | `0` | Texture quality |
| `gl_playermip` | `0` | Player model texture quality |
| `gl_round_down` | `3` | Texture rounding |
| `r_bmodelinterp` | `1` | Brush model interpolation |
| `r_drawentities` | `1` | Draw entities |
| `r_drawviewmodel` | `1` | Draw viewmodel (weapon) |
| `r_dynamic` | `1` | Dynamic lighting |
| `r_fullbright` | `0` | Prevents wallhack-like lighting |
| `r_glowshellfreq` | `2.2` | Glow shell frequency |
| `r_lightmap` | `0` | Prevents texture exploits |
| `r_traceglow` | `0` | Trace glow |
| `r_wadtextures` | `0` | WAD texture loading |
| `texgamma` | `2` | Texture gamma |
| `r_luminance` | `0` | Luminance |
| `s_show` | `0` | Prevents sound origin visualization |
| `cl_showevents` | `0` | Show client events |
| `cl_anglespeedkey` | `0.67` | Angle speed key multiplier |
| `cl_lc` | `1` | Lag compensation on |
| `cl_lw` | `1` | Client-side weapons on |
| `cl_upspeed` | `320` | Up/down movement speed |
| `lookspring` | `0` | Look spring |
| `lookstrafe` | `0` | Look strafe |
| `cl_movespeedkey` | `0.3` | Movement speed key multiplier |
| `m_pitch` | `0.022` or `-0.022` | Standard mouse pitch (inverted allowed) |
| `m_side` | `0.8` | Mouse side movement |
| `cl_pitchdown` | `89` | Pitch down limit |
| `cl_pitchup` | `89` | Pitch up limit |
| `cl_yawspeed` | `210` | Yaw speed |
| `cl_pitchspeed` | `225` | Pitch speed |
| `hud_takesshots` | `1` | HUD screenshot |
| `cl_mousegrab` | `1` | Mouse grab |

### Range Value Cvars (8)

| Cvar | Min | Max | Purpose |
|------|-----|-----|---------|
| `lightgamma` | `1.81` | `3.0` | Prevent extreme brightness |
| `cl_smoothtime` | `0.0` | `0.1` | Movement smoothing |
| `cl_bob` | `0.0` | `0.011` | View bobbing |
| `cl_updaterate` | `100` | `120` | Network update rate |
| `cl_cmdrate` | `100` | `500` | Command rate |
| `rate` | `100000` | `1000000` | Connection rate |
| `ex_interp` | `0.0` | `0.03` | Entity interpolation |
| `fps_max` | `60` | `500` | FPS limiter |

---

## 🎮 Usage

### For Server Admins

**Configure Discord Webhooks (Optional):**

1. Create a Discord webhook in your server
2. Edit `ktp_cvar.cfg`:
   ```cfg
   fcos_discord_enabled "1"
   fcos_discord_webhook "https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN"
   ```
3. Restart server or reload plugin
4. Violations will now appear as rich embeds in Discord

**Monitor Violations:**
```bash
# Check AMX logs
cat addons/amxmodx/logs/L1128.log | grep "KTP Cvar"

# Look for patterns of violations
# Investigate players with multiple violations
```

**Manual Cvar Check:**
- Players can type `/cvar` in chat to trigger manual check
- Runs same parallel query check as initial connect
- Useful for verifying configuration

### For Players

**Check If Monitoring Is Active:**
```
// In console
ktp_cvar_version

// Should see:
// KTP Cvar Checker version 7.3
```

**If You Receive Violations:**

1. **Check your config.cfg** for restricted cvars
2. **Reset to defaults**:
   ```
   exec userconfig.cfg
   exec config.cfg
   ```
3. **Common problematic cvars**:
   ```
   // Remove or fix these in config.cfg:
   r_fullbright "1"      // Change to "0"
   gl_overbright "1"     // Change to "0"
   s_show "1"            // Change to "0"
   ```
4. **All violations auto-correct** - plugin forces correct values immediately
5. **Persistent violations** indicate script/cheat interference

**Legitimate Settings:**
- `m_pitch` can be negative (`-0.022`) for inverted mouse
- Network cvars (`rate`, `cl_updaterate`) may need adjustment for your connection
- `ex_interp` between 0 and 0.03 is allowed for latency compensation

### For Competitive Match Admins

**Pre-Match Setup:**
```cfg
// Recommended competitive settings
fcos_discord_enabled "1"              // Enable Discord alerts
fcos_discord_webhook "YOUR_WEBHOOK"   // Your Discord webhook URL
```

**During Match:**
- Monitor AMX logs for violations
- Check Discord channel for real-time alerts
- All violations are auto-corrected immediately
- No player punishment - pure enforcement only

---

## 🔗 Related KTP Projects

### **KTP Competitive Infrastructure:**

**🔧 Engine Layer:**
- **[KTP-ReHLDS](https://github.com/afraznein/KTPReHLDS)** - Custom engine with pfnClientCvarChanged callback
- **[KTPAMXX](https://github.com/afraznein/KTPAMXX)** - Custom AMX Mod X with client_cvar_changed forward

**🎮 Plugin Layer:**
- **[KTP Match Handler](https://github.com/afraznein/KTPMatchHandler)** - Match management with pause
- **[KTP Cvar Checker](https://github.com/afraznein/KTPCvarChecker)** - This project

**🌐 Supporting Services:**
- **[KTP Discord Relay](https://github.com/afraznein/DiscordRelay)** - HTTP proxy for Discord
- **[KTP Score Parser](https://github.com/afraznein/KTPScoreBot-ScoreParser)** - Match score parsing
- **[KTP Weekly Matches](https://github.com/afraznein/KTPScoreBot-WeeklyMatches)** - Schedule management
- **[KTP HLTV Kicker](https://github.com/afraznein/KTPHLTVKicker)** - HLTV management

---

## 📝 Version History

### v7.4 (2025-12-02) - Priority-Based Periodic Monitoring
- ✅ **ADDED: Periodic cvar query system** - Actively queries cvars to trigger ReHLDS callback
- ✅ **ADDED: Priority cvar system** - 9 critical cvars (m_pitch, cl_yawspeed, cl_pitchspeed, lightgamma, cl_bob, cl_updaterate, cl_cmdrate, rate, ex_interp) checked every 2 seconds
- ✅ **ADDED: Standard cvar rotation** - 50 cvars rotated every 10 seconds (5 per check)
- 📊 **PERFORMANCE: ~5 queries/sec per player** (~160 q/s for 32 players, ~0.4% CPU, ~8 KB/s network)
- 📊 **DETECTION: Priority cvars in <2s, standard cvars in <100s** (worst case)
- 🔧 **CLARIFIED: System is query-based, not truly "real-time"** - Server must actively query cvars

### v7.3 (2025-11-29) - Bug Fixes and Chat Announcements
- 🔧 **FIXED: Cvar callback async bug** - Now looks up cvar by name instead of relying on counter
- ✅ **ADDED: Chat announcements** - All players see when a cvar is corrected

### v7.2 (2025-11-28) - Cvar List Updates
- ✅ **ADDED: gl_round_down** - Value: 3
- ✅ **ADDED: hud_takesshots** - Value: 1
- 🔧 **FIXED: lightgamma min** - Changed from 1.7 to 1.81
- 🔧 **FIXED: ex_interp max** - Changed from 0.04 to 0.03
- 📊 **Total cvars: 59** (51 exact + 8 ranges)

### v7.1 (2025-11-28) - Pure Enforcement + Discord
- ✅ **ADDED: /cvar command** - Manual cvar check for all players
- ✅ **ADDED: Discord webhook logging** - Optional real-time violation alerts via cURL
- ✅ **ADDED: fcos_discord_enabled cvar** - Enable/disable Discord logging
- ✅ **ADDED: fcos_discord_webhook cvar** - Discord webhook URL
- 🗑️ **REMOVED: All punishment cvars** - No more warnings, name change, slay, kick, ban
- 🗑️ **REMOVED: All punishment logic** - Pure enforcement only (auto-correct + logging)
- 📉 **Simplified: 443 lines** (down from 1047 lines in v6.5)

### v7.0 (2025-11-28) - MAJOR UPGRADE: Real-time Detection with KTPAMXX
- ⚡ **ADDED: client_cvar_changed() forward** - Real-time detection for ALL cvars via KTPAMXX
- 🚀 **PERFORMANCE: 100% real-time detection** - No periodic polling overhead
- 🚀 **PERFORMANCE: Instant detection** - < 1 second response time for all cvars
- ⚠️ **REQUIRES: KTPAMXX** - Custom AMX Mod X fork with pfnClientCvarChanged callback
- ⚠️ **REQUIRES: KTP-ReHLDS** - Custom ReHLDS with client cvar callback support
- 🗑️ **REMOVED: Backwards compatibility** - No ReAPI support, no periodic polling
- 🗑️ **REMOVED: Kick/ban system** - Enforcement only (no punishments)
- 🗑️ **REMOVED: MOTD warnings** - Console logging only
- 🗑️ **REMOVED: Priority tier system** - Not needed with real-time detection

### v6.5 and Earlier
- See git history for older versions with backwards compatibility, ReAPI support, and punishment systems

---

## 🐛 Troubleshooting

### Plugin Not Loading

**Problem:** Plugin fails to load or shows errors

**Solutions:**
- ✅ Verify you're running **KTPAMXX** (not standard AMX Mod X)
- ✅ Verify you're running **KTP-ReHLDS** (not standard ReHLDS)
- ✅ Check AMX logs for compile errors
- ✅ Ensure plugin is in `plugins/` directory
- ✅ Ensure plugin is enabled in `plugins.ini`

### Cvars Not Being Checked

**Problem:** No violations detected even with obvious cheats

**Solutions:**
- ✅ Verify plugin is loaded: `amx_plugins`
- ✅ Check AMX logs for errors
- ✅ Test with known violation: `r_fullbright 1` in console
- ✅ Type `/cvar` to trigger manual check
- ✅ Check logs for "client_cvar_changed" callbacks

### Slow or No Detection

**Problem:** Violations detected slowly or not at all

**Solutions:**
- ✅ **Verify KTPAMXX is installed** - Standard AMX will NOT work
- ✅ **Verify KTP-ReHLDS is installed** - Standard ReHLDS will NOT work
- ✅ **Check logs on startup** for: "Periodic monitoring started for player X"
- ✅ **Test with priority cvar**: `m_pitch 0.05` should be corrected within 2 seconds
- ✅ **Test with standard cvar**: `r_fullbright 1` may take up to 100 seconds to detect
- ✅ **Rate limiting is normal**: Max 1 validation per second per player
- ℹ️ **Expected behavior**: System queries cvars periodically, not instant on client change

### Discord Webhooks Not Working

**Problem:** Violations not appearing in Discord

**Solutions:**
- ✅ Verify `fcos_discord_enabled` is set to `1`
- ✅ Verify `fcos_discord_webhook` contains valid webhook URL
- ✅ Check AMX logs for "Discord payload file" errors
- ✅ Verify `curl` is installed and accessible from server
- ✅ Test webhook manually: `curl -X POST -H "Content-Type: application/json" -d '{"content":"test"}' YOUR_WEBHOOK_URL`

### False Positives

**Problem:** Legitimate players getting violations logged

**Solutions:**
- ℹ️ **All violations are auto-corrected** - No player punishment
- ℹ️ **Check network cvars** - `rate`, `cl_updaterate` vary by connection
- ℹ️ **m_pitch negatives are allowed** - Inverted mouse is legitimate (-0.022)
- ℹ️ **Review logs** to understand violation patterns
- ℹ️ **Logs are for information** - No automatic bans

---

## 🙏 Acknowledgments

**Current Maintainer:**
- **Nein_** ([@afraznein](https://github.com/afraznein)) - KTPAMXX integration, pure enforcement redesign, Discord webhooks

**Original Author:**
- **SubStream** - Force CAL Open Settings (fcos)
- **Original Thread**: http://forums.alliedmods.net/showthread.php?t=25927

**Contributors:**
- **KTP Community** - Testing, feedback, competitive insights
- **AMX Mod X Team** - Plugin platform

---

## 📄 License

**GPL v2** - Same as original fcos plugin

See [LICENSE](LICENSE) file for details

---

## 👤 Author

**Nein_**
- GitHub: [@afraznein](https://github.com/afraznein)
- Project: KTP Competitive Infrastructure

---

## ⚠️ Important Notes

### For Server Operators

**Requirements:**
- ✅ **KTPAMXX required** - Will NOT work on standard AMX Mod X
- ✅ **KTP-ReHLDS required** - Will NOT work on standard ReHLDS or HLDS
- ✅ **No backwards compatibility** - Designed specifically for KTP infrastructure

**Configuration:**
- ℹ️ **No punishment system** - Plugin only auto-corrects and logs
- ℹ️ **Discord webhooks optional** - Provides real-time alerts
- ℹ️ **Logs are informational** - Use for monitoring and investigation

**Performance:**
- ✅ **Low CPU overhead** - ~0.4% CPU usage for 32 players
- ✅ **Priority-based detection** - Critical cvars detected within 2 seconds
- ✅ **Periodic queries** - Server actively queries cvars on schedule
- ✅ **Rate limited** - Max 1 validation per second per player
- ✅ **Minimal network usage** - ~8 KB/s for 32-player server (~160 queries/sec)

### For Competitive Leagues

**Recommended Settings:**
```cfg
// Enable Discord webhooks for real-time monitoring
fcos_discord_enabled "1"
fcos_discord_webhook "YOUR_WEBHOOK_URL"
```

**Best Practices:**
- ✅ Announce enforcement in league rules
- ✅ Provide cvar config file for players
- ✅ Monitor Discord channel for violations
- ✅ Keep detailed logs for disputes
- ✅ Use KTPAMXX + KTP-ReHLDS infrastructure

**No Automatic Punishments:**
- ℹ️ Plugin only **auto-corrects** and **logs** violations
- ℹ️ No automatic warnings, kicks, or bans
- ℹ️ Admins must manually review logs and take action
- ℹ️ Pure enforcement ensures fair play without false positive bans

---

**KTP Cvar Checker** - Keeping competitive play fair through automatic enforcement. 🛡️
