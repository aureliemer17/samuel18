#!/bin/zsh

set -e
cd "$(dirname "$0")"
node "generer-config-archives.mjs"

echo ""
echo "Configuration des archives mise a jour."
read "?Appuyez sur Entree pour fermer cette fenetre..."
