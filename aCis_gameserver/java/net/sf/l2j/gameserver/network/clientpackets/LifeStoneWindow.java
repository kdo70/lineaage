package net.sf.l2j.gameserver.network.clientpackets;

import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.ThreadLocalRandom;
import net.sf.l2j.Config;
import net.sf.l2j.gameserver.data.xml.AugmentationData;
import net.sf.l2j.gameserver.data.xml.ItemIconData;
import net.sf.l2j.gameserver.data.xml.ItemData;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.model.item.instance.ItemInstance;
import net.sf.l2j.gameserver.network.serverpackets.ConfirmDlg;
import net.sf.l2j.gameserver.network.serverpackets.NpcHtmlMessage;
import net.sf.l2j.gameserver.enums.ShortcutType;

public final class LifeStoneWindow
{
	private record Request(int stone, int weapon, int token, long expires) {}
	private static final int PAGE_ROWS = 8;
	private static final Map<Player, Request> REQUESTS = new WeakHashMap<>();
	private LifeStoneWindow() {}

	public static synchronized void open(Player player, ItemInstance stone)
	{
		if (!Config.LIFE_STONE_WINDOW || !AbstractRefinePacket.isValid(player) || player.isItemDisabled(stone))
			return;
		REQUESTS.put(player, new Request(stone.getObjectId(), 0, 0, System.currentTimeMillis() + 120000));
		showPage(player, stone, 0);
	}

	private static void showPage(Player player, ItemInstance stone, int requestedPage)
	{
		var weapons = player.getInventory().getItems().stream().filter(w -> AbstractRefinePacket.isValid(player, w, true)).sorted(java.util.Comparator.comparingInt(ItemInstance::getObjectId)).toList();
		int pages = Math.max(1, (weapons.size() + PAGE_ROWS - 1) / PAGE_ROWS);
		int page = Math.max(0, Math.min(requestedPage, pages - 1));
		StringBuilder html = new StringBuilder("<html><title>" + escape(stone.getItem().getName()) + "</title><body><table width=280><tr><td height=24 align=center><font color=808080>Выберите оружие из списка для инкрустации</font></td></tr></table><img src=L2UI.SquareGray width=280 height=1><br1>");
		int row = 0;
		for (ItemInstance weapon : weapons.subList(page * PAGE_ROWS, Math.min(weapons.size(), (page + 1) * PAGE_ROWS)))
		{
			if (!AbstractRefinePacket.isValid(player, weapon, true))
				continue;
			String icon = ItemIconData.getInstance().getIcon(weapon.getItemId());
			html.append("<table width=280").append(row++ % 2 == 0 ? " bgcolor=000000" : "").append("><tr><td width=36 height=40 valign=middle><table cellpadding=0 cellspacing=0><tr><td height=4></td></tr><tr><td><button value=\"\" action=\"bypass -h ls_select ").append(weapon.getObjectId()).append("\" width=32 height=32 back=\"").append(icon).append("\" fore=\"").append(icon).append("\"></td></tr><tr><td height=4></td></tr></table></td><td width=244 valign=middle>").append(displayName(weapon)).append("<br1><font color=B09878>Стоимость: ").append(escape(costText(weapon))).append("</font></td></tr></table>");
		}
		if (row == 0) html.append("<br>Нет подходящего оружия C–S ранга.");
		html.append("<img src=L2UI.SquareGray width=280 height=1>").append(navigation(page, pages));
		int filler = 410 - 32 - 22 - row * 40;
		if (filler > 0) html.append("<img height=").append(filler).append(">");
		html.append("</body></html>");
		NpcHtmlMessage packet = new NpcHtmlMessage(0);
		packet.setHtml(html.toString());
		player.sendPacket(packet);
	}

	public static synchronized void page(Player player, String command)
	{
		Request request = REQUESTS.get(player);
		if (!Config.LIFE_STONE_WINDOW || request == null || request.expires() < System.currentTimeMillis())
		{
			player.sendMessage("Инкрустация недоступна: откройте предмет в инвентаре заново.");
			return;
		}
		ItemInstance stone = player.getInventory().getItemByObjectId(request.stone());
		if (stone == null) { player.sendMessage("Инкрустация невозможна: выбранный предмет отсутствует в инвентаре."); return; }
		try { showPage(player, stone, Integer.parseInt(command.substring(8))); }
		catch (NumberFormatException e) { return; }
	}

	private static String navigation(int page, int pages)
	{
		int first = Math.max(0, page - 3);
		int last = Math.min(pages, first + 7);
		first = Math.max(0, last - 7);
		StringBuilder html = new StringBuilder("<table width=280><tr><td width=28></td>");
		if (page > 0) html.append(pageLink(page - 1, "&lt;&lt;"));
		for (int i = first; i < last; i++)
			html.append(i == page ? "<td width=28 height=22 align=center><font color=LEVEL>" + (i + 1) + "</font></td>" : pageLink(i, String.valueOf(i + 1)));
		if (page + 1 < pages) html.append(pageLink(page + 1, "&gt;&gt;"));
		return html.append("</tr></table>").toString();
	}

	private static String pageLink(int page, String label)
	{
		return "<td width=28 height=22 align=center><a action=\"bypass -h ls_page " + page + "\">" + label + "</a></td>";
	}

