-- Default accounts. Change the passwords before exposing the server.
-- Login: admin@admin.com  Password: admin  GM level 3
SET NAMES utf8;
USE `auth`;
INSERT INTO `battlenet_accounts` (`id`, `email`, `sha_pass_hash`, `joindate`, `last_ip`, `failed_logins`, `locked`, `lock_country`, `last_login`, `online`, `locale`, `os`, `LastCharacterUndelete`) VALUES (1,'ADMIN@ADMIN.COM','8CF63C0A89B9D721F18FCBC09DA0C824AD561C77C7E5D9148AFCA927AB50457D','2026-11-06 12:47:12','127.0.0.1',0,0,'00','0000-00-00 00:00:00',0,0,'',0);
INSERT INTO `account` (`id`, `username`, `sha_pass_hash`, `sessionkey`, `v`, `s`, `token_key`, `email`, `reg_mail`, `joindate`, `last_ip`, `last_attempt_ip`, `failed_logins`, `locked`, `lock_country`, `last_login`, `online`, `expansion`, `mutetime`, `mutereason`, `muteby`, `locale`, `os`, `recruiter`, `battlenet_account`, `battlenet_index`) VALUES (1,'1#1','9032DE789F22E272A2C6EF687559A27B8319C58A','','','','','ADMIN@ADMIN.COM','ADMIN@ADMIN.COM','2026-11-06 12:47:12','127.0.0.1','127.0.0.1',0,0,'00','0000-00-00 00:00:00',0,5,0,'','',0,'',0,1,1);
INSERT INTO `account_access` (`id`, `gmlevel`, `RealmID`) VALUES (1,3,-1);
