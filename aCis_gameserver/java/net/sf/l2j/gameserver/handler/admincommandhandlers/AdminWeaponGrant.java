package net.sf.l2j.gameserver.handler.admincommandhandlers;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.sf.l2j.gameserver.data.xml.AdminData;
import net.sf.l2j.gameserver.data.manager.BuyListManager;
import net.sf.l2j.gameserver.handler.IAdminCommandHandler;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.model.buylist.NpcBuyList;
import net.sf.l2j.gameserver.model.item.instance.ItemInstance;
import net.sf.l2j.gameserver.model.item.kind.Item;
import net.sf.l2j.gameserver.model.item.kind.Weapon;
import net.sf.l2j.gameserver.network.serverpackets.ItemList;

final class AdminWeaponGrant
{
	record Product(int id, int count, int enchant, boolean stackable, int weight)
	{
	}

	record Plan(int slots, int weight, long count)
	{
	}

	private AdminWeaponGrant()
	{
	}

	static Plan plan(List<Product> products, Map<Integer, Integer> existing)
	{
		int slots = 0;
		int weight = 0;
		long count = 0;
		final Map<Integer, Integer> stacks = new HashMap<>(existing);
		for (Product product : products)
		{
			if (product.id() <= 0 || product.count() <= 0 || product.weight() < 0 || product.enchant() < 0 || product.enchant() > 65535 || (product.stackable() && product.enchant() != 0))
				throw new IllegalArgumentException("Invalid product");
			weight = Math.addExact(weight, Math.multiplyExact(product.weight(), product.count()));
			count = Math.addExact(count, product.count());
			if (product.stackable())
			{
				if (!stacks.containsKey(product.id()))
					slots = Math.addExact(slots, 1);
				stacks.put(product.id(), Math.addExact(stacks.getOrDefault(product.id(), 0), product.count()));
			}
			else
				slots = Math.addExact(slots, product.count());
		}
		return new Plan(slots, weight, count);
	}

	static void give(Player player, int listId)
	{
		if (!AdminData.getInstance().hasAccess("admin_buy", player.getAccessLevel()))
			return;
		final NpcBuyList list = BuyListManager.getInstance().getBuyList(listId);
		if (list == null || !list.isGmWeapon() || list.isEmpty())
		{
			player.sendMessage("Only GM weapon lists can be granted with All.");
			return;
		}
		if (player.isProcessingTransaction() || player.isOperating())
		{
			player.sendMessage("Stop trading or shopping before receiving the weapon list.");
			return;
		}
		final List<Product> products = new ArrayList<>();
		for (var product : list.values())
		{
			final Item item = product.getItem();
			products.add(new Product(item.getItemId(), 1, item instanceof Weapon ? 16 : 0, item.isStackable(), item.getWeight()));
		}
		final Map<Integer, Integer> existing = new HashMap<>();
		for (ItemInstance item : player.getInventory().getItems())
			if (item.isStackable())
				existing.put(item.getItemId(), item.getCount());
		final Plan plan;
		try
		{
			plan = plan(products, existing);
		}
		catch (IllegalArgumentException | ArithmeticException e)
		{
			player.sendMessage("Invalid quantity, enchantment or weight. No items were granted.");
			return;
		}
		player.getInventory().updateWeight();
		if ((long) player.getInventory().getSize() + plan.slots() > player.getStatus().getInventoryLimit() || (long) player.getInventory().getTotalWeight() + plan.weight() > player.getWeightLimit())
		{
			player.sendMessage("Not enough inventory space or weight capacity for the entire list. No items were granted.");
			return;
		}
		long granted = 0;
		for (Product product : products)
		{
			final int instances = product.stackable() ? 1 : product.count();
			for (int i = 0; i < instances; i++)
			{
				final int amount = product.stackable() ? product.count() : 1;
				// Create inventory items without pickup/equip side effects.
				final ItemInstance item = player.getInventory().addItem(product.id(), amount);
				if (item == null)
				{
					player.sendMessage("Grant interrupted; received " + granted + " items. Check server logs before retrying.");
					IAdminCommandHandler.LOGGER.warn("Admin {} grant {} interrupted after {} items", player.getName(), listId, granted);
					player.sendPacket(new ItemList(player, false));
					return;
				}
				if (product.enchant() > 0)
					item.setEnchantLevel(product.enchant(), player);
				granted += amount;
			}
		}
		player.sendPacket(new ItemList(player, false));
		player.sendMessage("Received " + granted + " items from all " + list.size() + " entries of " + listId + ".");
		IAdminCommandHandler.LOGGER.info("Admin {} granted {} items from {} to own inventory", player.getName(), granted, listId);
	}
}
