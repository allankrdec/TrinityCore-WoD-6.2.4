-- Same as sql/create/create_mysql.sql, but the servers connect from other containers.
CREATE USER 'trinity'@'%' IDENTIFIED BY 'trinity';
CREATE DATABASE `world` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE `characters` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE `auth` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE `hotfixes` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON `world`.* TO 'trinity'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON `characters`.* TO 'trinity'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON `auth`.* TO 'trinity'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON `hotfixes`.* TO 'trinity'@'%' WITH GRANT OPTION;
