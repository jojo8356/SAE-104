"""
Tests des vues (backend) pour l'application Cartes Grises
SAE 1.04

Tests des fonctionnalités de consultation & statistiques via requêtes HTTP simulées:
a. Lister les cartes grises par laps de temps
b. Lister par nom/prénom (ordre alphabétique) ou séquence de caractères
c. Lister par numéro de plaque (commence par, finit par, chiffres entre X-Y)
d. Lister les marques par ordre décroissant
e. Véhicules > X années + émission CO2 > Y
"""

from django.test import TransactionTestCase, Client
from django.db import connection
from django.conf import settings
from datetime import date, timedelta
import subprocess
import os

from .models import (
    CarteGrise, Vehicule, Proprietaire, Fabricant, Marque, Modele,
    CategorieModele, CategoriePermis, ClasseEnvironnementVehicule
)


class CarteGriseViewsTestCase(TransactionTestCase):
    """Classe de base pour les tests de vues"""

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

        # Créer les tables avec le schéma SQL
        db_settings = settings.DATABASES['default']
        test_db_name = connection.settings_dict['NAME']

        sql_file = os.path.join(os.path.dirname(__file__), '../../sql/create_tables.sql')

        mysql_cmd = [
            'mysql',
            '-u', db_settings['USER'],
            f'-p{db_settings["PASSWORD"]}',
            '-h', db_settings.get('HOST', 'localhost'),
            test_db_name
        ]

        with open(sql_file, 'r') as f:
            # Ne pas échouer si les tables existent déjà (--keepdb)
            result = subprocess.run(
                mysql_cmd,
                stdin=f,
                check=False,  # Ne pas lever d'exception
                capture_output=True,
                text=True
            )

    def _clean_tables(self):
        """Nettoyer toutes les tables de test"""
        with connection.cursor() as cursor:
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            for table in self.tables_to_truncate:
                try:
                    cursor.execute(f"TRUNCATE TABLE {table}")
                except Exception:
                    pass
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

    def setUp(self):
        """Créer des données de test"""
        self._clean_tables()

        # Client HTTP pour les requêtes
        self.client = Client()

        # Créer les catégories
        self.cat_modele = CategorieModele.objects.create(
            id_categorie_modele=1,
            categorie="automobile"
        )
        self.cat_permis_b = CategoriePermis.objects.create(
            id_permis=1,
            permis="B"
        )
        self.classe_env = ClasseEnvironnementVehicule.objects.create(
            id_classe_environnementale=1,
            classe="2"
        )

        # Créer fabricants et marques
        self.fabricant1 = Fabricant.objects.create(
            num_fabricant="FAB001",
            nom="Renault France"
        )
        self.fabricant2 = Fabricant.objects.create(
            num_fabricant="FAB002",
            nom="Peugeot SA"
        )

        self.marque_renault = Marque.objects.create(
            nom="Renault",
            id_fabricant=self.fabricant1
        )
        self.marque_peugeot = Marque.objects.create(
            nom="Peugeot",
            id_fabricant=self.fabricant2
        )

        # Créer modèles
        self.modele_clio = Modele.objects.create(
            nom="Clio 5",
            id_marque=self.marque_renault,
            id_categorie_modele=self.cat_modele
        )
        self.modele_208 = Modele.objects.create(
            nom="208",
            id_marque=self.marque_peugeot,
            id_categorie_modele=self.cat_modele
        )

        # Créer propriétaires
        self.proprio1 = Proprietaire.objects.create(
            nom="MARTIN",
            prenoms="Jean",
            adresse="1 rue de Paris 75001 Paris"
        )
        self.proprio2 = Proprietaire.objects.create(
            nom="BERNARD",
            prenoms="Marie",
            adresse="2 rue de Lyon 69001 Lyon"
        )
        self.proprio3 = Proprietaire.objects.create(
            nom="DUBOIS",
            prenoms="Pierre",
            adresse="3 rue de Marseille 13001 Marseille"
        )

        # Créer véhicules avec dates différentes (contrainte: >= 2020)
        today = date.today()
        self.vehicule1 = Vehicule.objects.create(
            num_serie="VF1CLIO5000001",
            id_modele=self.modele_clio,
            date_fabrication=date(2024, 1, 15),  # Récent (< 5 ans)
            date_premiere_immatriculation=date(2024, 2, 1),
            emission_co2=95,  # < 100
            id_classe_environnementale=self.classe_env,
            id_fabricant=self.fabricant1,
            id_permis=self.cat_permis_b
        )
        self.vehicule2 = Vehicule.objects.create(
            num_serie="VF3208000000001",
            id_modele=self.modele_208,
            date_fabrication=date(2022, 6, 20),  # Récent (< 5 ans)
            date_premiere_immatriculation=date(2022, 7, 1),
            emission_co2=110,  # > 100
            id_classe_environnementale=self.classe_env,
            id_fabricant=self.fabricant2,
            id_permis=self.cat_permis_b
        )
        self.vehicule3 = Vehicule.objects.create(
            num_serie="VF1CLIO5000002",
            id_modele=self.modele_clio,
            date_fabrication=date(2020, 3, 10),  # Plus ancien (> 4 ans)
            date_premiere_immatriculation=date(2020, 4, 1),
            emission_co2=130,  # > 100
            id_classe_environnementale=self.classe_env,
            id_fabricant=self.fabricant1,
            id_permis=self.cat_permis_b
        )

        # Créer cartes grises avec différentes plaques
        # Format num: AAAALLNNNNN (4 lettres + 2 lettres + 5 chiffres)
        # Format immat: LLNNNLL (2 lettres + 3 chiffres + 2 lettres)
        self.cg1 = CarteGrise.objects.create(
            num="2024AA12345",
            numero_immatriculation="BE123AA",
            date_immatriculation=today - timedelta(days=30),
            id_proprio=self.proprio1,
            id_vehicule=self.vehicule1
        )
        self.cg2 = CarteGrise.objects.create(
            num="2024BB23456",
            numero_immatriculation="CD456BB",
            date_immatriculation=today - timedelta(days=60),
            id_proprio=self.proprio2,
            id_vehicule=self.vehicule2
        )
        self.cg3 = CarteGrise.objects.create(
            num="2024CC34567",
            numero_immatriculation="BE025AC",
            date_immatriculation=today - timedelta(days=90),
            id_proprio=self.proprio3,
            id_vehicule=self.vehicule3
        )

    def tearDown(self):
        """Nettoyer après chaque test"""
        self._clean_tables()


