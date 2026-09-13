// Fixture for tools/test_check_published_cvars.py. Hand-written in the shape of
// ktp_cvar.sma and deliberately NOT generated from it: the paired
// cvar_list.md must be an independent statement of the same rules, or a check
// comparing the two could not fail.

new const inverse_p[] = "-0.022";

#define TOTAL_CVARS 8
#define MIN_MAX_CVAR_START 4
#define ALT_VALUES_COUNT 4

#define HUD_TAKESSHOTS_INDEX 1
#define M_PITCH_INDEX 2

new gs_cvars[TOTAL_CVARS][] = {
"r_fullbright", "hud_takesshots", "m_pitch", "r_glowshellfreq",
"lightgamma", "cl_updaterate", "rate", "ex_interp"
}

new gs_calvalues[TOTAL_CVARS][] = {
"0", "1", "0.022", "2.2",          // r_glowshellfreq is the "engine default"
"1.809", "100", "100000", "0.01"
}

new gs_altvalues[ALT_VALUES_COUNT][] = {
"3", "120", "100000", "0.05"
}

public fn_checkvalues(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, Float: calFloatValue, const s_VALUE[], const s_CALVALUE[]) {
	if (cvar_index == M_PITCH_INDEX) {
		if (!(floatabs(valueFromPlayer - calFloatValue) <= 0.00005 ||
			  equal(s_VALUE, inverse_p) || equal(s_VALUE, s_CALVALUE))) {
			defer_enforcement(id, cvar_index, valueFromPlayer, false)
		}
	}
}

stock fn_enforce_cvar(id, cvar_index, const s_CVARNAME[], Float: valueFromPlayer, bool:ceiling) {
	if (cvar_index == HUD_TAKESSHOTS_INDEX) {
		if (!gp_cvar_match_competitive)
			gp_cvar_match_competitive = get_cvar_pointer("ktp_match_competitive")
		if (gp_cvar_match_competitive && get_pcvar_num(gp_cvar_match_competitive) == 0)
			return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}
