# Gastown AI Factory

A monorepo that houses both the **infrastructure** for a self-hosted Git
environment (Gitea + PostgreSQL) and the **operational codebase** for AI
agents, workflows, and prompts.

Gastown uses Gitea to create and operate project repositories. The
`infrastructure/` stack runs that Gitea instance locally.

## Repository layout

```text
gastown-ai/
├── infrastructure/      # Docker Compose stack + ops Makefile
│   ├── docker-compose.yml
│   ├── gastown/         # Gastown sandbox image
│   ├── scripts/         # Gitea bootstrap
│   ├── .env.example
│   └── Makefile
├── agents/              # AI agent definitions and implementations
├── workflows/           # Multi-step workflows orchestrating agents
├── prompts/             # Reusable prompt templates
├── .gitignore
└── README.md
```

## Quickstart (infrastructure)

Requirements: Docker Engine 24+ and the Compose v2 plugin (`docker compose`).

```bash
cd infrastructure

make init
$EDITOR .env   # set POSTGRES_PASSWORD and GASTOWN_GIT_PASSWORD

make up
```

`make up` starts Postgres and Gitea, provisions the Gastown Gitea service
account (user, token, org), builds the Gastown container, and runs
`gt install` automatically.

| Service           | URL |
| ----------------- | --- |
| Gitea             | <http://localhost:3000> (SSH on port `2222`) |
| Gastown dashboard | <http://localhost:8080> |

## Gastown setup

Everything after `make up` happens **inside the Gastown container**. Follow
the [Gas Town docs](https://docs.gastownhall.ai/) from there — agent auth,
rigs, Mayor, all of it.

```bash
cd infrastructure
docker compose exec gastown zsh
```

Inside the container:

```bash
gt doctor
gt config agent list
gt up
gt mayor attach
```

Gitea is already wired (`http://gitea:3000`, credentials at
`/run/gastown/gitea-token`). When adding a rig, use a Gitea repo URL.

## Gitea admin (optional)

For browsing Gitea in the browser. Gastown uses its own service account
(created automatically on `make up`).

Public registration is disabled (`GITEA_DISABLE_REGISTRATION=true`). Create
a human admin from the host:

```bash
cd infrastructure
make create-admin ADMIN_USER=gastown-admin ADMIN_EMAIL=you@example.com
```

> Gitea reserves usernames that collide with URL routes (`admin`, `api`,
> `user`, `login`, etc.). Use something like `gastown-admin`.

## Infrastructure commands

Run from `infrastructure/`. See `make help` for the full list.

| Command         | What it does |
| --------------- | ------------ |
| `make up`       | Start stack, bootstrap Gitea, start Gastown |
| `make down`     | Stop containers (volumes preserved) |
| `make logs`     | Tail service logs |
| `make ps`       | Container status |
| `make bootstrap`| Re-run Gitea provisioning |
| `make backup`   | Dump Postgres to `backups/` |
| `make nuke`     | **Destructive** — delete volumes |

## Operational codebase

The `agents/`, `workflows/`, and `prompts/` directories define how Gastown
runs. Project repos live in Gitea.

## Secrets

All secrets live in `infrastructure/.env` (git-ignored). Use
`infrastructure/.env.example` as the template.

Gitea tokens from bootstrap are in `infrastructure/data/gastown-secrets/`
(git-ignored).
