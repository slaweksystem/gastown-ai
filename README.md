# Gastown AI Factory

A monorepo that houses both the **infrastructure** for a self-hosted Git
environment (Gitea + PostgreSQL) and the **operational codebase** for AI
agents, workflows, and prompts.

Gastown uses Gitea to create and operate project repositories. The
`infrastructure/` stack runs that Gitea instance locally.

## Repository layout

```text
gastown-ai/
├── infrastructure/      # Docker Compose stack (Gitea + PostgreSQL) + ops Makefile
│   ├── docker-compose.yml
│   ├── .env.example
│   └── Makefile
├── agents/              # AI agent definitions and implementations
├── workflows/           # Multi-step workflows orchestrating agents
├── prompts/             # Reusable prompt templates
├── .gitignore
└── README.md
```

## Quickstart: self-hosted Gitea

Requirements: Docker Engine 24+ and the Compose v2 plugin (`docker compose`).

```bash
cd infrastructure

# 1. Create your local .env from the template and edit the secrets.
make init
$EDITOR .env

# 2. Start the stack (Postgres + Gitea) in the background.
make up

# 3. Tail logs until Gitea is ready.
make logs
```

Gitea will then be available at <http://localhost:3000> (SSH on port `2222`
by default).

### Creating the first admin

This instance ships with **public registration disabled**
(`GITEA_DISABLE_REGISTRATION=true`), so the "Register" link is intentionally
hidden and there is no default admin. Create the first admin via the CLI:

```bash
# Interactive (prompts for a password):
make create-admin ADMIN_USER=gastown-admin ADMIN_EMAIL=you@example.com

# Or non-interactive:
ADMIN_PASSWORD='super-secret' make create-admin \
    ADMIN_USER=gastown-admin ADMIN_EMAIL=you@example.com
```

> **Note:** Gitea reserves a set of usernames that would collide with its
> URL routes — including `admin`, `api`, `user`, `login`, `org`, `repo`,
> `issues`, `pulls`, `new`, `help`, `install`, and a few dozen others. Pick
> something outside that list (e.g. `gastown-admin`, `sysadmin`, your own
> handle).

You can then sign in at <http://localhost:3000/user/login>. Use
`make list-admins` to verify, and create additional users from the admin
panel (Site Administration → Users → Create User) or by re-running
`make create-admin` without the `--admin` flag if you customise it.

If you'd rather use the web installer flow instead, set
`GITEA_DISABLE_REGISTRATION=false` in `infrastructure/.env` and
`make restart` — the "Register" link will reappear.

### Common operations

| Command            | What it does                                              |
| ------------------ | --------------------------------------------------------- |
| `make up`          | Start the stack in the background.                        |
| `make down`        | Stop the stack (volumes are preserved).                   |
| `make restart`     | Restart all services.                                     |
| `make logs`        | Tail logs from all services.                              |
| `make ps`          | Show container status.                                    |
| `make pull`        | Pull the latest images.                                   |
| `make psql`        | Open a `psql` shell against the Gitea database.           |
| `make gitea-shell` | Open a shell inside the Gitea container.                  |
| `make create-admin`| Create the first Gitea admin user (see above).            |
| `make list-admins` | List existing Gitea admin users.                          |
| `make backup`      | Dump the database to `infrastructure/backups/<ts>.sql.gz`.|
| `make nuke`        | **Destructive** – removes containers *and* volumes.       |

Run `make help` inside `infrastructure/` to see the full list.

## Operational codebase

The top-level `agents/`, `workflows/`, and `prompts/` directories define
how Gastown works. Gastown uses Gitea for project repos.

- **`agents/`** – individual agent implementations (one subdirectory per
  agent, each with its own README, code, and tests).
- **`workflows/`** – multi-step orchestrations that compose one or more
  agents to accomplish a higher-level task.
- **`prompts/`** – reusable prompt templates, organized by domain or agent.

They currently contain only a `.gitkeep` placeholder and will be populated
as the factory grows.

## Secrets

All secrets live in `infrastructure/.env`, which is **git-ignored**. Use
`infrastructure/.env.example` as the canonical template and update it
whenever a new variable is introduced.
