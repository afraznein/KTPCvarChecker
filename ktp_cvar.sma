/* 
*   Title:    KTP Cvar Settings (fcos)
*   Author:   Nein_
*
*   Current Version:   3.0
*   Release Date:      2022-06-17
*
*/

/*  AMXModX Script
*
*   Title:    Force CAL Open Settings (fcos)
*   Author:   SubStream
*
*   Current Version:   2.9
*   Release Date:      2007-04-06
*
*   For support on this plugin, please visit the following URL:
*   Force CAL Open Settings URL = http://forums.alliedmods.net/showthread.php?t=25927
*
*   Force CAL Open Settings - Forces CAL Open required settings for the Counter-Strike mod.
*   Copyright (C) 2006  SubStream
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*
*   Author Contact Email: starlineclan@dj-rj.com
*/


#include <amxmodx>
#include <amxmisc>


new const gs_PLUGIN[]	= "KTP Cvar Settings"
new const gs_VERSION[]	= "3.0"
new const gs_AUTHOR[]	= "Nein_"


new const gs_FILENAME[]	= "ktp_cvar"
new const gs_FILETYPE[]	= ".cfg"


new gp_fcos_repeat_check
new gp_fcos_show_admin_forced_msg
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


new gs_directory[33]
new gs_fcosconfigfile[55]


new gi_players[32]
new gi_playercnt
new gi_playernum 
new gi_playerID


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


//Cvar list curated from original CAL list and list used by Bud and Markoz
new gs_cvars[65][] =
{
	"ambient_fade",
	"ambient_level",
	"cl_bobcycle",
	"cl_bobup",
	"cl_fixtimerate",
	"cl_gaitestimation",
	"cl_resend",
	"fakelag",
	"fakeloss",
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
	"lightgamma",
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
	"developer",
	"r_luminance",
	"s_show",
	"cl_showevents",
	"cl_anglespeedkey",
	"cl_yawspeed",
	"cl_pitchspeed",
	"cl_lc",
	"cl_lw",
	"cl_upspeed",
	"cl_forwardspeed",
	"cl_backspeed",
	"cl_dlmax",
	"lookspring",
	"lookstrafe",
	"m_pitch",
	"m_side",
	"cl_pitchdown",
	"cl_pitchup",
	"cl_yawspeed",
	"cl_movespeedkey",
	"cl_pmanstats",
	"cl_smoothtime",//59
	"cl_bob",       //60
	"cl_updaterate",//61
	"cl_cmdrate",   //62
	"rate",         //63
	"ex_interp"     //64
}

//Equal or Min Values
new gs_calvalues[65][] =
{
	"100",
	"0.3",
	"0.8",
	"0.5",
	"7.5",
	"1",
	"6",
	"0",
	"0",
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
	"2.5",
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
	"0",
	"0.67",
	"210",
	"225",
	"1",
	"1",
	"320",
	"400",
	"400",
	"128",
	"0",
	"0",
	"0.022",
	"0.8",
	"89",
	"89",
	"210",
	"0.3",
	"0",
	"0",
	"0.005",
	"100",
	"100",
	"100000",
	"0.01"
}

//Max Values
new gs_altvalues[6][] =
{
	"0.1",
	"0.011",
	"120",
	"250",
	"1000000",
	"0.03"
}


new gi_cvarnumID[86]
new gi_cvarnum


public plugin_init ()
{
	register_plugin ( gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	register_cvar ( "ktp_cvar_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	gp_fcos_repeat_check		= register_cvar ( "fcos_repeat_check", "1" )
	gp_fcos_show_admin_forced_msg	= register_cvar ( "fcos_show_admin_forced_msg", "1" )
	gp_fcos_warn			= register_cvar ( "fcos_warn", "1" )
	gp_fcos_attempt_num_warn	= register_cvar ( "fcos_attempt_num_warn", "1" )
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
	//gi_playercnt = 0
	
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
	//client_print (id, print_chat, "%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	//client_print (id, print_console, "%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	//client_print (gi_playerID, print_chat, "%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	//client_print (gi_playerID, print_console, "%L", LANG_SERVER, "FCOS_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	
	get_user_name(id, gs_logname, 31);
	client_print (id, print_chat, "%s version %s, 2022 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	client_print (id, print_console, "%s version %s, 2022 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	client_print (id, print_chat, "Initializing KTP Cvar Checker for user %s.", gs_logname);
	client_print (id, print_console, "Initializing KTP Cvar Checker for user %s.", gs_logname);
}

public client_putinserver ( id )
{
	if ( ! is_user_bot ( id ) && ! is_user_hltv ( id ) )
	{
		gb_FirstCheckComplete[id] = false;
		gb_StopChecking[id] = false;
		gi_numofattempts[id] = 0;
		gi_cvarnumID[id] = -1;
		set_task ( 5.0, "fn_msginitial", id );
		set_task ( 5.0, "fn_loopquerries", id );
	}
}

public client_disconnect ( id )
{
	gb_StopChecking[id] = true;
	remove_task ( id );
	gb_FirstCheckComplete[id] = false;
	gi_numofattempts[id] = 0;
	gi_cvarnumID[id] = -1;
}

public fn_loopquerries ( id )
{
	gi_cvarnumID[id] = -1
	//get_user_name(id, gs_logname, 31);
	client_print(0, print_chat, "Temporary Debug Line: Cvar Checker Started for %s", gs_logname);
	set_task ( 0.14, "fn_query", id, "", 0, "a", 71 )
	
}

public fn_query ( id )
{
	gi_cvarnumID[id]++
	//get_user_name(id, gs_logname, 31);
	//client_print(0, print_chat, "Starting query for %s", gs_logname);
	if ( gi_cvarnumID[id] < 65 ) query_client_cvar ( id, gs_cvars[gi_cvarnumID[id]], "fn_queryresult" )
}

public fn_queryresult ( id, const s_CVARNAME[], const s_VALUE[] )
{
	gf_valuefromplayer = floatstr ( s_VALUE )
	
	gi_cvarnum = 0;
	while (gi_cvarnum < 59)
	//for ( gi_cvarnum = 0; gi_cvarnum < 80; gi_cvarnum++ )
	{ 
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarnum] )
			//client_print(0, print_chat, "Checking value %s on cvar %s for user %s against KTP value %f", gf_valuefromplayer, gs_cvars[gi_cvarnum], gs_logname, gf_calfloatvalue);
			fn_checkvalues ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		}
		gi_cvarnum +=1;
	}
		
	gi_cvarnum = 59;
	while (gi_cvarnum < 65)
	//for ( gi_cvarnum = 85; gi_cvarnum < 86; gi_cvarnum++ )
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarnum] )
			gf_altfloatvalue = floatstr ( gs_altvalues[gi_cvarnum-59] )
			
			//get_user_name(id, gs_logname, 31);
			//client_print(0, print_chat, "Checking value %s for user %s against the range of %f <= %f <= %f", gs_cvars[gi_cvarnum], gs_logname, gf_calfloatvalue, gf_valuefromplayer, gf_altfloatvalue);
			
			fn_checkaltallowed ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue )
		}
		gi_cvarnum += 1;
	}
	//client_print(0, print_chat, "Checking value equivalency %s = %s?", s_CVARNAME, gs_cvars[64]);
	if ( equal ( s_CVARNAME, gs_cvars[64] ) ) 
	{
		//get_user_name(id, gs_logname, 31);
		//client_print(0, print_chat, "Should have checked all %f values. Does %s = %s? If so, we check for firstcomplete bool", gi_cvarnum, s_CVARNAME, gs_cvars[64]);
		fn_checkfirstcomplete ( id );
	}
}

