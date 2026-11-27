package net.sf.l2j.gameserver.data;

import java.sql.SQLException;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;

import net.sf.l2j.commons.pool.ConnectionPool;

import net.sf.l2j.gameserver.enums.SayType;
import net.sf.l2j.gameserver.model.actor.Player;
import net.sf.l2j.gameserver.model.item.instance.ItemInstance;
import net.sf.l2j.gameserver.network.serverpackets.CreatureSay;

public final class EquipmentItemInfo
{
	public static final String BYPASS = "_itemskills ";
	public static final String TAG = "~ik~";
	private static final DateTimeFormatter OWNERSHIP_DATE = DateTimeFormatter.ofPattern("dd.MM.uuuu").withZone(ZoneId.of("Asia/Tomsk"));

	public static void ensureSchema() throws SQLException
	{
		try (var connection = ConnectionPool.getConnection(); var statement = connection.createStatement())
		{
			for (String table : new String[] { "items", "items_on_ground" })
			{
				boolean hasSkills;
				boolean hasColor;
				try (var columns = connection.getMetaData().getColumns(connection.getCatalog(), null, table, "equipment_skills"))
				{
					hasSkills = columns.next();
				}
				try (var columns = connection.getMetaData().getColumns(connection.getCatalog(), null, table, "equipment_name_color"))
				{
					hasColor = columns.next();
				}
				if (!hasSkills)
					statement.executeUpdate("ALTER TABLE " + table + " ADD COLUMN equipment_skills VARCHAR(219) NOT NULL DEFAULT ''");
				if (!hasColor)
					statement.executeUpdate("ALTER TABLE " + table + " ADD COLUMN equipment_name_color INT NOT NULL DEFAULT -1");

				statement.executeUpdate("ALTER TABLE " + table
					+ " ADD COLUMN IF NOT EXISTS instance_title VARCHAR(32) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',"
					+ " ADD COLUMN IF NOT EXISTS first_owner_name VARCHAR(35) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',"
					+ " ADD COLUMN IF NOT EXISTS first_owned_at BIGINT NOT NULL DEFAULT 0");
			}
		}
	}

	public static void request(Player player, String selection)
	{
		if (player.getClient() == null)
			return;
		player.getClient().enableEquipmentInfo();
		if (selection.equals("i"))
		{
			player.sendPacket(new CreatureSay(0, SayType.ALL, "", TAG + "reset"));
			for (ItemInstance item : player.getInventory().getItems())
			{
				if (item.getEquipmentNameColor() >= 0 || !item.getEquipmentSkills().isEmpty() || !item.getInstanceTitle().isEmpty() || item.getFirstOwnership().timestamp() > 0)
					send(player, item);
			}
			return;
		}

		try
		{
			final int id = Integer.parseInt(selection);
			final ItemInstance item = player.getInventory().getItemByObjectId(id);
			if (item != null)
				send(player, item);
		}
		catch (NumberFormatException ignored)
		{
			// The client must supply a numeric instance ID.
		}
	}

	public static void send(Player player, ItemInstance item)
	{
		final var client = player.getClient();
		if (client == null || !client.hasRequestedEquipmentInfo())
			return;

		final int color = item.getEquipmentNameColor();
		final String rgb = color < 0 ? "n" : (color >> 16) + "-" + ((color >> 8) & 255) + "-" + (color & 255);
		final StringBuilder row = new StringBuilder(TAG).append(item.getObjectId()).append(',').append(rgb);
		final StringBuilder types = new StringBuilder();
		for (var skill : item.getEquipmentSkills())
		{
			row.append(',').append(skill.getId()).append('-').append(skill.getLevel());
			types.append(skill.isChance() ? 'c' : skill.isToggle() ? 't' : skill.isPassive() ? 'p' : skill.isActive() ? 'a' : 'o');
		}
		if (!types.isEmpty())
			row.append(",k").append(types);
		final String title = item.getInstanceTitle();
		if (!title.isEmpty())
			row.append(",t").append(encode(title));
		final var origin = item.getFirstOwnership();
		if (origin.timestamp() > 0 && !origin.name().isEmpty())
		{
			row.append(",c").append(encode(origin.name()));
			row.append(",d").append(OWNERSHIP_DATE.format(Instant.ofEpochMilli(origin.timestamp())));
		}
		player.sendPacket(new CreatureSay(0, SayType.ALL, "", row.toString()));
	}

	private static String encode(String value)
	{
		final StringBuilder result = new StringBuilder(value.length() * 4);
		for (int i = 0; i < value.length(); i++)
			result.append(HexFormat.of().toHexDigits(value.charAt(i)));
		return result.toString();
	}

	private EquipmentItemInfo()
	{
	}
}
