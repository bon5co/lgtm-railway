FROM prom/prometheus:v3.14.0

COPY railway-entrypoint.sh /etc/prometheus/railway-entrypoint.sh

# Literals baked here rather than published as template variables, which
# templateGenerate would turn into blank required fields on the deploy form.
ENV PROMETHEUS_SCRAPE_TARGETS="loki=loki.railway.internal:3100/metrics" \
    PROMETHEUS_SCRAPE_INTERVAL=15s \
    PROMETHEUS_RETENTION_TIME=31d \
    PROMETHEUS_RETENTION_SIZE=0

# Railway mounts the volume as uid 0 and this image runs as nobody, which cannot
# write it. Making root the last USER is the same fix RAILWAY_RUN_UID=0 buys,
# without publishing a variable that would land on the deploy form blank.
USER root

EXPOSE 9090
ENTRYPOINT ["/bin/sh", "/etc/prometheus/railway-entrypoint.sh"]
