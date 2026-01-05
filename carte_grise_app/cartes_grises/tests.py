"""
Tests pour les fonctions de génération de numéros
SAE 1.04 - Carte Grise

Ces tests vérifient les fonctionnalités de génération automatique :
- Génération du prochain numéro de carte grise
- Génération du prochain numéro d'immatriculation
- Validation des formats
- Récupération des derniers numéros
"""

from django.test import TestCase, TransactionTestCase
from django.db import connection
from django.conf import settings
from datetime import date, datetime
import os
import subprocess
from .models import (
    Fabricant, Marque, Modele, Proprietaire, Vehicule, CarteGrise,
    CategorieModele, CategoriePermis, ClasseEnvironnementVehicule
)
from .utils import (
    generer_prochain_numero_carte_grise,
    generer_prochain_numero_immatriculation,
    generer_numero_serie,
    valider_format_numero_carte_grise,
    valider_format_immatriculation,
    recuperer_dernier_numero_carte_grise,
    recuperer_dernier_numero_immatriculation,
    _incrementer_lettres
)


class BaseTestCaseWithTables(TransactionTestCase):
    """
    Classe de base qui crée les tables avant chaque test
    car les modèles sont managed=False
    """
    # Liste des tables à vider entre les tests
    tables_to_truncate = [
        'Controle_Technique',
        'Carte_Grise',
        'Vehicule',
        'Proprietaire',
        'Modele',
        'Marque',
        'Fabricant',
        'CategorieModele',
        'CategoriePermis',
        'ClasseEnvironnementVehicule'
    ]

    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        # Récupérer le nom de la base de test depuis les settings
        db_settings = settings.DATABASES['default']
        test_db_name = connection.settings_dict['NAME']

        # Charger le schéma SQL
        sql_file = os.path.join(os.path.dirname(__file__), '../../create_tables.sql')

        # Exécuter le SQL avec mysql directement
        mysql_cmd = [
            'mysql',
            '-u', db_settings['USER'],
            f'-p{db_settings["PASSWORD"]}',
            '-h', db_settings.get('HOST', 'localhost'),
            test_db_name
        ]

        try:
            with open(sql_file, 'r') as f:
                subprocess.run(
                    mysql_cmd,
                    stdin=f,
                    check=True,
                    capture_output=True,
                    text=True
                )
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors de la création des tables: {e.stderr}")
            # Essayer aussi avec Django
            with open(sql_file, 'r') as f:
                sql_content = f.read()

            with connection.cursor() as cursor:
                for statement in sql_content.split(';'):
                    statement = statement.strip()
                    if statement and not statement.startswith('--') and not statement.startswith('/*'):
                        try:
                            cursor.execute(statement)
                        except Exception as ex:
                            print(f"Erreur SQL: {ex}")

    def tearDown(self):
        """Nettoyer les tables après chaque test"""
        super().tearDown()
        with connection.cursor() as cursor:
            # Désactiver les contraintes de clés étrangères temporairement
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

            # Vider toutes les tables
            for table in self.tables_to_truncate:
                try:
                    cursor.execute(f"TRUNCATE TABLE {table}")
                except Exception:
                    pass

            # Réactiver les contraintes
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")


class IncrementationLettresTestCase(TestCase):
    """Tests de la fonction d'incrémentation de lettres"""

    def test_increment_lettre_droite(self):
        """Test: AA -> AB"""
        self.assertEqual(_incrementer_lettres("AA"), "AB")

    def test_increment_lettre_droite_milieu(self):
        """Test: AM -> AN"""
        self.assertEqual(_incrementer_lettres("AM"), "AN")

    def test_increment_avec_retenue(self):
        """Test: AZ -> BA (retenue sur lettre gauche)"""
        self.assertEqual(_incrementer_lettres("AZ"), "BA")

    def test_increment_fin_alphabet(self):
        """Test: ZZ -> AA (retour au début)"""
        self.assertEqual(_incrementer_lettres("ZZ"), "AA")

    def test_increment_sequences(self):
        """Test: séquence complète AB -> AC -> ... -> AZ -> BA"""
        result = _incrementer_lettres("AB")
        self.assertEqual(result, "AC")
        result = _incrementer_lettres("AY")
        self.assertEqual(result, "AZ")
        result = _incrementer_lettres("AZ")
        self.assertEqual(result, "BA")


