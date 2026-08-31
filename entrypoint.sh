#!/bin/bash
set -euo pipefail

LOG_DIR=/app/logs
LOG_FILE="$LOG_DIR/claude-cron.log"
TOKEN_DIR=/run/claude-cron
TOKEN_FILE="$TOKEN_DIR/token"

# Échec immédiat si le token manque : sans lui les jobs échoueraient trois fois
# par jour sans que rien ne le signale.
if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "ERREUR : CLAUDE_CODE_OAUTH_TOKEN n'est pas défini (fichier .env manquant ?)." >&2
  exit 1
fi

# cron ne transmet pas de façon fiable l'environnement du container à ses jobs.
# Le token est donc déposé dans un fichier lisible par le seul utilisateur claude.
mkdir -p "$TOKEN_DIR"
chown root:claude "$TOKEN_DIR"
chmod 750 "$TOKEN_DIR"
printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN" > "$TOKEN_FILE"
chown claude:claude "$TOKEN_FILE"
chmod 400 "$TOKEN_FILE"

# /app/logs est un montage bind : les droits fixés dans le Dockerfile sont
# masqués par le montage, il faut donc les réappliquer au démarrage.
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chown -R claude:claude "$LOG_DIR"

# Recopie le log sur la sortie standard du container — c'est ce flux que
# Container Manager affiche dans son onglet "Journal".
tail -F "$LOG_FILE" &

echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] crond démarre — créneaux : 6h30, 12h00, 17h30."

exec "$@"
