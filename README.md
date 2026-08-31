# Claude Cron — déclencheur de fenêtre 5h (Synology Container Manager)

## Étape 1 — Générer le token OAuth (une seule fois, sur ta machine perso)

Il faut Claude Code installé sur un poste avec navigateur (pas sur le Synology) :

```bash
npm install -g @anthropic-ai/claude-code
claude setup-token
```

Une page de connexion s'ouvre : connecte-toi avec ton compte Claude.ai (celui
qui a l'abonnement Pro/Max). Un token est affiché dans le terminal
(commence par un identifiant long). Copie-le précieusement — il ne sera
plus jamais réaffiché.

⚠️ Ce token donne accès à ton compte. Traite-le comme un mot de passe.

## Étape 2 — Configurer le token dans le projet

Copie `.env.example` vers `.env` (ce fichier est ignoré par git, voir
`.gitignore`) et colle ton token :

```
CLAUDE_CODE_OAUTH_TOKEN=le_token_ici
```

`docker-compose.yml` lit automatiquement ce fichier `.env` et injecte la
variable dans le container — aucune modification du `docker-compose.yml`
n'est nécessaire. Si la variable est absente, `docker compose up` échoue
immédiatement avec un message explicite plutôt que de démarrer un container
qui planterait trois fois par jour sans rien dire.

## Étape 3 — Déployer sur le Synology

1. Copie tout le dossier (`Dockerfile`, `crontab`, `trigger.sh`,
   `entrypoint.sh`, `healthcheck.sh`, `docker-compose.yml`, `.env`) dans un
   dossier partagé, par exemple via File Station : `/docker/claude-cron/`.
2. Dans **Container Manager** → **Projet** → **Créer**, pointe vers ce
   dossier (il détecte automatiquement le `docker-compose.yml`).
3. Lance le build puis démarre le container.

## Étape 4 — Vérifier

```bash
# Journal des déclenchements (également visible dans l'onglet "Journal" de
# Container Manager, l'entrypoint le recopie sur la sortie standard)
docker exec -it claude-cron cat /app/logs/claude-cron.log

# Vérifier que le cron est bien enregistré.
# Attention : `crontab -l` listerait le crontab de root, qui est vide —
# le crontab utilisé est celui de l'utilisateur claude.
docker exec -it claude-cron cat /etc/crontabs/claude

# État de santé (unhealthy si aucun déclenchement réussi depuis 18h)
docker inspect --format '{{.State.Health.Status}}' claude-cron
```

Le premier vrai test aura lieu au prochain créneau (6h30, 12h ou 17h30).
Pour tester tout de suite sans attendre :

```bash
docker exec -u claude -it claude-cron /app/trigger.sh
```

⚠️ Le `-u claude` est indispensable : sans lui la commande tourne en root,
dans un environnement différent de celui du cron, et peut réussir alors que
le job planifié échoue.

## Notes importantes

- **Le container tourne sous un utilisateur non-root (`claude`)**, pas
  sous `root`. C'est nécessaire : Claude Code refuse de fonctionner en
  mode automatisé (`--dangerously-skip-permissions`) sous root, par
  sécurité. Le démon `crond` démarre bien en root (comportement standard
  d'Alpine), mais exécute les tâches planifiées sous l'utilisateur
  correspondant au **nom du fichier** crontab — ici `/etc/crontabs/claude`.
- **cron ne transmet pas l'environnement du container à ses jobs.** Le
  token est donc écrit au démarrage par `entrypoint.sh` dans
  `/run/claude-cron/token` (lisible par le seul utilisateur `claude`), et
  `trigger.sh` le relit de là. Pour la même raison, `trigger.sh` fixe
  lui-même son `PATH` : sans ça `claude`, installé dans `/usr/local/bin`,
  serait introuvable.
- **Le token a une durée de vie limitée** et devra être régénéré
  (étape 1) ; il peut aussi être révoqué avant terme (déconnexion sur
  claude.ai, changement de mot de passe...). Dans les deux cas les
  déclenchements échouent : le HEALTHCHECK passe le container en
  `unhealthy` au bout de 18h sans succès, et chaque échec écrit une ligne
  `ÉCHEC du déclenchement` dans le journal.
- **Chaque appel consomme un peu de quota**, y compris ton plafond
  hebdomadaire glissant (indépendant des 5h). Si tu pars en vacances,
  pense à arrêter le container (`docker stop claude-cron`) pour ne pas
  gaspiller de quota pour rien.
- **Le fuseau horaire est défini à un seul endroit**, `ENV TZ` dans le
  `Dockerfile`. Le modifier impose un rebuild de l'image.
- **La version de Claude Code est épinglée** dans le `Dockerfile`
  (`ARG CLAUDE_CODE_VERSION`). Pour la mettre à jour, change cette valeur
  et rebuild — de cette façon une nouvelle version ne casse jamais le cron
  à ton insu.
