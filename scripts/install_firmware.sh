#!/usr/bin/env bash
# Install ChromeDriver compatible with Brave Browser

set -e  # Arrêter en cas d'erreur

echo "=== Installation ChromeDriver pour Brave Browser ==="

# Vérifier si Brave est installé
if command -v brave-browser &> /dev/null; then
    brave_version=$(brave-browser --version | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "unknown")
    chrome_major=$(echo "$brave_version" | cut -d. -f1)
    echo "✓ Brave Browser détecté (version: $brave_version)"
elif command -v brave &> /dev/null; then
    brave_version=$(brave --version | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "unknown")
    chrome_major=$(echo "$brave_version" | cut -d. -f1)
    echo "✓ Brave Browser détecté (version: $brave_version)"
else
    echo "⚠ Brave Browser non trouvé"
    echo "  Brave utilise le même moteur que Chrome, le ChromeDriver fonctionnera."
    # Utiliser Chrome comme fallback si installé
    if command -v google-chrome &> /dev/null; then
        brave_version=$(google-chrome --version | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "unknown")
        chrome_major=$(echo "$brave_version" | cut -d. -f1)
        echo "✓ Google Chrome détecté (version: $brave_version)"
    else
        echo "⚠ Ni Brave ni Chrome détectés, installation de la dernière version de ChromeDriver"
        brave_version="unknown"
        chrome_major="unknown"
        echo "Installation de brave"
        curl -fsS https://dl.brave.com/install.sh | sh
    fi
fi

# Vérifier si ChromeDriver est déjà installé
if command -v chromedriver &> /dev/null; then
    installed_driver_version=$(chromedriver --version | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    driver_major=$(echo "$installed_driver_version" | cut -d. -f1)
    echo "✓ ChromeDriver déjà installé (version: $installed_driver_version)"

    # Vérifier la compatibilité avec Brave/Chrome
    if [ "$chrome_major" != "unknown" ] && [ "$chrome_major" != "$driver_major" ]; then
        echo "⚠ INCOMPATIBILITÉ DÉTECTÉE:"
        echo "  Brave/Chrome version : $brave_version (majeure: $chrome_major)"
        echo "  ChromeDriver         : $installed_driver_version (majeure: $driver_major)"
        echo "  → ChromeDriver $chrome_major.* est recommandé pour version $chrome_major.*"
        echo ""
        echo "→ Suppression de l'ancien ChromeDriver incompatible..."
        sudo rm -f /usr/local/bin/chromedriver
        skip_chromedriver=false
    else
        # Vérifier la dernière version disponible pour la version majeure de Chrome
        if [ "$chrome_major" != "unknown" ]; then
            # Essayer de trouver la version compatible
            latest_version=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${chrome_major}" 2>/dev/null || echo "")

            if [ -z "$latest_version" ]; then
                # Fallback: essayer l'ancienne API
                latest_version=$(curl -s http://chromedriver.storage.googleapis.com/LATEST_RELEASE_${chrome_major} 2>/dev/null || echo "$installed_driver_version")
            fi

            if [ "$installed_driver_version" == "$latest_version" ]; then
                echo "✓ ChromeDriver est compatible et à jour"
                skip_chromedriver=true
            else
                echo "⚠ Version plus récente disponible: $latest_version"
                read -p "Mettre à jour ChromeDriver? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sudo rm -f /usr/local/bin/chromedriver
                    skip_chromedriver=false
                else
                    skip_chromedriver=true
                fi
            fi
        else
            skip_chromedriver=true
        fi
    fi
else
    echo "⚠ ChromeDriver non installé"
    skip_chromedriver=false
fi

# Installer les dépendances si nécessaire
if ! dpkg -l | grep -q libnss3-dev; then
    echo "→ Installation des dépendances..."
    apt-get update && apt-get install -y libnss3-dev
else
    echo "✓ Dépendances déjà installées"
fi

# Installer ChromeDriver si nécessaire
if [ "$skip_chromedriver" != true ]; then
    echo "→ Installation de ChromeDriver..."
    version=$(curl -s http://chromedriver.storage.googleapis.com/LATEST_RELEASE)

    # Télécharger seulement si le fichier n'existe pas
    if [ ! -f "chromedriver_linux64.zip" ]; then
        wget -N http://chromedriver.storage.googleapis.com/${version}/chromedriver_linux64.zip
    fi

    unzip -o chromedriver_linux64.zip -d /usr/local/bin
    chmod +x /usr/local/bin/chromedriver

    # Nettoyer le zip
    rm -f chromedriver_linux64.zip

    echo "✓ ChromeDriver installé (version: $version)"
fi

echo ""
echo "=== Installation terminée ==="
echo ""
echo "Versions installées:"
chromedriver --version

if command -v brave-browser &> /dev/null; then
    brave-browser --version
elif command -v brave &> /dev/null; then
    brave --version
elif command -v google-chrome &> /dev/null; then
    google-chrome --version
else
    echo "⚠ Aucun navigateur Chromium détecté (Brave/Chrome)"
fi

echo ""
echo "Note: ChromeDriver fonctionne avec Brave Browser car ils partagent le même moteur Chromium"