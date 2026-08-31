#!/bin/bash
set -euo pipefail

# Le container est sain si un déclenchement a réussi dans les 18 dernières
# heures ; l'écart maximal entre deux créneaux est de 13h (17h30 -> 6h30).
SUCCESS_FILE=/app/logs/last-success
MAX_AGE=64800

[ -f "$SUCCESS_FILE" ] || exit 1
[ $(( $(date +%s) - $(stat -c %Y "$SUCCESS_FILE") )) -lt "$MAX_AGE" ]
