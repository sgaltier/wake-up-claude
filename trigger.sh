#!/bin/bash
set -euo pipefail

# cron fournit un PATH minimal qui n'inclut pas /usr/local/bin, où npm installe
# la commande claude. dcron ne garantit pas la prise en charge des affectations
# de variables dans le crontab : on fixe donc le PATH ici.
export PATH=/usr/local/bin:/usr/bin:/bin

TOKEN_FILE=/run/claude-cron/token
SUCCESS_FILE=/app/logs/last-success

timestamp() { date '+%Y-%m-%d %H:%M:%S %Z'; }

trap 'echo "[$(timestamp)] ÉCHEC du déclenchement (code $?)."' ERR

echo "[$(timestamp)] Déclenchement de la fenêtre de 5h..."

# Token déposé par l'entrypoint au démarrage du container.
if [ ! -r "$TOKEN_FILE" ]; then
  echo "ERREUR : $TOKEN_FILE illisible. Le message ne sera pas envoyé."
  exit 1
fi
export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$TOKEN_FILE")"

# --print (-p) : mode non interactif, une seule réponse puis sortie
# --output-format text : évite le JSON verbeux dans les logs
# Le message "ok" n'invoque aucun outil (pas de lecture/écriture de fichier,
# pas de commande shell), donc --dangerously-skip-permissions n'est pas
# nécessaire ici — et de toute façon Claude Code le refuse sous root.
cd /tmp
claude -p "ok" --output-format text

# Horodatage de la dernière réussite, lu par healthcheck.sh.
touch "$SUCCESS_FILE"

echo "[$(timestamp)] Terminé."
