package net.sf.l2j.gameserver.scripting.task;

import net.sf.l2j.gameserver.data.manager.RaidHuntManager;
import net.sf.l2j.gameserver.scripting.ScheduledQuest;

/**
 * Hands out the daily rewards of the raid boss book ladder.<br>
 * <br>
 * The rewarded positions and what each of them gives live on config/mods/raid_hunt.properties. A winner who happens to be offline doesn't lose anything : the reward waits for him in database and is
 * handed out on his next login.
 */
public final class RaidHuntDailyReward extends ScheduledQuest
{
	public RaidHuntDailyReward()
	{
		super(-1, "task");
	}

	@Override
	public final void onStart()
	{
		RaidHuntManager.getInstance().runDailyRewards();
	}

	@Override
	public final void onEnd()
	{
		// Do nothing.
	}
}
