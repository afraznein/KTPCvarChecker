/*
 *   Title:    KTP Cvar Settings (fcos)
 *   Author:   Nein_
 *
 *   Current Version:   7.17
 *   Release Date:      2026-02-25
 *
 *   Changelog:
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

// ============================================================================
// PLUGIN INFORMATION
// ============================================================================

new const gs_PLUGIN[] = "KTP Cvar Checker";
new const gs_VERSION[] = "7.17";
new const gs_AUTHOR[] = "Nein_";
new const gs_year     = 2026;

// ============================================================================
// CONSTANTS & DEFINES
// ============================================================================

// File configuration
new const gs_FILENAME[] = "ktp_cvar";
new const gs_FILETYPE[] = ".cfg";

// Special cvar names
new const gs_pitch[] = "m_pitch";
new const inverse_p[] = "-0.022";

// Precision constant for float comparisons
new const Float: FLOAT_PRECISION = 0.00005;

// Array size constants
#define TOTAL_CVARS 34
#define MIN_MAX_CVAR_START 26
#define ALT_VALUES_COUNT 8

// Queries per tick (engine only processes ~1 callback per frame)
#define QUERIES_PER_TICK 1

// Rate limiting
#define CHECK_RATE_LIMIT 1  // Minimum 1 second between checks per player

// Priority-based monitoring intervals (1 query per tick due to engine limitation)
#define PRIORITY_CHECK_INTERVAL 0.5   // Priority cvar rotation: 1 cvar every 0.5s (full cycle: 4.5s for 9 cvars)
#define STANDARD_CHECK_INTERVAL 1.0   // Standard cvar rotation: 1 cvar every 1.0s (full cycle: 25s for 25 cvars)

// Priority cvar count
#define PRIORITY_CVARS_COUNT 9

// Discord notification grouping
#define DISCORD_DELAY 5.0          // Delay to batch violations before sending Discord
#define MAX_CVAR_VIOLATIONS 32     // Max unique cvars to buffer per player
#define MAX_CVAR_NAME_LEN 32       // Max cvar name length

// ============================================================================
// CVAR POINTERS
// ============================================================================

// Discord toggle (separate from global discord.ini - allows disabling cvar spam specifically)
new gp_cvar_discord

// Discord config now loaded via ktp_discord.inc

// ============================================================================
// PLAYER DATA ARRAYS
// ============================================================================

new bool:gb_FirstCheckComplete[MAX_PLAYERS + 1]
new bool:gb_StopChecking[MAX_PLAYERS + 1]
new gi_cvarnumID[MAX_PLAYERS + 1]
new gi_last_check_time[MAX_PLAYERS + 1]
new bool:gb_enforcing_cvar[MAX_PLAYERS + 1]

// Periodic monitoring state
new gi_priority_cvar_index[MAX_PLAYERS + 1]  // Current index in priority cvar rotation
new gi_standard_cvar_index[MAX_PLAYERS + 1]  // Current index in standard cvar rotation

// Enforcement attempt tracking (detect cl_filterstuffcmd blocking)
new gi_enforce_attempts[MAX_PLAYERS + 1][TOTAL_CVARS]  // Count of failed enforcement attempts per cvar
new bool:gb_filterstuff_warned[MAX_PLAYERS + 1][TOTAL_CVARS]  // Already showed warning for this cvar
#define MAX_ENFORCE_ATTEMPTS 3  // After this many attempts, show cl_filterstuffcmd warning

// Deferred enforcement (moves expensive work out of opcode handler to prevent frame freezes)
#define TASK_DEFER_ENFORCE 3000
new g_deferCvarIndex[MAX_PLAYERS + 1]
new g_deferCvarName[MAX_PLAYERS + 1][MAX_CVAR_NAME_LEN]
new Float:g_deferValue[MAX_PLAYERS + 1]
new Float:g_deferCalValue[MAX_PLAYERS + 1]
new g_deferCalStr[MAX_PLAYERS + 1][16]

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

// Discord violation buffering for grouped notifications
new g_discordPlayerId
new g_discordPlayerName[32]
new g_discordPlayerAuthid[35]
new g_discordPlayerIp[22]
new g_discordCvarNames[MAX_CVAR_VIOLATIONS][MAX_CVAR_NAME_LEN]
new Float:g_discordCvarValues[MAX_CVAR_VIOLATIONS]      // Player's bad value
new Float:g_discordCvarCorrected[MAX_CVAR_VIOLATIONS]   // Corrected to value
new g_discordCvarCounts[MAX_CVAR_VIOLATIONS]            // Repeat count per cvar
new g_discordViolationCount                              // Unique cvars in buffer
new bool:g_discordPending

// ============================================================================
// CVAR CHECKING ARRAYS
// ============================================================================

// Priority cvars: checked every 2 seconds (movement/network/performance exploits)
new gs_priority_cvars[PRIORITY_CVARS_COUNT][] = {
"m_pitch", "cl_pitchdown", "cl_pitchup", "cl_updaterate", "cl_cmdrate",
"rate", "ex_interp", "cl_lc", "cl_lw"
}

// All cvars (for initial check and reference)
// Indices 0-25: exact value cvars, indices 26-33: range cvars (min/max)
new gs_cvars[TOTAL_CVARS][] = {
"cl_bobcycle", "cl_bobup", "cl_lc", "cl_lw", "cl_mousegrab",
"cl_pitchdown", "cl_pitchup", "cl_showevents", "fastsprites", "gl_clear",
"gl_d3dflip", "gl_monolights", "gl_nobind", "gl_nocolors", "gl_overbright",
"gl_playermip", "hud_takesshots", "m_pitch", "r_drawentities", "r_drawviewmodel",
"r_dynamic", "r_fullbright", "r_lightmap", "r_luminance", "s_show",
"texgamma", "lightgamma", "cl_smoothtime", "cl_bob", "cl_updaterate",
"cl_cmdrate", "rate", "ex_interp", "fps_max"
}

// Standard cvars (non-priority): checked via rotation every 10 seconds
// Excludes the 9 priority cvars listed above
#define STANDARD_CVARS_COUNT 25
new gs_standard_cvars[STANDARD_CVARS_COUNT][] = {
"cl_bobcycle", "cl_bobup", "cl_mousegrab", "cl_showevents", "fastsprites",
"gl_clear", "gl_d3dflip", "gl_monolights", "gl_nobind", "gl_nocolors",
"gl_overbright", "gl_playermip", "hud_takesshots", "r_drawentities", "r_drawviewmodel",
"r_dynamic", "r_fullbright", "r_lightmap", "r_luminance", "s_show",
"texgamma", "lightgamma", "cl_smoothtime", "cl_bob", "fps_max"
}

new gs_calvalues[TOTAL_CVARS][] = {
"0.8", "0.5", "1", "1", "1", "89", "89", "0", "0", "0",
"0", "0", "0", "0", "0", "0", "1", "0.022", "1", "1",
"1", "0", "0", "0", "0", "2", "1.81", "0", "0", "100",
"100", "100000", "0", "60"
}

new gs_altvalues[ALT_VALUES_COUNT][] = {
"3", "0.1", "0.011", "200", "500", "1000000", "0.03", "750"
}

// Cvar loop variable
new gi_cvarnum

// Pre-converted float arrays (performance optimization)
new Float:gf_calvalues[TOTAL_CVARS]
new Float:gf_altvalues[ALT_VALUES_COUNT]

// ============================================================================
// PLUGIN INITIALIZATION
// ============================================================================

public plugin_init() {
	register_plugin(gs_PLUGIN, gs_VERSION, gs_AUTHOR)
	register_cvar("ktp_cvar_version", gs_VERSION, FCVAR_SERVER | FCVAR_SPONLY)

	// Discord toggle - enabled by default (now uses grouped notifications to reduce spam)
	gp_cvar_discord = register_cvar("ktp_cvar_discord", "1")

	// Discord webhook logging now uses shared ktp_discord.inc

	// Register /cvar command for manual cvar check
	register_clcmd("say /cvar", "cmd_manual_check")
	register_clcmd("say_team /cvar", "cmd_manual_check")

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
	for (new i = 0; i < TOTAL_CVARS; i++) {
		gf_calvalues[i] = floatstr(gs_calvalues[i])
	}
	for (new i = 0; i < ALT_VALUES_COUNT; i++) {
		gf_altvalues[i] = floatstr(gs_altvalues[i])
	}
	log_amx("[%s] Pre-converted %d cvar values to floats", gs_PLUGIN, TOTAL_CVARS + ALT_VALUES_COUNT)
}

public fn_servermessage() {
	server_print("%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_year, gs_AUTHOR)
	server_print("%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG1")
	if (file_exists(gs_fcosconfigfile))
		server_print("%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG2")

	server_print("[%s] Monitoring %d cvars with priority-based system:", gs_PLUGIN, TOTAL_CVARS)
	server_print("[%s] - Priority cvars (%d): checked every %.0f seconds", gs_PLUGIN, PRIORITY_CVARS_COUNT, PRIORITY_CHECK_INTERVAL)
	server_print("[%s] - Standard cvars (%d): rotated every %.0f seconds", gs_PLUGIN, STANDARD_CVARS_COUNT, STANDARD_CHECK_INTERVAL)
	server_print("[%s] Enforcement: Auto-correct + console logging (Discord: %s)", gs_PLUGIN, get_pcvar_num(gp_cvar_discord) ? "enabled" : "disabled")
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

	// Only check after initial check complete
	if (!gb_FirstCheckComplete[id])
		return PLUGIN_CONTINUE

	// Skip if we just enforced this cvar
	if (gb_enforcing_cvar[id]) {
		gb_enforcing_cvar[id] = false
		return PLUGIN_CONTINUE
	}

	// Rate limiting (max 1 check per second per player)
	new current_time = get_systime()
	if (current_time - gi_last_check_time[id] < CHECK_RATE_LIMIT)
		return PLUGIN_CONTINUE
	gi_last_check_time[id] = current_time

	// Find and validate this cvar
	for (gi_cvarnum = 0; gi_cvarnum < TOTAL_CVARS; gi_cvarnum++) {
		if (equal(cvar, gs_cvars[gi_cvarnum])) {
			new Float:valueFromPlayer = floatstr(value)

			if (gi_cvarnum >= MIN_MAX_CVAR_START) {
				fn_checkaltallowed(id, gi_cvarnum, cvar, valueFromPlayer,
					gf_calvalues[gi_cvarnum], gf_altvalues[gi_cvarnum - MIN_MAX_CVAR_START],
					value, gs_calvalues[gi_cvarnum])
			}
			else {
				fn_checkvalues(id, gi_cvarnum, cvar, valueFromPlayer,
					gf_calvalues[gi_cvarnum], value, gs_calvalues[gi_cvarnum])
			}
			break
		}
	}

	return PLUGIN_CONTINUE
}

// ============================================================================
// CLIENT EVENTS
// ============================================================================

public fn_msginitial(id) {
	if (!is_user_connected(id))
		return

	get_user_name(id, gs_logname, 31)

	client_print(id, print_chat, "%s version %s by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR)
}

public client_putinserver(id) {
	if (id < 1 || id > MAX_PLAYERS || is_user_bot(id) || is_user_hltv(id))
		return

	gb_FirstCheckComplete[id] = false
	gb_StopChecking[id] = false
	gi_priority_cvar_index[id] = 0
	gi_standard_cvar_index[id] = 0

	set_task(5.0, "fn_msginitial", id)
	set_task(7.5, "fn_loopquery", id)

	// Start periodic monitoring after initial check completes
	set_task(10.0, "fn_start_monitoring", id)
}

public client_disconnected(id) {
	gb_StopChecking[id] = true
	remove_task(id)
	remove_task(id + 1000)  // priority monitoring task
	remove_task(id + 2000)  // standard monitoring task
	remove_task(id + TASK_DEFER_ENFORCE)  // deferred enforcement task
	gb_FirstCheckComplete[id] = false
	gi_last_check_time[id] = 0

	// Reset enforcement tracking
	for (new i = 0; i < TOTAL_CVARS; i++) {
		gi_enforce_attempts[id][i] = 0
		gb_filterstuff_warned[id][i] = false
	}
}

// ============================================================================
// MANUAL CVAR CHECK COMMAND
// ============================================================================

public cmd_manual_check(id) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED

	client_print(id, print_console, "[%s] Starting manual cvar check...", gs_PLUGIN)
	fn_loopquery(id)
	return PLUGIN_HANDLED
}

// ============================================================================
// INITIAL CVAR CHECK
// ============================================================================

public fn_loopquery(id) {
	if (id < 1 || id > MAX_PLAYERS) return
	gi_cvarnumID[id] = 0
	fn_query_parallel(id)
}

public fn_query_parallel(id) {
	if (id < 1 || id > MAX_PLAYERS) return
	if (gi_cvarnumID[id] >= TOTAL_CVARS) {
		fn_firstcomplete(id)
		return
	}

	// Send ONE query per tick (engine only processes ~1 callback per frame)
	query_client_cvar(id, gs_cvars[gi_cvarnumID[id]], "fn_querycvar")
	gi_cvarnumID[id]++

	if (gi_cvarnumID[id] < TOTAL_CVARS)
		set_task(0.3, "fn_query_parallel", id)
	else
		fn_firstcomplete(id)
}

public fn_querycvar(id, const s_CVARNAME[], const s_VALUE[]) {
	if (id < 1 || id > MAX_PLAYERS) return
	new Float:valueFromPlayer = floatstr(s_VALUE)

	// Find the cvar index by name (don't rely on counter)
	new cvar_index = -1
	for (new i = 0; i < TOTAL_CVARS; i++) {
		if (equal(s_CVARNAME, gs_cvars[i])) {
			cvar_index = i
			break
		}
	}

	if (cvar_index < 0)
		return

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
	if (!gb_FirstCheckComplete[id]) {
		gb_FirstCheckComplete[id] = true
	}
}

// ============================================================================
// PERIODIC MONITORING SYSTEM
// ============================================================================

/**
 * Start periodic monitoring after initial check completes
 * Priority cvars: checked every 2 seconds
 * Standard cvars: rotated through every 10 seconds
 */
