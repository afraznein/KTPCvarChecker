# KTP Cvar Checker

**Real-time client-side cvar enforcement system for competitive Day of Defeat servers**

A two-plugin anti-cheat system that continuously monitors 57 client cvars to prevent graphics exploits, wallhacks, sound advantages, and movement cheats. Features real-time detection with ReHLDS, progressive punishment system, and in-game admin configuration.

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
- ✅ Monitors 57 critical cvars continuously
- ✅ Real-time detection with ReHLDS (instant response)
- ✅ Automatic cvar correction on violation
- ✅ Progressive punishment system (warn → slay → kick/ban)
- ✅ Complete audit trail in AMX logs
- ✅ In-game admin configuration menu
- ✅ Works on base AMX, enhanced with ReHLDS

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│  Game Client                                    │
│  - Player changes cvar (r_fullbright 1)         │
│  - Userinfo updated                             │
└────────────────┬────────────────────────────────┘
                 │ Userinfo update
                 ↓
┌─────────────────────────────────────────────────┐
│  Half-Life Engine (HLDS/ReHLDS)                │
│  Detects userinfo change                        │
│  Calls client_infochanged() forward             │
└────────────────┬────────────────────────────────┘
                 │ AMXX Forward
                 ↓
┌─────────────────────────────────────────────────┐
│  KTP Cvar Checker (AMX Plugin)                 │
│  - client_infochanged() called                  │
│  - Rate limiting (1 second per player)          │
│  - Checks 57 cvars against whitelist           │
│  - Detects: r_fullbright is "1" (required: "0")│
│  - Forces correct value immediately             │
│  - Logs violation                               │
│  - Increments violation counter                │
│  - Applies punishment (warn/slay/kick)          │
└─────────────────────────────────────────────────┘
```

**Detection Speed:**
- **Real-time detection (v5.6+)**: **< 1 second** - Uses AMXX `client_infochanged()` forward, works on ALL servers!
- **Periodic fallback (ReAPI)**: 15-60 second intervals using direct userinfo parsing
- **Performance (v6.0+)**: **1-3ms per check** (optimized smart checking, only validates mismatched cvars)

---

## ✨ Key Features

### 🔍 Comprehensive Cvar Monitoring

**57 Monitored Cvars:**

**Graphics Anti-Cheat (31 cvars):**
```
gl_affinemodels, gl_alphamin, gl_clear, gl_cull, gl_d3dflip,
gl_dither, gl_keeptjunctions, gl_lightholes, gl_monolights,
gl_nobind, gl_nocolors, gl_overbright, gl_palette_tex, gl_picmip,
gl_playermip, r_bmodelinterp, r_drawentities, r_drawviewmodel,
r_dynamic, r_fullbright, r_glowshellfreq, r_lightmap, r_traceglow,
r_wadtextures, texgamma, r_luminance, lightgamma (range)
```

**Audio Anti-Cheat (2 cvars):**
```
s_show              (0 only - prevents sound origin visualization)
ambient_fade, ambient_level
```

**Movement Anti-Cheat (6 cvars):**
```
m_pitch             (0.022 or -0.022 - prevents pitch hacks)
m_side              (0.022 only - prevents strafe exploits)
cl_pitchdown, cl_pitchup, cl_yawspeed, cl_pitchspeed
```

**Network Settings (4 cvars with ranges):**
```
cl_updaterate       (100-120) - Fair network updates
cl_cmdrate          (100-500) - Command rate limits
rate                (100000-1000000) - Connection rate
ex_interp           (0-0.04) - Interpolation settings
```

**Gameplay Settings (14 cvars):**
```
cl_bob (range), cl_bobcycle, cl_bobup, cl_smoothtime (range),
cl_fixtimerate, cl_gaitestimation, fastsprites, fps_max (range),
cl_lc, cl_lw, lookspring, lookstrafe, and more
```

### ⚡ Real-Time Detection (v5.6+) - AMXX Forward

**How It Works (v5.6+):**
```pawn
// Plugin uses built-in AMXX forward (works on ALL servers!)
public client_infochanged(id) {
    // Called when player changes ANY userinfo (including cvars)

    // Validate player and check rate limiting
    if (!is_user_connected(id) || gb_StopChecking[id])
        return PLUGIN_CONTINUE

    // Rate limiting: 1 second minimum between checks (systime precision)
    new current_time = get_systime()
    if (current_time - gi_last_check_time[id] < 1)
        return PLUGIN_CONTINUE

    gi_last_check_time[id] = current_time

    // Parse userinfo DIRECTLY - no network queries!
    fn_check_userinfo_direct(id)
}

