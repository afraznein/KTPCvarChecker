/* 
*   Title:    KTP Cvar Settings (fcos)
*   Author:   Nein_
*
*   Current Version:   3.6
*   Release Date:      2022-12-26
*
					   3.5 2022-07-29
*					   3.0 2022-06-17
*
*/

#include <amxmodx>
#include <amxmisc>


new const gs_PLUGIN[]	= "KTP Cvar Checker"
new const gs_VERSION[]	= "3.6"
new const gs_AUTHOR[]	= "Nein_"


new const gs_FILENAME[]	= "ktp_cvar"
new const gs_FILETYPE[]	= ".cfg"

new const gs_pitch[]	= "m_pitch"


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
new Float: gf_calfloatvalue
new Float: gf_altfloatvalue
new Float: gf_randnum


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
	"gl_round_down",
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
	"hud_takesshots",
	"m_pitch",		//44
	"m_side",       //45
	"cl_pitchdown", //46
	"cl_pitchup",   //47
	"cl_yawspeed",  //48
	"cl_pitchspeed",//49
	"lightgamma",	//50
	"cl_smoothtime",//51
	"cl_bob",       //52
	"cl_updaterate",//53
	"cl_cmdrate",   //54
	"rate",         //55
	"ex_interp"     //56
}

//Equal or Min Values
new gs_calvalues[57][] =
{
	"100",
	"0.3",
	"0.8",
	"0.5",
	"7.5",
	"1",
	"0",
	"0",
	"0.25",
	"0",
	"1",
	"0",
	"1",
	"1",
	"1",
	"0",
	"0",
	"0",
	"0",
	"1",
	"0",
	"0",
	"3",
	"1",
	"1",
	"1",
	"1",
	"0",
	"2.2",
	"0",
	"0",
	"0",
	"2",
	"0",
	"0",
	"0",
	"0.67",
	"1",
	"1",
	"320",
	"0",
	"0",
	"0.3",
	"1",
	"0.022",
	"0.8",
	"89",
	"89",
	"210",
	"225",
	"1.700000", //lightgamma
	"0.000000", //smoothtime
	"0.000000", //bob (0.004999?)
	"100",	//updaterate
	"100", //cmdrate
	"100000", //rate
	"0.000000" //interp
}

//Max Values
new gs_altvalues[7][] =
{
	"3.000000", //lightgamma
	"0.100000", //smoothtime
	"0.011000", //bob
	"120.000000", //updaterate
	"500.000000", //cmdrate
	"1000000.000000", //rate
	"0.040000" //interp
}

new gi_cvarnumID[57]
new gi_cvarnum



public plugin_init ()
{
	register_plugin ( gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	register_cvar ( "ktp_cvar_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	gp_fcos_warn			= register_cvar ( "fcos_warn", "1" )
	gp_fcos_attempt_num_warn	= register_cvar ( "fcos_attempt_num_warn", "5" )
	gp_fcos_repeat_warning		= register_cvar ( "fcos_repeat_warning", "1" )
	gp_fcos_change_name		= register_cvar ( "fcos_change_name", "0" )
	gp_fcos_attempt_num_namechange	= register_cvar ( "fcos_attempt_num_namechange", "0" )
	gp_fcos_slay			= register_cvar ( "fcos_slay", "0" )
	gp_fcos_attempt_num_slay	= register_cvar ( "fcos_attempt_num_slay", "0" )
	gp_fcos_repeat_slaying		= register_cvar ( "fcos_repeat_slaying", "0" )
	gp_fcos_kick_or_ban		= register_cvar ( "fcos_kick_or_ban", "0" )
	gp_fcos_attempt_num_kickorban	= register_cvar ( "fcos_attempt_num_kickorban", "0" )
	gp_fcos_ban_time		= register_cvar ( "fcos_ban_time", "0" )
	gp_fcos_use_amx_bans		= register_cvar ( "fcos_use_amx_bans", "0" )
	
	register_dictionary ( "ktp_cvar.txt" )
	
	get_configsdir ( gs_directory, 32 )
	formatex ( gs_fcosconfigfile, 54, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE )
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
	client_print (id, print_chat, "%s version %s, 2022 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	client_print (id, print_console, "%s version %s, 2022 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
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
		//set_task ( 10.0, "fn_loopcheater", id );
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
	set_task ( 0.15, "fn_query", id, "", 0, "a", 56 )
}

public fn_query ( id )
{

	if ( gi_cvarnumID[id] < 57 ) query_client_cvar ( id, gs_cvars[gi_cvarnumID[id]], "fn_querycvar" )
	gi_cvarnumID[id]++
}

public fn_querycvar ( id, const s_CVARNAME[], const s_VALUE[] )
{
	gf_valuefromplayer = floatstr ( s_VALUE )
	
	for ( gi_cvarnum = 0; gi_cvarnum < 50; gi_cvarnum++ )
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarnum] )
			fn_checkvalues ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		}
	}

	for ( gi_cvarnum = 50; gi_cvarnum < 57; gi_cvarnum++ )	
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarnum] )
			gf_altfloatvalue = floatstr ( gs_altvalues[gi_cvarnum-50] )
			fn_checkaltallowed ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue )
		}
	}
		
	if ( equal ( s_CVARNAME, gs_cvars[56] ) ) 
	{
		fn_firstcomplete ( id );
	}
}


