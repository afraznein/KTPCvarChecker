/*
 *   Title:    KTP Cvar Settings (fcos)
 *   Author:   Nein_
 *
 *   Current Version:   7.31
 *   Release Date:      2026-07-18
 *
 *   Changelog:
 *   7.31 2026-07-18 - Discord violation buffer is now PER-PLAYER (was a single global buffer).
 *                      Two players violating in the same 5s batch window evicted and fragmented
 *                      each other's embed — the common case at match start, not an edge case.
 *                      Buffers are MAX_PLAYERS-sized parallel arrays keyed on slot with authid
 *                      re-verification for slot reuse. Also refreshes the buffered name/IP on
 *                      every violation (was only when the batch opened), so a mid-window rename
 *                      no longer shows a stale name in the embed.
 *   7.30 2026-07-11 - Removed cl_mousegrab from enforcement (client-only SDL pointer-grab
 *                      cvar, no server/aim surface; MOSS rationale obsolete; enforcing 1
 *                      pushed windowed players toward capture-blind exclusive-fullscreen GL).
 *                      TOTAL_CVARS 38->37, standard 23->22, HUD/M_PITCH indices shifted -1.
 *   7.29 2026-07-08 - Per-tier silence tripwire (closes the selective-tier-blocking residual)
 *                    + ADDED: per-tier unanswered counters — a client answering only one
 *                      rotation tier trips event=CVAR_TIER_SILENT + Discord alert after
 *                      ~90s of that tier's silence (ktp_cvar_silent_tier_secs, 0=off;
 *                      30-query floor; suppressed while globally silent so the
 *                      "selective" claim is structurally true). Alert-only, no kick.
 *                      Recovery from total silence resets both tiers (no false accusation).
 *   7.28 2026-07-08 - Silent-client tripwire + hygiene (2026-07-06 assessment CV items)
 *                    + ADDED: per-player unanswered-query liveness counter — a client that
 *                      never answers cvar queries now trips an audit log line
 *                      (event=CVAR_QUERY_SILENT) + Discord alert. Alert-only, no kick.
 *                      Cvars: ktp_cvar_silent_queries (300, 0=off), ktp_cvar_silent_grace (60.0)
 *                    * FIXED: putinserver now clears enforcement/defer/liveness state itself
 *                      (was relying on the previous occupant's disconnect having run)
 *                    * FIXED: steady-state responses were validated twice (query callback +
 *                      client_cvar_changed forward fire back-to-back for the same message) —
 *                      forward now skips responses fn_querycvar already handled
 *   7.27 2026-07-06 - Detection-latency + batching fixes (2026-07-05 review #15 + P2)
 *                    * CHANGED: 8 visual-cheat cvars promoted to the priority tier
 *                      (r_fullbright, r_lightmap, r_luminance, gl_monolights, gl_nocolors,
 *                       gl_overbright, gl_picmip, r_drawentities) — the 31s standard cycle
 *                      left room for scripted toggle-peek-revert
 *                    * CHANGED: priority interval 0.5s → 0.3s (netcode cycle ~4.5s, visual 31s → 4.5s)
 *                    * FIXED: ~7.5s zero-enforcement window per (re)connect — initial sweep
 *                      starts at 1.0s and queries priority cvars first (g_queryOrder)
 *                    * FIXED: /cvar re-entrancy — spam stacked concurrent query chains on one counter
 *                    * FIXED: Discord batch keyed on SteamID, not slot (slot reuse inside the
 *                      5s window misattributed violations; FileChecker 2.6 pattern)
 *   7.26 2026-04-29 - r_glowshellfreq enforced 0 → 2.2 (actual DoD default; kept as integrity
 *                      check, removed false-positive friction — see array comment)
 *   7.25 2026-04-28 - Removed cl_lc/cl_lw from enforcement (engine-source audit: no exploit
 *                      surface); cl_cmdrate cap raised to 1000 for input-resolution testing
 *   7.24 2026-04-28 - Re-added 7 cvars dropped in v7.13 (keyboard-look + visual-exploit
 *                      defenses: cl_pitchspeed/yawspeed/anglespeedkey/m_side + gl_picmip/
 *                      r_glowshellfreq/r_traceglow)
 *   7.23 2026-04-25 - Adopted ktp_version_reporter shared include; standardized version constants
 *   7.22 2026-03-24 - Enforcement range adjustments
 *                    * CHANGED: rate locked to exact 100000 (was range 100000-1000000)
 *                    * CHANGED: cl_updaterate max lowered from 200 to 120 (matches sv_maxupdaterate)
 *                    * CHANGED: ex_interp range adjusted to 0.01-0.05 (was 0-0.03)
 *                    - REMOVED: cl_smoothtime enforcement (purely cosmetic, no competitive advantage)
 *                    - REMOVED: Dead gs_pitch constant (replaced by integer index in v7.21)
 *   7.21 2026-03-24 - Performance optimizations
 *                    * CHANGED: Cvar name lookup via Trie O(1) hash (was O(n) 34-entry linear scan)
 *                    * CHANGED: m_pitch/hud_takesshots checks use integer index compare (was string compare)
 *                    * CHANGED: Disconnect enforcement reset uses dirty flag (skips 34-iteration loop for clean players)
 *                    * REMOVED: Per-player log_amx on monitoring start (24 disk writes per match connect wave)
 *   7.20 2026-03-13 - Discord task leak fix + cleanup
 *                    * FIXED: Discord task leak caused doubled notifications on player interleave
 *                    * FIXED: task_deferred_enforce accessed g_deferPending with invalid index on bounds-check failure
 *                    * FIXED: Chat/Discord announcements showed rate cvars with unnecessary decimals (100000.00 → 100000)
 *                    * FIXED: Stale comment on standard cvar rotation interval
 *                    * CHANGED: fn_enforce_cvar from public to stock (internal-only function)
 *                    * REMOVED: Unused s_CALVALUE parameter from fn_enforce_cvar
 *                    * REMOVED: Dead g_deferToAlt array (no longer needed after s_CALVALUE removal)
 *   7.19 2026-03-12 - Deferred enforcement queue + cleanup
 *                    * FIXED: Multiple simultaneous cvar violations dropped — only last enforced
 *                    * FIXED: gi_cvarnum global loop variable could be clobbered across calls
 *                    * FIXED: fn_loopquery missing bot/HLTV guard
 *                    * FIXED: fn_msginitial missing bounds check
 *                    * FIXED: Hardcoded m_pitch values not using constants
 *                    * FIXED: Stale comments on monitoring intervals
 *                    * FIXED: Discord description buffer too small for 32 violations
 *   7.18 2026-03-12 - Enforcement accuracy fixes
 *                    * FIXED: Rate limiter dropped legitimate cvar events within 1-second window
 *                    * FIXED: Enforcement flag suppressed ALL cvar events, not just the enforced cvar
 *                    * FIXED: Uncached get_cvar_num("ktp_match_competitive") on every enforcement
 *                    * FIXED: Dead store in fn_msginitial (get_user_name result unused)
 *   7.17 2026-02-25 - Range cvar correction fix + buffer safety
 *                    * FIXED: Range cvars always corrected to minimum even when value exceeds maximum
 *                    * FIXED: Hardcoded buffer sizes in get_configsdir/formatex replaced with charsmax()
 *                    * FIXED: Header version/date now matches #define VERSION
 *   7.16 2026-02-20 - Index out of bounds fix
 *                    * FIXED: Runtime error 4 (index out of bounds) in fn_loopquery/fn_query_parallel
 *                    + CHANGED: All player arrays from [MAX_PLAYERS] to [MAX_PLAYERS+1] (off-by-one safety)
 *                    + ADDED: Bounds checks on all functions receiving player ID parameter
 *   7.15 2026-02-19 - Performance fix: deferred enforcement
 *                    * FIXED: clc_cvarvalue2 opcode processing taking 160-185ms (froze entire server frame)
 *                    + CHANGED: Enforcement now deferred to next frame via set_task(0.0) — no longer blocks opcode handler
 *                    - REMOVED: Debug log_amx calls in fn_querycvar, fn_firstcomplete, fn_start_monitoring
 *   7.14 2026-02-18 - fps_max range update
 *                    + CHANGED: fps_max top-end raised from 500 to 750
 *   7.13 2026-02-17 - Cvar list cleanup
 *                    - REMOVED: 25 unnecessary cvars (rendering tweaks, engine-limited values)
 *                    + CHANGED: Enforced cvars reduced from 59 to 34
 *                    + CHANGED: Priority cvar list updated (replaced cl_yawspeed, cl_pitchspeed,
 *                      lightgamma, cl_bob with cl_pitchdown, cl_pitchup, cl_lc, cl_lw)
 *                    + CHANGED: cl_updaterate max raised from 120 to 200 (matches sv_maxupdaterate)
 *   7.12 2026-02-04 - Dynamic hud_takesshots enforcement
 *                    + CHANGED: hud_takesshots only enforced during competitive matches
 *   7.11 2026-01-20 - Discord notification grouping
 *                    + CHANGED: Group all cvar violations into single Discord embed per player
 *                    + ADDED: Track repeat violations with count per cvar
 *                    + ADDED: 5-second timed window before sending grouped notification
 *                    + CHANGED: ktp_cvar_discord now defaults to 1 (enabled)
 *                    * Matches KTPFileChecker v2.3 grouping technique
 *   7.10 2026-01-13 - Discord branding
 *                    * CHANGED: Discord embed title now includes :ktp: emoji for consistent branding
 *   7.9 2026-01-09 - Discord toggle
 *                    + ADDED: ktp_cvar_discord cvar (0/1) to disable Discord logging
 *                    * Default: 0 (disabled) to reduce Discord webhook spam
 *   7.8 2025-12-31 - Debug log cleanup
 *                    - REMOVED: fn_msginitial() debug logging (no longer needed)
 *   7.7 2025-12-20 - Shared Discord config via ktp_discord.inc
 *                    * CHANGED: Now uses ktp_discord.inc for Discord integration
 *                    * CHANGED: Config now loaded from discord.ini (same as other KTP plugins)
 *                    - REMOVED: fcos_discord_enabled and fcos_discord_webhook cvars
 *                    - REMOVED: Direct webhook code (replaced with relay pattern)
 *   7.6 2025-12-20 - cl_filterstuffcmd detection and warning system
 *                    + ADDED: Enforcement attempt tracking per player per cvar
 *                    + ADDED: After 3 failed enforcement attempts, shows warning message
 *                    + ADDED: Warning explains cl_filterstuffcmd must be 0 and how to fix
 *                    + ADDED: Announcement to all players when enforcement is blocked
 *                    * CHANGED: Stops spamming chat after warning is shown once per cvar
 *                    * CHANGED: Resets tracking when player fixes the cvar value
 *   7.5 2025-12-08 - Timing fixes and debug improvements
 *                    * FIXED: Moved fn_servermessage() to plugin_cfg() for proper timing
 *                    + ADDED: Debug logging to fn_msginitial() for troubleshooting
 *                    + ADDED: is_user_connected() safety check before client prints
 *                    * CHANGED: "Initial check complete" now uses print_chat instead of print_console
 *                    * BRANDING: Updated references from "KTPAMXX" to "KTP AMX"
 *   7.4 2025-12-02 - Priority-based periodic monitoring system
 *                    + ADDED: Periodic cvar queries to trigger ReHLDS pfnClientCvarChanged hook
 *                    + ADDED: Priority cvar system - 9 critical cvars checked every 2 seconds
 *                      (m_pitch, cl_yawspeed, cl_pitchspeed, lightgamma, cl_bob,
 *                       cl_updaterate, cl_cmdrate, rate, ex_interp)
 *                    + ADDED: Standard cvar rotation - 25 cvars cycled through every 1 second each
 *                    * PERFORMANCE: ~3 queries/second per player (engine limited to 1 callback/frame)
 *                    * DETECTION: Priority cvars full cycle ~4.5s, standard cvars full cycle ~25s
 *   7.3 2025-11-29 - Bug fixes and chat announcements
 *                    * FIXED: Cvar callback now looks up cvar by name (async query fix)
 *                    + ADDED: Chat announcement to all players when cvar is corrected
 *   7.2 2025-11-28 - Updated cvar list and values
 *                    + ADDED: gl_round_down (value: 3)
 *                    + ADDED: hud_takesshots (value: 1)
 *                    * FIXED: lightgamma min from 1.7 to 1.81
 *                    * FIXED: ex_interp max from 0.04 to 0.03
 *                    * Total monitored cvars: 59 (51 exact + 8 ranges)
 *   7.1 2025-11-28 - Pure enforcement - All punishments removed + Discord logging
 *                    + ADDED: /cvar command for manual cvar check
 *                    + ADDED: Discord webhook logging via cURL (optional)
 *                    + ADDED: fcos_discord_enabled cvar (0/1)
 *                    + ADDED: fcos_discord_webhook cvar (webhook URL)
 *                    - REMOVED: All punishment cvars (warn, name change, slay)
 *                    - SIMPLIFIED: Pure enforcement (auto-correct) + logging only
 *   7.0 2025-11-28 - MAJOR UPGRADE: Real-time detection with KTP AMX - Simplified & Optimized
 *                    + ADDED: client_cvar_changed() forward for REAL-TIME detection of ALL cvars
 *                    + PERFORMANCE: 100% real-time detection - no periodic polling overhead
 *                    + PERFORMANCE: Instant detection for all cvars (< 1 second response time)
 *                    * REQUIRES: KTP AMX with pfnClientCvarChanged callback
 *                    - REMOVED: Backwards compatibility code (ReAPI, periodic polling)
 *                    - REMOVED: Kick/ban punishment system (enforcement only)
 *                    - REMOVED: MOTD warning system (console logging only)
 *                    - REMOVED: Priority tier system (not needed with real-time)
 */

