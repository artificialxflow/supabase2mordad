#!/usr/bin/env bash
set -euo pipefail

echo "========== SUPABASE ALL-IN-ONE START =========="
echo "[start] time=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${JWT_SECRET:?JWT_SECRET is required}"
: "${ANON_KEY:?ANON_KEY is required}"
: "${SERVICE_ROLE_KEY:?SERVICE_ROLE_KEY is required}"
: "${PG_META_CRYPTO_KEY:?PG_META_CRYPTO_KEY is required}"

export POSTGRES_DB="${POSTGRES_DB:-postgres}"
export POSTGRES_HOST="${POSTGRES_HOST:-127.0.0.1}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export JWT_EXPIRY="${JWT_EXPIRY:-3600}"
export SUPABASE_PUBLIC_URL="${SUPABASE_PUBLIC_URL:-https://supabase.pasteur.plus}"
export API_EXTERNAL_URL="${API_EXTERNAL_URL:-$SUPABASE_PUBLIC_URL}"
export SITE_URL="${SITE_URL:-https://pasteur.plus}"
export ADDITIONAL_REDIRECT_URLS="${ADDITIONAL_REDIRECT_URLS:-https://pasteur.plus/**}"
export ENABLE_EMAIL_AUTOCONFIRM="${ENABLE_EMAIL_AUTOCONFIRM:-true}"
export DISABLE_SIGNUP="${DISABLE_SIGNUP:-false}"
export PGRST_DB_SCHEMAS="${PGRST_DB_SCHEMAS:-public,storage,graphql_public}"
export HOSTNAME="${HOSTNAME:-0.0.0.0}"

# Auth
export GOTRUE_API_HOST=0.0.0.0
export GOTRUE_API_PORT=9999
export GOTRUE_DB_DRIVER=postgres
export GOTRUE_DB_DATABASE_URL="postgres://supabase_auth_admin:${POSTGRES_PASSWORD}@127.0.0.1:5432/${POSTGRES_DB}"
export GOTRUE_SITE_URL="$SITE_URL"
export GOTRUE_URI_ALLOW_LIST="$ADDITIONAL_REDIRECT_URLS"
export GOTRUE_DISABLE_SIGNUP="$DISABLE_SIGNUP"
export GOTRUE_JWT_ADMIN_ROLES=service_role
export GOTRUE_JWT_AUD=authenticated
export GOTRUE_JWT_DEFAULT_GROUP_NAME=authenticated
export GOTRUE_JWT_EXP="$JWT_EXPIRY"
export GOTRUE_JWT_SECRET="$JWT_SECRET"
export GOTRUE_EXTERNAL_EMAIL_ENABLED=true
export GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=false
export GOTRUE_MAILER_AUTOCONFIRM="$ENABLE_EMAIL_AUTOCONFIRM"
export GOTRUE_MAILER_URLPATHS_INVITE=/auth/v1/verify
export GOTRUE_MAILER_URLPATHS_CONFIRMATION=/auth/v1/verify
export GOTRUE_MAILER_URLPATHS_RECOVERY=/auth/v1/verify
export GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE=/auth/v1/verify

# PostgREST on 3001 (Studio uses 3000)
export PGRST_DB_URI="postgres://authenticator:${POSTGRES_PASSWORD}@127.0.0.1:5432/${POSTGRES_DB}"
export PGRST_DB_ANON_ROLE=anon
export PGRST_DB_SCHEMAS="$PGRST_DB_SCHEMAS"
export PGRST_JWT_SECRET="$JWT_SECRET"
export PGRST_DB_USE_LEGACY_GUCS=false
export PGRST_SERVER_HOST=127.0.0.1
export PGRST_SERVER_PORT=3001
export PGRST_APP_SETTINGS_JWT_SECRET="$JWT_SECRET"
export PGRST_APP_SETTINGS_JWT_EXP="$JWT_EXPIRY"

# Meta
export PG_META_PORT=8080
export PG_META_DB_HOST=127.0.0.1
export PG_META_DB_PORT=5432
export PG_META_DB_NAME="$POSTGRES_DB"
export PG_META_DB_USER=supabase_admin
export PG_META_DB_PASSWORD="$POSTGRES_PASSWORD"
export CRYPTO_KEY="$PG_META_CRYPTO_KEY"

# Studio
export STUDIO_PG_META_URL=http://127.0.0.1:8080
export SUPABASE_URL=http://127.0.0.1:8000
export SUPABASE_PUBLIC_URL
export SUPABASE_ANON_KEY="$ANON_KEY"
export SUPABASE_SERVICE_KEY="$SERVICE_ROLE_KEY"
export AUTH_JWT_SECRET="$JWT_SECRET"
export PORT=3000
export SNIPPETS_MANAGEMENT_FOLDER=/tmp/snippets

echo "[start] SUPABASE_PUBLIC_URL=$SUPABASE_PUBLIC_URL"
echo "[start] API_EXTERNAL_URL=$API_EXTERNAL_URL"
echo "[start] SITE_URL=$SITE_URL"
echo "[start] Public gateway port: 8000"

PG_ENTRYPOINT=""
for candidate in \
  /usr/local/bin/docker-entrypoint.sh \
  /docker-entrypoint.sh \
  docker-entrypoint.sh
do
  if command -v "$candidate" >/dev/null 2>&1 || [ -x "$candidate" ]; then
    PG_ENTRYPOINT="$candidate"
    break
  fi
done

if [ -z "$PG_ENTRYPOINT" ]; then
  echo "[start] ERROR: postgres docker-entrypoint.sh not found"
  ls -la /usr/local/bin/ / 2>/dev/null || true
  exit 1
fi

echo "[start] Using postgres entrypoint: $PG_ENTRYPOINT"
echo "[start] Starting Postgres..."
"$PG_ENTRYPOINT" postgres \
  -c config_file=/etc/postgresql/postgresql.conf \
  -c log_min_messages=fatal &
PG_PID=$!

echo "[start] Waiting for Postgres..."
for i in $(seq 1 90); do
  if pg_isready -U postgres -h 127.0.0.1 >/dev/null 2>&1; then
    echo "[start] Postgres is ready (attempt $i)"
    break
  fi
  if ! kill -0 "$PG_PID" 2>/dev/null; then
    echo "[start] Postgres process died"
    exit 1
  fi
  sleep 2
done

if ! pg_isready -U postgres -h 127.0.0.1 >/dev/null 2>&1; then
  echo "[start] Postgres did not become ready in time"
  exit 1
fi

# Give roles/migrations a moment on first boot
sleep 5

echo "[start] Launching supervisord (auth/rest/meta/studio/nginx)..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
