#!/bin/bash

# ============================================
# SAE 1.04 : Script de test de conformité
# Exécute les tests de conformité et d'incrémentation
# ============================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Test de Conformité SAE 1.04${NC}"
echo -e "${BLUE}   Base de données Carte Grise${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Menu de sélection
echo -e "${CYAN}Choisissez le type de test à exécuter :${NC}"
echo -e "  ${YELLOW}1${NC} - Test de conformité complet (toutes les colonnes)"
echo -e "  ${YELLOW}2${NC} - Test d'incrémentation (numéros CG, immat, série)"
echo -e "  ${YELLOW}3${NC} - Test des fonctions Python (génération numéros)"
echo -e "  ${YELLOW}4${NC} - Tests Backend (consultation & statistiques Django)"
echo -e "  ${YELLOW}5${NC} - Tous les tests"
echo ""
read -p "Votre choix [1-5] (défaut: 5): " CHOICE
CHOICE=${CHOICE:-5}
echo ""

# Vérifier si MySQL est accessible (sauf pour tests Python/Selenium uniquement)
if [[ "$CHOICE" != "3" ]] && [[ "$CHOICE" != "4" ]]; then
    if ! command -v mysql &> /dev/null; then
        echo -e "${RED}✗${NC} MySQL n'est pas installé ou n'est pas dans le PATH"
        exit 1
    fi

    # Vérifier si la base de données existe
    if ! sudo mysql -e "USE carte_grise_db;" 2>/dev/null; then
        echo -e "${RED}✗${NC} La base de données carte_grise_db n'existe pas"
        echo -e "${YELLOW}[INFO]${NC} Veuillez d'abord exécuter ./install.sh pour créer la base de données"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} Base de données carte_grise_db détectée"
    echo ""
fi

# Fonction pour exécuter le test de conformité
run_conformite_test() {
    echo -e "${CYAN}=== Test de conformité complet ===${NC}"
    echo ""

    # Demander le numéro de carte grise à tester
    read -p "Numéro de carte grise à tester (défaut: 2020AA00001): " NUM_CARTE
    NUM_CARTE=${NUM_CARTE:-2020AA00001}

    echo -e "${YELLOW}[INFO]${NC} Test de la carte grise: ${NUM_CARTE}"
    echo ""

    # Créer un fichier temporaire avec la variable
    TEMP_SQL=$(mktemp)
    echo "SET @num_carte = '${NUM_CARTE}';" > "$TEMP_SQL"
    cat "$(dirname "$0")/../sql/test_conformite.sql" >> "$TEMP_SQL"

    # Exécuter le test
    echo -e "${YELLOW}[1/1]${NC} Exécution du test de conformité..."
    echo ""

    if sudo mysql < "$TEMP_SQL"; then
        echo ""
        echo -e "${GREEN}✓${NC} Test de conformité terminé avec succès"
        rm -f "$TEMP_SQL"
        return 0
    else
        echo ""
        echo -e "${RED}✗${NC} Erreur lors de l'exécution du test de conformité"
        rm -f "$TEMP_SQL"
        return 1
    fi
}

# Fonction pour exécuter le test d'incrémentation
run_incrementation_test() {
    echo -e "${CYAN}=== Test de logique d'incrémentation ===${NC}"
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Vérification des règles d'incrémentation..."
    echo -e "  - Numéros de carte grise (AAAALLNNNNN)"
    echo -e "  - Numéros d'immatriculation (LLNNNLL)"
    echo -e "  - Numéros de série (NumFab+YYYYMM+6chiffres)"
    echo ""

    # Exécuter le test
    echo -e "${YELLOW}[1/1]${NC} Exécution du test d'incrémentation..."
    echo ""

    if sudo mysql < "$(dirname "$0")/../sql/test_incrementation.sql"; then
        echo ""
        echo -e "${GREEN}✓${NC} Test d'incrémentation terminé avec succès"
        return 0
    else
        echo ""
        echo -e "${RED}✗${NC} Erreur lors de l'exécution du test d'incrémentation"
        return 1
    fi
}

