/* 
*   Title:    KTP Cvar Settings (fcos)
*   Author:   Nein_
*
*   Current Version:   4.5
*   Release Date:      2024-02-27
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


new const gs_PLUGIN[]	= "KTP Cvar Checker"
new const gs_VERSION[]	= "4.5"
new const gs_AUTHOR[]	= "Nein_"


new const gs_FILENAME[]	= "ktp_cvar"
new const gs_FILETYPE[]	= ".cfg"

new const gs_pitch[]	= "m_pitch"
new const inverse_p[]   = "-0.022"
new const gs_graph[]    = "net_graph"

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

new bool: gb_FirstCheckComplete[33]
new bool: gb_StopChecking[33]

new Float: gf_valuefromplayer
new Float: gf_netvaluefromplayer
new Float: gf_calfloatvalue
new Float: gf_altfloatvalue
new Float: gf_randnum
new Float: precision = 0.00005

new gs_directory[33]
new gs_fcosconfigfile[55]

new gi_players[32]
new gi_playercnt

new gs_logname[32]
new gs_logauthid[33]
new gs_logip[44]
new gs_newname[256]
new gs_reason[256]
new gi_userid
new gi_bantime

new gi_numofattempts[33]

new gs_motd[1000]
new gi_len
new gs_motdtitle[90]
new gs_subtitle[90]
new gs_mainmsg1[90]
new gs_mainmsg2[120]
new gs_mainmsg3[90]
new gs_mainmsg4[90]
new gs_mainmsg5[90]

//Cvar list. Originally curated from original CAL list, and brazillian list used by Bud and Markoz; Massive modifications made for KTP purposes
new gs_cvars[57][] =
{
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

//Equal or Min Values
new gs_calvalues[57][] =
{
	"100", //ambient_fade
	"0.3", //ambient_level
	"0.8", //cl_bobcycle
	"0.5", //cl_bobup
	"7.5", //cl_fixtimerate
	"1", //cl_gaitestimation
	"0", //fastsprites
	"0", //gl_affinemodels
	"0.25", //gl_alphamin
	"0", //gl_clear
	"1", //gl_cull
	"0", //gl_d3dflip
	"1", //gl_dither
	"1", //gl_keeptjunctions
	"1", //gl_lightholes
	"0", //gl_monolights
	"0", //gl_nobind
	"0", //gl_nocolors
	"0", //gl_overbright
	"1", //gl_palette_tex
	"0", //gl_picmip
	"0", //gl_playermip
	"1", //r_bmodelinterp
	"1", //r_drawentities
	"1", //r_drawviewmodel
	"1", //r_dynamic
	"0", //r_fullbright
	"2.2", //r_glowshellfreq
	"0", //r_lightmap
	"0", //r_traceglow
	"0", //r_wadtextures
	"2", //texgamma
	"0", //r_luminance
	"0", //s_show
	"0", //cl_showevents
	"0.67", //cl_anglespeedkey
	"1", //cl_lc
	"1", //cl_lw
	"320", //cl_upspeed
	"0", //lookspring
	"0", //lookstrafe
	"0.3", //cl_movespeedkey
	"0.022", //m_pitch (also allow inverse -0.022)
	"0.8", //m_side
	"89", //cl_pitchdown
	"89", //cl_pitchup
	"210", //cl_yawspeed
	"225", //cl_pitchspeed
	"1", //cl_mousegrab
	"1.7", // MIN VALUE: lightgamma (Index: 49)
	"0", // MIN VALUE: cl_smoothtime (Index: 50)
	"0", // MIN VALUE: cl_bob (Index: 51)
	"100", // MIN VALUE: cl_updaterate (Index: 52)
	"100", // MIN VALUE: cl_cmdrate (Index: 53)
	"100000", // MIN VALUE: rate (Index: 54)
	"0", // MIN VALUE: ex_interp (Index: 55)
	"60" // MIN VALUE: fps_max (Index: 56)
}

//Max Values
new gs_altvalues[8][] =
{
	"3", //lightgamma
	"0.1", //smoothtime
	"0.011", //bob
	"120", //updaterate
	"500", //cmdrate
	"1000000", //rate
	"0.04", //interp
	"500" //fps_max
}

//Net_Graph
new gs_netgraph[3][] =
{
	"1", 
	"2", 
	"3"
}

new gi_cvarnumID[57]
new gi_cvarnum

public plugin_init ()
{
	register_plugin ( gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	register_cvar ( "ktp_cvar_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	gp_fcos_warn				= register_cvar ( "fcos_warn", "1" )
	gp_fcos_attempt_num_warn	= register_cvar ( "fcos_attempt_num_warn", "5" )
	gp_fcos_repeat_warning		= register_cvar ( "fcos_repeat_warning", "1" )
	gp_fcos_change_name			= register_cvar ( "fcos_change_name", "0" )
	gp_fcos_attempt_num_namechange	= register_cvar ( "fcos_attempt_num_namechange", "0" )
	gp_fcos_slay				= register_cvar ( "fcos_slay", "0" )
	gp_fcos_attempt_num_slay	= register_cvar ( "fcos_attempt_num_slay", "0" )
	gp_fcos_repeat_slaying		= register_cvar ( "fcos_repeat_slaying", "0" )
	gp_fcos_kick_or_ban			= register_cvar ( "fcos_kick_or_ban", "0" )
	gp_fcos_attempt_num_kickorban	= register_cvar ( "fcos_attempt_num_kickorban", "0" )
	gp_fcos_ban_time			= register_cvar ( "fcos_ban_time", "0" )
	gp_fcos_use_amx_bans		= register_cvar ( "fcos_use_amx_bans", "0" )
	
	register_dictionary ( "ktp_cvar.txt" )
	
	get_configsdir ( gs_directory, 32 )
	formatex ( gs_fcosconfigfile, 57, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE )
	if ( file_exists ( gs_fcosconfigfile ) ) server_cmd ( "exec %s", gs_fcosconfigfile )
	
	fn_servermessage ()
}

public fn_servermessage ()
{
	server_print ( "%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	server_print ( "%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG1" )
	if ( file_exists ( gs_fcosconfigfile ) ) server_print ( "%L", LANG_SERVER, "FCOS_LANG_SERVER_MSG2" )
}

public fn_msginitial ( id )
{
	get_user_name(id, gs_logname, 31);
	client_print (id, print_chat, "%s version %s, 2024 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	client_print (id, print_console, "%s version %s, 2024 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	client_print (id, print_chat, "Initializing KTP Cvar Checker for %s.", gs_logname);
	client_print (id, print_console, "Initializing KTP Cvar Checker for %s.", gs_logname);
}

public client_putinserver ( id )
{
	if ( ! is_user_bot ( id ) && ! is_user_hltv ( id ) )
	{
		gb_FirstCheckComplete[id] = false;
		gb_StopChecking[id] = false;
		gi_numofattempts[id] = 0;
		set_task ( 5.0, "fn_msginitial", id );
		set_task ( 7.5, "fn_loopquery", id );
		//set_task ( 30, "fn_netgraph", id );
	}
}

public client_disconnect ( id )
{
	gb_StopChecking[id] = true;
	remove_task ( id );
	gb_FirstCheckComplete[id] = false;
	gi_numofattempts[id] = 0;
}


public fn_loopquery ( id )
{
	//client_print (id, print_console, "Loop Query Started");
	gi_cvarnumID[id] = 0;
	set_task ( 0.15, "fn_query", id, "", 0, "a", 58 )
}

public fn_query ( id )
{
	if ( gi_cvarnumID[id] < 57 ) query_client_cvar ( id, gs_cvars[gi_cvarnumID[id]], "fn_querycvar" )
	gi_cvarnumID[id]++
}

public fn_querycvar ( id, const s_CVARNAME[], const s_VALUE[], const s_CALVALUE[] )
{
	gf_valuefromplayer = floatstr ( s_VALUE )
	
	for ( gi_cvarnum = 0; gi_cvarnum < 49; gi_cvarnum++ )
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue = floatstr (gs_calvalues[gi_cvarnum])
			fn_checkvalues ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, s_VALUE, s_CALVALUE )
		}
	}

	for ( gi_cvarnum = 49; gi_cvarnum < 57; gi_cvarnum++ )	
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue =  floatstr(gs_calvalues[gi_cvarnum])
			gf_altfloatvalue =  floatstr(gs_altvalues[gi_cvarnum-49])
			fn_checkaltallowed ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue, s_VALUE, s_CALVALUE )
		}
	}
		
	if ( equal ( s_CVARNAME, gs_cvars[56] ) ) 
	{
		fn_firstcomplete ( id );
		//client_print (id, print_console, "First Loop marked completed.");
	}
}


public fn_firstcomplete ( id )
{
	gf_randnum = random_float(0.15,60.0);
	//client_print (id, print_console, "%f", gf_randnum);

	if (gb_FirstCheckComplete[id] == false) 
	{
		gb_FirstCheckComplete[id] = true;
		//set_task ( 0.15, "fn_loopquery", id )
		set_task ( gf_randnum, "fn_loopquery", id )
	}
	else 
	{
		//set_task ( 0.15, "fn_loopquery", id )
		set_task ( gf_randnum, "fn_loopquery", id )
	}
}

public fn_checkvalues ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue, const s_VALUE[], const s_CALVALUE[])
{
	get_user_name(id, gs_logname, 31);
	if (equal (s_CVARNAME, gs_pitch))
	{
		//client_print (id, print_chat, "m_pitch debug detection s: %s f: %f", s_VALUE, gf_valuefromplayer);
		if (!(equal(s_VALUE, inverse_p) || (equal(s_VALUE, s_CALVALUE)) || (floatabs(gf_valuefromplayer - gf_calfloatvalue) <= precision)|| (floatabs(gf_valuefromplayer + gf_calfloatvalue) <= precision)))//(gf_valuefromplayer == gf_calfloatvalue)))//
		{
			client_print(0, print_chat, "%s for %s. Client: %f Authorized: -%f OR %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
			client_print(0, print_console, "%s for %s. Client: %f Authorized: -%f OR %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
			fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, s_CALVALUE )
		}
	}
	else
	{
		if (!((equal(s_VALUE, s_CALVALUE)) || (floatabs(gf_valuefromplayer - gf_calfloatvalue) <= precision)))
		{
		client_print(0, print_chat, "%s for %s. Client: %f Authorized: %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
		client_print(0, print_console, "%s for %s. Client: %f Authorized: %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
		fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, s_CALVALUE )
		}
	}
	/*if( (!( gf_valuefromplayer == gf_calfloatvalue)) )
	{
		client_print(0, print_chat, "%s for %s. Client: %f Authorized: %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
		client_print(0, print_console, "%s for %s. Client: %f Authorized: %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
		fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
	}*/
}

