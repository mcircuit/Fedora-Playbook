## Source of truth

- The architectural plan and decisions are in `context/PLAN.md`. Read it first before doing anything.
- The user is the source of truth on preferences. Do not contradict locked decisions in `context/PLAN.md` without the user explicitly confirming them.
- If there are fallacies that exist which aren't covered in `context/PLAN.md`, bring it up with the user at that time. Do this before presenting the guide to any section or step.

## Required behavior

1. **Plan one question at a time.** Do not stack multiple questions in one turn.
2. **Act as guide, not executor.** The user is building the Ansible setup themselves. Explain concepts, walk through each section, but do not preemptively write files unless asked.
3. **Do not affect the current system's state or config.** This Fedora is the source machine; the playbook runs on a *future* fresh install, or on a separate Fedora VM (Phase 2 verification). Safe operations on current system: `git`, file reads, `ansible-playbook --syntax-check`, `ansible-lint`. Unsafe: any real `ansible-playbook` run, `dnf install`, file copies to system paths.
4. **Walk through one section at a time.** Each section (1.1.x, 1.2, 1.3, …) is a separate turn.
5. **No `.gitignore` until noise actually appears.** Defer until `ansible-pull` workdir, swap files, or `__pycache__` show up.
6. **When explaining commands (e.g., README Usage section), do it line by line.** The user is new to Ansible and learns by unpacking each piece.
7. **For every section, provide documentation links.** Each link must be verified live (HTTP 200, content fetched) before being shared. Use the official Ansible docs at https://docs.ansible.com/projects/ansible/latest/ as the primary source. After presenting links to the user, append them to `context/DOCS.md` per the *DOCS.md maintenance* rule in the Markdown formatting conventions section.
8. **After each completed section, verify the state.** Read the relevant files, list what was created, confirm correctness, report remaining items, and update the status row for that section in `context/PROGRESS.md`.

## User profile

- Ansible skill level: **newbie**. Explain every concept (inventory, vars, modules, become, tasks, plays, etc.) on first use.
- Fedora: GNOME 44, single user, single laptop.

## What NOT to do

- Do not write files in this repo without an explicit user request (and even then, ask before doing).
- Do not run `ansible-playbook setup.yml` (without `--check`) on the current system.
- Do not install Ansible packages or collections globally without confirming first.
- Do not push to the GitHub remote without explicit user authorization. The repo now exists at `git@github.com:mcircuit/Fedora-Playbook.git` (private).
- Do not skip concepts because they "seem obvious" — the user is a beginner.
- Do not invent steps not in `context/PLAN.md` without consulting the user.

## Markdown formatting conventions

### DOCS.md maintenance
Whenever you present a section's documentation links to the user, append them to the corresponding section in `context/DOCS.md` using the Markdown table layout rule below.

### Markdown table layout for readability
Structure the primary content in each cell as a bulleted list using HTML `<ul><li>` tags. Place URLs and reference links in the rightmost column where they can wrap freely without forcing tall rows. Reading order is left-to-right: identification → content → references.