// Extract all 57 cvar values from userinfo instantly
public fn_check_userinfo_direct(id) {
    for (i = 0; i < 57; i++) {
        get_user_info(id, cvar_name, value, maxlen)  // No network round-trip!
        // Validate and enforce immediately
    }
}
```

**Performance Features (v5.6):**
- ✅ **ZERO network queries** - parses userinfo string directly
- ✅ **All 57 cvars checked in < 0.1 seconds**
- ✅ **Real-time detection** when cvar changes (< 1 second with rate limiting)
- ✅ **Works on ALL servers** (HLDS, ReHLDS, any AMX server)
- ✅ **No custom hooks required** - uses standard AMXX forward
- ✅ **Pause-aware rate limiting** - uses `get_systime()` (works during KTP-ReHLDS pauses)
- ✅ **Minimal resource usage** - event-driven, not polling

**v5.2 vs v5.6 Comparison:**
| Version | Detection Method | Time to Check 57 Cvars | Network Queries | Server Requirement |
|---------|------------------|------------------------|-----------------|-------------------|
| v5.2 | RH_SV_CheckUserInfo → query each cvar | 8.55 seconds | 57 queries | KTP-ReHLDS + KTP-ReAPI |
| v5.6 | client_infochanged() → parse userinfo | < 0.1 seconds | 0 queries | Any AMX server |

### 🔄 Polling Fallback (ReAPI Servers)

**For servers with ReAPI module:**
```pawn
// Periodic polling as backup to real-time detection
// Random intervals: 15-60 seconds
// Uses direct userinfo parsing (< 0.1s per check)
// Zero network queries
```

**Platform Compatibility:**
- ✅ Works on **base AMX ModX** (HLDS) - Real-time via client_infochanged()
- ✅ Works on **standard ReHLDS** - Real-time via client_infochanged()
- ✅ Works on **ReAPI servers** - Real-time + periodic fallback

### 📊 Progressive Punishment System

**Configurable Escalation:**

```
Violation 1-4:   Automatic correction only
                ↓
Violation 5:    Warning MOTD displayed
                ↓
Violation 10:   Name changed to "Cheater"
                ↓
Violation 15:   Player slayed (killed)
                ↓
Violation 20:   Kicked from server
                ↓
Violation 25:   Banned (60 minutes default)
```

**Configuration:**
```cfg
fcos_warn "1"                      // Enable warning MOTD
fcos_attempt_num_warn "5"          // Violations before warning
fcos_repeat_warning "1"            // Show warning repeatedly

fcos_change_name "1"               // Enable name change
fcos_attempt_num_namechange "10"   // Violations before name change

fcos_slay "1"                      // Enable slay
fcos_attempt_num_slay "15"         // Violations before slay
fcos_repeat_slaying "0"            // Slay once only

fcos_kick_or_ban "2"               // 0=off, 1=kick, 2=ban
fcos_attempt_num_kickorban "20"    // Violations before kick/ban
fcos_ban_time "60"                 // Ban duration in minutes
fcos_use_amx_bans "1"              // Use amx_ban instead of banid
```

### 🎛️ In-Game Admin Menu

**Interactive Configuration:**
```
/fcosconfig  (or amx_fcosconfig)

