# Fedora GNOME 44 Post-Install Automation — Guided Plan

## 1. Decisions Locked (recap)

| #  | Decision                  | Choice                                                            |
|----|---------------------------|-------------------------------------------------------------------|
| 1  | Starting state            | Greenfield                                                        |
| 2  | Scope                     | Single laptop, single user                                        |
| 3  | Package sources           | DNF + RPM Fusion + Flatpak (Flathub)                              |
| 4  | GNOME settings            | `community.general.dconf` module                                  |
| 5  | GNOME extensions          | `gext` install + Extension Manager Flatpak                       |
| 6  | Browsers                  | Vivaldi + Zen; stage configs + manual login; copy workspace/space state regardless |
| 7  | Scope of automation       | Apps + extensions + browser configs only                          |
| 8  | App list source           | Auto-dump from current Fedora                                     |
| 9  | Ansible skill level       | Newbie — explain everything                                       |
| 10 | Repo structure            | Single sectioned playbook                                         |
| 11 | Invocation                | `ansible-pull` + hardcoded `target_user` variable                 |
| 12 | End-of-playbook           | Notify checklist (no auto-reboot)                                 |
| 13 | Git hosting               | GitHub private repo                                               |

---

## 2. Repository Layout

```
fedora-setup/
├── README.md                  # what this is, how to use it
├── Makefile                   # `make apply`, `make dry-run`, `make dump`
├── ansible.cfg                # ansible config (host_key_checking, retry, etc.)
├── requirements.yml           # community.general collection
├── setup.yml                  # THE playbook (all sections inside)
├── vars.yml                   # target_user, paths, repo URLs
├── inventory                  # `localhost` entry
├── dump-current-state.sh      # run NOW on your current Fedora
├── lists/
│   ├── dnf-userinstalled.txt  # generated
│   ├── flatpak-system.txt     # generated
│   └── flatpak-user.txt       # generated
└── files/
    ├── dconf/
    │   └── gnome-settings.ini # `dconf dump / >` output
    ├── extensions.yml         # UUIDs of installed extensions
    ├── vivaldi/
    │   └── Default/
    │       ├── Preferences
    │       └── Local State    # runtime state for workspaces
    └── zen/
        ├── profiles.ini
        └── Profiles/<random>.<name>/
            ├── containers.json
            ├── prefs.js
            └── storage/       # IndexedDB for Spaces
```

---

## 3. The Playbook — `setup.yml` Sections (in order)

Sequencing matters; each section assumes the prior sections succeeded.

### Section 1 — Bootstrap (idempotent)

- `ansible.builtin.dnf: name: ansible-core` (no-op if already installed)
- `ansible.builtin.command: ansible-galaxy collection install -r requirements.yml`
- Why: makes the repo self-sufficient and re-runnable.

### Section 2 — System Prep

- `community.general.dnf_config_manager: repo: rpmfusion-free, rpmfusion-nonfree` (enable)
- `community.general.flatpak_remote: name: flathub state: present`
- `ansible.builtin.dnf: name: ['git', 'wget', 'curl', 'pipx'] state: present`
- `ansible.builtin.dnf: name: '*' state: latest` (the full system upgrade)

### Section 3 — DNF Packages from Auto-Dump

- Reads `lists/dnf-userinstalled.txt` into a list variable
- One `ansible.builtin.dnf` task with `loop: "{{ packages_dnf }}"`

### Section 4 — Flatpak Packages

- `community.general.flatpak` module with `loop`, separate loops for system vs user Flatpaks (system Flatpaks need `become: true`)

### Section 5 — GNOME Configuration (dconf)

- Tasks run with `become_user: "{{ target_user }}"` and `become: true`
- `community.general.dconf` tasks for individual keys (favorites, dark mode, keybindings)
- One bulk task that runs `dconf load / < files/dconf/gnome-settings.ini` for everything else
- Note: user-level dconf requires a DBus session — module auto-handles via `dbus-run-session`

### Section 6 — GNOME Extensions

