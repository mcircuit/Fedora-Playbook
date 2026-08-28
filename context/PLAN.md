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
- **Swap ffmpeg-free → ffmpeg** (full codec set from RPM Fusion): remove `ffmpeg-free`, install `ffmpeg`
- **Upgrade `@core` group**: `ansible.builtin.dnf: name: "@core" state: present`
- **Firmware updates:** `fwupdmgr get-updates` (informational, read-only) + `fwupdmgr update --assume-yes` (writes firmware)
- **NVIDIA proprietary driver:** `ansible.builtin.dnf: name: [akmod-nvidia, xorg-x11-drv-nvidia-cuda] state: present` (requires RPM Fusion Nonfree)

### Section 2a — Hardware tweaks (GRUB backlight fix)

- `ansible.builtin.lineinfile: path: /etc/default/grub regexp: '^GRUB_CMDLINE_LINUX=' line: '...' backup: yes` — preserves the full GRUB line (including the existing NVIDIA blacklist + nouveau modprobe entries), just adding/editing the backlight parameter
- `ansible.builtin.command: grub2-mkconfig -o /boot/grub2/grub.cfg` — regenerate, gated on the lineinfile reporting `changed`

### Section 2b — Docker CE install + user setup

- `ansible.builtin.dnf: state: absent` for the 10 old `docker*` packages (idempotent cleanup)
- `ansible.builtin.yum_repository: name: docker-ce baseurl: https://download.docker.com/linux/fedora/$releasever/$basearch/stable gpgkey: https://download.docker.com/linux/fedora/gpg`
- `ansible.builtin.dnf: name: [docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin] state: present`
- `ansible.builtin.systemd_service: name: docker enabled: true state: started`
- `ansible.builtin.group: name: docker state: present` (idempotent — no-op if exists)
- `ansible.builtin.user: name: "{{ target_user }}" groups: docker append: yes` — add user to group (logout/login required to take effect)

### Section 2c — Vivaldi native RPM install (replaces Flatpak)

- `ansible.builtin.yum_repository: name: vivaldi baseurl: https://repo.vivaldi.com/archive/vivaldi/fedora/$releasever/$basearch gpgkey: https://repo.vivaldi.com/archive/linux_signing_key.pub`
- `ansible.builtin.dnf: name: vivaldi-stable state: present`

Note: Vivaldi is intentionally NOT in the Flatpak dump loop (Section 4). The user is migrating to the native RPM per init.pdf.

### Section 3 — DNF Packages from Auto-Dump

- Reads `lists/dnf-userinstalled.txt` into a list variable
- One `ansible.builtin.dnf` task with `loop: "{{ packages_dnf }}"`

### Section 4 — Flatpak Packages

- `community.general.flatpak` module with `loop`, separate loops for system vs user Flatpaks (system Flatpaks need `become: true`)
- **`community.general.flatpak_override` (via `command`)** for Signal: `flatpak override --env=SIGNAL_PASSWORD_STORE=gnome-libsecret org.signal.Signal` — runs after Signal flatpak is installed in the dump loop

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

The build runs in three phases. **Phase 1** develops on the **current Fedora** (the dev machine). **Phase 2** verifies on a **Fedora VM** (disposable, snapshotted, emulates a future fresh install). **Phase 3** is the real test on the **laptop after a fresh install**.

### Phase 1 — Develop (current Fedora, safe iteration)

1. **Repo skeleton** — `Makefile`, `inventory`, `vars.yml`, `requirements.yml`, `setup.yml` (play header only). Commit. *(Sections 1.1.1–1.1.10, done.)*
2. **`dump-current-state.sh`** — run it on the current Fedora; commit the output; verify `lists/` and `files/` look right. *(Section 1.2.)*
3. **Develop playbook sections one at a time**, with this iteration loop:
   - Write the section
   - `make syntax-check`
   - `make lint`
   - `ansible-playbook setup.yml --check --diff --tags <section>` for sections safe under check mode
   - `git commit` (one commit per section)
   
   Section order (respecting data dependencies from the dump and init.pdf-driven requirements):
   - Sections 1 + 2 (Bootstrap + System Prep — base: RPM Fusion, base tools, repos, Flathub, `dnf upgrade`)
   - **Section 2 extensions** (ffmpeg swap, `@core` group, `fwupdmgr` check + update, NVIDIA driver) — *added per init.pdf*
   - **Section 2a** (GRUB backlight fix) — *added per init.pdf*
   - **Section 2b** (Docker CE install + user setup) — *added per init.pdf*
   - **Section 2c** (Vivaldi native RPM) — *added per init.pdf*
   - Section 3 (DNF packages — depends on `lists/dnf-userinstalled.txt`)
   - Section 4 (Flatpak packages — depends on `lists/flatpak-*.txt`)
   - **Section 4.5** (Signal `flatpak override` for password store) — *added per init.pdf; runs after Signal is installed in 4*
   - Section 5 (dconf — needs a logged-in GNOME session; partial iterative testing)
   - Section 6 (Extensions — depends on `files/extensions.yml`)
   - Section 7 (Browsers — depends on `files/vivaldi/Default/`, `files/zen/...`)
   - Sections 8 + 9 (Extension Manager + notify — finalize)

   **Dependency notes for the new sections:**
   - Section 2 extensions must run before Section 3 (DNF dump) because some packages (e.g., NVIDIA deps) may pull from RPM Fusion Nonfree which is enabled in Section 2.
   - Section 2b (Docker) requires the docker-ce repo to be added (handled in-section) and runs before any section that uses Docker.
   - Section 2c (Vivaldi native) replaces the Vivaldi entry that would have come from the Flatpak dump. The dump file does not contain Vivaldi, so no Flatpak install of Vivaldi is needed.
   - Section 4.5 (Signal override) must run after Section 4 installs the Signal flatpak. The override will fail silently (due to `failed_when: false`) if Signal isn't installed yet.
   - Section 2a (GRUB) is independent but a botched `grub2-mkconfig` could break boot — keep `backup: yes` on the lineinfile and never auto-reboot as part of this section.

