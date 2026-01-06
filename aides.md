# Aides - Documentation du Projet SAE 1.04

Documentation complète ligne par ligne de tous les fichiers du projet.

---

## Table des matières

### Scripts Bash
- [install.sh](#scriptsinstallsh) - Installation complète du projet
- [run.sh](#scriptsrunsh) - Lancement du serveur Django
- [migrate.sh](#scriptsmigratesh) - Migrations Django
- [test.sh](#scriptstestsh) - Tests de conformité
- [install_firmware.sh](#scriptsinstall_firmwaresh) - Installation ChromeDriver/Brave

### Fichiers SQL
- [create_tables.sql](#sqlcreate_tablessql) - Création des tables

### Application Django
- [models.py](#carte_grise_appcartes_grisesmodelspy) - Modèles de données
- [views.py](#carte_grise_appcartes_grisesviewspy) - Vues (contrôleurs)
- [urls.py](#carte_grise_appcartes_grisesurlspy) - Routes URL
- [utils.py](#carte_grise_appcartes_grisesutilspy) - Fonctions utilitaires

### Templates HTML
- [base.html](#carte_grise_appcartes_grisestemplatescartes_grisesbasehtml) - Template de base

### Fichiers de Tests SQL
- [test_conformite.sql](#sqltest_conformitesql) - Test de conformité des données
- [test_incrementation.sql](#sqltest_incrementationsql) - Test de la logique d'incrémentation

### Fichiers de Tests Python
- [tests.py](#carte_grise_appcartes_grisestestspy) - Tests unitaires génération de numéros
- [test_views.py](#carte_grise_appcartes_grisestest_viewspy) - Tests des vues Django
- [test_utils.py](#carte_grise_apptest_utilspy) - Script de test manuel des utilitaires
- [test_setup.py](#carte_grise_appcartes_grisestest_setuppy) - Configuration des tests

### Référence rapide
- [Commandes Bash utiles](#commandes-bash-utiles)
- [Commandes Django utiles](#commandes-django-utiles)
- [Commandes Linux utiles](#commandes-linux-utiles)
- [Commandes SQL utiles](#commandes-sql-utiles)

---

## scripts/install.sh

**Fonction** : Installe toutes les dépendances et configure la base de données du projet.

### Fonctionnement ligne par ligne

```bash
#!/bin/bash
```
> Indique que ce script doit être exécuté avec Bash.

```bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
```
> Définit des codes de couleur pour afficher des messages colorés dans le terminal (vert pour succès, rouge pour erreur, etc.).

```bash
APT_UPDATED=false
```
> Variable qui permet de savoir si on a déjà fait `apt-get update` pour éviter de le refaire plusieurs fois.

```bash
apt_update_once() {
    if [ "$APT_UPDATED" = false ]; then
        sudo apt-get update
        APT_UPDATED=true
    fi
}
```
> Fonction qui met à jour les dépôts apt une seule fois. Si on l'appelle plusieurs fois, elle ne fait rien après la première exécution.

```bash
if ! command -v curl &> /dev/null; then
```
> Vérifie si `curl` est installé sur le système. `command -v` cherche la commande, et `&> /dev/null` cache la sortie.

```bash
apt_update_once
sudo apt-get install -y curl
```
> Si curl n'est pas installé, on met à jour les dépôts puis on l'installe. `-y` répond "oui" automatiquement.

```bash
if [ $? -eq 0 ]; then
```
> Vérifie si la commande précédente a réussi. `$?` contient le code de retour (0 = succès).

```bash
export PATH="$HOME/.local/bin:$PATH"
```
> Ajoute le dossier `~/.local/bin` au PATH pour que les commandes installées par pip soient trouvées.

```bash
pip3 install uv || pip install uv
```
> Essaie d'installer `uv` avec pip3, et si ça échoue, essaie avec pip.

```bash
get_mariadb_version() {
    mysql --version 2>/dev/null | grep -oP 'MariaDB.*?(\d+\.\d+)' | grep -oP '\d+\.\d+' | head -1
}
```
> Fonction qui extrait le numéro de version de MariaDB (ex: "10.11") à partir de la commande `mysql --version`.

```bash
if [ "$mariadb_major" -lt 10 ] || ([ "$mariadb_major" -eq 10 ] && [ "$mariadb_minor" -lt 5 ]); then
```
> Vérifie si la version de MariaDB est inférieure à 10.5 (requise par Django).

```bash
curl -fsSL https://mariadb.org/mariadb_release_signing_key.pgp | sudo gpg --dearmor -o /usr/share/keyrings/mariadb-keyring.gpg
```
> Télécharge la clé GPG de MariaDB et la convertit au format utilisable par apt.

```bash
if sudo mysql -u root -e "USE carte_grise_db" 2>/dev/null; then
```
> Vérifie si la base de données `carte_grise_db` existe déjà en essayant de l'utiliser.

```bash
sudo mysql -u root carte_grise_db < "$(dirname "$0")/../sql/create_tables.sql"
```
> Exécute le fichier SQL qui crée les tables. `$(dirname "$0")` donne le dossier du script.

```bash
nb_fabricants=$(sudo mysql -u root carte_grise_db -N -e "SELECT COUNT(*) FROM Fabricant" 2>/dev/null || echo "0")
```
> Compte le nombre de fabricants dans la base. `-N` supprime les en-têtes. Si ça échoue, retourne "0".

```bash
if [ -d ".venv" ] && [ -f ".venv/pyvenv.cfg" ]; then
```
> Vérifie si l'environnement virtuel Python existe déjà (dossier .venv avec son fichier de config).

---

## scripts/run.sh

**Fonction** : Lance le serveur de développement Django.

### Fonctionnement ligne par ligne

```bash
cd carte_grise_app
```
> Se déplace dans le dossier de l'application Django.

```bash
printf "\n${BLUE}========================================${NC}"
printf "${BLUE}   Serveur Django démarré !${NC}"
printf "${BLUE}   URL: http://127.0.0.1:8000${NC}"
```
> Affiche un message indiquant que le serveur démarre avec l'URL d'accès.

```bash
uv run python manage.py runserver
```
> Lance le serveur Django via `uv`. `uv run` exécute la commande dans l'environnement virtuel géré par uv.

---

## scripts/migrate.sh

**Fonction** : Applique les migrations Django à la base de données (si nécessaire).

### Fonctionnement ligne par ligne

```bash
cd "$(dirname "$0")/../carte_grise_app"
```
> Se déplace dans le dossier de l'app Django. `$(dirname "$0")` donne le chemin du script, puis on remonte d'un niveau.

```bash
pending_migrations=$(uv run python manage.py showmigrations --plan 2>/dev/null | grep -c "\[ \]" || echo "0")
```
> Compte les migrations non appliquées. `showmigrations --plan` liste toutes les migrations, `[ ]` indique une migration en attente.

```bash
if [ "$pending_migrations" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Aucune migration en attente, base de données à jour\n"
    exit 0
fi
```
> Si aucune migration n'est en attente, on affiche un message et on quitte immédiatement (gain de temps).

```bash
uv run python manage.py migrate
```
> Applique toutes les migrations en attente à la base de données.

---

## scripts/test.sh

**Fonction** : Exécute les tests de conformité et les tests unitaires du projet.

### Fonctionnement ligne par ligne

```bash
read -p "Votre choix [1-5] (défaut: 5): " CHOICE
CHOICE=${CHOICE:-5}
```
> Demande à l'utilisateur de choisir un type de test. Si rien n'est entré, la valeur par défaut est 5 (tous les tests).

```bash
if ! command -v mysql &> /dev/null; then
```
> Vérifie que MySQL/MariaDB est installé avant de lancer les tests SQL.

```bash
TEMP_SQL=$(mktemp)
echo "SET @num_carte = '${NUM_CARTE}';" > "$TEMP_SQL"
cat "$(dirname "$0")/../sql/test_conformite.sql" >> "$TEMP_SQL"
```
> Crée un fichier temporaire qui définit une variable SQL puis ajoute le contenu du fichier de test.

```bash
if sudo mysql < "$TEMP_SQL"; then
```
> Exécute le fichier SQL temporaire et vérifie si ça a réussi.

```bash
case $CHOICE in
    1) run_conformite_test ;;
    2) run_incrementation_test ;;
    ...
esac
```
> Selon le choix de l'utilisateur, exécute la fonction de test correspondante.

---

## scripts/install_firmware.sh

**Fonction** : Installe ChromeDriver compatible avec Brave/Chrome pour les tests Selenium.

### Fonctionnement ligne par ligne

```bash
set -e
```
> Arrête le script immédiatement si une commande échoue.

```bash
if command -v brave-browser &> /dev/null; then
    brave_version=$(brave-browser --version | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "unknown")
```
> Vérifie si Brave est installé et récupère sa version.

```bash
chrome_major=$(echo "$brave_version" | cut -d. -f1)
```
> Extrait la version majeure (premier nombre avant le point).

```bash
curl -fsS https://dl.brave.com/install.sh | sh
```
> Si ni Brave ni Chrome ne sont installés, télécharge et exécute le script d'installation de Brave.

```bash
wget -N http://chromedriver.storage.googleapis.com/${version}/chromedriver_linux64.zip
unzip -o chromedriver_linux64.zip -d /usr/local/bin
chmod +x /usr/local/bin/chromedriver
```
> Télécharge ChromeDriver, le décompresse et le rend exécutable.

---

## sql/create_tables.sql

**Fonction** : Crée toutes les tables de la base de données avec leurs contraintes.

### Fonctionnement ligne par ligne

```sql
DROP TABLE IF EXISTS Controle_Technique;
DROP TABLE IF EXISTS Carte_Grise;
...
```
> Supprime les tables existantes dans l'ordre inverse des dépendances (les tables qui ont des clés étrangères sont supprimées en premier).

```sql
CREATE TABLE Fabricant (
    id_fabricant INT AUTO_INCREMENT,
    num_fabricant VARCHAR(10) NOT NULL UNIQUE,
    nom VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_fabricant)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
> Crée la table Fabricant avec un ID auto-incrémenté, un numéro unique et un nom. InnoDB permet les transactions et les clés étrangères.

```sql
FOREIGN KEY (id_fabricant) REFERENCES Fabricant(id_fabricant)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
```
> Crée une clé étrangère. `RESTRICT` empêche la suppression si des enregistrements liés existent. `CASCADE` propage les modifications.

```sql
CONSTRAINT chk_categorie CHECK (categorie IN ('deux_roues', 'automobile', 'camion_leger'))
```
> Contrainte CHECK qui limite les valeurs possibles pour la catégorie.

```sql
CONSTRAINT chk_format_num_carte
    CHECK (num REGEXP '^[0-9]{4}[A-Z]{2}[0-9]{5}$')
```
> Vérifie que le numéro de carte grise suit le format : 4 chiffres + 2 lettres + 5 chiffres (ex: 2024AB00001).

```sql
DELIMITER //
CREATE TRIGGER before_insert_vehicule
BEFORE INSERT ON Vehicule
FOR EACH ROW
BEGIN
    IF NEW.date_fabrication < '2020-01-01' OR NEW.date_fabrication > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La date de fabrication doit être entre 01/01/2020 et aujourd''hui';
    END IF;
END//
DELIMITER ;
```
> Trigger qui vérifie avant chaque insertion que la date de fabrication est valide. `SIGNAL` génère une erreur personnalisée.

---

## carte_grise_app/cartes_grises/models.py

**Fonction** : Définit les modèles Django qui représentent les tables de la base de données.

### Fonctionnement ligne par ligne

```python
class Fabricant(models.Model):
    id_fabricant = models.AutoField(primary_key=True)
    num_fabricant = models.CharField(max_length=10, unique=True)
    nom = models.CharField(max_length=100)
```
> Définit le modèle Fabricant avec ses champs. `AutoField` = auto-incrémenté, `CharField` = texte avec longueur max.

```python
class Meta:
    db_table = 'Fabricant'
    managed = False
```
> `db_table` spécifie le nom exact de la table SQL. `managed = False` indique que Django ne doit pas créer/modifier cette table (elle existe déjà).

```python
def __str__(self):
    return self.nom
```
> Méthode qui définit comment l'objet s'affiche en texte (utilisé dans l'admin et les templates).

```python
id_fabricant = models.ForeignKey(
    Fabricant,
    on_delete=models.RESTRICT,
    db_column='id_fabricant'
)
```
> Clé étrangère vers Fabricant. `RESTRICT` empêche la suppression si des enregistrements liés existent.

```python
class Vehicule(models.Model):
    num_serie = models.CharField(max_length=20, unique=True)
    emission_co2 = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
```
> `unique=True` garantit l'unicité. `DecimalField` pour les nombres décimaux. `null=True, blank=True` rend le champ optionnel.

---

## carte_grise_app/cartes_grises/views.py

**Fonction** : Contient les vues (contrôleurs) qui gèrent les requêtes HTTP.

### Fonctionnement ligne par ligne

```python
def index(request):
    context = {
        'total_cartes': CarteGrise.objects.count(),
        ...
    }
    return render(request, 'cartes_grises/index.html', context)
```
> Vue de la page d'accueil. Compte les enregistrements et passe les données au template.

```python
def liste_cartes_grises(request):
    cartes = CarteGrise.objects.select_related(
        'id_proprio', 'id_vehicule', ...
    ).all()
```
> `select_related` fait une jointure SQL pour éviter les requêtes N+1 (optimisation).

```python
search = request.GET.get('search', '')
if search:
    cartes = cartes.filter(
        Q(num__icontains=search) |
        Q(numero_immatriculation__icontains=search)
    )
```
> Récupère le paramètre de recherche de l'URL. `Q()` permet de combiner des filtres avec OR (`|`). `icontains` = recherche insensible à la casse.

```python
cartes = cartes.annotate(
    proprietaire_complet=Concat(
        'id_proprio__nom', Value(' '), 'id_proprio__prenoms',
        output_field=CharField()
    )
)
```
> `annotate` ajoute un champ calculé. `Concat` concatène les champs nom et prénom.

```python
def ajouter_carte_grise(request):
    if request.method == 'POST':
        try:
            carte = CarteGrise.objects.create(...)
            messages.success(request, f'Carte grise créée!')
            return redirect('detail_carte_grise', num=carte.num)
        except Exception as e:
            messages.error(request, f'Erreur: {str(e)}')
```
> Gère le formulaire d'ajout. Si POST, crée l'enregistrement. `messages` affiche des notifications. `redirect` redirige vers une autre page.

```python
def detail_carte_grise(request, num):
    carte = get_object_or_404(CarteGrise, num=num)
```
> `get_object_or_404` récupère l'objet ou renvoie une erreur 404 si non trouvé.

---

## carte_grise_app/cartes_grises/urls.py

**Fonction** : Définit les routes URL de l'application.

### Fonctionnement ligne par ligne

```python
urlpatterns = [
    path('', views.index, name='index'),
    path('cartes/', views.liste_cartes_grises, name='liste_cartes_grises'),
    path('cartes/<str:num>/', views.detail_carte_grise, name='detail_carte_grise'),
]
```
> `path()` associe une URL à une vue. `<str:num>` capture un paramètre texte dans l'URL. `name` permet de référencer l'URL dans les templates.

---

## carte_grise_app/cartes_grises/utils.py

**Fonction** : Fonctions utilitaires pour la génération automatique de numéros.

### Fonctionnement ligne par ligne

```python
def generer_prochain_numero_carte_grise():
    annee_actuelle = datetime.now().year
    dernier = CarteGrise.objects.filter(
        num__startswith=str(annee_actuelle)
    ).order_by('-num').first()
```
> Récupère le dernier numéro de carte grise de l'année en cours, trié par ordre décroissant.

```python
if not dernier:
    return f"{annee_actuelle}AA00001"
```
> Si aucune carte grise n'existe pour l'année, retourne le premier numéro.

```python
lettres = num_actuel[4:6]
chiffres = int(num_actuel[6:11])
chiffres += 1
if chiffres > 99999:
    chiffres = 0
    lettres = _incrementer_lettres(lettres)
```
> Incrémente les chiffres. Si dépassement (99999), remet à 0 et incrémente les lettres.

```python
def _incrementer_lettres(lettres):
    lettre1 = ord(lettres[0])
    lettre2 = ord(lettres[1])
    lettre2 += 1
    if lettre2 > ord('Z'):
        lettre2 = ord('A')
        lettre1 += 1
```
> `ord()` convertit un caractère en code ASCII. Incrémente la 2e lettre, et si elle dépasse Z, remet à A et incrémente la 1ère.

```python
def valider_format_numero_carte_grise(numero):
    import re
    pattern = r'^[0-9]{4}[A-Z]{2}[0-9]{5}$'
    return bool(re.match(pattern, numero))
```
> Valide le format avec une expression régulière. `^` = début, `$` = fin, `[0-9]{4}` = exactement 4 chiffres.

---

## carte_grise_app/cartes_grises/templates/cartes_grises/base.html

**Fonction** : Template de base dont héritent toutes les pages.

### Fonctionnement ligne par ligne

```html
<script src="https://cdn.tailwindcss.com"></script>
```
> Charge Tailwind CSS depuis un CDN pour le style.

```html
{% block title %}Gestion Carte Grise{% endblock %}
```
> Bloc Django que les templates enfants peuvent remplacer pour personnaliser le titre.

```html
<div class="hidden md:block">
```
> Classes Tailwind : `hidden` cache l'élément, `md:block` l'affiche sur écrans moyens et plus.

```html
<a href="{% url 'index' %}" class="...">
```
> `{% url 'index' %}` génère l'URL correspondant au nom 'index' défini dans urls.py.

```html
<button id="mobile-menu-button" aria-controls="mobile-menu" aria-expanded="false">
```
> Bouton hamburger avec attributs d'accessibilité ARIA.

```html
document.getElementById('mobile-menu-button').addEventListener('click', function() {
    mobileMenu.classList.toggle('hidden');
});
```
> JavaScript qui bascule la classe 'hidden' pour afficher/masquer le menu mobile.

```html
{% if messages %}
    {% for message in messages %}
        <div class="{% if message.tags == 'success' %}bg-green-50{% endif %}">
```
> Affiche les messages flash Django avec des couleurs selon le type (succès, erreur, info).

```html
{% block content %}{% endblock %}
```
> Bloc où les templates enfants insèrent leur contenu.

---

## Commandes Bash utiles

| Commande | Description |
|----------|-------------|
| `command -v X` | Vérifie si la commande X existe |
| `$?` | Code de retour de la dernière commande (0 = succès) |
| `$(...)` | Exécute une commande et retourne sa sortie |
| `${VAR:-default}` | Utilise la valeur de VAR, ou "default" si VAR est vide |
| `&> /dev/null` | Redirige stdout et stderr vers le néant (silence) |
| `2>/dev/null` | Redirige seulement stderr |
| `\|\| echo "0"` | Si la commande échoue, exécute `echo "0"` |
| `-eq`, `-lt`, `-gt` | Comparaisons numériques (égal, inférieur, supérieur) |
| `grep -c` | Compte le nombre de lignes correspondantes |
| `grep -oP` | Extrait seulement la partie correspondante (Perl regex) |
| `cut -d. -f1` | Coupe par "." et prend le 1er champ |
| `mktemp` | Crée un fichier temporaire |
| `set -e` | Arrête le script si une commande échoue |

---

## Commandes Django utiles

| Commande | Description |
|----------|-------------|
| `uv run python manage.py runserver` | Lance le serveur de développement |
| `uv run python manage.py migrate` | Applique les migrations |
| `uv run python manage.py makemigrations` | Crée de nouvelles migrations |
| `uv run python manage.py showmigrations` | Liste les migrations |
| `uv run python manage.py test` | Lance les tests |
| `uv run python manage.py shell` | Ouvre un shell Python interactif |
| `uv run python manage.py createsuperuser` | Crée un admin |

---

## Commandes Linux utiles

| Commande | Description |
|----------|-------------|
| `sudo adduser nom` | Crée un utilisateur |
| `sudo usermod -aG sudo nom` | Donne les droits sudo |
| `sudo userdel -r nom` | Supprime un utilisateur et son home |
| `exit` ou `logout` | Se déconnecter |
| `su - nom` | Se connecter en tant que nom |
| `sudo systemctl start mariadb` | Démarre MariaDB |
| `sudo systemctl status mariadb` | Vérifie le statut de MariaDB |
| `sudo mysql -u root` | Ouvre le client MySQL en root |

---

## Commandes SQL utiles

| Commande | Description |
|----------|-------------|
| `SHOW DATABASES;` | Liste les bases de données |
| `USE carte_grise_db;` | Sélectionne une base |
| `SHOW TABLES;` | Liste les tables |
| `DESCRIBE Fabricant;` | Montre la structure d'une table |
| `SELECT * FROM Fabricant;` | Affiche toutes les données |
| `SELECT COUNT(*) FROM Fabricant;` | Compte les enregistrements |

---

## sql/test_conformite.sql

**Fonction** : Vérifie que toutes les colonnes d'une carte grise respectent le cahier des charges.

### Fonctionnement ligne par ligne

```sql
SET @num_carte = '2020AA00001';
```
> Définit une variable SQL avec le numéro de carte grise à tester.

```sql
SELECT
    '0 - Numéro carte grise' AS 'Champ',
    cg.num AS 'Valeur',
    CASE
        WHEN cg.num REGEXP '^[0-9]{4}[A-Z]{2}[0-9]{5}$'
        THEN '✓ Format valide (AAAALLNNNNN)'
        ELSE '✗ Format invalide'
    END AS 'Validation'
FROM Carte_Grise cg
WHERE cg.num = @num_carte
```
> Pour chaque champ, affiche le nom, la valeur et vérifie le format avec une expression régulière.

```sql
UNION ALL
```
> Combine plusieurs SELECT en un seul résultat. `UNION ALL` garde les doublons (plus rapide que `UNION`).

```sql
IFNULL(DATE_FORMAT(cg.date_fin_validite, '%d/%m/%Y'), 'Indéterminée')
```
> Si la date est NULL, affiche "Indéterminée" sinon formate la date en JJ/MM/AAAA.

```sql
JOIN Proprietaire p ON cg.id_proprio = p.id_proprio
```
> Jointure pour récupérer les informations du propriétaire lié à la carte grise.

```sql
CASE
    WHEN v.poids_max_charge >= v.poids_vide
    THEN '✓ Cohérent (≥ poids vide)'
    ELSE '✗ Incohérent'
END
```
> Vérifie la cohérence logique : le poids chargé doit être supérieur au poids vide.

```sql
ROW_NUMBER() OVER (ORDER BY ct.date_controle)
```
> Fonction de fenêtrage qui numérote les lignes dans l'ordre des dates de contrôle.

### Sections du test

1. **Informations Carte Grise** - Numéro, immatriculation, dates
2. **Informations Propriétaire** - Nom, prénoms, adresse
3. **Informations Véhicule** - Marque, modèle, type, numéro de série
4. **Caractéristiques Techniques** - Cylindrée, puissance, poids, émissions
5. **Contrôles Techniques** - Liste des contrôles effectués
6. **Statistiques Globales** - Comptages de validation
7. **Vérification des Formats** - Validation globale de tous les enregistrements

---

## sql/test_incrementation.sql

**Fonction** : Vérifie que les règles d'incrémentation sont respectées pour tous les numéros.

### Fonctionnement ligne par ligne

```sql
SELECT
    'Liste complète des numéros' AS 'Test',
    num AS 'Numéro',
    SUBSTRING(num, 1, 4) AS 'Année',
    SUBSTRING(num, 5, 2) AS 'Lettres',
    SUBSTRING(num, 7, 5) AS 'Chiffres'
FROM Carte_Grise
ORDER BY num;
```
> Décompose chaque numéro de carte grise en ses parties : année (4 chiffres), lettres (2), chiffres (5).

```sql
LEFT JOIN Carte_Grise t2 ON t2.num = (
    SELECT MIN(num) FROM Carte_Grise
    WHERE num > t1.num
)
```
> Auto-jointure pour comparer chaque numéro avec le suivant (plus petit numéro supérieur).

```sql
CAST(SUBSTRING(t1.num, 7, 5) AS UNSIGNED)
```
> Convertit les 5 derniers caractères en nombre pour comparaison numérique.

```sql
GROUP_CONCAT(SUBSTRING(v.num_serie, -6) ORDER BY v.num_serie SEPARATOR ', ')
```
> Concatène les 6 derniers chiffres de tous les numéros de série, séparés par des virgules.

### Règles d'incrémentation testées

| Type | Format | Règle |
|------|--------|-------|
| Carte grise | AAAALLNNNNN | Chiffres (00000-99999) puis lettres (AA-ZZ) |
| Immatriculation | LLNNNLL | Lettres droite, puis chiffres (010-999), puis lettres gauche |
| Numéro de série | NumFab+YYYYMM+6chiffres | Séquence par fabricant et mois |

---

## carte_grise_app/cartes_grises/tests.py

**Fonction** : Tests unitaires Django pour la génération automatique de numéros.

### Fonctionnement ligne par ligne

```python
class BaseTestCaseWithTables(TransactionTestCase):
```
> Classe de base pour les tests. `TransactionTestCase` permet de manipuler la base de données entre les tests.

```python
tables_to_truncate = [
    'Controle_Technique',
    'Carte_Grise',
    ...
]
```
> Liste des tables à vider entre chaque test, dans l'ordre des dépendances (enfants d'abord).

```python
@classmethod
def setUpClass(cls):
    super().setUpClass()
    ...
    subprocess.run(mysql_cmd, stdin=f, check=True)
```
> Méthode exécutée une fois avant tous les tests de la classe. Charge le schéma SQL via mysql.

```python
def tearDown(self):
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    for table in self.tables_to_truncate:
        cursor.execute(f"TRUNCATE TABLE {table}")
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
```
> Après chaque test, désactive les contraintes de clés étrangères, vide les tables, puis réactive les contraintes.

```python
class IncrementationLettresTestCase(TestCase):
    def test_increment_lettre_droite(self):
        self.assertEqual(_incrementer_lettres("AA"), "AB")
```
> Test unitaire simple : vérifie que AA devient AB après incrémentation.

```python
def test_increment_avec_retenue(self):
    self.assertEqual(_incrementer_lettres("AZ"), "BA")
```
> Test de la retenue : quand Z atteint sa limite, on remet à A et on incrémente la lettre de gauche.

```python
class GenerationNumeroCarteGriseTestCase(BaseTestCaseWithTables):
    def setUp(self):
        self.fabricant = Fabricant.objects.create(
            num_fabricant="FAB001",
            nom="Test Fabricant"
        )
```
> Prépare les données nécessaires pour les tests (fabricant, marque, modèle, véhicule, etc.).

```python
def test_premier_numero_annee(self):
    annee = datetime.now().year
    numero = generer_prochain_numero_carte_grise()
    self.assertEqual(numero, f"{annee}AA00001")
```
> Vérifie que le premier numéro de l'année est bien AAAAA00001.

```python
def test_increment_lettres_apres_99999(self):
    CarteGrise.objects.create(num=f"{annee}AA99999", ...)
    numero = generer_prochain_numero_carte_grise()
    self.assertEqual(numero, f"{annee}AB00000")
```
> Vérifie que après 99999, on passe à AB00000 (incrémentation des lettres).

```python
def test_limite_maximale(self):
    CarteGrise.objects.create(numero_immatriculation="ZZ999ZZ", ...)
    with self.assertRaises(ValueError):
        generer_prochain_numero_immatriculation()
```
> Vérifie qu'une exception est levée quand on atteint la limite maximale ZZ999ZZ.

### Classes de tests

| Classe | Tests |
|--------|-------|
| `IncrementationLettresTestCase` | Incrémentation AA→AB, AZ→BA, ZZ→AA |
| `ValidationFormatTestCase` | Formats valides/invalides de numéros |
| `GenerationNumeroCarteGriseTestCase` | Génération du prochain numéro CG |
| `GenerationNumeroImmatriculationTestCase` | Génération du prochain numéro immat |
| `RecuperationDernierNumeroTestCase` | Récupération des derniers numéros |
| `GenerationNumeroSerieTestCase` | Format et séquence des numéros de série |

---

## carte_grise_app/cartes_grises/test_views.py

**Fonction** : Tests des vues Django (requêtes HTTP simulées).

### Fonctionnement ligne par ligne

```python
class CarteGriseViewsTestCase(TransactionTestCase):
    def setUp(self):
        self.client = Client()
```
> `Client()` est un client HTTP de test Django qui simule un navigateur.

```python
self.cg1 = CarteGrise.objects.create(
    num="2024AA12345",
    numero_immatriculation="BE123AA",
    date_immatriculation=today - timedelta(days=30),
    ...
)
```
> Crée des données de test avec des dates relatives (30 jours avant aujourd'hui).

```python
def test_filtre_par_date_debut_et_fin(self):
    response = self.client.get('/cartes/', {
        'date_debut': date_debut,
        'date_fin': date_fin
    })
    self.assertEqual(response.status_code, 200)
```
> Simule une requête GET avec des paramètres de filtre et vérifie que la réponse est OK (200).

```python
cartes = response.context['cartes']
self.assertEqual(len(cartes), 2)
```
> Accède au contexte passé au template et vérifie le nombre de résultats.

```python
plaques = [cg.numero_immatriculation for cg in cartes]
self.assertIn("BE123AA", plaques)
self.assertNotIn("BE025AC", plaques)
```
> Vérifie que les bonnes plaques sont présentes/absentes dans les résultats.

```python
def test_tri_alphabetique_nom(self):
    response = self.client.get('/cartes/', {'sort': 'proprietaire_nom'})
    cartes = list(response.context['cartes'])
    self.assertEqual(cartes[0].id_proprio.nom, "BERNARD")
```
> Vérifie que le tri alphabétique fonctionne (BERNARD < DUBOIS < MARTIN).

```python
def test_statistiques_marques_ordre_decroissant(self):
    stats_marques = response.context['stats_marques']
    for i in range(len(stats_marques) - 1):
        self.assertGreaterEqual(
            stats_marques[i]['count'],
            stats_marques[i + 1]['count']
        )
```
> Vérifie que les marques sont triées par nombre décroissant de véhicules.

### Tests par fonctionnalité SAE

| Fonctionnalité | Classe de test |
|----------------|----------------|
| a. Cartes grises par laps de temps | `TestListeCartesGrisesParDate` |
| b. Par nom/prénom (alphabétique) | `TestListeCartesGrisesParNomPrenom` |
| c. Par numéro de plaque (filtres) | `TestListeCartesGrisesParPlaque` |
| d. Marques ordre décroissant | `TestStatistiquesMarques` |
| e. Véhicules > X ans + CO2 > Y | `TestVehiculesAnciensPolluants` |

---

## carte_grise_app/test_utils.py

**Fonction** : Script de test manuel pour vérifier les fonctions utilitaires.

### Fonctionnement ligne par ligne

```python
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
```
> Configure Django manuellement pour pouvoir utiliser les modèles en dehors du serveur.

```python
def test_generation_numero_serie():
    vehicule = Vehicule.objects.first()
    if vehicule:
        print(f"Numéro de série généré: {vehicule.numero_serie}")
```
> Récupère le premier véhicule et affiche son numéro de série.

```python
def test_generation_numero_carte_grise():
    dernier = recuperer_dernier_numero_carte_grise()
    prochain = generer_prochain_numero_carte_grise()
    print(f"Dernier numéro: {dernier}")
    print(f"Prochain numéro: {prochain}")
```
> Affiche le dernier numéro et le prochain qui serait généré.

```python
def test_statistiques_base():
    print(f"Fabricants: {Fabricant.objects.count()}")
    print(f"Marques: {Marque.objects.count()}")
    ...
```
> Affiche les comptages de chaque table pour avoir une vue d'ensemble.

```python
if __name__ == "__main__":
    test_statistiques_base()
    test_generation_numero_serie()
    ...
```
> Point d'entrée : exécute tous les tests quand le script est lancé directement.

### Utilisation

```bash
cd carte_grise_app
uv run python test_utils.py
```

---

## carte_grise_app/cartes_grises/test_setup.py

**Fonction** : Configuration de base pour créer les tables de test.

### Fonctionnement ligne par ligne

```python
def setup_test_database():
    with connection.cursor() as cursor:
        with open('../../create_tables.sql', 'r') as f:
            sql_content = f.read()
```
> Ouvre une connexion à la base et lit le fichier SQL de création des tables.

```python
sql_commands = [cmd.strip() for cmd in sql_content.split(';') if cmd.strip()]
```
> Découpe le contenu SQL par point-virgule pour exécuter chaque commande séparément.

```python
for command in sql_commands:
    if command and not command.startswith('--'):
        try:
            cursor.execute(command)
        except Exception as e:
            if 'DROP' not in command:
                print(f"Erreur: {e}")
```
> Exécute chaque commande SQL, en ignorant les commentaires et les erreurs DROP (table n'existe pas).

```python
class BaseTestCase(TestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        setup_test_database()
```
> Classe de base qui crée automatiquement les tables au début de chaque série de tests.

---

## Commandes de test utiles

| Commande | Description |
|----------|-------------|
| `./scripts/test.sh` | Lance le menu interactif de tests |
| `uv run python manage.py test cartes_grises` | Tous les tests Python |
| `uv run python manage.py test cartes_grises.tests` | Tests de génération de numéros |
| `uv run python manage.py test cartes_grises.test_views` | Tests des vues |
| `uv run python manage.py test cartes_grises --verbosity=2` | Mode verbose |
| `uv run python manage.py test cartes_grises.tests.GenerationNumeroCarteGriseTestCase` | Une classe de test |
| `uv run python manage.py test cartes_grises.tests.GenerationNumeroCarteGriseTestCase.test_premier_numero_annee` | Un test spécifique |
| `uv run python test_utils.py` | Tests manuels des utilitaires |
