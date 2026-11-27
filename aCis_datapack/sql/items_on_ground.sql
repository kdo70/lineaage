CREATE TABLE IF NOT EXISTS `items_on_ground` (
  `object_id` int(11) NOT NULL default '0',
  `item_id` int(11) default NULL,
  `count` int(11) default NULL,
  `enchant_level` int(11) default NULL,
  `x` int(11) default NULL,
  `y` int(11) default NULL,
  `z` int(11) default NULL,
  `time` decimal(20,0) default NULL,
  `equipment_skills` VARCHAR(219) NOT NULL DEFAULT '',
  `equipment_name_color` INT NOT NULL DEFAULT -1,
  `instance_title` VARCHAR(32) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',
  `first_owner_name` VARCHAR(35) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',
  `first_owned_at` BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY  (`object_id`)
);