public fn_firstcomplete ( id )
{
	gf_randnum = random_float(0.15,60.0);
	//client_print (id, print_console, "%f", gf_randnum);

	if (gb_FirstCheckComplete[id] == false) 
	{
		gb_FirstCheckComplete[id] = true;
		set_task ( gf_randnum, "fn_loopquery", id )
	}
	else 
	{
		set_task ( gf_randnum, "fn_loopquery", id )
	}
}


/*public fn_loopcheater ( id )
{
	gi_cvarnumcheatID[id] = 43;
	set_task ( 5.0, "fn_querycheats", id, "", 0, "a", 13)
}

public fn_querycheats ( id )
{

	if ( gi_cvarnumcheatID[id] < 56 ) query_client_cvar ( id, gs_cvars[gi_cvarnumcheatID[id]], "fn_querycheatresult" )
	gi_cvarnumcheatID[id]++
}

public fn_querycheatresult ( id, const s_CVARNAME[], const s_VALUE[] )
{
	gf_valuefromplayer = floatstr ( s_VALUE )
	
	for ( gi_cvarcheatnum = 43; gi_cvarcheatnum < 49; gi_cvarcheatnum++ )
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarcheatnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarcheatnum] )
			fn_checkvalues ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		}
	}
		
	for ( gi_cvarcheatnum = 49; gi_cvarcheatnum < 56; gi_cvarcheatnum++ )	
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarcheatnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarcheatnum] )
			gf_altfloatvalue = floatstr ( gs_altvalues[gi_cvarcheatnum-49] )
			fn_checkaltallowed ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue )
		}
	}
	gb_FirstCheaterCheckComplete[id] = true;
	set_task ( 0.25, "fn_loopcheater", id )
}*/

public fn_checkvalues ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue )
{
	get_user_name(id, gs_logname, 31);
	if ( ! ( gf_valuefromplayer == gf_calfloatvalue ) )
	{
		if (!(equal( s_CVARNAME, gs_pitch) && gf_valuefromplayer == -0.022))
		{
			client_print(0, print_chat, "%s for %s. Client: %f Authorized: %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
			client_print(0, print_console, "%s for %s. Client: %f Authorized: %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
			fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		}
	}
}

public fn_checkaltallowed ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue, Float: gf_altfloatvalue )
{
	get_user_name(id, gs_logname, 31);
	//if ( ( gf_valuefromplayer <= gf_calfloatvalue ) || ( gf_valuefromplayer >= gf_altfloatvalue ) )
	if ( ((floatcmp(gf_valuefromplayer,gf_calfloatvalue) == -1) && (floatcmp(gf_valuefromplayer,gf_calfloatvalue) != 0)) 
	|| ((floatcmp(gf_valuefromplayer,gf_altfloatvalue) == 1) && (floatcmp(gf_valuefromplayer,gf_altfloatvalue) != 0)) )
	{
		client_print(0, print_chat, "%s for %s. Client: %f Authorized: %f - %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue);
		client_print(0, print_console, "%s for %s. Client: %f Authorized: %f - %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue);
		fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
	}
}

public fn_fcoslogshow ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue )
{
	if ( ! gb_StopChecking[id] == true )
	{
		client_cmd ( id, "%s %f", s_CVARNAME, gf_calfloatvalue )

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
