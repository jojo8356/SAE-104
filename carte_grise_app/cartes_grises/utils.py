"""
Fonctions utilitaires pour la génération de numéros
"""
from datetime import datetime
from .models import CarteGrise, Vehicule


def generer_numero_serie(vehicule):
    """
    Génère le numéro de série d'un véhicule dynamiquement
    Format: NumFabricant + Année + Mois + Séquence(6 chiffres)
    Exemple: FAB0012024030000001

    Args:
        vehicule: Instance du modèle Vehicule

    Returns:
        str: Numéro de série formaté
    """
    num_fabricant = vehicule.id_fabricant.num_fabricant
    annee = vehicule.date_fabrication.year
    mois = str(vehicule.date_fabrication.month).zfill(2)

    # Compter le nombre de véhicules du même fabricant, même année/mois
    # ayant un id_vehicule <= au véhicule actuel
    count = Vehicule.objects.filter(
        id_fabricant=vehicule.id_fabricant,
        date_fabrication__year=annee,
        date_fabrication__month=vehicule.date_fabrication.month,
        id_vehicule__lte=vehicule.id_vehicule
    ).count()

    sequence = str(count).zfill(6)

    return f"{num_fabricant}{annee}{mois}{sequence}"


def generer_prochain_numero_carte_grise():
    """
    Génère le prochain numéro de carte grise
    Format: Année(4) + Lettres(2) + Chiffres(5)
    Exemple: 2026AA00001 -> 2026AA00002
             2026AA99999 -> 2026AB00000

    Returns:
        str: Prochain numéro de carte grise
    """
    annee_actuelle = datetime.now().year

    # Récupérer le dernier numéro de carte grise de l'année en cours
    dernier = CarteGrise.objects.filter(
        num__startswith=str(annee_actuelle)
    ).order_by('-num').first()

    if not dernier:
        # Premier numéro de l'année
        return f"{annee_actuelle}AA00001"

    # Extraire les composants du dernier numéro
    num_actuel = dernier.num
    annee = int(num_actuel[0:4])
    lettres = num_actuel[4:6]
    chiffres = int(num_actuel[6:11])

    # Incrémenter
    chiffres += 1

    if chiffres > 99999:
        # Reset chiffres et incrémenter les lettres
        chiffres = 0
        lettres = _incrementer_lettres(lettres)

    return f"{annee}{lettres}{str(chiffres).zfill(5)}"


def generer_prochain_numero_immatriculation():
    """
    Génère le prochain numéro d'immatriculation
    Format: Lettres(2) + Chiffres(3) + Lettres(2)
    Exemple: AB078ZA -> AB078ZB
             AB078ZZ -> AB079AA
             AB999ZZ -> AC010AA

    Returns:
        str: Prochain numéro d'immatriculation
    """
    # Récupérer le dernier numéro d'immatriculation
    dernier = CarteGrise.objects.order_by('-numero_immatriculation').first()

    if not dernier:
        # Premier numéro
        return "AA010AA"

    # Extraire les composants
    num_actuel = dernier.numero_immatriculation
    lettres_gauche = num_actuel[0:2]
    chiffres = int(num_actuel[2:5])
    lettres_droite = num_actuel[5:7]

    # Incrémenter les lettres de droite
    lettres_droite = _incrementer_lettres(lettres_droite)

    if lettres_droite == "AA":
        # Reset lettres droite, incrémenter chiffres
        chiffres += 1

        if chiffres > 999:
            # Reset chiffres à 010, incrémenter lettres gauche
            chiffres = 10
            lettres_gauche = _incrementer_lettres(lettres_gauche)

            if lettres_gauche == "AA":
                # Limite atteinte
                raise ValueError("Limite maximale d'immatriculation atteinte (ZZ999ZZ)")

    # S'assurer que les chiffres sont >= 10
    if chiffres < 10:
        chiffres = 10

    return f"{lettres_gauche}{str(chiffres).zfill(3)}{lettres_droite}"


def _incrementer_lettres(lettres):
    """
    Incrémente une paire de lettres (AA -> AB -> ... -> ZZ -> AA)

    Args:
        lettres: Chaîne de 2 lettres (ex: "AB")

    Returns:
        str: Lettres incrémentées
    """
    lettre1 = ord(lettres[0])
    lettre2 = ord(lettres[1])

    lettre2 += 1

    if lettre2 > ord('Z'):
        lettre2 = ord('A')
        lettre1 += 1

        if lettre1 > ord('Z'):
            lettre1 = ord('A')

    return chr(lettre1) + chr(lettre2)


def valider_format_numero_carte_grise(numero):
    """
    Valide le format d'un numéro de carte grise
    Format attendu: YYYYLLNNNNN (Année + 2 Lettres + 5 Chiffres)

    Args:
        numero: Numéro de carte grise à valider

    Returns:
        bool: True si valide, False sinon
    """
    import re
    pattern = r'^[0-9]{4}[A-Z]{2}[0-9]{5}$'
    return bool(re.match(pattern, numero))


def valider_format_immatriculation(numero):
    """
    Valide le format d'un numéro d'immatriculation
    Format attendu: LLNNNLL (2 Lettres + 3 Chiffres + 2 Lettres)

    Args:
        numero: Numéro d'immatriculation à valider

    Returns:
        bool: True si valide, False sinon
    """
    import re
    pattern = r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$'
    return bool(re.match(pattern, numero))


# Fonction de récupération du dernier numéro (pour les requêtes SQL demandées)
def recuperer_dernier_numero_carte_grise():
    """
    Récupère le dernier numéro de carte grise généré

    Returns:
        str: Dernier numéro ou None si aucune carte grise
    """
    dernier = CarteGrise.objects.order_by('-num').first()
    return dernier.num if dernier else None


def recuperer_dernier_numero_immatriculation():
    """
    Récupère le dernier numéro d'immatriculation généré

    Returns:
        str: Dernier numéro ou None si aucune carte grise
    """
    dernier = CarteGrise.objects.order_by('-numero_immatriculation').first()
    return dernier.numero_immatriculation if dernier else None
