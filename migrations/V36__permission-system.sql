CREATE TABLE `auth_permission` (
  `id` MEDIUMINT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL COMMENT 'e.g. gameban.create or gameban.delete',
  `create_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) )
COMMENT = 'List of all permissions, assigned over role assignments (auth_role_permission_assignments)';

CREATE TABLE `auth_role` (
  `id` MEDIUMINT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL COMMENT 'e.g. Admin, Mod',
  `level` MEDIUMINT(4) UNSIGNED COMMENT 'Level of this role for greater less comparison in server: Admin >= 999; Mod >= 500;',
  `create_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) )
COMMENT = 'List of all roles. Bunch of permissions form a role (see auth_role_permission_assignments) and are assigned over auth_user_role_assignment to a user';

CREATE TABLE `auth_role_permission_assignments` (
  `id` MEDIUMINT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id` MEDIUMINT(8) UNSIGNED NOT NULL,
  `permission_id` MEDIUMINT(8) UNSIGNED NOT NULL,
  `create_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`role_id`) REFERENCES `auth_role`(`id`),
  FOREIGN KEY (`permission_id`) REFERENCES `auth_permission`(`id`))
COMMENT = 'Connects roles (auth_role) and permissions (auth_role_permission_assignments)';

CREATE TABLE `auth_user_role_assignment` (
  `id` MEDIUMINT(8) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` MEDIUMINT(8) UNSIGNED NOT NULL,
  `role_id` MEDIUMINT(8) UNSIGNED NOT NULL,
  `create_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `login`(`id`),
  FOREIGN KEY (`role_id`) REFERENCES `auth_role`(`id`))
COMMENT = 'Assign users (login) to a role (a bunch of permissions)';

CREATE VIEW `auth_login` AS
    SELECT 
        `login`.`id` AS `login_id`,
        MAX(`auth_role`.`level`) AS `auth_level`
    FROM
        ((`login`
        LEFT JOIN `auth_user_role_assignment` ON ((`login`.`id` = `auth_user_role_assignment`.`user_id`)))
        LEFT JOIN `auth_role` ON ((`auth_user_role_assignment`.`role_id` = `auth_role`.`id`)))
    GROUP BY `login`.`id`;

# Backwards compatible to old `lobby_admin` table
# https://github.com/search?utf8=%E2%9C%93&q=org%3AFAForever+lobby_admin&type=Code

# https://github.com/FAForever/api/blob/2e51e0e26e49bf89454360c326cae212f7e9abe0/api/user.py#L7
INSERT INTO `auth_role` (`id`, `name`, `level`) VALUES
    (1, 'Moderator', 500),
    (2, 'Administrator', 999);

INSERT INTO `auth_user_role_assignment` (`user_id`, `role_id`) 
SELECT `user_id`, `group` FROM `lobby_admin`;

DROP TABLE `lobby_admin`;

CREATE VIEW `lobby_admin` AS
    SELECT 
        `auth_login`.`login_id` AS `user_id`,
        case 
          when `auth_login`.`auth_level` >= 999 then 2
          when `auth_login`.`auth_level` >= 500 then 1 
          else 0 
        end AS `group`
    FROM
        `auth_login`;