#include <amxmodx>
#include <amxmisc>
#include <ktp_discord>
#include <ktp_version_reporter>

// ============================================================================
// PLUGIN INFORMATION
// ============================================================================

#define PLUGIN_NAME    "KTP Cvar Checker"
#define PLUGIN_VERSION "7.32"
#define PLUGIN_AUTHOR  "Nein_"
new const gs_year     = 2026;

// ============================================================================
// CONSTANTS & DEFINES
// ============================================================================

// File configuration
new const gs_FILENAME[] = "ktp_cvar";
new const gs_FILETYPE[] = ".cfg";

// Special cvar values
new const inverse_p[] = "-0.022";

// Precision constant for float comparisons
new const Float: FLOAT_PRECISION = 0.00005;

// Array size constants
#define TOTAL_CVARS 37
#define MIN_MAX_CVAR_START 30
#define ALT_VALUES_COUNT 7

// Enforcement cvar name length
#define ENFORCE_CVAR_LEN 32

// Cvar indices in gs_cvars[] array — must match array positions
// v7.25: shifted down by 2 after cl_lc/cl_lw removal (was 16, 17)
// v7.30: shifted down 1 more after cl_mousegrab removal (were 14, 15)
#define HUD_TAKESSHOTS_INDEX 13
#define M_PITCH_INDEX 14

// Priority-based monitoring intervals (1 query per tick due to engine limitation)
// v7.27: priority interval 0.5 → 0.3s to absorb the 8 promoted visual cvars —
// netcode cvars keep a ~4.5s full cycle (was 3.5s) while the visual-cheat set
// drops from a 31s cycle to 4.5s (a scripted toggle-peek fit comfortably in 31s).
#define PRIORITY_CHECK_INTERVAL 0.3   // Priority cvar rotation: full cycle = PRIORITY_CVARS_COUNT * this
#define STANDARD_CHECK_INTERVAL 1.0   // Standard cvar rotation: full cycle = gi_standardCvarCount * this
#define INITIAL_SWEEP_INTERVAL  0.3   // Initial-sweep query spacing (README/CHANGELOG timing math keys off this)

// Priority cvar count (v7.27: 7 → 15 with the visual-cheat set promoted)
#define PRIORITY_CVARS_COUNT 15

// Discord notification grouping
#define DISCORD_DELAY 5.0          // Delay to batch violations before sending Discord
#define MAX_CVAR_VIOLATIONS 32     // Max unique cvars to buffer per player
#define MAX_CVAR_NAME_LEN 32       // Max cvar name length
#define TASK_DISCORD_SEND 4000     // Task ID offset for Discord send timer

// ============================================================================
// CVAR POINTERS
// ============================================================================

// Discord toggle (separate from global discord.ini - allows disabling cvar spam specifically)
new gp_cvar_discord
new gp_cvar_match_competitive

// Silent-client tripwire thresholds (see liveness section for the math)
new gp_cvar_silent_queries
new gp_cvar_silent_grace

// KTP: Trie for O(1) cvar name → index lookup (replaces O(n) linear scan)
new Trie:g_cvarIndexTrie

// Discord config now loaded via ktp_discord.inc

// ============================================================================
// PLAYER DATA ARRAYS
// ============================================================================

new bool:gb_FirstCheckComplete[MAX_PLAYERS + 1]
new bool:gb_StopChecking[MAX_PLAYERS + 1]
new gi_cvarnumID[MAX_PLAYERS + 1]
new gs_enforcing_cvar[MAX_PLAYERS + 1][ENFORCE_CVAR_LEN]

