/* 
*   Title:    KTP File Checker
*   Author:   Nein_
*
*   Current Version:   1.1
*   
*   Release Date:       2023-02-23
*						1.0 2023-02-15
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

	static szConfigFile[64]
	get_localinfo("amxx_configsdir", szConfigFile, 63)
	format(szConfigFile, 63, "%s/adminn.ini", szConfigFile)

	new File = fopen(szConfigFile, "rt")

	if(!File)
		return

	static szFile[64]
	while(!feof(File))
	{
		fgets(File, szFile, 63)
		trim( szFile )
		if(!szFile[0] || szFile[0] == ';' || (szFile[0] == '/' && szFile[1] == '/'))
			continue
		if(equali(szFile[strlen(szFile)-4], ".mdl"))
		{
			force_unmodified(get_pcvar_float(g_pcvarExactModel) ? force_exactfile : force_model_samebounds, {0,0,0}, {0,0,0}, szFile)
		}
		else
		{
			force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, szFile)
		}
	}
	fclose(File)
}

public inconsistent_file(id, const filename[], reason[64])
{
	static szMessage[192], szName[32], szAuthid[32]

	get_user_name(id, szName, 31)
	get_user_authid(id, szAuthid, 31)

	formatex(szMessage, 191, "^"%s<%s>^" has inconsistent file ^"%s^"", szName, szAuthid, filename)

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
	return PLUGIN_HANDLED
}