package net.sf.l2j.gameserver.handler.admincommandhandlers;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.StringTokenizer;

import net.sf.l2j.commons.pool.ConnectionPool;

import net.sf.l2j.gameserver.enums.actors.OperateType;
import net.sf.l2j.gameserver.data.manager.CursedWeaponManager;
import net.sf.l2j.gameserver.enums.items.EtcItemType;
import net.sf.l2j.gameserver.enums.items.ItemType;
import net.sf.l2j.gameserver.handler.IAdminCommandHandler;
import net.sf.l2j.gameserver.model.World;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.model.actor.Summon;
import net.sf.l2j.gameserver.model.item.instance.ItemInstance;
import net.sf.l2j.gameserver.model.item.kind.Item;
import net.sf.l2j.gameserver.network.serverpackets.ItemList;
import net.sf.l2j.gameserver.network.serverpackets.NpcHtmlMessage;

final class AdminInventoryCleanup
{
	private enum Category
	{
		all("Delete all"), weapons("Weapons"), armor("Armor / shields"), jewelry("Jewelry"), consumables("Consumables"), quest("Quest items"), money("Currency"), other("Other items");

		private final String _label;

		Category(String label)
		{
			_label = label;
		}
	}

	private AdminInventoryCleanup()
	{
	}

	static String classify(int type, ItemType itemType)
	{
		return switch (type)
		{
			case Item.TYPE2_WEAPON -> "weapons";
			case Item.TYPE2_SHIELD_ARMOR -> "armor";
			case Item.TYPE2_ACCESSORY -> "jewelry";
			case Item.TYPE2_QUEST -> "quest";
			case Item.TYPE2_MONEY -> "money";
			default -> (itemType instanceof EtcItemType etc && switch (etc)
			{
				case ARROW, POTION, SHOT, SCROLL, SCRL_ENCHANT_WP, SCRL_ENCHANT_AM, BLESS_SCRL_ENCHANT_WP, BLESS_SCRL_ENCHANT_AM, ELIXIR, LURE, DYE, HERB -> true;
				default -> false;
			}) ? "consumables" : "other";
		};
	}

	private static boolean matches(Category category, ItemInstance item)
	{
		return category == Category.all || category.name().equals(classify(item.getItem().getType2(), item.getItemType()));
	}

	static void handle(Player admin, StringTokenizer tokens, boolean delete)
	{
		try
		{
			if (!delete)
			{
				if (tokens.countTokens() != 1)
					throw new IllegalArgumentException();
				final String who = tokens.nextToken();
				if (who.equals("self"))
					show(admin, admin);
				else if (who.equals("target") && admin.getTarget() instanceof Player target)
					show(admin, target);
				else
					admin.sendMessage("Select a player first. No items were removed.");
				return;
			}
			if (tokens.countTokens() != 2)
				throw new IllegalArgumentException();
			final int ownerId = Integer.parseInt(tokens.nextToken());
			final Category category = Category.valueOf(tokens.nextToken());
			final Player owner = World.getInstance().getPlayer(ownerId);
			if (owner == null || !owner.isOnline() || (owner != admin && admin.getTarget() != owner))
			{
				admin.sendMessage("Inventory owner is offline or target changed. Reopen inventory cleanup.");
				return;
			}
			if (category != Category.all && (owner.isProcessingTransaction() || owner.isOperating() || owner.isFishing()))
			{
				admin.sendMessage("Stop trading, shopping, crafting or fishing before clearing this inventory.");
				return;
			}
			if (category == Category.all)
			{
				owner.cancelActiveTrade();
				owner.cancelActiveEnchant();
				if (owner.isOperating())
					owner.setOperateType(OperateType.NONE);
				if (owner.isFishing())
					owner.getFishingStance().end(false);
			}
			int removed = 0;
			int skipped = 0;
			long amount = 0;
			for (ItemInstance item : new ArrayList<>(owner.getInventory().getItems()))
			{
				if (!matches(category, item))
					continue;
				synchronized (item)
				{
					if (category != Category.all && (owner.isProcessingTransaction() || owner.isOperating() || owner.isFishing()))
					{
						admin.sendMessage("Inventory cleanup stopped: the owner is busy.");
						break;
					}
					if (item.getOwnerId() != ownerId || owner.getInventory().getItemByObjectId(item.getObjectId()) != item
						|| (category != Category.all && (item.isSummonItem() || CursedWeaponManager.getInstance().isCursed(item.getItemId()))))
					{
						skipped++;
						continue;
					}
					final int count = item.getCount();
					if (category == Category.all)
					{
						if (item.isSummonItem())
							releasePet(owner, item.getObjectId());
						if (owner.getCursedWeaponEquippedId() == item.getItemId())
							CursedWeaponManager.getInstance().getCursedWeapon(item.getItemId()).endOfLife();
					}
					if (owner.getInventory().getItemByObjectId(item.getObjectId()) == null || owner.destroyItem(item, count, false))
					{
						removed++;
						amount += count;
					}
					else
						skipped++;
				}
			}
			owner.refreshExpertisePenalty();
			owner.sendPacket(new ItemList(owner, false));
			owner.broadcastUserInfo();
			final String report = "Inventory of " + owner.getName() + ": removed " + removed + " stacks (" + amount + " items), skipped " + skipped + ".";
			admin.sendMessage(report);
			if (owner != admin)
				owner.sendMessage(report);
			IAdminCommandHandler.LOGGER.info("Admin {} cleared inventory of {} [{}]: category={}, stacks={}, items={}, skipped={}", admin.getName(), owner.getName(), ownerId, category, removed, amount, skipped);
			show(admin, owner);
		}
		catch (IllegalArgumentException e)
		{
			admin.sendMessage("Usage: //item inventory self|target or //item clear ownerId all|weapons|armor|jewelry|consumables|quest|money|other");
		}
	}

	private static void releasePet(Player owner, int objectId)
	{
		if (owner.isMounted() && owner.getMountObjectId() == objectId)
			owner.dismount();

		final Summon summon = owner.getSummon();
		if (summon != null && summon.getControlItemId() == objectId)
			summon.unSummon(owner);

		try (Connection con = ConnectionPool.getConnection();
			PreparedStatement statement = con.prepareStatement("DELETE FROM pets WHERE item_obj_id=?"))
		{
			statement.setInt(1, objectId);
			statement.executeUpdate();
		}
		catch (SQLException e)
		{
			IAdminCommandHandler.LOGGER.error("Couldn't delete pet record for item {}.", objectId, e);
		}
	}

	static void show(Player admin, Player owner)
	{
		final StringBuilder buttons = new StringBuilder("<table width=240 cellpadding=0 cellspacing=0>");
		final Category[] categories = Category.values();
		for (int i = 0; i < categories.length; i++)
		{
			if (i % 2 == 0)
				buttons.append("<tr>");
			final Category category = categories[i];
			buttons.append("<td width=120 height=25 align=center><button value=\"").append(category._label)
				.append("\" action=\"bypass -h admin_item clear ").append(owner.getObjectId()).append(' ').append(category.name())
				.append("\" width=112 height=20 back=\"sek.cbui94\" fore=\"sek.cbui92\"></td>");
			if (i % 2 == 1)
				buttons.append("</tr>");
		}
		buttons.append("</table>");

		final NpcHtmlMessage html = new NpcHtmlMessage(0);
		html.setFile("data/html/admin/itemcreation.htm");
		html.replace("%inventoryOwner%", owner.getName());
		html.replace("%inventoryButtons%", buttons.toString());
		admin.sendPacket(html);
	}
}
