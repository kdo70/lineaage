-- Run in one MariaDB connection with the game server stopped and a verified backup.
CREATE TEMPORARY TABLE retired_weapon (old_id INT PRIMARY KEY, new_id INT NULL);
INSERT INTO retired_weapon VALUES
(8576, NULL),
(8577, NULL),
(8578, NULL),
(8579, NULL),
(8580, NULL),
(8581, NULL),
(8582, NULL),
(8583, NULL),
(8584, NULL),
(8585, NULL),
(8586, NULL),
(8587, NULL),
(8588, NULL),
(8589, NULL),
(8590, NULL),
(8591, NULL),
(8763, NULL);

START TRANSACTION;
-- Cancel buy orders for retired templates rather than applying old prices to new items.
DELETE o FROM character_offline_trade_items o
JOIN character_offline_trade t ON t.charId=o.charId AND t.type=3
JOIN retired_weapon r ON r.old_id=o.item;
DELETE o FROM character_offline_trade_items o
JOIN character_offline_trade t ON t.charId=o.charId AND t.type IN (1,8)
JOIN items i ON i.object_id=o.item
JOIN retired_weapon r ON r.old_id=i.item_id;
DELETE a FROM augmentations a JOIN items i ON i.object_id=a.item_oid
JOIN retired_weapon r ON r.old_id=i.item_id WHERE r.new_id IS NULL;
DELETE s FROM character_shortcuts s JOIN items i ON i.object_id=s.id
JOIN retired_weapon r ON r.old_id=i.item_id WHERE s.type='ITEM' AND r.new_id IS NULL;
DELETE i FROM items i JOIN retired_weapon r ON r.old_id=i.item_id WHERE r.new_id IS NULL;
UPDATE items i JOIN retired_weapon r ON r.old_id=i.item_id
SET i.item_id=r.new_id WHERE r.new_id IS NOT NULL;
DELETE g FROM items_on_ground g JOIN retired_weapon r ON r.old_id=g.item_id WHERE r.new_id IS NULL;
UPDATE items_on_ground g JOIN retired_weapon r ON r.old_id=g.item_id
SET g.item_id=r.new_id WHERE r.new_id IS NOT NULL;
DELETE q FROM raid_hunt_rewards q JOIN retired_weapon r ON r.old_id=q.item_id WHERE r.new_id IS NULL;
UPDATE raid_hunt_rewards q JOIN retired_weapon r ON r.old_id=q.item_id
SET q.item_id=r.new_id WHERE r.new_id IS NOT NULL;
DELETE b FROM buylists b JOIN retired_weapon r ON r.old_id=b.item_id;
COMMIT;
DROP TEMPORARY TABLE retired_weapon;