class ValidationFormatTestCase(TestCase):
    """Tests des fonctions de validation de format"""

    def test_format_carte_grise_valide(self):
        """Test: format carte grise valide (2026AA00001)"""
        self.assertTrue(valider_format_numero_carte_grise("2026AA00001"))
        self.assertTrue(valider_format_numero_carte_grise("2020ZZ99999"))

    def test_format_carte_grise_invalide(self):
        """Test: formats carte grise invalides"""
        self.assertFalse(valider_format_numero_carte_grise("2026AA0001"))  # Trop court
        self.assertFalse(valider_format_numero_carte_grise("2026AA000001"))  # Trop long
        self.assertFalse(valider_format_numero_carte_grise("2026aa00001"))  # Minuscules
        self.assertFalse(valider_format_numero_carte_grise("26AA00001"))  # Année courte
        self.assertFalse(valider_format_numero_carte_grise("2026A100001"))  # Chiffre dans lettres

    def test_format_immatriculation_valide(self):
        """Test: format immatriculation valide (AA010AA)"""
        self.assertTrue(valider_format_immatriculation("AA010AA"))
        self.assertTrue(valider_format_immatriculation("ZZ999ZZ"))

    def test_format_immatriculation_invalide(self):
        """Test: formats immatriculation invalides"""
        self.assertFalse(valider_format_immatriculation("AA10AA"))  # Chiffres courts
        self.assertFalse(valider_format_immatriculation("AA0100AA"))  # Trop long
        self.assertFalse(valider_format_immatriculation("aa010aa"))  # Minuscules
        self.assertFalse(valider_format_immatriculation("A1010AA"))  # Chiffre dans lettres


