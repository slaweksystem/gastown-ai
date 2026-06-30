# Infrastructure operations (Docker Compose + Gitea bootstrap).
# Gastown itself is configured inside the container — see README.

SHELL        := /usr/bin/env bash
.SHELLFLAGS  := -eu -o pipefail -c

COMPOSE      ?= docker compose
COMPOSE_FILE ?= docker-compose.yml
ENV_FILE     ?= .env

DC := $(COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

.DEFAULT_GOAL := help

.PHONY: help init up down restart logs ps status pull build bootstrap \
        psql backup clean nuke create-admin list-admins

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Create .env from .env.example if it does not yet exist.
	@if [ ! -f $(ENV_FILE) ]; then \
		cp .env.example $(ENV_FILE); \
		echo "Created $(ENV_FILE) – edit it before running 'make up'."; \
	else \
		echo "$(ENV_FILE) already exists, leaving it untouched."; \
	fi

up: ## Start the full stack (Gitea, bootstrap, Gastown).
	$(DC) up -d db gitea --wait
	@ENV_FILE=$(ENV_FILE) ./scripts/bootstrap-gitea.sh
	$(DC) up -d gastown --build --wait

bootstrap: ## Provision Gastown Gitea user, token, and org.
	@ENV_FILE=$(ENV_FILE) ./scripts/bootstrap-gitea.sh

down: ## Stop the stack and remove containers (keeps volumes).
	$(DC) down

restart: ## Restart the stack.
	$(DC) restart

logs: ## Tail logs from all services.
	$(DC) logs -f --tail=200

ps: ## Show container status.
	$(DC) ps

status: ps ## Alias for `ps`.

pull: ## Pull latest images for all services.
	$(DC) pull

build: ## Rebuild local images (no-op if none are defined).
	$(DC) build

psql: ## Open a psql shell against the Postgres database.
	$(DC) exec db psql -U $${POSTGRES_USER:-gitea} -d $${POSTGRES_DB:-gitea}

create-admin: ## Create a Gitea admin user. Usage: make create-admin [ADMIN_USER=...] [ADMIN_EMAIL=...] [ADMIN_PASSWORD=...]
	@user="$${ADMIN_USER:-gastown-admin}"; \
	email="$${ADMIN_EMAIL:-admin@localhost}"; \
	password="$${ADMIN_PASSWORD:-}"; \
	if [ -z "$$password" ]; then \
		read -r -s -p "Password for $$user: " password; echo; \
	fi; \
	$(DC) exec -u git -T gitea gitea admin user create \
		--username "$$user" \
		--email "$$email" \
		--password "$$password" \
		--admin \
		--must-change-password=false

list-admins: ## List existing Gitea users (admins are flagged with `true` in the IsAdmin column).
	$(DC) exec -u git -T gitea gitea admin user list --admin

backup: ## Dump the Postgres database to ./backups/<timestamp>.sql.gz.
	@mkdir -p backups
	@ts=$$(date +%Y%m%d-%H%M%S); \
	$(DC) exec -T db pg_dump -U $${POSTGRES_USER:-gitea} $${POSTGRES_DB:-gitea} \
		| gzip > backups/$$ts.sql.gz; \
	echo "Wrote backups/$$ts.sql.gz"

clean: ## Stop the stack and remove containers + networks (keeps volumes).
	$(DC) down --remove-orphans

nuke: ## DANGER: stop the stack and DELETE all volumes (irreversible).
	$(DC) down -v --remove-orphans
