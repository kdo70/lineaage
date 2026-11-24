package net.sf.l2j.gameserver.scripting.task;

import java.util.HashMap;
import java.util.Map;

import net.sf.l2j.gameserver.data.manager.RaidPointManager;
import net.sf.l2j.gameserver.data.sql.ClanTable;
import net.sf.l2j.gameserver.model.pledge.Clan;
import net.sf.l2j.gameserver.scripting.ScheduledQuest;

/**
 * Each month players hunt Raid Bosses and get raid points. At the end of the month top 100 players from the list get clan reputation points.<br>
 * <br>
 * The points are added after the first weekly game maintenance of the month.<br>
 * <br>
 * Only the players belonging to clans level 5 or higher can get such points.
 */
public final class RaidPointReset extends ScheduledQuest
{
	public RaidPointReset()
	{
		super(-1, "task");
	}
	
	@Override
	public final void onStart()
	{
		// RaidHunt owns the daily reset and rewards.
	}
	
	@Override
	public final void onEnd()
	{
		// Do nothing.
	}
}