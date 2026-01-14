# Global CLAUDE.md

This file applies to ALL your projects. Define your identity, security rules, and scaffolding standards once.

## Identity & Accounts

- **GitHub**: YourUsername (SSH: `git@github.com:YourUsername/<repo>.git`)
- **Docker Hub**: authenticated via `~/.docker/config.json`
- **Deployment**: Dokploy (API URL in `~/.env`)

> **Customize this section** with your actual accounts and preferred tools.

---

## NEVER EVER DO (Security Gatekeeper)

These rules are **ABSOLUTE**. No exceptions.

### NEVER Publish Sensitive Data
- ❌ NEVER commit passwords, API keys, tokens to git/npm/docker
- ❌ NEVER hardcode credentials in source files
- ❌ NEVER include secrets in error messages or logs

### NEVER Commit .env Files
- ❌ NEVER commit `.env` to git
- ✅ ALWAYS verify `.env` is in `.gitignore`
- ✅ ALWAYS use `.env.example` with placeholder values

### NEVER Skip Verification
- Before ANY commit: verify no secrets included
- Before ANY push: check staged files for sensitive data
- Before ANY publish: audit package contents

---

## New Project Setup (Scaffolding Rules)

When creating ANY new project, ALWAYS do the following:

### 1. Required Files (Create Immediately)

| File | Purpose | Notes |
|------|---------|-------|
| `.env` | Environment variables | NEVER commit |
| `.env.example` | Template with placeholders | Commit this |
| `.gitignore` | Ignore patterns | Must include .env |
| `.dockerignore` | Docker ignore patterns | Mirror .gitignore |
| `README.md` | Project overview | Reference env vars, don't hardcode |
| `CLAUDE.md` | Project instructions | Required sections below |

### 2. Required Directory Structure

```
project-root/
├── src/               # Source code
├── tests/             # Test files
├── docs/              # Documentation
├── .claude/           # Claude configuration
│   ├── commands/      # Custom slash commands
│   ├── skills/        # Project-specific skills
│   └── settings.json  # Project settings
└── scripts/           # Build/deploy scripts
```

### 3. Required .gitignore Entries

```gitignore
# Environment
.env
.env.*
.env.local
!.env.example

# Dependencies
node_modules/
vendor/
__pycache__/
.venv/

# Build outputs
dist/
build/
.next/
*.pyc

# Claude local files
.claude/settings.local.json
CLAUDE.local.md

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db
```

### 4. Required CLAUDE.md Sections

Every project `CLAUDE.md` must include:

```markdown
# Project Name

## Overview
[What this project does]

## Tech Stack
- Language: [e.g., TypeScript]
- Framework: [e.g., Next.js]
- Database: [e.g., PostgreSQL]

## Commands
- `npm run dev` — Start development server
- `npm run build` — Build for production
- `npm test` — Run tests
- `npm run lint` — Check code style

## Architecture
[High-level overview of the codebase structure]

## Environment Variables
[List required env vars WITHOUT values]
```

---

## Framework-Specific Rules

### Node.js Projects
- Add error handlers to entry point
- Use TypeScript strict mode
- Configure ESLint + Prettier
- Set up Husky for pre-commit hooks

### Python Projects
- Create `pyproject.toml` (not setup.py)
- Use `src/` layout
- Include `requirements.txt` AND `requirements-dev.txt`
- Configure Ruff for linting

### Next.js Projects
- Use App Router (not Pages Router)
- Create `src/app/` directory structure
- Enable strict mode in next.config.js

### Docker Projects
- Multi-stage builds ALWAYS
- Never run as root
- Include health checks
- `.dockerignore` must include `.git/`

---

## Quality Gates

### File Size Limits
- No file > 300 lines (split if larger)
- No function > 50 lines

### Required Before Commit
- [ ] All tests pass
- [ ] TypeScript compiles with no errors
- [ ] Linter passes with no warnings
- [ ] No secrets in staged files

### CI/CD Requirements
- GitHub Actions workflow for CI
- Pre-commit hooks via Husky (Node.js) or pre-commit (Python)

---

## Required MCP Servers

Consider adding these MCP servers for enhanced capabilities:

```bash
# Live documentation access
claude mcp add context7 -- npx -y @anthropic-ai/context7-mcp

# Browser testing
claude mcp add playwright -- npx -y @anthropic-ai/playwright-mcp

# GitHub integration
claude mcp add github -- npx -y @modelcontextprotocol/server-github
```

---

## Global Commands

Store these in `~/.claude/commands/` for use in ALL projects:

| Command | Purpose |
|---------|---------|
| `/new-project` | Create project with scaffolding rules |
| `/security-check` | Scan for secrets, validate .gitignore |
| `/pre-commit` | Run all quality gates |
| `/docs-lookup` | Research documentation via Context7 |

---

*Last updated: [DATE]*