┌─────────────────────────────────────────┐
│  KTP Cvar Checker Configuration        │
├─────────────────────────────────────────┤
│  1. Warning MOTD: [ON]                  │
│  2. Violations before warning: [5]      │
│  3. Repeat warnings: [ON]               │
│  4. Name change punishment: [OFF]       │
│  5. Violations before name change: [10] │
│  6. Slay punishment: [OFF]              │
│  7. Violations before slay: [15]        │
│  8. Repeat slaying: [OFF]               │
│  9. Kick/Ban mode: [2] (Ban)            │
│  10. Violations before kick/ban: [20]   │
│  11. Ban duration (minutes): [60]       │
│  12. Use AMX bans: [ON]                 │
├─────────────────────────────────────────┤
│  [Apply Changes]  [Cancel]              │
└─────────────────────────────────────────┘
```

**Features:**
- ✅ Real-time configuration (no server restart)
- ✅ Persistent settings saved to `ktp_cvar.cfg`
- ✅ Preview before applying
- ✅ Admin-only access (ADMIN_CFG flag)

### 🎯 Smart Value Handling

**Float Precision:**
```pawn
// Uses 0.00005 tolerance for float comparisons
new Float:player_value = get_cvar_float("lightgamma");
new Float:required_value = 2.5;

if (floatabs(player_value - required_value) <= 0.00005) {
    // Value is acceptable
}
```

**Range Checks:**
```pawn
// lightgamma must be between 1.7 and 3.0
if (1.7 <= player_value <= 3.0) {
    // Valid
}

// ex_interp must be between 0 and 0.04
if (0.0 <= player_value <= 0.04) {
    // Valid
}
```

**Special Case - m_pitch:**
```pawn
// Allows both positive and negative
if (value == 0.022 || value == -0.022) {
    // Valid (inverted mouse is legitimate)
}
```

### 📝 Complete Audit Trail

**AMX Log Format:**
```
L 11/19/2025 - 14:32:15: [KTP Cvar Checker] STEAMID:0:1:12345678 | PlayerName | 192.168.1.100 | Invalid r_fullbright: 1.0 (Required: 0.0)
L 11/19/2025 - 14:32:18: [KTP Cvar Checker] STEAMID:0:1:12345678 | PlayerName | 192.168.1.100 | Invalid gl_overbright: 2.0 (Required: 0.0)
L 11/19/2025 - 14:32:45: [KTP Cvar Checker] STEAMID:0:1:12345678 | PlayerName | 192.168.1.100 | Kicked for 20 violations
```

**Log Information:**
- ✅ Timestamp
- ✅ SteamID
- ✅ Player name
- ✅ IP address
- ✅ Cvar name and values (actual vs required)
- ✅ Punishment actions

---

## 🔧 Plugin Components

### ktp_cvar.sma - Core Enforcement Engine

**Version:** 6.0 (2025-11-24)
**File Size:** ~1000 lines
**Purpose:** Real-time client cvar monitoring and enforcement using AMXX forwards and direct userinfo parsing

**Key Functions:**
```pawn
public plugin_init()                     // Initialize plugin
public client_infochanged(id)            // AMXX forward - real-time detection (ALL servers!)
public fn_check_single_cvar_changed(id)  // Optimized smart checking (v6.0+, only validates mismatches)
public fn_check_userinfo_direct(id)      // Parse userinfo directly (instant, zero queries)
public fn_recheck_direct(id)             // Periodic fallback check (ReAPI servers)
public client_putinserver(id)            // Start initial check timer
public CheckCvarValue(id, cvar, value)   // Validate and enforce
public ApplyPunishment(id, count)        // Progressive punishment
```

**Detection Methods:**
- **Primary (v5.6+)**: AMXX `client_infochanged()` forward + direct userinfo parsing (< 1s with rate limiting, zero queries, works on ALL servers)
- **Periodic Fallback (ReAPI servers)**: Direct userinfo parsing at 15-60s intervals (< 0.1s, zero queries)
- **Rate Limiting**: 1 second minimum between checks per player using `get_systime()` (pause-aware)

### ktp_cvarconfig.sma - Admin Configuration Interface

**Version:** 3.2
**File Size:** ~400 lines
**Purpose:** In-game admin menu for configuring enforcement settings

**Key Functions:**
```pawn
public plugin_init()                // Register commands
public ShowMainMenu(id)             // Display config menu
public MainMenuHandler(id, menu, item)  // Handle menu selections
public SaveConfig()                 // Write settings to file
```

**Configuration File:**
- **Location**: `addons/amxmodx/configs/ktp_cvar.cfg`
- **Format**: Standard AMX cvar format
- **Auto-created**: On first save from menu

---

## 🚀 Installation

### Prerequisites

- **AMX Mod X 1.9+** (1.10 recommended)
- **Optional**: ReHLDS for real-time detection
- **Optional**: ReAPI module (auto-detected by plugin)

### Step 1: Compile Plugins

```bash
# Navigate to AMX scripting directory
cd addons/amxmodx/scripting