### Phase 2 — Verify on Fedora VM

After each section is committed, verify on a Fedora VM (GNOME Boxes / KVM). The VM is disposable; restore from a "just-installed Fedora 44" snapshot before each test run.

1. Restore the VM to its "just-installed Fedora 44" snapshot
2. From inside the VM: `ansible-pull -U git@github.com:mcircuit/Fedora-Playbook.git -C main setup.yml`
3. Observe the outcome — log in to GNOME, inspect settings, extensions, browsers
4. Re-run to confirm idempotency (second run reports `changed=0`)
5. If wrong: fix in the dev tree, `git push`, restore the VM snapshot, repeat
6. If right: move to the next section

**VM notes:**
- Use a separate SSH key on the VM (recommended), authorized on your GitHub account — distinct identity from the dev machine
- The VM provides a logged-in GNOME session, so dconf and extension tasks run in their natural environment
- This emulates the future fresh-install workflow without committing to a real reinstall

### Phase 3 — Real test on laptop after fresh Fedora install

After Phase 2 confirms every section works end-to-end:

1. Fresh install Fedora 44 on the real laptop
2. `sudo dnf install -y ansible-core ansible-lint git`
3. Authorize SSH key on GitHub
4. `ansible-pull -U git@github.com:mcircuit/Fedora-Playbook.git -C main setup.yml`
5. Follow the playbook's post-run notify checklist (reboot for kernel, logout/login for GNOME, log in to Vivaldi and Zen)

If Phase 2 was thorough, Phase 3 should just work.

### Why this three-phase order

- **Section dependencies drive order:** the dump must happen before sections that consume `lists/` and `files/` data.
- **VM is a cheaper proxy for fresh install:** bugs surface immediately, snapshot restore is instant vs reinstalling Fedora on the laptop.
- **Iterative commits make rollback safe:** each section is its own commit; revert one without touching the others.
- **`ansible-pull` is exercised for real on every iteration** (Phase 2), not just on the final fresh install.

---

## 7. Risks & Caveats to Acknowledge

- **Workspaces/Spaces state copy may fail** — IndexedDB/LevelDB are fragile to copy. You tested sync and it didn't work; if direct copy fails too, you'll do it manually. Plan accounts for this.
- **GNOME extension compatibility with GNOME 44** — verify each extension UUID works on GNOME Shell 44 before locking it in.
- **dconf user-level needs a DBus session** — the module handles this via `dbus-run-session` fallback, but the first run may need to happen AFTER you've logged into GNOME once (so the home dir and D-Bus are set up).
- **Browser config copy requires browsers to be closed** — handled via `pkill` tasks, but you may want to add a warning.
- **Vivaldi's DNF repo** — their official repo URL rotates; check `vivaldi.com/download` for the current one before you commit a broken URL.
- **`ansible-pull` + first run** — `ansible-pull` does NOT bootstrap Ansible itself; you must `sudo dnf install ansible-core` once before first invocation.
- **`fwupdmgr update` can brick hardware** — power loss mid-write or a buggy firmware can leave devices (especially UEFI) unbootable. Recovery is hardware-dependent. The same risk exists whether you run it manually or via the playbook. **Mitigation:** only run on AC power with battery ≥ 50% charged.
- **NVIDIA `akmod-nvidia` build takes 5-10 minutes on first boot** — the kernel module is compiled by the `akmods` systemd service. Don't reboot too quickly after `make apply`, or the nvidia driver won't be ready when the boot sequence needs it.
- **Docker group add requires logout/login** — `usermod -aG docker` adds the user to the group, but the new session inherits the old group list. Until the user starts a new login session, `docker` commands fail with "permission denied."
- **`dnf swap ffmpeg-free → ffmpeg` leaves a transient no-ffmpeg window** — the remove + install pair removes ffmpeg-free before installing ffmpeg. Usually safe (single-pass) but if anything between the two tasks crashes, the system has no ffmpeg.
- **GRUB config edit is reversible but only from a live boot** — `lineinfile backup: yes` creates a timestamped backup of `/etc/default/grub`, but if a botched `grub2-mkconfig` bricks the bootloader, recovery requires a live USB.