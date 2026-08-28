#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
TARGET_USER="${1:-$(whoami)}"
HOME_DIR="/home/$TARGET_USER"

mkdir -p "$REPO/lists" "$REPO/files/dconf"

# DNF user-installed
dnf repoquery --userinstalled > "$REPO/lists/dnf-userinstalled.txt"

# Flatpaks
flatpak list --system --columns=application > "$REPO/lists/flatpak-system.txt"
flatpak list --user --columns=application > "$REPO/lists/flatpak-user.txt"

# dconf
dconf dump / > "$REPO/files/dconf/gnome-settings.ini"

# GNOME extensions
pipx install gnome-extensions-cli 2>/dev/null || true
~/.local/bin/gext --no-color list --all  > "$REPO/files/extensions-installed.txt"

# Vivaldi
mkdir -p "$REPO/files/vivaldi/Default"
[ -f "$HOME_DIR/.config/vivaldi/Default/Preferences" ] && \
    cp "$HOME_DIR/.config/vivaldi/Default/Preferences" "$REPO/files/vivaldi/Default/"
[ -f "$HOME_DIR/.config/vivaldi/Default/Local State" ] && \
    cp "$HOME_DIR/.config/vivaldi/Default/Local State" "$REPO/files/vivaldi/Default/"

# Zen (Flatpak install — data lives in ~/.var/app/)
ZEN_DIRS=()
[ -f "$HOME_DIR/.var/app/app.zen_browser.zen/.zen/profiles.ini" ] && \
    ZEN_DIRS+=("$HOME_DIR/.var/app/app.zen_browser.zen/.zen")
[ -f "$HOME_DIR/.zen/profiles.ini" ] && \
    ZEN_DIRS+=("$HOME_DIR/.zen")

if [ ${#ZEN_DIRS[@]} -gt 0 ]; then
    mkdir -p "$REPO/files/zen"
    # Pick the most recently modified Zen profile dir across all detected installs
    LATEST_ZEN_DIR=""
    LATEST_ZEN_MTIME=0
    for ZEN_DIR in "${ZEN_DIRS[@]}"; do
        cp "$ZEN_DIR/profiles.ini" "$REPO/files/zen/profiles-${ZEN_DIR//\//_}.ini"
        while IFS= read -r PROFILE_PATH; do
            [ -z "$PROFILE_PATH" ] && continue
            PROFILE_DIR="$ZEN_DIR/$PROFILE_PATH"
            if [ -d "$PROFILE_DIR" ]; then
                MTIME=$(stat -c %Y "$PROFILE_DIR" 2>/dev/null || echo 0)
                if [ "$MTIME" -gt "$LATEST_ZEN_MTIME" ]; then
                    LATEST_ZEN_MTIME=$MTIME
                    LATEST_ZEN_DIR=$PROFILE_DIR
                fi
            fi
        done < <(grep '^Path=' "$ZEN_DIR/profiles.ini" 2>/dev/null | cut -d= -f2)
    done
    if [ -n "$LATEST_ZEN_DIR" ]; then
        PROFILE_NAME=$(basename "$LATEST_ZEN_DIR")
        mkdir -p "$REPO/files/zen/$PROFILE_NAME"
        [ -f "$LATEST_ZEN_DIR/containers.json" ] && \
            cp "$LATEST_ZEN_DIR/containers.json" "$REPO/files/zen/$PROFILE_NAME/"
        [ -f "$LATEST_ZEN_DIR/prefs.js" ] && \
            cp "$LATEST_ZEN_DIR/prefs.js" "$REPO/files/zen/$PROFILE_NAME/"
        [ -d "$LATEST_ZEN_DIR/storage" ] && \
            cp -r "$LATEST_ZEN_DIR/storage" "$REPO/files/zen/$PROFILE_NAME/"
        echo "Zen: dumped profile '$PROFILE_NAME' from $LATEST_ZEN_DIR"
    fi
fi

echo "Dump complete. Review files/ and lists/ before committing."