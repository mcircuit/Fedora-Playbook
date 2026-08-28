# Project Progress

Tracks the Fedora GNOME post-install automation project status. This is the single source of truth for which skeleton steps are done, in progress, or pending. Updated by the agent after each completed subsection.

## How this file is maintained

- **Who:** the agent updates this file after verifying a subsection is complete (per AGENTS.md rule #8).
- **When:** immediately after verification — same turn as the verification message to the user.
- **What changes:** the row for that subsection's status flips to `Done`, `Skipped`, or remains `In progress` if the subsection is partial.
- **What stays the same:** the row order, the step labels, and the "Notes" column (unless notes need updating).
- **Add new steps:** only when explicitly asked by the user or when PLAN.md introduces them.

## Status

| Step | Status | Notes |
|---|---|---|
| A.1 — `git init -b main` | Done | `.git/` initialized with `main` branch |
| A.2 — `.gitignore` | Skipped | Deferred per user preference until noise appears |
| A.3 — `README.md` | Done | 22 lines, includes Usage block and pointer to PLAN.md |
| A.4 — `inventory` | Done | Single line: `localhost ansible_connection=local` |
| A.5 — `vars.yml` | Done | Contains `target_user: merlin`, `target_home` (templated), `expected_hostname: merlin-pc` |
| A.6 — `requirements.yml` | Done | Contains `community.general` with version `>=8.0.0`; YAML parses cleanly |
| A.7 — `setup.yml` skeleton | Done | One play, pre_task safety check + debug placeholder; `ansible-playbook --syntax-check` passes |
| A.8 — `Makefile` | Done | 5 targets + help; TAB-indented recipes verified; `make syntax-check` passes; `REPO_URL` still placeholder until GitHub repo exists |
| A.9 — first commit | Done | User made initial commit; subsequent URL/DOCS/PROGRESS updates in follow-up commit `f14611b` |
| A.10 — verification | Pending | `syntax-check` + `ansible-lint` |

## Files in this repo (status of source artifacts)

| File | Purpose | Maintained by |
|---|---|---|
| `context/PLAN.md` | Architectural plan + locked decisions | User |
| `AGENTS.md` | Operating instructions for agents | User (rare; never edited by agent unless asked) |
| `context/DOCS.md` | Curated Ansible docs reading list | Agent (per Markdown conventions) |
| `context/PROGRESS.md` | This file — project status | Agent (per Required behavior rule #8) |
| `README.md` | Human-facing repo intro | User + Agent |
| `inventory` | Ansible managed-hosts file | User |
| `vars.yml` | Variables used by `setup.yml` | User |
| `requirements.yml` | Galaxy collections manifest | User |
| `setup.yml` | The Ansible playbook | User |
| `Makefile` | Convenience targets (`apply`, `dry-run`, `dump`, `lint`, `syntax-check`) | User |

## What is NOT tracked here

- Architectural decisions and rationale → `context/PLAN.md`
- Documentation links and reading order → `context/DOCS.md`
- Operating instructions for agents → `AGENTS.md`