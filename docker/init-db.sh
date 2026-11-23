#!/bin/bash
set -e
[[ "${GAME_HEX_ID:?}" =~ ^[a-f0-9]+$ ]] || exit 1
for sql in /seed/*.sql; do
  MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb --protocol=socket -uroot "$MARIADB_DATABASE" < "$sql"
done
MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb --protocol=socket -uroot "$MARIADB_DATABASE" <<SQL
INSERT INTO gameservers (server_id, hexid, host) VALUES (1, '$GAME_HEX_ID', 'game');
SQL
