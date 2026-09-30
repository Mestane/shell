#!/usr/bin/env bash
#
# bootstrap.sh — one-line installer: clones cykler-caelestia and hands off to install.sh.
#
# Usage (from anywhere, needs nothing checked out first):
#   curl -fsSL https://raw.githubusercontent.com/cykler01/cykler-caelestia/main/bootstrap.sh | bash
#
# Pass install.sh's own flags through after --:
#   curl -fsSL .../bootstrap.sh | bash -s -- -y
#   curl -fsSL .../bootstrap.sh | bash -s -- --install-deps false
#
# This script does nothing but clone the repo and exec its install.sh (see install.sh
# --help for what that does) - kept deliberately tiny and separate from install.sh so a
# curl | bash of it can't run anything else, and so install.sh keeps working exactly the
# same whether you get to it through this script or a manual git clone.

set -euo pipefail

REPO_URL="https://github.com/cykler01/cykler-caelestia.git"
DEST="cykler-caelestia"

# Same checks install.sh itself makes, done here too so a clone (the assets folder alone
# makes this a real download) isn't wasted on a machine that was going to fail anyway.
command -v pacman >/dev/null || { echo "This project only supports Arch Linux." >&2; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Run this as your normal user, not root (sudo is used where needed)." >&2; exit 1; }
command -v git >/dev/null || sudo pacman -S --needed --noconfirm git

if [[ -d "$DEST" ]]; then
    [[ -d "$DEST/.git" ]] || { echo "./$DEST already exists and isn't a git checkout - move it aside first." >&2; exit 1; }
    echo "Found an existing checkout at ./$DEST, using it as-is."
else
    git clone "$REPO_URL" "$DEST"
fi

cd "$DEST"

# Piped into bash, this script's own text is this process's stdin, so by the time it gets
# here stdin is at EOF rather than connected to the terminal - install.sh's confirmation
# prompts need the real thing. Reattach it when one is actually available (it won't be
# under CI or another non-interactive caller, which is what --yes is for).
if ( : < /dev/tty ) 2>/dev/null; then
    exec ./install.sh "$@" < /dev/tty
else
    exec ./install.sh "$@"
fi
