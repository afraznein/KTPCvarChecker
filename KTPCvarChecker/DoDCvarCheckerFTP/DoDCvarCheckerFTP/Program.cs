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
        public static Dictionary<string, int> NumViolations = new Dictionary<string, int>();
        public static int numServers = 0;
        public static bool ignoreRates = false;
        public static string Version = "KTP Cvar Checker FTPLOG. Version 01.21.23 Nein_";
        static void Main(string[] args) {

            // ..\..\..\ for debug
            // ..\..\..\..\ for publish
            while (true){
                Console.WriteLine(Version);
                Console.WriteLine("1. Get status of all of the files, last modified date.");
                Console.WriteLine("2. FTP Update for CVAR Checker");
                Console.WriteLine("3. Pull CVAR logs");
                Console.WriteLine("4. Pull CVAR logs (ignore rates)");
                Console.WriteLine("5. Delete server CVAR logs");
                Console.WriteLine("6. Pull dod logs");
                string val = Console.ReadLine();
                int input = Convert.ToInt32(val);
                if (input == 1) {
                    //Get the status of the local files
                    Local_GetAllLocalFiles();
                }
                if (input == 2) {
                    //Push FTP update for all 10 servers
                    //FTP_AllServers();
                }
                if (input == 3) {
                    //Pull logs and create .txt file
                    DeleteLocalLogs();
                    FTP_DownloadAllServers();
                    ProcessDirectory(@"..\..\..\Logs\");
                    ProcessLogs();
                }
                if (input == 4) {
                    //Pull logs and create .txt file
                    ignoreRates = true;
                    DeleteLocalLogs();
                    FTP_DownloadAllServers();
                    ProcessDirectory(@"..\..\..\Logs\");
                    ProcessLogs();
                    ignoreRates = false;
                }
                if (input == 5) {
                    //Pull logs and create .txt file
                    DeleteLocalLogs();
                    FTP_DownloadAllServers();
                    ProcessLogs();
                    FTP_DeleteLogsAllServers();
                }
                if (input == 6) {
                    //Pull dod logs and create .txt file
                    FTP_DownloadDoDLogsAllServers();
                    ProcessDoDLogs();
                }
            }
        }

        public static void Local_GetAllLocalFiles() {
            Local_GetDateTimeModified(@"..\..\..\amxmodx\configs\amxx.cfg");
            Local_GetDateTimeModified(@"..\..\..\amxmodx\configs\plugins.ini");
            Local_GetDateTimeModified(@"..\..\..\amxmodx\data\lang\ktp_cvar.txt");
            Local_GetDateTimeModified(@"..\..\..\amxmodx\data\lang\ktp_cvarcfg.txt");
            Local_GetDateTimeModified(@"..\..\..\amxmodx\plugins\ktp_cvar.amxx");
            Local_GetDateTimeModified(@"..\..\..\amxmodx\plugins\ktp_cvarconfig.amxx");
        }
        
        public static void Local_GetDateTimeModified(string path) {
            DateTime dt;
            dt = File.GetLastWriteTime(path);
            Console.WriteLine("The last write time for " + path + " was {0}.", dt);
        }

        public static void FTP_AllServers() {
            numServers = 0;
            FTP_Update(ServerKeys.NineteenEleven_NY_2_HOSTNAME, ServerKeys.NineteenEleven_NY_2_IP, Convert.ToInt32(ServerKeys.NineteenEleven_NY_2_PORT), ServerKeys.NineteenEleven_NY_2_USERNAME, ServerKeys.NineteenEleven_NY_2_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.NineteenEleven_CHI_1_HOSTNAME, ServerKeys.NineteenEleven_CHI_1_IP, Convert.ToInt32(ServerKeys.NineteenEleven_CHI_1_PORT),ServerKeys.NineteenEleven_CHI_1_USERNAME, ServerKeys.NineteenEleven_CHI_1_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.NineteenEleven_NY_1_HOSTNAME, ServerKeys.NineteenEleven_NY_1_IP, Convert.ToInt32(ServerKeys.NineteenEleven_NY_1_PORT),ServerKeys.NineteenEleven_NY_1_USERNAME, ServerKeys.NineteenEleven_NY_1_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.NineteenEleven_DAL_1_HOSTNAME, ServerKeys.NineteenEleven_DAL_1_IP, Convert.ToInt32(ServerKeys.NineteenEleven_DAL_1_PORT),ServerKeys.NineteenEleven_DAL_1_USERNAME, ServerKeys.NineteenEleven_DAL_1_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.SHAKYTABLE_DAL_HOSTNAME, ServerKeys.SHAKYTABLE_DAL_IP, Convert.ToInt32(ServerKeys.SHAKYTABLE_DAL_PORT),ServerKeys.SHAKYTABLE_DAL_USERNAME, ServerKeys.SHAKYTABLE_DAL_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.NOGO_CHI_HOSTNAME, ServerKeys.NOGO_CHI_IP, Convert.ToInt32(ServerKeys.NOGO_CHI_PORT),ServerKeys.NOGO_CHI_USERNAME, ServerKeys.NOGO_CHI_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, Convert.ToInt32(ServerKeys.MTP_NY_PORT),ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.MTP_CHI_HOSTNAME, ServerKeys.MTP_CHI_IP, Convert.ToInt32(ServerKeys.MTP_CHI_PORT),ServerKeys.MTP_CHI_USERNAME, ServerKeys.MTP_CHI_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, Convert.ToInt32(ServerKeys.Thunder_NY_PORT),ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, Convert.ToInt32(ServerKeys.Thunder_CHI_PORT),ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.ICYHOT_KANGUH_ATL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_ATL_IP, Convert.ToInt32(ServerKeys.ICYHOT_KANGUH_ATL_PORT), ServerKeys.ICYHOT_KANGUH_ATL_USERNAME, ServerKeys.ICYHOT_KANGUH_ATL_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, Convert.ToInt32(ServerKeys.WASHEDUP_NY_PORT), ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, Convert.ToInt32(ServerKeys.ALLEN_SEA_PORT), ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, Convert.ToInt32(ServerKeys.NEINKTP_DAL_PORT), ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_Update(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, Convert.ToInt32(ServerKeys.ICYHOT_KANGUH_DAL_PORT), ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
        }

        public static void FTP_Update(string HOSTNAME, string IP, int PORT, string USERNAME, string PASSWORD) {
            Console.WriteLine("FTP Access to " + HOSTNAME);

            using (WebClient client = new WebClient()) {
                client.Credentials = new NetworkCredential(USERNAME, PASSWORD);
                byte[] responseArray = client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/configs/amxx.cfg", @"..\..\..\amxmodx\configs\amxx.cfg");
                Console.WriteLine("\n{0}",System.Text.Encoding.ASCII.GetString(responseArray)+"/dod/addons/amxmodx/configs/amxx.cfg", @"..\..\..\amxmodx\configs\amxx.cfg");
                responseArray = client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/configs/plugins.ini", @"..\..\..\amxmodx\configs\plugins.ini");
                Console.WriteLine("\n{0}", System.Text.Encoding.ASCII.GetString(responseArray)+"/dod/addons/amxmodx/configs/plugins.ini", @"..\..\..\amxmodx\configs\plugins.ini");
                responseArray = client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/data/lang/ktp_cvar.txt", @"..\..\..\amxmodx\data\lang\ktp_cvar.txt");
                Console.WriteLine("\n{0}", System.Text.Encoding.ASCII.GetString(responseArray)+ "/dod/addons/amxmodx/data/lang/ktp_cvar.txt", @"..\..\..\amxmodx\data\lang\ktp_cvar.txt");
                responseArray = client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/data/lang/ktp_cvarcfg.txt", @"..\..\..\amxmodx\data\lang\ktp_cvarcfg.txt");
                Console.WriteLine("\n{0}", System.Text.Encoding.ASCII.GetString(responseArray)+ "/dod/addons/amxmodx/data/lang/ktp_cvarcfg.txt", @"..\..\..\amxmodx\data\lang\ktp_cvarcfg.txt");
                responseArray = client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/plugins/ktp_cvar.amxx", @"..\..\..\amxmodx\plugins\ktp_cvar.amxx");
                Console.WriteLine("\n{0}", System.Text.Encoding.ASCII.GetString(responseArray)+ "/dod/addons/amxmodx/plugins/ktp_cvar.amxx", @"..\..\..\amxmodx\plugins\ktp_cvar.amxx");
                responseArray = client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/plugins/ktp_cvarconfig.amxx", @"..\..\..\amxmodx\plugins\ktp_cvarconfig.amxx");
                Console.WriteLine("\n{0}", System.Text.Encoding.ASCII.GetString(responseArray)+ "/dod/addons/amxmodx/plugins/ktp_cvarconfig.amxx", @"..\..\..\amxmodx\plugins\ktp_cvarconfig.amxx");
            }
            Console.WriteLine("\nFINISHED UPDATING " + HOSTNAME);
        }

        public static void DeleteLocalLogs() {
            string path = @"..\..\..\Logs\";

            DirectoryInfo directory = new DirectoryInfo(path);

            foreach (FileInfo file in directory.GetFiles()) {
                file.Delete();
            }

            foreach (DirectoryInfo dir in directory.GetDirectories()) {
                dir.Delete(true);
            }
            Console.WriteLine("Deleted local old log files");
        }

        public static void FTP_DownloadAllServers() {
            numServers = 0;
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
            FTP_DownloadLogs(ServerKeys.ICYHOT_KANGUH_ATL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_ATL_IP, ServerKeys.ICYHOT_KANGUH_ATL_USERNAME, ServerKeys.ICYHOT_KANGUH_ATL_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DownloadLogs(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
        }

        public static void FTP_DownloadLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine("FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            // download a folder and all its files
            //client.DownloadDirectory(@"..\..\..\Logs\"+HOSTNAME, @"/dod/addons/amxmodx/logs", FtpFolderSyncMode.Update);
            List<string> paths = new List<string>();
            foreach(FtpListItem element in client.GetListing(@"/dod/addons/amxmodx/logs/*.log")) {
                paths.Add(element.FullName);
                Console.WriteLine(element.FullName);
            }
            var newHOSTNAME = HOSTNAME.Split(":")[0];
            System.IO.Directory.CreateDirectory(@"..\..\..\Logs\" + newHOSTNAME);
            client.DownloadFiles(@"..\..\..\Logs\" + newHOSTNAME, paths);
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
            Console.WriteLine("Processing Logs.");
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
            LogFiles = LogFiles.Select(s => s.Replace("dod_armory_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_railroad2_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_solitude_b2", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_lennon2_b1", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_halle", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_saints", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("dod_saints_b1", "")).ToList();
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
            LogFiles = LogFiles.Select(s => s.Replace("dod_rr2_test", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<<< Drudge >>>", "Drudge")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("<<< Drudge >>", "Drudge")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("SLeePeRS <> ", "SLeePeRS <>")).ToList();



            string sssssssss = "";
            foreach (string s in LogFiles) {
                sssssssss += s;
            }


            Console.WriteLine("Finished generic line replacement.");
            string pattern = "";
            foreach (string s in LogFiles) {
                pattern = @"\d+:\d+:\d+:\d*";
                LogFilesNew.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine("Finished REGEX 00:00:00:00 replacement.");
            foreach (string s in LogFilesNew) {
                pattern = @"\d+/\d+/\d+";
                LogFilesNew2.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine("Finished REGEX 00/00/00 replacement.");
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
                            if(!s[j].Contains("rate")){
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
                Console.WriteLine("Finished parsing string " + i + " out of " + LogFilesNew2.Count);
            }
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"..\..\..\FullLog" + DateTime.Now.ToString("yyyy_MM_dd_HHmm") + ".txt", true)) {
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
            FTP_DeleteLogs(ServerKeys.ICYHOT_KANGUH_ATL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_ATL_IP, ServerKeys.ICYHOT_KANGUH_ATL_USERNAME, ServerKeys.ICYHOT_KANGUH_ATL_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DeleteLogs(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
        }

        public static void FTP_DeleteLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine("FTP Access to " + HOSTNAME);
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
                Console.WriteLine("Deleting: " + s);
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
            FTP_DownloadDODLogs(ServerKeys.ICYHOT_KANGUH_ATL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_ATL_IP, ServerKeys.ICYHOT_KANGUH_ATL_USERNAME, ServerKeys.ICYHOT_KANGUH_ATL_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.WASHEDUP_NY_HOSTNAME, ServerKeys.WASHEDUP_NY_IP, ServerKeys.WASHEDUP_NY_USERNAME, ServerKeys.WASHEDUP_NY_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.ALLEN_SEA_HOSTNAME, ServerKeys.ALLEN_SEA_IP, ServerKeys.ALLEN_SEA_USERNAME, ServerKeys.ALLEN_SEA_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.NEINKTP_DAL_HOSTNAME, ServerKeys.NEINKTP_DAL_IP, ServerKeys.NEINKTP_DAL_USERNAME, ServerKeys.NEINKTP_DAL_PASSWORD);
            numServers++;
            FTP_DownloadDODLogs(ServerKeys.ICYHOT_KANGUH_DAL_HOSTNAME, ServerKeys.ICYHOT_KANGUH_DAL_IP, ServerKeys.ICYHOT_KANGUH_DAL_USERNAME, ServerKeys.ICYHOT_KANGUH_DAL_PASSWORD);
            numServers++;
        }

        public static void FTP_DownloadDODLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine("FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            // download a folder and all its files
            List<string> paths = new List<string>();
            foreach (FtpListItem element in client.GetListing(@"/dod/logs/*.log")) {
                paths.Add(element.FullName);
                Console.WriteLine(element.FullName);
            }
            var newHOSTNAME = HOSTNAME.Split(":")[0];
            System.IO.Directory.CreateDirectory(@"..\..\..\Logs\" + newHOSTNAME);
            client.DownloadFiles(@"..\..\DoDLogs\" + newHOSTNAME, paths);
            ProcessDirectory(@"..\..\DoDLogs\");
        }

        public static void ProcessDoDLogs() {
            Console.WriteLine("Processing Logs.");
            LogFiles = LogFiles.Select(s => s.Replace("L ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("Log file started (file", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" (game ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace(" (version ", "")).ToList();
            LogFiles = LogFiles.Select(s => s.Replace("48/1.1.2.6/8308", "")).ToList();

            Console.WriteLine("Finished generic line replacement.");
            string pattern = "";
            foreach (string s in LogFiles) {
                pattern = @"\d+:\d+:\d+:\d*";
                LogFilesNew.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine("Finished REGEX 00:00:00:00 replacement.");
            foreach (string s in LogFilesNew) {
                pattern = @"\d+/\d+/\d+";
                LogFilesNew2.Add(Regex.Replace(s, pattern, ""));
            }
            Console.WriteLine("Finished REGEX 00/00/00 replacement.");
            //LogFilesNew2 = LogFilesNew2.Select(s => s.Replace(" -  ", "")).ToHashSet();
            int count = 0;
            for (int i = 0; i < LogFilesNew2.Count; i++) {
                string str = LogFilesNew2.ToList()[i];
                string[] s = str.Split("\r\n");
                for (int j = 0; j < s.Length; j++) {
                        LogLines.Add(s[j]);
                        Console.Write("\rLogline " + count + "added.");
                        count++;
                }
            }
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"..\..\FullDoDLog" + DateTime.Now.ToString("yyyy_MM_dd_HHmm") + ".txt", true)) {
                file.WriteLine(Version);
                file.WriteLine("Compiled on " + DateTime.Now.ToString("yyyy_MM_dd_HH:mm") + " from " + LogFiles.Count + " logfile lines across 12 servers.\r\n");
                foreach (string s in LogLines) {
                    file.WriteLine(s);
                }
            }
        }
    }
}