// Periodic monitoring state
new gi_priority_cvar_index[MAX_PLAYERS + 1]  // Current index in priority cvar rotation
new gi_standard_cvar_index[MAX_PLAYERS + 1]  // Current index in standard cvar rotation

// Enforcement attempt tracking (detect cl_filterstuffcmd blocking)
new gi_enforce_attempts[MAX_PLAYERS + 1][TOTAL_CVARS]  // Count of failed enforcement attempts per cvar
new bool:gb_filterstuff_warned[MAX_PLAYERS + 1][TOTAL_CVARS]  // Already showed warning for this cvar
new bool:gb_hasViolations[MAX_PLAYERS + 1]  // Dirty flag: skip enforcement reset on disconnect if no violations
#define MAX_ENFORCE_ATTEMPTS 3  // After this many attempts, show cl_filterstuffcmd warning

// Deferred enforcement (moves expensive work out of opcode handler to prevent frame freezes)
// Uses per-cvar bitmask to queue multiple violations per player per frame
#define TASK_DEFER_ENFORCE 3000
new g_deferPending[MAX_PLAYERS + 1]        // bits 0-31: cvar indices needing enforcement
new g_deferPendingHi[MAX_PLAYERS + 1]      // bits 0-4: cvar indices 32-36
new Float:g_deferValue[MAX_PLAYERS + 1][TOTAL_CVARS]     // player's bad value per cvar
new Float:g_deferCalValue[MAX_PLAYERS + 1][TOTAL_CVARS]  // target float value per cvar

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

// File paths
new gs_directory[64]
new gs_fcosconfigfile[128]

// Player info (reused across functions)
new gs_logname[32]
new gs_logauthid[35]
new gs_logip[16]

// Discord violation buffering for grouped notifications — one buffer PER PLAYER
// (v7.31). A single global buffer let two players violating in the same 5s window
// evict and fragment each other's embed — the common case at match start, not an
// edge case. Slot is the index; identity is re-verified on authid for slot reuse.
#define DISCORD_NAME_LEN   32
#define DISCORD_AUTHID_LEN 35
#define DISCORD_IP_LEN     22
new g_discordPlayerName[MAX_PLAYERS + 1][DISCORD_NAME_LEN]
new g_discordPlayerAuthid[MAX_PLAYERS + 1][DISCORD_AUTHID_LEN]
new g_discordPlayerIp[MAX_PLAYERS + 1][DISCORD_IP_LEN]
new g_discordCvarNames[MAX_PLAYERS + 1][MAX_CVAR_VIOLATIONS][MAX_CVAR_NAME_LEN]
new Float:g_discordCvarValues[MAX_PLAYERS + 1][MAX_CVAR_VIOLATIONS]      // Player's bad value
new Float:g_discordCvarCorrected[MAX_PLAYERS + 1][MAX_CVAR_VIOLATIONS]   // Corrected to value
new g_discordCvarCounts[MAX_PLAYERS + 1][MAX_CVAR_VIOLATIONS]            // Repeat count per cvar
new g_discordViolationCount[MAX_PLAYERS + 1]                              // Unique cvars in buffer
new bool:g_discordPending[MAX_PLAYERS + 1]

// ============================================================================
// CVAR CHECKING ARRAYS
// ============================================================================

// Priority cvars: checked every PRIORITY_CHECK_INTERVAL (movement/network/visual exploits)
// v7.25: cl_lc and cl_lw removed from enforcement after deep audit confirmed
// no exploit surface (either flag = 0 is a strict self-handicap on the shooter).
// See KTPReHLDS sv_user.cpp:1284,1492 — gates lag-comp rewind on shooter's flags.
// AC detection rules don't depend on these. Player-asked permitting; documented
// trade-off in KTP Cvar List.
// v7.27: visual-cheat cvars promoted from the standard tier (review 2026-07-05
// #15) — at the 31s standard cycle a scripted toggle-peek-revert (fullbright/
// picmip peek for a few seconds) fit between checks. Render/visibility toggles
// now rotate with the netcode set.
new gs_priority_cvars[PRIORITY_CVARS_COUNT][] = {
"m_pitch", "cl_pitchdown", "cl_pitchup", "cl_updaterate", "cl_cmdrate",
"rate", "ex_interp",
"r_fullbright", "r_lightmap", "r_luminance", "gl_monolights", "gl_nocolors",
"gl_overbright", "gl_picmip", "r_drawentities"
}

// All cvars (for initial check and reference)
// Indices 0-29: exact value cvars, indices 30-36: range cvars (min/max)
//
// v7.24 (2026-04-28): re-added 7 cvars dropped in v7.13 (2026-02-17) under the
// false rationale "engine-limited values." All actually register with
// `pfnRegisterVariable(..., 0)` — flag 0 means no FCVAR_SERVER, no clamp,
// freely settable client-side. Indices 22-25 (keyboard-look — defeats
// alias-based no-recoil pulse scripts at cl_pitchspeed=9999 + 1000fps) and
// indices 26-28 (visual-class — gl_picmip enforced at 0 defeats picmip
// wallhack; r_glowshellfreq enforced at 2.2 = DoD default for integrity
// check only; r_traceglow enforced at 0 = its actual default).
//
// v7.25 (2026-04-28): removed cl_lc and cl_lw from enforcement after
// engine-source audit confirmed no exploit surface. HUD_TAKESSHOTS_INDEX and
// M_PITCH_INDEX shifted -2 (was 16,17 → now 14,15). MIN_MAX_CVAR_START shifted
// 33→31 to keep range cvars at logically the same positions.
//
// v7.26 (2026-04-29): r_glowshellfreq enforced value 0 → 2.2 (the actual DoD
// engine default). The original v7.24 rationale claimed enforcing 0 would
// "disable the entire glow-shell rendering path that ESPs hooked," but that
// reasoning broke twice: (1) DoD genuinely uses glow shells on flag carriers
// (gameplay element), so forcing 0 changes what players see vs. what the game
// designers shipped, and (2) clients with the natural default 2.2 were being
// kicked by the cvar checker for being "non-compliant" — friction without
// security benefit (an ESP attacker would just set 0 too). Enforcing the
// actual default keeps the integrity check (catches autoexec overrides) while
// removing the false-positive kick path.
//
// v7.30 (2026-07-11): removed cl_mousegrab from enforcement. It's a client-only
// SDL pointer-grab cvar (server never reads it — no netcode/hitreg/aim surface;
// aim deltas come from m_rawinput/recenter, not grab). The only retention
// rationale was MOSS compat, obsolete under KTPAntiCheat. Enforcing 1 forced
// windowed-mode players' cursor to catch monitor corners / break on alt-tab +
// multi-monitor and pushed them toward exclusive-fullscreen GL — the AntiCheat's
// screenshot-blind mode — so enforcement actively worked against capturability.
// Edge cases (accidental click-out mid-round) are pure self-handicaps, same as
// the v7.25 cl_lc/cl_lw removal. TOTAL_CVARS 38→37, MIN_MAX_CVAR_START 31→30,
// HUD_TAKESSHOTS/M_PITCH indices −1, STANDARD_CVARS_COUNT 23→22.
new gs_cvars[TOTAL_CVARS][] = {
"cl_bobcycle", "cl_bobup",
"cl_pitchdown", "cl_pitchup", "cl_showevents", "fastsprites", "gl_clear",
"gl_d3dflip", "gl_monolights", "gl_nobind", "gl_nocolors", "gl_overbright",
"gl_playermip", "hud_takesshots", "m_pitch", "r_drawentities", "r_drawviewmodel",
"r_dynamic", "r_fullbright", "r_lightmap", "r_luminance", "s_show",
"cl_pitchspeed", "cl_yawspeed", "cl_anglespeedkey", "m_side",
"gl_picmip", "r_glowshellfreq", "r_traceglow",
"texgamma", "lightgamma", "cl_bob", "cl_updaterate",
"cl_cmdrate", "rate", "ex_interp", "fps_max"
}

// Standard cvars (non-priority): checked via rotation every 1.0 seconds.
// DERIVED at init as gs_cvars minus gs_priority_cvars -- it used to be a
// hand-typed list that every cvar add/remove/retier had to be replayed into,
// with nothing checking the two agreed.
new gi_standardCvarIdx[TOTAL_CVARS]
new gi_standardCvarCount

new gs_calvalues[TOTAL_CVARS][] = {
"0.8", "0.5", "89", "89", "0", "0", "0",
"0", "0", "0", "0", "0", "0", "1", "0.022", "1", "1",
"1", "0", "0", "0", "0",
"225", "210", "0.67", "0.8",
"0", "2.2", "0",                  // gl_picmip, r_glowshellfreq, r_traceglow — see v7.26 note above for r_glowshellfreq=2.2 rationale
"2", "1.809", "0", "100",
"100", "100000", "0.009", "60"
}

