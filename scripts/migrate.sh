#!/bin/bash

# ============================================
# Script de migration Django
# SAE 1.04 - Base de données Carte Grise
# ============================================

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Migration Django${NC}"
echo -e "${BLUE}========================================${NC}\n"

cd "$(dirname "$0")/../carte_grise_app"

echo -e "${YELLOW}Exécution des migrations Django...${NC}\n"

uv run python manage.py migrate

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ Migrations appliquées avec succès${NC}\n"
else
    echo -e "\n${RED}✗ Erreur lors des migrations${NC}\n"
    exit 1
fi
