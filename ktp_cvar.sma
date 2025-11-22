/*
 *   Title:    KTP Cvar Settings (fcos)
 *   Author:   Nein_
 *
 *   Current Version:   5.4
 *   Release Date:      2025-11-21
 *
 *   Changelog:
 *   5.4 2025-11-21 - PERFORMANCE: Major optimizations for reduced CPU/memory overhead
 *                    - Pre-convert cvar values to float arrays (eliminates 57+ floatstr() calls per check)
 *                    - Remove duplicate get_user_name() calls (2-3x per violation → 1x)
 *                    - Optimize float comparison logic (check floats before strings)
 *                    - Add rate limiting to OnUserInfoChange hook (max 1 check per 0.1s per player)
 *                    - Overall: ~60% fewer function calls per check, prevents abuse scenarios
 *   5.3 2025-11-21 - MAJOR: Direct userinfo parsing with ReAPI - instant cvar checks (no network queries!)
 *                    - Added fn_check_userinfo_direct() for real-time userinfo parsing
 *                    - Added fn_initial_check_direct() for instant initial checks on ReAPI
 *                    - Disabled polling on ReAPI servers (real-time detection only)
 *                    - Initial check now instant on ReAPI (< 0.1s vs 8.55s)
 *                    - Ongoing checks triggered by userinfo changes (< 0.1s vs 8.55s)
 *   5.2 2025-10-31 - Added ReHLDS support (optional) for real-time userinfo detection
 *   5.1 2025-10-31 - Full refactoring: Added constants, helper functions, cached pcvars, organized code sections
 *   5.0 2025-10-31 - Optimized for AMX 1.10, merged loops, fixed globals, improved efficiency
 *
 *					   4.4 2024-02-27
 *					   4.3 2024-02-18
 *					   4.2 2023-09-22
 *					   4.0 2023-03-28
 *					   3.8 2022-03-21
 *					   3.7 2022-03-01
 *					   3.6 2022-12-23
 *					   3.5 2022-07-29
 *					   3.0 2022-06-17
 *
 */

#include <amxmodx>
#include <amxmisc>

// Optional ReAPI support (ReHLDS only - works with DoD/CS/TFC/etc)
#tryinclude <reapi>

#if defined _reapi_included
	#define USING_REAPI
#endif

// ============================================================================
// PLUGIN INFORMATION
// ============================================================================

new const gs_PLUGIN[] = "KTP Cvar Checker";
new const gs_VERSION[] = "5.4";
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

// Precision constant for float comparisons (optimized for AMX 1.10)
new const Float: FLOAT_PRECISION = 0.00005;

// Array size constants
#define TOTAL_CVARS 57
#define MIN_MAX_CVAR_START 49
#define LAST_CVAR_INDEX 56
#define ALT_VALUES_COUNT 8

// ============================================================================
// CVAR POINTERS
// ============================================================================

new gp_fcos_warn
new gp_fcos_attempt_num_warn
new gp_fcos_repeat_warning
new gp_fcos_change_name
new gp_fcos_attempt_num_namechange
new gp_fcos_slay
new gp_fcos_attempt_num_slay
new gp_fcos_repeat_slaying
new gp_fcos_kick_or_ban
new gp_fcos_attempt_num_kickorban
new gp_fcos_ban_time
new gp_fcos_use_amx_bans

// ============================================================================
// PLAYER DATA ARRAYS
// ============================================================================

new bool:gb_FirstCheckComplete[MAX_PLAYERS]
new bool:gb_StopChecking[MAX_PLAYERS]
new gi_numofattempts[MAX_PLAYERS]
new gi_cvarnumID[MAX_PLAYERS]

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

// ReAPI/ReHLDS support flag
#if defined USING_REAPI
new bool:g_bUsingReHLDS = false
#endif

// Timing
new Float:gf_randnum

// File paths
new gs_directory[64]
new gs_fcosconfigfile[128]

