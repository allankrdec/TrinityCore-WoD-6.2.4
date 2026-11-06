#!/bin/sh
# Waits for the database, applies SERVER_IP, then starts bnetserver or worldserver.
set -eu

server="$1"
export MYSQL_PWD=trinity

until mysql -h db -u trinity -e "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done

mysql -h db -u trinity auth -e \
  "UPDATE realmlist SET address='${SERVER_IP}', localAddress='${SERVER_IP}' WHERE id=1;"

conf="/tmp/${server}.conf"
sed -E "s/^LoginREST\.(External|Local)Address *=.*/LoginREST.\1Address=${SERVER_IP}/" \
  "/app/etc/${server}.conf" > "$conf"

exec "/app/bin/${server}" -c "$conf"
