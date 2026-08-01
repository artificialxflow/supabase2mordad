# All-in-one Supabase for Runflare (single Docker service)
# Public port: 8000 (nginx gateway -> auth/rest/studio)

# Use widely-available tags so Runflare can pull from Docker Hub
FROM supabase/gotrue:v2.151.0 AS gotrue
FROM postgrest/postgrest:v12.2.3 AS postgrest
FROM supabase/postgres-meta:v0.84.2 AS meta
FROM supabase/studio:latest AS studio

FROM supabase/postgres:15.8.1.060

USER root

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    gnupg \
    supervisor \
    nginx \
    xz-utils; \
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -; \
  apt-get install -y --no-install-recommends nodejs; \
  rm -rf /var/lib/apt/lists/*; \
  mkdir -p /var/log/supervisor /opt/studio /opt/postgres-meta

# GoTrue
COPY --from=gotrue /usr/local/bin/auth /usr/local/bin/auth
COPY --from=gotrue /usr/local/bin/gotrue /usr/local/bin/gotrue
COPY --from=gotrue /usr/local/etc/auth /usr/local/etc/auth
ENV GOTRUE_DB_MIGRATIONS_PATH=/usr/local/etc/auth/migrations

# PostgREST (static binary in official image)
COPY --from=postgrest /bin/postgrest /usr/local/bin/postgrest

# postgres-meta (Node app)
COPY --from=meta /usr/src/app /opt/postgres-meta

# Studio (Node/Next app)
COPY --from=studio /app /opt/studio

# Gateway + process manager
COPY volumes/api/nginx.conf /etc/nginx/nginx.conf
COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start-all.sh /start-all.sh

RUN chmod +x /start-all.sh /usr/local/bin/auth /usr/local/bin/postgrest \
  && ln -sf /usr/local/bin/auth /usr/local/bin/gotrue

ENV POSTGRES_HOST=127.0.0.1 \
    POSTGRES_PORT=5432 \
    POSTGRES_DB=postgres \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    PGRST_SERVER_HOST=127.0.0.1 \
    PGRST_SERVER_PORT=3001 \
    ENABLE_EMAIL_AUTOCONFIRM=true \
    SUPABASE_PUBLIC_URL=https://supabase.pasteur.plus \
    API_EXTERNAL_URL=https://supabase.pasteur.plus \
    SITE_URL=https://pasteur.plus

EXPOSE 8000

CMD ["/start-all.sh"]