# Compile both plugins
amxxpc ktp_cvar.sma -oktp_cvar.amxx
amxxpc ktp_cvarconfig.sma -oktp_cvarconfig.amxx
```

### Step 2: Install Plugins

```bash
# Copy compiled plugins to plugins directory
cp ktp_cvar.amxx ../plugins/
cp ktp_cvarconfig.amxx ../plugins/
```

### Step 3: Enable Plugins

Edit `addons/amxmodx/configs/plugins.ini`:
```ini
; KTP Cvar Checker - Anti-cheat system
ktp_cvar.amxx
ktp_cvarconfig.amxx
```

### Step 4: Configure Settings (Optional)

**Option A - In-Game Menu (Recommended):**
1. Join server as admin
2. Type `/fcosconfig` in chat or `amx_fcosconfig` in console
3. Configure settings via menu
4. Settings auto-save to `ktp_cvar.cfg`

**Option B - Manual Configuration:**

Create `addons/amxmodx/configs/ktp_cvar.cfg`:
```cfg
// Warning system
fcos_warn "1"
fcos_attempt_num_warn "5"
fcos_repeat_warning "1"

// Punishment escalation
fcos_change_name "0"          // Usually disabled in competitive
fcos_slay "0"                 // Usually disabled in competitive
fcos_kick_or_ban "2"          // 2 = ban
fcos_attempt_num_kickorban "15"
fcos_ban_time "60"            // 60 minutes
fcos_use_amx_bans "1"
```

### Step 5: Restart Server

```bash
# Or use amx_reloadadmins if you don't want to restart
amx_plugins reload ktp_cvar.amxx
amx_plugins reload ktp_cvarconfig.amxx
```

### Step 6: Verify Installation

```
// In server console or player console
ktp_cvar_version

// Should output:
// KTP Cvar Checker version 5.7

