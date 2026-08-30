#!/bin/sh
set -eu

DATA_DIR=/loki
OWNER="$(stat -c %u:%g "$DATA_DIR" 2>/dev/null || echo unknown)"
echo "[railway] ${DATA_DIR} owned by ${OWNER}"
if [ "$OWNER" != "10001:10001" ]; then
  # Railway mounts a volume owned by uid 0; the loki image runs as uid 10001.
  echo "[railway] repairing ownership to 10001:10001"
  chown -R 10001:10001 "$DATA_DIR"
fi
for d in chunks rules tsdb-index tsdb-cache compactor; do
  mkdir -p "$DATA_DIR/$d"
  chown 10001:10001 "$DATA_DIR/$d"
done

echo "[railway] loki retention=${LOKI_RETENTION_PERIOD} ingestion_rate_mb=${LOKI_INGESTION_RATE_MB} listening on 3100"
exec su-exec 10001:10001 /usr/bin/loki -config.file=/etc/loki/loki.yaml -config.expand-env=true "$@"
