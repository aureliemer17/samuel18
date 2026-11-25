#!/bin/zsh

# Point d'entree unique pour la maintenance des archives.
set -e
SCRIPT_DIR="${0:A:h}"
exec "$SCRIPT_DIR/archives.command" "$@"
