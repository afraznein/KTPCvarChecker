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
new gs_cvars[][] =
{
	"ambient_fade",
	"ambient_level",
	"cl_bobcycle",
	"cl_bobup",
	"cl_fixtimerate",
	"cl_gaitestimation",
	"cl_gg",
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
	"gl_flipmatrix",
	"gl_keeptjunctions",
	"gl_lightholes",
	"gl_monolights",
	"gl_nobind",
	"gl_nocolors",
	"gl_overbright",
	"gl_palette_tex",
	"gl_picmip",
	"gl_playermip",
	"gl_reporttjunctions",
	"gl_round_down",
	"gl_ztrick_old",
	"lambert",
	"lightgamma",
	"nosound",
	"r_bmodelinterp",
	"r_cachestudio",
	"r_cullsequencebox",
	"r_drawentities",
	"r_drawviewmodel",
	"r_dynamic",
	"r_fullbright",
	"r_glowshellfreq",
	"r_lightmap",
	"r_norefresh",
	"r_novis",
	"r_speeds",
	"r_traceglow",
	"r_wadtextures",
	"r_wateralpha",
	"s_a3d",
	"texgamma",
	"developer",
	"hud_draw",
	"cl_cmdbackup",
	"lookspring",
	"r_luminance",
	"s_show",
	"c_maxdistance",
	"c_maxpitch",
	"c_maxyaw",
	"c_minpitch",
	"c_minyaw",
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
	"cl_smoothtime",//80
	"cl_bob",		//81
	"cl_updaterate",//82
	"cl_cmdrate",	//83
	"rate",			//84
	"ex_interp" 	//85
}

//Equal or Min Values
new gs_calvalues[][] =
{
	"100",
	"0.3",
	"0.8",
	"0.5",
	"7.5",
	"1",
	"0",
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
	"0",
	"1",
	"1",
	"0",
	"0",
	"0",
	"0",
	"1",
	"0",
	"0",
	"0",
	"3",
	"0",
	"1.5",
	"2.5",
	"0",
	"1",
	"1",
	"1",
	"1",
	"1",
	"1",
	"0",
	"2.2",
	"0",
	"0",
	"0",
	"0",
	"0",
	"0",
	"1",
	"0",
	"2",
	"0",
	"1",
	"2",
	"0",
	"0",
	"0",
	"200",
	"90",
	"135",
	"0",
	"-135",
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
	"0.009"
}

//Max Values
new gs_altvalues[][] =
{
	"0.1",
	"0.011",
	"120",
	"250",
	"1000000",
	"0.03"
}


new gi_cvarnumID[33]
new gi_cvarnum


public plugin_init ()
{
	register_plugin ( gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	register_cvar ( "ktp_cvar_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	gp_fcos_repeat_check		= register_cvar ( "fcos_repeat_check", "0" )
	gp_fcos_show_admin_forced_msg	= register_cvar ( "fcos_show_admin_forced_msg", "0" )
	gp_fcos_warn			= register_cvar ( "fcos_warn", "0" )
	gp_fcos_attempt_num_warn	= register_cvar ( "fcos_attempt_num_warn", "0" )
	gp_fcos_repeat_warning		= register_cvar ( "fcos_repeat_warning", "0" )
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

public client_putinserver ( id )
{
	if ( ! is_user_bot ( id ) && ! is_user_hltv ( id ) )
	{
		gb_FirstCheckComplete[id] = false
		gb_StopChecking[id] = false
		gi_numofattempts[id] = 0
		gi_cvarnumID[id] = -1
		set_task ( 30.0, "fn_loopquerries", id )
	}
}

public client_disconnect ( id )
{
	gb_StopChecking[id] = true
	remove_task ( id )
	gb_FirstCheckComplete[id] = false
	gi_numofattempts[id] = 0
	gi_cvarnumID[id] = -1
}

public fn_loopquerries ( id )
{
	gi_cvarnumID[id] = -1
	set_task ( 0.14, "fn_query", id, "", 0, "a", 71 )
}

public fn_query ( id )
{
	gi_cvarnumID[id]++
	
	if ( gi_cvarnumID[id] < 86 ) query_client_cvar ( id, gs_cvars[gi_cvarnumID[id]], "fn_queryresult" )
}

public fn_queryresult ( id, const s_CVARNAME[], const s_VALUE[] )
{
	gf_valuefromplayer = floatstr ( s_VALUE )
	
	for ( gi_cvarnum = 0; gi_cvarnum < 80; gi_cvarnum++ )
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarnum] )
			
			fn_checkvalues ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		}
	}
	
	if ( equal ( s_CVARNAME, gs_cvars[80] ) )
	{
		gf_calfloatvalue = floatstr ( gs_calvalues[80] )
		gf_altfloatvalue = floatstr ( gs_altvalues[0] )
		
		if ( ( gf_valuefromplayer < gf_calfloatvalue ) || ( gf_valuefromplayer > gf_altfloatvalue ) )
		{
			fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		}
	}			
	
	for ( gi_cvarnum = 80; gi_cvarnum < 86; gi_cvarnum++ )
	{
		if ( equal ( s_CVARNAME, gs_cvars[gi_cvarnum] ) )
		{
			gf_calfloatvalue = floatstr ( gs_calvalues[gi_cvarnum] )
			gf_altfloatvalue = floatstr ( gs_altvalues[gi_cvarnum+1] )
			
			fn_checkaltallowed ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue, gf_altfloatvalue )
		}
	}
	
	if ( equal ( s_CVARNAME, gs_cvars[80] ) ) fn_checkfirstcomplete ( id )
}

public fn_checkfirstcomplete ( id )
{
	if ( get_pcvar_num ( gp_fcos_repeat_check ) )
	{
		if ( gb_FirstCheckComplete[id] == true ) set_task ( 1.0, "fn_loopquerries", id )
		else set_task ( 5.0, "fn_restartcycle", id )
	}
}

public fn_restartcycle ( id )
{
	gb_FirstCheckComplete[id] = true
	set_task ( 1.0, "fn_loopquerries", id )
}

public fn_checkvalues ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue )
{
	if ( ! ( gf_valuefromplayer == gf_calfloatvalue ) )
	{
		fn_fcoslogshow ( id, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
	}
}

public fn_checkaltallowed ( id, const s_CVARNAME[], Float: gf_valuefromplayer, Float: gf_calfloatvalue, Float: gf_altfloatvalue )
{
	if ( ( gf_valuefromplayer < gf_calfloatvalue ) || ( gf_valuefromplayer > gf_altfloatvalue ) )
	{
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
		
		log_amx ( "%L", LANG_SERVER, "FCOS_LANG_LOG_ENTRY", gs_logname, get_user_userid ( id ), gs_logauthid, gs_logip, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
		
		get_players ( gi_players, gi_playercnt, "ch" )
		
		for ( gi_playernum = 0; gi_playernum < gi_playercnt; gi_playernum++ )
		{
			gi_playerID = gi_players[gi_playernum]
			
			if ( is_user_admin ( gi_playerID ) && get_pcvar_num ( gp_fcos_show_admin_forced_msg ) )
			{
				client_print ( gi_playerID, print_console, "%L", LANG_SERVER, "FCOS_LANG_SHOW_ADMIN", gs_logname, s_CVARNAME, gf_valuefromplayer, gf_calfloatvalue )
			}
		}
		
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
