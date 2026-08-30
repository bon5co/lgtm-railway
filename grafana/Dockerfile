FROM grafana/grafana-oss:13.0.2

USER root

RUN apk add --no-cache su-exec

COPY datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Literals a Railway template variable cannot carry: templateGenerate drops a
# literal defaultValue and republishes the variable as blank-and-required.
ENV GF_SECURITY_ADMIN_USER=admin \
    GF_USERS_ALLOW_SIGN_UP=false \
    GF_AUTH_ANONYMOUS_ENABLED=false \
    GF_DEFAULT_INSTANCE_NAME="Grafana on Railway" \
    GF_ANALYTICS_REPORTING_ENABLED=false \
    GF_ANALYTICS_CHECK_FOR_UPDATES=false \
    GF_PATHS_DATA=/var/lib/grafana \
    LOKI_URL=http://loki.railway.internal:3100 \
    PROMETHEUS_URL=http://prometheus.railway.internal:9090

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
