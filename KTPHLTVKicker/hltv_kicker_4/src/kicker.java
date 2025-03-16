import java.util.*;
import java.util.concurrent.TimeoutException;
import com.github.koraktor.steamcondenser.*;
import com.github.koraktor.steamcondenser.exceptions.SteamCondenserException;
import com.github.koraktor.steamcondenser.steam.SteamPlayer;
import com.github.koraktor.steamcondenser.steam.servers.GoldSrcServer;

	
public class kicker{

	//#region New York
	public static String KTP_NY1 = "192.223.24.155:27015";
	public static String KTP_NY1_HLTV = "104.153.109.168:27020";
	public static String KTP_NY1_HLTVNAME = "KTP - New York 1 - HLTV";
	public static String KTP_NY1_PASSWORD = "ktpsix";
	public static String KTP_NY1_RCON = "ktpadmin";

	public static String KTP_NY2 = "192.223.24.47:27015";
	public static String KTP_NY2_HLTV = "162.248.93.150:27020";
	public static String KTP_NY2_HLTVNAME = "KTP - New York 2 - HLTV";
	public static String KTP_NY2_PASSWORD = "ktpsix";
	public static String KTP_NY2_RCON = "ktpadmin";

	public static String MTP_NY = "63.251.20.127:27015";
	public static String MTP_NY_HLTV = "64.94.100.54:27020";
	public static String MTP_NY_HLTVNAME = "KTP - New York 3 - HLTV";
	public static String MTP_NY_PASSWORD = "ktpsix";
	public static String MTP_NY_RCON = "ktpadmin";

	public static String THUNDER_NY = "74.91.123.205:27015";
	public static String THUNDER_NY_HLTV = "104.153.109.189:27020";
	public static String THUNDER_NY_HLTVNAME = "THUNDER - New York - HLTV";
	public static String THUNDER_NY_PASSWORD = "ktpsix";
	public static String THUNDER_NY_RCON = "ktpadmin";

	public static String WASHEDUP_NY = "74.91.123.32:27015";
	public static String WASHEDUP_NY_HLTV = "162.248.93.193:27020";
	public static String WASHEDUP_NY_HLTVNAME = "Godfodder's HLTV";
	public static String WASHEDUP_NY_PASSWORD = "ktpsix";
	public static String WASHEDUP_NY_RCON = "ktpadmin";
	//#endregion

	//#region Chicago
	public static String KTP_CHI1 = "74.91.122.118:27015";
	public static String KTP_CHI1_HLTV = "162.248.93.140:27020";
	public static String KTP_CHI1_HLTVNAME = "KTP - Chicago 1 - HLTV";
	public static String KTP_CHI1_PASSWORD = "ktpsix";
	public static String KTP_CHI1_RCON = "ktpadmin";

	public static String MTP_CHI = "74.91.124.202:27015";
	public static String MTP_CHI_HLTV = "66.150.188.190:27020";
	public static String MTP_CHI_HLTVNAME = "KTP - Chicago 2 - HLTV";
	public static String MTP_CHI_PASSWORD = "ktpsix";
	public static String MTP_CHI_RCON = "ktpadmin";

	public static String THUNDER_CHI = "74.91.115.69:27015";
	public static String THUNDER_CHI_HLTV = "162.248.93.232:27020";
	public static String THUNDER_CHI_HLTVNAME = "THUNDER - Chicago - HLTV";
	public static String THUNDER_CHI_PASSWORD = "ktpsix";
	public static String THUNDER_CHI_RCON = "ktpadmin";
	//#endregion

	//#region Dallas
	public static String KTP_DAL1 = "74.91.114.61:27015";
	public static String KTP_DAL1_HLTV = "104.153.109.224:27020";
	public static String KTP_DAL1_HLTVNAME = "KTP - Dallas 1 - HLTV";
	public static String KTP_DAL1_PASSWORD = "ktpsix";
	public static String KTP_DAL1_RCON = "ktpadmin";

	public static String NEIN_DAL = "74.91.126.189:27015";
	public static String NEIN_DAL_HLTV = "162.148.93.48:27020";
	public static String NEIN_DAL_HLTVNAME = "SEC - Dallas - HLTV";
	public static String NEIN_DAL_PASSWORD = "ktpsix";
	public static String NEIN_DAL_RCON = "ktpadmin";

	public static String ICYHOT_DAL = "74.91.126.193:27015";
	public static String ICYHOT_DAL_HLTV = "162.248.93.121:27020";
	public static String ICYHOT_DAL_HLTVNAME = "icyHOT - Dallas - HLTV";
	public static String ICYHOT_DAL_PASSWORD = "ktpsix";
	public static String ICYHOT_DAL_RCON = "ktpadmin";