// Range cvar upper bounds (paired with gs_calvalues lower bounds for indices >= MIN_MAX_CVAR_START).
// Index → range cvar:
//   0: lightgamma  (cal=1.809 → alt=3)
//   1: cl_bob      (cal=0     → alt=0.011)
//   2: cl_updaterate (cal=100 → alt=120)
//   3: cl_cmdrate  (cal=100   → alt=1000)   v7.25: was 500, raised to enable input-resolution testing
//   4: rate        (cal=alt=100000, locked single value)
//   5: ex_interp   (cal=0.009 → alt=0.05)
//   6: fps_max     (cal=60    → alt=750)
new gs_altvalues[ALT_VALUES_COUNT][] = {
"3", "0.011", "120", "1000", "100000", "0.05", "750"
}

// Pre-converted float arrays (performance optimization)
new Float:gf_calvalues[TOTAL_CVARS]
new Float:gf_altvalues[ALT_VALUES_COUNT]

// v7.27: initial-sweep query order — priority cvars first, then the rest.
// The old sweep walked gs_cvars[] in declaration order, so the cvars that
// matter most could sit at the tail of an ~11s sweep.
new g_queryOrder[TOTAL_CVARS]

// v7.27: /cvar re-entrancy guard — spamming the command stacked concurrent
// query chains sharing one gi_cvarnumID counter.
new bool:gb_initialCheckRunning[MAX_PLAYERS + 1]

// v7.28: silent-client liveness tripwire. A client that answers NO cvar
// queries produces zero callbacks — previously zero logs, zero enforcement,
// zero tripwire (the one clean bypass). Count consecutive unanswered queries;
// any response resets. Alert-only by fleet audit policy — never a kick.
new gi_unansweredQueries[MAX_PLAYERS + 1]     // consecutive queries with no response
new Float:gf_silenceStart[MAX_PLAYERS + 1]    // gametime of first query in current streak
new Float:gf_putinTime[MAX_PLAYERS + 1]       // gametime at putinserver (grace anchor)
new bool:gb_silentAlerted[MAX_PLAYERS + 1]    // one alert per silent streak

// v7.28: response dedup. The engine dispatches the query callback
// (fn_querycvar) then the client_cvar_changed forward back-to-back for the
// SAME response message (KTPReHLDS SV_ParseCvarValue2) — steady state was
// validating every response twice. fn_querycvar sets this; the forward
// consumes it and skips. Stale-mark edge (forward suppressed by the AMXX
// ingame guard) at worst skips one opportunistic validation — the next
// rotation query covers it.
new bool:gb_queryJustHandled[MAX_PLAYERS + 1]

// v7.29: per-tier liveness — closes the selective-blocking residual 7.28
// documented. A client answering only one rotation tier (e.g. everything
// EXCEPT the 0.3s visual tier, where the wallhack-relevant cvars live)
// resets the global counter forever while the blocked tier stays
// unvalidated. Each tier's counter resets only on a response resolved to
// that tier; the check is time-primary (both rotations have different
// cadences) with a minimum-query floor so it can't fire off a stall.
#define TIER_PRIORITY 0
#define TIER_STANDARD 1
#define TIER_SILENT_MIN_QUERIES 30
new gi_unansweredTier[MAX_PLAYERS + 1][2]
new Float:gf_tierSilenceStart[MAX_PLAYERS + 1][2]
new bool:gb_tierAlerted[MAX_PLAYERS + 1][2]
new bool:gb_isPriorityCvar[TOTAL_CVARS]
new gp_cvar_silent_tier_secs

// ============================================================================
// PLUGIN INITIALIZATION
// ============================================================================

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	KTP_RegisterVersion(PLUGIN_NAME, PLUGIN_VERSION)
	register_cvar("ktp_cvar_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY)

	// Discord toggle - enabled by default (now uses grouped notifications to reduce spam)
	gp_cvar_discord = register_cvar("ktp_cvar_discord", "1")

	// Silent-client tripwire. 300 unanswered ≈ 69s of total silence at the
	// steady ~4.3 q/s cadence — deliberately past the 60s engine timeout so a
	// dead connection is dropped before we alert; a query-blocking client
	// keeps sending move packets, never times out, and always gets here.
	// 0 disables. Grace covers slow loaders whose queued queries answer late.
	gp_cvar_silent_queries = register_cvar("ktp_cvar_silent_queries", "300")
	gp_cvar_silent_grace = register_cvar("ktp_cvar_silent_grace", "60.0")

	// Per-tier silence window (seconds). Time-primary because the two
	// rotations run at different cadences (priority ~3.3 q/s, standard
	// ~1 q/s); 90s means both tiers alert on comparable wall-clock silence.
	// 0 disables the tier tripwire (the global one keeps working).
	gp_cvar_silent_tier_secs = register_cvar("ktp_cvar_silent_tier_secs", "90.0")

	// Map full-list indexes to tiers once — name-compare at init avoids any
	// ordering dependency on the trie build (15x38 compares, one time).
	for (new p = 0; p < PRIORITY_CVARS_COUNT; p++) {
		for (new i = 0; i < TOTAL_CVARS; i++) {
			if (equal(gs_priority_cvars[p], gs_cvars[i])) {
				gb_isPriorityCvar[i] = true
				break
			}
		}
	}

	gi_standardCvarCount = 0
	for (new i = 0; i < TOTAL_CVARS; i++) {
		if (!gb_isPriorityCvar[i])
			gi_standardCvarIdx[gi_standardCvarCount++] = i
	}

	// A short count means a gs_priority_cvars entry matched nothing in gs_cvars
	// (typo, or a rename applied to one list only) -- that cvar is then enforced
	// by neither tier, which is silent by construction.
	if (gi_standardCvarCount != TOTAL_CVARS - PRIORITY_CVARS_COUNT) {
		log_amx("[%s] CVAR TIER MISMATCH: %d standard, expected %d -- a priority name does not exist in gs_cvars",
			PLUGIN_NAME, gi_standardCvarCount, TOTAL_CVARS - PRIORITY_CVARS_COUNT)
	}

	// Discord webhook logging now uses shared ktp_discord.inc

	// Register /cvar command for manual cvar check
	register_clcmd("say /cvar", "cmd_manual_check")
	register_clcmd("say_team /cvar", "cmd_manual_check")

	// Cache KTPMatchHandler's competitive mode cvar (may not exist yet at plugin_init)
	gp_cvar_match_competitive = get_cvar_pointer("ktp_match_competitive")

	register_dictionary("ktp_cvar.txt")
	get_configsdir(gs_directory, charsmax(gs_directory))
	formatex(gs_fcosconfigfile, charsmax(gs_fcosconfigfile), "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE)
	if (file_exists(gs_fcosconfigfile))
		server_cmd("exec %s", gs_fcosconfigfile)

	fn_init_float_arrays()
}

public plugin_cfg () {
	fn_servermessage()
	ktp_discord_load_config()
}

// ============================================================================
// INITIALIZATION FUNCTIONS
// ============================================================================

public fn_init_float_arrays() {
	// Build cvar name → index Trie for O(1) lookup in hot paths
	g_cvarIndexTrie = TrieCreate()
	for (new i = 0; i < TOTAL_CVARS; i++) {
		TrieSetCell(g_cvarIndexTrie, gs_cvars[i], i)
	}

	for (new i = 0; i < TOTAL_CVARS; i++) {
		gf_calvalues[i] = floatstr(gs_calvalues[i])
	}
	for (new i = 0; i < ALT_VALUES_COUNT; i++) {
		gf_altvalues[i] = floatstr(gs_altvalues[i])
	}

	// Build the initial-sweep order: priority cvars first, remainder after
	new bool:placed[TOTAL_CVARS]
	new orderPos = 0
	for (new p = 0; p < PRIORITY_CVARS_COUNT; p++) {
		new idx
		if (TrieGetCell(g_cvarIndexTrie, gs_priority_cvars[p], idx) && !placed[idx]) {
			g_queryOrder[orderPos++] = idx
			placed[idx] = true
		}
	}
	for (new i = 0; i < TOTAL_CVARS; i++) {
		if (!placed[i])
			g_queryOrder[orderPos++] = i
	}

	log_amx("[%s] Pre-converted %d cvar values to floats", PLUGIN_NAME, TOTAL_CVARS + ALT_VALUES_COUNT)
}

public fn_servermessage() {
	server_print("%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", PLUGIN_NAME, PLUGIN_VERSION, gs_year, PLUGIN_AUTHOR)
	server_print("%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG1")
	if (file_exists(gs_fcosconfigfile))
		server_print("%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG2")

	server_print("[%s] Monitoring %d cvars with priority-based system:", PLUGIN_NAME, TOTAL_CVARS)
	server_print("[%s] - Priority cvars (%d): checked every %.1f seconds", PLUGIN_NAME, PRIORITY_CVARS_COUNT, PRIORITY_CHECK_INTERVAL)
	server_print("[%s] - Standard cvars (%d): rotated every %.0f seconds", PLUGIN_NAME, gi_standardCvarCount, STANDARD_CHECK_INTERVAL)
	server_print("[%s] Enforcement: Auto-correct + console logging (Discord: %s)", PLUGIN_NAME, get_pcvar_num(gp_cvar_discord) ? "enabled" : "disabled")
}

// ============================================================================
// REAL-TIME CVAR DETECTION
// ============================================================================

/**
 * Real-time cvar change detection for ALL cvars
 * Requires KTP AMX with pfnClientCvarChanged callback
 *
 * @param id        Client index
 * @param cvar      Name of the cvar that changed
 * @param value     New value of the cvar
 */
public client_cvar_changed(id, const cvar[], const value[]) {
	// Validate player
	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id) || gb_StopChecking[id])
		return PLUGIN_CONTINUE

	// Any response = client is answering queries
	fn_note_response(id)

	// Consume the dedup mark before any early return so it can't go stale
	new bool:handledByQuery = gb_queryJustHandled[id]
	gb_queryJustHandled[id] = false

	// Only check after initial check complete
	if (!gb_FirstCheckComplete[id])
		return PLUGIN_CONTINUE

	// Skip if we just enforced this specific cvar (prevents re-triggering on our own correction)
	if (gs_enforcing_cvar[id][0] && equal(cvar, gs_enforcing_cvar[id])) {
		gs_enforcing_cvar[id][0] = 0
		return PLUGIN_CONTINUE
	}

	// fn_querycvar already validated this exact response — same engine message,
	// dispatched to the query callback one call before this forward
	if (handledByQuery)
		return PLUGIN_CONTINUE

	// Find cvar index via Trie (O(1) hash lookup instead of O(n) linear scan)
	new ci
	if (TrieGetCell(g_cvarIndexTrie, cvar, ci)) {
		fn_note_tier_response(id, ci)
		new Float:valueFromPlayer = floatstr(value)

		if (ci >= MIN_MAX_CVAR_START) {
			fn_checkaltallowed(id, ci, cvar, valueFromPlayer,
				gf_calvalues[ci], gf_altvalues[ci - MIN_MAX_CVAR_START],
				value, gs_calvalues[ci])
		}
		else {
			fn_checkvalues(id, ci, cvar, valueFromPlayer,
				gf_calvalues[ci], value, gs_calvalues[ci])
		}
	}

	return PLUGIN_CONTINUE
}