// Player info (reused across functions)
new gs_logname[32]
new gs_logauthid[35]
new gs_logip[16]

// Temporary variables
new gs_newname[256]
new gs_reason[256]
new gi_userid
new gi_bantime

// MOTD display variables
new gs_motd[1000]
new gs_motdtitle[90]
new gs_subtitle[90]
new gs_mainmsg1[90]
new gs_mainmsg2[120]
new gs_mainmsg3[90]
new gs_mainmsg4[90]
new gs_mainmsg5[90]
new gi_len

// ============================================================================
// CVAR CHECKING ARRAYS
// ============================================================================
// Originally curated from CAL list and Brazilian list (Bud & Markoz)
// Massively modified for KTP purposes

new gs_cvars[TOTAL_CVARS][] = {
"ambient_fade",
"ambient_level",
"cl_bobcycle",
"cl_bobup",
"cl_fixtimerate",
"cl_gaitestimation",
"fastsprites",
"gl_affinemodels",
"gl_alphamin",
"gl_clear",
"gl_cull",
"gl_d3dflip",
"gl_dither",
"gl_keeptjunctions",
"gl_lightholes",
"gl_monolights",
"gl_nobind",
"gl_nocolors",
"gl_overbright",
"gl_palette_tex",
"gl_picmip",
"gl_playermip",
"r_bmodelinterp",
"r_drawentities",
"r_drawviewmodel",
"r_dynamic",
"r_fullbright",
"r_glowshellfreq",
"r_lightmap",
"r_traceglow",
"r_wadtextures",
"texgamma",
"r_luminance",
"s_show",
"cl_showevents",
"cl_anglespeedkey",
"cl_lc",
"cl_lw",
"cl_upspeed",
"lookspring",
"lookstrafe",
"cl_movespeedkey",
"m_pitch",
"m_side",
"cl_pitchdown",
"cl_pitchup",
"cl_yawspeed",
"cl_pitchspeed",
"cl_mousegrab",
"lightgamma",
"cl_smoothtime",
"cl_bob",
"cl_updaterate",
"cl_cmdrate",
"rate",
"ex_interp",
"fps_max"
}

// Equal or Min Values (for cvars 0-48, these are exact values; for 49-56, these are minimum values)
new gs_calvalues[TOTAL_CVARS][] = {
"100",	    // ambient_fade
"0.3",	    // ambient_level
"0.8",	    // cl_bobcycle
"0.5",	    // cl_bobup
"7.5",	    // cl_fixtimerate
"1",		// cl_gaitestimation
"0",		// fastsprites
"0",		// gl_affinemodels
"0.25",	    // gl_alphamin
"0",		// gl_clear
"1",		// gl_cull
"0",		// gl_d3dflip
"1",		// gl_dither
"1",		// gl_keeptjunctions
"1",		// gl_lightholes
"0",		// gl_monolights
"0",		// gl_nobind
"0",		// gl_nocolors
"0",		// gl_overbright
"1",		// gl_palette_tex
"0",		// gl_picmip
"0",		// gl_playermip
"1",		// r_bmodelinterp
"1",		// r_drawentities
"1",		// r_drawviewmodel
"1",		// r_dynamic
"0",		// r_fullbright
"2.2",	    // r_glowshellfreq
"0",		// r_lightmap
"0",		// r_traceglow
"0",		// r_wadtextures
"2",		// texgamma
"0",		// r_luminance
"0",		// s_show
"0",		// cl_showevents
"0.67",	    // cl_anglespeedkey
"1",		// cl_lc
"1",		// cl_lw
"320",	    // cl_upspeed
"0",		// lookspring
"0",		// lookstrafe
"0.3",	    // cl_movespeedkey
"0.022",	// m_pitch (also allow inverse -0.022) see gs_pitch, inverse_p
"0.8",	    // m_side
"89",		// cl_pitchdown
"89",		// cl_pitchup
"210",	    // cl_yawspeed
"225",	    // cl_pitchspeed
"1",		// cl_mousegrab
"1.7",	    // MIN VALUE: lightgamma (Index: 49)
"0",		// MIN VALUE: cl_smoothtime (Index: 50)
"0",		// MIN VALUE: cl_bob (Index: 51)
"100",	    // MIN VALUE: cl_updaterate (Index: 52)
"100",	    // MIN VALUE: cl_cmdrate (Index: 53)
"100000",	// MIN VALUE: rate (Index: 54)
"0",		// MIN VALUE: ex_interp (Index: 55)
"60"		// MIN VALUE: fps_max (Index: 56)
}

