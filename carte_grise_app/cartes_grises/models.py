from django.db import models


class Fabricant(models.Model):
    """Fabricant de véhicules"""
    id_fabricant = models.AutoField(primary_key=True)
    num_fabricant = models.CharField(max_length=10, unique=True)
    nom = models.CharField(max_length=100)

    class Meta:
        db_table = 'Fabricant'
        managed = False  # Ne pas laisser Django gérer cette table

    def __str__(self):
        return self.nom


class Marque(models.Model):
    """Marque de véhicules"""
    id_marque = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100)
    id_fabricant = models.ForeignKey(
        Fabricant,
        on_delete=models.RESTRICT,
        db_column='id_fabricant'
    )

    class Meta:
        db_table = 'Marque'
        managed = False

    def __str__(self):
        return self.nom


class CategorieModele(models.Model):
    """Catégories de véhicules (deux_roues, automobile, camion_leger)"""
    id_categorie_modele = models.AutoField(primary_key=True)
    categorie = models.CharField(max_length=50, unique=True)

    class Meta:
        db_table = 'CategorieModele'
        managed = False

    def __str__(self):
        return self.categorie


class Modele(models.Model):
    """Modèle de véhicule"""
    id_modele = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100)
    id_marque = models.ForeignKey(
        Marque,
        on_delete=models.RESTRICT,
        db_column='id_marque'
    )
    id_categorie_modele = models.ForeignKey(
        CategorieModele,
        on_delete=models.RESTRICT,
        db_column='id_categorie_modele'
    )

    class Meta:
        db_table = 'Modele'
        managed = False

    def __str__(self):
        return f"{self.id_marque.nom} {self.nom}"


class CategoriePermis(models.Model):
    """Catégories de permis (A1, A2, A, B, C)"""
    id_permis = models.AutoField(primary_key=True)
    permis = models.CharField(max_length=10, unique=True)

    class Meta:
        db_table = 'CategoriePermis'
        managed = False

    def __str__(self):
        return self.permis


class ClasseEnvironnementVehicule(models.Model):
    """Classes environnementales Crit'Air (0, 1, 2, 3, 4, 5)"""
    id_classe_environnementale = models.AutoField(primary_key=True)
    classe = models.CharField(max_length=20, unique=True)

    class Meta:
        db_table = 'ClasseEnvironnementVehicule'
        managed = False

    def __str__(self):
        return f"Crit'Air {self.classe}"


class Proprietaire(models.Model):
    """Propriétaire de véhicule"""
    id_proprio = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100)
    prenoms = models.CharField(max_length=200)
    adresse = models.CharField(max_length=255)

    class Meta:
        db_table = 'Proprietaire'
        managed = False

    def __str__(self):
        return f"{self.nom} {self.prenoms}"


class Vehicule(models.Model):
    """Véhicule"""
    id_vehicule = models.AutoField(primary_key=True)
    num_serie = models.CharField(max_length=20, unique=True)  # E: Numéro de série
    date_fabrication = models.DateField()
    date_premiere_immatriculation = models.DateField()
    type_vehicule = models.CharField(max_length=10, null=True, blank=True)  # D2: VP, CTTE, etc.
    cylindree = models.PositiveIntegerField(null=True, blank=True)
    puissance_chevaux = models.PositiveIntegerField(null=True, blank=True)
    puissance_cv = models.PositiveIntegerField(null=True, blank=True)
    poids_vide = models.PositiveIntegerField(null=True, blank=True)
    poids_max_charge = models.PositiveIntegerField(null=True, blank=True)
    places_assises = models.PositiveSmallIntegerField(null=True, blank=True)
    places_debout = models.PositiveSmallIntegerField(null=True, blank=True)
    nv_sonore = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    vitesse_moteur_tr_mn = models.PositiveIntegerField(null=True, blank=True)  # U2: tr/mn
    vitesse_max = models.PositiveIntegerField(null=True, blank=True)  # Vitesse max en km/h
    emission_co2 = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)

    id_modele = models.ForeignKey(
        Modele,
        on_delete=models.RESTRICT,
        db_column='id_modele'
    )
    id_fabricant = models.ForeignKey(
        Fabricant,
        on_delete=models.RESTRICT,
        db_column='id_fabricant'
    )
    id_classe_environnementale = models.ForeignKey(
        ClasseEnvironnementVehicule,
        on_delete=models.RESTRICT,
        db_column='id_classe_environnementale'
    )
    id_permis = models.ForeignKey(
        CategoriePermis,
        on_delete=models.RESTRICT,
        db_column='id_permis'
    )

    class Meta:
        db_table = 'Vehicule'
        managed = False

    def __str__(self):
        return f"{self.id_modele} ({self.date_fabrication.year}) - {self.num_serie}"


class CarteGrise(models.Model):
    """Carte Grise"""
    num = models.CharField(max_length=20, primary_key=True)
    numero_immatriculation = models.CharField(max_length=15, unique=True)
    date_immatriculation = models.DateField()
    date_fin_validite = models.DateField(null=True, blank=True)
    conducteur_est_proprietaire = models.BooleanField(default=True)

    id_proprio = models.ForeignKey(
        Proprietaire,
        on_delete=models.RESTRICT,
        db_column='id_proprio'
    )
    id_vehicule = models.ForeignKey(
        Vehicule,
        on_delete=models.RESTRICT,
        db_column='id_vehicule'
    )

    class Meta:
        db_table = 'Carte_Grise'
        managed = False

    def __str__(self):
        return f"{self.num} - {self.numero_immatriculation}"


class ControleTechnique(models.Model):
    """Contrôle Technique"""
    id_controle = models.AutoField(primary_key=True)
    date_controle = models.DateField()
    num = models.ForeignKey(
        CarteGrise,
        on_delete=models.CASCADE,
        db_column='num'
    )

    class Meta:
        db_table = 'Controle_Technique'
        managed = False

    def __str__(self):
        return f"CT du {self.date_controle} - {self.num}"
