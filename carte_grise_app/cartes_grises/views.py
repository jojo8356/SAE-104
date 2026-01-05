from django.shortcuts import render, redirect, get_object_or_404
from django.db.models import Q, Count, Value, CharField
from django.db.models.functions import Concat
from django.contrib import messages
from datetime import datetime, timedelta

from .models import (
    CarteGrise, Vehicule, Proprietaire, Fabricant, Marque, Modele,
    CategorieModele, CategoriePermis, ClasseEnvironnementVehicule,
    ControleTechnique
)
from .utils import (
    generer_prochain_numero_carte_grise,
    generer_prochain_numero_immatriculation,
)


def index(request):
    """Page d'accueil avec statistiques"""
    context = {
        'total_cartes': CarteGrise.objects.count(),
        'total_vehicules': Vehicule.objects.count(),
        'total_proprietaires': Proprietaire.objects.count(),
        'total_controles': ControleTechnique.objects.count(),
    }
    return render(request, 'cartes_grises/index.html', context)


def liste_cartes_grises(request):
    """Liste toutes les cartes grises avec filtres"""
    cartes = CarteGrise.objects.select_related(
        'id_proprio', 'id_vehicule', 'id_vehicule__id_modele',
        'id_vehicule__id_modele__id_marque', 'id_vehicule__id_fabricant',
        'id_vehicule__id_classe_environnementale', 'id_vehicule__id_permis'
    ).all()

    # Filtres basiques
    search = request.GET.get('search', '')
    date_debut = request.GET.get('date_debut', '')
    date_fin = request.GET.get('date_fin', '')

    # Filtres avancés pour plaque d'immatriculation
    plaque_commence = request.GET.get('plaque_commence', '')
    plaque_finit = request.GET.get('plaque_finit', '')
    plaque_chiffres_min = request.GET.get('plaque_chiffres_min', '')
    plaque_chiffres_max = request.GET.get('plaque_chiffres_max', '')

    if search:
        # Annoter avec nom complet du propriétaire et du véhicule pour la recherche
        cartes = cartes.annotate(
            proprietaire_complet=Concat(
                'id_proprio__nom', Value(' '),
                'id_proprio__prenoms',
                output_field=CharField()
            ),
            vehicule_complet=Concat(
                'id_vehicule__id_modele__id_marque__nom', Value(' '),
                'id_vehicule__id_modele__nom',
                output_field=CharField()
            )
        )

        cartes = cartes.filter(
            # Carte grise
            Q(num__icontains=search) |
            Q(numero_immatriculation__icontains=search) |
            Q(date_immatriculation__icontains=search) |
            # Propriétaire - recherche dans nom, prénom ou nom complet
            Q(id_proprio__nom__icontains=search) |
            Q(id_proprio__prenoms__icontains=search) |
            Q(proprietaire_complet__icontains=search) |
            Q(id_proprio__adresse__icontains=search) |
            # Véhicule - Marque et Modèle
            Q(id_vehicule__id_modele__id_marque__nom__icontains=search) |
            Q(id_vehicule__id_modele__nom__icontains=search) |
            Q(vehicule_complet__icontains=search) |
            # Véhicule - Fabricant
            Q(id_vehicule__id_fabricant__nom__icontains=search) |
            # Véhicule - Classe environnementale et Permis
            Q(id_vehicule__id_classe_environnementale__classe__icontains=search) |
            Q(id_vehicule__id_permis__permis__icontains=search)
        )

    # Filtres de dates
    if date_debut:
        cartes = cartes.filter(date_immatriculation__gte=date_debut)

    if date_fin:
        cartes = cartes.filter(date_immatriculation__lte=date_fin)

    # Filtres avancés de plaque d'immatriculation
    if plaque_commence:
        cartes = cartes.filter(numero_immatriculation__istartswith=plaque_commence.upper())

    if plaque_finit:
        cartes = cartes.filter(numero_immatriculation__iendswith=plaque_finit.upper())

    # Filtre pour les chiffres de la plaque (format: LLNNNLL, extraire les 3 chiffres du milieu)
    if plaque_chiffres_min or plaque_chiffres_max:
        # Filtrer en Python car extraction des chiffres nécessite regex complexe
        filtered_cartes = []
        for carte in cartes:
            # Extraire les chiffres du milieu (positions 2-4 dans LLNNNLL)
            if len(carte.numero_immatriculation) == 7:
                try:
                    chiffres = int(carte.numero_immatriculation[2:5])
                    min_ok = not plaque_chiffres_min or chiffres >= int(plaque_chiffres_min)
                    max_ok = not plaque_chiffres_max or chiffres <= int(plaque_chiffres_max)
                    if min_ok and max_ok:
                        filtered_cartes.append(carte.num)
                except (ValueError, IndexError):
                    pass

        if filtered_cartes:
            cartes = cartes.filter(num__in=filtered_cartes)
        else:
            cartes = cartes.none()

    # Tri
    sort_by = request.GET.get('sort', '-date_immatriculation')

    # Support tri par nom/prénom alphabétique
    if sort_by == 'proprietaire_nom':
        cartes = cartes.order_by('id_proprio__nom', 'id_proprio__prenoms')
    elif sort_by == '-proprietaire_nom':
        cartes = cartes.order_by('-id_proprio__nom', '-id_proprio__prenoms')
    else:
        cartes = cartes.order_by(sort_by)

    context = {
        'cartes': cartes,
        'search': search,
        'date_debut': date_debut,
        'date_fin': date_fin,
        'plaque_commence': plaque_commence,
        'plaque_finit': plaque_finit,
        'plaque_chiffres_min': plaque_chiffres_min,
        'plaque_chiffres_max': plaque_chiffres_max,
        'sort_by': sort_by,
    }
    return render(request, 'cartes_grises/liste.html', context)


