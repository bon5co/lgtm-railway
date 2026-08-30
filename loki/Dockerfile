FROM grafana/loki:3.7.7

USER root

RUN apk add --no-cache su-exec

COPY loki.yaml /etc/loki/loki.yaml
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Literals baked here rather than published as template variables, which
# templateGenerate would turn into blank required fields on the deploy form.
ENV LOKI_RETENTION_PERIOD=744h \
    LOKI_INGESTION_RATE_MB=8 \
    LOKI_INGESTION_BURST_MB=16 \
    LOKI_LOG_LEVEL=info

EXPOSE 3100
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
