package net.sf.l2j.gameserver.handler.admincommandhandlers;

import java.util.Comparator;
import java.util.List;

import net.sf.l2j.gameserver.data.EquipmentItemInfo;
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
			if (args.length == 1 || (args.length == 3 && args[1].equals("page")))
			{
				showList(admin, owner, args.length == 1 ? 0 : Integer.parseInt(args[2]));
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
		catch (NumberFormatException e)
		{
			admin.sendMessage("Enter a valid item ID, skill ID and level.");
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

	private static void showList(Player admin, Player owner, int requestedPage)
	{
		final List<ItemInstance> items = owner.getInventory().getItems().stream()
			.sorted(Comparator.comparing(ItemInstance::isEquipped).reversed().thenComparingInt(ItemInstance::getObjectId)).toList();
		final int last = Math.max(0, (items.size() - 1) / PAGE_SIZE);
		final int page = Math.clamp(requestedPage, 0, last);
		final StringBuilder html = new StringBuilder("<html><body><center>Equipment<br>");
		for (ItemInstance item : items.subList(page * PAGE_SIZE, Math.min(items.size(), (page + 1) * PAGE_SIZE)))
		{
			html.append("<a action=\"bypass -h admin_equipment ").append(item.getObjectId()).append("\">+")
				.append(item.getEnchantLevel()).append(' ').append(escape(item.getItem().getName())).append(" #")
				.append(item.getObjectId()).append("</a><br>");
		}
		if (page > 0)
			html.append("<a action=\"bypass -h admin_equipment page ").append(page - 1).append("\">Previous</a> ");
		if (page < last)
			html.append("<a action=\"bypass -h admin_equipment page ").append(page + 1).append("\">Next</a>");
		sendHtml(admin, html);
	}

	private static void showItem(Player admin, ItemInstance item)
	{
		final int id = item.getObjectId();
		final String command = "admin_equipment " + id;
		final StringBuilder html = new StringBuilder("<html><body><center>");
		html.append(escape(item.getItem().getName())).append(" #").append(id).append("<br>");
		if (!item.getInstanceTitle().isEmpty())
			html.append(escape(item.getInstanceTitle())).append("<br>");
		for (L2Skill skill : item.getEquipmentSkills())
		{
			html.append(escape(skill.getName())).append(" Lv. ").append(skill.getLevel())
				.append(" <a action=\"bypass -h ").append(command).append(" del ").append(skill.getId()).append("\">Remove</a><br>");
		}
		html.append("<table><tr><td>Title</td><td><edit var=\"title\" width=120></td></tr></table>");
		html.append("<a action=\"bypass -h ").append(command).append(" title $title\">Set title</a> ");
		html.append("<a action=\"bypass -h ").append(command).append(" cleartitle\">Reset title</a><br>");
		if (item.isEquipable())
		{
			html.append("<table><tr><td>Skill ID</td><td><edit var=\"sid\" width=65></td><td>Level</td><td><edit var=\"lvl\" width=35></td></tr></table>");
			html.append("<a action=\"bypass -h ").append(command).append(" add $sid $lvl\">Add skill</a><br>");
			html.append("<table><tr><td>RGB</td><td><edit var=\"rgb\" width=65></td></tr></table>");
			html.append("<a action=\"bypass -h ").append(command).append(" color $rgb\">Set color</a> ");
			html.append("<a action=\"bypass -h ").append(command).append(" color clear\">Reset color</a><br>");
			html.append("<table><tr><td>Enchant +").append(item.getEnchantLevel()).append("</td><td><edit var=\"ench\" width=45></td></tr></table>");
			html.append("<a action=\"bypass -h admin_enchant ").append(id).append(" $ench\">Set enchant</a><br>");
		}
		html.append("<a action=\"bypass -h admin_equipment\">Equipment list</a>");
		sendHtml(admin, html);
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
