# Documentation Reading List

A curated reading list for the Fedora GNOME post-install automation project. Each link below was verified live (HTTP 200, content fetched) before being shared. Links are grouped by the section they support, and ordered by recommended reading flow within each section.

---

## 1.1.4 — inventory

**Concepts introduced:** managed hosts, the inventory file, host variables, the `ansible_connection` parameter, implicit localhost.

| # | Topic | What to read |
|---|---|---|
| 1 | Inventory overview | <ul><li>Read "Inventory basics: formats, hosts, and groups"</li><li>Read "Assigning a variable to one machine: host variables"</li><li>Skip: groups, ranges, parent/child groups, dynamic inventory</li></ul>[intro_inventory.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html) |
| 2 | Connection methods (incl. localhost) | <ul><li>Read "Running against localhost" subsection only</li><li>Skim: SSH key setup, host key checking</li></ul>[connection_details.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/connection_details.html) |
| 3 | Implicit localhost | <ul><li>Read fully (short page)</li><li>Why we *could* skip our `inventory` file entirely</li><li>What overriding the implicit localhost actually changes</li></ul>[implicit_localhost.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/implicit_localhost.html) |

**Minimum viable read (~2 min):** the "Running against localhost" section of `connection_details.html` + skim `implicit_localhost.html`. Covers 90% of what you need for this section.

---

## 1.1.5 — vars.yml

**Concepts introduced:** Ansible variables, the `vars_files` directive, Jinja2 templating, YAML quoting rules for `{{ ... }}` values, Ansible facts (`ansible_hostname`).

