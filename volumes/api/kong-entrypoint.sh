#!/bin/sh
set -e

CONFIG_OUT="${KONG_DECLARATIVE_CONFIG:-/var/lib/kong/kong.yml}"
mkdir -p "$(dirname "$CONFIG_OUT")"

awk '{
  result = ""
  rest = $0
  while (match(rest, /\$[A-Za-z_][A-Za-z_0-9]*/)) {
    varname = substr(rest, RSTART + 1, RLENGTH - 1)
    if (varname in ENVIRON) {
      result = result substr(rest, 1, RSTART - 1) ENVIRON[varname]
    } else {
      result = result substr(rest, 1, RSTART + RLENGTH - 1)
    }
    rest = substr(rest, RSTART + RLENGTH)
  }
  print result rest
}' /home/kong/temp.yml > "$CONFIG_OUT"

if [ -x /docker-entrypoint.sh ]; then
  exec /docker-entrypoint.sh kong docker-start
fi
if [ -x /entrypoint.sh ]; then
  exec /entrypoint.sh kong docker-start
fi
exec kong docker-start