// ============================================================================
// CLIENT EVENTS
// ============================================================================

public fn_msginitial(id) {
	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id))
		return

	client_print(id, print_chat, "%s version %s by %s", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
}

public client_putinserver(id) {
	if (id < 1 || id > MAX_PLAYERS || is_user_bot(id) || is_user_hltv(id))
		return

	gb_FirstCheckComplete[id] = false
	gb_StopChecking[id] = false
	gb_initialCheckRunning[id] = false
	gi_priority_cvar_index[id] = 0
	gi_standard_cvar_index[id] = 0

	// v7.28: don't trust the previous occupant's disconnect to have run —
	// clear enforcement, defer, and liveness state on slot (re)use, and kill
	// any tasks still keyed to this slot.
	remove_task(id)
	remove_task(id + 1000)
	remove_task(id + 2000)
	remove_task(id + TASK_DEFER_ENFORCE)
	gs_enforcing_cvar[id][0] = 0
	g_deferPending[id] = 0
	g_deferPendingHi[id] = 0
	// v7.31: a new connection can beat the previous occupant's disconnect cleanup.
	// Flush any Discord batch still buffered on this slot (sent under the previous
	// occupant's stored identity) — this also clears the slot for the new player.
	flush_discord_violations(id)
	if (gb_hasViolations[id]) {
		for (new i = 0; i < TOTAL_CVARS; i++) {
			gi_enforce_attempts[id][i] = 0
			gb_filterstuff_warned[id][i] = false
		}
		gb_hasViolations[id] = false
	}
	gi_unansweredQueries[id] = 0
	gf_silenceStart[id] = 0.0
	gf_putinTime[id] = get_gametime()
	gb_silentAlerted[id] = false
	gb_queryJustHandled[id] = false
	for (new t = 0; t < 2; t++) {
		gi_unansweredTier[id][t] = 0
		gf_tierSilenceStart[id][t] = 0.0
		gb_tierAlerted[id][t] = false
	}

	set_task(5.0, "fn_msginitial", id)
	// v7.27: initial sweep starts at 1.0s (was 7.5s — a ~7.5s zero-enforcement
	// window per connect, repeatable by reconnecting). The sweep now queries
	// priority cvars first (g_queryOrder), so the cvars that matter are
	// checked within the first few seconds. Queries to a still-loading client
	// just queue in the reliable channel and answer once in-game.
	set_task(1.0, "fn_loopquery", id)

	// Start periodic monitoring after initial check completes
	set_task(10.0, "fn_start_monitoring", id)
}

public client_disconnected(id) {
	gb_StopChecking[id] = true
	remove_task(id)
	remove_task(id + 1000)  // priority monitoring task
	remove_task(id + 2000)  // standard monitoring task
	remove_task(id + TASK_DEFER_ENFORCE)  // deferred enforcement task
	g_deferPending[id] = 0
	g_deferPendingHi[id] = 0
	gb_FirstCheckComplete[id] = false
	gb_initialCheckRunning[id] = false
	gs_enforcing_cvar[id][0] = 0
	gi_unansweredQueries[id] = 0
	gb_silentAlerted[id] = false
	gb_queryJustHandled[id] = false

	// Flush any pending Discord violations for this player (sends + clears the slot)
	if (g_discordPending[id]) {
		flush_discord_violations(id)
	}

	// Reset enforcement tracking (only loop if player had violations)
	if (gb_hasViolations[id]) {
		for (new i = 0; i < TOTAL_CVARS; i++) {
			gi_enforce_attempts[id][i] = 0
			gb_filterstuff_warned[id][i] = false
		}
		gb_hasViolations[id] = false
	}
}

// ============================================================================
// MANUAL CVAR CHECK COMMAND
// ============================================================================

public cmd_manual_check(id) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED

	// Re-entrancy guard: a second /cvar while a sweep runs would stack a
	// concurrent query chain on the same gi_cvarnumID counter.
	if (gb_initialCheckRunning[id]) {
		client_print(id, print_console, "[%s] Cvar check already in progress...", PLUGIN_NAME)
		return PLUGIN_HANDLED
	}

	client_print(id, print_console, "[%s] Starting manual cvar check...", PLUGIN_NAME)
	fn_loopquery(id)
	return PLUGIN_HANDLED
}

// ============================================================================
// INITIAL CVAR CHECK
// ============================================================================

public fn_loopquery(id) {
	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) return
	if (gb_initialCheckRunning[id]) return
	gb_initialCheckRunning[id] = true
	gi_cvarnumID[id] = 0
	fn_query_parallel(id)
}

public fn_query_parallel(id) {
	if (id < 1 || id > MAX_PLAYERS) return
	if (gi_cvarnumID[id] >= TOTAL_CVARS) {
		fn_firstcomplete(id)
		return
	}

	// Send ONE query per tick (engine only processes ~1 callback per frame).
	// g_queryOrder puts the priority cvars at the front of the sweep.
	query_client_cvar(id, gs_cvars[g_queryOrder[gi_cvarnumID[id]]], "fn_querycvar")
	fn_note_query_sent(id)
	gi_cvarnumID[id]++

	if (gi_cvarnumID[id] < TOTAL_CVARS)
		set_task(INITIAL_SWEEP_INTERVAL, "fn_query_parallel", id)
	else
		fn_firstcomplete(id)
}

public fn_querycvar(id, const s_CVARNAME[], const s_VALUE[]) {
	if (id < 1 || id > MAX_PLAYERS) return
	fn_note_response(id)
	new Float:valueFromPlayer = floatstr(s_VALUE)

	// Find cvar index via Trie (O(1) hash lookup instead of O(n) linear scan)
	new cvar_index
	if (!TrieGetCell(g_cvarIndexTrie, s_CVARNAME, cvar_index))
		return

	// The client_cvar_changed forward fires next for this same response —
	// mark it handled so we don't validate twice
	gb_queryJustHandled[id] = true

	fn_note_tier_response(id, cvar_index)

	if (cvar_index >= MIN_MAX_CVAR_START) {
		fn_checkaltallowed(id, cvar_index, s_CVARNAME, valueFromPlayer,
			gf_calvalues[cvar_index], gf_altvalues[cvar_index - MIN_MAX_CVAR_START],
			s_VALUE, gs_calvalues[cvar_index])
	}
	else {
		fn_checkvalues(id, cvar_index, s_CVARNAME, valueFromPlayer,
			gf_calvalues[cvar_index], s_VALUE, gs_calvalues[cvar_index])
	}
}

