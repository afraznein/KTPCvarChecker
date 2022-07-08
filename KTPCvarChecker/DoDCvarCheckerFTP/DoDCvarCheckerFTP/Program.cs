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
        public static string Version = "KTP Cvar Checker FTPLOG. Version 07.08.22 Nein_";
        static void Main(string[] args) {


            while (true){
                Console.WriteLine(Version);
                Console.WriteLine("1. Get status of all of the files, last modified date.");
                Console.WriteLine("2. FTP Update for CVAR Checker");
                Console.WriteLine("3. Pull logs");
                string val = Console.ReadLine();
                int input = Convert.ToInt32(val);
                if (input == 1) {
                    //Get the status of the local files
                    Local_GetAllLocalFiles();
                }
                if (input == 2) {
                    //Push FTP update for all 10 servers
                    FTP_AllServers();
                }
                if (input == 3) {
                    //Pull logs and create .txt file
                    DeleteLocalLogs();
                    FTP_DownloadAllServers();
                    ProcessLogs();
                }
            }
        }

        public static void Local_GetAllLocalFiles() {
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\amxmodx\configs\amxx.cfg");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\amxmodx\configs\plugins.ini");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\amxmodx\data\lang\ktp_cvar.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\amxmodx\data\lang\ktp_cvarcfg.txt");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\amxmodx\plugins\ktp_cvar.amxx");
            Local_GetDateTimeModified(@"N:\Nein_\KTPCvarChecker\amxmodx\plugins\ktp_cvarconfig.amxx");
        }
        
        public static void Local_GetDateTimeModified(string path) {
            DateTime dt;
            dt = File.GetLastWriteTime(path);
            Console.WriteLine("The last write time for " + path + " was {0}.", dt);
        }

        public static void FTP_AllServers() {
            FTP_Update(ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_HOSTNAME, ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_IP, Convert.ToInt32(ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_PORT), ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_USERNAME, ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_PASSWORD);
            FTP_Update(ServerKeys.NineteenEleven_CHIOne_HOSTNAME, ServerKeys.NineteenEleven_CHIOne_IP, Convert.ToInt32(ServerKeys.NineteenEleven_CHIOne_PORT),ServerKeys.NineteenEleven_CHIOne_USERNAME, ServerKeys.NineteenEleven_CHIOne_PASSWORD);
            FTP_Update(ServerKeys.NineteenEleven_CHIThree_HOSTNAME, ServerKeys.NineteenEleven_CHIThree_IP, Convert.ToInt32(ServerKeys.NineteenEleven_CHIThree_PORT),ServerKeys.NineteenEleven_CHIThree_USERNAME, ServerKeys.NineteenEleven_CHIThree_PASSWORD);
            FTP_Update(ServerKeys.NineteenEleven_DALOne_HOSTNAME, ServerKeys.NineteenEleven_DALOne_IP, Convert.ToInt32(ServerKeys.NineteenEleven_DALOne_PORT),ServerKeys.NineteenEleven_DALOne_USERNAME, ServerKeys.NineteenEleven_DALOne_PASSWORD);
            FTP_Update(ServerKeys.NineteenEleven_NYOne_HOSTNAME, ServerKeys.NineteenEleven_NYOne_IP, Convert.ToInt32(ServerKeys.NineteenEleven_NYOne_PORT),ServerKeys.NineteenEleven_NYOne_USERNAME, ServerKeys.NineteenEleven_NYOne_PASSWORD);
            FTP_Update(ServerKeys.CORYBBJ_HOSTNAME, ServerKeys.CORYBBJ_IP, Convert.ToInt32(ServerKeys.CORYBBJ_PORT),ServerKeys.CORYBBJ_USERNAME, ServerKeys.CORYBBJ_PASSWORD);
            FTP_Update(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, Convert.ToInt32(ServerKeys.MTP_NY_PORT),ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            FTP_Update(ServerKeys.MTP_AL_HOSTNAME, ServerKeys.MTP_AL_IP, Convert.ToInt32(ServerKeys.MTP_AL_PORT),ServerKeys.MTP_AL_USERNAME, ServerKeys.MTP_AL_PASSWORD);
            FTP_Update(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, Convert.ToInt32(ServerKeys.Thunder_NY_PORT),ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            FTP_Update(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, Convert.ToInt32(ServerKeys.Thunder_CHI_PORT),ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
        }

        public static void FTP_Update(string HOSTNAME, string IP, int PORT, string USERNAME, string PASSWORD) {
            Console.WriteLine("FTP Access to " + HOSTNAME);

            using (WebClient client = new WebClient()) {
                client.Credentials = new NetworkCredential(USERNAME, PASSWORD);
                client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/configs/amxx.cfg", @"N:\Nein_\KTPCvarChecker\amxmodx\configs\amxx.cfg");
                client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/configs/plugins.ini", @"N:\Nein_\KTPCvarChecker\amxmodx\configs\plugins.ini");
                client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/data/lang/ktp_cvar.txt", @"N:\Nein_\KTPCvarChecker\amxmodx\data\lang\ktp_cvar.txt");
                client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/data/lang/ktp_cvarcfg.txt", @"N:\Nein_\KTPCvarChecker\amxmodx\data\lang\ktp_cvarcfg.txt");
                client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/plugins/ktp_cvar.amxx", @"N:\Nein_\KTPCvarChecker\amxmodx\plugins\ktp_cvar.amxx");
                client.UploadFile("ftp://" + IP + "/dod/addons/amxmodx/plugins/ktp_cvarconfig.amxx", @"N:\Nein_\KTPCvarChecker\amxmodx\plugins\ktp_cvarconfig.amxx");
            }
            Console.WriteLine("FINISHED UPDATING " + HOSTNAME);
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
            Console.WriteLine("Deleted local old log files");
        }

        public static void FTP_DownloadAllServers() {
            FTP_DownloadLogs(ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_HOSTNAME, ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_IP, ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_USERNAME, ServerKeys.NineteenEleven_CHI_TwentyFiveSlot_PASSWORD);
            FTP_DownloadLogs(ServerKeys.NineteenEleven_CHIOne_HOSTNAME, ServerKeys.NineteenEleven_CHIOne_IP, ServerKeys.NineteenEleven_CHIOne_USERNAME, ServerKeys.NineteenEleven_CHIOne_PASSWORD);
            FTP_DownloadLogs(ServerKeys.NineteenEleven_CHIThree_HOSTNAME, ServerKeys.NineteenEleven_CHIThree_IP, ServerKeys.NineteenEleven_CHIThree_USERNAME, ServerKeys.NineteenEleven_CHIThree_PASSWORD);
            FTP_DownloadLogs(ServerKeys.NineteenEleven_DALOne_HOSTNAME, ServerKeys.NineteenEleven_DALOne_IP, ServerKeys.NineteenEleven_DALOne_USERNAME, ServerKeys.NineteenEleven_DALOne_PASSWORD);
            FTP_DownloadLogs(ServerKeys.NineteenEleven_NYOne_HOSTNAME, ServerKeys.NineteenEleven_NYOne_IP, ServerKeys.NineteenEleven_NYOne_USERNAME, ServerKeys.NineteenEleven_NYOne_PASSWORD);
            FTP_DownloadLogs(ServerKeys.CORYBBJ_HOSTNAME, ServerKeys.CORYBBJ_IP, ServerKeys.CORYBBJ_USERNAME, ServerKeys.CORYBBJ_PASSWORD);
            FTP_DownloadLogs(ServerKeys.MTP_NY_HOSTNAME, ServerKeys.MTP_NY_IP, ServerKeys.MTP_NY_USERNAME, ServerKeys.MTP_NY_PASSWORD);
            FTP_DownloadLogs(ServerKeys.MTP_AL_HOSTNAME, ServerKeys.MTP_AL_IP, ServerKeys.MTP_AL_USERNAME, ServerKeys.MTP_AL_PASSWORD);
            FTP_DownloadLogs(ServerKeys.Thunder_NY_HOSTNAME, ServerKeys.Thunder_NY_IP, ServerKeys.Thunder_NY_USERNAME, ServerKeys.Thunder_NY_PASSWORD);
            FTP_DownloadLogs(ServerKeys.Thunder_CHI_HOSTNAME, ServerKeys.Thunder_CHI_IP, ServerKeys.Thunder_CHI_USERNAME, ServerKeys.Thunder_CHI_PASSWORD);
        }

        public static void FTP_DownloadLogs(string HOSTNAME, string IP, string USERNAME, string PASSWORD) {
            Console.WriteLine("FTP Access to " + HOSTNAME);
            FtpClient client = new FtpClient(IP, USERNAME, PASSWORD);
            client.AutoConnect();
            // download a folder and all its files
            //client.DownloadDirectory(@"N:\Nein_\KTPCvarChecker\Logs\"+HOSTNAME, @"/dod/addons/amxmodx/logs", FtpFolderSyncMode.Update);
            List<string> paths = new List<string>();
            foreach(FtpListItem element in client.GetListing(@"/dod/addons/amxmodx/logs/*.log")) {
                paths.Add(element.FullName);
                Console.WriteLine(element.FullName);
            }
            var newHOSTNAME = HOSTNAME.Split(":")[0];
            System.IO.Directory.CreateDirectory(@"N:\Nein_\KTPCvarChecker\Logs\" + newHOSTNAME);
            client.DownloadFiles(@"N:\Nein_\KTPCvarChecker\Logs\" + newHOSTNAME, paths);
            ProcessDirectory(@"N:\Nein_\KTPCvarChecker\Logs\");
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
            LogFilesNew2 = LogFilesNew2.Select(s => s.Replace(" -  ", "")).ToHashSet();
            LogFilesNew2 = LogFilesNew2.Select(s => s.Replace("[AMXX] ", "")).ToHashSet();
            int count = 0;
            for (int i = 0; i<LogFilesNew2.Count; i++) {
                string str = LogFilesNew2.ToList()[i];
                string[] s = str.Split("\r\n");
                for (int j = 0; j < s.Length; j++) {
                    if (s[j].Contains("KTP")) {
                        string[] ss = s[j].Split(">");
                        HashSet<string> TempHash = new HashSet<string>();
                        if (!SteamIDDictionary.ContainsKey(ss[0])) {
                            TempHash.Add(ss[1]);
                            SteamIDDictionary.Add(ss[0], TempHash);
                        }
                        else {
                            TempHash = SteamIDDictionary[ss[0]];
                            TempHash.Add(ss[1]);
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
                Console.WriteLine("Finished parsing string " + i + " out of " + LogFilesNew2.Count);
            }
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"N:\Nein_\KTPCvarChecker\FullLog" + DateTime.Now.ToString("yyyy_MM_dd_HHmm") + ".txt", true)) {
                file.WriteLine(Version);
                file.WriteLine("Compiled on " + DateTime.Now.ToString("yyyy_MM_dd_HH:mm") + " from " + LogFiles.Count + " logfile lines across 10 servers. Grouped by STEAMID. \r\n");
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

    }
}