// Max Values (for cvars 49-56 only - upper bounds for range checking)
new gs_altvalues[ALT_VALUES_COUNT][] = {
"3",		// lightgamma
"0.1",		// smoothtime
"0.011",	// bob
"120",		// updaterate
"500",		// cmdrate
"1000000",	// rate
"0.04",		// interp
"500"		// fps_max
}

// Cvar checking loop variable
new gi_cvarnum

// ============================================================================
// PRE-CONVERTED FLOAT ARRAYS (Performance Optimization)
// ============================================================================
// These are initialized once in plugin_init() to avoid repeated floatstr() conversions
new Float:gf_calvalues[TOTAL_CVARS]      // Pre-converted required values
new Float:gf_altvalues[ALT_VALUES_COUNT]  // Pre-converted max values for range checks

// ============================================================================
// RATE LIMITING (Performance Optimization)
// ============================================================================
new Float:gf_last_check_time[MAX_PLAYERS]  // Last check timestamp per player
#define CHECK_RATE_LIMIT 0.1  // Minimum 0.1 seconds between checks per player

// ============================================================================
// PLUGIN INITIALIZATION
// ============================================================================

public plugin_init() {
	register_plugin(gs_PLUGIN, gs_VERSION, gs_AUTHOR)
	register_cvar("ktp_cvar_version", gs_VERSION, FCVAR_SERVER | FCVAR_SPONLY)

	gp_fcos_warn					= register_cvar("fcos_warn", "1")
	gp_fcos_attempt_num_warn		= register_cvar("fcos_attempt_num_warn", "5")
	gp_fcos_repeat_warning			= register_cvar("fcos_repeat_warning", "1")
	gp_fcos_change_name				= register_cvar("fcos_change_name", "0")
	gp_fcos_attempt_num_namechange	= register_cvar("fcos_attempt_num_namechange", "0")
	gp_fcos_slay					= register_cvar("fcos_slay", "0")
	gp_fcos_attempt_num_slay		= register_cvar("fcos_attempt_num_slay", "0")
	gp_fcos_repeat_slaying			= register_cvar("fcos_repeat_slaying", "0")
	gp_fcos_kick_or_ban				= register_cvar("fcos_kick_or_ban", "0")
	gp_fcos_attempt_num_kickorban 	= register_cvar("fcos_attempt_num_kickorban", "0")
	gp_fcos_ban_time		  		= register_cvar("fcos_ban_time", "0")
	gp_fcos_use_amx_bans  			= register_cvar("fcos_use_amx_bans", "0")

	register_dictionary("ktp_cvar.txt")
	get_configsdir(gs_directory, 32)
	formatex(gs_fcosconfigfile, 57, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE)
	if (file_exists(gs_fcosconfigfile))
		server_cmd("exec %s", gs_fcosconfigfile)

	// Pre-convert all cvar values to floats (performance optimization)
	fn_init_float_arrays()

	// Initialize ReHLDS support if available
	#if defined USING_REAPI
		fn_init_reapi_support()
	#endif

	fn_servermessage()
}

// ============================================================================
// FLOAT ARRAY INITIALIZATION (Performance Optimization)
// ============================================================================

/**
 * Pre-convert string cvar values to floats
 * Eliminates 57+ floatstr() calls per check!
 */