public fn_firstcomplete(id) {
	if (id < 1 || id > MAX_PLAYERS) return
	gb_initialCheckRunning[id] = false
	if (!gb_FirstCheckComplete[id]) {
		gb_FirstCheckComplete[id] = true
	}
}

// ============================================================================
// PERIODIC MONITORING SYSTEM
// ============================================================================

/**
 * Start periodic monitoring after initial check completes.
 * One cvar per tick per rotation; full cycle = list count * interval
 * (see PRIORITY_CHECK_INTERVAL / STANDARD_CHECK_INTERVAL).
 */
public fn_start_monitoring(id) {
	if (id < 1 || id > MAX_PLAYERS) return
	if (!is_user_connected(id) || gb_StopChecking[id])
		return

	// Ensure FirstCheckComplete is set — periodic monitoring should not be gated on initial check
	if (!gb_FirstCheckComplete[id]) {
		gb_FirstCheckComplete[id] = true
	}

	// Start priority cvar checks (one cvar per PRIORITY_CHECK_INTERVAL)
	set_task(PRIORITY_CHECK_INTERVAL, "fn_check_priority_cvars", id + 1000, "", 0, "b")

	// Start standard cvar rotation (one cvar per STANDARD_CHECK_INTERVAL)
	set_task(STANDARD_CHECK_INTERVAL, "fn_check_standard_cvars", id + 2000, "", 0, "b")

	// Removed: log_amx per-player monitoring start — 24 disk writes per match connect wave
}

/**
 * Check one priority cvar per call (every PRIORITY_CHECK_INTERVAL)
 * These are the most critical anti-cheat cvars
 */
public fn_check_priority_cvars(taskid) {
	new id = taskid - 1000

	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id) || gb_StopChecking[id] || !gb_FirstCheckComplete[id])
		return

	// Send ONE query per tick (engine only processes ~1 callback per frame)
	new idx = gi_priority_cvar_index[id]
	query_client_cvar(id, gs_priority_cvars[idx], "fn_querycvar")
	fn_note_query_sent(id)
	fn_note_tier_query(id, TIER_PRIORITY)

	// Rotate to next priority cvar
	gi_priority_cvar_index[id] = (idx + 1) % PRIORITY_CVARS_COUNT
}

/**
 * Check one standard cvar per call (every STANDARD_CHECK_INTERVAL)
 * Cycles through all standard cvars via rotation
 */
public fn_check_standard_cvars(taskid) {
	new id = taskid - 2000

	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id) || gb_StopChecking[id] || !gb_FirstCheckComplete[id])
		return

	// Send ONE query per tick (engine only processes ~1 callback per frame)
	// Guards the modulo below: every cvar being priority would divide by zero.
	if (gi_standardCvarCount < 1)
		return

	new idx = gi_standard_cvar_index[id]
	query_client_cvar(id, gs_cvars[gi_standardCvarIdx[idx]], "fn_querycvar")
	fn_note_query_sent(id)
	fn_note_tier_query(id, TIER_STANDARD)

	// Rotate to next standard cvar
	gi_standard_cvar_index[id] = (idx + 1) % gi_standardCvarCount
}

// ============================================================================
// SILENT-CLIENT LIVENESS TRIPWIRE (v7.28)
// ============================================================================

/**
 * Called at every query_client_cvar site. Tracks consecutive unanswered
 * queries; crossing the threshold after the connect grace fires a one-shot
 * audit alert. Alert-only — a silent client is a review flag, not a kick.
 */
stock fn_note_query_sent(id) {
	if (gi_unansweredQueries[id] == 0)
		gf_silenceStart[id] = get_gametime()
	gi_unansweredQueries[id]++

	if (gb_silentAlerted[id])
		return

	new threshold = get_pcvar_num(gp_cvar_silent_queries)
	if (threshold <= 0 || gi_unansweredQueries[id] < threshold)
		return

	// Grace after putinserver — a still-loading client's queries queue in the
	// reliable channel and answer late; don't flag them
	if (get_gametime() - gf_putinTime[id] < get_pcvar_float(gp_cvar_silent_grace))
		return

	fn_alert_query_silence(id)
}

// Any response (query callback or forward) proves the client answers queries
stock fn_note_response(id) {
	// Recovery from a TOTAL-silence stretch (network stall, alt-tab, load
	// hitch) contaminated both tier counters — they kept accumulating while
	// tier alerts were suppressed. Reset them here or the sibling tier's
	// stale counter fires a false "selective blocking" accusation on its
	// next query, before that tier's own response arrives. A genuinely
	// selective client re-accumulates the blocked tier and fires ~90s later.
	if (gb_silentAlerted[id] || gi_unansweredQueries[id] >= TIER_SILENT_MIN_QUERIES) {
		for (new t = 0; t < 2; t++) {
			gi_unansweredTier[id][t] = 0
			gf_tierSilenceStart[id][t] = 0.0
			gb_tierAlerted[id][t] = false
		}
	}
	gi_unansweredQueries[id] = 0
	gb_silentAlerted[id] = false
}

/**
 * v7.29: tier-scoped query note. Time-primary threshold (the tiers run at
 * different cadences) with a minimum-query floor; suppressed while the
 * global total-silence alert is latched (total silence is the stronger,
 * already-fired signal — tier alerts are for the SELECTIVE case).
 */
stock fn_note_tier_query(id, tier) {
	if (gi_unansweredTier[id][tier] == 0)
		gf_tierSilenceStart[id][tier] = get_gametime()
	gi_unansweredTier[id][tier]++

	if (gb_tierAlerted[id][tier] || gb_silentAlerted[id])
		return

	// Not "selective" if the client is globally silent right now — the
	// embed's claim that other queries ARE being answered must be true
	// (also covers the global tripwire being disabled/raised).
	if (gi_unansweredQueries[id] >= TIER_SILENT_MIN_QUERIES)
		return

	new Float:windowSecs = get_pcvar_float(gp_cvar_silent_tier_secs)
	if (windowSecs <= 0.0 || gi_unansweredTier[id][tier] < TIER_SILENT_MIN_QUERIES)
		return
	if (get_gametime() - gf_tierSilenceStart[id][tier] < windowSecs)
		return
	if (get_gametime() - gf_putinTime[id] < get_pcvar_float(gp_cvar_silent_grace))
		return

	fn_alert_tier_silence(id, tier)
}

// A response resolved to a tracked cvar proves delivery for that cvar's tier
stock fn_note_tier_response(id, cvar_index) {
	new tier = gb_isPriorityCvar[cvar_index] ? TIER_PRIORITY : TIER_STANDARD
	gi_unansweredTier[id][tier] = 0
	gb_tierAlerted[id][tier] = false
}

stock fn_alert_tier_silence(id, tier) {
	gb_tierAlerted[id][tier] = true

	get_user_name(id, gs_logname, charsmax(gs_logname))
	get_user_authid(id, gs_logauthid, charsmax(gs_logauthid))
	get_user_ip(id, gs_logip, charsmax(gs_logip), 1)

	new tierName[12]
	copy(tierName, charsmax(tierName), tier == TIER_PRIORITY ? "priority" : "standard")
	new Float:window = get_gametime() - gf_tierSilenceStart[id][tier]

	log_amx("[%s] event=CVAR_TIER_SILENT tier=%s sid=%s name=%s ip=%s unanswered=%d window_s=%.1f",
		PLUGIN_NAME, tierName, gs_logauthid, gs_logname, gs_logip, gi_unansweredTier[id][tier], window)

	if (get_pcvar_num(gp_cvar_discord) && ktp_discord_is_enabled()) {
		new description[512]
		formatex(description, charsmax(description),
			"**Player:** %s^n**SteamID:** %s^n**IP:** %s^n^n%d consecutive %s-tier cvar queries unanswered over %.0f seconds while OTHER queries are being answered — selective-blocking signature (that tier's cvars are unvalidated for this client). Tripwire only, no action taken.",
			gs_logname, gs_logauthid, gs_logip, gi_unansweredTier[id][tier], tierName, window)
		ktp_discord_send_embed_audit("<:KTP:1002382703020212245> CVAR Tier Silence", description, KTP_DISCORD_COLOR_RED)
	}
}