# Fonction pour exécuter les tests unitaires Python
run_python_tests() {
    echo -e "${CYAN}=== Test des fonctions Python (utils.py) ===${NC}"
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Tests des fonctions de génération automatique..."
    echo -e "  - generer_prochain_numero_carte_grise()"
    echo -e "  - generer_prochain_numero_immatriculation()"
    echo -e "  - recuperer_dernier_numero_carte_grise()"
    echo -e "  - recuperer_dernier_numero_immatriculation()"
    echo ""

    # Exécuter les tests Django
    echo -e "${YELLOW}[1/1]${NC} Exécution des tests unitaires Django..."
    echo ""

    cd carte_grise_app

    # Vérifier si uv est disponible (préféré), sinon utiliser python3
    if command -v uv &> /dev/null; then
        if uv run python manage.py test cartes_grises --verbosity=2; then
            cd ..
            echo ""
            echo -e "${GREEN}✓${NC} Tests Python terminés avec succès"
            return 0
        else
            cd ..
            echo ""
            echo -e "${RED}✗${NC} Erreur lors de l'exécution des tests Python"
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if python3 manage.py test cartes_grises --verbosity=2; then
            cd ..
            echo ""
            echo -e "${GREEN}✓${NC} Tests Python terminés avec succès"
            return 0
        else
            cd ..
            echo ""
            echo -e "${RED}✗${NC} Erreur lors de l'exécution des tests Python"
            return 1
        fi
    else
        cd ..
        echo ""
        echo -e "${RED}✗${NC} Ni uv ni python3 n'est disponible"
        return 1
    fi
}

# Fonction pour exécuter les tests backend (vues Django)
run_backend_tests() {
    echo -e "${CYAN}=== Tests Backend (vues Django) ===${NC}"
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Tests des fonctionnalités de consultation & statistiques:"
    echo -e "  - a. Lister cartes grises par laps de temps"
    echo -e "  - b. Lister par nom/prénom (ordre alphabétique)"
    echo -e "  - c. Lister par numéro de plaque (filtres avancés)"
    echo -e "  - d. Marques par ordre décroissant"
    echo -e "  - e. Véhicules > X années + émission CO2 > Y"
    echo ""

    # Vérifier les dépendances
    if ! command -v python3 &> /dev/null && ! command -v uv &> /dev/null; then
        echo -e "${RED}✗${NC} Python n'est pas installé"
        return 1
    fi

    cd carte_grise_app

    echo -e "${YELLOW}[1/1]${NC} Exécution des tests backend..."
    echo ""

    # Exécuter les tests
    if command -v uv &> /dev/null; then
        if uv run python manage.py test cartes_grises.test_views --verbosity=2 --keepdb; then
            cd ..
            echo ""
            echo -e "${GREEN}✓${NC} Tests backend terminés avec succès (16/16 tests passent)"
            return 0
        else
            cd ..
            echo ""
            echo -e "${RED}✗${NC} Erreur lors de l'exécution des tests backend"
            return 1
        fi
    else
        if python3 manage.py test cartes_grises.test_views --verbosity=2 --keepdb; then
            cd ..
            echo ""
            echo -e "${GREEN}✓${NC} Tests backend terminés avec succès (16/16 tests passent)"
            return 0
        else
            cd ..
            echo ""
            echo -e "${RED}✗${NC} Erreur lors de l'exécution des tests backend"
            return 1
        fi
    fi
}

# Exécuter les tests selon le choix
case $CHOICE in
    1)
        run_conformite_test
        STATUS=$?
        ;;
    2)
        run_incrementation_test
        STATUS=$?
        ;;
    3)
        run_python_tests
        STATUS=$?
        ;;
    4)
        run_backend_tests
        STATUS=$?
        ;;
    5)
        echo -e "${CYAN}=== Exécution de tous les tests ===${NC}"
        echo ""

        # Test 1: Conformité
        run_conformite_test
        STATUS1=$?

        echo ""
        echo -e "${BLUE}----------------------------------------${NC}"
        echo ""

        # Test 2: Incrémentation
        run_incrementation_test
        STATUS2=$?

        echo ""
        echo -e "${BLUE}----------------------------------------${NC}"
        echo ""

        # Test 3: Tests Python
        run_python_tests
        STATUS3=$?

        echo ""
        echo -e "${BLUE}----------------------------------------${NC}"
        echo ""

        # Test 4: Tests Backend
        run_backend_tests
        STATUS4=$?

        # Status global
        if [ $STATUS1 -eq 0 ] && [ $STATUS2 -eq 0 ] && [ $STATUS3 -eq 0 ] && [ $STATUS4 -eq 0 ]; then
            STATUS=0
        else
            STATUS=1
        fi
        ;;
    *)
        echo -e "${RED}✗${NC} Choix invalide"
        exit 1
        ;;
esac

# Résumé final
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Résumé${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Base de données : carte_grise_db"
echo -e "Tests exécutés  : "
case $CHOICE in
    1) echo -e "  - Test de conformité" ;;
    2) echo -e "  - Test d'incrémentation" ;;
    3) echo -e "  - Test des fonctions Python" ;;
    4) echo -e "  - Tests Backend (Django)" ;;
    5) echo -e "  - Test de conformité"
       echo -e "  - Test d'incrémentation"
       echo -e "  - Test des fonctions Python"
       echo -e "  - Tests Backend (Django)" ;;
esac
echo ""

if [ $STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les tests ont réussi !${NC}"
else
    echo -e "${RED}✗ Certains tests ont échoué${NC}"
fi
echo ""

exit $STATUS
