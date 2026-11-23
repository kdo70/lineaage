package net.sf.l2j.gameserver.handler.admincommandhandlers;

import java.util.StringTokenizer;

import net.sf.l2j.gameserver.handler.IAdminCommandHandler;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.network.serverpackets.NpcHtmlMessage;

public class AdminTest implements IAdminCommandHandler
{
	private static final String[] ADMIN_COMMANDS =
	{
		"admin_test",
	};
	
	@Override
	public void useAdminCommand(String command, Player player)
	{
		final StringTokenizer st = new StringTokenizer(command);
		st.nextToken();
		
		if (!st.hasMoreTokens())
		{
			player.sendMessage("Usage : //test ...");
			return;
		}
		
		switch (st.nextToken())
		{
			case "dialog":
				try
				{
					final NpcHtmlMessage html = new NpcHtmlMessage(0);
					String size = "Standard";
					if (st.hasMoreTokens())
					{
						final String width = st.nextToken();
						if (!width.equals("default"))
						{
							final int w = Integer.parseInt(width);
							final int h = Integer.parseInt(st.nextToken());
							html.setWindowSize(w, h);
							size = w + " x " + h;
						}
					}
					final StringBuilder content = new StringBuilder("<html><body><center><font color=LEVEL>Dialog size test: " + size + "</font></center><br>");
					content.append("<a action=\"bypass -h admin_test dialog 800 600\">800 x 600</a><br>");
					content.append("<a action=\"bypass -h admin_test dialog 500 350\">500 x 350</a><br>");
					content.append("<a action=\"bypass -h admin_test dialog default\">Restore standard size</a><br>");
					for (int i = 1; i <= 40; i++)
						content.append("Scroll test row ").append(i).append("<br>");
					content.append("<a action=\"bypass -h admin_test dialog default\">Bottom link: restore standard size</a></body></html>");
					html.setHtml(content.toString());
					player.sendPacket(html);
				}
				catch (IllegalArgumentException | java.util.NoSuchElementException e)
				{
					player.sendMessage("Usage: //test dialog [default|width height]; width 200..1920, height 120..1080");
				}
				break;
			// Add your own cases.
			
			default:
				player.sendMessage("Usage : //test ...");
				break;
		}
	}
	
	@Override
	public String[] getAdminCommandList()
	{
		return ADMIN_COMMANDS;
	}
}
