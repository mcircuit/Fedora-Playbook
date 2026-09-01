# Project Progress

Tracks the Fedora GNOME post-install automation project status. Each playbook section has a row with: **expected state**, **VM test**, and **user confirmation**. Updated by the agent after each section is verified on the VM or after the user confirms the expected state (per AGENTS.md rule #8).

## How this file is maintained

- **Who:** the agent updates this file after each section is verified on the VM, or after the user confirms the expected state.
- **When:** immediately after verification or confirmation — same turn as the message to the user.
- **What changes:** the "VM test" column reflects the latest VM run result; the "User confirmation" column flips from `Pending` to `Confirmed` (or `NOT confirmed` with reason) when the user verifies the expected state.
- **Test methods used:** (1) VM-based dry runs on Fedora Boxes, (2) **live end-to-end test on a fresh Fedora install on the user's physical laptop (Lenovo Legion 5 Pro 16ACH6H)**. The live test is the more authoritative of the two.
- **Add new sections:** when `context/PLAN.md` §3 introduces them.

## Status

| Section | Expected state | VM test | User confirmation |
|---|---|---|---|
| **1.1 — Skeleton** | All required files exist (`Makefile`, `inventory`, `vars.yml`, `requirements.yml`, `setup.yml`); `make syntax-check` and `make lint` pass | Run locally (not on VM — these are dev-machine file creations) | Confirmed |
| **1.2 — `dump-current-state.sh`** | `lists/dnf-userinstalled.txt` (~427 lines), `lists/flatpak-system.txt` (19 lines), `lists/flatpak-user.txt`, `files/dconf/gnome-settings.ini` (~500 lines), `files/extensions-installed.txt` (14 ext), `files/vivaldi/Default/{Preferences,Local State}` populated | Run locally | Confirmed (with known gaps: Zen block incomplete — uses `~/.zen/` but Zen is Flatpak-installed; `head -1` picks empty default profile missing 375 MB "release" profile) |
| **Section 1 — Bootstrap** | `ansible-core` installed (latest available); `community.general 13.3.0` collection installed at `~/.ansible/collections/ansible_collections/community/general/`; `ansible-galaxy collection list` shows both | Run on VM, ok + **live end-to-end test on fresh Fedora install (physical laptop) — all init.pdf tasks passed including Section 1** | Confirmed |
| **Section 2 — System Prep (base: RPM Fusion + base tools + Flathub + `dnf upgrade`)** | `dnf repolist \| grep rpmfusion` shows `rpmfusion-free` and `rpmfusion-nonfree` enabled; `which git wget curl pipx dnf-plugins-core` returns paths; `flatpak remotes` shows `flathub`; `dnf check-update` is empty | Run on VM (8 ok / 2 changed / 1 skipped / failed=0; idempotent — changed=0 on 2nd run) + **live end-to-end test on fresh Fedora install (physical laptop) — base System Prep passed** | Confirmed |
| **Section 2 — extensions (ffmpeg / `@core` / fwupdmgr / NVIDIA)** | `rpm -q ffmpeg` shows ffmpeg (not ffmpeg-free); `dnf group list installed` shows core updated; `fwupdmgr get-updates` returns output without error; `rpm -q akmod-nvidia xorg-x11-drv-nvidia-cuda` installed; `nvidia-smi` shows RTX 3070 | Run on VM (initial run failed at ffmpeg swap with depsolve error; **fixed** with `allowerasing: true`; second run succeeded end-to-end for all four sub-items) + **live end-to-end test on fresh Fedora install (physical laptop) — all four extensions passed** | **Confirmed** (ffmpeg-free removed + ffmpeg installed, `@core` group updated, fwupdmgr runs cleanly, NVIDIA driver working) |
| **Section 2a — GRUB backlight fix** | `grep GRUB_CMDLINE_LINUX /etc/default/grub` shows `acpi_backlight=native`; existing NVIDIA + nouveau blacklist entries still in the line; `grubby --info=DEFAULT` shows `acpi_backlight=native` in the kernel boot args; brightness keys work after manual reboot | Run on VM (initially lineinfile + grub2-mkconfig only updated /etc/default/grub, not the BLS kernel entry; **fixed** by adding a `grubby` task to update BLS directly) + **live end-to-end test on fresh Fedora install (physical laptop) — GRUB line written and BLS cmdline updated** | **Confirmed** (file-level + BLS kernel cmdline both have the parameter; manual reboot still required for brightness keys to actually work) |
| **Section 2b — Docker CE install + user setup** | `docker --version` works; `systemctl status docker` shows `active (running)`; `groups $USER` includes `docker` (after logout/login); no leftover old `docker*` packages | Run on VM (initial run failed at cleanup step with depsolve error — `passt-selinux` blocked `docker-selinux` removal; **fixed** with `allowerasing: true`; second run succeeded end-to-end) + **live end-to-end test on fresh Fedora install (physical laptop) — Docker installed and service running** | **Confirmed** (Docker CE 29.7.2 installed, docker.service active, user `merlin` in docker group) |
| **Section 2c — Vivaldi native RPM** | `rpm -q vivaldi-stable` shows installed; `which vivaldi` returns `/usr/bin/vivaldi`; Vivaldi launches; user signs in | Run on VM (failed at install — wrong `baseurl`; **fixed** by changing to `https://repo.vivaldi.com/archive/rpm/$basearch`; re-run after fix succeeded) + **live end-to-end test on fresh Fedora install (physical laptop) — Vivaldi installed and opened** | **Confirmed** (Vivaldi installed and opened in VM) |
| **Section 3 — DNF Packages from Auto-Dump** | All 427 packages from `lists/dnf-userinstalled.txt` are installed (some skipped via `failed_when: false` if unavailable on the fresh Fedora); `dnf repoquery --userinstalled \| wc -l` ≥ 427; `comm -23 <(dnf repoquery --userinstalled \| sort -u) <(sort -u lists/dnf-userinstalled.txt)` is small (just base-Fedora adds) | Run on VM (changed=N large, idempotent — changed=0 on 2nd run) — **live test on fresh system did not include Section 3 (no dump data on fresh install — section was a no-op)** | Confirmed |
| **Section 4 — Flatpak Packages from Auto-Dump** | `flatpak list --columns=application` shows 19 apps from the dump (Zen, Bitwarden, Discord, Extension Manager, Amberol, Obsidian, Resources, Thunderbird, OnlyOffice, Signal + 9 runtimes/SDKs) | Run on VM (silent failure — `changed=0` but 0 flatpaks installed; root D-Bus issue with `community.general.flatpak` under `become: true`; **needs fix** — likely switch to user-scope or `become_user: "{{ target_user }}"` with `become: true`) — **live test on fresh system did not include Section 4 (no dump data on fresh install — section was a no-op)** | NOT confirmed (silent failure — see VM test) |
| **Section 4.5 — Signal flatpak override** | `flatpak override --show org.signal.Signal` shows `SIGNAL_PASSWORD_STORE=gnome-libsecret`; Signal stores encryption keys in GNOME keyring (not plain text) | Not run — **live test on fresh system explicitly excluded the Signal override per user ("except the signal password section")** | **Blocked by Section 4** — `flatpak override --show org.signal.Signal` returns empty on VM, meaning Signal isn't installed yet (Section 4's flatpak install has the silent-failure bug, so Signal never got installed, and the override task was a no-op). Will verify once Section 4 is fixed. |
| **Section 5 — dconf** | `dconf dump /` matches `files/dconf/gnome-settings.ini` (favorites, dark mode, keybindings, etc. all restored) | Not run — **live test on fresh system did not include Section 5 (no dump data — section was a no-op)** | Pending |
| **Section 6 — Extensions** | `gext list --user --no-color` (run as `{{ target_user }}`) shows all UUIDs from `files/extensions.yml` as enabled | Not run — **live test on fresh system did not include Section 6 (no dump data — section was a no-op)** | Pending |
| **Section 7 — Browsers** | Vivaldi (native) installed and signed in; Zen (Flatpak) installed and signed in; `files/vivaldi/Default/` and `files/zen/<profile>/` exist on VM; user manually signed in to both | Not run — **live test on fresh system did not include Section 7 (no dump data — section was a no-op for the config-copy parts; the native Vivaldi and Zen flatpak were installed by Sections 2c and the dump)** | Pending (manual sign-in step required) |
| **Section 8 — Extension Manager** | `flatpak list --columns=application` shows `com.mattjakeman.ExtensionManager` | Not run — **live test on fresh system did not include Section 8 (no dump data — section was a no-op)** | Pending |
| **Section 9 — Post-Run Notify** | Playbook prints a multi-line notify message at the end covering: reboot if kernel updated, logout/login for GNOME, log in to Vivaldi and Zen, manually set up workspaces/spaces if needed | Not run — **live test on fresh system did not include Section 9 explicitly (the live test reported "all init.pdf tasks done" without a final post-run notify step)** | Pending |

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