stock fn_alert_query_silence(id) {
	gb_silentAlerted[id] = true

	get_user_name(id, gs_logname, charsmax(gs_logname))
	get_user_authid(id, gs_logauthid, charsmax(gs_logauthid))
	get_user_ip(id, gs_logip, charsmax(gs_logip), 1)

	new Float:window = get_gametime() - gf_silenceStart[id]

	log_amx("[%s] event=CVAR_QUERY_SILENT sid=%s name=%s ip=%s unanswered=%d window_s=%.1f",
		PLUGIN_NAME, gs_logauthid, gs_logname, gs_logip, gi_unansweredQueries[id], window)

	if (get_pcvar_num(gp_cvar_discord) && ktp_discord_is_enabled()) {
		new description[512]
		formatex(description, charsmax(description),
			"**Player:** %s^n**SteamID:** %s^n**IP:** %s^n^n%d consecutive cvar queries unanswered over %.0f seconds.^nClient is answering no cvar queries at all — enforcement is blind to it. Tripwire only, no action taken.",
			gs_logname, gs_logauthid, gs_logip, gi_unansweredQueries[id], window)
		ktp_discord_send_embed_audit("<:KTP:1002382703020212245> CVAR Query Silence", description, KTP_DISCORD_COLOR_RED)
	}
}

// ============================================================================
// CVAR VALIDATION FUNCTIONS
// ============================================================================

public fn_checkvalues(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	new bool: isInvalid = false

	if (cvar_index == M_PITCH_INDEX) {
		if (!(floatabs(valueFromPlayer - calFloatValue) <= FLOAT_PRECISION ||
			  floatabs(valueFromPlayer + calFloatValue) <= FLOAT_PRECISION ||
			  equal(s_VALUE, inverse_p) || equal(s_VALUE, s_CALVALUE))) {
			isInvalid = true
		}
	}
	else {
		if (!(floatabs(valueFromPlayer - calFloatValue) <= FLOAT_PRECISION || equal(s_VALUE, s_CALVALUE))) {
			isInvalid = true
		}
	}

	if (isInvalid) {
		defer_enforcement(id, cvar_index, valueFromPlayer, calFloatValue)
	} else {
		// Cvar is valid - reset enforcement tracking for this cvar
		fn_reset_enforce_tracking(id, cvar_index)
	}
}

public fn_checkaltallowed(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, Float: altFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	if (valueFromPlayer < calFloatValue) {
		// Below minimum — correct to minimum
		defer_enforcement(id, cvar_index, valueFromPlayer, calFloatValue)
	} else if (valueFromPlayer > altFloatValue) {
		// Above maximum — correct to maximum
		defer_enforcement(id, cvar_index, valueFromPlayer, altFloatValue)
	} else {
		// Cvar is valid - reset enforcement tracking for this cvar
		fn_reset_enforce_tracking(id, cvar_index)
	}
}

/**
 * Defer cvar enforcement to next frame via set_task(0.0)
 * Moves expensive work (get_user_*, log_amx, client_print broadcast) out of the
 * clc_cvarvalue2 opcode handler to prevent 160-185ms server frame freezes.
 */
stock defer_enforcement(id, cvar_index, Float:valueFromPlayer, Float:calFloatValue) {
	// Set pending bit for this cvar index
	if (cvar_index < 32)
		g_deferPending[id] |= (1 << cvar_index)
	else
		g_deferPendingHi[id] |= (1 << (cvar_index - 32))

	// Store per-cvar data
	g_deferValue[id][cvar_index] = valueFromPlayer
	g_deferCalValue[id][cvar_index] = calFloatValue
	// Schedule for next frame (only if not already scheduled)
	if (!task_exists(id + TASK_DEFER_ENFORCE))
		set_task(0.0, "task_deferred_enforce", id + TASK_DEFER_ENFORCE)
}

public task_deferred_enforce(taskid) {
	new id = taskid - TASK_DEFER_ENFORCE
	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id))
		return

	// Process all pending cvar violations for this player
	for (new idx = 0; idx < TOTAL_CVARS; idx++) {
		new pending
		if (idx < 32)
			pending = g_deferPending[id] & (1 << idx)
		else
			pending = g_deferPendingHi[id] & (1 << (idx - 32))

		if (!pending)
			continue

		fn_enforce_cvar(id, idx, gs_cvars[idx],
			g_deferValue[id][idx], g_deferCalValue[id][idx])
	}

	g_deferPending[id] = 0
	g_deferPendingHi[id] = 0
}

// Reset enforcement tracking when cvar becomes valid
stock fn_reset_enforce_tracking(id, cvar_index) {
	if (gi_enforce_attempts[id][cvar_index] > 0) {
		gi_enforce_attempts[id][cvar_index] = 0
		gb_filterstuff_warned[id][cvar_index] = false
	}
}

// ============================================================================
// ENFORCEMENT & PUNISHMENT
// ============================================================================

stock fn_enforce_cvar(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue) {
	if (gb_StopChecking[id])
		return PLUGIN_CONTINUE

	// Skip hud_takesshots enforcement for non-competitive matches (12man, scrim, draft)
	// ktp_match_competitive is set by KTPMatchHandler: 1 = .ktp/.ktpOT, 0 = casual modes
	if (cvar_index == HUD_TAKESSHOTS_INDEX) {
		// Re-cache pointer if not found at init (KTPMatchHandler may load after us)
		if (!gp_cvar_match_competitive)
			gp_cvar_match_competitive = get_cvar_pointer("ktp_match_competitive")
		if (gp_cvar_match_competitive && get_pcvar_num(gp_cvar_match_competitive) == 0)
			return PLUGIN_CONTINUE
	}

	// Increment enforcement attempt counter
	gi_enforce_attempts[id][cvar_index]++
	gb_hasViolations[id] = true

	// Get player info (needed for both warning and normal enforcement)
	get_user_name(id, gs_logname, charsmax(gs_logname))
	get_user_authid(id, gs_logauthid, charsmax(gs_logauthid))
	get_user_ip(id, gs_logip, charsmax(gs_logip), 1)

	if (gs_logname[0] == 0 || gs_logauthid[0] == 0) {
		log_amx("[%s] WARNING: Player %d disconnected before logging violation", PLUGIN_NAME, id)
		return PLUGIN_CONTINUE
	}

	// Check if enforcement is being blocked (likely cl_filterstuffcmd 1)
	if (gi_enforce_attempts[id][cvar_index] >= MAX_ENFORCE_ATTEMPTS) {
		// Only show warning once per cvar until player fixes it
		if (!gb_filterstuff_warned[id][cvar_index]) {
			gb_filterstuff_warned[id][cvar_index] = true

			// Send warning to the player
			client_print(id, print_chat, "")
			client_print(id, print_chat, "[KTP] ========== CVAR ENFORCEMENT BLOCKED ==========")
			client_print(id, print_chat, "[KTP] You need to set cl_filterstuffcmd to 0")
			client_print(id, print_chat, "[KTP] You are in violation of: %s (current: %.2f, required: %.2f)", s_CVARNAME, valueFromPlayer, calFloatValue)
			client_print(id, print_chat, "[KTP] Unless you change cl_filterstuffcmd to 0, or manually")
			client_print(id, print_chat, "[KTP] adjust %s, you are unable to participate in this", s_CVARNAME)
			client_print(id, print_chat, "[KTP] match by KTP rules.")
			client_print(id, print_chat, "[KTP] ================================================")
			client_print(id, print_chat, "")

			// Also show in console with more detail
			client_print(id, print_console, "")
			client_print(id, print_console, "========== KTP CVAR ENFORCEMENT BLOCKED ==========")
			client_print(id, print_console, "Your client is blocking server cvar corrections.")
			client_print(id, print_console, "This is typically caused by cl_filterstuffcmd 1")
			client_print(id, print_console, "")
			client_print(id, print_console, "VIOLATION: %s", s_CVARNAME)
			client_print(id, print_console, "  Your value:    %.3f", valueFromPlayer)
			client_print(id, print_console, "  Required:      %.3f", calFloatValue)
			client_print(id, print_console, "")
			client_print(id, print_console, "TO FIX: Type in console:")
			client_print(id, print_console, "  cl_filterstuffcmd 0")
			client_print(id, print_console, "  %s %.3f", s_CVARNAME, calFloatValue)
			client_print(id, print_console, "")
			client_print(id, print_console, "Until this is resolved, you cannot participate")
			client_print(id, print_console, "in competitive matches per KTP rules.")
			client_print(id, print_console, "==================================================")
			client_print(id, print_console, "")

			// Log this escalation
			log_amx("[%s] FILTERSTUFF_BLOCKED: %s <%s> (%s) - %s stuck at %.2f (required %.2f) after %d attempts",
				PLUGIN_NAME, gs_logname, gs_logauthid, gs_logip, s_CVARNAME, valueFromPlayer, calFloatValue, gi_enforce_attempts[id][cvar_index])

			// Announce to all players that this player is blocked
			client_print(0, print_chat, "[%s] %s has blocked cvar enforcement (%s) - cannot participate until fixed", PLUGIN_NAME, gs_logname, s_CVARNAME)
		}
		// Don't spam - just silently skip further enforcement attempts
		return PLUGIN_CONTINUE
	}

	new bool:is_pitch = (cvar_index == M_PITCH_INDEX)

	// Store enforced cvar name to prevent recursion (only skips this specific cvar's response)
	copy(gs_enforcing_cvar[id], ENFORCE_CVAR_LEN - 1, s_CVARNAME)

	// Force correct value on client
	if (is_pitch && (valueFromPlayer < 0.0)) {
		client_cmd(id, "%s %s", s_CVARNAME, inverse_p)
	}
	else if (is_pitch && (valueFromPlayer >= 0.0)) {
		client_cmd(id, "%s %s", s_CVARNAME, gs_calvalues[M_PITCH_INDEX])
	}
	else if (calFloatValue >= 100.0) {
		new intValue = floatround(calFloatValue, floatround_floor)
		client_cmd(id, "%s %d", s_CVARNAME, intValue)
	}
	else {
		client_cmd(id, "%s %.3f", s_CVARNAME, calFloatValue)
	}

	// Log violation
	log_amx("%L", LANG_SERVER, "FCOS_LANG_LOG_ENTRY", gs_logauthid, gs_logname, gs_logip, s_CVARNAME, valueFromPlayer, calFloatValue)

	// Announce to all players (use integer format for large values like rate/cmdrate)
	if (calFloatValue >= 100.0)
		client_print(0, print_chat, "[%s] %s had invalid %s (%d) - corrected to %d", PLUGIN_NAME, gs_logname, s_CVARNAME, floatround(valueFromPlayer, floatround_floor), floatround(calFloatValue, floatround_floor))
	else
		client_print(0, print_chat, "[%s] %s had invalid %s (%.3f) - corrected to %.3f", PLUGIN_NAME, gs_logname, s_CVARNAME, valueFromPlayer, calFloatValue)

	// Buffer violation for grouped Discord notification
	// Only if ktp_cvar_discord is enabled (disabled by default to reduce spam)
	if (get_pcvar_num(gp_cvar_discord) && ktp_discord_is_enabled()) {
		buffer_discord_violation(id, s_CVARNAME, valueFromPlayer, calFloatValue)
	}

	return PLUGIN_CONTINUE
}

