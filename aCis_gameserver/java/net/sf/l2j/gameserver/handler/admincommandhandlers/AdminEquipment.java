package net.sf.l2j.gameserver.handler.admincommandhandlers;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

import net.sf.l2j.gameserver.data.EquipmentItemInfo;
import net.sf.l2j.gameserver.data.xml.ItemIconData;
import net.sf.l2j.gameserver.handler.IAdminCommandHandler;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.model.item.instance.ItemInstance;
import net.sf.l2j.gameserver.network.serverpackets.NpcHtmlMessage;
import net.sf.l2j.gameserver.skills.L2Skill;

public class AdminEquipment implements IAdminCommandHandler
{
	private static final int PAGE_SIZE = 8;

	@Override
	public String[] getAdminCommandList()
	{
		return new String[] { "admin_equipment" };
	}

	@Override
	public void useAdminCommand(String command, Player admin)
	{
		final Player owner = getTargetPlayer(admin, true);
		final String[] args = command.split(" +");
		try
		{
			if (args.length == 1 || args[1].equals("search"))
			{
				final String query = args.length < 3 ? "" : command.split(" +", 3)[2].strip();
				showList(admin, owner, 0, query);
				return;
			}
			if (args[1].equals("page") && (args.length == 3 || args.length == 4))
			{
				final String query = args.length == 3 ? "" : new String(Base64.getUrlDecoder().decode(args[3]), StandardCharsets.UTF_8);
				showList(admin, owner, Integer.parseInt(args[2]), query);
				return;
			}

			final ItemInstance item = owner.getInventory().getItemByObjectId(Integer.parseInt(args[1]));
			if (item == null)
			{
				admin.sendMessage("Equipment is no longer in the selected inventory.");
				return;
			}
			synchronized (item)
			{
				if (item.getOwnerId() != owner.getObjectId() || owner.getInventory().getItemByObjectId(item.getObjectId()) != item)
				{
					admin.sendMessage("Equipment is no longer in the selected inventory.");
					return;
				}

				if (args.length > 2)
				{
					final boolean changed = switch (args[2])
					{
						case "add" -> args.length == 5 && Integer.parseInt(args[4]) > 0 && item.setEquipmentSkill(Integer.parseInt(args[3]), Integer.parseInt(args[4]));
						case "del" -> args.length == 4 && item.setEquipmentSkill(Integer.parseInt(args[3]), 0);
						case "color" -> item.isEquipable() && args.length == 4 && setColor(item, args[3]);
						case "title" -> args.length >= 4 && item.setInstanceTitle(String.join(" ", java.util.Arrays.copyOfRange(args, 3, args.length)));
						case "cleartitle" -> args.length == 3 && item.setInstanceTitle("");
						default -> false;
					};
					if (changed)
					{
						if (item.isEquipped())
							owner.refreshEquipmentSkills();
						EquipmentItemInfo.send(owner, item);
					}
					else
						admin.sendMessage("Invalid value or equipment skill limit reached.");
				}
				showItem(admin, item);
			}
		}
		catch (IllegalArgumentException e)
		{
			admin.sendMessage("Invalid page, search, item ID, skill ID or level.");
		}
	}

	private static boolean setColor(ItemInstance item, String value)
	{
		if (value.equals("clear"))
			item.setEquipmentNameColor(-1);
		else if (value.matches("[0-9a-fA-F]{6}"))
			item.setEquipmentNameColor(Integer.parseInt(value, 16));
		else
			return false;
		return true;
	}

	private static void showList(Player admin, Player owner, int requestedPage, String query)
	{
		if (query.length() > 64)
		{
			admin.sendMessage("Search is limited to 64 characters.");
			return;
		}
		final String nameQuery = query.toLowerCase(Locale.ROOT);
		final List<ItemInstance> items = owner.getInventory().getItems().stream()
			.filter(item -> query.isEmpty() || item.getItem().getName().toLowerCase(Locale.ROOT).contains(nameQuery)
				|| query.equals(Integer.toString(item.getItemId())) || query.equals(Integer.toString(item.getObjectId())))
			.sorted(Comparator.comparing(ItemInstance::isEquipped).reversed().thenComparingInt(ItemInstance::getObjectId)).toList();
		final int last = Math.max(0, (items.size() - 1) / PAGE_SIZE);
		final int page = Math.clamp(requestedPage, 0, last);
		final String pageSuffix = query.isEmpty() ? "" : " " + Base64.getUrlEncoder().withoutPadding().encodeToString(query.getBytes(StandardCharsets.UTF_8));
		final StringBuilder html = new StringBuilder("<html><body><center><font color=LEVEL>Equipment</font> - ")
			.append(escape(owner.getName())).append("<br><table width=268><tr><td width=155><edit var=\"query\" width=145></td><td>");
		link(html, "admin_equipment search $query", "Search");
		html.append("</td><td>");
		link(html, "admin_equipment", "Reset");
		html.append("</td></tr></table>");
		if (!query.isEmpty())
			html.append("Search: ").append(escape(query)).append("<br>");
		html.append("<table width=268><tr><td height=6></td></tr></table>");
		html.append("<table width=268><tr><td width=70>");
		if (page > 0)
			link(html, "admin_equipment page " + (page - 1) + pageSuffix, "Previous");
		html.append("</td><td width=128 align=center>").append(page + 1).append(" / ").append(last + 1)
			.append(" (").append(items.size()).append(" items)</td><td width=70 align=right>");
		if (page < last)
			link(html, "admin_equipment page " + (page + 1) + pageSuffix, "Next");
		html.append("</td></tr></table>");
		if (items.isEmpty())
			html.append(query.isEmpty() ? "Inventory is empty." : "No matching items.");

		html.append("<table width=268>");
		for (ItemInstance item : items.subList(page * PAGE_SIZE, Math.min(items.size(), (page + 1) * PAGE_SIZE)))
		{
			html.append("<tr><td width=30 height=35>");
			appendIcon(html, item);
			html.append("</td><td width=238>");
			link(html, "admin_equipment " + item.getObjectId(), itemName(item));
			final String title = item.getInstanceTitle();
			if (!title.isEmpty())
				html.append("<font color=LEVEL>&nbsp;").append(escape(title)).append("</font>");
			html.append("<br1><font color=AAAAAA>ID ").append(item.getItemId()).append(" / #").append(item.getObjectId())
				.append(" | x").append(item.getCount()).append("</font>");
			if (item.isEquipped())
				html.append(" <font color=LEVEL>Equipped</font>");
			html.append("</td></tr>");
		}
		html.append("</table>");
		sendHtml(admin, html);
	}

