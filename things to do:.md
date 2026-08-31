things to do:

- Install flatpak apps,
- fix signal password (maybe?)
- install DNF packages
- setup system extensions
- configure system wide settings
- setup browsers

ansible-pull -U git@github.com:mcircuit/Fedora-Playbook.git -C main setup.yml -Kv 

ansible-playbook setup.yml --start-at-task="Remove any pre-existing docker packages" -Kv