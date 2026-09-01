# Fedora GNOME Post-Install Setup

Automated post-install setup for Fedora GNOME 44 (single user, single laptop) using Ansible.

## Usage

Before running the playbook on a fresh install of Fedora, **DISABLE SECURE BOOT!** (needed for NVIDIA drivers installation)

### 1. Install required packages

    sudo dnf install -y ansible-core ansible-lint pipx git make

### 2. Generate ssh key and add it to your github account

    ssh-keygen -t ed25519 -C "fedora-key"   # if not already

Replace 'fedora-key' with any name of your choice.

### 3. Clone the repo 

    git clone https://github.com/mcircuit/Fedora-Playbook.git ~/Fedora-Playbook

Change directory into the repo's directory:

    cd ~/Fedora-Playbook

Install the requirements for the repo:

    ansible-galaxy collection install -r requirements.yml

### 4. Check the playbook

    make syntax-check    # parse only — no execution
    make lint            # static analysis 
    make dry-run         # shows what would change (does NOT modify the system)

### 5. Run the playbook

    make apply # real run via ansible-pull

See `context/PLAN.md` for the full plan.
