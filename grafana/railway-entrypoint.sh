#!/bin/sh
set -eu

if [ -z "${GF_SECURITY_ADMIN_PASSWORD:-}" ]; then
  echo "[railway] GF_SECURITY_ADMIN_PASSWORD is empty. Refusing to start an" >&2
  echo "[railway] internet-facing Grafana with no admin credential." >&2
  exit 1
fi

# Railway routes the edge at the port it injects, and its HTTP healthcheck dials
# that same injected port, so the server must honour it.
export GF_SERVER_HTTP_PORT="${PORT:-3000}"

DATA_DIR="${GF_PATHS_DATA:-/var/lib/grafana}"
OWNER="$(stat -c %u:%g "$DATA_DIR" 2>/dev/null || echo unknown)"
echo "[railway] ${DATA_DIR} owned by ${OWNER}"
if [ "$OWNER" != "472:0" ]; then
  # Railway mounts a volume owned by uid 0; grafana runs as uid 472.
  echo "[railway] repairing ownership to 472:0"
  chown -R 472:0 "$DATA_DIR"
fi
chmod 0775 "$DATA_DIR"

echo "[railway] grafana listening on ${GF_SERVER_HTTP_PORT}, loki=${LOKI_URL:-unset} prometheus=${PROMETHEUS_URL:-unset}"
exec su-exec 472:0 /run.sh "$@"