class TestListeCartesGrisesParDate(CarteGriseViewsTestCase):
    """Tests de filtrage par date"""

    def test_filtre_par_date_debut_et_fin(self):
        """Test du filtre par plage de dates"""
        today = date.today()
        date_debut = (today - timedelta(days=70)).strftime('%Y-%m-%d')
        date_fin = (today - timedelta(days=20)).strftime('%Y-%m-%d')

        response = self.client.get('/cartes/', {
            'date_debut': date_debut,
            'date_fin': date_fin
        })

        self.assertEqual(response.status_code, 200)

        # Vérifier que seules les cartes dans la plage sont retournées
        cartes = response.context['cartes']
        self.assertEqual(len(cartes), 2)  # cg1 (30j) et cg2 (60j)

        plaques = [cg.numero_immatriculation for cg in cartes]
        self.assertIn("BE123AA", plaques)
        self.assertIn("CD456BB", plaques)
        self.assertNotIn("BE025AC", plaques)  # cg3 est à 90j


class TestListeCartesGrisesParNomPrenom(CarteGriseViewsTestCase):
    """Tests de recherche par nom/prénom"""

    def test_recherche_par_nom(self):
        """Test de recherche par nom de propriétaire"""
        response = self.client.get('/cartes/', {
            'search': 'MARTIN'
        })

        self.assertEqual(response.status_code, 200)
        cartes = response.context['cartes']
        self.assertEqual(len(cartes), 1)
        self.assertEqual(cartes[0].id_proprio.nom, "MARTIN")
        self.assertEqual(cartes[0].numero_immatriculation, "BE123AA")

    def test_recherche_par_prenom(self):
        """Test de recherche par prénom"""
        response = self.client.get('/cartes/', {
            'search': 'Marie'
        })

        self.assertEqual(response.status_code, 200)
        cartes = response.context['cartes']
        self.assertEqual(len(cartes), 1)
        self.assertEqual(cartes[0].id_proprio.prenoms, "Marie")
        self.assertEqual(cartes[0].numero_immatriculation, "CD456BB")

    def test_tri_alphabetique_nom(self):
        """Test du tri alphabétique par nom"""
        response = self.client.get('/cartes/', {
            'sort': 'proprietaire_nom'
        })

        self.assertEqual(response.status_code, 200)
        cartes = list(response.context['cartes'])

        # Vérifier l'ordre alphabétique: BERNARD < DUBOIS < MARTIN
        self.assertEqual(cartes[0].id_proprio.nom, "BERNARD")
        self.assertEqual(cartes[1].id_proprio.nom, "DUBOIS")
        self.assertEqual(cartes[2].id_proprio.nom, "MARTIN")


