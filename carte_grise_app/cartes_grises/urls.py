from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('cartes/', views.liste_cartes_grises, name='liste_cartes_grises'),
    path('cartes/ajouter/', views.ajouter_carte_grise, name='ajouter_carte_grise'),
    path('cartes/<str:num>/', views.detail_carte_grise, name='detail_carte_grise'),
    path('cartes/<str:num>/modifier/', views.modifier_carte_grise, name='modifier_carte_grise'),
    path('cartes/<str:num>/supprimer/', views.supprimer_carte_grise, name='supprimer_carte_grise'),
    path('statistiques/', views.statistiques, name='statistiques'),
]