// ============================================================================
// DISCORD NOTIFICATION BUFFERING
// ============================================================================

/**
 * Buffer a cvar violation for grouped Discord notification
 * Groups multiple violations per player into a single embed
 * Tracks repeat violations with count
 */
stock buffer_discord_violation(id, const cvar_name[], Float:player_value, Float:corrected_value) {
	// Slot reused inside the 5s batch window (disconnect + new connect on the
	// same slot): the buffer still holds the previous occupant's violations under
	// their authid. Flush that batch under its own identity before starting fresh
	// (v7.27 SteamID-keyed detection, the FileChecker 2.6 pattern).
	if (g_discordViolationCount[id] > 0 && !equal(g_discordPlayerAuthid[id], gs_logauthid)) {
		flush_discord_violations(id)
	}

	// New batch for this slot: pin identity.
	if (g_discordViolationCount[id] == 0) {
		copy(g_discordPlayerAuthid[id], DISCORD_AUTHID_LEN - 1, gs_logauthid)
	}

	// CV-02: refresh name/IP on every violation, not just when the batch opens —
	// a mid-window rename would otherwise show a stale name in the embed. These
	// are already fetched fresh into gs_logname/gs_logip by fn_enforce_cvar right
	// before this call, so it's a copy, not a new lookup.
	copy(g_discordPlayerName[id], DISCORD_NAME_LEN - 1, gs_logname)
	copy(g_discordPlayerIp[id], DISCORD_IP_LEN - 1, gs_logip)

	// Check if this cvar is already in the buffer (repeat violation)
	new cvar_index = -1
	for (new i = 0; i < g_discordViolationCount[id]; i++) {
		if (equal(g_discordCvarNames[id][i], cvar_name)) {
			cvar_index = i
			break
		}
	}

	if (cvar_index >= 0) {
		// Existing cvar - increment count and update values
		g_discordCvarCounts[id][cvar_index]++
		g_discordCvarValues[id][cvar_index] = player_value
		g_discordCvarCorrected[id][cvar_index] = corrected_value
	} else if (g_discordViolationCount[id] < MAX_CVAR_VIOLATIONS) {
		// New cvar - add to buffer
		new n = g_discordViolationCount[id]
		copy(g_discordCvarNames[id][n], MAX_CVAR_NAME_LEN - 1, cvar_name)
		g_discordCvarValues[id][n] = player_value
		g_discordCvarCorrected[id][n] = corrected_value
		g_discordCvarCounts[id][n] = 1
		g_discordViolationCount[id]++
	}

	// Schedule Discord send with per-player task ID (reset timer on each new violation)
	remove_task(id + TASK_DISCORD_SEND)
	g_discordPending[id] = true
	set_task(DISCORD_DELAY, "send_discord_violations", id + TASK_DISCORD_SEND)
}

/**
 * Task callback: flush this player's buffered violations as one grouped embed.
 * taskid is the slot offset by TASK_DISCORD_SEND.
 */
public send_discord_violations(taskid) {
	flush_discord_violations(taskid - TASK_DISCORD_SEND)
}

/**
 * Build + send one player's buffered violations as a single grouped Discord embed,
 * then clear that player's buffer. Safe to call directly (slot reuse / disconnect
 * flush) or via the task callback.
 */
flush_discord_violations(id) {
	if (id < 1 || id > MAX_PLAYERS)
		return

	remove_task(id + TASK_DISCORD_SEND)
	g_discordPending[id] = false

	if (g_discordViolationCount[id] == 0)
		return

	// Build description with all cvars
	new description[2048]
	new pos = 0

	// Calculate total violations (sum of all counts)
	new total_violations = 0
	for (new i = 0; i < g_discordViolationCount[id]; i++) {
		total_violations += g_discordCvarCounts[id][i]
	}

	pos += formatex(description[pos], charsmax(description) - pos,
		"**Player:** %s^n**SteamID:** %s^n**IP:** %s^n^n**Violations (%d total, %d unique):**^n",
		g_discordPlayerName[id], g_discordPlayerAuthid[id], g_discordPlayerIp[id], total_violations, g_discordViolationCount[id])

	// Add cvar list (use integer format for large values like rate/cmdrate)
	for (new i = 0; i < g_discordViolationCount[id] && pos < charsmax(description) - 100; i++) {
		new bool:isLarge = (g_discordCvarCorrected[id][i] >= 100.0)
		if (g_discordCvarCounts[id][i] > 1) {
			if (isLarge)
				pos += formatex(description[pos], charsmax(description) - pos,
					"• **%s** (x%d): %d → %d^n",
					g_discordCvarNames[id][i], g_discordCvarCounts[id][i],
					floatround(g_discordCvarValues[id][i], floatround_floor), floatround(g_discordCvarCorrected[id][i], floatround_floor))
			else
				pos += formatex(description[pos], charsmax(description) - pos,
					"• **%s** (x%d): %.3f → %.3f^n",
					g_discordCvarNames[id][i], g_discordCvarCounts[id][i],
					g_discordCvarValues[id][i], g_discordCvarCorrected[id][i])
		} else {
			if (isLarge)
				pos += formatex(description[pos], charsmax(description) - pos,
					"• **%s**: %d → %d^n",
					g_discordCvarNames[id][i],
					floatround(g_discordCvarValues[id][i], floatround_floor), floatround(g_discordCvarCorrected[id][i], floatround_floor))
			else
				pos += formatex(description[pos], charsmax(description) - pos,
					"• **%s**: %.3f → %.3f^n",
					g_discordCvarNames[id][i],
					g_discordCvarValues[id][i], g_discordCvarCorrected[id][i])
		}
	}

	// Send to audit channel
	ktp_discord_send_embed_audit("<:KTP:1002382703020212245> CVAR Violations", description, KTP_DISCORD_COLOR_ORANGE)

	// Reset this player's buffer
	g_discordViolationCount[id] = 0
	g_discordPlayerAuthid[id][0] = 0
}

// ============================================================================
// DISCORD INTEGRATION
// ============================================================================
// Discord webhook logging now handled by ktp_discord.inc
// Config loaded from discord.ini via ktp_discord_load_config()
// Messages sent via ktp_discord_send_embed_audit()

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
 *{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
 */
