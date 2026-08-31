#!/bin/bash
set -euo pipefail

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] Déclenchement de la fenêtre de 5h..."

if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "ERREUR : CLAUDE_CODE_OAUTH_TOKEN n'est pas défini. Le message ne sera pas envoyé."
  exit 1
fi

# --print (-p) : mode non interactif, une seule réponse puis sortie
# --output-format text : évite le JSON verbeux dans les logs
# On utilise /tmp comme workdir : ce message n'a rien à faire avec des fichiers
cd /tmp
claude -p "ok" --output-format text --dangerously-skip-permissions

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] Terminé."
