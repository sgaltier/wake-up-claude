FROM node:22-alpine

# Outils nécessaires : bash pour les scripts, tzdata pour le fuseau horaire,
# dcron pour le planificateur (busybox crond est aussi présent mais dcron
# gère mieux les logs et le fuseau horaire local dans Alpine)
RUN apk add --no-cache bash tzdata dcron nano tini

# Fuseau horaire — à adapter si besoin (important : cron lit l'heure système)
ENV TZ=Europe/Paris

# Installation de Claude Code (CLI officiel)
RUN npm install -g @anthropic-ai/claude-code

# Claude Code refuse --dangerously-skip-permissions sous root/sudo.
# On crée donc un utilisateur dédié non-root pour tout faire tourner.
RUN addgroup -S claude && adduser -S -G claude -h /home/claude claude

WORKDIR /app

# Fichiers de configuration du cron et le script déclencheur
# dcron lit le crontab d'un utilisateur donné dans /etc/crontabs/<nom>
COPY crontab /etc/crontabs/claude
COPY trigger.sh /app/trigger.sh
RUN chmod +x /app/trigger.sh

# Prépare les répertoires nécessaires avec les bons droits pour l'utilisateur claude
RUN mkdir -p /var/log /home/claude/.claude \
    && touch /var/log/claude-cron.log \
    && chown -R claude:claude /app /var/log/claude-cron.log /home/claude

# Le token d'authentification est injecté au runtime via une variable
# d'environnement (voir docker-compose.yml) — jamais copié dans l'image.

# Lance crond au premier plan (PID 1). crond lui-même doit démarrer en root
# (c'est le comportement standard : le démon tourne en root mais exécute
# chaque job avec l'utilisateur propriétaire du fichier crontab, ici "claude").
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["crond", "-f", "-l", "2"]
