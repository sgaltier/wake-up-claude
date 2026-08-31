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
n'est nécessaire.

## Étape 3 — Déployer sur le Synology

1. Copie tout le dossier (`Dockerfile`, `crontab`, `trigger.sh`,
   `docker-compose.yml`, `.env`) dans un dossier partagé, par exemple via
   File Station : `/docker/claude-cron/`.
2. Dans **Container Manager** → **Projet** → **Créer**, pointe vers ce
   dossier (il détecte automatiquement le `docker-compose.yml`).
3. Lance le build puis démarre le container.

## Étape 4 — Vérifier

```bash
# Se connecter au container pour vérifier les logs
docker exec -it claude-cron cat /var/log/claude-cron.log

# Vérifier que le cron est bien enregistré
docker exec -it claude-cron crontab -l
```

Le premier vrai test aura lieu au prochain créneau (7h, 12h ou 17h).
Pour tester tout de suite sans attendre, lance manuellement :

```bash
docker exec -it claude-cron /app/trigger.sh
```

## Notes importantes

- **Le token n'expire pas comme un mot de passe classique**, mais s'il est
  révoqué (déconnexion sur claude.ai, changement de mot de passe...), le
  cron échouera silencieusement — pense à consulter `claude-cron.log` de
  temps en temps.
- **Chaque appel consomme un peu de quota**, y compris ton plafond
  hebdomadaire glissant (indépendant des 5h). Si tu pars en vacances,
  pense à arrêter le container (`docker stop claude-cron`) pour ne pas
  gaspiller de quota pour rien.
- Le fuseau horaire est fixé dans le `Dockerfile` (`TZ=Europe/Paris`) et
  repris par le `docker-compose.yml` — les deux doivent rester cohérents.