| # | Topic | What to read |
|---|---|---|
| 1 | YAML syntax (quoting rules) | <ul><li>Read "Gotchas" section at the bottom (mandatory)</li><li>Explains the `{{ ... }}` quoting requirement</li><li>Prevents the most common beginner syntax error</li></ul>[YAMLSyntax.html](https://docs.ansible.com/projects/ansible/latest/reference_appendices/YAMLSyntax.html) |
| 2 | Variables in playbooks | <ul><li>Read "Defining simple variables"</li><li>Read "Referencing simple variables"</li><li>Read "When to quote variables (a YAML gotcha)"</li><li>Skip list/dictionary sections for now</li></ul>[playbooks_variables.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html) |
| 3 | Facts and magic variables | <ul><li>Read "Ansible facts" section only</li><li>Just need to know facts exist + `ansible_hostname` is one of them</li><li>Bookmark magic variables section for later</li></ul>[playbooks_vars_facts.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_vars_facts.html) |

**Minimum viable read (~5 min):** "Gotchas" in `YAMLSyntax.html` + "When to quote variables" in `playbooks_variables.html`. These two together eliminate most YAML/Jinja errors.

---

## 1.1.6 — requirements.yml

**Concepts introduced:** Ansible Galaxy, collections vs roles, version range specifiers, `ansible-galaxy collection install -r`.

| # | Topic | What to read |
|---|---|---|
| 1 | Galaxy User Guide (requirements.yml format) | <ul><li>Skip the role sections — we only use collections</li><li>Read the "Installing roles and collections from the same requirements.yml file" example</li><li>Shows the exact `collections:` structure we use</li></ul>[user_guide.html](https://docs.ansible.com/projects/ansible/latest/galaxy/user_guide.html) |
| 2 | Installing collections | <ul><li>Read "Install multiple collections with a requirements file"</li><li>Skim version range syntax under "Installing an older version of a collection"</li><li>Bookmark signature verification for later (not needed now)</li></ul>[collections_installing.html](https://docs.ansible.com/projects/ansible/latest/collections_guide/collections_installing.html) |

**Minimum viable read (~3 min):** the "Installing roles and collections from the same requirements.yml file" example in `user_guide.html`. That single block shows the exact format we use.

---

## 1.1.7 — setup.yml (skeleton)

**Concepts introduced:** plays, tasks, modules, FQCN, play keywords (`hosts`, `become`, `gather_facts`, `vars_files`, `pre_tasks`), task keywords (`name`, `when`), `ansible.builtin.fail`, `ansible.builtin.debug`, `ansible_hostname` fact.

| # | Topic | What to read |
|---|---|---|
| 1 | Ansible playbooks (intro) | <ul><li>Read "Playbook syntax" and "Playbook execution"</li><li>Skim the example playbook to see plays + tasks + modules in action</li><li>Skim "Desired state and idempotency"</li></ul>[playbooks_intro.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html) |
| 2 | Playbook Keywords | <ul><li>Read the "Play" section: `hosts`, `become`, `gather_facts`, `vars_files`, `pre_tasks`, `tasks`, `vars`, `connection`</li><li>Read the "Task" section: `name`, `when`, `register`</li><li>Skip everything about roles, blocks, handlers for now</li></ul>[playbooks_keywords.html](https://docs.ansible.com/projects/ansible/latest/reference_appendices/playbooks_keywords.html) |
| 3 | Conditionals (`when:`) | <ul><li>Read "Basic conditionals with when"</li><li>Skim "Conditionals based on ansible_facts"</li><li>The note: `when:` is raw Jinja2, NO `{{ }}` inside</li></ul>[playbooks_conditionals.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_conditionals.html) |
| 4 | `ansible.builtin.fail` module | <ul><li>Read Synopsis and Examples</li><li>The canonical "fail + when" pattern we used</li></ul>[fail_module.html](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/fail_module.html) |
| 5 | `ansible.builtin.debug` module | <ul><li>Read Synopsis and Examples</li><li>Shows `msg:` and `var:` forms (we use `msg:`)</li></ul>[debug_module.html](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/debug_module.html) |

**Minimum viable read (~5 min):** `playbooks_intro.html` "Playbook syntax" + "Playbook execution" sections. That alone gets you ~80% of what you need to understand a playbook structure.

---

## 1.1.8 — Makefile

**Concepts introduced:** GNU `make` and `Makefile` basics, targets, recipes, tab-indented commands.

No Ansible-specific docs required for this section. The `make` build tool is independent of Ansible.

## 1.1.10 — verification

**Concepts introduced:** `ansible-playbook --syntax-check`, `ansible-lint`, check mode (`--check`), diff mode (`--diff`), idempotency.

| # | Topic | What to read |
|---|---|---|
| 1 | Check mode + diff mode | <ul><li>Read "Using check mode" and "Using diff mode"</li><li>Note: check mode simulates changes without applying them</li><li>Diff mode shows before/after for changed files</li></ul>[playbooks_checkmode.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html) |
| 2 | Verifying playbooks (overview) | <ul><li>Read "Verifying playbooks" section: `--check`, `--diff`, `--list-hosts`, `--list-tasks`, `--syntax-check`</li><li>Skim the `ansible-lint` subsection</li></ul>[playbooks_intro.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html) |
| 3 | ansible-lint | <ul><li>External site (not docs.ansible.com)</li><li>The default rules list, and how to suppress a rule with `# noqa: <rule>`</li></ul>[ansible-lint rules](https://ansible.readthedocs.io/projects/lint/rules/) |

**Minimum viable read (~3 min):** the "Using check mode" + "Using diff mode" sections of `playbooks_checkmode.html`. Tells you exactly what `--check --diff` does and doesn't catch.

---

## 1.2 — `dump-current-state.sh`

**Concepts introduced:** `dnf history userinstalled`, `flatpak list --system/--user`, `dconf dump`/`load` round-trip, `pipx install`, `gext list`, bash safety flags (`set -euo pipefail`), bash idioms (`[ -f ] && cmd`, `tail -n +5`, `${1:-default}`).

| # | Topic | What to read |
|---|---|---|
| 1 | DNF Command Reference | <ul><li>Search for "history" → "History Command"</li><li>Read `dnf history userinstalled` — shows packages installed by user</li><li>Skim return-value table at the top</li></ul>[command_ref.html](https://dnf.readthedocs.io/en/latest/command_ref.html) |
| 2 | Flatpak Command Reference | <ul><li>Search for "list" → `flatpak list` command</li><li>Note the `--system` and `--user` flags (we use both)</li><li>Note the `--columns=application` flag for machine-readable output</li></ul>[flatpak-command-reference.html](https://docs.flatpak.org/en/latest/flatpak-command-reference.html) |
| 3 | dconf(1) man page | <ul><li>Read "DESCRIPTION" and "COMMANDS"</li><li>Focus on `dump DIR` and `load [-f] DIR` — these are the two we'll use</li><li>Note: needs D-Bus session (works while logged into GNOME)</li></ul>[dconf.1.en](https://man.archlinux.org/man/dconf.1.en) |
| 4 | pipx | <ul><li>Read "pip vs pipx" + "Where apps come from"</li><li>Skim "Install pipx" how-to for setup</li><li>For our use: `pipx install <package>` is the whole story</li></ul>[pipx.pypa.io/stable](https://pipx.pypa.io/stable/) |
| 5 | gext (gnome-extensions-cli) | <ul><li>Already verified earlier (A.6 era)</li><li>We use `gext list --all --no-color` for our dump</li></ul>[gnome-extensions-cli](https://github.com/essembeh/gnome-extensions-cli) |

**Minimum viable read (~5 min):** the four commands above in sequence. The dconf page is the most important — it explains exactly what `dump` produces and what `load` consumes.

---

## 1.3 — Playbook sections 1 + 2 (Bootstrap + System Prep)

**Concepts introduced:** `ansible.builtin.dnf` module, `ansible.builtin.command` module, `community.general.dnf_config_manager`, `community.general.flatpak_remote`, idempotency, `state: present/latest`, package globs (`name: '*'`).

| # | Topic | What to read |
|---|---|---|
| 1 | `ansible.builtin.dnf` module | <ul><li>Read Synopsis + Parameters (focus on `name`, `state`)</li><li>Skim the "Upgrade all packages" example (`name: "*"` + `state: latest`)</li><li>Note: requires `python3-dnf` on the target host (already present on Fedora)</li></ul>[dnf_module.html](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/dnf_module.html) |
| 2 | `ansible.builtin.command` module | <ul><li>Read Synopsis + Parameters</li><li>Note: NO shell processing — use `ansible.builtin.shell` if you need `>`, `\|`, etc.</li><li>We use it for the `ansible-galaxy collection install` invocation in Section 1</li></ul>[command_module.html](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/command_module.html) |
| 3 | `community.general.dnf_config_manager` module | <ul><li>Read Synopsis + Parameters (`name`, `state`)</li><li>Required host package: `dnf-plugins-core` (Section 2's `dnf` task installs it)</li><li>Skim the "Ensure the crb repository is enabled" example</li></ul>[dnf_config_manager_module.html](https://docs.ansible.com/projects/ansible/latest/collections/community/general/dnf_config_manager_module.html) |
| 4 | `community.general.flatpak_remote` module | <ul><li>Read Synopsis + Parameters (`name`, `flatpakrepo_url`, `method`, `state`)</li><li>Required host package: `flatpak`</li><li>Note: `flatpakrepo_url` is REQUIRED for `state=present`</li><li>Use Flathub URL: `https://dl.flathub.org/repo/flathub.flatpakrepo`</li></ul>[flatpak_remote_module.html](https://docs.ansible.com/projects/ansible/latest/collections/community/general/flatpak_remote_module.html) |

**Minimum viable read (~5 min):** the `ansible.builtin.dnf` Synopsis + Parameters table — covers the most-used module in this playbook. The other three are skimmable.

---

## 1.4 — Playbook section 3 (DNF packages)

**Concepts introduced:** `ansible.builtin.set_fact`, `lookup` plugin (`lines`), task-level `vars:`, `ignore_errors`, `playbook_dir` magic variable.

| # | Topic | What to read |
|---|---|---|
| 1 | `ansible.builtin.set_fact` module | <ul><li>Read Synopsis + Parameters</li><li>Skim the Examples (especially "Setting host facts using complex arguments")</li><li>Note: `set_fact` variables persist for the rest of the play; this is why we split the read and install into two tasks</li></ul>[set_fact_module.html](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/set_fact_module.html) |
| 2 | Lookups (`lookup('lines', ...)`) | <ul><li>Read "The lookup function" — explains `lookup` syntax and `wantlist=True`</li><li>Note: lookup runs on the *controller* (Ansible's host), not the target. `lines` returns one list element per line of the file</li><li>Skim "The query/q function" (related, used in loops)</li></ul>[playbooks_lookups.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_lookups.html) |
| 3 | `ignore_errors` task keyword | <ul><li>Reference docs under "Task" section: `ignore_errors` = "Boolean that allows you to ignore task failures and continue with play"</li><li>Used here so a few packages unavailable on the fresh Fedora don't abort the whole playbook</li></ul>[playbooks_keywords.html](https://docs.ansible.com/projects/ansible/latest/reference_appendices/playbooks_keywords.html) |

**Minimum viable read (~5 min):** the `lookup` page "The lookup function" section — explains the syntax you'll see in the task. The set_fact docs are skimmable if you've used similar variable-setting patterns in other tools.

---

## 1.5 — Playbook section 4 (Flatpak packages)

**Concepts introduced:** `community.general.flatpak` module, `method:` parameter (system vs user), `become_user:` keyword (per-task), `when:` conditional with content-length check.

| # | Topic | What to read |
|---|---|---|
| 1 | `community.general.flatpak` module | <ul><li>Read Synopsis + Parameters (focus on `name`, `state`, `method`, `remote`)</li><li>Note the "Install multiple packages" example — list of reverse-DNS names in `name:`</li><li>Skim Return Values to see what the module returns</li></ul>[flatpak_module.html](https://docs.ansible.com/projects/ansible/latest/collections/community/general/flatpak_module.html) |
| 2 | Privilege escalation (`become_user`) | <ul><li>Read "Become directives" — focuses on `become`, `become_user`, `become_method`</li><li>Note: setting `become_user` does NOT imply `become: true` (already set at play level here)</li><li>Skim the rest (Network, Windows) — we only need the Linux sections</li></ul>[playbooks_privilege_escalation.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_privilege_escalation.html) |

**Minimum viable read (~5 min):** the flatpak module's Parameters table (focus on `name`, `method`, `state`). The become page is reference material — read "Become directives" only.