public fn_checkaltallowed ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue, Float: gf_altfloatvalue,const s_VALUE[], const s_CALVALUE[] )
{
	get_user_name(id, gs_logname, 31);

	if ( ((floatcmp(gf_valuefromplayer,gf_calfloatvalue) == -1) && (floatcmp(gf_valuefromplayer,gf_calfloatvalue) != 0)) 
	|| ((floatcmp(gf_valuefromplayer,gf_altfloatvalue) == 1) && (floatcmp(gf_valuefromplayer,gf_altfloatvalue) != 0)) )
	//if (!(floatabs(gf_valuefromplayer - gf_calfloatvalue) <= precision))
	{
		client_print(0, print_chat, "%s for %s. Client: %f Authorized: %f - %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue);
		client_print(0, print_console, "%s for %s. Client: %f Authorized: %f - %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue);
		fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, s_CALVALUE )
	}
}

public fn_fcoslogshow ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue, const s_CALVALUE[] )
{
	if ( ! gb_StopChecking[id] == true )
	{

		//client_cmd ( id, "%s %f", s_CVARNAME, gf_calfloatvalue )
		if (equal(s_CVARNAME, gs_pitch) && (gf_valuefromplayer < 0))
		{
			client_cmd ( id, "%s %f", s_CVARNAME, -0.022 )
		}
		else if (equal(s_CVARNAME, gs_pitch) && (gf_valuefromplayer >= 0))
		{
			client_cmd ( id, "%s %f", s_CVARNAME, 0.022 )
		}
		else 
		{
			client_cmd ( id, "%s %f", s_CVARNAME, gf_calfloatvalue )
		}
		

		get_user_name ( id, gs_logname, 31 )
		get_user_authid ( id, gs_logauthid, 32 )
		get_user_ip ( id, gs_logip, 43 )
		
		client_print(0, print_chat, "Attempted %s for %s from %f to %f", gs_logname, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue);
		client_print(0, print_console, "Attempted %s for %s from %f to %f", gs_logname, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue);
		
		log_amx ( "%L", LANG_SERVER, "FCOS_LANG_LOG_ENTRY", gs_logauthid, gs_logname, gs_logip, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		
		get_players ( gi_players, gi_playercnt, "ch" ) //ch removes bot (c) and hltv proxy (h)
		
		//if ( gb_FirstCheckComplete[id] == true || gb_FirstCheaterCheckComplete[id] == true )
		if ( gb_FirstCheckComplete[id] == true )
		{
			gi_numofattempts[id]++
			gi_userid = get_user_userid ( id )
			formatex ( gs_reason, 255, "%L", id, "FCOS_LANG_REASON", s_CVARNAME, gf_calfloatvalue, gf_valuefromplayer )
			
			if ( get_pcvar_num ( gp_fcos_warn ) && gi_numofattempts[id] == get_pcvar_num ( gp_fcos_attempt_num_warn ) || get_pcvar_num ( gp_fcos_warn ) && gi_numofattempts[id] > get_pcvar_num ( gp_fcos_attempt_num_warn ) && get_pcvar_num ( gp_fcos_repeat_warning ) )
			{
				fn_formatandshowmotd ( id, s_CVARNAME, gf_calfloatvalue, gf_valuefromplayer )
			}
			
			if ( get_pcvar_num ( gp_fcos_change_name ) && gi_numofattempts[id] == get_pcvar_num ( gp_fcos_attempt_num_namechange ) )
			{
				formatex ( gs_newname, 255, "[fcos] %s", s_CVARNAME )
				set_user_info ( id, "name", gs_newname )
			}
			
			if ( get_pcvar_num ( gp_fcos_slay ) && gi_numofattempts[id] == get_pcvar_num ( gp_fcos_attempt_num_slay ) && is_user_alive ( id ) || get_pcvar_num ( gp_fcos_slay ) && gi_numofattempts[id] > get_pcvar_num ( gp_fcos_attempt_num_slay ) && get_pcvar_num ( gp_fcos_repeat_slaying ) && is_user_alive ( id ) )
			{
				user_kill ( id )
			}
			
			if ( get_pcvar_num ( gp_fcos_kick_or_ban ) == 1 && gi_numofattempts[id] == get_pcvar_num ( gp_fcos_attempt_num_kickorban ) )
			{
				server_cmd ( "kick #%i %s", gi_userid, gs_reason )
				gb_StopChecking[id] = true
				remove_task ( id )
				gb_FirstCheckComplete[id] = false
				gi_numofattempts[id] = 0
				gi_cvarnumID[id] = -1
			}
			
			if ( get_pcvar_num ( gp_fcos_kick_or_ban ) == 2 && gi_numofattempts[id] == get_pcvar_num ( gp_fcos_attempt_num_kickorban ) )
			{
				gi_bantime = get_pcvar_num ( gp_fcos_ban_time )
				
				if ( equal ( gs_logauthid, "STEAM_ID_PENDING" ) ) return PLUGIN_CONTINUE
				
				else if ( get_pcvar_num ( gp_fcos_use_amx_bans ) )
				{
					server_cmd ( "amx_ban %i %s %s", gi_bantime, gs_logauthid, gs_reason )
					gb_StopChecking[id] = true
					remove_task ( id )
					gb_FirstCheckComplete[id] = false
					gi_numofattempts[id] = 0
					gi_cvarnumID[id] = -1
				}
				
				else
				{
					server_cmd ( "banid %i #%i;writeid", gi_bantime, gi_userid )
					server_cmd ( "kick #%i %s", gi_userid, gs_reason )
					gb_StopChecking[id] = true
					remove_task ( id )
					gb_FirstCheckComplete[id] = false
					gi_numofattempts[id] = 0
					gi_cvarnumID[id] = -1
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE
}

public fn_formatandshowmotd ( id, const s_CVARNAME[], Float: gf_calfloatvalue, Float: gf_valuefromplayer )
{
	formatex ( gs_motdtitle, 89, "%L", id, "FCOS_LANG_MOTD_TITLE" )
	formatex ( gs_subtitle, 89, "%L", id, "FCOS_LANG_MOTD_SUBTITLE" )
	formatex ( gs_mainmsg1, 89, "%L", id, "FCOS_LANG_MOTD_MAINMSG1" )
	formatex ( gs_mainmsg2, 119, "%L", id, "FCOS_LANG_MOTD_MAINMSG2", s_CVARNAME, gf_calfloatvalue, gf_valuefromplayer )
	formatex ( gs_mainmsg3, 89, "%L", id, "FCOS_LANG_MOTD_MAINMSG3" )
	formatex ( gs_mainmsg4, 89, "%L", id, "FCOS_LANG_MOTD_MAINMSG4" )
	formatex ( gs_mainmsg5, 89, "%L", id, "FCOS_LANG_MOTD_MAINMSG5" )
	
	gi_len = formatex ( gs_motd , 999 , "<body bgcolor=^"#00000^"><font color=^"#FFB000^">" )
	gi_len += formatex ( gs_motd[gi_len], 999-gi_len, "<center><b><font size=^"8^" color=^"#FF0000^">%s</font><br>", gs_motdtitle )
	gi_len += formatex ( gs_motd[gi_len], 999-gi_len, "%s</center><br>", gs_subtitle )
	gi_len += formatex ( gs_motd[gi_len], 999-gi_len, "%s ", gs_mainmsg1 )
	gi_len += formatex ( gs_motd[gi_len], 999-gi_len, "%s ", gs_mainmsg2 )
	gi_len += formatex ( gs_motd[gi_len], 999-gi_len, "%s ", gs_mainmsg3 )
	gi_len += formatex ( gs_motd[gi_len], 999-gi_len, "%s ", gs_mainmsg4 )
	gi_len += formatex ( gs_motd[gi_len], 999-gi_len, "%s", gs_mainmsg5 )
	
	show_motd ( id, gs_motd, gs_motdtitle )
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
