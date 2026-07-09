ARG ALPINE_VERSION=3.18
FROM alpine:${ALPINE_VERSION}

RUN apk --no-cache add \
    bash \
    curl \
    ca-certificates \
    docker-cli \
    jq \
 && curl -fsSL \
    https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
    -o /usr/local/bin/supercronic \
 && chmod +x /usr/local/bin/supercronic

WORKDIR /app

RUN addgroup -g 1000 app \
 && adduser -D -u 1000 -G app app

ENV \
  API_KEY_FILE="" \
  CRON_SCHEDULE="0 0 * * *" \
  ENABLE_ABUSEIPDB=true \
  ENABLE_BORESTAD=true \
  CONFIG_BY_ENV=true

COPY --chown=app:app . .
RUN chmod +x /app/entrypoint.sh \
 && chmod +x /app/import_*.sh

USER app

ENTRYPOINT ["/app/entrypoint.sh"]