	public static String SHAKYTABLE_DAL = "74.91.126.186:27015";
	public static String SHAKYTABLE_DAL_HLTV = "104.153.109.162:27020";
	public static String SHAKYTABLE_DAL_HLTVNAME = "Shaky Table - Dallas - HLTV";
	public static String SHAKYTABLE_DAL_PASSWORD = "ktpsix";
	public static String SHAKYTABLE_DAL_RCON = "ktpadmin";

	//public static String DICE_DAL = "167.88.164.164:27015";
	//public static String DICE_DAL_HLTV = "";
	//public static String DICE_DAL_HLTVNAME = "dicE[: :]Dallas - HLTV Proxy";
	//public static String DICE_DAL_PASSWORD = "ktpsix";
	//public static String DICE_DAL_RCON = "ktpadmin";
	//#endregion

	//#region Atlanta
	public static String THREEH_ATL_PIFF = "74.91.121.242:27015";
	public static String THREEH_ATL_PIFF_HLTV = "162.248.93.202:27020";
	public static String THREEH_ATL_PIFF_HLTVNAME = "3h - Atlanta - HLTV";
	public static String THREEH_ATL_PIFF_PASSWORD = "ktpsix";
	public static String THREEH_ATL_PIFF_RCON = "ktpadmin";

	public static String IYCHOT_ATL = "74.91.112.239:27015";
	public static String IYCHOT_ATL_HLTV = "162.248.93.143:27020";
	public static String IYCHOT_ATL_HLTVNAME = "icyHOT - Atlanta - HLTV";
	public static String IYCHOT_ATL_PASSWORD = "ktpsix";
	public static String IYCHOT_ATL_RCON = "ktpadmin";
	//#endregion

	//#region Los Angeles
	public static String CPRICE_LA = "162.248.93.219:27015";
	public static String CPRICE_LA_HLTV = "104.153.109.46:27020";
	public static String CPRICE_LA_HLTVNAME = "Cory Price Big Boner Jam - HLTV";
	public static String CPRICE_LA_PASSWORD = "ktpsix";
	public static String CPRICE_LA_RCON = "ktpadmin";

	//public static String THREEH_LA_WARCHYLD = "dod3hgaming.game.nfoservers.com:27015";
	//public static String THREEH_LA_WARCHYLD_HLTV = "dod3hgaming.hltv.nfoservers.com:27020";
	//public static String THREEH_LA_WARCHYLD_HLTVNAME = "dicE[: :]Los Angeles - HLTV";
	//public static String THREEH_LA_WARCHYLD_PASSWORD = "ktpsix";
	//public static String THREEH_LA_WARCHYLD_RCON = "ktpadmin";
	//#endregion

	//region Miami
	public static String BULLET_MIAMI = "64.31.43.235:27015";
	public static String BULLET_MIAMI_HLTV = "64.31.43.235:27115";
	public static String BULLET_MIAMI_HLTVNAME = "The Wickeds' HLTV";
	public static String BULLET_MIAMI_PASSWORD = "ktpsix";
	public static String BULLET_MIAMI_RCON = "ktpadmin";

	//#endregion
	
	//#region international
	//#endregion

	//#region retired
/* 	public static String SEA1 = "162.248.94.22:27015";
	public static String SEA1_HLTV = "seaktps5.hltv.nfoservers.com:27020";
	public static String SEA1_HLTVNAME = "KTP - Seattle 1 - HLTV";
	public static String SEA1_PASSWORD = "ktpsix";
	public static String SEA1_RCON = "ktpadmin";

	public static String OVER_FRANK = "185.107.96.221:27015";
	public static String OVER_FRANK_HLTV = "162.248.93.181:27020";
	public static String OVER_FRANK_HLTVNAME = "OVER- Frankfurt - HLTV";
	public static String OVER_FRANK_PASSWORD = "ktpsix";
	public static String OVER_FRANK_RCON = "ktpadmin";

	public static String THREESIDEDQUARTER_DAL = "eliteassassins.game.nfoservers.com:27015";
	public static String THREESIDEDQUARTER_DAL_HLTV = "eliteassassins.hltv.nfoservers.com:27020";
	public static String THREESIDEDQUARTER_DAL_HLTVNAME = "Coin Purse TV";
	public static String THREESIDEDQUARTER_DAL_PASSWORD = "ktpsix";
	public static String THREESIDEDQUARTER_DAL_RCON = "ktpadmin"; */

	//#endregion

	public static void main(String args[]){
		System.out.println(kill_all_hltv_servers());
	}
	
