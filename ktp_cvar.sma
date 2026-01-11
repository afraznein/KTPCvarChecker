/*
 *   Title:    KTP Cvar Settings (fcos)
 *   Author:   Nein_
 *
 *   Current Version:   7.9
 *   Release Date:      2026-01-09
 *
 *   Changelog:
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
 *                    + ADDED: Standard cvar rotation - 50 cvars cycled through every 10 seconds
 *                    * PERFORMANCE: ~5 queries/second per player (160 q/s for 32 players)
 *                    * DETECTION: Priority cvars detected in <2s, standard cvars in <100s
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
new const gs_VERSION[] = "7.9";
new const gs_AUTHOR[] = "Nein_";
new const gs_year     = 2025;

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
#define TOTAL_CVARS 59
#define MIN_MAX_CVAR_START 51
#define ALT_VALUES_COUNT 8

// Parallel query batch size for initial check
#define PARALLEL_BATCH_SIZE 8

// Rate limiting
#define CHECK_RATE_LIMIT 1  // Minimum 1 second between checks per player

// Priority-based monitoring intervals
#define PRIORITY_CHECK_INTERVAL 2.0   // High-priority cvars checked every 2 seconds
#define STANDARD_CHECK_INTERVAL 10.0  // Standard cvars checked every 10 seconds

// Priority cvar count
#define PRIORITY_CVARS_COUNT 9

// ============================================================================
// CVAR POINTERS
// ============================================================================

// Discord toggle (separate from global discord.ini - allows disabling cvar spam specifically)
new gp_cvar_discord

// Discord config now loaded via ktp_discord.inc

// ============================================================================
// PLAYER DATA ARRAYS
// ============================================================================

new bool:gb_FirstCheckComplete[MAX_PLAYERS]
new bool:gb_StopChecking[MAX_PLAYERS]
new gi_cvarnumID[MAX_PLAYERS]
new gi_last_check_time[MAX_PLAYERS]
new bool:gb_enforcing_cvar[MAX_PLAYERS]

// Periodic monitoring state
new gi_standard_cvar_index[MAX_PLAYERS]  // Current index in standard cvar rotation

// Enforcement attempt tracking (detect cl_filterstuffcmd blocking)
new gi_enforce_attempts[MAX_PLAYERS][TOTAL_CVARS]  // Count of failed enforcement attempts per cvar
new bool:gb_filterstuff_warned[MAX_PLAYERS][TOTAL_CVARS]  // Already showed warning for this cvar
#define MAX_ENFORCE_ATTEMPTS 3  // After this many attempts, show cl_filterstuffcmd warning

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

// ============================================================================
// CVAR CHECKING ARRAYS
// ============================================================================

// Priority cvars: checked every 2 seconds (movement/network/performance exploits)
new gs_priority_cvars[PRIORITY_CVARS_COUNT][] = {
"m_pitch", "cl_yawspeed", "cl_pitchspeed", "lightgamma", "cl_bob",
"cl_updaterate", "cl_cmdrate", "rate", "ex_interp"
}

// All cvars (for initial check and reference)
new gs_cvars[TOTAL_CVARS][] = {
"ambient_fade", "ambient_level", "cl_bobcycle", "cl_bobup", "cl_fixtimerate",
"cl_gaitestimation", "fastsprites", "gl_affinemodels", "gl_alphamin", "gl_clear",
"gl_cull", "gl_d3dflip", "gl_dither", "gl_keeptjunctions", "gl_lightholes",
"gl_monolights", "gl_nobind", "gl_nocolors", "gl_overbright", "gl_palette_tex",
"gl_picmip", "gl_playermip", "gl_round_down", "r_bmodelinterp", "r_drawentities",
"r_drawviewmodel", "r_dynamic", "r_fullbright", "r_glowshellfreq", "r_lightmap",
"r_traceglow", "r_wadtextures", "texgamma", "r_luminance", "s_show",
"cl_showevents", "cl_anglespeedkey", "cl_lc", "cl_lw", "cl_upspeed",
"lookspring", "lookstrafe", "cl_movespeedkey", "m_pitch", "m_side",
"cl_pitchdown", "cl_pitchup", "cl_yawspeed", "cl_pitchspeed", "hud_takesshots",
"cl_mousegrab", "lightgamma", "cl_smoothtime", "cl_bob", "cl_updaterate",
"cl_cmdrate", "rate", "ex_interp", "fps_max"
}

// Standard cvars (non-priority): checked via rotation every 10 seconds
// Excludes the 9 priority cvars listed above
#define STANDARD_CVARS_COUNT 50
new gs_standard_cvars[STANDARD_CVARS_COUNT][] = {
"ambient_fade", "ambient_level", "cl_bobcycle", "cl_bobup", "cl_fixtimerate",
"cl_gaitestimation", "fastsprites", "gl_affinemodels", "gl_alphamin", "gl_clear",
"gl_cull", "gl_d3dflip", "gl_dither", "gl_keeptjunctions", "gl_lightholes",
"gl_monolights", "gl_nobind", "gl_nocolors", "gl_overbright", "gl_palette_tex",
"gl_picmip", "gl_playermip", "gl_round_down", "r_bmodelinterp", "r_drawentities",
"r_drawviewmodel", "r_dynamic", "r_fullbright", "r_glowshellfreq", "r_lightmap",
"r_traceglow", "r_wadtextures", "texgamma", "r_luminance", "s_show",
"cl_showevents", "cl_anglespeedkey", "cl_lc", "cl_lw", "cl_upspeed",
"lookspring", "lookstrafe", "cl_movespeedkey", "m_side", "cl_pitchdown",
"cl_pitchup", "hud_takesshots", "cl_mousegrab", "cl_smoothtime", "fps_max"
}

new gs_calvalues[TOTAL_CVARS][] = {
"100", "0.3", "0.8", "0.5", "7.5", "1", "0", "0", "0.25", "0",
"1", "0", "1", "1", "1", "0", "0", "0", "0", "1",
"0", "0", "3", "1", "1", "1", "1", "0", "2.2", "0",
"0", "0", "2", "0", "0", "0", "0.67", "1", "1", "320",
"0", "0", "0.3", "0.022", "0.8", "89", "89", "210", "225", "1",
"1", "1.81", "0", "0", "100", "100", "100000", "0", "60"
}

new gs_altvalues[ALT_VALUES_COUNT][] = {
"3", "0.1", "0.011", "120", "500", "1000000", "0.03", "500"
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

	// Discord toggle - disabled by default to reduce webhook spam
	gp_cvar_discord = register_cvar("ktp_cvar_discord", "0")

	// Discord webhook logging now uses shared ktp_discord.inc

	// Register /cvar command for manual cvar check
	register_clcmd("say /cvar", "cmd_manual_check")
	register_clcmd("say_team /cvar", "cmd_manual_check")

	register_dictionary("ktp_cvar.txt")
	get_configsdir(gs_directory, 32)
	formatex(gs_fcosconfigfile, 57, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE)
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

	server_print("[%s] Monitoring 59 cvars with priority-based system:", gs_PLUGIN)
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
	gi_standard_cvar_index[id] = 0

	set_task(5.0, "fn_msginitial", id)
	set_task(7.5, "fn_loopquery", id)

	// Start periodic monitoring after initial check completes
	set_task(10.0, "fn_start_monitoring", id)
}

public client_disconnected(id) {
	gb_StopChecking[id] = true
	remove_task(id)
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
	gi_cvarnumID[id] = 0
	fn_query_parallel(id)
}

public fn_query_parallel(id) {
	if (gi_cvarnumID[id] >= TOTAL_CVARS) {
		fn_firstcomplete(id)
		return
	}

	new batch_count = 0
	new start_idx = gi_cvarnumID[id]

	for (new i = start_idx; i < TOTAL_CVARS && batch_count < PARALLEL_BATCH_SIZE; i++) {
		query_client_cvar(id, gs_cvars[i], "fn_querycvar")
		gi_cvarnumID[id]++
		batch_count++
	}

	if (gi_cvarnumID[id] < TOTAL_CVARS)
		set_task(0.25, "fn_query_parallel", id)
	else
		fn_firstcomplete(id)
}

public fn_querycvar(id, const s_CVARNAME[], const s_VALUE[], const s_CALVALUE[]) {
	new Float:valueFromPlayer = floatstr(s_VALUE)

	// Find the cvar index by name (don't rely on counter)
	new cvar_index = -1
	for (new i = 0; i < TOTAL_CVARS; i++) {
		if (equal(s_CVARNAME, gs_cvars[i])) {
			cvar_index = i
			break
		}
	}

	if (cvar_index < 0) {
		log_amx("[%s] ERROR: Unknown cvar '%s' in callback", gs_PLUGIN, s_CVARNAME)
		return
	}

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
	if (!is_user_connected(id) || gb_StopChecking[id])
		return

	// Start priority cvar checks (repeating every 2 seconds)
	set_task(PRIORITY_CHECK_INTERVAL, "fn_check_priority_cvars", id, _, _, "b")

	// Start standard cvar rotation (repeating every 10 seconds)
	set_task(STANDARD_CHECK_INTERVAL, "fn_check_standard_cvars", id, _, _, "b")

	log_amx("[%s] Periodic monitoring started for player %d", gs_PLUGIN, id)
}

/**
 * Check all priority cvars (called every 2 seconds)
 * These are the most critical anti-cheat cvars
 */
