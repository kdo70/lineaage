#!/bin/bash
set -euo pipefail
: "${DB_PASSWORD:?}" "${GAME_HEX_ID:?}"
[[ "$DB_PASSWORD" =~ ^[a-f0-9]+$ && "$GAME_HEX_ID" =~ ^[a-f0-9]+$ ]] || exit 1
case "${SERVER_ROLE:?}" in
  login) main=net.sf.l2j.loginserver.LoginServer; cfg=loginserver.properties ;;
  gameserver) main=net.sf.l2j.gameserver.GameServer; cfg=server.properties ;;
  *) exit 1 ;;
esac
cd "/server/$SERVER_ROLE"
sed -i -E \
  -e 's|^URL[[:space:]]*=.*|URL = jdbc:mariadb://db:3306/acis|' \
  -e 's/^Login[[:space:]]*=.*/Login = acis/' \
  -e "s/^Password[[:space:]]*=.*/Password = $DB_PASSWORD/" \
  -e 's/^Hostname[[:space:]]*=.*/Hostname = 127.0.0.1/' \
  "config/$cfg"
if [[ "$SERVER_ROLE" == gameserver ]]; then
  sed -i -E 's/^GeoDataType[[:space:]]*=.*/GeoDataType = L2J/' config/geoengine.properties
  sed -i -E 's/^GeoDataType[[:space:]]*=.*/GeoDataType = L2J/' config/geoengine.properties
  sed -i -E -e 's/^LoginHost[[:space:]]*=.*/LoginHost = login/' config/server.properties
  printf 'ServerID=1\nHexID=%s\n' "$GAME_HEX_ID" > config/hexid.txt
fi
exec java -cp 'libs/*' "$main"
