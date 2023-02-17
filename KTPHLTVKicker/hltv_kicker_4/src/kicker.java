import java.util.*;
import java.util.concurrent.TimeoutException;

import com.github.koraktor.steamcondenser.*;
import com.github.koraktor.steamcondenser.exceptions.SteamCondenserException;
import com.github.koraktor.steamcondenser.steam.SteamPlayer;
import com.github.koraktor.steamcondenser.steam.servers.GoldSrcServer;

	
public class kicker{

	public static String NY1 = "192.223.24.155:27015";
	public static String NY1_HLTV = "104.153.109.168:27020";
	public static String NY1_HLTVNAME = "KTP - New York 1 - HLTV";
	public static String NY1_PASSWORD = "1911";
	public static String NY1_RCON = "ktps3";


	public static String NY2 = "192.223.24.47:27015";
	public static String NY2_HLTV = "162.248.93.150:27020";
	public static String NY2_HLTVNAME = "KTP - New York 2 - HLTV";
	public static String NY2_PASSWORD = "1911";
	public static String NY2_RCON = "ktps3";

	public static String MTPNY = "63.251.20.127:27015";
	public static String MTPNY_HLTV = "64.94.100.54:27020";
	public static String MTPNY_HLTVNAME = "MTP - New York - HLTV";
	public static String MTPNY_PASSWORD = "1911";
	public static String MTPNY_RCON = "ktps3";

	public static String THUNDERNY = "74.91.123.205:27015";
	public static String THUNDERNY_HLTV = "162.248.93.186:27020";
	public static String THUNDERNY_HLTVNAME = "THUNDER - New York - HLTV";
	public static String THUNDERNY_PASSWORD = "1911";
	public static String THUNDERNY_RCON = "thunderny";

	public static String WASHEDUPNY = "74.91.123.32:27015";
	public static String WASHEDUPNY_HLTV = "162.248.93.193:27020";
	public static String WASHEDUPNY_HLTVNAME = "Washed Up HLTV";
	public static String WASHEDUPNY_PASSWORD = "1911";
	public static String WASHEDUPNY_RCON = "unibrow";

	public static String CHI1 = "74.91.122.118:27015";
	public static String CHI1_HLTV = "162.248.93.140:27020";
	public static String CHI1_HLTVNAME = "KTP - Chicago 1 - HLTV";
	public static String CHI1_PASSWORD = "1911";
	public static String CHI1_RCON = "ktps3";

	public static String THUNDERCHI = "74.91.115.69:27015";
	public static String THUNDERCHI_HLTV = "162.248.93.232:27020";
	public static String THUNDERCHI_HLTVNAME = "THUNDER - Chicago - HLTV";
	public static String THUNDERCHI_PASSWORD = "1911";
	public static String THUNDERCHI_RCON = "ktps3";

	public static String PRICEISRIGHT_CHI = "74.91.115.213:27015";
	public static String PRICEISRIGHT_CHI_HLTV = "104.153.109.46:27020";
	public static String PRICEISRIGHT_CHI_HLTVNAME = "Price is Right - Chicago - HLTV";
	public static String PRICEISRIGHT_CHI_PASSWORD = "1911";
	public static String PRICEISRIGHT_CHI_RCON = "ktps3";

	public static String SHAKYTABLE_DAL = "74.91.126.186:27015";
	public static String SHAKYTABLE_DAL_HLTV = "104.153.109.162:27020";
	public static String SHAKYTABLE_DAL_HLTVNAME = "Shaky Table - Dallas - HLTV";
	public static String SHAKYTABLE_DAL_PASSWORD = "1911";
	public static String SHAKYTABLE_DAL_RCON = "ktps3";

	public static String DAL1 = "74.91.114.61:27015";
	public static String DAL1_HLTV = "104.153.109.224:27020";
	public static String DAL1_HLTVNAME = "KTP - Dallas 1 - HLTV";
	public static String DAL1_PASSWORD = "1911";
	public static String DAL1_RCON = "ktps3";

