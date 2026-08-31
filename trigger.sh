#!/bin/bash
set -euo pipefail

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] Déclenchement de la fenêtre de 5h..."

if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "ERREUR : CLAUDE_CODE_OAUTH_TOKEN n'est pas défini. Le message ne sera pas envoyé."
  exit 1
fi

# --print (-p) : mode non interactif, une seule réponse puis sortie
# --output-format text : évite le JSON verbeux dans les logs
# Le message "ok" n'invoque aucun outil (pas de lecture/écriture de fichier,
# pas de commande shell), donc --dangerously-skip-permissions n'est pas
# nécessaire ici — et de toute façon Claude Code le refuse sous root.
cd /tmp
claude -p "ok" --output-format text

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] Terminé."
