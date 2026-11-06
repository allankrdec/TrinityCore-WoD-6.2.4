#!/bin/bash
# Runs once, when the database volume is empty.
set -euo pipefail
export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
load() {
  echo "import: $1 <- $2 ($(date +%T))"
  mysql -uroot --max_allowed_packet=128M --default-character-set=utf8 "$1" < "$2"
  echo "import: $1 done, tables=$(mysql -uroot -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$1'") ($(date +%T))"
}
load auth /import/repo/auth_database.sql
load characters /import/repo/characters_database.sql
load hotfixes /import/tdb/TDB_hotfixes_6.04_2016_04_11.sql
load world /import/tdb/TDB_world_6.04_2016_04_11.sql
echo "import: ALL DONE"
