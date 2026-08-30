# lgtm-railway

Wrapper images for a Loki + Prometheus + Grafana observability stack on
[Railway](https://railway.com), published as a one-click template.

Three images, all built by GitHub Actions and pushed to GHCR:

| image | upstream | pinned |
| --- | --- | --- |
| `ghcr.io/bon5co/lgtm-railway-grafana` | `grafana/grafana-oss` | `13.0.2` |
| `ghcr.io/bon5co/lgtm-railway-loki` | `grafana/loki` | `3.7.7` |
| `ghcr.io/bon5co/lgtm-railway-prometheus` | `prom/prometheus` | `v3.14.0` |

## Why these exist

Everything below was measured on a live Railway deploy of the leading
"Grafana Stack" template (template code `8TLSQD`) on 2026-08-31.

**Prometheus scrapes nothing but itself.** The competing templates bake
`prometheus.yml` into the image with every application target commented out,
and no environment variable reaches it — the live control reported exactly one
active target, `localhost:9090`, so adding your own service means forking their
repository and redeploying from the fork. Here the scrape list is
`PROMETHEUS_SCRAPE_TARGETS`, a comma-separated list of
`[job=]host:port[/path]` entries read at boot, so a target is a variable edit
and a restart. The stack's own Loki is scraped by default.

**Loki never deletes anything.** The control's running config reported
`compactor.retention_enabled: false` and `limits_config.retention_period: 0s`,
so log chunks accumulate until the Railway volume is full and ingestion stops.
This image ships a compactor with retention on and a default
`LOKI_RETENTION_PERIOD` of `744h` (31 days).

**Three services instead of four.** The competing stack also bills a Tempo,
which is only useful once an application is emitting OTLP traces.

**Pinned and prebuilt.** The competing services all deploy `latest` from a
GitHub source build, so each deploy spends the deployer's build minutes and can
silently move Grafana's SQLite schema and Loki's index schema forward.

**Grafana does not run as root.** Railway mounts volumes as uid 0 while
`grafana-oss` runs as uid 472; rather than setting `RAILWAY_RUN_UID=0`, the
entrypoint repairs the mount as root and then drops privileges with `su-exec`.
The same applies to Loki (uid 10001).

## Configuration

### grafana

| variable | default | meaning |
| --- | --- | --- |
| `GF_SECURITY_ADMIN_PASSWORD` | *(none — boot fails without it)* | admin password |
| `GF_SECURITY_ADMIN_USER` | `admin` | admin login |
| `LOKI_URL` | `http://loki.railway.internal:3100` | provisioned Loki datasource |
| `PROMETHEUS_URL` | `http://prometheus.railway.internal:9090` | provisioned Prometheus datasource |

Both datasources are provisioned with `access: proxy`, so queries are made by
the Grafana server over Railway's private network. Sign-up is disabled and
anonymous access is off.

### loki

| variable | default | meaning |
| --- | --- | --- |
| `LOKI_RETENTION_PERIOD` | `744h` | how long log chunks are kept |
| `LOKI_INGESTION_RATE_MB` | `8` | per-tenant ingest rate limit |
| `LOKI_INGESTION_BURST_MB` | `16` | per-tenant ingest burst |
| `LOKI_LOG_LEVEL` | `info` | Loki's own log level |

Single-binary mode, filesystem storage, TSDB schema v13, on a volume at `/loki`.

### prometheus

| variable | default | meaning |
| --- | --- | --- |
| `PROMETHEUS_SCRAPE_TARGETS` | *(empty)* | comma-separated `[job=]host:port[/path]` |
| `PROMETHEUS_SCRAPE_INTERVAL` | `15s` | global scrape interval |
| `PROMETHEUS_RETENTION_TIME` | `31d` | metric retention |
| `PROMETHEUS_RETENTION_SIZE` | `0` | size cap, `0` for none |

Example: `PROMETHEUS_SCRAPE_TARGETS=api=api.railway.internal:8080,https://example.com/metrics`

Data lives on a volume at `/prometheus`.

## Licence

The upstream projects are Apache-2.0 (Grafana OSS, Loki) and Apache-2.0
(Prometheus). Everything added here is provided under the same terms.
