/* 
*   Title:    KTP File Checker
*   Author:   Nein_
*
*   Current Version:   1.0
*   Release Date:      2023-02-15
*
*
*

* AMX Mod X Plugin
* 
* (c) Copyright 2008, ConnorMcLeod 
* This file is provided as is (no warranties). 
* 
*/ 

#include <amxmodx>

new g_pcvarExactModel, g_pcvarSeparateLogFile

new gi_fileNumID
new gs_files[90][] =
{	
	"models/player/axis-inf/axis-inf.mdl",
	"models/player/axis-inf/axis-infT.mdl",
	"models/player/axis-para/axis-para.mdl",
	"models/player/axis-para/axis-paraT.mdl",
	"models/player/us-inf/us-inf.mdl",
	"models/player/us-inf/us-infT.mdl",
	"models/player/us-para/us-para.mdl",
	"models/player/us-para/us-paraT.mdl",
	"player/headshot1.wav",
	"player/damage1.wav",
	"player/damage2.wav",
	"player/damage3.wav",
	"player/damage4.wav",
	"player/damage5.wav",
	"player/damage6.wav",
	"player/damage7.wav",
	"player/damage8.wav",
	"player/damage9.wav",
	"player/damage10.wav",
	"player/damage11.wav",
	"player/ow.wav",
	"player/goprone.wav",
	"player/jump.wav",
	"player/jumplanding.wav",
	"player/pl_dirt1.wav",
	"player/pl_dirt2.wav",
	"player/pl_dirt3.wav",
	"player/pl_dirt4.wav",
	"player/pl_duct1.wav",
	"player/pl_duct2.wav",
	"player/pl_duct3.wav",
	"player/pl_duct4.wav",
	"player/pl_fallpain.wav",
	"player/pl_gravel1.wav",
	"player/pl_gravel2.wav",
	"player/pl_gravel3.wav",
	"player/pl_gravel4.wav",
	"player/pl_ladder1.wav",
	"player/pl_ladder2.wav",
	"player/pl_ladder3.wav",
	"player/pl_ladder4.wav",
	"player/pl_metal1.wav",
	"player/pl_metal2.wav",
	"player/pl_metal3.wav",
	"player/pl_metal4.wav",
	"player/pl_shell1.wav",
	"player/pl_shell2.wav",
	"player/pl_shell3.wav",
	"player/pl_slosh1.wav",
	"player/pl_slosh2.wav",
	"player/pl_slosh3.wav",
	"player/pl_slosh4.wav",
	"player/pl_step1.wav",
	"player/pl_step2.wav",
	"player/pl_step3.wav",
	"player/pl_step4.wav",
	"player/pl_tile1.wav",
	"player/pl_tile2.wav",
	"player/pl_tile3.wav",
	"player/pl_tile4.wav",
	"player/pl_tile5.wav",
	"player/pl_wade1.wav",
	"player/pl_wade2.wav",
	"player/pl_wade3.wav",
	"player/pl_wade4.wav",
	"player/pl_wood1.wav",
	"player/pl_wood2.wav",
	"player/pl_wood3.wav",
	"player/pl_wood4.wav",
	"player/pl_grate1.wav",
	"player/pl_grate2.wav",
	"player/pl_grate3.wav",
	"player/pl_grate4.wav",
	"player/pl_swim1.wav",
	"player/pl_swim2.wav",
	"player/pl_swim3.wav",
	"player/pl_swim4.wav",
	"player/pl_snow1.wav",
	"player/pl_snow2.wav",
	"player/pl_snow3.wav",
	"player/pl_snow4.wav",
	"models/p_grenade.mdl",
	"models/p_mills.mdl",
	"models/p_stick.mdl",
	"models/v_grenade.mdl",
	"models/v_mills.mdl",
	"models/v_stick.mdl",
	"models/w_grenade.mdl",
	"models/w_mills.mdl",
	"models/w_stick.mdl"
}

public plugin_init()
{
	static const VERSION[] = "1.0"
	register_plugin("KTP Files Check", VERSION, "Nein_")
	register_cvar("fc_version", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	g_pcvarSeparateLogFile = register_cvar("fc_separatelog", "2")
}

public plugin_precache()
{
	g_pcvarExactModel = register_cvar("fc_exactweapons", "1")
	for ( gi_fileNumID = 0; gi_fileNumID < 90; gi_fileNumID++ )	
	{
		force_unmodified(get_pcvar_float(g_pcvarExactModel) ? force_exactfile : force_model_samebounds, {0,0,0}, {0,0,0}, gs_files[gi_fileNumID])
	}
}

public inconsistent_file(id, const filename[], reason[64])
{
	static szMessage[192], szName[32], szAuthid[32]

	get_user_name(id, szName, 31)
	get_user_authid(id, szAuthid, 31)

	//formatex(szMessage, 191, "^"%s<%s>^" has inconsistent file ^"%s^"", szName, szAuthid, filename)

	switch( get_pcvar_num(g_pcvarSeparateLogFile) )
	{
		case 1:
		{
			log_amx(szMessage)
		}
		case 2:
		{
			static const szLogFile[] = "filecheck.log"
			log_to_file(szLogFile, szMessage)
		}
		default:
		{
			log_message(szMessage)
		}
	}

	//server_cmd("say ^"%s^"", szMessage)
	log_amx(szMessage)
	return PLUGIN_HANDLED
}