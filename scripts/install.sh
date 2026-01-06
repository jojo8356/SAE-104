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

# Variable pour tracker si apt-get update a été fait
APT_UPDATED=false

# Fonction pour faire apt-get update une seule fois si nécessaire
apt_update_once() {
    if [ "$APT_UPDATED" = false ]; then
        echo -e "${YELLOW}Mise à jour des dépôts apt...${NC}"
        sudo apt-get update
        APT_UPDATED=true
    fi
}

# ============================================
# 0. Vérifier et installer curl si nécessaire
# ============================================
echo -e "${YELLOW}[0/9]${NC} Vérification de curl..."
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}curl n'est pas installé. Installation en cours...${NC}"
    apt_update_once
    sudo apt-get install -y curl
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
echo -e "${YELLOW}[1/9]${NC} Vérification de pip..."
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo -e "${YELLOW}pip n'est pas installé. Installation en cours...${NC}"
    apt_update_once
    sudo apt-get install -y python3-pip
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
echo -e "${YELLOW}[2/9]${NC} Vérification de uv..."
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
# 3. Vérifier et installer/démarrer MariaDB 10.5+
# ============================================
echo -e "${YELLOW}[3/9]${NC} Vérification de MariaDB..."

# Fonction pour obtenir la version majeure de MariaDB
get_mariadb_version() {
    mysql --version 2>/dev/null | grep -oP 'MariaDB.*?(\d+\.\d+)' | grep -oP '\d+\.\d+' | head -1
}

# Vérifier si MariaDB est installé et si la version est >= 10.5
install_mariadb=false
if ! command -v mysql &> /dev/null; then
    install_mariadb=true
    echo -e "${YELLOW}MariaDB n'est pas installé.${NC}"
else
    mariadb_version=$(get_mariadb_version)
    mariadb_major=$(echo "$mariadb_version" | cut -d. -f1)
    mariadb_minor=$(echo "$mariadb_version" | cut -d. -f2)
    if [ "$mariadb_major" -lt 10 ] || ([ "$mariadb_major" -eq 10 ] && [ "$mariadb_minor" -lt 5 ]); then
        echo -e "${YELLOW}MariaDB $mariadb_version détecté, version 10.5+ requise. Mise à jour...${NC}"
        # Arrêter MariaDB avant la mise à jour
        sudo systemctl stop mariadb 2>/dev/null || sudo service mariadb stop 2>/dev/null
        install_mariadb=true
    else
        echo -e "${GREEN}✓${NC} MariaDB $mariadb_version est déjà installé"
    fi
fi

if [ "$install_mariadb" = true ]; then
    echo -e "${YELLOW}Installation de MariaDB 10.11 (LTS) depuis le dépôt officiel...${NC}"

    # Vérifier si les dépendances sont déjà installées
    if ! dpkg -l | grep -q "apt-transport-https" || ! command -v gpg &> /dev/null; then
        apt_update_once
        sudo apt-get install -y apt-transport-https gnupg
    fi

    # Ajouter la clé GPG de MariaDB seulement si elle n'existe pas
    if [ ! -f /usr/share/keyrings/mariadb-keyring.gpg ]; then
        curl -fsSL https://mariadb.org/mariadb_release_signing_key.pgp | sudo gpg --dearmor -o /usr/share/keyrings/mariadb-keyring.gpg 2>/dev/null || true
    fi

    # Détecter la distribution Debian/Ubuntu
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        CODENAME=$VERSION_CODENAME
    else
        DISTRO="debian"
        CODENAME="bookworm"
    fi

    # Ajouter le dépôt MariaDB 10.11 LTS seulement s'il n'existe pas
    if [ ! -f /etc/apt/sources.list.d/mariadb.list ]; then
        echo "deb [signed-by=/usr/share/keyrings/mariadb-keyring.gpg] https://mirrors.ircam.fr/pub/mariadb/repo/10.11/$DISTRO $CODENAME main" | sudo tee /etc/apt/sources.list.d/mariadb.list > /dev/null
        # Forcer la mise à jour car nouveau dépôt ajouté
        APT_UPDATED=false
    fi

    apt_update_once
    sudo apt-get install -y mariadb-server mariadb-client

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} MariaDB 10.11 installé avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de l'installation de MariaDB"
        exit 1
    fi
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
# Vérifier si la base existe déjà
if sudo mysql -u root -e "USE carte_grise_db" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Base de données carte_grise_db existe déjà"
else
    sudo mysql -u root -e "CREATE DATABASE carte_grise_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Base de données créée avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de la création de la base de données"
        exit 1
    fi
fi

# ============================================
# 5. Créer les tables
# ============================================
echo -e "\n${YELLOW}[5/9]${NC} Création des tables..."
# Vérifier si les tables existent déjà
if sudo mysql -u root carte_grise_db -e "SELECT 1 FROM Fabricant LIMIT 1" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Tables déjà créées"
else
    sudo mysql -u root carte_grise_db < "$(dirname "$0")/../sql/create_tables.sql"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Tables créées avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de la création des tables"
        exit 1
    fi
fi

# ============================================
# 6. Insérer les données de test
# ============================================
echo -e "\n${YELLOW}[6/9]${NC} Insertion des données de test..."
# Vérifier si les données existent déjà
nb_fabricants=$(sudo mysql -u root carte_grise_db -N -e "SELECT COUNT(*) FROM Fabricant" 2>/dev/null || echo "0")
if [ "$nb_fabricants" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Données déjà insérées ($nb_fabricants fabricants)"
else
    sudo mysql -u root carte_grise_db < "$(dirname "$0")/../sql/insert_data.sql"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Données insérées avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de l'insertion des données"
        exit 1
    fi
fi

# ============================================
# 7. Créer l'utilisateur Django
# ============================================
echo -e "\n${YELLOW}[7/9]${NC} Création de l'utilisateur Django..."
# Vérifier si l'utilisateur existe déjà
if sudo mysql -u root -e "SELECT User FROM mysql.user WHERE User='django_user'" 2>/dev/null | grep -q django_user; then
    echo -e "${GREEN}✓${NC} Utilisateur django_user existe déjà"
else
    sudo mysql -u root -e "CREATE USER 'django_user'@'localhost' IDENTIFIED BY 'django_password';"
    sudo mysql -u root -e "GRANT ALL PRIVILEGES ON carte_grise_db.* TO 'django_user'@'localhost';"
    sudo mysql -u root -e "GRANT ALL PRIVILEGES ON \`test_carte_grise_db\`.* TO 'django_user'@'localhost';"
    sudo mysql -u root -e "GRANT CREATE, DROP ON *.* TO 'django_user'@'localhost';"
    sudo mysql -u root -e "FLUSH PRIVILEGES;"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Utilisateur Django créé avec succès (avec permissions de test)"
    else
        echo -e "${RED}✗${NC} Erreur lors de la création de l'utilisateur"
        exit 1
    fi
fi

# ============================================
# 8. Installer les dépendances Python
# ============================================
echo -e "\n${YELLOW}[8/9]${NC} Installation des dépendances Python avec uv..."
cd "$(dirname "$0")/../carte_grise_app"
# Vérifier si le venv existe déjà et si les dépendances sont installées
if [ -d ".venv" ] && [ -f ".venv/pyvenv.cfg" ]; then
    echo -e "${GREEN}✓${NC} Environnement virtuel déjà configuré"
else
    uv sync
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Dépendances installées avec succès"
    else
        echo -e "${RED}✗${NC} Erreur lors de l'installation des dépendances"
        exit 1
    fi
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