public fn_check_priority_cvars(id) {
	if (!is_user_connected(id) || gb_StopChecking[id] || !gb_FirstCheckComplete[id])
		return

	// Query all priority cvars
	for (new i = 0; i < PRIORITY_CVARS_COUNT; i++) {
		query_client_cvar(id, gs_priority_cvars[i], "fn_querycvar")
	}
}

/**
 * Check standard cvars via rotation (called every 10 seconds)
 * Queries 5 cvars each time, cycling through all 49 standard cvars
 */
public fn_check_standard_cvars(id) {
	if (!is_user_connected(id) || gb_StopChecking[id] || !gb_FirstCheckComplete[id])
		return

	// Query 5 standard cvars per check (completes full rotation in ~100 seconds)
	new cvars_to_check = 5

	for (new i = 0; i < cvars_to_check && gi_standard_cvar_index[id] < STANDARD_CVARS_COUNT; i++) {
		query_client_cvar(id, gs_standard_cvars[gi_standard_cvar_index[id]], "fn_querycvar")
		gi_standard_cvar_index[id]++
	}

	// Reset rotation when we reach the end
	if (gi_standard_cvar_index[id] >= STANDARD_CVARS_COUNT) {
		gi_standard_cvar_index[id] = 0
	}
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
		fn_enforce_cvar(id, cvar_index, s_CVARNAME, valueFromPlayer, calFloatValue, s_CALVALUE)
	} else {
		// Cvar is valid - reset enforcement tracking for this cvar
		fn_reset_enforce_tracking(id, cvar_index)
	}
}

public fn_checkaltallowed(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, Float: altFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	if (valueFromPlayer < calFloatValue || valueFromPlayer > altFloatValue) {
		fn_enforce_cvar(id, cvar_index, s_CVARNAME, valueFromPlayer, calFloatValue, s_CALVALUE)
	} else {
		// Cvar is valid - reset enforcement tracking for this cvar
		fn_reset_enforce_tracking(id, cvar_index)
	}
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
	gb_enforcing_cvar[id] = true

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

	// Send to Discord audit (using shared ktp_discord.inc)
	// Only if ktp_cvar_discord is enabled (disabled by default to reduce spam)
	if (get_pcvar_num(gp_cvar_discord) && ktp_discord_is_enabled()) {
		new description[384]
		formatex(description, charsmax(description),
			"**Player:** %s^n**SteamID:** %s^n**IP:** %s^n**Cvar:** %s^n**Value:** %.3f^n**Corrected:** %.3f",
			gs_logname, gs_logauthid, gs_logip, s_CVARNAME, valueFromPlayer, calFloatValue)
		ktp_discord_send_embed_audit("CVAR Violation", description, KTP_DISCORD_COLOR_ORANGE)
	}

	return PLUGIN_CONTINUE
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
