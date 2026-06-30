#!/usr/bin/env bash
# Provision the Gastown service account in Gitea (user, token, org).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${ENV_FILE:-.env}"
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

COMPOSE="${COMPOSE:-docker compose}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
DC="$COMPOSE --env-file $ENV_FILE -f $COMPOSE_FILE"

GASTOWN_GIT_USER="${GASTOWN_GIT_USER:-gastown}"
GASTOWN_GIT_EMAIL="${GASTOWN_GIT_EMAIL:-gastown@localhost}"
GASTOWN_GIT_PASSWORD="${GASTOWN_GIT_PASSWORD:-}"
GASTOWN_ORG="${GASTOWN_ORG:-projects}"
SECRETS_DIR="${SECRETS_DIR:-./data/gastown-secrets}"

mkdir -p "$SECRETS_DIR"

gitea_admin() {
    $DC exec -T -u git gitea gitea admin "$@"
}

user_exists() {
    gitea_admin user list | awk -v user="$GASTOWN_GIT_USER" 'NR > 1 && $2 == user { found = 1 } END { exit !found }'
}

org_exists() {
    curl -fsS "http://localhost:${GITEA_HTTP_PORT:-3000}/api/v1/orgs/${GASTOWN_ORG}" >/dev/null 2>&1
}

echo "Waiting for Gitea..."
for _ in $(seq 1 60); do
    if $DC exec -T gitea curl -fsS http://localhost:3000/api/healthz >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

if ! user_exists; then
    if [ -z "$GASTOWN_GIT_PASSWORD" ]; then
        echo "error: GASTOWN_GIT_PASSWORD must be set in ${ENV_FILE}" >&2
        exit 1
    fi
    echo "Creating Gitea user: ${GASTOWN_GIT_USER}"
    gitea_admin user create \
        --username "$GASTOWN_GIT_USER" \
        --email "$GASTOWN_GIT_EMAIL" \
        --password "$GASTOWN_GIT_PASSWORD" \
        --must-change-password=false
else
    echo "Gitea user already exists: ${GASTOWN_GIT_USER}"
fi

if [ ! -f "${SECRETS_DIR}/gitea-token" ]; then
    echo "Generating Gitea access token..."
    token="$(gitea_admin user generate-access-token \
        --username "$GASTOWN_GIT_USER" \
        --token-name factory \
        --raw)"
    printf '%s' "$token" > "${SECRETS_DIR}/gitea-token"
    chmod 600 "${SECRETS_DIR}/gitea-token"
else
    echo "Reusing existing Gitea token."
fi

printf '%s\n' "http://gitea:3000" > "${SECRETS_DIR}/gitea-url"
printf '%s\n' "$GASTOWN_GIT_USER" > "${SECRETS_DIR}/gitea-user"
printf '%s\n' "$GASTOWN_ORG" > "${SECRETS_DIR}/gitea-org"

if ! org_exists; then
    echo "Creating Gitea org: ${GASTOWN_ORG}"
    gitea_admin create-org --name "$GASTOWN_ORG" --user "$GASTOWN_GIT_USER" || true
else
    echo "Gitea org already exists: ${GASTOWN_ORG}"
fi

echo "Gitea bootstrap complete."