- Install `gnome-extensions-cli` via `community.general.pipx` (so it's user-scoped, no system pip mess)
- `become_user: "{{ target_user }}"` for these tasks
- Loop over `files/extensions.yml`, calling `gext install <uuid>` with `creates:` guard for idempotency
- `gext enable <uuid>` for each

### Section 7 — Browser Configuration

- **Vivaldi:** add their DNF repo (or download .rpm), `dnf install vivaldi-stable`
- **Zen:** `community.general.flatpak: name: dev.zen_browser.Zen`
- **Config copy (Vivaldi):**
  - Task: kill any running vivaldi (`ansible.builtin.shell: pkill -f vivaldi` ignore_errors)
  - `ansible.builtin.copy: src: files/vivaldi/Default/ dest: /home/{{ target_user }}/.config/vivaldi/Default/ owner: ...`
- **Config copy (Zen):**
  - Same pattern: kill zen, copy `files/zen/Profiles/...` to `~target_user/.zen/Profiles/...`
  - First-run only logic for Zen: if profile dir doesn't exist, launch Zen once with `--headless` to create it, then copy
- `ansible.builtin.debug: msg: "Log in to Vivaldi and Zen manually for sync."` at end

### Section 8 — Extension Manager Install

- `community.general.flatpak: name: com.mattjakeman.ExtensionManager`
- Reason: keeps your existing GUI workflow intact

### Section 9 — Post-Run Notify

- Single `ansible.builtin.debug` with a multi-line message covering:
  - Reboot if kernel updated (`needs-restarting -r` equivalent or just the message)
  - Log out and back in for GNOME extensions + dconf
  - Launch both browsers, log in to accounts
  - If workspaces/spaces look wrong, set them up manually

---

## 4. The Dump Script — `dump-current-state.sh`

Run this on your CURRENT Fedora before reinstalling. It populates `lists/` and `files/`.

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
TARGET_USER="${1:-$(whoami)}"
HOME_DIR="/home/$TARGET_USER"

mkdir -p "$REPO/lists" "$REPO/files/dconf"

# DNF user-installed
dnf history userinstalled | tail -n +5 > "$REPO/lists/dnf-userinstalled.txt"

# Flatpaks
flatpak list --system --columns=application > "$REPO/lists/flatpak-system.txt"
flatpak list --user --columns=application > "$REPO/lists/flatpak-user.txt"

# dconf
dconf dump / > "$REPO/files/dconf/gnome-settings.ini"

# GNOME extensions
pipx install gnome-extensions-cli 2>/dev/null || true
~/.local/bin/gext list --all --no-color > "$REPO/files/extensions-installed.txt"

# Vivaldi
mkdir -p "$REPO/files/vivaldi/Default"
[ -f "$HOME_DIR/.config/vivaldi/Default/Preferences" ] && \
    cp "$HOME_DIR/.config/vivaldi/Default/Preferences" "$REPO/files/vivaldi/Default/"
[ -f "$HOME_DIR/.config/vivaldi/Default/Local State" ] && \
    cp "$HOME_DIR/.config/vivaldi/Default/Local State" "$REPO/files/vivaldi/Default/"

# Zen
mkdir -p "$REPO/files/zen"
[ -f "$HOME_DIR/.zen/profiles.ini" ] && cp "$HOME_DIR/.zen/profiles.ini" "$REPO/files/zen/"
ZEN_PROFILE=$(grep '^Path=' "$HOME_DIR/.zen/profiles.ini" | head -1 | cut -d= -f2)
if [ -n "$ZEN_PROFILE" ]; then
    mkdir -p "$REPO/files/zen/$ZEN_PROFILE"
    cp "$HOME_DIR/.zen/$ZEN_PROFILE/containers.json" "$REPO/files/zen/$ZEN_PROFILE/" 2>/dev/null || true
    cp "$HOME_DIR/.zen/$ZEN_PROFILE/prefs.js" "$REPO/files/zen/$ZEN_PROFILE/" 2>/dev/null || true
    cp -r "$HOME_DIR/.zen/$ZEN_PROFILE/storage" "$REPO/files/zen/$ZEN_PROFILE/" 2>/dev/null || true
fi

echo "Dump complete. Review files/ and lists/ before committing."
```

After running: review `files/extensions-installed.txt` and `lists/*` — clean up anything you don't want replicated.

---

## 5. First-Run on Fresh Fedora (after `dnf install` of Fedora 44)

```bash
# 1. Install Ansible + git
sudo dnf install -y ansible-core git

# 2. Set up SSH key for GitHub (if not already)
ssh-keygen -t ed25519 -C "your@email"
# Add ~/.ssh/id_ed25519.pub to GitHub

# 3. Clone the repo locally (to set up requirements.yml etc.)
git clone git@github.com:you/fedora-setup.git ~/fedora-setup
cd ~/fedora-setup

# 4. Install the Galaxy collection (only on first run)
ansible-galaxy collection install -r requirements.yml

# 5. Dry run to catch obvious errors
ansible-playbook setup.yml --check --diff

# 6. Real run (uses the playbook from the repo, not a clone)
ansible-pull -U git@github.com:you/fedora-setup.git -C main setup.yml

# 7. Follow the playbook's notify checklist
```

Subsequent runs (after initial setup):

```bash
cd ~/fedora-setup
make apply   # or run the ansible-pull command directly
```

The `Makefile`:

```makefile
REPO_URL := git@github.com:you/fedora-setup.git
PLAYBOOK := setup.yml

apply:
	ansible-pull -U $(REPO_URL) -C main $(PLAYBOOK)

dry-run:
	ansible-pull -U $(REPO_URL) -C main $(PLAYBOOK) --check --diff

dump:
	./dump-current-state.sh $(USER)
```

---

## 6. Learning Path — Build Order (for a newbie)

Since you're new to Ansible and want to do this yourself, build in this order so each step is verifiable before the next:

1. **Repo + Makefile + inventory + vars.yml + ansible.cfg + requirements.yml** — empty skeleton; commit.
2. **`dump-current-state.sh`** — run it on current Fedora; commit the output; verify `lists/` and `files/` look right.
3. **Section 1 (Bootstrap) + Section 2 (System Prep)** — run on fresh Fedora; verify `dnf repolist` shows RPM Fusion, Flatpak remotes, system upgraded.
4. **Section 3 (DNF packages)** — read `lists/dnf-userinstalled.txt`, write the loop; run on fresh Fedora; verify packages installed.
5. **Section 4 (Flatpak packages)** — same pattern; verify.
6. **Section 5 (dconf)** — start with one key (e.g., favorite apps); test on fresh Fedora; then add bulk `dconf load`.
7. **Section 6 (Extensions)** — install `gext`, then loop all UUIDs.
8. **Section 7 (Browsers)** — Vivaldi first, then Zen (Zen's profile-dir creation is the trickiest).
9. **Section 8 + 9 (Extension Manager + notify)** — finalize.

We will walk through each section in turn.

---

## 7. Risks & Caveats to Acknowledge

- **Workspaces/Spaces state copy may fail** — IndexedDB/LevelDB are fragile to copy. You tested sync and it didn't work; if direct copy fails too, you'll do it manually. Plan accounts for this.
- **GNOME extension compatibility with GNOME 44** — verify each extension UUID works on GNOME Shell 44 before locking it in.
- **dconf user-level needs a DBus session** — the module handles this via `dbus-run-session` fallback, but the first run may need to happen AFTER you've logged into GNOME once (so the home dir and D-Bus are set up).
- **Browser config copy requires browsers to be closed** — handled via `pkill` tasks, but you may want to add a warning.
- **Vivaldi's DNF repo** — their official repo URL rotates; check `vivaldi.com/download` for the current one before you commit a broken URL.
- **`ansible-pull` + first run** — `ansible-pull` does NOT bootstrap Ansible itself; you must `sudo dnf install ansible-core` once before first invocation.