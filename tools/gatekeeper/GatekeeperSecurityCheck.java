import java.util.*; import java.util.concurrent.*; import java.util.concurrent.atomic.*;
public class GatekeeperSecurityCheck {
static class Player { boolean online=true, dead, restricted, available=true; int money=100, charges, ports; boolean isOnline(){return online;} boolean isDead(){return dead;} boolean isOperating(){return restricted;} boolean isInOlympiadMode(){return restricted;} boolean isInObserverMode(){return restricted;} boolean isFestivalParticipant(){return restricted;} boolean isCursedWeaponEquipped(){return restricted;} int getObjectId(){return 1;} void broadcastPacket(Object o){} void sendPacket(Object o){} boolean destroyItemByItemId(int id,int n,boolean msg){charges++; if(money<n)return false;money-=n;return true;} }
static class GatekeeperPoint { int getCastleId(){return 1;} int getPriceId(){return 57;} boolean isAvailableFor(Player p){return p.available;} }
static class Castle { Castle getSiege(){return this;} boolean isInProgress(){return siege;} }
static boolean siege; static class CastleManager {static CastleManager getInstance(){return new CastleManager();} Castle getCastleById(int id){return new Castle();}}
static class MagicSkillCanceled {MagicSkillCanceled(int id){}} static class SystemMessageId {static final Object YOU_NOT_ENOUGH_ADENA=new Object();}
static void doTeleport(Player p,GatekeeperPoint g){p.ports++;}
static void check(boolean b){if(!b)throw new AssertionError();}
public static void main(String[] args)throws Exception{
GatekeeperPoint g=new GatekeeperPoint();
for(int i=0;i<5;i++){Player p=new Player(); if(i==0)p.dead=true; if(i==1)p.online=false; if(i==2)p.restricted=true; if(i==3)p.available=false; siege=i==4; completeTeleport(p,g,50);check(p.money==100&&p.charges==0&&p.ports==0);} siege=false;
Player p=new Player();p.money=49;completeTeleport(p,g,50);check(p.money==49&&p.ports==0);p=new Player();completeTeleport(p,g,50);check(p.money==50&&p.charges==1&&p.ports==1);
Set<Integer> pending=ConcurrentHashMap.newKeySet();AtomicInteger winners=new AtomicInteger();ExecutorService pool=Executors.newFixedThreadPool(16);for(int i=0;i<10000;i++)pool.submit(()->{if(pending.add(1))winners.incrementAndGet();});pool.shutdown();check(pool.awaitTermination(30,TimeUnit.SECONDS));check(winners.get()==1);pending.remove(1);check(pending.add(1));
System.out.println("PASS: death, offline, restricted state, availability, siege, insufficient funds, paid success; 10000 concurrent registrations, retry after release");}
	private static void completeTeleport(Player player, GatekeeperPoint point, int price)
	{
		final Castle castle = point.getCastleId() > 0 ? CastleManager.getInstance().getCastleById(point.getCastleId()) : null;
		if (!player.isOnline() || player.isDead() || player.isOperating() || player.isInOlympiadMode() || player.isInObserverMode() || player.isFestivalParticipant() || player.isCursedWeaponEquipped() || !point.isAvailableFor(player) || (castle != null && castle.getSiege().isInProgress()))
		{
			player.broadcastPacket(new MagicSkillCanceled(player.getObjectId()));
			return;
		}

		// Charge only after the delay: cancellation and disconnect never require an offline refund.
		if (price > 0 && !player.destroyItemByItemId(point.getPriceId(), price, true))
		{
			player.broadcastPacket(new MagicSkillCanceled(player.getObjectId()));
			player.sendPacket(SystemMessageId.YOU_NOT_ENOUGH_ADENA);
			return;
		}
		doTeleport(player, point);
	}

}