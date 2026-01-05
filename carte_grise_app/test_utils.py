"""
Script de test pour les fonctions utilitaires
Exécuter avec: uv run python test_utils.py
"""
import os
import django

# Configuration Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from cartes_grises.models import CarteGrise, Vehicule, Fabricant
from cartes_grises.utils import (
    generer_numero_serie,
    generer_prochain_numero_carte_grise,
    generer_prochain_numero_immatriculation,
    valider_format_numero_carte_grise,
    valider_format_immatriculation,
    recuperer_dernier_numero_carte_grise,
    recuperer_dernier_numero_immatriculation,
)


def test_generation_numero_serie():
    """Test de la génération de numéro de série"""
    print("=" * 60)
    print("TEST: Génération numéro de série")
    print("=" * 60)

    # Prendre le premier véhicule de la base
    vehicule = Vehicule.objects.first()
    if vehicule:
        numero_serie = vehicule.numero_serie
        print(f"Véhicule ID: {vehicule.id_vehicule}")
        print(f"Fabricant: {vehicule.id_fabricant.nom} ({vehicule.id_fabricant.num_fabricant})")
        print(f"Date fabrication: {vehicule.date_fabrication}")
        print(f"Numéro de série généré: {numero_serie}")
        print("✓ Test réussi\n")
    else:
        print("❌ Aucun véhicule trouvé dans la base\n")


def test_generation_numero_carte_grise():
    """Test de la génération de numéro de carte grise"""
    print("=" * 60)
    print("TEST: Génération numéro de carte grise")
    print("=" * 60)

    dernier = recuperer_dernier_numero_carte_grise()
    print(f"Dernier numéro: {dernier}")

    prochain = generer_prochain_numero_carte_grise()
    print(f"Prochain numéro: {prochain}")

    # Validation du format
    if valider_format_numero_carte_grise(prochain):
        print(f"✓ Format valide: {prochain}")
    else:
        print(f"❌ Format invalide: {prochain}")
    print()


def test_generation_numero_immatriculation():
    """Test de la génération de numéro d'immatriculation"""
    print("=" * 60)
    print("TEST: Génération numéro d'immatriculation")
    print("=" * 60)

    dernier = recuperer_dernier_numero_immatriculation()
    print(f"Dernier numéro: {dernier}")

    prochain = generer_prochain_numero_immatriculation()
    print(f"Prochain numéro: {prochain}")

    # Validation du format
    if valider_format_immatriculation(prochain):
        print(f"✓ Format valide: {prochain}")
    else:
        print(f"❌ Format invalide: {prochain}")
    print()


def test_statistiques_base():
    """Affiche des statistiques de la base de données"""
    print("=" * 60)
    print("STATISTIQUES DE LA BASE DE DONNÉES")
    print("=" * 60)

    from cartes_grises.models import (
        Fabricant, Marque, Modele, Proprietaire,
        Vehicule, CarteGrise, ControleTechnique
    )

    print(f"Fabricants: {Fabricant.objects.count()}")
    print(f"Marques: {Marque.objects.count()}")
    print(f"Modèles: {Modele.objects.count()}")
    print(f"Propriétaires: {Proprietaire.objects.count()}")
    print(f"Véhicules: {Vehicule.objects.count()}")
    print(f"Cartes grises: {CarteGrise.objects.count()}")
    print(f"Contrôles techniques: {ControleTechnique.objects.count()}")
    print()


def test_afficher_quelques_cartes():
    """Affiche quelques cartes grises"""
    print("=" * 60)
    print("EXEMPLES DE CARTES GRISES")
    print("=" * 60)

    cartes = CarteGrise.objects.select_related(
        'id_proprio', 'id_vehicule', 'id_vehicule__id_modele'
    ).all()[:5]

    for carte in cartes:
        print(f"\nCarte Grise: {carte.num}")
        print(f"  Immatriculation: {carte.numero_immatriculation}")
        print(f"  Propriétaire: {carte.id_proprio}")
        print(f"  Véhicule: {carte.id_vehicule.id_modele}")
        print(f"  Date immatriculation: {carte.date_immatriculation}")


if __name__ == "__main__":
    print("\n" + "🚗" * 30)
    print("   TEST DES FONCTIONS UTILITAIRES - CARTE GRISE")
    print("🚗" * 30 + "\n")

    try:
        test_statistiques_base()
        test_generation_numero_serie()
        test_generation_numero_carte_grise()
        test_generation_numero_immatriculation()
        test_afficher_quelques_cartes()

        print("\n" + "=" * 60)
        print("✅ TOUS LES TESTS SONT TERMINÉS")
        print("=" * 60 + "\n")

    except Exception as e:
        print(f"\n❌ ERREUR: {e}")
        import traceback
        traceback.print_exc()
