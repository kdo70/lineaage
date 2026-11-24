CREATE TABLE IF NOT EXISTS `character_raid_hunt` (
  `char_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `boss_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `kills` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`char_id`,`boss_id`)
);

CREATE TABLE IF NOT EXISTS `raid_hunt_history` (
  `boss_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `char_name` VARCHAR(35) NOT NULL DEFAULT '',
  `clan_name` VARCHAR(45) NOT NULL DEFAULT '',
  `kill_time` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  KEY `boss_time` (`boss_id`,`kill_time`)
);

CREATE TABLE IF NOT EXISTS `raid_hunt_rewards` (
  `char_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `place` INT UNSIGNED NOT NULL DEFAULT 0,
  `item_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `count` INT UNSIGNED NOT NULL DEFAULT 0,
  `kind` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  KEY `char_id` (`char_id`)
);

-- "kind" tells the daily ladder rewards (0) from the monthly ones (1) : the only thing which differs
-- once the reward is stored is the message its winner is told about it.
-- On a server which already holds this table, add it with :
-- ALTER TABLE `raid_hunt_rewards` ADD COLUMN `kind` TINYINT UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `raid_hunt_monthly_wins` (
  `char_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `wins` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`char_id`)
);

-- How many times a character took the first place of the daily ladder since the last monthly reward.
-- It is what the monthly ladder is sorted on, and it is wiped the moment the monthly rewards are
-- handed out - the month starts over from an empty board.