public fn_checkfirstcomplete ( id )
{
	//client_print(0, print_chat, "Made it to chkfirstcomplete. value of FirstCheckComplete[player index: %i]: %b", id, gb_FirstCheckComplete[id]);
	if (gb_FirstCheckComplete[id] == false) 
	{
		get_user_name(id, gs_logname, 31);
		//client_print(0, print_chat, "FirstCheckComplete was false for user %s, going to restart cycle", gs_logname);
		set_task ( 0.14, "fn_restartcycle", id )

	}
	else 
	{
		get_user_name(id, gs_logname, 31);
		//client_print(0, print_chat, "FirstCheckComplete was true for user %s, going to continue loopquerries", gs_logname);
		set_task ( 1.0, "fn_loopquerries", id )
	}
}

public fn_restartcycle ( id )
{
	gb_FirstCheckComplete[id] = true
	get_user_name(id, gs_logname, 31);
	//client_print(0, print_chat, "Set FirstCheckComplete to true for %s, Setting task to loopquerries", gs_logname);
	set_task ( 1.0, "fn_loopquerries", id )
}

public fn_checkvalues ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue )
{
	get_user_name(id, gs_logname, 31);
	if ( ! ( gf_valuefromplayer == gf_calfloatvalue ) )
	{
		client_print(0, print_chat, "KTP. %s for player %s. Client value: %f Authorized Value: %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue);
		fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
	}
}

public fn_checkaltallowed ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue, Float: gf_altfloatvalue )
{
	//if ( ( gf_valuefromplayer <= gf_calfloatvalue ) || ( gf_valuefromplayer >= gf_altfloatvalue ) )
	if ( ((floatcmp(gf_valuefromplayer,gf_calfloatvalue) == -1) && (floatcmp(gf_valuefromplayer,gf_calfloatvalue) != 0)) 
	|| ((floatcmp(gf_valuefromplayer,gf_altfloatvalue) == 1) && (floatcmp(gf_valuefromplayer,gf_altfloatvalue) != 0)) )
	{
		client_print(0, print_chat, "KTP. %s for player %s. Client value: %f Authorized Values (inclusive) between %f - %f", s_CVARNAME, gs_logname, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue);
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
		
		client_print(0, print_chat, "Attempted to overrwite %s for user %s from %f to %f", gs_logname, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue);
		
		//gi_playernum = 0;
		//while (gi_playernum < gi_playercnt)
		//{
		//	gi_playerID = gi_players[gi_playernum];
		//	//client_print(0, print_chat, "%L", 0, "Player: %s", gs_logname);
		//	//client_print(0, print_chat, "%L", 0, "FCOS_LANG_SERVER_MSG2", gs_logname, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue);
		//	gi_playernum += 1;
		//}
		
		log_amx ( "%L", LANG_SERVER, "FCOS_LANG_LOG_ENTRY", gs_logname, get_user_userid ( id ), gs_logauthid, gs_logip, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		
		get_players ( gi_players, gi_playercnt, "ch" ) //ch removes bot (c) and hltv proxy (h)
		
		//for ( gi_playernum = 0; gi_playernum < gi_playercnt; gi_playernum++ )
		//{
		//	gi_playerID = gi_players[gi_playernum]
		//	
		//	if ( is_user_admin ( gi_playerID ) && get_pcvar_num ( gp_fcos_show_admin_forced_msg ) )
		//	{
		//		client_print ( 0, print_console, "%L", LANG_SERVER, "FCOS_LANG_SHOW_ADMIN", gs_logname, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		//	}
		//}
		
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
