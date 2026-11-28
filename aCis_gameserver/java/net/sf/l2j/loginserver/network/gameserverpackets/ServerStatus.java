package net.sf.l2j.loginserver.network.gameserverpackets;

import net.sf.l2j.commons.network.AttributeType;
import net.sf.l2j.commons.network.ServerType;

import net.sf.l2j.loginserver.data.manager.GameServerManager;
import net.sf.l2j.loginserver.model.GameServerInfo;
import net.sf.l2j.loginserver.network.clientpackets.ClientBasePacket;

public class ServerStatus extends ClientBasePacket
{
	private static final int ON = 0x01;
	
	public ServerStatus(byte[] decrypt, int serverId)
	{
		super(decrypt);
		
		GameServerInfo gsi = GameServerManager.getInstance().getRegisteredGameServers().get(serverId);
		if (gsi != null && decrypt.length >= 5)
		{
			final int size = readD();
			if (size < 0 || size > (decrypt.length - 5) / 8)
				return;

			for (int i = 0; i < size; i++)
			{
				int type = readD();
				int value = readD();
				
				if (type < 0 || type >= AttributeType.VALUES.length)
					continue;

				switch (AttributeType.VALUES[type])
				{
					case STATUS:
						if (value >= 0 && value < ServerType.VALUES.length)
							gsi.setType(ServerType.VALUES[value]);
						break;
					
					case CLOCK:
						gsi.setShowingClock(value == ON);
						break;
					
					case BRACKETS:
						gsi.setShowingBrackets(value == ON);
						break;
					
					case AGE_LIMIT:
						gsi.setAgeLimit(value);
						break;
					
					case TEST_SERVER:
						gsi.setTestServer(value == ON);
						break;
					
					case PVP_SERVER:
						gsi.setPvp(value == ON);
						break;
					
					case MAX_PLAYERS:
						gsi.setMaxPlayers(value);
						break;

					case SERVER_LIST_ACTIVITY:
						final int mode = value & 0x300;
						if (value == 0 || mode == 0x100 || mode == 0x200)
							gsi.setActivityFlags(value & 0x7fffff00);
						break;
				}
			}
		}
	}
}