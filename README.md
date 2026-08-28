# Fedora GNOME Post-Install Setup

Automated post-install setup for Fedora GNOME 44 (single user, single laptop) using Ansible.

## Usage

First run (on a freshly installed Fedora):

    sudo dnf install -y ansible-core ansible-lint pipx git
    ssh-keygen -t ed25519 -C "your@email"   # if not already
    git clone git@github.com:mcircuit/Fedora-Playbook.git ~/Fedora-Playbook
    cd ~/Fedora-Playbook
    ansible-galaxy collection install -r requirements.yml
    make syntax-check    # parse only — no execution
    make lint            # static analysis 
    make dry-run         # shows what would change (does NOT modify the system)
    make apply # real run via ansible-pull

Subsequent runs:

    cd ~/fedora-setup
    make apply

See `context/PLAN.md` for the full plan.
