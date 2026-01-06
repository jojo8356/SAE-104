#!/bin/bash

# ============================================
# Script d'installation complète
# SAE 1.04 - Base de données Carte Grise
# ============================================

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Installation SAE 1.04${NC}"
echo -e "${BLUE}   Base de données Carte Grise${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ============================================
# 0. Vérifier et installer curl si nécessaire
# ============================================
echo -e "${YELLOW}[0/7]${NC} Vérification de curl..."
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}curl n'est pas installé. Installation en cours...${NC}"
    sudo apt-get update && sudo apt-get install -y curl
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} curl installé avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de l'installation de curl"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} curl est déjà installé"
fi

# ============================================
# 1. Vérifier et installer pip si nécessaire
# ============================================
echo -e "${YELLOW}[1/8]${NC} Vérification de pip..."
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo -e "${YELLOW}pip n'est pas installé. Installation en cours...${NC}"
    sudo apt-get update && sudo apt-get install -y python3-pip
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} pip installé avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de l'installation de pip"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} pip est déjà installé"
fi

# ============================================
# 2. Vérifier et installer uv si nécessaire
# ============================================
echo -e "${YELLOW}[2/8]${NC} Vérification de uv..."
# Ajouter le chemin de uv au PATH pour cette session
export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}uv n'est pas installé. Installation via pip...${NC}"
    pip3 install uv || pip install uv
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} uv installé avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de l'installation de uv"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} uv est déjà installé"
fi

# ============================================
# 3. Vérifier et installer/démarrer MariaDB
# ============================================
echo -e "${YELLOW}[3/9]${NC} Vérification de MariaDB..."
if ! command -v mysql &> /dev/null; then
    echo -e "${YELLOW}MariaDB n'est pas installé. Installation en cours...${NC}"
    sudo apt-get update && sudo apt-get install -y mariadb-server
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} MariaDB installé avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de l'installation de MariaDB"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} MariaDB est déjà installé"
fi

# Démarrer MariaDB s'il n'est pas en cours d'exécution
if ! sudo systemctl is-active --quiet mariadb 2>/dev/null && ! sudo service mariadb status &>/dev/null; then
    echo -e "${YELLOW}Démarrage de MariaDB...${NC}"
    sudo systemctl start mariadb 2>/dev/null || sudo service mariadb start
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} MariaDB démarré avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors du démarrage de MariaDB"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} MariaDB est en cours d'exécution"
fi

# ============================================
# 4. Créer la base de données
# ============================================
echo -e "${YELLOW}[4/9]${NC} Création de la base de données..."
sudo mysql -u root -e "DROP DATABASE IF EXISTS carte_grise_db;" 2>/dev/null
sudo mysql -u root -e "CREATE DATABASE carte_grise_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Base de données créée avec succès"
else
    echo -e "${RED}✗${NC} Erreur lors de la création de la base de données"
    exit 1
fi

# ============================================
# 5. Créer les tables
# ============================================
echo -e "\n${YELLOW}[5/9]${NC} Création des tables..."
sudo mysql -u root carte_grise_db < "$(dirname "$0")/../sql/create_tables.sql"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Tables créées avec succès"
else
    echo -e "${RED}✗${NC} Erreur lors de la création des tables"
    exit 1
fi

# ============================================
# 6. Insérer les données de test
# ============================================
echo -e "\n${YELLOW}[6/9]${NC} Insertion des données de test..."
sudo mysql -u root carte_grise_db < "$(dirname "$0")/../sql/insert_data.sql"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Données insérées avec succès"
else
    echo -e "${RED}✗${NC} Erreur lors de l'insertion des données"
    exit 1
fi

# ============================================
# 7. Créer l'utilisateur Django
# ============================================
echo -e "\n${YELLOW}[7/9]${NC} Création de l'utilisateur Django..."
sudo mysql -u root -e "DROP USER IF EXISTS 'django_user'@'localhost';" 2>/dev/null
sudo mysql -u root -e "CREATE USER 'django_user'@'localhost' IDENTIFIED BY 'django_password';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON carte_grise_db.* TO 'django_user'@'localhost';"
# Donner les permissions pour créer/supprimer des bases de données de test
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON \`test_carte_grise_db\`.* TO 'django_user'@'localhost';"
sudo mysql -u root -e "GRANT CREATE, DROP ON *.* TO 'django_user'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Utilisateur Django créé avec succès (avec permissions de test)"
else
    echo -e "${RED}✗${NC} Erreur lors de la création de l'utilisateur"
    exit 1
fi

# ============================================
# 8. Installer les dépendances Python
# ============================================
echo -e "\n${YELLOW}[8/9]${NC} Installation des dépendances Python avec uv..."
cd "$(dirname "$0")/carte_grise_app"
uv sync
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Dépendances installées avec succès"
else
    echo -e "${RED}✗${NC} Erreur lors de l'installation des dépendances"
    exit 1
fi
cd ..

# ============================================
# 9. Afficher un résumé
# ============================================
echo -e "\n${YELLOW}[9/9]${NC} Vérification de l'installation..."
echo -e "\n${BLUE}Résumé des données insérées :${NC}"
sudo mysql -u root carte_grise_db -e "
SELECT
    'Fabricants' as Table_Name, COUNT(*) as Nombre FROM Fabricant
UNION ALL SELECT 'Marques', COUNT(*) FROM Marque
UNION ALL SELECT 'Modèles', COUNT(*) FROM Modele
UNION ALL SELECT 'Propriétaires', COUNT(*) FROM Proprietaire
UNION ALL SELECT 'Véhicules', COUNT(*) FROM Vehicule
UNION ALL SELECT 'Cartes Grises', COUNT(*) FROM Carte_Grise
UNION ALL SELECT 'Contrôles Techniques', COUNT(*) FROM Controle_Technique;
" | column -t

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   Installation terminée avec succès !${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${BLUE}Base de données :${NC} carte_grise_db"
echo -e "${BLUE}Utilisateur MySQL :${NC} django_user"
echo -e "${BLUE}Mot de passe :${NC} django_password"
echo -e "\n${YELLOW}Pour lancer l'application Django :${NC}"
echo -e "  ./run.sh\n"