def detail_carte_grise(request, num):
    """Détail d'une carte grise"""
    carte = get_object_or_404(
        CarteGrise.objects.select_related(
            'id_proprio', 'id_vehicule', 'id_vehicule__id_modele',
            'id_vehicule__id_modele__id_marque', 'id_vehicule__id_fabricant',
            'id_vehicule__id_classe_environnementale', 'id_vehicule__id_permis'
        ),
        num=num
    )

    # Récupérer les contrôles techniques
    controles = ControleTechnique.objects.filter(num=carte).order_by('-date_controle')

    context = {
        'carte': carte,
        'controles': controles,
    }
    return render(request, 'cartes_grises/detail.html', context)


def ajouter_carte_grise(request):
    """Formulaire d'ajout d'une carte grise"""
    if request.method == 'POST':
        try:
            # Récupération des données du formulaire
            id_proprio = request.POST.get('id_proprio')
            id_vehicule = request.POST.get('id_vehicule')
            conducteur_est_proprietaire = request.POST.get('conducteur_est_proprietaire') == 'on'

            # Génération automatique des numéros
            num_carte = generer_prochain_numero_carte_grise()
            num_immat = generer_prochain_numero_immatriculation()
            date_immat = datetime.now().date()

            # Création de la carte grise
            carte = CarteGrise.objects.create(
                num=num_carte,
                numero_immatriculation=num_immat,
                date_immatriculation=date_immat,
                conducteur_est_proprietaire=conducteur_est_proprietaire,
                id_proprio_id=id_proprio,
                id_vehicule_id=id_vehicule,
            )

            messages.success(request, f'Carte grise {carte.num} créée avec succès!')
            return redirect('detail_carte_grise', num=carte.num)

        except Exception as e:
            messages.error(request, f'Erreur lors de la création: {str(e)}')

    # Données pour le formulaire
    context = {
        'proprietaires': Proprietaire.objects.all().order_by('nom', 'prenoms'),
        'vehicules': Vehicule.objects.select_related(
            'id_modele', 'id_modele__id_marque'
        ).all(),
        'prochain_num_carte': generer_prochain_numero_carte_grise(),
        'prochain_num_immat': generer_prochain_numero_immatriculation(),
    }
    return render(request, 'cartes_grises/ajouter.html', context)


def modifier_carte_grise(request, num):
    """Formulaire de modification d'une carte grise"""
    carte = get_object_or_404(CarteGrise, num=num)

    if request.method == 'POST':
        try:
            carte.conducteur_est_proprietaire = request.POST.get('conducteur_est_proprietaire') == 'on'
            carte.id_proprio_id = request.POST.get('id_proprio')
            carte.save()

            messages.success(request, f'Carte grise {carte.num} modifiée avec succès!')
            return redirect('detail_carte_grise', num=carte.num)

        except Exception as e:
            messages.error(request, f'Erreur lors de la modification: {str(e)}')

    context = {
        'carte': carte,
        'proprietaires': Proprietaire.objects.all().order_by('nom', 'prenoms'),
    }
    return render(request, 'cartes_grises/modifier.html', context)


def supprimer_carte_grise(request, num):
    """Suppression d'une carte grise"""
    carte = get_object_or_404(CarteGrise, num=num)

    if request.method == 'POST':
        carte.delete()
        messages.success(request, f'Carte grise {num} supprimée avec succès!')
        return redirect('liste_cartes_grises')

    context = {'carte': carte}
    return render(request, 'cartes_grises/supprimer.html', context)


