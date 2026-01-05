# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

cd carte_grise_app

printf "\n${BLUE}========================================${NC}"
printf "${BLUE}   Serveur Django démarré !${NC}"
printf  "${BLUE}   URL: http://127.0.0.1:8000${NC}"
printf  "${BLUE}========================================${NC}\n"

uv run python manage.py runserver