	public static String kill_all_hltv_servers() {
		String report = "--KICKING HLTV REPORT--\n";

		//#region New York Servers
		try{
			report += kill_hltv_server(KTP_NY1, KTP_NY1_RCON, KTP_NY1_HLTVNAME, KTP_NY1_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(KTP_NY2, KTP_NY2_RCON, KTP_NY2_HLTVNAME, KTP_NY2_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(MTP_NY, MTP_NY_RCON, MTP_NY_HLTVNAME, MTP_NY_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(THUNDER_NY, THUNDER_NY_RCON, THUNDER_NY_HLTVNAME, THUNDER_NY_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(WASHEDUP_NY, WASHEDUP_NY_RCON, WASHEDUP_NY_HLTVNAME, WASHEDUP_NY_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion
		
 		//#region Chicago Servers
		try{
			report += kill_hltv_server(KTP_CHI1, KTP_CHI1_RCON, KTP_CHI1_HLTVNAME, KTP_CHI1_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(MTP_CHI, MTP_CHI_RCON, MTP_CHI_HLTVNAME, MTP_CHI_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(THUNDER_CHI, THUNDER_CHI_RCON, THUNDER_CHI_HLTVNAME, THUNDER_CHI_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion

		//#region Dallas Servers
		try{
			report += kill_hltv_server(KTP_DAL1, KTP_DAL1_RCON, KTP_DAL1_HLTVNAME, KTP_DAL1_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(NEIN_DAL, NEIN_DAL_RCON, NEIN_DAL_HLTVNAME, NEIN_DAL_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(ICYHOT_DAL, ICYHOT_DAL_RCON, ICYHOT_DAL_HLTVNAME, ICYHOT_DAL_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(SHAKYTABLE_DAL, SHAKYTABLE_DAL_RCON, SHAKYTABLE_DAL_HLTVNAME, SHAKYTABLE_DAL_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion

		//#region Atlanta Servers
		try{
			report += kill_hltv_server(THREEH_ATL_PIFF, THREEH_ATL_PIFF_RCON, THREEH_ATL_PIFF_HLTVNAME, THREEH_ATL_PIFF_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(IYCHOT_ATL, IYCHOT_ATL_RCON, IYCHOT_ATL_HLTVNAME, IYCHOT_ATL_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion

		//#region Los Angeles Servers
		try{
			report += kill_hltv_server(CPRICE_LA, CPRICE_LA_RCON, CPRICE_LA_HLTVNAME, CPRICE_LA_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion

		//#region Miami Servers
		try{
			report += kill_hltv_server(BULLET_MIAMI, BULLET_MIAMI_RCON, BULLET_MIAMI_HLTVNAME, BULLET_MIAMI_PASSWORD);
			report += "\n";
			}
			catch (Exception ex){
				report += ex.getMessage();
				report += "\n";
			}
		//#endregion
		return report;
	}
	
	public static String kill_hltv_server(String serverIP, String rcon, String hltv, String password){
		try {
		GoldSrcServer server = new GoldSrcServer(serverIP);
		  hltv = " \"" + hltv + "\"";
		  server.rconAuth(rcon);
		  //bool f = server.isRconAuthenticated();
		  //server.rconExec("host_players_show" + " 1");
		  //System.out.println(server.getPlayers());
		  System.out.println(server.rconExec("say KTP_RCON KICKING HLTV"));
		  server.rconExec("kick" + hltv);
		  //System.out.println(server.rconExec("status"));
		  return "Successfully kicked HLTV on " + serverIP;
		}
		catch(SteamCondenserException ex) {
		  System.err.println("Could not authenticate with the game server.");
		  return "Failed to authenticate RCON, failed to kick HLTV on " + serverIP;
		}
		catch(TimeoutException ex) {
			System.err.println("Timed Out");
			return "Timed out, failed to kick HLTV on " + serverIP;
		  }  
	}

	public static String change_map(String serverIP, String rcon, String hltv, String password){
		try {
		GoldSrcServer server = new GoldSrcServer(serverIP);
		  hltv = " \"" + hltv + "\"";
		  server.rconAuth(rcon);
		  //bool f = server.isRconAuthenticated();
		  server.rconExec("host_players_show" + " 1");
		  System.out.println(server.getPlayers());
		  System.out.println(server.rconExec("say KTP_RCON CHANGING MAP"));
		  server.rconExec("chankick" + hltv);
		  //System.out.println(server.rconExec("status"));
		  return "Successfully kicked HLTV on " + serverIP;
		}
		catch(SteamCondenserException ex) {
		  System.err.println("Could not authenticate with the game server.");
		  return "Failed to authenticate RCON, failed to kick HLTV on " + serverIP;
		}
		catch(TimeoutException ex) {
			System.err.println("Timed Out");
			return "Timed out, failed to kick HLTV on " + serverIP;
		  }  
	}
}