// Check AMX logs on startup
// Should show:
// [KTP Cvar Checker] Real-time detection via client_infochanged() enabled
// (If ReAPI detected, also shows periodic fallback enabled)
```

---

## 📋 Monitored Cvars Reference

### Exact Value Cvars (49)

| Cvar | Required | Purpose |
|------|----------|---------|
| `r_fullbright` | `0` | Prevents wallhack-like lighting |
| `r_lightmap` | `0` | Prevents texture exploits |
| `gl_overbright` | `0` | Prevents brightness exploits |
| `gl_clear` | `0` | Prevents transparent walls |
| `s_show` | `0` | Prevents sound origin visualization |
| `m_pitch` | `0.022` or `-0.022` | Standard mouse pitch |
| `m_side` | `0.022` | Standard mouse side movement |
| `fastsprites` | `0` | Standard sprite rendering |
| `cl_lc` | `1` | Lag compensation on |
| `cl_lw` | `1` | Client-side weapons on |
| `cl_fixtimerate` | `7.5` | Standard timerate |
| ... | ... | (+ 38 more, see code for full list) |

### Range Value Cvars (8)

| Cvar | Min | Max | Purpose |
|------|-----|-----|---------|
| `lightgamma` | `1.7` | `3.0` | Prevent extreme brightness |
| `cl_smoothtime` | `0` | `0.1` | Movement smoothing |
| `cl_bob` | `0` | `0.011` | View bobbing |
| `cl_updaterate` | `100` | `120` | Network update rate |
| `cl_cmdrate` | `100` | `500` | Command rate |
| `rate` | `100000` | `1000000` | Connection rate |
| `ex_interp` | `0` | `0.04` | Entity interpolation |
| `fps_max` | `60` | `500` | FPS limiter |

---

## 🎮 Usage

### For Server Admins

**Configure Punishment System:**

1. **Join server** with admin privileges (ADMIN_CFG flag)
2. **Open menu**: Type `/fcosconfig` in chat
3. **Configure settings**:
   - Enable warning MOTD (recommended: ON)
   - Set violations before warning (recommended: 3-5)
   - Set kick/ban mode (competitive: BAN)
   - Set violations before ban (recommended: 10-20)
   - Set ban duration (recommended: 60-120 minutes)
4. **Apply changes** - Settings save automatically

**Monitor Violations:**
```bash
# Check AMX logs
cat addons/amxmodx/logs/L1119.log | grep "KTP Cvar"

# Look for patterns of violations
# Investigate players with multiple violations
```

**Manual Intervention:**
```bash
# Check specific player's cvars (requires ReAPI)
amx_cvar @id cvar_name

# Kick player manually
amx_kick #userid "Cvar violations"

# Ban player manually
amx_ban #userid 60 "Repeated cvar violations"
```

### For Players

**Check If Monitoring Is Active:**
```
// In console
ktp_cvar_version

// Should see:
// KTP Cvar Checker version 5.7
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
4. **Most violations auto-correct** - plugin forces correct values
5. **Persistent violations** indicate script/cheat interference

**Legitimate Settings:**
- `m_pitch` can be negative (`-0.022`) for inverted mouse
- Network cvars (`rate`, `cl_updaterate`) may need adjustment for your connection
- `ex_interp` between 0 and 0.04 is allowed for latency compensation

### For Competitive Match Admins

**Pre-Match Setup:**
```cfg
// Recommended competitive settings
fcos_warn "1"
fcos_attempt_num_warn "3"        // Warn early
fcos_kick_or_ban "2"              // Ban mode
fcos_attempt_num_kickorban "10"   // 10 violations = ban
fcos_ban_time "120"               // 2 hour ban
fcos_use_amx_bans "1"            // Use AMX ban system
```

**During Match:**
- Monitor AMX logs for violations
- Investigate suspicious players
- Most violations are auto-corrected
- Persistent violators are automatically banned

---

## 🔗 Related KTP Projects

### **KTP Competitive Infrastructure:**

