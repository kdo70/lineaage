package net.sf.l2j.gameserver.network.serverpackets;

import java.util.List;

import net.sf.l2j.gameserver.data.EquipmentItemInfo;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.model.trade.TradeItem;

public class PrivateStoreListSell extends L2GameServerPacket
{
	private final int _objectId;
	private final int _playerAdena;
	private final List<TradeItem> _items;
	private final boolean _packaged;
	
	public PrivateStoreListSell(Player player, Player storePlayer)
	{
		_objectId = storePlayer.getObjectId();
		_playerAdena = player.getAdena();
		_packaged = storePlayer.getSellList().isPackaged();
		_items = List.copyOf(storePlayer.getSellList());
		for (TradeItem entry : _items)
		{
			final var item = storePlayer.getInventory().getItemByObjectId(entry.getObjectId());
			if (item != null && item.isEquipable())
				EquipmentItemInfo.send(player, item);
		}
	}
	
	@Override
	protected final void writeImpl()
	{
		writeC(0x9b);
		writeD(_objectId);
		writeD(_packaged ? 1 : 0);
		writeD(_playerAdena);
		writeD(_items.size());
		
		for (TradeItem item : _items)
		{
			writeD(item.getItem().getType2());
			writeD(item.getObjectId());
			writeD(item.getItem().getItemId());
			writeD(item.getCount());
			writeH(0x00);
			writeH(item.getEnchant());
			writeH(0x00);
			writeD(item.getItem().getBodyPart());
			writeD(item.getPrice()); // your price
			writeD(item.getItem().getReferencePrice()); // store price
		}
	}
}