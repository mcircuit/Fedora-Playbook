things to add to the Playbook:

- Install flatpak apps,
- fix signal password (maybe?)
- install DNF packages
- setup system extensions
- configure system wide settings
- setup browsers

ansible-playbook setup.yml --start-at-task="Remove any pre-existing docker packages" -Kv