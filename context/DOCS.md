# Documentation Reading List

A curated reading list for the Fedora GNOME post-install automation project. Each link below was verified live (HTTP 200, content fetched) before being shared. Links are grouped by the skeleton subsection they support, and ordered by recommended reading flow within each section.

---

## A.4 — inventory

**Concepts introduced:** managed hosts, the inventory file, host variables, the `ansible_connection` parameter, implicit localhost.

| # | Topic | What to read |
|---|---|---|
| 1 | Inventory overview | <ul><li>Read "Inventory basics: formats, hosts, and groups"</li><li>Read "Assigning a variable to one machine: host variables"</li><li>Skip: groups, ranges, parent/child groups, dynamic inventory</li></ul>[intro_inventory.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html) |
| 2 | Connection methods (incl. localhost) | <ul><li>Read "Running against localhost" subsection only</li><li>Skim: SSH key setup, host key checking</li></ul>[connection_details.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/connection_details.html) |
| 3 | Implicit localhost | <ul><li>Read fully (short page)</li><li>Why we *could* skip our `inventory` file entirely</li><li>What overriding the implicit localhost actually changes</li></ul>[implicit_localhost.html](https://docs.ansible.com/projects/ansible/latest/inventory_guide/implicit_localhost.html) |

**Minimum viable read (~2 min):** the "Running against localhost" section of `connection_details.html` + skim `implicit_localhost.html`. Covers 90% of what you need for this section.

---

## A.5 — vars.yml

**Concepts introduced:** Ansible variables, the `vars_files` directive, Jinja2 templating, YAML quoting rules for `{{ ... }}` values, Ansible facts (`ansible_hostname`).

| # | Topic | What to read |
|---|---|---|
| 1 | YAML syntax (quoting rules) | <ul><li>Read "Gotchas" section at the bottom (mandatory)</li><li>Explains the `{{ ... }}` quoting requirement</li><li>Prevents the most common beginner syntax error</li></ul>[YAMLSyntax.html](https://docs.ansible.com/projects/ansible/latest/reference_appendices/YAMLSyntax.html) |
| 2 | Variables in playbooks | <ul><li>Read "Defining simple variables"</li><li>Read "Referencing simple variables"</li><li>Read "When to quote variables (a YAML gotcha)"</li><li>Skip list/dictionary sections for now</li></ul>[playbooks_variables.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html) |
| 3 | Facts and magic variables | <ul><li>Read "Ansible facts" section only</li><li>Just need to know facts exist + `ansible_hostname` is one of them</li><li>Bookmark magic variables section for later</li></ul>[playbooks_vars_facts.html](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_vars_facts.html) |

**Minimum viable read (~5 min):** "Gotchas" in `YAMLSyntax.html` + "When to quote variables" in `playbooks_variables.html`. These two together eliminate most YAML/Jinja errors.

---

## A.6 — requirements.yml

**Concepts introduced:** Ansible Galaxy, collections vs roles, version range specifiers, `ansible-galaxy collection install -r`.

| # | Topic | What to read |
|---|---|---|
| 1 | Galaxy User Guide (requirements.yml format) | <ul><li>Skip the role sections — we only use collections</li><li>Read the "Installing roles and collections from the same requirements.yml file" example</li><li>Shows the exact `collections:` structure we use</li></ul>[user_guide.html](https://docs.ansible.com/projects/ansible/latest/galaxy/user_guide.html) |
| 2 | Installing collections | <ul><li>Read "Install multiple collections with a requirements file"</li><li>Skim version range syntax under "Installing an older version of a collection"</li><li>Bookmark signature verification for later (not needed now)</li></ul>[collections_installing.html](https://docs.ansible.com/projects/ansible/latest/collections_guide/collections_installing.html) |

**Minimum viable read (~3 min):** the "Installing roles and collections from the same requirements.yml file" example in `user_guide.html`. That single block shows the exact format we use.

---

## A.7 — setup.yml (skeleton)

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

## Future sections (links will be added as we get there)

- A.8 — `Makefile` — `make`/Makefile basics, no Ansible docs required
- A.10 — verification (`ansible-playbook --syntax-check`, `ansible-lint`) — those tool docs