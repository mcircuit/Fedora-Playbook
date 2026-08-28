# Project Progress

Tracks the Fedora GNOME post-install automation project status. This is the single source of truth for which sections are done, in progress, or pending. Updated by the agent after each completed section.

## How this file is maintained

- **Who:** the agent updates this file after verifying a section is complete (per AGENTS.md rule #8).
- **When:** immediately after verification — same turn as the verification message to the user.
- **What changes:** the row for that section's status flips to `Done`, `Skipped`, or remains `In progress` if the section is partial.
- **What stays the same:** the row order, the section labels, and the "Notes" column (unless notes need updating).
- **Add new sections:** only when explicitly asked by the user or when `context/PLAN.md` introduces them.

## Status

| Section | Status | Notes |
|---|---|---|
| **1.1.1 — `git init -b main`** | Done | `.git/` initialized with `main` branch |
| **1.1.2 — `.gitignore`** | Skipped | Deferred per user preference until noise appears |
| **1.1.3 — `README.md`** | Done | Includes Usage block, Verifying section, pointer to PLAN.md |
| **1.1.4 — `inventory`** | Done | Single line: `localhost ansible_connection=local` |
| **1.1.5 — `vars.yml`** | Done | `target_user: merlin`, `target_home` (templated), `expected_hostname: merlin-pc` |
| **1.1.6 — `requirements.yml`** | Done | `community.general` version `>=8.0.0`; YAML parses cleanly |
| **1.1.7 — `setup.yml` skeleton** | Done | One play, safety check + debug placeholder; `syntax-check` passes |
| **1.1.8 — `Makefile`** | Done | 5 targets + help; TAB-indented recipes verified; `make syntax-check` passes |
| **1.1.9 — first commit** | Done | User made initial commit `cec1d3d` |
| **1.1.10 — verification** | Done | `make syntax-check` passes; `make lint` passes (0 failures, profile `production`) |
| **1.2 — `dump-current-state.sh`** | Done | Script runs end-to-end. Captured: 427 DNF packages, 19 system Flatpaks, 481-line dconf dump, 14 extensions, Vivaldi `Preferences`. **Known gap:** Zen block incomplete — script assumed `~/.zen/` but Zen is installed via Flatpak, config lives at `~/.var/app/app.zen_browser.zen/.zen/`. Also `head -1` selects the empty default profile, missing the 375 MB "release" profile. Fix needed before fresh-install playbook Section 1.8 will capture Zen correctly. Two non-obvious workarounds applied during dev: `dnf5` dropped `history userinstalled` (now using `dnf repoquery --userinstalled`); `gext --no-color` must precede the subcommand. |
| **1.3 — Playbook sections 1 + 2 (Bootstrap + System Prep)** | Done | Section 1 (Bootstrap) + Section 2 base (RPM Fusion release install → base tools incl. `dnf-plugins-core` → enable RPM Fusion repos → Flathub remote → `dnf upgrade`) all in `tasks:` block; `syntax-check` and `lint` pass (0 failures, profile `production`). User caught and corrected task ordering during review. |
| **1.3-ext — Section 2 extensions (ffmpeg / @core / fwupdmgr / NVIDIA)** | Pending | Added per `init.pdf` after the original 1.3 was verified. ffmpeg-free → ffmpeg swap, `@core` group upgrade, `fwupdmgr get-updates` + `fwupdmgr update`, NVIDIA `akmod-nvidia` + `xorg-x11-drv-nvidia-cuda`. Playbook updated; `syntax-check` and `lint` pass. VM verification pending. |
| **1.3a — Section 2a (GRUB backlight fix)** | Pending | Added per `init.pdf`. `ansible.builtin.lineinfile` rewrites `GRUB_CMDLINE_LINUX` with `acpi_backlight=native` while preserving the existing NVIDIA + nouveau blacklist entries. `grub2-mkconfig` runs via a handler (notified only on lineinfile change). `backup: yes` creates a timestamped backup. Playbook updated; `syntax-check` and `lint` pass. VM verification pending (skip auto-reboot — reboot must be manual after VM test). |
| **1.3b — Section 2b (Docker CE install + user setup)** | Pending | Added per `init.pdf`. Removes 10 legacy `docker*` packages, adds `docker-ce` repo (RPM-style with `gpgkey`), installs `docker-ce` + `docker-ce-cli` + `containerd.io` + `docker-buildx-plugin` + `docker-compose-plugin`, enables+starts the service via `ansible.builtin.systemd_service`, ensures `docker` group exists, adds `{{ target_user }}` to the group with `append: yes`. Playbook updated; `syntax-check` and `lint` pass. VM verification pending. |
| **1.3c — Section 2c (Vivaldi native RPM)** | Pending | Added per `init.pdf`. Adds Vivaldi repo (RPM-style), installs `vivaldi-stable` natively instead of as a Flatpak (avoids Flatpak sandboxing friction). Dump file `lists/flatpak-system.txt` does not include Vivaldi, so no Flatpak install needed. Playbook updated; `syntax-check` and `lint` pass. VM verification pending. |
| **1.4 — Playbook section 3 (DNF packages)** | Done | Uses `slurp` + `b64decode` instead of `lookup('lines', …)` to avoid a VM lookup permission issue; `failed_when: false` + `# noqa: ignore-errors` to skip packages unavailable on fresh Fedora. VM-verified: first run installs packages, second run `changed=0` (idempotent). |
| **1.5 — Playbook section 4 (Flatpak packages)** | Done | Two slurp-based reads (system + user), `community.general.flatpak` with `method: system` and `method: user` (`become_user: "{{ target_user }}"` for the latter), `when:` guard skips empty lists, `failed_when: false` + noqa for unavailable Flatpaks. VM-verified: `syntax-check` + `lint` pass, `make apply` runs the system-Flatpak install task (user-Flatpak skipped via the empty `when:` guard). |
| **1.5a — Section 4.5 (Signal flatpak override)** | Pending | Added per `init.pdf` to fix Signal's plain-text password storage. `flatpak override --env=SIGNAL_PASSWORD_STORE=gnome-libsecret org.signal.Signal` (via `ansible.builtin.command`; no dedicated module exists). Must run AFTER Section 4 installs Signal; wrapped in `become: true` + `become_user: "{{ target_user }}"` + `failed_when: false` (silently no-op if Signal not present yet). Playbook updated; `syntax-check` and `lint` pass. VM verification pending. |
| **1.6 — Playbook section 5 (dconf)** | Pending | Depends on `files/dconf/gnome-settings.ini` from section 1.2 |
| **1.7 — Playbook section 6 (Extensions)** | Pending | Depends on `files/extensions.yml` from section 1.2 |
| **1.8 — Playbook section 7 (Browsers)** | Pending | Depends on `files/vivaldi/Default/`, `files/zen/...` from section 1.2; |
| **1.9 — Playbook sections 8 + 9 (Extension Manager + notify)** | Pending | Finalize |
| **2.1 — VM provisioning (GNOME Boxes + Fedora 44 image + snapshot)** | Done | VM ready, "clean-fedora44-base" snapshot taken |
| **2.2 — SSH key authorized on GitHub from VM** | Done | `fedora-vm-fedoraplaysbook` key authorized; clone works |
| **2.3 — VM verification rounds** | In progress | Section 1.3 verified (8 ok / 2 changed / 1 skipped / failed=0; idempotent changed=0); Section 1.4 verified (slurp approach; idempotent changed=0); Section 1.5 verified (`syntax-check` + `lint` pass, `make apply` runs system Flatpak install, user Flatpak skipped via `when:` guard). Pending VM verifications: 1.3-ext (system prep extensions), 1.3a (GRUB), 1.3b (Docker), 1.3c (Vivaldi native), 1.5a (Signal override). |
| **3.1 — Fresh Fedora 44 install on laptop** | Pending | |
| **3.2 — `ansible-pull` real run** | Pending | |
| **3.3 — Manual follow-ups** | Pending | Browser login, GNOME session restart |

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