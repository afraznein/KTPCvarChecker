using FluentFTP;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;
using System.Threading;

namespace DoDCvarCheckerFTP {
    class Program {
        public static List<string> LogFiles = new List<string>();
        public static HashSet<string> LogFilesNew = new HashSet<string>();
        public static HashSet<string> LogFilesNew2 = new HashSet<string>();
        public static HashSet<string> LogLines = new HashSet<string>();
        public static Dictionary<string, int> CvarErrors = new Dictionary<string, int>();
        public static Dictionary<string, HashSet<string>> SteamIDDictionary = new Dictionary<string, HashSet<string>>();
        public static Dictionary<string, HashSet<string>> RconCommands = new Dictionary<string, HashSet<string>>();
        public static Dictionary<string, string> IPDictionary = new Dictionary<string, string>();
        public static Dictionary<string, int> NumViolations = new Dictionary<string, int>();
        public static int numServers = 0;
        public static bool ignoreRates = false;
        public static string Version = "KTP Cvar Checker FTPLOG. Version 02.27.24 Nein_";

        static void Main(string[] args) {

            // ..\..\..\ for debug
            // ..\..\..\..\ for publish
            while (true) {
                Console.WriteLine(Version);
                Console.WriteLine(DateTime.Now+" 1. Get status of all of the files, last modified date.");
                Console.WriteLine(DateTime.Now+" 2. Push FTP Update");
                Console.WriteLine(DateTime.Now+" 3. Pull File Logs");
                Console.WriteLine(DateTime.Now+" 4. Pull CVAR logs");
                Console.WriteLine(DateTime.Now+" 5. Pull CVAR logs (ignore rates)");
                Console.WriteLine(DateTime.Now+" 6. Delete server CVAR logs");
                Console.WriteLine(DateTime.Now+" 7. Pull dod logs");
                Console.WriteLine(DateTime.Now+" 8. Delete File Logs");
                string val = Console.ReadLine();
                int input = Convert.ToInt32(val);
                if (input == 1) {
                    //Get the status of the local files
                    Local_GetAllLocalFiles();
                }
                if (input == 2) {
                    //Push FTP update for all 15 servers
                    FTP_AllServers();
                }
                if (input == 3) {
                    DeleteLocalLogs();
                    FTP_DownloadFileLogsAllServers();
                    LogFiles.Clear();
                    LogFilesNew.Clear();
                    LogFilesNew2.Clear();
                    LogLines.Clear();
                    SteamIDDictionary.Clear();
                    IPDictionary.Clear();
                    ProcessDirectory(@"N:\Nein_\KTPCvarChecker\Logs\");
                    ProcessFileLogs();
                }
                if (input == 4) {
                    //Pull logs and create .txt file
                    DeleteLocalLogs();
                    FTP_DownloadAllServers();
                    LogFiles.Clear();
                    LogFilesNew.Clear();
                    LogFilesNew2.Clear();
                    LogLines.Clear();
                    SteamIDDictionary.Clear();
                    IPDictionary.Clear();
                    ProcessDirectory(@"N:\Nein_\KTPCvarChecker\Logs\");
                    ProcessLogs();
                }
                if (input == 5) {
                    //Pull logs and create .txt file
                    ignoreRates = true;
                    DeleteLocalLogs();
                    FTP_DownloadAllServers();
                    LogFiles.Clear();
                    LogFilesNew.Clear();
                    LogFilesNew2.Clear();
                    LogLines.Clear();
                    SteamIDDictionary.Clear();
                    IPDictionary.Clear();
                    ProcessDirectory(@"N:\Nein_\KTPCvarChecker\Logs\");
                    ProcessLogs();
                    ignoreRates = false;
                }
                if (input == 6) {
                    //Pull logs and create .txt file
                    DeleteLocalLogs();
                    FTP_DownloadAllServers();
                    LogFiles.Clear();
                    LogFilesNew.Clear();
                    LogFilesNew2.Clear();
                    LogLines.Clear();
                    SteamIDDictionary.Clear();
                    IPDictionary.Clear();
                    ProcessLogs();
                    FTP_DeleteLogsAllServers();
                }
                if (input == 7) {
                    //Pull dod logs and create .txt file
                    LogFiles.Clear();
                    LogFilesNew.Clear();
                    LogFilesNew2.Clear();
                    LogLines.Clear();
                    SteamIDDictionary.Clear();
                    IPDictionary.Clear();
                    FTP_DownloadDoDLogsAllServers();
                    ProcessDoDLogs();
                }
                if (input == 8) {
                    FTP_DeleteFileLogsAllServers();
                }
            }
        }

        public static void Local_GetAllLocalFiles() {
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\configs\amxx.cfg");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\configs\plugins.ini");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\configs\filelist.ini");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\data\lang\ktp_cvar.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\data\lang\ktp_cvarcfg.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\plugins\ktp_cvar.amxx");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\plugins\ktp_cvarconfig.amxx");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\amxmodx\plugins\filescheck.amxx");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\server.cfg");
            Console.WriteLine(DateTime.Now+" End of KTP/AMX \r\n \r\n");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\ace.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\dod_railroad.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\dod_railroad2_b2.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\dod_siena.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\jlord.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\lennonn.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\thunder2.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\cs_havana.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\dod_advance.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\dod_carta.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\dod_custom.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\dod_emmanuel.wad");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\anjou.wad");
            Console.WriteLine(DateTime.Now+" End of .wads \r\n \r\n");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_halle.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_halle.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_harrington.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_harrington.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_lennon_test.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_lennon_test.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_b2.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_b2.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railyard_b4.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railyard_b4.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_saints_b5.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_saints_b5.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_siena_test.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_siena_test.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_solitude_b2.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_solitude_b2.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_thunder2_b4.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_thunder2_b4.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_test.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_test.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_armory_b5.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_armory_b5.res");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_anjou_a2.bsp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_anjou_a2.res");
            Console.WriteLine(DateTime.Now+" End of maps \r\n \r\n");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_anzio.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_anzio.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_chemille.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_chemille.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_halle.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_halle.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_harrington.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_harrington.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_lennon_test.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_lennon_test.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_b2.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_b2.txt");
            //Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railyard_b4.bmp");
            //Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railyard_b4.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints_b5.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints_b5.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_siena_test.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_siena_test.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_solitude_b2.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_solitude_b2.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b2.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b2.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b3.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b3.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b4.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b4.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_test.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_test.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_armory_b5.bmp");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_armory_b5.txt");
            Console.WriteLine(DateTime.Now+" End of overviews");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\server.cfg");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\Sync\dod\models\mapmodels\flo_rubble_a.mdl");
            Console.WriteLine(DateTime.Now+" End of configs and msc.");
        }

        public static void Local_GetDateTimeModified(string path) {
            DateTime dt;
            dt = File.GetLastWriteTime(path);
            Console.WriteLine(DateTime.Now+" The last write time for " + path + " was {0}.", dt);
        }

        public static void FTP_AllServers() {
            numServers = 0;
            FTP_Update(ServerKeys.THREESIDEDQUARTER_DAL_HOSTNAME, ServerKeys.THREESIDEDQUARTER_DAL_IP, Convert.ToInt32(ServerKeys.THREESIDEDQUARTER_DAL_PORT), ServerKeys.THREESIDEDQUARTER_DAL_USERNAME, ServerKeys.THREESIDEDQUARTER_DAL_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.THREE_H_WARCHYLD_LA_HOSTNAME, ServerKeys.THREE_H_WARCHYLD_LA_IP, Convert.ToInt32(ServerKeys.THREE_H_WARCHYLD_LA_PORT), ServerKeys.THREE_H_WARCHYLD_LA_USERNAME, ServerKeys.THREE_H_WARCHYLD_LA_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.THREE_H_PIFF_ATL_HOSTNAME, ServerKeys.THREE_H_PIFF_ATL_IP, Convert.ToInt32(ServerKeys.THREE_H_PIFF_ATL_PORT), ServerKeys.THREE_H_PIFF_ATL_USERNAME, ServerKeys.THREE_H_PIFF_ATL_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.ICYHOT_KANGUH_CHI_HOSTNAME, ServerKeys.ICYHOT_KANGUH_CHI_IP, Convert.ToInt32(ServerKeys.ICYHOT_KANGUH_CHI_PORT), ServerKeys.ICYHOT_KANGUH_CHI_USERNAME, ServerKeys.ICYHOT_KANGUH_CHI_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.NineteenEleven_NY_2_HOSTNAME, ServerKeys.NineteenEleven_NY_2_IP, Convert.ToInt32(ServerKeys.NineteenEleven_NY_2_PORT), ServerKeys.NineteenEleven_NY_2_USERNAME, ServerKeys.NineteenEleven_NY_2_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.NineteenEleven_CHI_1_HOSTNAME, ServerKeys.NineteenEleven_CHI_1_IP, Convert.ToInt32(ServerKeys.NineteenEleven_CHI_1_PORT), ServerKeys.NineteenEleven_CHI_1_USERNAME, ServerKeys.NineteenEleven_CHI_1_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.NineteenEleven_NY_1_HOSTNAME, ServerKeys.NineteenEleven_NY_1_IP, Convert.ToInt32(ServerKeys.NineteenEleven_NY_1_PORT), ServerKeys.NineteenEleven_NY_1_USERNAME, ServerKeys.NineteenEleven_NY_1_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.NineteenEleven_DAL_1_HOSTNAME, ServerKeys.NineteenEleven_DAL_1_IP, Convert.ToInt32(ServerKeys.NineteenEleven_DAL_1_PORT), ServerKeys.NineteenEleven_DAL_1_USERNAME, ServerKeys.NineteenEleven_DAL_1_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.SHAKYTABLE_DAL_HOSTNAME, ServerKeys.SHAKYTABLE_DAL_IP, Convert.ToInt32(ServerKeys.SHAKYTABLE_DAL_PORT), ServerKeys.SHAKYTABLE_DAL_USERNAME, ServerKeys.SHAKYTABLE_DAL_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.NOGO_CHI_HOSTNAME, ServerKeys.NOGO_CHI_IP, Convert.ToInt32(ServerKeys.NOGO_CHI_PORT), ServerKeys.NOGO_CHI_USERNAME, ServerKeys.NOGO_CHI_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, Convert.ToInt32(ServerKeys.MTP_NY_PORT), ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.MTP_CHI_HOSTNAME, ServerKeys.MTP_CHI_IP, Convert.ToInt32(ServerKeys.MTP_CHI_PORT), ServerKeys.MTP_CHI_USERNAME, ServerKeys.MTP_CHI_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, Convert.ToInt32(ServerKeys.Thunder_NY_PORT), ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, Convert.ToInt32(ServerKeys.Thunder_CHI_PORT), ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, Convert.ToInt32(ServerKeys.WASHEDUP_NY_PORT), ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, Convert.ToInt32(ServerKeys.NEINKTP_DAL_PORT), ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            FTP_Update(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, Convert.ToInt32(ServerKeys.ICYHOT_KANGUH_DAL_PORT), ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
            Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            //FTP_Update(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, Convert.ToInt32(ServerKeys.ALLEN_SEA_PORT), ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            //numServers++;
            //Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            //FTP_Update(ServerKeys.OVER_MATA_EURO_HOSTNAME, ServerKeys.OVER_MATA_EURO_IP, Convert.ToInt32(ServerKeys.OVER_MATA_EURO_PORT), ServerKeys.OVER_MATA_EURO_USERNAME, ServerKeys.OVER_MATA_EURO_PASSWORD);
            //numServers++;
            //Console.WriteLine(DateTime.Now+" Server " + numServers + " handled so far.");
            //Console.WriteLine(DateTime.Now+" \n\nServers are handled.");
        }

        public static void FTP_Update(string HOSTNAME, string IP, int PORT, string USERNAME, string PASSWORD) {
            Console.WriteLine(DateTime.Now+" FTP Access to " + HOSTNAME);
            string errorString = "";

            using (WebClient client = new WebClient()) {
                client.Credentials = new NetworkCredential(USERNAME, PASSWORD);
                #region amx_and_wads
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/configs/amxx.cfg"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\configs\amxx.cfg"); }
                catch (WebException ex) {
                    errorString += "Error with: amxx.cfg \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/configs/plugins.ini"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\configs\plugins.ini"); }
                catch (WebException ex) {
                    errorString += "Error with: plugins.ini \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/configs/filelist.ini"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\configs\filelist.ini"); }
                catch (WebException ex) {
                    errorString += "Error with: filelist.ini \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/data/lang/ktp_cvar.txt"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\data\lang\ktp_cvar.txt"); }
                catch (WebException ex) {
                    errorString += "Error with: ktp_cvar.txt \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/data/lang/ktp_cvarcfg.txt"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\data\lang\ktp_cvarcfg.txt"); }
                catch (WebException ex) {
                    errorString += "Error with: ktp_cvarcfg.txt  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/plugins/ktp_cvar.amxx"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\plugins\ktp_cvar.amxx"); }
                catch (WebException ex) {
                    errorString += "Error with: ktp_cvar.amxx \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/plugins/ktp_cvarconfig.amxx"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\plugins\ktp_cvarconfig.amxx"); }
                catch (WebException ex) {
                    errorString += "Error with: ktp_cvarconfig.amxx  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/addons/amxmodx/plugins/filescheck.amxx"), @"N:\Nein_\KTPCvarChecker\Sync\amxmodx\plugins\filescheck.amxx"); }
                catch (WebException ex) {
                    errorString += "Error with: \filescheck.amxx  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                Console.WriteLine(DateTime.Now+" Finished writing AMX/KTP Plugins");
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/ace.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\ace.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: ace.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_railroad.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_railroad.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad.wad  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_railroad2_b2.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_railroad2_b2.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad2_b2.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_siena.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_siena.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_siena.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/jlord.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\jlord.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: jlord.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/lennonn.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\lennonn.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: lennonn.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/thunder2.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\thunder2.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: thunder2.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/cs_havana.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\cs_havana.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: cs_havana.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                //client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_anzio.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_anzio.wad");
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_advance.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_advance.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_advance.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_carta.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_carta.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_carta.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_custom.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_custom.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_custom.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_emmanuel.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_emmanuel.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_emmanuel.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/anjou.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\anjou.wad"); }
                catch (WebException ex) {
                    errorString += "Error with: anjou.wad \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                //client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_merderet.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_merderet.wad");
                //client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_narby.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_narby.wad");
                //client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_sturm.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_sturm.wad");
                //client.UploadFile(new Uri("ftp://" + IP + "/dod/dod_vicenza.wad"), @"N:\Nein_\KTPCvarChecker\Sync\dod\dod_vicenza.wad");
                Console.WriteLine(DateTime.Now+" Finished writing .wads");
                #endregion
                #region maps
                /*
                try {  client.UploadFile(" + IP + "/dod/maps/dod_anzio.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_anzio.bsp");}
                catch (WebException ex){
                    errorString += "Error with: dod_anzio.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                */
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_anzio.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_anzio.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_anzio.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                /*
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_chemille.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_chemille.bsp");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_chemille.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                */
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_chemille.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_chemille.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_chemille.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_halle.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_halle.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_halle.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_halle.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_halle.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_halle.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_harrington.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_harrington.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_harrington.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_harrington.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_harrington.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_harrington.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_lennon_test.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_lennon_test.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_lennon_test.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_lennon_test.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_lennon_test.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_lennon_test.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_railroad2_b2.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_b2.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad2_b2.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_railroad2_b2.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_b2.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad2_b2.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_railyard_b4.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railyard_b4.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railyard_b4.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_railyard_b4.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railyard_b4.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railyard_b2.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                /*
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_saints.bsp", @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_saints.bsp");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_saints.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                */
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_saints.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_saints.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_saints.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_saints_b5.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_saints_b5.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_saints_b5.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_saints_b5.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_saints_b5.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_saints_b5.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_siena_test.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_siena_test.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_siena_test.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_siena_test.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_siena_test.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_siena_test.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_solitude_b2.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_solitude_b2.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_solitude_b2.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_solitude_b2.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_solitude_b2.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_solitude_b2.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_thunder2_b4.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_thunder2_b4.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_thunder2_b4.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_thunder2_b4.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_thunder2_b4.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_thunder2_b4.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_armory_b5.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_armory_b5.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_armory_b5.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_armory_b5.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_armory_b5.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_armory_b5.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_railroad2_test.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_test.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad2_test.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_railroad2_test.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_railroad2_test.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad2_test.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_anjou_a2.bsp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_anjou_a2.bsp"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_anjou_a2.bsp \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/maps/dod_anjou_a2.res"), @"N:\Nein_\KTPCvarChecker\Sync\dod\maps\dod_anjou_a2.res"); }
                catch (WebException ex) {
                    errorString += "Error with: dod_anjou_a2.res \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                Console.WriteLine(DateTime.Now+" Finished writing maps folder");
                if (errorString != "") { if (errorString != "") { Console.WriteLine(errorString); } }
                errorString = "";
                #endregion
                #region overviews
                /*try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_anzio.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_anzio.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_anzio.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_anzio.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_anzio overview files \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_chemille.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_chemille.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_chemille.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_chemille.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_chemille overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }*/
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_halle.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_halle.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_halle.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_halle.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_halle overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_harrington.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_harrington.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_harrington.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_harrington.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_harrington overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_lennon_test.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_lennon_test.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_lennon_test.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_lennon_test.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_lennon_test overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_railroad2_b2.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_b2.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_railroad2_b2.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_b2.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad2_b2 overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                /*try {
                    //client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_railyard_b4.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railyard_b4.bmp");
                    //client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_railyard_b4.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railyard_b4.txt");
                }
                catch (WebException ex) {
                    //errorString += "Error with: dod_railyard_b4 overview files  \r\n";
                    //errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_saints.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_saints.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_saints overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }*/
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_saints_b5.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints_b5.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_saints_b5.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_saints_b5.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_saints_b5 overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_siena_test.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_siena_test.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_siena_test.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_siena_test.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_siena_test overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_solitude_b2.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_solitude_b2.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_solitude_b2.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_solitude_b2.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_solitude_b2 overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_thunder2_b4.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b4.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_thunder2_b4.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_thunder2_b4.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_thunder2_b4 overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_armory_b5.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_armory_b5.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_armory_b5.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_armory_b5.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_armory_b5 overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_railroad2_test.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_test.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_railroad2_test.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_railroad2_test.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_railroad2_test overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_anjou_a2.bmp"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_anjou_a2.bmp");
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/overviews/dod_anjou_a2.txt"), @"N:\Nein_\KTPCvarChecker\Sync\dod\overviews\dod_anjou_a2.txt");
                }
                catch (WebException ex) {
                    errorString += "Error with: dod_anjou_a2 overview files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                Console.WriteLine(DateTime.Now+" Finished writing overviews folder");
                if (errorString != "") { Console.WriteLine(errorString); }
                errorString = "";
                #endregion
                #region sounds
                /*
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try {
                    client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage5.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage5.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage5 sound  files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage6.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage6.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage6 sound   files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage7.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage7.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage7 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage8.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage8.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage8 sound  files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage9.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage9.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage9 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage10.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage10.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage10 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/damage11.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\damage11.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: damage11 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/ow.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\ow.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: ow sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/goprone.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\goprone.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: goprone sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/jump.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\jump.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: jump sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                */
                /*try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/jumplanding.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\jumplanding.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: jumplanding sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }*/
                /*
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_dirt1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_dirt1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: dirt1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_dirt2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_dirt2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: dirt2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_dirt3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_dirt3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: dirt3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_dirt4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_dirt4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: dirt4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_duct1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_duct1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: duct1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_duct2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_duct2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: duct2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_duct3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_duct3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: duct3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_duct4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_duct4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: duct4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_fallpain.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_fallpain.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: fallpain sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_gravel1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_gravel1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: gravel1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_gravel2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_gravel2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: gravel2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_gravel3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_gravel3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: gravel3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_gravel4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_gravel4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: gravel4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_ladder1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_ladder1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: ladder1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_ladder2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_ladder2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: ladder2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_ladder3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_ladder3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: ladder3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_ladder4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_ladder4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: ladder4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_metal1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_metal1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: metal1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_metal2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_metal2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: metal2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_metal3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_metal3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: metal3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_metal4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_metal4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: metal4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_shell1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_shell1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: shell1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_shell2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_shell2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: shell2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_shell3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_shell3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: shell3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_slosh1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_slosh1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: slosh1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_slosh2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_slosh2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: slosh2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_slosh3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_slosh3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: slosh3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_slosh4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_slosh4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: slosh4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_step1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_step1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: step1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_step2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_step2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: step2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_step3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_step3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: step3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_step4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_step4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: step4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_tile1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_tile1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: tile1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_tile2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_tile2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: tile2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_tile3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_tile3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: tile3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_tile4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_tile4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: tile4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_tile5.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_tile5.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: tile5 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wade1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wade1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wade1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wade2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wade2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wade2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wade3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wade3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wade3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wade4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wade4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wade4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wood1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wood1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wood1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wood2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wood2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wood2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wood3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wood3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wood3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_wood4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_wood4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: wood4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_grate1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_grate1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: grate1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_grate2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_grate2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: grate2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_grate3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_grate3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: grate3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_grate4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_grate4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: grate4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_swim1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_swim1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: swim1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_swim2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_swim2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: swim2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_swim3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_swim3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: swim3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_swim4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_swim4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: swim4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_snow1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_snow1.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: snow1 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_snow2.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_snow2.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: snow2 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_snow3.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_snow3.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: snow3 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/pl_snow4.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\pl_snow4.wav");
                }
                catch (WebException ex) {
                    errorString += "Error with: snow4 sound files  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                */
                //try { client.UploadFile(new Uri("ftp://" + IP + "/dod/sound/player/headshot1.wav", @"N:\Nein_\KTPCvarChecker\Sync\dod\sound\player\headshot1.wav");
                //}
                //catch (WebException ex) {
                //    errorString += "Error with: headshot1 sound files  \r\n";
                //    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                //}
                //Console.WriteLine(DateTime.Now+" Finished writing sounds folder");
                //if (errorString != "") { Console.WriteLine(errorString); }
                //errorString = "";
                #endregion
                #region configs and msc
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/server.cfg"), @"N:\Nein_\KTPCvarChecker\Sync\dod\server.cfg"); }
                catch (WebException ex) {
                    errorString += "Error with: server.cfg  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                try { client.UploadFile(new Uri("ftp://" + IP + "/dod/models/mapmodels/flo_rubble_a.mdl"), @"N:\Nein_\KTPCvarChecker\Sync\dod\models\mapmodels\flo_rubble_a.mdl"); }
                catch (WebException ex) {
                    errorString += "Error with: flo_rubble_a.mdl  \r\n";
                    errorString += ((FtpWebResponse)ex.Response).StatusDescription;
                }
                #endregion
            }

            Console.WriteLine(DateTime.Now+" FINISHED UPDATING " + HOSTNAME);
        }

        public static void DeleteLocalLogs() {
            string path = @"N:\Nein_\KTPCvarChecker\Logs\";

            DirectoryInfo directory = new DirectoryInfo(path);

            foreach (FileInfo file in directory.GetFiles()) {
                file.Delete();
            }

            foreach (DirectoryInfo dir in directory.GetDirectories()) {
                dir.Delete(true);
            }
            Console.WriteLine(DateTime.Now+" Deleted local old log files  \r\n");
        }

        public static void FTP_DownloadAllServers() {
            numServers = 0;
            FTP_DownloadLogs(ServerKeys.THREESIDEDQUARTER_DAL_HOSTNAME, ServerKeys.THREESIDEDQUARTER_DAL_IP, ServerKeys.THREESIDEDQUARTER_DAL_USERNAME, ServerKeys.THREESIDEDQUARTER_DAL_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.THREE_H_WARCHYLD_LA_HOSTNAME, ServerKeys.THREE_H_WARCHYLD_LA_IP, ServerKeys.THREE_H_WARCHYLD_LA_USERNAME, ServerKeys.THREE_H_WARCHYLD_LA_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.THREE_H_PIFF_ATL_HOSTNAME, ServerKeys.THREE_H_PIFF_ATL_IP, ServerKeys.THREE_H_PIFF_ATL_USERNAME, ServerKeys.THREE_H_PIFF_ATL_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.NineteenEleven_NY_2_HOSTNAME, ServerKeys.NineteenEleven_NY_2_IP, ServerKeys.NineteenEleven_NY_2_USERNAME, ServerKeys.NineteenEleven_NY_2_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.NineteenEleven_CHI_1_HOSTNAME, ServerKeys.NineteenEleven_CHI_1_IP, ServerKeys.NineteenEleven_CHI_1_USERNAME, ServerKeys.NineteenEleven_CHI_1_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.NineteenEleven_NY_1_HOSTNAME, ServerKeys.NineteenEleven_NY_1_IP, ServerKeys.NineteenEleven_NY_1_USERNAME, ServerKeys.NineteenEleven_NY_1_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.NineteenEleven_DAL_1_HOSTNAME, ServerKeys.NineteenEleven_DAL_1_IP, ServerKeys.NineteenEleven_DAL_1_USERNAME, ServerKeys.NineteenEleven_DAL_1_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.SHAKYTABLE_DAL_HOSTNAME, ServerKeys.SHAKYTABLE_DAL_IP, ServerKeys.SHAKYTABLE_DAL_USERNAME, ServerKeys.SHAKYTABLE_DAL_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.NOGO_CHI_HOSTNAME, ServerKeys.NOGO_CHI_IP, ServerKeys.NOGO_CHI_USERNAME, ServerKeys.NOGO_CHI_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.MTP_CHI_HOSTNAME, ServerKeys.MTP_CHI_IP, ServerKeys.MTP_CHI_USERNAME, ServerKeys.MTP_CHI_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.ICYHOT_KANGUH_CHI_HOSTNAME, ServerKeys.ICYHOT_KANGUH_CHI_IP, ServerKeys.ICYHOT_KANGUH_CHI_USERNAME, ServerKeys.ICYHOT_KANGUH_CHI_PASSWORD);
            numServers++;
            //FTP_DownloadLogs(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            //numServers++;
            //FTP_DownloadLogs(ServerKeys.OVER_MATA_EURO_HOSTNAME, ServerKeys.OVER_MATA_EURO_IP, ServerKeys.OVER_MATA_EURO_USERNAME, ServerKeys.OVER_MATA_EURO_PASSWORD);
            //numServers++;
        }

        public static void FTP_DownloadFileLogsAllServers() {
            numServers = 0;
            FTP_DownloadFileLog(ServerKeys.THREESIDEDQUARTER_DAL_HOSTNAME, ServerKeys.THREESIDEDQUARTER_DAL_IP, ServerKeys.THREESIDEDQUARTER_DAL_USERNAME, ServerKeys.THREESIDEDQUARTER_DAL_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.THREE_H_WARCHYLD_LA_HOSTNAME, ServerKeys.THREE_H_WARCHYLD_LA_IP, ServerKeys.THREE_H_WARCHYLD_LA_USERNAME, ServerKeys.THREE_H_WARCHYLD_LA_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.NineteenEleven_NY_2_HOSTNAME, ServerKeys.NineteenEleven_NY_2_IP, ServerKeys.NineteenEleven_NY_2_USERNAME, ServerKeys.NineteenEleven_NY_2_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.NineteenEleven_CHI_1_HOSTNAME, ServerKeys.NineteenEleven_CHI_1_IP, ServerKeys.NineteenEleven_CHI_1_USERNAME, ServerKeys.NineteenEleven_CHI_1_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.NineteenEleven_NY_1_HOSTNAME, ServerKeys.NineteenEleven_NY_1_IP, ServerKeys.NineteenEleven_NY_1_USERNAME, ServerKeys.NineteenEleven_NY_1_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.NineteenEleven_DAL_1_HOSTNAME, ServerKeys.NineteenEleven_DAL_1_IP, ServerKeys.NineteenEleven_DAL_1_USERNAME, ServerKeys.NineteenEleven_DAL_1_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.SHAKYTABLE_DAL_HOSTNAME, ServerKeys.SHAKYTABLE_DAL_IP, ServerKeys.SHAKYTABLE_DAL_USERNAME, ServerKeys.SHAKYTABLE_DAL_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.NOGO_CHI_HOSTNAME, ServerKeys.NOGO_CHI_IP, ServerKeys.NOGO_CHI_USERNAME, ServerKeys.NOGO_CHI_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.MTP_CHI_HOSTNAME, ServerKeys.MTP_CHI_IP, ServerKeys.MTP_CHI_USERNAME, ServerKeys.MTP_CHI_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.ICYHOT_KANGUH_CHI_HOSTNAME, ServerKeys.ICYHOT_KANGUH_CHI_IP, ServerKeys.ICYHOT_KANGUH_CHI_USERNAME, ServerKeys.ICYHOT_KANGUH_CHI_PASSWORD);
            numServers++;
            FTP_DownloadFileLog(ServerKeys.THREE_H_PIFF_ATL_HOSTNAME, ServerKeys.THREE_H_PIFF_ATL_IP, ServerKeys.THREE_H_PIFF_ATL_USERNAME, ServerKeys.THREE_H_PIFF_ATL_PASSWORD);
            numServers++;
            //FTP_DownloadFileLog(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            //numServers++;
            //FTP_DownloadFileLog(ServerKeys.OVER_MATA_EURO_HOSTNAME, ServerKeys.OVER_MATA_EURO_IP, ServerKeys.OVER_MATA_EURO_USERNAME, ServerKeys.OVER_MATA_EURO_PASSWORD);
            //numServers++;
        }

        public static void FTP_DownloadLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine(DateTime.Now+" FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            // download a folder and all its files
            //client.DownloadDirectory(@"..\..\..\Logs\"+HOSTNAME, @"/dod/addons/amxmodx/logs", FtpFolderSyncMode.Update);
            List<string> paths = new List<string>();
            foreach (FtpListItem element in client.GetListing(@"/dod/addons/amxmodx/logs/*.log")) {
                paths.Add(element.FullName);
                Console.WriteLine(element.FullName);
            }
            var newHOSTNAME = HOSTNAME.Split(":")[0];
            System.IO.Directory.CreateDirectory(@"N:\Nein_\KTPCvarChecker\Logs\" + newHOSTNAME);
            client.DownloadFiles(@"N:\Nein_\KTPCvarChecker\Logs\" + newHOSTNAME, paths);
        }

        public static void FTP_DownloadFileLog(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine(DateTime.Now+" FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            client.DownloadFile(@"N:\Nein_\KTPCvarChecker\Logs\" + HOSTNAME + "_filecheck.log", "/dod/addons/amxmodx/logs/filecheck.log");
        }

        public static void ProcessDirectory(string targetDirectory) {
            // Process the list of files found in the directory.
            string[] fileEntries = Directory.GetFiles(targetDirectory);
            foreach (string fileName in fileEntries)
                LogFiles.Add(ProcessFile(fileName));

            // Recurse into subdirectories of this directory.
            string[] subdirectoryEntries = Directory.GetDirectories(targetDirectory);
            foreach (string subdirectory in subdirectoryEntries)
                ProcessDirectory(subdirectory);
        }

        public static string ProcessFile(string path) {
            return File.ReadAllText(path);
        }

        public static void ProcessLogs() {
            Console.WriteLine(DateTime.Now+" Processing Logs.");
            LogFiles = LogFiles.Select(s => s.Replace("L  - ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<0.000000>", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" [ktp_cvar.amxx] ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("--------", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" Mapchange to ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" [DODX] Could not load stats file: ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(@"dod\addons\amxmodx\data\dodstats.dat", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_anzio", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_harrington", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_lennon_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_lennon_test", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_chemille", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_thunder2_b1c", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_thunder2_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_thunder2_b3", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_thunder2_b4", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_armory_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_armory_b3", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_armory_b4", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_armory_b5", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_armory_testmap", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railroad2_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railroad2_test", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_solitude_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_lennon2_b1", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_halle", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_saints", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_saints_b5", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_donner", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railroad", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_aleutian", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_avalanche", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_emmanuel", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_kalt", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_lennon_b3", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_merderet", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_northbound", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_muhle_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_lindbergh_b1", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_cal_sherman2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_forest", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_glider", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_jagd", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_kraftstoff", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_merderet", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_vicenza", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_zalec", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_zafod", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_caen", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_charlie", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_flash", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_orange", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_pandemic_aim", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_tensions", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("DoD_Solitude_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railyard_test", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railyard_b1", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railyard_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railyard_b3", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railyard_b4", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railroad2_test", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_rails_ktp1", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<<< Drudge >>>", "Drudge")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<<< Drudge >>", "Drudge")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("SLeePeRS <> ", "SLeePeRS <>")).ToList();



            string sssssssss = "";
            foreach (string s in LogFiles) {
                sssssssss += s;
            }


            Console.WriteLine(DateTime.Now+" Finished generic line replacement.");
            string pattern = "";
            foreach (string s in LogFiles) {
                pattern = @"\d+:\d+:\d+:\d*";
                LogFilesNew.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine(DateTime.Now+" Finished REGEX 00:00:00:00 replacement.");
            foreach (string s in LogFilesNew) {
                pattern = @"\d+/\d+/\d+";
                LogFilesNew2.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine(DateTime.Now+" Finished REGEX 00/00/00 replacement.");
            LogFilesNew2 = LogFilesNew2.Select(s => s.Replace("L  -", "")).ToHashSet();
            LogFilesNew2 = LogFilesNew2.Select(s => s.Replace("L -", "")).ToHashSet();
            LogFilesNew2 = LogFilesNew2.Select(s => s.Replace("[AMXX] ", "")).ToHashSet();
            LogFilesNew2 = LogFilesNew2.Select(s => s.Replace("> ip:", " ip:")).ToHashSet();
            int count = 0;
            for (int i = 0; i < LogFilesNew2.Count; i++) {
                string str = LogFilesNew2.ToList()[i];
                string[] s = str.Split("\r\n");
                for (int j = 0; j < s.Length; j++) {
                    if (s[j].Contains("KTP value") && !s[j].Contains("hud_takesshots")) {
                        if (ignoreRates) {
                            if (!s[j].Contains("rate") && !s[j].Contains("interp")) {
                                string[] ss = s[j].Split("> ");
                                HashSet<string> TempHash = new HashSet<string>();
                                if (!SteamIDDictionary.ContainsKey(ss[0])) {
                                    TempHash.Add(ss[1]);
                                    SteamIDDictionary.Add(ss[0], TempHash);
                                }
                                else {
                                    TempHash = SteamIDDictionary[ss[0]];
                                    if (ss[1].Contains("KTP value")) {
                                        TempHash.Add(ss[1]);
                                    }
                                    SteamIDDictionary[ss[0]] = TempHash;
                                }
                                if (!NumViolations.ContainsKey(ss[1])) {
                                    NumViolations.Add(ss[1], 1);
                                }
                                else {
                                    int temp = NumViolations[ss[1]];
                                    NumViolations[ss[1]] = ++temp;
                                }
                                LogLines.Add(s[j]);
                                Console.Write("\rLogline " + count + "added.");
                                count++;
                            }
                        }
                        else {
                            string[] ss = s[j].Split("> ");
                            HashSet<string> TempHash = new HashSet<string>();
                            if (!SteamIDDictionary.ContainsKey(ss[0])) {
                                TempHash.Add(ss[1]);
                                SteamIDDictionary.Add(ss[0], TempHash);
                            }
                            else {
                                TempHash = SteamIDDictionary[ss[0]];
                                if (ss[1].Contains("KTP value")) {
                                    TempHash.Add(ss[1]);
                                }
                                SteamIDDictionary[ss[0]] = TempHash;
                            }
                            if (!NumViolations.ContainsKey(ss[1])) {
                                NumViolations.Add(ss[1], 1);
                            }
                            else {
                                int temp = NumViolations[ss[1]];
                                NumViolations[ss[1]] = ++temp;
                            }
                            LogLines.Add(s[j]);
                            Console.Write("\rLogline " + count + "added.");
                            count++;
                        }
                    }
                }
                Console.WriteLine(DateTime.Now+" Finished parsing string " + i + " out of " + LogFilesNew2.Count);
            }
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"N:\Nein_\KTPCvarChecker\FULL_CVAR_LOG_" + DateTime.Now.ToString("yyyy_MM_dd_HHmm") + ".txt", true)) {
                file.WriteLine(Version);
                file.WriteLine("Compiled on " + DateTime.Now.ToString("yyyy_MM_dd_HH:mm") + " from " + LogFiles.Count + " logfile lines across " + numServers + " servers. Grouped by STEAMID. \r\n");
                /*foreach (string s in LogLines) {
                    file.WriteLine(s);
                }
                file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                file.WriteLine("By STEAMID Attempt. \r\n");
                */
                for (int i = 0; i < SteamIDDictionary.Count; i++) {
                    file.WriteLine(SteamIDDictionary.Keys.ElementAt(i) + ">");
                    string ALIASES = "ALIASES: ";
                    string ADDRESSES = "IP ADDRESSES: ";
                    for (int j = 0; j < SteamIDDictionary.Values.ElementAt(i).Count; j++) {
                        string str = SteamIDDictionary.Values.ElementAt(i).ToList()[j].ToString();
                        string[] ss = str.Split(" ip:");
                        if (!ALIASES.Contains(ss[0])) {
                            ALIASES += ss[0] + "; ";
                        }
                    }
                    file.WriteLine("\t" + ALIASES);
                    for (int j = 0; j < SteamIDDictionary.Values.ElementAt(i).Count; j++) {
                        string str = SteamIDDictionary.Values.ElementAt(i).ToList()[j].ToString();
                        string[] ss = str.Split(" changed ");
                        string[] sss = ss[0].Split("ip:");
                        if (!ADDRESSES.Contains(sss[1])) {
                            ADDRESSES += sss[1] + ";  ";
                        }
                    }
                    file.WriteLine("\t" + ADDRESSES);
                    int num = 0;
                    string violationsStr = "\r\n\t\t";
                    for (int j = 0; j < SteamIDDictionary.Values.ElementAt(i).Count; j++) {
                        string str = SteamIDDictionary.Values.ElementAt(i).ToList()[j].ToString();
                        num += NumViolations[str];
                        string[] ss = str.Split(" changed ");
                        if (!violationsStr.Contains(ss[1])) {
                            violationsStr += ss[1] + "\r\n\t\t";
                        }
                        //file.WriteLine("\t" + ss[1] + "# of Violations: " + num);
                    }
                    file.WriteLine("\t# of Violations: " + num);
                    file.WriteLine("\t--CVAR VIOLATIONS--" + violationsStr);
                    file.WriteLine("");
                }
            }
        }

        public static void FTP_DeleteLogsAllServers() {
            int numServers = 0;
            FTP_DeleteLogs(ServerKeys.THREESIDEDQUARTER_DAL_HOSTNAME, ServerKeys.THREESIDEDQUARTER_DAL_IP, ServerKeys.THREESIDEDQUARTER_DAL_USERNAME, ServerKeys.THREESIDEDQUARTER_DAL_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.THREE_H_WARCHYLD_LA_HOSTNAME, ServerKeys.THREE_H_WARCHYLD_LA_IP, ServerKeys.THREE_H_WARCHYLD_LA_USERNAME, ServerKeys.THREE_H_WARCHYLD_LA_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.NineteenEleven_NY_2_HOSTNAME, ServerKeys.NineteenEleven_NY_2_IP, ServerKeys.NineteenEleven_NY_2_USERNAME, ServerKeys.NineteenEleven_NY_2_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.NineteenEleven_CHI_1_HOSTNAME, ServerKeys.NineteenEleven_CHI_1_IP, ServerKeys.NineteenEleven_CHI_1_USERNAME, ServerKeys.NineteenEleven_CHI_1_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.NineteenEleven_NY_1_HOSTNAME, ServerKeys.NineteenEleven_NY_1_IP, ServerKeys.NineteenEleven_NY_1_USERNAME, ServerKeys.NineteenEleven_NY_1_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.NineteenEleven_DAL_1_HOSTNAME, ServerKeys.NineteenEleven_DAL_1_IP, ServerKeys.NineteenEleven_DAL_1_USERNAME, ServerKeys.NineteenEleven_DAL_1_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.SHAKYTABLE_DAL_HOSTNAME, ServerKeys.SHAKYTABLE_DAL_IP, ServerKeys.SHAKYTABLE_DAL_USERNAME, ServerKeys.SHAKYTABLE_DAL_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.NOGO_CHI_HOSTNAME, ServerKeys.NOGO_CHI_IP, ServerKeys.NOGO_CHI_USERNAME, ServerKeys.NOGO_CHI_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.MTP_CHI_HOSTNAME, ServerKeys.MTP_CHI_IP, ServerKeys.MTP_CHI_USERNAME, ServerKeys.MTP_CHI_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.ICYHOT_KANGUH_CHI_HOSTNAME, ServerKeys.ICYHOT_KANGUH_CHI_IP, ServerKeys.ICYHOT_KANGUH_CHI_USERNAME, ServerKeys.ICYHOT_KANGUH_CHI_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.THREE_H_PIFF_ATL_HOSTNAME, ServerKeys.THREE_H_PIFF_ATL_IP, ServerKeys.THREE_H_PIFF_ATL_USERNAME, ServerKeys.THREE_H_PIFF_ATL_PASSWORD);
            numServers++;
            //FTP_DeleteLogs(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            //numServers++;
            //FTP_DeleteLogs(ServerKeys.OVER_MATA_EURO_HOSTNAME, ServerKeys.OVER_MATA_EURO_IP, ServerKeys.OVER_MATA_EURO_USERNAME, ServerKeys.OVER_MATA_EURO_PASSWORD);
            //numServers++;
        }

        public static void FTP_DeleteFileLogsAllServers() {
            int numServers = 0;
            FTP_DeleteFileLogs(ServerKeys.THREESIDEDQUARTER_DAL_HOSTNAME, ServerKeys.THREESIDEDQUARTER_DAL_IP, ServerKeys.THREESIDEDQUARTER_DAL_USERNAME, ServerKeys.THREESIDEDQUARTER_DAL_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.THREE_H_WARCHYLD_LA_HOSTNAME, ServerKeys.THREE_H_WARCHYLD_LA_IP, ServerKeys.THREE_H_WARCHYLD_LA_USERNAME, ServerKeys.THREE_H_WARCHYLD_LA_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.NineteenEleven_NY_2_HOSTNAME, ServerKeys.NineteenEleven_NY_2_IP, ServerKeys.NineteenEleven_NY_2_USERNAME, ServerKeys.NineteenEleven_NY_2_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.NineteenEleven_CHI_1_HOSTNAME, ServerKeys.NineteenEleven_CHI_1_IP, ServerKeys.NineteenEleven_CHI_1_USERNAME, ServerKeys.NineteenEleven_CHI_1_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.NineteenEleven_NY_1_HOSTNAME, ServerKeys.NineteenEleven_NY_1_IP, ServerKeys.NineteenEleven_NY_1_USERNAME, ServerKeys.NineteenEleven_NY_1_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.NineteenEleven_DAL_1_HOSTNAME, ServerKeys.NineteenEleven_DAL_1_IP, ServerKeys.NineteenEleven_DAL_1_USERNAME, ServerKeys.NineteenEleven_DAL_1_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.SHAKYTABLE_DAL_HOSTNAME, ServerKeys.SHAKYTABLE_DAL_IP, ServerKeys.SHAKYTABLE_DAL_USERNAME, ServerKeys.SHAKYTABLE_DAL_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.NOGO_CHI_HOSTNAME, ServerKeys.NOGO_CHI_IP, ServerKeys.NOGO_CHI_USERNAME, ServerKeys.NOGO_CHI_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.MTP_CHI_HOSTNAME, ServerKeys.MTP_CHI_IP, ServerKeys.MTP_CHI_USERNAME, ServerKeys.MTP_CHI_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.ICYHOT_KANGUH_CHI_HOSTNAME, ServerKeys.ICYHOT_KANGUH_CHI_IP, ServerKeys.ICYHOT_KANGUH_CHI_USERNAME, ServerKeys.ICYHOT_KANGUH_CHI_PASSWORD);
            numServers++;
            FTP_DeleteFileLogs(ServerKeys.THREE_H_PIFF_ATL_HOSTNAME, ServerKeys.THREE_H_PIFF_ATL_IP, ServerKeys.THREE_H_PIFF_ATL_USERNAME, ServerKeys.THREE_H_PIFF_ATL_PASSWORD);
            numServers++;
            //FTP_DeleteFileLogs(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            //numServers++;
            //FTP_DeleteFileLogs(ServerKeys.OVER_MATA_EURO_HOSTNAME, ServerKeys.OVER_MATA_EURO_IP, ServerKeys.OVER_MATA_EURO_USERNAME, ServerKeys.OVER_MATA_EURO_PASSWORD);
            //numServers++;
        }

        public static void FTP_DeleteLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine(DateTime.Now+" FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            // download a folder and all its files
            //client.DownloadDirectory(@"..\..\..\Logs\"+HOSTNAME, @"/dod/addons/amxmodx/logs", FtpFolderSyncMode.Update);
            List<string> paths = new List<string>();
            foreach (FtpListItem element in client.GetListing(@"/dod/addons/amxmodx/logs/*.log")) {
                paths.Add(element.FullName);
                Console.WriteLine(element.FullName);
            }
            foreach (string s in paths) {
                Console.WriteLine(DateTime.Now+" Deleting: " + s);
                client.DeleteFile(@"" + s);
            }
        }

        public static void FTP_DeleteFileLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine(DateTime.Now+" FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            // download a folder and all its files
            //client.DownloadDirectory(@"..\..\..\Logs\"+HOSTNAME, @"/dod/addons/amxmodx/logs", FtpFolderSyncMode.Update);
            List<string> paths = new List<string>();
            foreach (FtpListItem element in client.GetListing(@"/dod/addons/amxmodx/logs/*file*.log")) {
                paths.Add(element.FullName);
                Console.WriteLine(element.FullName);
            }
            foreach (string s in paths) {
                Console.WriteLine(DateTime.Now+" Deleting: " + s);
                client.DeleteFile(@"" + s);
            }
        }

        public static void FTP_DownloadDoDLogsAllServers() {
            int numServers = 0;
            FTP_DownloadDODLogs(ServerKeys.NineteenEleven_NY_2_HOSTNAME, ServerKeys.NineteenEleven_NY_2_IP, ServerKeys.NineteenEleven_NY_2_USERNAME, ServerKeys.NineteenEleven_NY_2_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.NineteenEleven_CHI_1_HOSTNAME, ServerKeys.NineteenEleven_CHI_1_IP, ServerKeys.NineteenEleven_CHI_1_USERNAME, ServerKeys.NineteenEleven_CHI_1_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.NineteenEleven_NY_1_HOSTNAME, ServerKeys.NineteenEleven_NY_1_IP, ServerKeys.NineteenEleven_NY_1_USERNAME, ServerKeys.NineteenEleven_NY_1_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.NineteenEleven_DAL_1_HOSTNAME, ServerKeys.NineteenEleven_DAL_1_IP, ServerKeys.NineteenEleven_DAL_1_USERNAME, ServerKeys.NineteenEleven_DAL_1_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.SHAKYTABLE_DAL_HOSTNAME, ServerKeys.SHAKYTABLE_DAL_IP, ServerKeys.SHAKYTABLE_DAL_USERNAME, ServerKeys.SHAKYTABLE_DAL_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.NOGO_CHI_HOSTNAME, ServerKeys.NOGO_CHI_IP, ServerKeys.NOGO_CHI_USERNAME, ServerKeys.NOGO_CHI_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.MTP_CHI_HOSTNAME, ServerKeys.MTP_CHI_IP, ServerKeys.MTP_CHI_USERNAME, ServerKeys.MTP_CHI_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.ICYHOT_KANGUH_CHI_HOSTNAME, ServerKeys.ICYHOT_KANGUH_CHI_IP, ServerKeys.ICYHOT_KANGUH_CHI_USERNAME, ServerKeys.ICYHOT_KANGUH_CHI_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.THREE_H_PIFF_ATL_HOSTNAME, ServerKeys.THREE_H_PIFF_ATL_IP, ServerKeys.THREE_H_PIFF_ATL_USERNAME, ServerKeys.THREE_H_PIFF_ATL_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.THREE_H_WARCHYLD_LA_HOSTNAME, ServerKeys.THREE_H_WARCHYLD_LA_IP, ServerKeys.THREE_H_WARCHYLD_LA_USERNAME, ServerKeys.THREE_H_WARCHYLD_LA_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.THREESIDEDQUARTER_DAL_HOSTNAME, ServerKeys.THREESIDEDQUARTER_DAL_IP, ServerKeys.THREESIDEDQUARTER_DAL_USERNAME, ServerKeys.THREESIDEDQUARTER_DAL_PASSWORD);
            numServers++;
            //FTP_DownloadDODLogs(ServerKeys.OVER_MATA_EURO_HOSTNAME, ServerKeys.OVER_MATA_EURO_IP, ServerKeys.OVER_MATA_EURO_USERNAME, ServerKeys.OVER_MATA_EURO_PASSWORD);
            //numServers++;
            //FTP_DownloadDODLogs(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            //numServers++;
        }

        public static void FTP_DownloadDODLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine(DateTime.Now+" FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            // download a folder and all its files
            List<string> paths = new List<string>();
            foreach (FtpListItem element in client.GetListing(@"/dod/logs/*.log")) {
                if (element.Size > 6493) {
                    paths.Add(element.FullName);
                    Console.WriteLine(element.FullName);
                }
            }
            var newHOSTNAME = HOSTNAME.Split(":")[0];
            System.IO.Directory.CreateDirectory(@"N:\Nein_\KTPCvarChecker\Logs\" + newHOSTNAME);
            client.DownloadFiles(@"N:\Nein_\KTPCvarChecker\DoDLogs\" + newHOSTNAME, paths);
            ProcessDirectory(@"N:\Nein_\KTPCvarChecker\DoDLogs\");
        }

        public static void ProcessDoDLogs() {
            Console.WriteLine(DateTime.Now+" Processing Logs.");
            string pattern = "";
            foreach (string s in LogFiles) {
                pattern = @"\d+/\d+/\d+";
                LogFilesNew.Add(Regex.Replace(s, pattern, ""));
            }
            LogFiles.Clear();
            LogFiles = LogFilesNew.ToList();
            Console.WriteLine(DateTime.Now+" Finished REGEX 00/00/00 replacement.");

            LogFiles = LogFiles.Select(s => s.Replace("L ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("- ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" -", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" - ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("-", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("48/1.1.2.6/8308", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("\"", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("\\", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("/", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("Log file started (file", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" (game ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" (version ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<>", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<Axis>", " ")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<Allies>", " ")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<HLTV>", "HLTVHLTVHLTVHLTVHLTV")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(">", "")).ToList();

            Console.WriteLine(DateTime.Now+" Finished generic line replacement.");
            foreach (string s in LogFiles) {
                pattern = @"\d+:\d+:\d+:\d*";
                LogFilesNew2.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine(DateTime.Now+" Finished REGEX 00:00:00:00 replacement.");
            LogFilesNew.Clear();
            foreach (string s in LogFilesNew2) {
                pattern = @"<\d+>";
                LogFilesNew.Add(Regex.Replace(s, pattern, ""));
            }
            
            //LogFilesNew2 = LogFilesNew2.Select(s => s.Replace(" -  ", "")).ToHashSet();
            int count = 0;
            for (int i = 0; i < LogFilesNew.Count; i++) {
                bool rconParsed = false;
                string str = LogFilesNew.ToList()[i];
                string[] s = str.Split("\r\n");
                for (int j = 0; j < s.Length; j++) {
                    if (!s[j].Contains("HLTVHLTVHLTVHLTVHLTV") &&
                        !s[j].Contains("STEAM USERID validated") &&
                        !s[j].Contains("entered the game") &&
                        !s[j].Contains("[META] ini") &&
                        !s[j].Contains("disconnected") &&
                        !s[j].Contains("Log file closed") &&
                        !s[j].Contains(".log") &&
                        !s[j].Contains("joined team") &&
                        !s[j].Contains("changed role") &&
                        !s[j].Contains("Server cvar") &&
                        !s[j].Contains("Match Config Executed") &&
                        !s[j].Contains("RECORD DEMOS, TURN ON MOSS, START CAPTURE WITH MOSS!!!! MOSS!!!")&&
                        !s[j].Contains("[META] dll:") &&
                        !s[j].Contains("Version") &&
                        !s[j].Contains("Final Scores:") &&
                        !s[j].Contains("KTP_RCON KICKING HLTV")) {
                        string[] ss;
                        if (s[j].Contains("Rcon:") && s[j].Contains("from")) {
                            ss = s[j].Split("from");
                            string command = ss[0];
                            string ip = ss[1];
                            ip = ip.Trim();
                            if (!ip.Contains("address")) {
                                ip = "address " + ip.Trim();
                            }
                            string steamID;
                            if (IPDictionary.ContainsKey(ip)) {
                                steamID = IPDictionary[ip];
                                if (steamID == "") {
                                    HashSet<string> LookupHash = new HashSet<string>();
                                    LookupHash.Add(ip);
                                    if (SteamIDDictionary.ContainsValue(LookupHash)) {
                                        int index = SteamIDDictionary.Values.ToList().IndexOf(LookupHash);
                                        steamID = SteamIDDictionary.Keys.ToList()[index];
                                    }
                                }
                                if(!steamID.Contains("Rcon") && !steamID.Contains("rcon") && steamID != "") {
                                    HashSet<string> TempHash = new HashSet<string>();
                                    if (!SteamIDDictionary.ContainsKey(steamID)) {
                                        TempHash.Add(command);
                                        SteamIDDictionary.Add(steamID, TempHash);
                                    }
                                    else {
                                        TempHash = SteamIDDictionary[steamID];
                                        TempHash.Add(command);
                                        SteamIDDictionary[steamID] = TempHash;
                                    }
                                }
                                else {
                                    HashSet<string> TempHash = new HashSet<string>();
                                    if (!RconCommands.ContainsKey(ip)) {
                                        TempHash.Add(command);
                                        RconCommands.Add(ip, TempHash);
                                    }
                                    else {
                                        TempHash = RconCommands[ip];
                                        TempHash.Add(command);
                                        SteamIDDictionary[ip] = TempHash;
                                    }
                                }

                            }
                            else {
                                try {
                                    IPDictionary.Add(ip, "");
                                }
                                catch {
                                    string weShouldNotGetHere = "failure";
                                }
                                
                            }
                            rconParsed = true;
                        }
                        else if (s[j].Contains("connected, ")) {
                            ss = s[j].Split("connected, ");
                            string[] aliasName = ss[0].Split("STEAM_");
                            string alias = "name: " + aliasName[0].ToString();
                            string steamID = aliasName[1].ToString();
                            string address = ss[1];
                            HashSet<string> TempHash = new HashSet<string>();
                            if (!SteamIDDictionary.ContainsKey(steamID)) {
                                TempHash.Add(alias);
                                TempHash.Add(address);
                                SteamIDDictionary.Add(steamID, TempHash);
                            }
                            else {
                                TempHash = SteamIDDictionary[steamID];
                                TempHash.Add(alias);
                                TempHash.Add(address);
                                SteamIDDictionary[steamID] = TempHash;
                            }
                            if (!IPDictionary.ContainsKey(address) && address.Contains(".") && address.Contains(":")) {
                                IPDictionary.Add(address, steamID);
                            }
                            if (IPDictionary.ContainsKey(address)) {
                                if (IPDictionary[address] == ""){
                                    IPDictionary[address] = steamID;
                                   }
                            }
                        }
                        else if (s[j].Contains("say_team")) {
                            ss = s[j].Split("say_team");
                            string[] aliasName = ss[0].Split("STEAM_");
                            string alias = "name: " + aliasName[0].ToString();
                            string steamID = aliasName[1].ToString();
                            string address = ss[1];
                            HashSet<string> TempHash = new HashSet<string>();
                            if (!SteamIDDictionary.ContainsKey(steamID)) {
                                TempHash.Add(alias);
                                TempHash.Add(address);
                                SteamIDDictionary.Add(steamID, TempHash);
                            }
                            else {
                                TempHash = SteamIDDictionary[steamID];
                                TempHash.Add(alias);
                                TempHash.Add(address);
                                SteamIDDictionary[steamID] = TempHash;
                            }
                            if (!IPDictionary.ContainsKey(address) && address.Contains(".") && address.Contains(":")) {
                                IPDictionary.Add(address, steamID);
                            }
                            if (IPDictionary.ContainsKey(address)) {
                                if (IPDictionary[address] == "") {
                                    IPDictionary[address] = steamID;
                                }
                            }
                        }
                        else if (s[j].Contains("say \"") && !s[j].Contains("Rcon:") && !rconParsed) {
                            ss = s[j].Split("say \"");
                            string[] aliasName = ss[0].Split("STEAM_");
                            string alias = "name: " + aliasName[0].ToString();
                            string steamID = aliasName[1].ToString();
                            string address = ss[1];
                            HashSet<string> TempHash = new HashSet<string>();
                            if (!SteamIDDictionary.ContainsKey(steamID)) {
                                TempHash.Add(alias);
                                TempHash.Add(address);
                                SteamIDDictionary.Add(steamID, TempHash);
                            }
                            else {
                                TempHash = SteamIDDictionary[steamID];
                                TempHash.Add(alias);
                                TempHash.Add(address);
                                SteamIDDictionary[steamID] = TempHash;
                            }
                            if (!IPDictionary.ContainsKey(address) && address.Contains(".") && address.Contains(":")) {
                                IPDictionary.Add(address, steamID);
                            }
                            if (IPDictionary.ContainsKey(address)) {
                                if (IPDictionary[address] == "") {
                                    IPDictionary[address] = steamID;
                                }
                            }
                        }
                    }
                    else {
                        LogLines.Add(s[j]);
                        Console.Write("\rLogline " + count + "added.");
                        count++;
                    }
                }
            }
            for (int i = 0; i < RconCommands.Count; i++) {
                string ip = RconCommands.Keys.ElementAt(i);
                string steamID = "";
                for (int j = 0; j < RconCommands.Values.ElementAt(i).Count; j++){
                    HashSet<string> LookupHash = new HashSet<string>();
                    LookupHash.Add(ip);
                    if (SteamIDDictionary.ContainsValue(LookupHash)) {
                        int index = SteamIDDictionary.Values.ToList().IndexOf(LookupHash);
                        steamID = SteamIDDictionary.Keys.ToList()[index];
                        HashSet<string> Hash1 = new HashSet<string>();
                        HashSet<string> Hash2 = new HashSet<string>();
                        Hash1 = SteamIDDictionary[steamID];
                        Hash2 = RconCommands.Values.ElementAt(j);
                        foreach(var item in Hash2) {
                            Hash1.Add(item);
                        }
                        SteamIDDictionary[steamID] = Hash1;
                    }
                }
            }
            SteamIDDictionary.ToList();
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"N:\Nein_\KTPCvarChecker\FULL_DOD_LOG_" + DateTime.Now.ToString("yyyy_MM_dd_HHmm") + ".txt", true)) {
                file.WriteLine(Version);
                file.WriteLine("Compiled on " + DateTime.Now.ToString("yyyy_MM_dd_HH:mm") + " from " + LogFiles.Count + " logfile lines across 15 servers.\r\n");

                file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                file.WriteLine("----------------------------------------------------------------------------------------\r\n");

                for (int i = 0; i < SteamIDDictionary.Count; i++) {
                    file.WriteLine(SteamIDDictionary.Keys.ElementAt(i) + ">");
                    string ALIASES = "ALIASES: ";
                    string ADDRESSES = "IP ADDRESSES: ";
                    string LOGS = "LOGS: ";
                    for (int j = 0; j < SteamIDDictionary.Values.ElementAt(i).Count; j++) {
                        string str = SteamIDDictionary.Values.ElementAt(i).ToList()[j].ToString();
                        if (str.Contains("name: ")) {
                            string[] s = str.Split("name: ");
                            ALIASES += s[1] + ";";
                        }
                        else if (str.Contains("address ")) {
                            string[] s = str.Split("address");
                            ADDRESSES += s[1] + ";";
                        }
                        else {
                            LOGS += str;
                        }
                    }
                    file.WriteLine("\t" + ALIASES);
                    file.WriteLine("\t" + ADDRESSES);
                    file.WriteLine("\t" + LOGS);
                    file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                    file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                    file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                    file.WriteLine("NOT YET PARSED\r\n");
                }
                    foreach (string s in LogLines) {
                    file.WriteLine(s);
                }
            }
        }

        public static void ProcessFileLogs() {
            Console.WriteLine(DateTime.Now+" Processing Logs.");
            LogFiles = LogFiles.Select(s => s.Replace("L ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("- ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" -", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" - ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(">", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("\\", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("\"", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("--------", "")).ToList();

            string pattern = "";
            foreach (string s in LogFiles) {
                pattern = @"\d+:\d+:\d+:\d*";
                LogFilesNew.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine(DateTime.Now+" Finished REGEX 00:00:00:00 replacement.");
            foreach (string s in LogFilesNew) {
                pattern = @"\d+/\d+/\d+";
                LogFilesNew2.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine(DateTime.Now+" Finished REGEX 00/00/00 replacement.");
            for (int i = 0; i < LogFilesNew2.Count; i++) {
                string str = LogFilesNew2.ToList()[i];
                string[] s = str.Split("\r\n");
                for (int j = 0; j < s.Length; j++) {
                    if (s[j].Contains("inconsistent file")) {
                            string[] ss = s[j].Split("has inconsistent file");
                            string[] sss = ss[0].Split("STEAM_");
                            HashSet<string> TempHash = new HashSet<string>();
                            if (!SteamIDDictionary.ContainsKey(sss[1])) {
                                TempHash.Add(ss[1]);
                                TempHash.Add(sss[0]);
                                SteamIDDictionary.Add(sss[1], TempHash);
                            }
                            else {
                                TempHash = SteamIDDictionary[sss[1]];
                                if (ss[1].Contains("inconsistent file")) {
                                    TempHash.Add(ss[1]);
                                    TempHash.Add(sss[0]);
                                }
                                SteamIDDictionary[sss[1]] = TempHash;
                            }
                            LogLines.Add(s[j]);
                        }
                    }
                }
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"N:\Nein_\KTPCvarChecker\FILE_CHECKER_LOG_" + DateTime.Now.ToString("yyyy_MM_dd_HHmm") + ".txt", true)) {
                file.WriteLine(Version);
                file.WriteLine("Compiled on " + DateTime.Now.ToString("yyyy_MM_dd_HH:mm") + " from " + LogFiles.Count + " logfile lines across " + numServers + " servers. Grouped by STEAMID. \r\n");
                /*foreach (string s in LogLines) {
                    file.WriteLine(s);
                }
                file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                file.WriteLine("----------------------------------------------------------------------------------------\r\n");
                file.WriteLine("By STEAMID Attempt. \r\n");
                */
                for (int i = 0; i < SteamIDDictionary.Count; i++) {
                    file.WriteLine(SteamIDDictionary.Keys.ElementAt(i));
                    string ALIASES = "ALIASES: ";
                    for (int j = 0; j < SteamIDDictionary.Values.ElementAt(i).Count; j++) {
                        string str = SteamIDDictionary.Values.ElementAt(i).ToList()[j].ToString();
                        if (!str.Contains(".mdl") && !str.Contains(".wav")){
                            ALIASES += str.Trim() + "; ";
                        }
                    }
                    file.WriteLine(ALIASES);
                    for (int j = 0; j < SteamIDDictionary.Values.ElementAt(i).Count; j++) {
                        string str = SteamIDDictionary.Values.ElementAt(i).ToList()[j].ToString();
                        if (str.Contains(".mdl") || str.Contains(".wav")) {
                            file.WriteLine(str.Trim() + "\r\n");
                        }
                    }
                    file.WriteLine("");
                }
            }
        }
    }
}
