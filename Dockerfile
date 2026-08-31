FROM node:22-alpine

# Outils nécessaires : bash pour les scripts, tzdata pour le fuseau horaire,
# dcron pour le planificateur (busybox crond est aussi présent mais dcron
# gère mieux les logs et le fuseau horaire local dans Alpine)
RUN apk add --no-cache bash tzdata dcron tini

# Fuseau horaire — source unique de vérité pour tout le projet (le
# docker-compose.yml ne le redéfinit pas). Le changer impose un rebuild.
ENV TZ=Europe/Paris
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Installation de Claude Code (CLI officiel). Version épinglée : une mise à
# jour non maîtrisée peut changer les options du CLI et casser le cron.
ARG CLAUDE_CODE_VERSION=2.1.251
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Claude Code refuse --dangerously-skip-permissions sous root/sudo.
# On crée donc un utilisateur dédié non-root pour tout faire tourner.
# -s /bin/sh : un shell valide, pour ne pas dépendre du shell choisi par cron.
RUN addgroup -S claude && adduser -S -G claude -h /home/claude -s /bin/sh claude

WORKDIR /app

# dcron exécute le crontab /etc/crontabs/<nom> sous l'utilisateur <nom> :
# c'est le NOM DU FICHIER qui détermine l'utilisateur, pas son propriétaire.
COPY crontab /etc/crontabs/claude
COPY trigger.sh entrypoint.sh healthcheck.sh /app/
RUN chmod +x /app/trigger.sh /app/entrypoint.sh /app/healthcheck.sh

# /app/logs est recréé et rechowné au démarrage par l'entrypoint : un montage
# bind masque les droits fixés ici.
RUN mkdir -p /app/logs /home/claude/.claude \
    && chown -R claude:claude /app /home/claude

# Le token d'authentification est injecté au runtime via une variable
# d'environnement (voir docker-compose.yml) — jamais copié dans l'image.

# Marque le container "unhealthy" si aucun déclenchement n'a réussi depuis 18h.
HEALTHCHECK --interval=1h --timeout=10s --start-period=24h --retries=1 \
    CMD ["/app/healthcheck.sh"]

# L'entrypoint valide le token et prépare les droits, puis exec crond (PID 1).
# crond doit démarrer en root : le démon tourne en root mais exécute chaque job
# sous l'utilisateur correspondant au nom du fichier crontab, ici "claude".
ENTRYPOINT ["/sbin/tini", "-g", "--", "/app/entrypoint.sh"]
CMD ["crond", "-f", "-l", "2"]