public fn_start_monitoring(id) {
	if (id < 1 || id > MAX_PLAYERS) return
	if (!is_user_connected(id) || gb_StopChecking[id])
		return

	// Ensure FirstCheckComplete is set — periodic monitoring should not be gated on initial check
	if (!gb_FirstCheckComplete[id]) {
		gb_FirstCheckComplete[id] = true
	}

	// Start priority cvar checks (repeating every 2 seconds)
	set_task(PRIORITY_CHECK_INTERVAL, "fn_check_priority_cvars", id + 1000, "", 0, "b")

	// Start standard cvar rotation (repeating every 10 seconds)
	set_task(STANDARD_CHECK_INTERVAL, "fn_check_standard_cvars", id + 2000, "", 0, "b")

	log_amx("[%s] Periodic monitoring started for player %d (priority taskid=%d, standard taskid=%d)", gs_PLUGIN, id, id + 1000, id + 2000)
}

/**
 * Check all priority cvars (called every 2 seconds)
 * These are the most critical anti-cheat cvars
 */
public fn_check_priority_cvars(taskid) {
	new id = taskid - 1000

	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id) || gb_StopChecking[id] || !gb_FirstCheckComplete[id])
		return

	// Send ONE query per tick (engine only processes ~1 callback per frame)
	new idx = gi_priority_cvar_index[id]
	query_client_cvar(id, gs_priority_cvars[idx], "fn_querycvar")

	// Rotate to next priority cvar
	gi_priority_cvar_index[id] = (idx + 1) % PRIORITY_CVARS_COUNT
}

