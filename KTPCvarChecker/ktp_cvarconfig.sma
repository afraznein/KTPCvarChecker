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


new const gs_PLUGIN[]	= "KTP Cvar Settings Config"
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


new gi_menupage[33]
new g_keys
new gi_casenum
new gs_menucase[10][64]
new gs_fcosmenu[512]


new gi_warningattemptnum
new gi_namechangeattemptnum
new gi_slayingattemptnum
new gi_kickorbanattemptnum
new gi_kickorbansetting
new gs_kickorbanshow[6]
new gi_bantime


new gs_directory[33]
new gs_cfgfile[128]


new gs_fcos_repeat_check[64]
new gs_fcos_show_admin_forced_msg[64]
new gs_fcos_warn[64]
new gs_fcos_attempt_num_warn[64]
new gs_fcos_repeat_warning[64]
new gs_fcos_change_name[64]
new gs_fcos_attempt_num_namechange[64]
new gs_fcos_slay[64]
new gs_fcos_attempt_num_slay[64]
new gs_fcos_repeat_slaying[64]
new gs_fcos_kick_or_ban[64]
new gs_fcos_attempt_num_kickorban[64]
new gs_fcos_ban_time[64]
new gs_fcos_use_amx_bans[64]


new gs_motdurl[128]


public plugin_init ()
{
	register_plugin ( gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	register_cvar ( "fcoscfg_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	gp_fcos_repeat_check		= get_cvar_pointer ( "fcos_repeat_check" )
	gp_fcos_show_admin_forced_msg	= get_cvar_pointer ( "fcos_show_admin_forced_msg" )
	gp_fcos_warn			= get_cvar_pointer ( "fcos_warn" )
	gp_fcos_attempt_num_warn	= get_cvar_pointer ( "fcos_attempt_num_warn" )
	gp_fcos_repeat_warning		= get_cvar_pointer ( "fcos_repeat_warning" )
	gp_fcos_change_name		= get_cvar_pointer ( "fcos_change_name" )
	gp_fcos_attempt_num_namechange	= get_cvar_pointer ( "fcos_attempt_num_namechange" )
	gp_fcos_slay			= get_cvar_pointer ( "fcos_slay" )
	gp_fcos_attempt_num_slay	= get_cvar_pointer ( "fcos_attempt_num_slay" )
	gp_fcos_repeat_slaying		= get_cvar_pointer ( "fcos_repeat_slaying" )
	gp_fcos_kick_or_ban		= get_cvar_pointer ( "fcos_kick_or_ban" )
	gp_fcos_attempt_num_kickorban	= get_cvar_pointer ( "fcos_attempt_num_kickorban" )
	gp_fcos_ban_time		= get_cvar_pointer ( "fcos_ban_time" )
	gp_fcos_use_amx_bans		= get_cvar_pointer ( "fcos_use_amx_bans" )
		
	register_clcmd ( "amx_ktpmenu", "fn_checkaccess", ADMIN_CFG, "- [KTP]: Configuration Menu" )
	register_clcmd ( "say /ktpsmenu", "fn_checkaccess", ADMIN_CFG, "- [KTP]: Configuration Menu" )
	register_clcmd ( "say /ktpshelp", "fn_showfcoshelp", ADMIN_CFG, "- Shows KTP Menu Help Page." )
	register_clcmd ( "/ktphelp", "fn_showfcoshelp", ADMIN_CFG, "- Shows KTP Menu Help Page." )
	register_dictionary ( "ktp_cvarcfg.txt" )
	register_menucmd ( register_menuid ( "[KTP CVAR]" ), 1023, "fn_menuselection" )
}

public fn_checkaccess ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	else
	{
		gi_menupage[id] = 1
		fn_showfcosmenu ( id )
	}
	
	return PLUGIN_HANDLED
}

public fn_showfcosmenu ( id )
{
	g_keys =  (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
	
	for ( gi_casenum = 0; gi_casenum < 10; ++gi_casenum )
	{
		gs_menucase[gi_casenum][0] = 0
	}
	
	switch ( gi_menupage[id] )
	{
		case 1:
		{
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "FCOS_LANG_MENU_REPEAT_CHECKING", get_pcvar_num ( gp_fcos_repeat_check ) ? "ON" : "OFF" )
			formatex ( gs_menucase[1], 63, "\w2. %L\R\y%s^n", id, "FCOS_LANG_MENU_SHOW_ADMIN_MESSAGE", get_pcvar_num ( gp_fcos_show_admin_forced_msg ) ? "ON" : "OFF" )
			
			if ( ! get_pcvar_num ( gp_fcos_repeat_check ) )
			{
				formatex ( gs_menucase[2], 63, "\d3. %L\R\d%s^n", id, "FCOS_LANG_MENU_WARNING", get_pcvar_num ( gp_fcos_warn ) ? "ON" : "OFF" )
				formatex ( gs_menucase[3], 63, "\d4. %L\R\d%i^n", id, "FCOS_LANG_MENU_WARNING_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_warn ) )
				formatex ( gs_menucase[4], 63, "\d5. %L\R\d%s^n", id, "FCOS_LANG_MENU_REPEAT_WARNING", get_pcvar_num ( gp_fcos_repeat_warning ) ? "ON" : "OFF" )
				formatex ( gs_menucase[5], 63, "\d6. %L\R\d%s^n", id, "FCOS_LANG_MENU_NAME_CHANGE", get_pcvar_num ( gp_fcos_change_name ) ? "ON" : "OFF" )
				formatex ( gs_menucase[6], 63, "\d7. %L\R\d%i^n^n", id, "FCOS_LANG_MENU_NAME_CHANGE_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_namechange ) )
				formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "FCOS_LANG_MENU_SAVE" )
				formatex ( gs_menucase[8], 63, "\d9. %L^n", id, "FCOS_LANG_MENU_MORE" )
				formatex ( gs_menucase[9], 63, "\w0. %L", id, "FCOS_LANG_MENU_EXIT" )
				g_keys -= (1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<8)
			}
			
			else
			{
				formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "FCOS_LANG_MENU_WARNING", get_pcvar_num ( gp_fcos_warn ) ? "ON" : "OFF" )
				
				if ( ! get_pcvar_num ( gp_fcos_warn ) )
				{
					formatex ( gs_menucase[3], 63, "\d4. %L\R\d%i^n", id, "FCOS_LANG_MENU_WARNING_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_warn ) )
					formatex ( gs_menucase[4], 63, "\d5. %L\R\d%s^n", id, "FCOS_LANG_MENU_REPEAT_WARNING", get_pcvar_num ( gp_fcos_repeat_warning ) ? "ON" : "OFF" )
					g_keys -= (1<<3)|(1<<4)
				}
				
				else
				{
					formatex ( gs_menucase[3], 63, "\w4. %L\R\y%i^n", id, "FCOS_LANG_MENU_WARNING_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_warn ) )
					formatex ( gs_menucase[4], 63, "\w5. %L\R\y%s^n", id, "FCOS_LANG_MENU_REPEAT_WARNING", get_pcvar_num ( gp_fcos_repeat_warning ) ? "ON" : "OFF" )
				}
				
				formatex ( gs_menucase[5], 63, "\w6. %L\R\y%s^n", id, "FCOS_LANG_MENU_NAME_CHANGE", get_pcvar_num ( gp_fcos_change_name ) ? "ON" : "OFF" )
				
				if ( ! get_pcvar_num ( gp_fcos_change_name ) )
				{
					formatex ( gs_menucase[6], 63, "\d7. %L\R\d%i^n^n", id, "FCOS_LANG_MENU_NAME_CHANGE_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_namechange ) )
					g_keys -= (1<<6)
				}
				
				else
				{
					formatex ( gs_menucase[6], 63, "\w7. %L\R\y%i^n^n", id, "FCOS_LANG_MENU_NAME_CHANGE_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_namechange ) )
				}
				
				formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "FCOS_LANG_MENU_SAVE" )
				formatex ( gs_menucase[8], 63, "\w9. %L^n", id, "FCOS_LANG_MENU_MORE" )
				formatex ( gs_menucase[9], 63, "\w0. %L", id, "FCOS_LANG_MENU_EXIT" )
			}
		}
		
		case 2:
		{
			gi_kickorbansetting = get_pcvar_num ( gp_fcos_kick_or_ban )
			
			if ( gi_kickorbansetting == 0 ) copy ( gs_kickorbanshow, 5, "OFF" )
			else if ( gi_kickorbansetting == 1 ) copy ( gs_kickorbanshow, 5, "KICK" )
			else if ( gi_kickorbansetting == 2 ) copy ( gs_kickorbanshow, 5, "BAN" )
			
			gi_bantime = get_pcvar_num ( gp_fcos_ban_time )
			
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "FCOS_LANG_MENU_SLAYING", get_pcvar_num ( gp_fcos_slay ) ? "ON" : "OFF" )
			
			if ( ! get_pcvar_num ( gp_fcos_slay ) )
			{
				formatex ( gs_menucase[1], 63, "\d2. %L\R\d%i^n", id, "FCOS_LANG_MENU_SLAYING_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_slay ) )
				formatex ( gs_menucase[2], 63, "\d3. %L\R\d%s^n", id, "FCOS_LANG_MENU_REPEAT_SLAYING", get_pcvar_num ( gp_fcos_repeat_slaying ) ? "ON" : "OFF" )
				g_keys -= (1<<1)|(1<<2)
			}
			
			else
			{
				formatex ( gs_menucase[1], 63, "\w2. %L\R\y%i^n", id, "FCOS_LANG_MENU_SLAYING_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_slay ) )
				formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "FCOS_LANG_MENU_REPEAT_SLAYING", get_pcvar_num ( gp_fcos_repeat_slaying ) ? "ON" : "OFF" )
			}
			
			formatex ( gs_menucase[3], 63, "\w4. %L\R\y%s^n", id, "FCOS_LANG_MENU_KICK_OR_BAN", gs_kickorbanshow )
			
			if ( gi_kickorbansetting == 0 )
			{
				formatex ( gs_menucase[4], 63, "\d5. %L\R\d%i^n", id, "FCOS_LANG_MENU_KICK_OR_BAN_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_kickorban ) )
				formatex ( gs_menucase[5], 63, gi_bantime ? "\d6. %L\R\d%i MINS^n" : "\d6. %L\R\dPERMANENT^n", id, "FCOS_LANG_MENU_BAN_TIME", gi_bantime )
				formatex ( gs_menucase[6], 63, "\d7. %L\R\d%s^n^n", id, "FCOS_LANG_MENU_USE_AMX_BAN", get_pcvar_num ( gp_fcos_use_amx_bans ) ? "ON" : "OFF" )
				g_keys -= (1<<4)|(1<<5)|(1<<6)
			}
			
			else if ( gi_kickorbansetting == 1 )
			{
				formatex ( gs_menucase[4], 63, "\w5. %L\R\y%i^n", id, "FCOS_LANG_MENU_KICK_OR_BAN_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_kickorban ) )
				formatex ( gs_menucase[5], 63, gi_bantime ? "\d6. %L\R\d%i MINS^n" : "\d6. %L\R\dPERMANENT^n", id, "FCOS_LANG_MENU_BAN_TIME", gi_bantime )
				formatex ( gs_menucase[6], 63, "\d7. %L\R\d%s^n^n", id, "FCOS_LANG_MENU_USE_AMX_BAN", get_pcvar_num ( gp_fcos_use_amx_bans ) ? "ON" : "OFF" )
				g_keys -= (1<<5)|(1<<6)
			}
			
			else
			{
				formatex ( gs_menucase[4], 63, "\w5. %L\R\y%i^n", id, "FCOS_LANG_MENU_KICK_OR_BAN_ATTEMPT", get_pcvar_num ( gp_fcos_attempt_num_kickorban ) )
				formatex ( gs_menucase[5], 63, gi_bantime ? "\w6. %L\R\y%i MINS^n" : "\w6. %L\R\yPERMANENT^n", id, "FCOS_LANG_MENU_BAN_TIME", gi_bantime )
				formatex ( gs_menucase[6], 63, "\w7. %L\R\y%s^n^n", id, "FCOS_LANG_MENU_USE_AMX_BAN", get_pcvar_num ( gp_fcos_use_amx_bans ) ? "ON" : "OFF" )
			}
			
			formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "FCOS_LANG_MENU_SAVE" )
			formatex ( gs_menucase[9], 63, "\w0. %L", id, "FCOS_LANG_MENU_BACK" )
			g_keys -= (1<<8)
		}
	}

	formatex ( gs_fcosmenu, 511, "\y[KTP CVAR] Menu:^n^n%s%s%s%s%s%s%s%s%s%s", gs_menucase[0], gs_menucase[1], gs_menucase[2], gs_menucase[3], gs_menucase[4], gs_menucase[5], gs_menucase[6], gs_menucase[7], gs_menucase[8], gs_menucase[9] )
	
	show_menu ( id, g_keys, gs_fcosmenu )
	
	return PLUGIN_HANDLED
}

public fn_menuselection ( id, key )
{
	if ( gi_menupage[id] == 1 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_fcos_repeat_check, get_pcvar_num ( gp_fcos_repeat_check ) ? 0 : 1 )
			case 1: set_pcvar_num ( gp_fcos_show_admin_forced_msg, get_pcvar_num ( gp_fcos_show_admin_forced_msg ) ? 0 : 1 )
			case 2: set_pcvar_num ( gp_fcos_warn, get_pcvar_num ( gp_fcos_warn ) ? 0 : 1 )
			
			case 3:
			{
				gi_warningattemptnum = get_pcvar_num ( gp_fcos_attempt_num_warn )
				if ( gi_warningattemptnum++ > 35 || gi_warningattemptnum > 35 ) set_pcvar_num ( gp_fcos_attempt_num_warn, 1 )
				else set_pcvar_num ( gp_fcos_attempt_num_warn, gi_warningattemptnum++ )
			}
			
			case 4: set_pcvar_num ( gp_fcos_repeat_warning, get_pcvar_num ( gp_fcos_repeat_warning ) ? 0 : 1 )
			case 5: set_pcvar_num ( gp_fcos_change_name, get_pcvar_num ( gp_fcos_change_name ) ? 0 : 1 )
			
			case 6:
			{
				gi_namechangeattemptnum = get_pcvar_num ( gp_fcos_attempt_num_namechange )
				if ( gi_namechangeattemptnum++ > 35 || gi_namechangeattemptnum > 35 ) set_pcvar_num ( gp_fcos_attempt_num_namechange, 1 )
				else set_pcvar_num ( gp_fcos_attempt_num_namechange, gi_namechangeattemptnum++ )
			}
			
			case 7: fn_fcossave ( id )
			
			case 8:
			{
				gi_menupage[id] = 2
				fn_showfcosmenu ( id )
				return PLUGIN_HANDLED
			}
			
			case 9:
			{
				gi_menupage[id] = 0
				return PLUGIN_HANDLED
			}
		}
		
		fn_showfcosmenu ( id )
		return PLUGIN_HANDLED
	}
	
	if ( gi_menupage[id] == 2 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_fcos_slay, get_pcvar_num ( gp_fcos_slay ) ? 0 : 1 )
			
			case 1:
			{
				gi_slayingattemptnum = get_pcvar_num ( gp_fcos_attempt_num_slay )
				if ( gi_slayingattemptnum++ > 35 || gi_slayingattemptnum > 35 ) set_pcvar_num ( gp_fcos_attempt_num_slay, 1 )
				else set_pcvar_num ( gp_fcos_attempt_num_slay, gi_slayingattemptnum++ )
			}
			
			case 2: set_pcvar_num ( gp_fcos_repeat_slaying, get_pcvar_num ( gp_fcos_repeat_slaying ) ? 0 : 1 )
			
			case 3:
			{
				gi_kickorbansetting = get_pcvar_num ( gp_fcos_kick_or_ban )
				if ( gi_kickorbansetting == 0 ) set_pcvar_num ( gp_fcos_kick_or_ban, 1 )
				else if ( gi_kickorbansetting == 1 ) set_pcvar_num ( gp_fcos_kick_or_ban, 2 )
				else if ( gi_kickorbansetting == 2 ) set_pcvar_num ( gp_fcos_kick_or_ban, 0 )
			}
			
			case 4:
			{
				gi_kickorbanattemptnum = get_pcvar_num ( gp_fcos_attempt_num_kickorban )
				if ( gi_kickorbanattemptnum++ > 35 || gi_kickorbanattemptnum > 35 ) set_pcvar_num ( gp_fcos_attempt_num_kickorban, 1 )
				else set_pcvar_num ( gp_fcos_attempt_num_kickorban, gi_kickorbanattemptnum++ )
			}
			
			case 5:
			{
				gi_bantime = get_pcvar_num ( gp_fcos_ban_time )
				if ( gi_bantime + 30 > 600 || gi_bantime > 600 ) set_pcvar_num ( gp_fcos_ban_time, 0 )
				else set_pcvar_num ( gp_fcos_ban_time, gi_bantime += 30 )
			}
			
			case 6: set_pcvar_num ( gp_fcos_use_amx_bans, get_pcvar_num ( gp_fcos_use_amx_bans ) ? 0 : 1 )
			
			case 7: fn_fcossave ( id )
			
			case 9:
			{
				gi_menupage[id] = 1
				fn_showfcosmenu ( id )
				return PLUGIN_HANDLED
			}
		}
	}
	
	update_fcosmenu ()
	return PLUGIN_HANDLED
}

public update_fcosmenu ()
{
	new i_playerID[32], i_playercnt, menu, keys
	
	get_players ( i_playerID, i_playercnt )
	
	for ( new i_playernum = 0; i_playernum < i_playercnt; ++i_playernum )
	{
		if ( gi_menupage[i_playerID[i_playernum]] > 0 && ! get_user_menu ( i_playerID[i_playernum], menu, keys ) ) gi_menupage[i_playerID[i_playernum]] = 0
		else if ( gi_menupage[i_playerID[i_playernum]] > 0 ) fn_showfcosmenu ( i_playerID[i_playernum] )
		else return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public fn_fcossave ( id )
{
	formatex ( gs_fcos_repeat_check, 63, "fcos_repeat_check %i", get_pcvar_num ( gp_fcos_repeat_check ) )
	formatex ( gs_fcos_show_admin_forced_msg, 63, "fcos_show_admin_forced_msg %i", get_pcvar_num ( gp_fcos_show_admin_forced_msg ) )
	formatex ( gs_fcos_warn, 63, "fcos_warn %i", get_pcvar_num ( gp_fcos_warn ) )
	formatex ( gs_fcos_attempt_num_warn, 63, "fcos_attempt_num_warn %i", get_pcvar_num ( gp_fcos_attempt_num_warn ) )
	formatex ( gs_fcos_repeat_warning, 63, "fcos_repeat_warning %i", get_pcvar_num ( gp_fcos_repeat_warning ) )
	formatex ( gs_fcos_change_name, 63, "fcos_change_name %i", get_pcvar_num ( gp_fcos_change_name ) )
	formatex ( gs_fcos_attempt_num_namechange, 63, "fcos_attempt_num_namechange %i", get_pcvar_num ( gp_fcos_attempt_num_namechange ) )
	formatex ( gs_fcos_slay, 63, "fcos_slay %i", get_pcvar_num ( gp_fcos_slay ) )
	formatex ( gs_fcos_attempt_num_slay, 63, "fcos_attempt_num_slay %i", get_pcvar_num ( gp_fcos_attempt_num_slay ) )
	formatex ( gs_fcos_repeat_slaying, 63, "fcos_repeat_slaying %i", get_pcvar_num ( gp_fcos_repeat_slaying ) )
	formatex ( gs_fcos_kick_or_ban, 63, "fcos_kick_or_ban %i", get_pcvar_num ( gp_fcos_kick_or_ban ) )
	formatex ( gs_fcos_attempt_num_kickorban, 63, "fcos_attempt_num_kickorban %i", get_pcvar_num ( gp_fcos_attempt_num_kickorban ) )
	formatex ( gs_fcos_ban_time, 63, "fcos_ban_time %i", get_pcvar_num ( gp_fcos_ban_time ) )
	formatex ( gs_fcos_use_amx_bans, 63, "fcos_use_amx_bans %i", get_pcvar_num ( gp_fcos_use_amx_bans ) )
	
	get_configsdir ( gs_directory, 32 )
	formatex ( gs_cfgfile, 127, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE )
	
	write_file ( gs_cfgfile, gs_fcos_repeat_check, 7 )
	write_file ( gs_cfgfile, gs_fcos_show_admin_forced_msg, 12 )
	write_file ( gs_cfgfile, gs_fcos_warn, 17 )
	write_file ( gs_cfgfile, gs_fcos_attempt_num_warn, 21 )
	write_file ( gs_cfgfile, gs_fcos_repeat_warning, 26 )
	write_file ( gs_cfgfile, gs_fcos_change_name, 31 )
	write_file ( gs_cfgfile, gs_fcos_attempt_num_namechange, 36 )
	write_file ( gs_cfgfile, gs_fcos_slay, 41 )
	write_file ( gs_cfgfile, gs_fcos_attempt_num_slay, 45 )
	write_file ( gs_cfgfile, gs_fcos_repeat_slaying, 50 )
	write_file ( gs_cfgfile, gs_fcos_kick_or_ban, 55 )
	write_file ( gs_cfgfile, gs_fcos_attempt_num_kickorban, 60 )
	write_file ( gs_cfgfile, gs_fcos_ban_time, 65 )
	write_file ( gs_cfgfile, gs_fcos_use_amx_bans, 70 )
	
	client_print ( id, print_chat, "%L", id, "FCOS_LANG_MENU_SAVE_MSG" )
	
	return PLUGIN_CONTINUE
}

public fn_showfcoshelp ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	else
	{
		formatex ( gs_motdurl, 127, "https://discord.gg/2TKYnK7Q9J" )
		show_motd ( id, gs_motdurl, "KTP Cvar Checker" )
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
