package net.sf.l2j.gameserver.network.clientpackets;

import net.sf.l2j.gameserver.enums.ShortcutType;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.model.item.instance.ItemInstance;
import net.sf.l2j.gameserver.network.SystemMessageId;
import net.sf.l2j.gameserver.network.serverpackets.ExVariationCancelResult;
import net.sf.l2j.gameserver.network.serverpackets.SystemMessage;

public final class RequestRefineCancel extends L2GameClientPacket
{
	private int _objectId;
	
	@Override
	protected void readImpl()
	{
		_objectId = readD();
	}
	
	@Override
	protected void runImpl()
	{
		final Player player = getClient().getPlayer();
		if (player == null)
			return;
		
		final ItemInstance item = player.getInventory().getItemByObjectId(_objectId);
		if (item == null)
		{
			player.sendPacket(new ExVariationCancelResult(0));
			return;
		}
		
		if (item.getOwnerId() != player.getObjectId())
			return;
		
		// cannot remove augmentation from a not augmented item
		if (!item.isAugmented())
		{
			player.sendPacket(SystemMessageId.AUGMENTATION_REMOVAL_CAN_ONLY_BE_DONE_ON_AN_AUGMENTED_ITEM);
			player.sendPacket(new ExVariationCancelResult(0));
			return;
		}
		
		int price = getRemovalPrice(item);
		if (price <= 0) return;

		// try to reduce the players adena
		if (!player.reduceAdena(price, true))
		{
			player.sendPacket(new ExVariationCancelResult(0));
			return;
		}
		
		// unequip item
		if (item.isEquipped())
			player.disarmWeapon(false);
		
		// remove the augmentation
		item.removeAugmentation(player);
		
		// send ExVariationCancelResult
		player.sendPacket(new ExVariationCancelResult(1));
		
		// Refresh shortcuts.
		player.getShortcutList().refreshShortcuts(s -> item.getObjectId() == s.getId() && s.getType() == ShortcutType.ITEM);
		
		// send system message
		player.sendPacket(SystemMessage.getSystemMessage(SystemMessageId.AUGMENTATION_HAS_BEEN_SUCCESSFULLY_REMOVED_FROM_YOUR_S1).addItemName(item));
	}
	public static int getRemovalPrice(ItemInstance item)
	{
		int crystals = item.getCrystalCount();
		return switch (item.getItem().getCrystalType())
		{
			case C -> crystals < 1720 ? 95000 : crystals < 2452 ? 150000 : 210000;
			case B -> crystals < 1746 ? 240000 : 270000;
			case A -> crystals < 2160 ? 330000 : crystals < 2824 ? 390000 : 420000;
			case S -> 480000;
			default -> 0;
		};
	}

}