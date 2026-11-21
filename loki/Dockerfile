FROM grafana/loki:3.7.10

# grafana/loki:3.7.10 is distroless: the whole filesystem carries one binary at
# /usr/bin/loki and no shell, so there is no entrypoint script and no su-exec
# here. Railway mounts volumes owned by uid 0, and the upstream image runs as
# uid 10001, so the container runs as root instead -- Loki then creates its own
# directories under the mount on first boot.
USER root

COPY loki.yaml /etc/loki/loki.yaml

# Literals baked here rather than published as template variables, which
# templateGenerate would turn into blank required fields on the deploy form.
# -config.expand-env resolves them inside loki.yaml at startup.
ENV LOKI_RETENTION_PERIOD=744h \
    LOKI_INGESTION_RATE_MB=8 \
    LOKI_INGESTION_BURST_MB=16 \
    LOKI_LOG_LEVEL=info

EXPOSE 3100
ENTRYPOINT ["/usr/bin/loki", "-config.file=/etc/loki/loki.yaml", "-config.expand-env=true"]