	public static synchronized void select(Player player, String command)
	{
		Request request = REQUESTS.get(player);
		if (!Config.LIFE_STONE_WINDOW || request == null || request.expires() < System.currentTimeMillis())
			return;
		int id;
		try { id = Integer.parseInt(command.substring(10)); }
		catch (NumberFormatException e) { return; }
		ItemInstance weapon = player.getInventory().getItemByObjectId(id);
		if (!AbstractRefinePacket.isValid(player, weapon, true))
			return;
		int token = ThreadLocalRandom.current().nextInt(1, Integer.MAX_VALUE);
		REQUESTS.put(player, new Request(request.stone(), id, token, System.currentTimeMillis() + 15000));
		ItemInstance stone = player.getInventory().getItemByObjectId(request.stone());
		if (stone == null) { player.sendMessage("Инкрустация невозможна: выбранный предмет отсутствует в инвентаре."); return; }
		player.sendPacket(new ConfirmDlg(614).addString("Подтвердить инкрустацию " + stone.getItem().getName() + " в " + weapon.getItem().getName() + "? Стоимость: " + costText(weapon) + (weapon.isAugmented() ? ". Текущая инкрустация будет заменена" : "")).addTime(15000).addRequesterId(token));
	}

	public static synchronized void answer(Player player, int answer, int token)
	{
		Request request = REQUESTS.get(player);
		if (request == null || request.token() == 0 || (token != 0 && request.token() != token))
			return;
		REQUESTS.remove(player);
		if (answer != 1) return;
		if (!Config.LIFE_STONE_WINDOW || request.expires() < System.currentTimeMillis())
		{
			player.sendMessage("Инкрустация отменена: время подтверждения истекло или функция отключена.");
			return;
		}
		synchronized (player.getInventory())
		{
			ItemInstance stone = player.getInventory().getItemByObjectId(request.stone());
			ItemInstance weapon = player.getInventory().getItemByObjectId(request.weapon());
			if (stone == null || !AbstractRefinePacket.isValid(player, weapon, true) || player.isItemDisabled(stone) || player.isItemDisabled(weapon))
			{
				player.sendMessage("Инкрустация невозможна: выбранный предмет или оружие недоступны. Откройте окно заново.");
				return;
			}
			var ls = AbstractRefinePacket.getLifeStone(stone.getItemId());
			if (ls == null) { player.sendMessage("Инкрустация невозможна: неподходящий предмет " + stone.getItem().getName() + "."); return; }
			if (player.getStatus().getLevel() < ls.getPlayerLevel())
			{
				player.sendMessage("Инкрустация " + stone.getItem().getName() + " невозможна: требуется уровень " + ls.getPlayerLevel() + ".");
				return;
			}
			var grade = weapon.getItem().getCrystalType();
			if (player.getInventory().getItemCount(grade.getGemstoneId()) < grade.getGemstoneCount())
			{
				player.sendMessage("Инкрустация " + stone.getItem().getName() + " невозможна: недостаточно материалов. Требуется " + costText(weapon));
				return;
			}
			var augmentation = AugmentationData.getInstance().generateRandomAugmentation(ls.level(), ls.grade());
			if (!player.destroyItem(stone, 1, false))
			{
				player.sendMessage("Инкрустация невозможна: не удалось изъять " + stone.getItem().getName() + ".");
				return;
			}
			if (!player.destroyItemByItemId(grade.getGemstoneId(), grade.getGemstoneCount(), false))
			{
				player.addItem(stone.getItemId(), 1, false);
				player.sendMessage("Инкрустация отменена: не удалось списать материалы. Выбранный предмет возвращён.");
				return;
			}
			if (weapon.isAugmented())
			{
				if (weapon.isEquipped()) weapon.getAugmentation().removeBonus(player);
				weapon.removeAugmentation(player);
			}
			weapon.setAugmentation(augmentation, player);
			if (weapon.isEquipped()) augmentation.applyBonus(player);
			player.getShortcutList().refreshShortcuts(s -> s.getId() == weapon.getObjectId() && s.getType() == ShortcutType.ITEM);
			player.sendIU();
			player.broadcastUserInfo();
			player.sendMessage("Инкрустация выполнена: " + stone.getItem().getName() + " инкрустирован в " + weapon.getItem().getName() + ".");
		}
	}

	private static String displayName(ItemInstance weapon)
	{
		String name = weapon.getItem().getName();
		int split = name.indexOf(" - ");
		String title = split < 0 ? "" : " <font color=LEVEL>" + escape(name.substring(split + 3)) + "</font>";
		if (split >= 0) name = name.substring(0, split);
		return (weapon.getEnchantLevel() > 0 ? "<font color=B09878>+" + weapon.getEnchantLevel() + "</font> " : "") + (weapon.isAugmented() ? "Augmented " : "") + escape(name) + title;
	}

	private static String costText(ItemInstance weapon)
	{
		var grade = weapon.getItem().getCrystalType();
		var template = ItemData.getInstance().getTemplate(grade.getGemstoneId());
		return grade.getGemstoneCount() + " x " + (template == null ? "Gemstone" : template.getName());
	}

	private static String escape(String text)
	{
		return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
	}
}