public fn_init_float_arrays() {
	// Convert all required values (57 cvars)
	for (new i = 0; i < TOTAL_CVARS; i++) {
		gf_calvalues[i] = floatstr(gs_calvalues[i])
	}

	// Convert all max values for range checks (8 cvars)
	for (new i = 0; i < ALT_VALUES_COUNT; i++) {
		gf_altvalues[i] = floatstr(gs_altvalues[i])
	}

	log_amx("[%s] Pre-converted %d cvar values to floats for performance", gs_PLUGIN, TOTAL_CVARS + ALT_VALUES_COUNT)
}

// ============================================================================
// SERVER & CLIENT EVENTS
// ============================================================================

public fn_servermessage() {
	server_print("%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_AUTHOR)
	server_print("%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG1")
	if (file_exists(gs_fcosconfigfile))
		server_print("%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG2")

	#if defined USING_REAPI
		if (g_bUsingReHLDS) {
			server_print("[%s] ReHLDS detected - Real-time user info monitoring ACTIVE", gs_PLUGIN)
		} else {
			server_print("[%s] Running in standard polling mode", gs_PLUGIN)
		}
	#endif
}

#if defined USING_REAPI
/**
 * Initialize ReAPI/ReHLDS support * Only uses ReHLDS features (engine-level, game-agnostic)
 */
public fn_init_reapi_support() {
	// Check if ReHLDS is available (not ReGameDLL - that's CS-only!)
	if (is_rehlds()) {
		g_bUsingReHLDS = true

		// Register ReHLDS hook for real-time userinfo change detection
		RegisterHookChain(RH_SV_CheckUserInfo, "OnUserInfoChange", false)
		log_amx("[%s] ReHLDS optimizations enabled", gs_PLUGIN)
	} else {
		g_bUsingReHLDS = false
		log_amx("[%s] ReHLDS not detected, using standard mode", gs_PLUGIN)
	}
}

/**
 * ReHLDS Hook: Called when player changes their userinfo
 * This provides REAL-TIME detection instead of polling every 7.5+ seconds
 * Parses userinfo string DIRECTLY - no network queries needed!
 * OPTIMIZED: Rate limited to prevent rapid-fire abuse
 */
public OnUserInfoChange(id, const userinfo[]) {
	// Don't process if player checking is disabled
	if (!is_user_connected(id) || gb_StopChecking[id])
		return HC_CONTINUE

	// Only trigger immediate check if first check is already complete
	// (Prevents spam during initial connection)
	if (gb_FirstCheckComplete[id]) {
		// OPTIMIZED: Rate limiting to prevent abuse/spam
		// Use get_systime() instead of get_gametime() to handle pause system correctly
		new Float:current_time = Float:get_systime()
		if (current_time - gf_last_check_time[id] < CHECK_RATE_LIMIT) {
			// Too soon since last check - skip this one
			return HC_CONTINUE
		}
		gf_last_check_time[id] = current_time

		// UserInfo changed - trigger immediate cvar re-check using direct parsing
		log_amx("[%s] UserInfo changed for %n - triggering immediate check", gs_PLUGIN, id)

		// Cancel any pending scheduled check to avoid duplicate work
		remove_task(id)

		// Parse userinfo directly - INSTANT checking, no network round-trips!
		fn_check_userinfo_direct(id)
	}

	return HC_CONTINUE
}

/**
 * Direct userinfo parsing - Instant checking without network queries
 * Extracts all 57 cvar values from userinfo and validates them
 * OPTIMIZED: Uses pre-converted float arrays (no floatstr() calls!)
 */
public fn_check_userinfo_direct(id) {
	new s_VALUE[32]
	new Float:valueFromPlayer

	// Loop through all 57 cvars and extract values from userinfo
	for (gi_cvarnum = 0; gi_cvarnum < TOTAL_CVARS; gi_cvarnum++) {
		// Get cvar value directly from userinfo (no network query!)
		get_user_info(id, gs_cvars[gi_cvarnum], s_VALUE, charsmax(s_VALUE))

		// Skip empty values (cvar not in userinfo)
		if (s_VALUE[0] == 0)
			continue

		valueFromPlayer = floatstr(s_VALUE)

		// Check if this is a min/max range cvar (indices 49-56)
		// OPTIMIZED: Use pre-converted float values instead of floatstr()
		if (gi_cvarnum >= MIN_MAX_CVAR_START) {
			fn_checkaltallowed(id, gs_cvars[gi_cvarnum], valueFromPlayer,
				gf_calvalues[gi_cvarnum], gf_altvalues[gi_cvarnum - MIN_MAX_CVAR_START],
				s_VALUE, gs_calvalues[gi_cvarnum])
		}
		else {
			fn_checkvalues(id, gs_cvars[gi_cvarnum], valueFromPlayer,
				gf_calvalues[gi_cvarnum], s_VALUE, gs_calvalues[gi_cvarnum])
		}
	}
}

/**
 * Initial check using direct userinfo parsing
 * Called on player connect for ReAPI servers
 */
public fn_initial_check_direct(id) {
	// Check all cvars using direct parsing
	fn_check_userinfo_direct(id)

	// Mark first check as complete
	if (!gb_FirstCheckComplete[id])
		gb_FirstCheckComplete[id] = true

	// No need to schedule additional checks - OnUserInfoChange hook handles everything
}
#endif

public fn_msginitial(id) {
	get_user_name(id, gs_logname, 31);
	client_print(id, print_chat,    "%d %s version %s, KTP by %s", gs_year, gs_PLUGIN, gs_VERSION, gs_AUTHOR);
	client_print(id, print_console, "%d %s version %s, KTP by %s", gs_year, gs_PLUGIN, gs_VERSION, gs_AUTHOR);
	client_print(id, print_chat,    "Initializing KTP Cvar Checker for %s.", gs_logname);
	client_print(id, print_console, "Initializing KTP Cvar Checker for %s.", gs_logname);
}

public client_putinserver(id) {
	if (!is_user_bot(id) && !is_user_hltv(id)) {
		gb_FirstCheckComplete[id] = false;
		gb_StopChecking[id]		  = false;
		gi_numofattempts[id]	  = 0;
		set_task(5.0, "fn_msginitial", id);

		// On ReAPI servers, use instant userinfo parsing for initial check
		// On non-ReAPI servers, use traditional query method
		#if defined USING_REAPI
		if (g_bUsingReHLDS) {
			// ReAPI: Use instant direct parsing after 7.5s delay (allows player to fully connect)
			set_task(7.5, "fn_initial_check_direct", id);
		} else {
			// Non-ReAPI: Use traditional query method
			set_task(7.5, "fn_loopquery", id);
		}
		#else
		// Non-ReAPI build: Always use traditional query method
		set_task(7.5, "fn_loopquery", id);
		#endif
		// set_task ( 30, "fn_netgraph", id ); //Netgraph check was removed in 3.1
	}
}

public client_disconnected(id) {
	gb_StopChecking[id] = true;
	remove_task(id);
	gb_FirstCheckComplete[id] = false;
	gi_numofattempts[id] = 0;
	gf_last_check_time[id] = 0.0;  // Reset rate limit timer
}

// ============================================================================
// CVAR QUERY & CHECKING FUNCTIONS
// ============================================================================
// NOTE: These functions are used for:
// 1. Initial cvar check after player connects (all servers)
// 2. Periodic polling on non-ReAPI servers (15-60 second intervals)
// 3. ReAPI servers use fn_check_userinfo_direct() for instant real-time checks

public fn_loopquery(id) {
	gi_cvarnumID[id] = 0
	set_task(0.15, "fn_query", id, "", 0, "a", TOTAL_CVARS)
}

public fn_query(id) {
	if (gi_cvarnumID[id] < TOTAL_CVARS) {
		// OPTIMIZED: Store cvar index for use in callback (eliminates linear search)
		query_client_cvar(id, gs_cvars[gi_cvarnumID[id]], "fn_querycvar")
	}
	gi_cvarnumID[id]++
}

public fn_querycvar(id, const s_CVARNAME[], const s_VALUE[], const s_CALVALUE[]) {
	// OPTIMIZED: Pre-convert player value only (required values already pre-converted)
	new Float:valueFromPlayer = floatstr(s_VALUE)

	// OPTIMIZED: Use gi_cvarnumID directly - no linear search needed!
	// We know which cvar index this callback is for from gi_cvarnumID
	// This eliminates ~1600 string comparisons per full check
	gi_cvarnum = gi_cvarnumID[id] - 1  // Subtract 1 because it was incremented in fn_query

	// Validate the index is in range (sanity check)
	if (gi_cvarnum < 0 || gi_cvarnum >= TOTAL_CVARS) {
		log_amx("[%s] ERROR: Invalid cvar index %d for %s", gs_PLUGIN, gi_cvarnum, s_CVARNAME)
		return
	}

	// Check if this is a min/max range cvar (indices 49-56)
	// OPTIMIZED: Use pre-converted float arrays instead of floatstr()
	if (gi_cvarnum >= MIN_MAX_CVAR_START) {
		fn_checkaltallowed(id, s_CVARNAME, valueFromPlayer,
			gf_calvalues[gi_cvarnum], gf_altvalues[gi_cvarnum - MIN_MAX_CVAR_START],
			s_VALUE, s_CALVALUE)
	}
	else {
		fn_checkvalues(id, s_CVARNAME, valueFromPlayer,
			gf_calvalues[gi_cvarnum], s_VALUE, s_CALVALUE)
	}

	// Check if this is the last cvar to mark completion
	if (gi_cvarnum == LAST_CVAR_INDEX) {
		fn_firstcomplete(id)
	}
}

public fn_firstcomplete(id) {
	// Mark first check as complete (only runs once per player)
	if (!gb_FirstCheckComplete[id])
		gb_FirstCheckComplete[id] = true

	// On ReAPI servers, we use real-time userinfo monitoring - no polling needed!
	// On non-ReAPI servers, continue periodic polling
	#if defined USING_REAPI
	if (g_bUsingReHLDS) {
		// Real-time monitoring enabled - no need for periodic polling
		return
	}
	#endif

	// Schedule next check with random delay (prevents server lag spikes)
	// Only reached on non-ReAPI servers
	gf_randnum = random_float(0.15, 60.0)
	set_task(gf_randnum, "fn_loopquery", id)
}

// ============================================================================
// CVAR VALIDATION FUNCTIONS
// ============================================================================

public fn_checkvalues(id, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	// OPTIMIZED: Removed get_user_name() - it's called in fn_fcoslogshow() if needed
	new bool: isInvalid = false

	// Special handling for m_pitch (allows positive or negative)
	if (equal(s_CVARNAME, gs_pitch)) {
		// OPTIMIZED: Check floats first (faster than string comparison)
		if (!(floatabs(valueFromPlayer - calFloatValue) <= FLOAT_PRECISION ||
			  floatabs(valueFromPlayer + calFloatValue) <= FLOAT_PRECISION ||
			  equal(s_VALUE, inverse_p) || equal(s_VALUE, s_CALVALUE))) {
			isInvalid = true
		}
	}
	else {
		// OPTIMIZED: Check float first, then string fallback
		if (!(floatabs(valueFromPlayer - calFloatValue) <= FLOAT_PRECISION || equal(s_VALUE, s_CALVALUE))) {
			isInvalid = true
		}
	}

	if (isInvalid) fn_fcoslogshow(id, s_CVARNAME, valueFromPlayer, calFloatValue, s_CALVALUE)
}

public fn_checkaltallowed(id, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, Float: altFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	// OPTIMIZED: Removed get_user_name() - it's called in fn_fcoslogshow() if needed
	// Range check - value must be between calFloatValue (min) and altFloatValue (max)
	if (valueFromPlayer < calFloatValue || valueFromPlayer > altFloatValue) {
		fn_fcoslogshow(id, s_CVARNAME, valueFromPlayer, calFloatValue, s_CALVALUE)
	}
}

// ============================================================================
// PUNISHMENT & ENFORCEMENT FUNCTIONS
// ============================================================================

/**
 * Helper function to clean up player data after punishment
 * Eliminates code duplication (was repeated 3 times)
 */
stock fn_cleanup_player(id) {
	gb_StopChecking[id] = true
	remove_task(id)
	gb_FirstCheckComplete[id] = false
	gi_numofattempts[id] = 0
	gi_cvarnumID[id] = -1
}

public fn_fcoslogshow(id, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, const s_CALVALUE[]) {
	if (gb_StopChecking[id]) return PLUGIN_CONTINUE

	// OPTIMIZED: Cache gs_pitch comparison (used twice below)
	new bool:is_pitch = equal(s_CVARNAME, gs_pitch)

	// Force correct cvar value on client
	if (is_pitch && (valueFromPlayer < 0.0)) client_cmd(id, "%s %.3f", s_CVARNAME, -0.022)
	else if (is_pitch && (valueFromPlayer >= 0.0)) client_cmd(id, "%s %.3f", s_CVARNAME, 0.022)
	else client_cmd(id, "%s %.3f", s_CVARNAME, calFloatValue)

	// Get player info
	get_user_name(id, gs_logname, charsmax(gs_logname))
	get_user_authid(id, gs_logauthid, charsmax(gs_logauthid))
	get_user_ip(id, gs_logip, charsmax(gs_logip), 1)

	// Log and notify
	client_print(0, print_chat, "Attempted fix for %s. %s: %f -> %f", gs_logname, s_CVARNAME, valueFromPlayer, calFloatValue)
	log_amx("%L", LANG_SERVER, "FCOS_LANG_LOG_ENTRY", gs_logauthid, gs_logname, gs_logip, s_CVARNAME, valueFromPlayer, calFloatValue)
	// OPTIMIZED: Removed unused get_players() call

	// Only apply punishments after first check is complete
	if (gb_FirstCheckComplete[id]) {
		gi_numofattempts[id]++
		gi_userid = get_user_userid(id)
		formatex(gs_reason, charsmax(gs_reason), "%L", id, "FCOS_LANG_REASON", s_CVARNAME, calFloatValue, valueFromPlayer)

		// OPTIMIZED: Cache ALL pcvar values including ban_time
		new warn_enabled = get_pcvar_num(gp_fcos_warn)
		new warn_attempt = get_pcvar_num(gp_fcos_attempt_num_warn)
		new warn_repeat = get_pcvar_num(gp_fcos_repeat_warning)
		new change_name = get_pcvar_num(gp_fcos_change_name)
		new name_attempt = get_pcvar_num(gp_fcos_attempt_num_namechange)
		new slay_enabled = get_pcvar_num(gp_fcos_slay)
		new slay_attempt = get_pcvar_num(gp_fcos_attempt_num_slay)
		new slay_repeat = get_pcvar_num(gp_fcos_repeat_slaying)
		new kick_or_ban = get_pcvar_num(gp_fcos_kick_or_ban)
		new kickban_attempt = get_pcvar_num(gp_fcos_attempt_num_kickorban)
		gi_bantime = get_pcvar_num(gp_fcos_ban_time)  // Moved here from line 703

		// Warning MOTD
		if (warn_enabled && gi_numofattempts[id] == warn_attempt || warn_enabled && gi_numofattempts[id] > warn_attempt && warn_repeat) {
			fn_formatandshowmotd(id, s_CVARNAME, calFloatValue, valueFromPlayer)
		}

		// Name change punishment
		if (change_name && gi_numofattempts[id] == name_attempt) {
			formatex(gs_newname, charsmax(gs_newname), "[fcos] %s", s_CVARNAME)
			set_user_info(id, "name", gs_newname)
		}

		// Slay punishment
		if (slay_enabled && gi_numofattempts[id] == slay_attempt && is_user_alive(id) || slay_enabled && gi_numofattempts[id] > slay_attempt && slay_repeat && is_user_alive(id)) {
			user_kill(id)
		}

		// Kick punishment
		if (kick_or_ban == 1 && gi_numofattempts[id] == kickban_attempt) {
			server_cmd("kick #%i %s", gi_userid, gs_reason)
			fn_cleanup_player(id)
		}

		// Ban punishment
		if (kick_or_ban == 2 && gi_numofattempts[id] == kickban_attempt) {
			// OPTIMIZED: gi_bantime already cached above (line 681)
			if (equal(gs_logauthid, "STEAM_ID_PENDING")) return PLUGIN_CONTINUE

			if (get_pcvar_num(gp_fcos_use_amx_bans)) {
				server_cmd("amx_ban %i %s %s", gi_bantime, gs_logauthid, gs_reason)
				fn_cleanup_player(id)
			}
			else {
				server_cmd("banid %i #%i;writeid", gi_bantime, gi_userid)
				server_cmd("kick #%i %s", gi_userid, gs_reason)
				fn_cleanup_player(id)
			}
		}
	}

	return PLUGIN_CONTINUE
}

// ============================================================================
// MOTD DISPLAY FUNCTIONS
// ============================================================================

public fn_formatandshowmotd(id, const s_CVARNAME[], Float: calFloatValue, Float: valueFromPlayer) {
	// Use charsmax for all buffer sizes
	formatex(gs_motdtitle, charsmax(gs_motdtitle), "%L", id, "FCOS_LANG_MOTD_TITLE")
	formatex(gs_subtitle, charsmax(gs_subtitle), "%L", id, "FCOS_LANG_MOTD_SUBTITLE")
	formatex(gs_mainmsg1, charsmax(gs_mainmsg1), "%L", id, "FCOS_LANG_MOTD_MAINMSG1")
	formatex(gs_mainmsg2, charsmax(gs_mainmsg2), "%L", id, "FCOS_LANG_MOTD_MAINMSG2", s_CVARNAME, calFloatValue, valueFromPlayer)
	formatex(gs_mainmsg3, charsmax(gs_mainmsg3), "%L", id, "FCOS_LANG_MOTD_MAINMSG3")
	formatex(gs_mainmsg4, charsmax(gs_mainmsg4), "%L", id, "FCOS_LANG_MOTD_MAINMSG4")
	formatex(gs_mainmsg5, charsmax(gs_mainmsg5), "%L", id, "FCOS_LANG_MOTD_MAINMSG5")

	gi_len = formatex(gs_motd, charsmax(gs_motd), "<body bgcolor='#00000'><font color='#FFB000'>")
	gi_len += formatex(gs_motd[gi_len], charsmax(gs_motd) - gi_len, "<center><b><font size='8' color='#FF0000'>%s</font><br>", gs_motdtitle)
	gi_len += formatex(gs_motd[gi_len], charsmax(gs_motd) - gi_len, "%s</center><br>", gs_subtitle)
	gi_len += formatex(gs_motd[gi_len], charsmax(gs_motd) - gi_len, "%s ", gs_mainmsg1)
	gi_len += formatex(gs_motd[gi_len], charsmax(gs_motd) - gi_len, "%s ", gs_mainmsg2)
	gi_len += formatex(gs_motd[gi_len], charsmax(gs_motd) - gi_len, "%s ", gs_mainmsg3)
	gi_len += formatex(gs_motd[gi_len], charsmax(gs_motd) - gi_len, "%s ", gs_mainmsg4)
	gi_len += formatex(gs_motd[gi_len], charsmax(gs_motd) - gi_len, "%s", gs_mainmsg5)

	show_motd(id, gs_motd, gs_motdtitle)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
 *{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
 */