class GenerationNumeroCarteGriseTestCase(BaseTestCaseWithTables):
    """Tests de génération du prochain numéro de carte grise"""

    def setUp(self):
        """Préparation des données de test"""
        # Créer les données minimales nécessaires
        self.fabricant = Fabricant.objects.create(
            num_fabricant="FAB001",
            nom="Test Fabricant"
        )
        self.marque = Marque.objects.create(
            nom="Test Marque",
            id_fabricant=self.fabricant
        )
        self.categorie = CategorieModele.objects.create(
            categorie="automobile"
        )
        self.modele = Modele.objects.create(
            nom="Test Modele",
            id_marque=self.marque,
            id_categorie_modele=self.categorie
        )
        self.proprietaire = Proprietaire.objects.create(
            nom="Test",
            prenoms="Utilisateur",
            adresse="123 Rue Test"
        )
        self.permis = CategoriePermis.objects.create(permis="B")
        self.classe_env = ClasseEnvironnementVehicule.objects.create(classe="1")
        self.vehicule = Vehicule.objects.create(
            num_serie="FAB001202001000001",
            date_fabrication=date(2020, 1, 15),
            date_premiere_immatriculation=date(2020, 2, 1),
            id_modele=self.modele,
            id_fabricant=self.fabricant,
            id_classe_environnementale=self.classe_env,
            id_permis=self.permis
        )

    def test_premier_numero_annee(self):
        """Test: génération du premier numéro d'une année (aucune carte existante)"""
        annee = datetime.now().year
        numero = generer_prochain_numero_carte_grise()
        self.assertEqual(numero, f"{annee}AA00001")

    def test_increment_chiffres_simple(self):
        """Test: 2026AA00001 -> 2026AA00002"""
        annee = datetime.now().year
        CarteGrise.objects.create(
            num=f"{annee}AA00001",
            numero_immatriculation="AA010AA",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        numero = generer_prochain_numero_carte_grise()
        self.assertEqual(numero, f"{annee}AA00002")

    def test_increment_multiples(self):
        """Test: incrémentation successive"""
        annee = datetime.now().year
        CarteGrise.objects.create(
            num=f"{annee}AA00010",
            numero_immatriculation="AA010AA",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        numero = generer_prochain_numero_carte_grise()
        self.assertEqual(numero, f"{annee}AA00011")

    def test_increment_lettres_apres_99999(self):
        """Test: 2026AA99999 -> 2026AB00000"""
        annee = datetime.now().year
        CarteGrise.objects.create(
            num=f"{annee}AA99999",
            numero_immatriculation="AA010AA",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        numero = generer_prochain_numero_carte_grise()
        self.assertEqual(numero, f"{annee}AB00000")

    def test_format_resultat_valide(self):
        """Test: le numéro généré respecte le format"""
        numero = generer_prochain_numero_carte_grise()
        self.assertTrue(valider_format_numero_carte_grise(numero))


class GenerationNumeroImmatriculationTestCase(BaseTestCaseWithTables):
    """Tests de génération du prochain numéro d'immatriculation"""

    def setUp(self):
        """Préparation des données de test"""
        self.fabricant = Fabricant.objects.create(
            num_fabricant="FAB001",
            nom="Test Fabricant"
        )
        self.marque = Marque.objects.create(
            nom="Test Marque",
            id_fabricant=self.fabricant
        )
        self.categorie = CategorieModele.objects.create(
            categorie="automobile"
        )
        self.modele = Modele.objects.create(
            nom="Test Modele",
            id_marque=self.marque,
            id_categorie_modele=self.categorie
        )
        self.proprietaire = Proprietaire.objects.create(
            nom="Test",
            prenoms="Utilisateur",
            adresse="123 Rue Test"
        )
        self.permis = CategoriePermis.objects.create(permis="B")
        self.classe_env = ClasseEnvironnementVehicule.objects.create(classe="1")
        self.vehicule = Vehicule.objects.create(
            num_serie="FAB001202001000001",
            date_fabrication=date(2020, 1, 15),
            date_premiere_immatriculation=date(2020, 2, 1),
            id_modele=self.modele,
            id_fabricant=self.fabricant,
            id_classe_environnementale=self.classe_env,
            id_permis=self.permis
        )

    def test_premier_numero(self):
        """Test: génération du premier numéro (aucune immatriculation)"""
        numero = generer_prochain_numero_immatriculation()
        self.assertEqual(numero, "AA010AA")

    def test_increment_lettres_droite(self):
        """Test: AA010AA -> AA010AB"""
        CarteGrise.objects.create(
            num="2026AA00001",
            numero_immatriculation="AA010AA",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        numero = generer_prochain_numero_immatriculation()
        self.assertEqual(numero, "AA010AB")

    def test_increment_lettres_droite_fin(self):
        """Test: AA010ZZ -> AA011AA (reset lettres droite)"""
        CarteGrise.objects.create(
            num="2026AA00001",
            numero_immatriculation="AA010ZZ",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        numero = generer_prochain_numero_immatriculation()
        self.assertEqual(numero, "AA011AA")

    def test_increment_chiffres(self):
        """Test: AB078ZZ -> AB079AA"""
        CarteGrise.objects.create(
            num="2026AA00001",
            numero_immatriculation="AB078ZZ",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        numero = generer_prochain_numero_immatriculation()
        self.assertEqual(numero, "AB079AA")

    def test_increment_lettres_gauche(self):
        """Test: AB999ZZ -> AC010AA"""
        CarteGrise.objects.create(
            num="2026AA00001",
            numero_immatriculation="AB999ZZ",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        numero = generer_prochain_numero_immatriculation()
        self.assertEqual(numero, "AC010AA")

    def test_chiffres_minimum_010(self):
        """Test: les chiffres sont toujours >= 010"""
        numero = generer_prochain_numero_immatriculation()
        chiffres = int(numero[2:5])
        self.assertGreaterEqual(chiffres, 10)

    def test_limite_maximale(self):
        """Test: exception si limite ZZ999ZZ atteinte"""
        CarteGrise.objects.create(
            num="2026AA00001",
            numero_immatriculation="ZZ999ZZ",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        with self.assertRaises(ValueError):
            generer_prochain_numero_immatriculation()

    def test_format_resultat_valide(self):
        """Test: le numéro généré respecte le format"""
        numero = generer_prochain_numero_immatriculation()
        self.assertTrue(valider_format_immatriculation(numero))


class RecuperationDernierNumeroTestCase(BaseTestCaseWithTables):
    """Tests de récupération des derniers numéros"""

    def setUp(self):
        """Préparation des données de test"""
        self.fabricant = Fabricant.objects.create(
            num_fabricant="FAB001",
            nom="Test Fabricant"
        )
        self.marque = Marque.objects.create(
            nom="Test Marque",
            id_fabricant=self.fabricant
        )
        self.categorie = CategorieModele.objects.create(
            categorie="automobile"
        )
        self.modele = Modele.objects.create(
            nom="Test Modele",
            id_marque=self.marque,
            id_categorie_modele=self.categorie
        )
        self.proprietaire = Proprietaire.objects.create(
            nom="Test",
            prenoms="Utilisateur",
            adresse="123 Rue Test"
        )
        self.permis = CategoriePermis.objects.create(permis="B")
        self.classe_env = ClasseEnvironnementVehicule.objects.create(classe="1")
        self.vehicule = Vehicule.objects.create(
            num_serie="FAB001202001000001",
            date_fabrication=date(2020, 1, 15),
            date_premiere_immatriculation=date(2020, 2, 1),
            id_modele=self.modele,
            id_fabricant=self.fabricant,
            id_classe_environnementale=self.classe_env,
            id_permis=self.permis
        )

    def test_aucune_carte_grise(self):
        """Test: retourne None si aucune carte grise"""
        self.assertIsNone(recuperer_dernier_numero_carte_grise())
        self.assertIsNone(recuperer_dernier_numero_immatriculation())

    def test_recuperer_dernier_numero_carte_grise(self):
        """Test: récupère le dernier numéro de carte grise"""
        CarteGrise.objects.create(
            num="2026AA00001",
            numero_immatriculation="AA010AA",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        CarteGrise.objects.create(
            num="2026AA00005",
            numero_immatriculation="AA011AA",
            date_immatriculation=date(2020, 1, 2),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        self.assertEqual(recuperer_dernier_numero_carte_grise(), "2026AA00005")

    def test_recuperer_dernier_numero_immatriculation(self):
        """Test: récupère le dernier numéro d'immatriculation"""
        CarteGrise.objects.create(
            num="2026AA00001",
            numero_immatriculation="AA010AA",
            date_immatriculation=date(2020, 1, 1),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        CarteGrise.objects.create(
            num="2026AA00002",
            numero_immatriculation="AB025ZZ",
            date_immatriculation=date(2020, 1, 2),
            id_proprio=self.proprietaire,
            id_vehicule=self.vehicule
        )
        self.assertEqual(recuperer_dernier_numero_immatriculation(), "AB025ZZ")


class GenerationNumeroSerieTestCase(BaseTestCaseWithTables):
    """Tests de génération du numéro de série"""

    def setUp(self):
        """Préparation des données de test"""
        self.fabricant = Fabricant.objects.create(
            num_fabricant="FAB001",
            nom="Yamaha"
        )
        self.marque = Marque.objects.create(
            nom="Yamaha",
            id_fabricant=self.fabricant
        )
        self.categorie = CategorieModele.objects.create(
            categorie="deux_roues"
        )
        self.modele = Modele.objects.create(
            nom="MT-07",
            id_marque=self.marque,
            id_categorie_modele=self.categorie
        )
        self.permis = CategoriePermis.objects.create(permis="A")
        self.classe_env = ClasseEnvironnementVehicule.objects.create(classe="2")

    def test_format_numero_serie(self):
        """Test: format NumFabricant + YYYYMM + 6 chiffres"""
        vehicule = Vehicule.objects.create(
            num_serie="TEMP",
            date_fabrication=date(2024, 3, 15),
            date_premiere_immatriculation=date(2024, 4, 1),
            id_modele=self.modele,
            id_fabricant=self.fabricant,
            id_classe_environnementale=self.classe_env,
            id_permis=self.permis
        )
        numero = generer_numero_serie(vehicule)
        self.assertTrue(numero.startswith("FAB001202403"))
        self.assertEqual(len(numero), 18)  # FAB001(6) + 2024(4) + 03(2) + 000001(6)

    def test_sequence_par_mois(self):
        """Test: séquence s'incrémente par fabricant et mois"""
        # Premier véhicule mars 2024
        v1 = Vehicule.objects.create(
            num_serie="TEMP1",
            date_fabrication=date(2024, 3, 15),
            date_premiere_immatriculation=date(2024, 4, 1),
            id_modele=self.modele,
            id_fabricant=self.fabricant,
            id_classe_environnementale=self.classe_env,
            id_permis=self.permis
        )
        # Deuxième véhicule mars 2024
        v2 = Vehicule.objects.create(
            num_serie="TEMP2",
            date_fabrication=date(2024, 3, 20),
            date_premiere_immatriculation=date(2024, 4, 5),
            id_modele=self.modele,
            id_fabricant=self.fabricant,
            id_classe_environnementale=self.classe_env,
            id_permis=self.permis
        )

        num1 = generer_numero_serie(v1)
        num2 = generer_numero_serie(v2)

        self.assertEqual(num1, "FAB001202403000001")
        self.assertEqual(num2, "FAB001202403000002")


# Instructions pour lancer les tests
"""
Pour lancer tous les tests:
    python manage.py test cartes_grises

Pour lancer une classe de tests spécifique:
    python manage.py test cartes_grises.tests.GenerationNumeroCarteGriseTestCase

Pour lancer un test spécifique:
    python manage.py test cartes_grises.tests.GenerationNumeroCarteGriseTestCase.test_increment_chiffres_simple

Pour lancer avec verbose:
    python manage.py test cartes_grises --verbosity=2
"""
