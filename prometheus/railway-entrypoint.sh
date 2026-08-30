#!/bin/sh
set -eu

DATA_DIR=/prometheus
OWNER="$(stat -c %u:%g "$DATA_DIR" 2>/dev/null || echo unknown)"
echo "[railway] ${DATA_DIR} owned by ${OWNER}"
mkdir -p "$DATA_DIR"

CONF=/etc/prometheus/prometheus.yml
cat > "$CONF" <<CONFHEAD
global:
  scrape_interval: ${PROMETHEUS_SCRAPE_INTERVAL}
  evaluation_interval: ${PROMETHEUS_SCRAPE_INTERVAL}

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['127.0.0.1:9090']
CONFHEAD

# PROMETHEUS_SCRAPE_TARGETS is a comma-separated list. Each entry is
#   [job=]host:port[/metrics_path]      scraped over http, or
#   [job=]https://host[:port][/path]    scraped over https.
# Upstream templates bake this list into a file inside the image, so adding your
# own application means forking their repository and redeploying from the fork.
count=0
OLDIFS=$IFS
IFS=,
for entry in ${PROMETHEUS_SCRAPE_TARGETS:-}; do
  IFS=$OLDIFS
  entry="$(echo "$entry" | tr -d ' ')"
  [ -n "$entry" ] || { IFS=,; continue; }

  job=""
  case "$entry" in
    *=*) job="${entry%%=*}"; entry="${entry#*=}" ;;
  esac

  scheme=http
  case "$entry" in
    https://*) scheme=https; entry="${entry#https://}" ;;
    http://*)  scheme=http;  entry="${entry#http://}" ;;
  esac

  path=/metrics
  case "$entry" in
    */*) path="/${entry#*/}"; entry="${entry%%/*}" ;;
  esac

  [ -n "$job" ] || job="$(echo "$entry" | tr ':.' '__')"
  count=$((count + 1))

  cat >> "$CONF" <<CONFTARGET
  - job_name: '${job}'
    scheme: ${scheme}
    metrics_path: '${path}'
    static_configs:
      - targets: ['${entry}']
CONFTARGET
  IFS=,
done
IFS=$OLDIFS

echo "[railway] prometheus config written with ${count} user target(s), retention=${PROMETHEUS_RETENTION_TIME}"

exec /bin/prometheus \
  --config.file="$CONF" \
  --storage.tsdb.path="$DATA_DIR" \
  --storage.tsdb.retention.time="${PROMETHEUS_RETENTION_TIME}" \
  --storage.tsdb.retention.size="${PROMETHEUS_RETENTION_SIZE}" \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle \
  "$@"