/**
 * Check standard cvars via rotation (called every 10 seconds)
 * Queries 5 cvars each time, cycling through all standard cvars
 */
public fn_check_standard_cvars(taskid) {
	new id = taskid - 2000

	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id) || gb_StopChecking[id] || !gb_FirstCheckComplete[id])
		return

	// Send ONE query per tick (engine only processes ~1 callback per frame)
	new idx = gi_standard_cvar_index[id]
	query_client_cvar(id, gs_standard_cvars[idx], "fn_querycvar")

	// Rotate to next standard cvar
	gi_standard_cvar_index[id] = (idx + 1) % STANDARD_CVARS_COUNT
}

// ============================================================================
// CVAR VALIDATION FUNCTIONS
// ============================================================================

public fn_checkvalues(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	new bool: isInvalid = false

	if (equal(s_CVARNAME, gs_pitch)) {
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
		defer_enforcement(id, cvar_index, s_CVARNAME, valueFromPlayer, calFloatValue, s_CALVALUE)
	} else {
		// Cvar is valid - reset enforcement tracking for this cvar
		fn_reset_enforce_tracking(id, cvar_index)
	}
}

public fn_checkaltallowed(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, Float: altFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	if (valueFromPlayer < calFloatValue) {
		// Below minimum — correct to minimum
		defer_enforcement(id, cvar_index, s_CVARNAME, valueFromPlayer, calFloatValue, s_CALVALUE)
	} else if (valueFromPlayer > altFloatValue) {
		// Above maximum — correct to maximum
		defer_enforcement(id, cvar_index, s_CVARNAME, valueFromPlayer, altFloatValue, gs_altvalues[cvar_index - MIN_MAX_CVAR_START])
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
stock defer_enforcement(id, cvar_index, const s_CVARNAME[], Float:valueFromPlayer, Float:calFloatValue, const s_CALVALUE[]) {
	g_deferCvarIndex[id] = cvar_index
	copy(g_deferCvarName[id], MAX_CVAR_NAME_LEN - 1, s_CVARNAME)
	g_deferValue[id] = valueFromPlayer
	g_deferCalValue[id] = calFloatValue
	copy(g_deferCalStr[id], 15, s_CALVALUE)

	// Schedule for next frame (removes any existing deferred task for this player)
	remove_task(id + TASK_DEFER_ENFORCE)
	set_task(0.0, "task_deferred_enforce", id + TASK_DEFER_ENFORCE)
}

public task_deferred_enforce(taskid) {
	new id = taskid - TASK_DEFER_ENFORCE
	if (id < 1 || id > MAX_PLAYERS || !is_user_connected(id))
		return

	fn_enforce_cvar(id, g_deferCvarIndex[id], g_deferCvarName[id],
		g_deferValue[id], g_deferCalValue[id], g_deferCalStr[id])
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

public fn_enforce_cvar(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, const s_CALVALUE[]) {
	if (gb_StopChecking[id])
		return PLUGIN_CONTINUE

	// Skip hud_takesshots enforcement for non-competitive matches (12man, scrim, draft)
	// ktp_match_competitive is set by KTPMatchHandler: 1 = .ktp/.ktpOT, 0 = casual modes
	if (equal(s_CVARNAME, "hud_takesshots") && get_cvar_num("ktp_match_competitive") == 0)
		return PLUGIN_CONTINUE

	// Increment enforcement attempt counter
	gi_enforce_attempts[id][cvar_index]++

	// Get player info (needed for both warning and normal enforcement)
	get_user_name(id, gs_logname, charsmax(gs_logname))
	get_user_authid(id, gs_logauthid, charsmax(gs_logauthid))
	get_user_ip(id, gs_logip, charsmax(gs_logip), 1)

	if (gs_logname[0] == 0 || gs_logauthid[0] == 0) {
		log_amx("[%s] WARNING: Player %d disconnected before logging violation", gs_PLUGIN, id)
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
				gs_PLUGIN, gs_logname, gs_logauthid, gs_logip, s_CVARNAME, valueFromPlayer, calFloatValue, gi_enforce_attempts[id][cvar_index])

			// Announce to all players that this player is blocked
			client_print(0, print_chat, "[%s] %s has blocked cvar enforcement (%s) - cannot participate until fixed", gs_PLUGIN, gs_logname, s_CVARNAME)
		}
		// Don't spam - just silently skip further enforcement attempts
		return PLUGIN_CONTINUE
	}

	new bool:is_pitch = equal(s_CVARNAME, gs_pitch)

	// Set enforcement flag to prevent recursion
	gb_enforcing_cvar[id] = bool:true

	// Force correct value on client
	if (is_pitch && (valueFromPlayer < 0.0)) {
		client_cmd(id, "%s -0.022", s_CVARNAME)
	}
	else if (is_pitch && (valueFromPlayer >= 0.0)) {
		client_cmd(id, "%s 0.022", s_CVARNAME)
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

	// Announce to all players
	client_print(0, print_chat, "[%s] %s had invalid %s (%.2f) - corrected to %.2f", gs_PLUGIN, gs_logname, s_CVARNAME, valueFromPlayer, calFloatValue)

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
	// Check if this is a new player or same player
	if (g_discordPlayerId != id) {
		// Send any pending violations for previous player
		if (g_discordPending) {
			send_discord_violations()
		}

		// Start buffering for new player
		g_discordPlayerId = id
		copy(g_discordPlayerName, charsmax(g_discordPlayerName), gs_logname)
		copy(g_discordPlayerAuthid, charsmax(g_discordPlayerAuthid), gs_logauthid)
		copy(g_discordPlayerIp, charsmax(g_discordPlayerIp), gs_logip)
		g_discordViolationCount = 0
	}

	// Check if this cvar is already in the buffer (repeat violation)
	new cvar_index = -1
	for (new i = 0; i < g_discordViolationCount; i++) {
		if (equal(g_discordCvarNames[i], cvar_name)) {
			cvar_index = i
			break
		}
	}

	if (cvar_index >= 0) {
		// Existing cvar - increment count and update values
		g_discordCvarCounts[cvar_index]++
		g_discordCvarValues[cvar_index] = player_value
		g_discordCvarCorrected[cvar_index] = corrected_value
	} else if (g_discordViolationCount < MAX_CVAR_VIOLATIONS) {
		// New cvar - add to buffer
		copy(g_discordCvarNames[g_discordViolationCount], MAX_CVAR_NAME_LEN - 1, cvar_name)
		g_discordCvarValues[g_discordViolationCount] = player_value
		g_discordCvarCorrected[g_discordViolationCount] = corrected_value
		g_discordCvarCounts[g_discordViolationCount] = 1
		g_discordViolationCount++
	}

	// Schedule Discord send (will be called after violations settle)
	if (!g_discordPending) {
		g_discordPending = true
		set_task(DISCORD_DELAY, "send_discord_violations")
	}
}

/**
 * Send buffered violations as a single grouped Discord embed
 */
public send_discord_violations() {
	g_discordPending = false

	if (g_discordViolationCount == 0)
		return

	// Build description with all cvars
	new description[1024]
	new pos = 0

	// Calculate total violations (sum of all counts)
	new total_violations = 0
	for (new i = 0; i < g_discordViolationCount; i++) {
		total_violations += g_discordCvarCounts[i]
	}

	pos += formatex(description[pos], charsmax(description) - pos,
		"**Player:** %s^n**SteamID:** %s^n**IP:** %s^n^n**Violations (%d total, %d unique):**^n",
		g_discordPlayerName, g_discordPlayerAuthid, g_discordPlayerIp, total_violations, g_discordViolationCount)

	// Add cvar list
	for (new i = 0; i < g_discordViolationCount && pos < charsmax(description) - 100; i++) {
		if (g_discordCvarCounts[i] > 1) {
			// Repeat violation - show count
			pos += formatex(description[pos], charsmax(description) - pos,
				"• **%s** (x%d): %.3f → %.3f^n",
				g_discordCvarNames[i], g_discordCvarCounts[i],
				g_discordCvarValues[i], g_discordCvarCorrected[i])
		} else {
			// Single violation
			pos += formatex(description[pos], charsmax(description) - pos,
				"• **%s**: %.3f → %.3f^n",
				g_discordCvarNames[i],
				g_discordCvarValues[i], g_discordCvarCorrected[i])
		}
	}

	// Send to audit channel
	ktp_discord_send_embed_audit("<:ktp:1105490705188659272> CVAR Violations", description, KTP_DISCORD_COLOR_ORANGE)

	// Reset buffer
	g_discordPlayerId = 0
	g_discordViolationCount = 0
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
