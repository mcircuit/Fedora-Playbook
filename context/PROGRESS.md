# Project Progress

Tracks the Fedora GNOME post-install automation project status. Each playbook section has a row with: **expected state**, **VM test**, and **user confirmation**. Updated by the agent after each section is verified on the VM or after the user confirms the expected state (per AGENTS.md rule #8).

## How this file is maintained

- **Who:** the agent updates this file after each section is verified on the VM, or after the user confirms the expected state.
- **When:** immediately after verification or confirmation — same turn as the message to the user.
- **What changes:** the "VM test" column reflects the latest VM run result; the "User confirmation" column flips from `Pending` to `Confirmed` (or `NOT confirmed` with reason) when the user verifies the expected state.
- **Add new sections:** when `context/PLAN.md` §3 introduces them.

## Status

| Section | Expected state | VM test | User confirmation |
|---|---|---|---|
| **1.1 — Skeleton** | All required files exist (`Makefile`, `inventory`, `vars.yml`, `requirements.yml`, `setup.yml`); `make syntax-check` and `make lint` pass | Run locally (not on VM — these are dev-machine file creations) | Confirmed |
| **1.2 — `dump-current-state.sh`** | `lists/dnf-userinstalled.txt` (~427 lines), `lists/flatpak-system.txt` (19 lines), `lists/flatpak-user.txt`, `files/dconf/gnome-settings.ini` (~500 lines), `files/extensions-installed.txt` (14 ext), `files/vivaldi/Default/{Preferences,Local State}` populated | Run locally | Confirmed (with known gaps: Zen block incomplete — uses `~/.zen/` but Zen is Flatpak-installed; `head -1` picks empty default profile missing 375 MB "release" profile) |
| **Section 1 — Bootstrap** | `ansible-core` installed (latest available); `community.general 13.3.0` collection installed at `~/.ansible/collections/ansible_collections/community/general/`; `ansible-galaxy collection list` shows both | Run on VM, ok | Confirmed |
| **Section 2 — System Prep (base: RPM Fusion + base tools + Flathub + `dnf upgrade`)** | `dnf repolist \| grep rpmfusion` shows `rpmfusion-free` and `rpmfusion-nonfree` enabled; `which git wget curl pipx dnf-plugins-core` returns paths; `flatpak remotes` shows `flathub`; `dnf check-update` is empty | Run on VM (8 ok / 2 changed / 1 skipped / failed=0; idempotent — changed=0 on 2nd run) | Confirmed |
| **Section 2 — extensions (ffmpeg / `@core` / fwupdmgr / NVIDIA)** | `rpm -q ffmpeg` shows ffmpeg (not ffmpeg-free); `dnf group list installed` shows core updated; `fwupdmgr get-updates` returns output without error; `rpm -q akmod-nvidia xorg-x11-drv-nvidia-cuda` installed; `nvidia-smi` shows RTX 3070 | Run on VM (failed at ffmpeg swap with depsolve error; **fixed** with `allowerasing: true`; not yet re-run past ffmpeg) | Pending |
| **Section 2a — GRUB backlight fix** | `grep GRUB_CMDLINE_LINUX /etc/default/grub` shows `acpi_backlight=native`; existing NVIDIA + nouveau blacklist entries still in the line; brightness keys work after manual reboot | In progress (playbook uses handler + `backup: true`; manual reboot required after VM test) | Pending |
| **Section 2b — Docker CE install + user setup** | `docker --version` works; `systemctl status docker` shows `active (running)`; `groups $USER` includes `docker` (after logout/login); no leftover old `docker*` packages | Run on VM (failed at cleanup step with depsolve error — `passt-selinux` blocked `docker-selinux` removal; **fixed** with `allowerasing: true`; not yet re-run past Docker cleanup) | Pending |
| **Section 2c — Vivaldi native RPM** | `rpm -q vivaldi-stable` shows installed; `which vivaldi` returns `/usr/bin/vivaldi`; Vivaldi launches; user signs in | Not run | Pending |
| **Section 3 — DNF Packages from Auto-Dump** | All 427 packages from `lists/dnf-userinstalled.txt` are installed (some skipped via `failed_when: false` if unavailable on the fresh Fedora); `dnf repoquery --userinstalled \| wc -l` ≥ 427; `comm -23 <(dnf repoquery --userinstalled \| sort -u) <(sort -u lists/dnf-userinstalled.txt)` is small (just base-Fedora adds) | Run on VM (changed=N large, idempotent — changed=0 on 2nd run) | Confirmed |
| **Section 4 — Flatpak Packages from Auto-Dump** | `flatpak list --columns=application` shows 19 apps from the dump (Zen, Bitwarden, Discord, Extension Manager, Amberol, Obsidian, Resources, Thunderbird, OnlyOffice, Signal + 9 runtimes/SDKs) | Run on VM (silent failure — `changed=0` but 0 flatpaks installed; root D-Bus issue with `community.general.flatpak` under `become: true`; **needs fix** — likely switch to user-scope or `become_user: "{{ target_user }}"` with `become: true`) | NOT confirmed (silent failure — see VM test) |
| **Section 4.5 — Signal flatpak override** | `flatpak override --show org.signal.Signal` shows `SIGNAL_PASSWORD_STORE=gnome-libsecret`; Signal stores encryption keys in GNOME keyring (not plain text) | Not run | Pending |
| **Section 5 — dconf** | `dconf dump /` matches `files/dconf/gnome-settings.ini` (favorites, dark mode, keybindings, etc. all restored) | Not run | Pending |
| **Section 6 — Extensions** | `gext list --user --no-color` (run as `{{ target_user }}`) shows all UUIDs from `files/extensions.yml` as enabled | Not run | Pending |
| **Section 7 — Browsers** | Vivaldi (native) installed and signed in; Zen (Flatpak) installed and signed in; `files/vivaldi/Default/` and `files/zen/<profile>/` exist on VM; user manually signed in to both | Not run | Pending (manual sign-in step required) |
| **Section 8 — Extension Manager** | `flatpak list --columns=application` shows `com.mattjakeman.ExtensionManager` | Not run | Pending |
| **Section 9 — Post-Run Notify** | Playbook prints a multi-line notify message at the end covering: reboot if kernel updated, logout/login for GNOME, log in to Vivaldi and Zen, manually set up workspaces/spaces if needed | Not run | Pending |

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
