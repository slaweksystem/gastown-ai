# Project Specification: Gastown AI Factory (Monorepo)

## 1. Project Overview
The "Gastown AI Factory" is a monorepo that houses both the infrastructure for a self-hosted Git environment (Gitea + PostgreSQL) and the operational codebase for AI agents, workflows, and prompts. The master repository will be hosted on GitHub, while the self-hosted Gitea instance will be used for local agent tasks and operations.

## 2. Directory Structure to Generate
Please scaffold the following directory structure exactly as shown. Create the specified files with production-ready code. For empty directories, include a `.gitkeep` file so they are tracked by version control.

```text
gastown-ai/
├── infrastructure/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── Makefile
├── agents/
│   └── .gitkeep
├── workflows/
│   └── .gitkeep
├── prompts/
│   └── .gitkeep
├── .gitignore
└── README.md