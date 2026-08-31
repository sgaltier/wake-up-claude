FROM node:22-alpine

# Outils nécessaires : bash pour les scripts, tzdata pour le fuseau horaire,
# dcron pour le planificateur (busybox crond est aussi présent mais dcron
# gère mieux les logs et le fuseau horaire local dans Alpine)
RUN apk add --no-cache bash tzdata dcron nano

# Fuseau horaire — à adapter si besoin (important : cron lit l'heure système)
ENV TZ=Europe/Paris

# Installation de Claude Code (CLI officiel)
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

# Fichiers de configuration du cron et le script déclencheur
COPY crontab /etc/crontabs/root
COPY trigger.sh /app/trigger.sh
RUN chmod +x /app/trigger.sh

# Le token d'authentification est injecté au runtime via une variable
# d'environnement (voir docker-compose.yml) — jamais copié dans l'image.

# Lance crond au premier plan (PID 1) pour que le container reste actif
CMD ["crond", "-f", "-l", "2"]
