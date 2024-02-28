/* 
*   Title:    KTP File Checker
*   Author:   Nein_
*
*   Current Version:   1.3
*   Release Date:      2023-03-28
*
*						1.1 2023-02-23
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

new gs_logname[32]
new const gs_PLUGIN[]	= "KTP File Checker"
new const gs_VERSION[]	= "1.3"
new const gs_AUTHOR[]	= "Nein_"

public fn_msginitial ( id )
{
	get_user_name(id, gs_logname, 31);
	client_print (id, print_chat, "%s version %s, 2023 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	client_print (id, print_console, "%s version %s, 2023 KTP by %s", gs_PLUGIN, gs_VERSION, gs_AUTHOR );
	client_print (id, print_chat, "Initializing KTP File Checker for %s.", gs_logname);
	client_print (id, print_console, "Initializing KTP File Checker for %s.", gs_logname);
}

public plugin_init()
{
	static const VERSION[] = "1.2"
	register_plugin("KTP File Checker", VERSION, "Nein_")
	register_cvar("fc_version", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	g_pcvarSeparateLogFile = register_cvar("fc_separatelog", "2")
}

public client_putinserver ( id )
{
	if ( ! is_user_bot ( id ) && ! is_user_hltv ( id ) )
	{
		set_task ( 5.0, "fn_msginitial", id );
	}
}

public plugin_precache()
{
	g_pcvarExactModel = register_cvar("fc_exactweapons", "1")

	static szConfigFile[64]
	get_localinfo("amxx_configsdir", szConfigFile, 63)
	format(szConfigFile, 63, "%s/filelist.ini", szConfigFile)

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

	server_cmd("say ^"%s^"", szMessage)
	return PLUGIN_HANDLED
}