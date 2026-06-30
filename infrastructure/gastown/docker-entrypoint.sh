#!/bin/sh
set -e

# If git identity is provided, configure git/dolt so commits and beads metadata
# have a stable author inside the container.
if [ -n "$GIT_USER" ] && [ -n "$GIT_EMAIL" ]; then
    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
    git config --global credential.helper store
    dolt config --global --add user.name "$GIT_USER"
    dolt config --global --add user.email "$GIT_EMAIL"
fi

# If a provisioned Gitea token is mounted, write HTTP git credentials and
# map localhost URLs to the in-network Gitea hostname for container-internal use.
if [ -f /run/gastown/gitea-token ]; then
    gitea_user="${GITEA_USER:-gastown}"
    gitea_host="${GITEA_HOST:-gitea:3000}"
    token="$(cat /run/gastown/gitea-token)"
    cred_file="${HOME}/.git-credentials"
    touch "$cred_file"
    chmod 600 "$cred_file"
    grep -v "@${gitea_host}" "$cred_file" > "${cred_file}.tmp" 2>/dev/null || true
    mv "${cred_file}.tmp" "$cred_file"
    printf 'http://%s:%s@%s\n' "$gitea_user" "$token" "$gitea_host" >> "$cred_file"
    git config --global url."http://${gitea_host}/".insteadOf "http://localhost:3000/"
fi

# If the Gastown workspace has not been initialized yet, run a one-time
# `gt install`; otherwise keep existing state untouched.
if [ ! -f /gt/mayor/town.json ]; then
    echo "Initializing Gas Town workspace at /gt..."
    /app/gastown/gt install /gt --git
else
    echo "Gas Town workspace already initialized at /gt."
fi

echo "Configuring Cursor agent..."
/app/gastown/gt config default-agent cursor
/app/gastown/gt up || true

echo "Starting Gastown dashboard on port 8080..."
/app/gastown/gt dashboard --port 8080 >/tmp/gastown-dashboard.log 2>&1 &

exec "$@"