def statistiques(request):
    """Page de statistiques"""
    from django.db.models import Count, Avg
    from datetime import date

    # Totaux
    total_cartes = CarteGrise.objects.count()
    total_vehicules = Vehicule.objects.count()
    total_proprietaires = Proprietaire.objects.count()
    total_controles = ControleTechnique.objects.count()

    # Statistiques par marque
    stats_marques_raw = Vehicule.objects.values(
        'id_modele__id_marque__nom'
    ).annotate(
        count=Count('id_vehicule')
    ).order_by('-count')

    stats_marques = []
    for stat in stats_marques_raw:
        marque = stat['id_modele__id_marque__nom']
        count = stat['count']
        percentage = (count / total_vehicules * 100) if total_vehicules > 0 else 0
        stats_marques.append({
            'marque': marque,
            'count': count,
            'percentage': round(percentage, 1)
        })

    # Statistiques par année d'immatriculation
    stats_annees_raw = CarteGrise.objects.extra(
        select={'annee': "YEAR(date_immatriculation)"}
    ).values('annee').annotate(
        count=Count('num')
    ).order_by('annee')

    max_count = max([s['count'] for s in stats_annees_raw]) if stats_annees_raw else 1
    stats_annees = []
    for stat in stats_annees_raw:
        percentage = (stat['count'] / max_count * 100) if max_count > 0 else 0
        stats_annees.append({
            'annee': stat['annee'],
            'count': stat['count'],
            'percentage': round(percentage, 1)
        })

    # Statistiques par classe environnementale (Crit'Air 0-2)
    stats_pollution_raw = Vehicule.objects.filter(
        id_classe_environnementale__classe__in=['0', '1', '2']
    ).values(
        'id_classe_environnementale__classe'
    ).annotate(
        count=Count('id_vehicule')
    ).order_by('id_classe_environnementale__classe')

    stats_pollution = []
    for stat in stats_pollution_raw:
        classe = stat['id_classe_environnementale__classe']
        count = stat['count']
        percentage = (count / total_vehicules * 100) if total_vehicules > 0 else 0
        stats_pollution.append({
            'classe': classe,
            'count': count,
            'percentage': round(percentage, 1)
        })

    # Statistiques par catégorie de permis
    stats_permis_raw = Vehicule.objects.values(
        'id_permis__permis'
    ).annotate(
        count=Count('id_vehicule')
    ).order_by('id_permis__permis')

    stats_permis = []
    for stat in stats_permis_raw:
        permis = stat['id_permis__permis']
        count = stat['count']
        percentage = (count / total_vehicules * 100) if total_vehicules > 0 else 0
        stats_permis.append({
            'permis': permis,
            'count': count,
            'percentage': round(percentage, 1)
        })

    # e. Requête avancée: Véhicules > X années + émission CO2 > Y
    annees_min = request.GET.get('annees_min', '')
    emission_min = request.GET.get('emission_min', '')

    vehicules_anciens_polluants = []
    if annees_min or emission_min:
        vehicules_query = Vehicule.objects.select_related(
            'id_modele__id_marque', 'id_fabricant'
        ).all()

        # Filtrer par âge
        if annees_min:
            try:
                annee_limite = date.today().year - int(annees_min)
                vehicules_query = vehicules_query.extra(
                    where=["YEAR(date_fabrication) <= %s"],
                    params=[annee_limite]
                )
            except ValueError:
                pass

        # Filtrer par émission CO2
        if emission_min:
            try:
                vehicules_query = vehicules_query.filter(emission_co2__gte=int(emission_min))
            except ValueError:
                pass

        for vehicule in vehicules_query:
            # Calculer l'âge
            age = date.today().year - vehicule.date_fabrication.year if vehicule.date_fabrication else 0
            vehicules_anciens_polluants.append({
                'marque': vehicule.id_modele.id_marque.nom if vehicule.id_modele else 'Inconnu',
                'modele': vehicule.id_modele.nom if vehicule.id_modele else 'Inconnu',
                'num_serie': vehicule.num_serie,
                'age': age,
                'emission_co2': vehicule.emission_co2,
                'date_fabrication': vehicule.date_fabrication,
            })

    context = {
        'total_cartes': total_cartes,
        'total_vehicules': total_vehicules,
        'total_proprietaires': total_proprietaires,
        'total_controles': total_controles,
        'stats_marques': stats_marques,
        'stats_annees': stats_annees,
        'stats_pollution': stats_pollution,
        'stats_permis': stats_permis,
        # Requête avancée
        'annees_min': annees_min,
        'emission_min': emission_min,
        'vehicules_anciens_polluants': vehicules_anciens_polluants,
        'count_anciens_polluants': len(vehicules_anciens_polluants),
    }
    return render(request, 'cartes_grises/statistiques.html', context)
