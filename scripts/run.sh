#!/bin/bash

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aller dans le répertoire carte_grise_app
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../carte_grise_app"

# Activer le venv
source .venv/bin/activate

printf "\n${BLUE}========================================${NC}"
printf "\n${BLUE}   Serveur Django démarré !${NC}"
printf "\n${BLUE}   URL: http://127.0.0.1:8000${NC}"
printf "\n${BLUE}========================================${NC}\n\n"

python manage.py runserver