class TestListeCartesGrisesParPlaque(CarteGriseViewsTestCase):
    """Tests de filtrage par numéro de plaque"""

    def test_filtre_plaque_commence_par(self):
        """Test: plaque commençant par BE"""
        response = self.client.get('/cartes/', {
            'plaque_commence': 'BE'
        })

        self.assertEqual(response.status_code, 200)
        cartes = list(response.context['cartes'])

        self.assertEqual(len(cartes), 2)
        plaques = [cg.numero_immatriculation for cg in cartes]
        self.assertIn("BE123AA", plaques)
        self.assertIn("BE025AC", plaques)
        self.assertNotIn("CD456BB", plaques)

    def test_filtre_plaque_finit_par(self):
        """Test: plaque se terminant par AC"""
        response = self.client.get('/cartes/', {
            'plaque_finit': 'AC'
        })

        self.assertEqual(response.status_code, 200)
        cartes = list(response.context['cartes'])

        self.assertEqual(len(cartes), 1)
        self.assertEqual(cartes[0].numero_immatriculation, "BE025AC")

    def test_filtre_plaque_chiffres_entre_20_et_30(self):
        """Test: plaque dont les chiffres varient entre 20 et 30"""
        response = self.client.get('/cartes/', {
            'plaque_chiffres_min': '20',
            'plaque_chiffres_max': '30'
        })

        self.assertEqual(response.status_code, 200)
        cartes = list(response.context['cartes'])

        # BE025AC a 025 (25) qui est dans [20, 30]
        self.assertEqual(len(cartes), 1)
        self.assertEqual(cartes[0].numero_immatriculation, "BE025AC")

    def test_filtre_plaque_combine(self):
        """Test: combinaison de filtres (commence par + chiffres)"""
        response = self.client.get('/cartes/', {
            'plaque_commence': 'BE',
            'plaque_chiffres_min': '100',
            'plaque_chiffres_max': '200'
        })

        self.assertEqual(response.status_code, 200)
        cartes = list(response.context['cartes'])

        # BE123AA commence par BE et a 123 dans [100, 200]
        self.assertEqual(len(cartes), 1)
        self.assertEqual(cartes[0].numero_immatriculation, "BE123AA")


class TestStatistiquesMarques(CarteGriseViewsTestCase):
    """Tests de la page statistiques - marques"""

    def test_statistiques_marques_ordre_decroissant(self):
        """Test de la page statistiques avec tri des marques"""
        # Ajouter plus de véhicules Renault pour avoir un ordre
        vehicule4 = Vehicule.objects.create(
            num_serie="VF1CLIO5000003",
            id_modele=self.modele_clio,
            date_fabrication=date(2021, 5, 10),
            date_premiere_immatriculation=date(2021, 6, 1),
            emission_co2=100,
            id_classe_environnementale=self.classe_env,
            id_fabricant=self.fabricant1,
            id_permis=self.cat_permis_b
        )
        proprio4 = Proprietaire.objects.create(
            nom="PETIT",
            prenoms="Luc",
            adresse="4 rue de Lille 59000 Lille"
        )
        CarteGrise.objects.create(
            num="2024DD45678",
            numero_immatriculation="FG789DD",
            date_immatriculation=date.today(),
            id_proprio=proprio4,
            id_vehicule=vehicule4
        )

        response = self.client.get('/statistiques/')

        self.assertEqual(response.status_code, 200)
        stats_marques = response.context['stats_marques']

        # Vérifier que les marques sont triées par nombre décroissant
        self.assertTrue(len(stats_marques) >= 2)

        # Renault devrait avoir plus de véhicules (3) que Peugeot (1)
        renault_stat = next((m for m in stats_marques if m['marque'] == 'Renault'), None)
        peugeot_stat = next((m for m in stats_marques if m['marque'] == 'Peugeot'), None)

        self.assertIsNotNone(renault_stat)
        self.assertIsNotNone(peugeot_stat)
        self.assertGreater(renault_stat['count'], peugeot_stat['count'])

        # Vérifier l'ordre décroissant
        for i in range(len(stats_marques) - 1):
            self.assertGreaterEqual(
                stats_marques[i]['count'],
                stats_marques[i + 1]['count']
            )

    def test_statistiques_affichage_pourcentages(self):
        """Test que les pourcentages sont affichés"""
        response = self.client.get('/statistiques/')

        self.assertEqual(response.status_code, 200)
        stats_marques = response.context['stats_marques']

        # Vérifier que chaque marque a un pourcentage
        for marque in stats_marques:
            self.assertIn('percentage', marque)  # La clé est 'percentage' pas 'pourcentage'
            self.assertIsInstance(marque['percentage'], (int, float))
            self.assertGreaterEqual(marque['percentage'], 0)
            self.assertLessEqual(marque['percentage'], 100)


