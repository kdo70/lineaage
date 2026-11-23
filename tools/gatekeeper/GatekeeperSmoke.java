import net.sf.l2j.Config;
import net.sf.l2j.gameserver.data.xml.GatekeeperData;
public class GatekeeperSmoke {
 public static void main(String[] args) throws Exception {
  var load=Config.class.getDeclaredMethod("loadGatekeeper"); load.setAccessible(true); load.invoke(null);
  var d=GatekeeperData.getInstance();
  if(d.getNpcIds().length!=18 || d.getMenu(0)==null || d.getMenu(0).getPoints().isEmpty()) throw new AssertionError("Missing data");
  int count=d.getMenu(0).getPoints().size();
  for(int id:d.getNpcIds()) if(d.getMenuByNpcId(id)!=d.getMenu(0)) throw new AssertionError("NPC menu");
  if(d.getMenu(0).getPoint(-1)!=null) throw new AssertionError("Whitelist");
  d.reload(); if(d.getMenu(0).getPoints().size()!=count) throw new AssertionError("Reload");
  if(Config.GATEKEEPER_TELEPORT_DELAY!=5000) throw new AssertionError("Config");
  System.out.println("PASS: config, 18 NPC menus, "+count+" points, whitelist, XML reload");
 }
}