**🔧 Engine Layer:**
- **[KTP-ReHLDS](https://github.com/afraznein/KTP-ReHLDS)** - Custom engine with pause system and real-time hooks
- **[KTP-ReAPI](https://github.com/afraznein/KTP-ReAPI)** - Custom ReAPI exposing RH_SV_CheckUserInfo

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

### v6.0 (2025-11-24) - ktp_cvar.sma 🚀 PERFORMANCE - Smart Checking
- ⚡ **OPTIMIZED: client_infochanged now uses smart checking** - Only validates cvars that don't match expected values
- 🚀 **ADDED: fn_check_single_cvar_changed()** - Early exit when cvar matches expected value (skips expensive validation)
- 📊 **PERFORMANCE: Reduced execution time from ~29ms to ~1-3ms** - 10-30x faster real-time detection!
- 🎯 **IMPROVED: Eliminated performance warnings** - No more "executed more than 29.1ms" messages
- ℹ️ **NOTE:** Still loops through all 57 cvars, but exits early for correct values instead of running full validation
- ✅ **Typical case:** Player changes 1-2 cvars → only validates those 2 instead of all 57

### v5.9 (2025-11-24) - ktp_cvar.sma 🔥 CRITICAL FIX - Command Enforcement
- 🚨 **CRITICAL: Fixed client_cmd newline issue** - Commands were being split across lines breaking enforcement
- 🐛 **FIXED: "Server tried to send invalid command" errors** - Commands like "rate 100000\n" were breaking
- ✅ **CHANGED: Added semicolon terminator to all client_cmd calls** - `rate 100000;` prevents command splitting
- 🎯 **IMPROVED: Cvar enforcement now works correctly** - All values (small and large) are properly enforced
- ℹ️ **ROOT CAUSE:** client_cmd() adds automatic newline, causing double newline which splits commands
- ✅ **SOLUTION:** Semicolon prevents command from being split across the automatic newline

### v5.8 (2025-11-23) - ktp_cvar.sma 🐛 BUG FIX - Large Value Formatting (Incomplete)
- 🔧 **Attempted fix for large cvar values** - Used integer format for values >= 100
- ⚠️ **NOTE: Fix was incomplete** - Formatting was correct, but newline handling was wrong (fixed in v5.9)
- ❌ **Still had enforcement issues** - Commands were still failing due to newline problem

### v5.7 (2025-11-22) - ktp_cvar.sma 🧹 OPTIMIZATION - Cleanup
- 🧹 **Removed unnecessary debug logging** - No more "[KTP Cvar Checker] UserInfo changed" spam in logs
- 🧹 **Removed failed optimization attempt** - Simplified client_infochanged() implementation
- 📊 **Documented expected performance** - 2-6ms per check is normal for 57 cvars
- ℹ️ **Performance notes added** - AMXX warnings (>2ms) are expected and acceptable
- ℹ️ **Overhead is negligible** - Max 6ms per second (0.2-0.6% of server tick at 1000fps)
- ✅ **Plugin performing optimally** - Rate limiting prevents abuse, real-time detection working perfectly

### v5.6 (2025-11-22) - ktp_cvar.sma 🔥 CRITICAL FIX - Real-Time Detection
- 🚨 **CRITICAL: Removed broken RH_SV_CheckUserInfo hook** - Was causing crashes with invalid player IDs
- ⚡ **NEW: Real-time detection via client_infochanged() forward** - Works on ALL servers (HLDS, ReHLDS, any AMX)
- ✅ **No custom hooks required** - Uses standard AMXX forward instead of ReHLDS-specific hook
- 🔄 **Added periodic polling fallback** - 15-60s random intervals on ReAPI servers as backup
- ⏱️ **Pause-aware rate limiting** - Uses `get_systime()` with 1-second precision (works during KTP-ReHLDS pauses)
- 🐛 **Fixed all runtime crashes** - No more "index out of bounds" errors from invalid player IDs
- 📊 **Instant detection** - < 1 second with rate limiting (was 15-60s polling or 8.55s with broken hook)
- 🎯 **Platform compatibility expanded** - Now works perfectly on base HLDS without any custom engine mods

### v5.5 (2025-11-22) - ktp_cvar.sma (Internal - Not Released)
- Changed rate limiting from `get_gametime()` to `get_systime()` for pause compatibility
- Fixed compilation errors with rate limit variable type
- Adjusted precision from 0.1s to 1s for systime
- (Superseded by v5.6 which fixed the broken hook)

### v5.4 (2025-11-21) - ktp_cvar.sma 🚀 PERFORMANCE UPDATE
- ⚡ **Pre-converted float arrays** - Eliminates 57+ `floatstr()` calls per check
- 🔧 **Removed duplicate get_user_name()** - 2-3 calls per violation → 1 call
- 🎯 **Optimized float comparisons** - Check floats before strings (faster)
- 🛡️ **Rate limiting** - Max 1 check per 0.1s per player (prevents abuse)
- ⏱️ **Uses system time** - Rate limiting works correctly with pause system
- 🧹 **Removed unused variables** - Cleaned up gi_players, gi_playercnt, gs_graph, gs_netgraph
- 💾 **Cache ban_time pcvar** - Grouped with other cached punishment settings
- 🔄 **Cache gs_pitch comparison** - Eliminates duplicate string check per violation
- 🚀 **Eliminated linear search** - Replaced O(n) cvar loop with O(1) direct array access (~1600 string comparisons removed per full check on non-ReAPI servers)
- 📊 **Overall: ~60% fewer function calls** per check, ~1600 fewer string comparisons per full check

### v5.3 (2025-11-21) - ktp_cvar.sma ⭐ MAJOR UPDATE
- 🚀 **MAJOR: Direct userinfo parsing** - Zero network queries for instant cvar checks!
- ⚡ **Performance: < 0.1 seconds** to check all 57 cvars (was 8.55s in v5.2)
- 🔧 Added `fn_check_userinfo_direct()` function to parse userinfo string instantly
- 🔧 Added `fn_initial_check_direct()` for instant initial checks on player connect
- ⏱️ **Disabled polling on ReAPI servers** - Real-time detection only (event-driven)
- 🎯 **Initial check now instant** on ReAPI servers (< 0.1s vs 8.55s)
- 🎯 **Ongoing checks instant** on userinfo changes (< 0.1s vs 8.55s)
- 📊 **85x faster detection** on ReAPI servers vs v5.2
- 🎯 Eliminates 57 network round-trips per check

### v5.2 (2025-10-31) - ktp_cvar.sma
- ✨ Added ReHLDS real-time userinfo detection via `RH_SV_CheckUserInfo`
- 🚀 Optimized for AMX ModX 1.10
- 🏗️ Refactored code organization
- 📚 Added comprehensive constants and documentation
- 🔧 Improved float precision handling
- ⚠️ Note: Still used `query_client_cvar()` for all checks (8.55s per check)

### v3.2 (2025-10-31) - ktp_cvarconfig.sma
- 🏗️ Full code refactoring for maintainability
- 🎛️ Modernized menu system
- 💾 Cached pcvar pointers for performance
- 🐛 Fixed file writing bugs
- 📝 Improved configuration file format
- ✨ Added configuration preview

### v5.0-5.1 (2024-XX-XX)
- Base implementation of 57 cvar checks
- Polling system for standard HLDS/ReHLDS
- Progressive punishment system
- AMX log integration

---

## 🐛 Troubleshooting

### Cvars Not Being Checked

**Problem:** No violations detected even with obvious cheats

**Solutions:**
- ✅ Verify plugin is loaded: `amx_plugins`
- ✅ Check AMX logs for errors
- ✅ Ensure players aren't admins (admins may be immune)
- ✅ Verify ReHLDS hook registered (check logs on startup)
- ✅ Test with known violation: `r_fullbright 1` in console

### Real-Time Detection Not Working

**Problem:** Violations detected slowly (15-60 second delay)

**Solutions:**
- ✅ **Verify plugin version**: Run `ktp_cvar_version` - should show **6.0** for optimized performance
- ✅ **Check AMX logs on startup** for: "[KTP Cvar Checker] Real-time detection via client_infochanged() enabled"
- ✅ **If using v5.8 or older**: Upgrade to v5.9+ for working enforcement and v6.0 for best performance
- ✅ **Test with a cvar change**: Type `r_fullbright 1` in console, should be corrected within 1 second
- ✅ **Rate limiting is normal**: Max 1 check per second per player to prevent abuse
- ✅ **Performance improved in v6.0**: Smart checking takes 1-3ms (was 2-6ms in v5.7, 29ms+ with violations)
- ✅ **Periodic polling on ReAPI servers**: 15-60s fallback checks are normal as backup

### Configuration Not Saving

**Problem:** Admin menu settings don't persist after restart

**Solutions:**
- ✅ Verify write permissions on `configs/` directory
- ✅ Check AMX logs for file write errors
- ✅ Manually create `ktp_cvar.cfg` and test
- ✅ Ensure ktp_cvarconfig.amxx is loaded

### False Positives

**Problem:** Legitimate players getting banned

**Solutions:**
- ⚠️ **Review ban threshold** - 10-20 violations recommended (not 5)
- ⚠️ **Check network cvars** - `rate`, `cl_updaterate` vary by connection
- ⚠️ **Allow m_pitch negatives** - Inverted mouse is legitimate
- ⚠️ **Review logs** before permanent bans
- ⚠️ **Adjust ranges** if needed for network cvars

### Players Circumventing Checks

**Problem:** Players changing cvars back after correction

**Solutions:**
- ✅ **Verify v5.7 is installed** - Real-time detection via client_infochanged() catches changes instantly
- ✅ **Lower ban threshold** - 10 violations instead of 20
- ✅ **Enable repeat slaying** - Punish during match
- ✅ **Manual review** - Check logs for persistent violators
- ✅ **Consider stricter punishment** at earlier violation count

### Plugin Conflicts

**Problem:** Other plugins interfering with cvar checks

**Solutions:**
- ✅ Load ktp_cvar.amxx **after** other cvar-related plugins
- ✅ Check for plugins that also implement `client_infochanged()` forward
- ✅ Disable conflicting anti-cheat plugins
- ✅ Review AMX logs for errors or conflicts

---

## 🙏 Acknowledgments

**Current Maintainer:**
- **Nein_** ([@afraznein](https://github.com/afraznein)) - KTP modifications, ReHLDS integration, optimization

**Original Author:**
- **SubStream** - Force CAL Open Settings (fcos)
- **Original Thread**: http://forums.alliedmods.net/showthread.php?t=25927

**Contributors:**
- **KTP Community** - Testing, feedback, competitive insights
- **ReHLDS Team** - Engine hooks and API support
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

**Legal and Ethical Considerations:**
- ✅ **Inform players** that cvar checking is active
- ✅ **MOTD disclosure** recommended (e.g., "This server enforces anti-cheat cvar checks")
- ✅ **Review bans manually** before making permanent
- ✅ **Keep logs** as evidence for disputed bans
- ✅ **Test configuration** in non-competitive environment first

**False Positive Prevention:**
- ⚠️ Some hardware/drivers cause unusual cvar values
- ⚠️ Network cvars vary legitimately by connection quality
- ⚠️ Test with multiple players before strict enforcement
- ⚠️ Allow grace period for warnings (5-10 violations)
- ⚠️ Manual review recommended before permanent bans

**Performance Considerations:**
- ✅ **v5.7 (Current)**: **MINIMAL overhead** - Event-driven via client_infochanged(), direct userinfo parsing, zero network queries
- ✅ **Real-time detection**: < 1 second with rate limiting (1 check per second max per player)
- ✅ **Check performance**: 2-6ms per check (acceptable for 57 cvars, < 0.6% of server tick)
- ✅ **Periodic fallback (ReAPI servers)**: 15-60s intervals for backup detection
- ✅ **Server with 32 players**: Only checks when cvars actually change (event-driven, not polling)
- ℹ️ **AMXX performance warnings (>2ms)**: Expected and acceptable when checking 57 cvars
- ⚠️ **Upgrade recommendation**: If using v5.6 or older, upgrade to v5.7 for optimized performance

### For Competitive Leagues

**Recommended Settings:**
```cfg
fcos_warn "1"                      // Enable warnings
fcos_attempt_num_warn "3"          // Warn at 3 violations
fcos_kick_or_ban "2"               // Ban mode
fcos_attempt_num_kickorban "15"    // Ban at 15 violations
fcos_ban_time "120"                // 2 hour ban
fcos_use_amx_bans "1"              // Use AMX ban system
```

**Best Practices:**
- ✅ Announce enforcement in league rules
- ✅ Provide cvar config file for players
- ✅ Review all bans before matches
- ✅ Keep detailed logs for disputes
- ✅ Use ReHLDS for real-time enforcement

---

**KTP Cvar Checker** - Keeping competitive play fair, one cvar at a time. 🛡️