class TestVehiculesAnciensPolluants(CarteGriseViewsTestCase):
    """Tests de recherche de véhicules anciens et polluants"""

    def test_recherche_vehicules_anciens_plus_5_ans(self):
        """Test: véhicules de plus de 4 ans (contrainte BD: dates >= 2020)"""
        response = self.client.get('/statistiques/', {
            'annees_min': '4'
        })

        self.assertEqual(response.status_code, 200)
        vehicules = response.context['vehicules_anciens_polluants']

        # vehicule3 (2020) a plus de 4 ans
        # vehicule2 (2022) a moins de 4 ans
        # vehicule1 (2024) a moins de 4 ans
        self.assertGreaterEqual(len(vehicules), 1)

        # Vérifier que tous les véhicules ont plus de 4 ans
        for v in vehicules:
            self.assertGreaterEqual(v['age'], 4)

    def test_recherche_vehicules_emission_sup_100(self):
        """Test: véhicules avec émission CO2 > 100 g/km"""
        response = self.client.get('/statistiques/', {
            'emission_min': '100'
        })

        self.assertEqual(response.status_code, 200)
        vehicules = response.context['vehicules_anciens_polluants']

        # vehicule2 (110) et vehicule3 (130) ont > 100
        # vehicule1 (95) a < 100
        self.assertEqual(len(vehicules), 2)

        # Vérifier que tous ont émission >= 100
        for v in vehicules:
            self.assertGreaterEqual(v['emission_co2'], 100)

    def test_recherche_combine_age_et_emission(self):
        """Test: combinaison âge > 4 ans ET émission > 100 g/km"""
        response = self.client.get('/statistiques/', {
            'annees_min': '4',
            'emission_min': '100'
        })

        self.assertEqual(response.status_code, 200)
        vehicules = response.context['vehicules_anciens_polluants']

        # Seuls les véhicules qui ont PLUS de 4 ans ET émission > 100
        # vehicule3 (2020, 130) correspond
        # vehicule2 (2022, 110) a < 4 ans
        # vehicule1 (2024, 95) a < 4 ans et < 100
        self.assertGreaterEqual(len(vehicules), 1)

        # Vérifier que tous répondent aux deux critères
        for v in vehicules:
            self.assertGreaterEqual(v['age'], 4)
            self.assertGreaterEqual(v['emission_co2'], 100)


class TestNavigationGenerale(CarteGriseViewsTestCase):
    """Tests de navigation générale"""

    def test_acces_page_liste(self):
        """Test d'accès à la page liste"""
        response = self.client.get('/cartes/')

        self.assertEqual(response.status_code, 200)
        self.assertIn('cartes', response.context)

    def test_acces_page_statistiques(self):
        """Test d'accès à la page statistiques"""
        response = self.client.get('/statistiques/')

        self.assertEqual(response.status_code, 200)
        self.assertIn('stats_marques', response.context)
        self.assertIn('vehicules_anciens_polluants', response.context)

    def test_reinitialiser_filtres(self):
        """Test du bouton réinitialiser (retour à la page sans filtres)"""
        # D'abord avec des filtres
        response1 = self.client.get('/cartes/', {
            'search': 'MARTIN',
            'plaque_commence': 'BE'
        })
        self.assertEqual(response1.status_code, 200)

        # Puis sans filtres (réinitialisation)
        response2 = self.client.get('/cartes/')
        self.assertEqual(response2.status_code, 200)

        # Toutes les cartes doivent être affichées
        cartes = response2.context['cartes']
        self.assertEqual(len(cartes), 3)