	private static void showItem(Player admin, ItemInstance item)
	{
		final int id = item.getObjectId();
		final String command = "admin_equipment " + id;
		final StringBuilder html = new StringBuilder("<html><body><center>");
		link(html, "admin_equipment", "Back to equipment");
		html.append("<table width=268><tr><td width=36><img src=\"")
			.append(ItemIconData.getInstance().getIcon(item.getItemId())).append("\" width=32 height=32></td>")
			.append("<td width=232><font color=LEVEL>").append(itemName(item)).append("</font><br1>ID ")
			.append(item.getItemId()).append(" / #").append(id);
		final String title = item.getInstanceTitle();
		if (!title.isEmpty())
			html.append("<br1>Title: ").append(escape(title));
		final int color = item.getEquipmentNameColor();
		if (item.isEquipable() && color >= 0)
			html.append("<br1>RGB: ").append(String.format(Locale.ROOT, "%06X", color));
		html.append("</td></tr></table><br1>");

		html.append("<table width=268><tr><td width=55 height=24>Title</td><td width=120><edit var=\"title\" width=110></td><td width=40>");
		link(html, command + " title $title", "Set");
		html.append("</td><td width=53>");
		link(html, command + " cleartitle", "Reset");
		html.append("</td></tr>");
		if (item.isEquipable())
		{
			html.append("<tr><td height=24>RGB</td><td><edit var=\"rgb\" width=110></td><td>");
			link(html, command + " color $rgb", "Set");
			html.append("</td><td>");
			link(html, command + " color clear", "Reset");
			html.append("</td></tr><tr><td height=24>Enchant</td><td><edit var=\"ench\" width=110></td><td>");
			link(html, "admin_enchant " + id + " $ench", "Set");
			html.append("</td><td></td></tr>");
		}
		html.append("</table>");
		if (item.isEquipable())
		{
			html.append("<br1><table width=268><tr><td width=55 height=24>Skill ID</td><td width=57><edit var=\"sid\" width=54></td>")
				.append("<td width=23>Lv.</td><td width=40><edit var=\"lvl\" width=36></td><td width=93>");
			link(html, command + " add $sid $lvl", "Apply");
			html.append("</td></tr></table>");
		}
		html.append("<table width=268>");
		for (L2Skill skill : item.getEquipmentSkills())
		{
			html.append("<tr><td width=175 height=17>").append(escape(skill.getName())).append(" Lv. ").append(skill.getLevel())
				.append("</td><td width=93>");
			link(html, command + " del " + skill.getId(), "Remove");
			html.append("</td></tr>");
		}
		html.append("</table>");
		sendHtml(admin, html);
	}

	private static void appendIcon(StringBuilder html, ItemInstance item)
	{
		html.append("<img src=\"").append(ItemIconData.getInstance().getIcon(item.getItemId())).append("\" width=24 height=24>");
	}

	private static String itemName(ItemInstance item)
	{
		final int enchant = item.getEnchantLevel();
		return (enchant > 0 ? "+" + enchant + " " : "") + escape(item.getItem().getName());
	}

	private static void link(StringBuilder html, String command, String label)
	{
		html.append("<a action=\"bypass -h ").append(command).append("\">").append(label).append("</a>");
	}

	private static String escape(String value)
	{
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}

	private static void sendHtml(Player admin, StringBuilder html)
	{
		final NpcHtmlMessage packet = new NpcHtmlMessage(0);
		packet.setHtml(html.append("</center></body></html>").toString());
		admin.sendPacket(packet);
	}
}