	public static String INS_DAL = "74.91.126.189:27015";
	public static String INS_DAL_HLTV = "162.148.93.48:27020";
	public static String INS_DAL_HLTVNAME = "ins[g] - Dallas - HLTV";
	public static String INS_DAL_PASSWORD = "1911";
	public static String INS_DAL_RCON = "ktps3";

	public static String ICYHOT_DAL = "74.91.126.193:27015";
	public static String ICYHOT_DAL_HLTV = "162.248.93.121:27020";
	public static String ICYHOT_DAL_HLTVNAME = "icyHOT - Dallas - HLTV";
	public static String ICYHOT_DAL_PASSWORD = "1911";
	public static String ICYHOT_DAL_RCON = "ktps3";

	public static String MTPCHI = "74.91.124.202:27015";
	public static String MTPCHI_HLTV = "66.150.188.190:27020";
	public static String MTPCHI_HLTVNAME = "MTP - Chicago - HLTV";
	public static String MTPCHI_PASSWORD = "1911";
	public static String MTPCHI_RCON = "ktps3";

	public static String ICYHOT_ATL = "74.91.121.162:27015";
	public static String ICYHOT_ATL_HLTV = "162.248.93.143:27020";
	public static String ICYHOT_ATL_HLTVNAME = "icyHOT - Atlanta - HLTV";
	public static String ICYHOT_ATL_PASSWORD = "1911";
	public static String ICYHOT_ATL_RCON = "ktps3";

	public static String SEA1 = "162.248.94.22:27015";
	public static String SEA1_HLTV = "sea1911.hltv.nfoservers.com:27020";
	public static String SEA1_HLTVNAME = "KTP - Seattle 1 - HLTV";
	public static String SEA1_PASSWORD = "1911";
	public static String SEA1_RCON = "ktps3";
	
	public static void main(String args[]){
		System.out.println(kill_all_hltv_servers());
	}
	
	public static String kill_all_hltv_servers(){
		String report = "--KICKING HLTV REPORT--\n";

		
		//#region New York Servers
		try{
			report += kill_hltv_server(NY1, NY1_RCON, NY1_HLTVNAME, NY1_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(NY2, NY2_RCON, NY2_HLTVNAME, NY2_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(MTPNY, MTPNY_RCON, MTPNY_HLTVNAME, MTPNY_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(THUNDERNY, THUNDERNY_RCON, THUNDERNY_HLTVNAME, THUNDERNY_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(WASHEDUPNY, WASHEDUPNY_RCON, WASHEDUPNY_HLTVNAME, WASHEDUPNY_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion
		
 		//#region Chicago Servers
		try{
			report += kill_hltv_server(CHI1, CHI1_RCON, CHI1_HLTVNAME, CHI1_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(THUNDERCHI, THUNDERCHI_RCON, THUNDERCHI_HLTVNAME, THUNDERCHI_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(PRICEISRIGHT_CHI, PRICEISRIGHT_CHI_RCON, PRICEISRIGHT_CHI_HLTVNAME, PRICEISRIGHT_CHI_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		try{
			report += kill_hltv_server(MTPCHI, MTPCHI_RCON, MTPCHI_HLTVNAME, MTPCHI_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion

		//#region Dallas Servers
		try{
			report += kill_hltv_server(DAL1, DAL1_RCON, DAL1_HLTVNAME, DAL1_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		
		try{
			report += kill_hltv_server(INS_DAL, INS_DAL_RCON, INS_DAL_HLTVNAME, INS_DAL_PASSWORD);
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
			report += kill_hltv_server(ICYHOT_ATL, ICYHOT_ATL_RCON, ICYHOT_ATL_HLTVNAME, ICYHOT_ATL_PASSWORD);
			report += "\n";
		}
		catch (Exception ex){
			report += ex.getMessage();
			report += "\n";
		}
		//#endregion

		//#region Seattle Servers 
		try{
			report += kill_hltv_server(SEA1, SEA1_RCON, SEA1_HLTVNAME, SEA1_PASSWORD);
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
		  server.rconExec("host_players_show" + " 1");
		  System.out.println(server.getPlayers());
		  //System.out.println(server.rconExec("say KTP_RCON KICKING HLTV"));
		  //erver.rconExec("kick" + hltv);
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