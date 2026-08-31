FROM node:22-alpine

# Outils nécessaires : bash pour les scripts, tzdata pour le fuseau horaire,
# dcron pour le planificateur (busybox crond est aussi présent mais dcron
# gère mieux les logs et le fuseau horaire local dans Alpine), tini comme
# init PID 1 (dcron appelle setpgid() en interne, ce qui échoue avec EPERM
# s'il tourne lui-même en PID 1 / session leader)
RUN apk add --no-cache bash tzdata dcron nano tini

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

# tini en PID 1 fait office d'init (reap des zombies) et lance crond en
# enfant, au premier plan, pour que le container reste actif
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["crond", "-f", "-l", "2"]
