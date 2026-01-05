-- ============================================
-- SAE 1.04 : Script de test de conformité
-- Vérifie TOUTES les colonnes selon le cahier des charges
-- ============================================

USE carte_grise_db;

SET @num_carte = '2020AA00001';  -- Carte grise à tester

SELECT
    '============================================' AS '';
SELECT 'TEST DE CONFORMITÉ - CARTE GRISE' AS '';
SELECT 'SAE 1.04 - Vérification de toutes les colonnes' AS '';
SELECT '============================================' AS '';

-- ============================================
-- SECTION 1: Informations Carte Grise
-- ============================================
SELECT '' AS '';
SELECT '=== INFORMATIONS CARTE GRISE ===' AS '';
SELECT '' AS '';

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

UNION ALL

SELECT
    'A - Immatriculation' AS 'Champ',
    cg.numero_immatriculation AS 'Valeur',
    CASE
        WHEN cg.numero_immatriculation REGEXP '^[A-Z]{2}[0-9]{3}[A-Z]{2}$'
        THEN '✓ Format valide (LLNNNLL)'
        ELSE '✗ Format invalide'
    END AS 'Validation'
FROM Carte_Grise cg
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'I - Date immatriculation' AS 'Champ',
    DATE_FORMAT(cg.date_immatriculation, '%d/%m/%Y') AS 'Valeur',
    CASE
        WHEN cg.date_immatriculation BETWEEN '2020-01-01' AND '2026-12-31'
        THEN '✓ Date valide (2020-2026)'
        ELSE '✗ Date hors plage'
    END AS 'Validation'
FROM Carte_Grise cg
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'H - Date fin validité' AS 'Champ',
    IFNULL(DATE_FORMAT(cg.date_fin_validite, '%d/%m/%Y'), 'Indéterminée') AS 'Valeur',
    '✓ Optionnel' AS 'Validation'
FROM Carte_Grise cg
WHERE cg.num = @num_carte;

-- ============================================
-- SECTION 2: Informations Propriétaire
-- ============================================
SELECT '' AS '';
SELECT '=== INFORMATIONS PROPRIÉTAIRE ===' AS '';
SELECT '' AS '';

SELECT
    'C1 - Nom propriétaire' AS 'Champ',
    p.nom AS 'Valeur',
    CASE
        WHEN p.nom IS NOT NULL AND LENGTH(p.nom) > 0
        THEN '✓ Présent'
        ELSE '✗ Manquant'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Proprietaire p ON cg.id_proprio = p.id_proprio
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'C2 - Prénoms propriétaire' AS 'Champ',
    p.prenoms AS 'Valeur',
    CASE
        WHEN p.prenoms IS NOT NULL AND LENGTH(p.prenoms) > 0
        THEN '✓ Présent'
        ELSE '✗ Manquant'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Proprietaire p ON cg.id_proprio = p.id_proprio
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'C3 - Adresse propriétaire' AS 'Champ',
    p.adresse AS 'Valeur',
    CASE
        WHEN p.adresse IS NOT NULL AND LENGTH(p.adresse) > 0
        THEN '✓ Présent'
        ELSE '✗ Manquant'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Proprietaire p ON cg.id_proprio = p.id_proprio
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'C4 - Conducteur = Propriétaire' AS 'Champ',
    CASE WHEN cg.conducteur_est_proprietaire THEN 'OUI' ELSE 'NON' END AS 'Valeur',
    '✓ Présent' AS 'Validation'
FROM Carte_Grise cg
WHERE cg.num = @num_carte;

-- ============================================
-- SECTION 3: Informations Véhicule
-- ============================================
SELECT '' AS '';
SELECT '=== INFORMATIONS VÉHICULE ===' AS '';
SELECT '' AS '';

SELECT
    'D1 - Marque' AS 'Champ',
    m.nom AS 'Valeur',
    CASE
        WHEN m.nom IS NOT NULL
        THEN '✓ Présent'
        ELSE '✗ Manquant'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
JOIN Modele mo ON v.id_modele = mo.id_modele
JOIN Marque m ON mo.id_marque = m.id_marque
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'D2 - Type véhicule' AS 'Champ',
    v.type_vehicule AS 'Valeur',
    CASE
        WHEN v.type_vehicule IN ('VP', 'MTL', 'CTTE')
        THEN '✓ Valeur valide'
        ELSE '✗ Valeur invalide'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'D2.1 - Modèle' AS 'Champ',
    mo.nom AS 'Valeur',
    CASE
        WHEN mo.nom IS NOT NULL
        THEN '✓ Présent'
        ELSE '✗ Manquant'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
JOIN Modele mo ON v.id_modele = mo.id_modele
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'E - Numéro de série' AS 'Champ',
    v.num_serie AS 'Valeur',
    CASE
        WHEN v.num_serie REGEXP '^[A-Z0-9]{6}[0-9]{6}[0-9]{6}$'
        THEN '✓ Format valide (NumFab+YYYYMM+6chiffres)'
        ELSE '⚠ Vérifié manuellement'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'B - Date fabrication' AS 'Champ',
    DATE_FORMAT(v.date_fabrication, '%d/%m/%Y') AS 'Valeur',
    CASE
        WHEN v.date_fabrication BETWEEN '2020-01-01' AND CURDATE()
        THEN '✓ Date valide (2020 à aujourd\'hui)'
        ELSE '✗ Date invalide'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'B - Première immatriculation' AS 'Champ',
    DATE_FORMAT(v.date_premiere_immatriculation, '%d/%m/%Y') AS 'Valeur',
    CASE
        WHEN v.date_premiere_immatriculation >= v.date_fabrication
        THEN '✓ Date cohérente (≥ fabrication)'
        ELSE '✗ Date incohérente'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte;

-- ============================================
-- SECTION 4: Caractéristiques Techniques
-- ============================================
SELECT '' AS '';
SELECT '=== CARACTÉRISTIQUES TECHNIQUES ===' AS '';
SELECT '' AS '';

SELECT
    'P1 - Cylindrée (cm³)' AS 'Champ',
    CONCAT(v.cylindree, ' cm³') AS 'Valeur',
    CASE
        WHEN v.cylindree > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'P2 - Puissance (chevaux)' AS 'Champ',
    CONCAT(v.puissance_chevaux, ' ch') AS 'Valeur',
    CASE
        WHEN v.puissance_chevaux > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'P3 - Puissance admin. (CV)' AS 'Champ',
    CONCAT(v.puissance_cv, ' CV') AS 'Valeur',
    CASE
        WHEN v.puissance_cv > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'F1 - Poids vide (kg)' AS 'Champ',
    CONCAT(v.poids_vide, ' kg') AS 'Valeur',
    CASE
        WHEN v.poids_vide > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'F2 - Poids max chargé (kg)' AS 'Champ',
    CONCAT(v.poids_max_charge, ' kg') AS 'Valeur',
    CASE
        WHEN v.poids_max_charge >= v.poids_vide
        THEN '✓ Cohérent (≥ poids vide)'
        ELSE '✗ Incohérent'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'S1 - Places assises' AS 'Champ',
    CAST(v.places_assises AS CHAR) AS 'Valeur',
    CASE
        WHEN v.places_assises > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'S2 - Places debout' AS 'Champ',
    CAST(v.places_debout AS CHAR) AS 'Valeur',
    CASE
        WHEN v.places_debout >= 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'U1 - Niveau sonore (dB)' AS 'Champ',
    CONCAT(v.nv_sonore, ' dB') AS 'Valeur',
    CASE
        WHEN v.nv_sonore > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'U2 - Vitesse moteur (tr/mn)' AS 'Champ',
    CONCAT(v.vitesse_moteur_tr_mn, ' tr/mn') AS 'Valeur',
    CASE
        WHEN v.vitesse_moteur_tr_mn > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'Vitesse max (km/h)' AS 'Champ',
    CONCAT(v.vitesse_max, ' km/h') AS 'Valeur',
    CASE
        WHEN v.vitesse_max > 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'V1 - Émission CO2 (g/km)' AS 'Champ',
    CONCAT(v.emission_co2, ' g/km') AS 'Valeur',
    CASE
        WHEN v.emission_co2 >= 0
        THEN '✓ Présent'
        ELSE '⚠ Absent (optionnel)'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'V2 - Classe environnementale' AS 'Champ',
    CONCAT('Crit\'Air ', cev.classe) AS 'Valeur',
    CASE
        WHEN cev.classe IN ('0', '1', '2', '3', '4', '5')
        THEN '✓ Classe valide'
        ELSE '✗ Classe invalide'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
JOIN ClasseEnvironnementVehicule cev ON v.id_classe_environnementale = cev.id_classe_environnementale
WHERE cg.num = @num_carte

UNION ALL

SELECT
    'J - Permis requis' AS 'Champ',
    cp.permis AS 'Valeur',
    CASE
        WHEN cp.permis IN ('A1', 'A2', 'A', 'B', 'C')
        THEN '✓ Permis valide'
        ELSE '✗ Permis invalide'
    END AS 'Validation'
FROM Carte_Grise cg
JOIN Vehicule v ON cg.id_vehicule = v.id_vehicule
JOIN CategoriePermis cp ON v.id_permis = cp.id_permis
WHERE cg.num = @num_carte;

-- ============================================
-- SECTION 5: Contrôles Techniques
-- ============================================
SELECT '' AS '';
SELECT '=== CONTRÔLES TECHNIQUES ===' AS '';
SELECT '' AS '';

-- Nombre total de contrôles
SELECT
    'X1 - Nombre de contrôles' AS 'Information',
    COUNT(*) AS 'Valeur',
    CASE
        WHEN COUNT(*) > 0 THEN '✓ Contrôles présents'
        ELSE '⚠ Aucun contrôle (véhicule récent)'
    END AS 'Statut'
FROM Controle_Technique ct
WHERE ct.num = @num_carte;

-- Liste des contrôles techniques
SELECT
    CONCAT('X1.', ROW_NUMBER() OVER (ORDER BY ct.date_controle)) AS 'Champ',
    DATE_FORMAT(ct.date_controle, '%d/%m/%Y') AS 'Date Contrôle',
    CONCAT('#', ct.id_controle) AS 'N° Contrôle',
    CASE
        WHEN ct.date_controle IS NOT NULL
        THEN '✓ Valide'
        ELSE '✗ Invalide'
    END AS 'Validation'
FROM Controle_Technique ct
WHERE ct.num = @num_carte
ORDER BY ct.date_controle;

-- ============================================
-- SECTION 6: Statistiques Globales
-- ============================================
SELECT '' AS '';
SELECT '=== STATISTIQUES GLOBALES DATABASE ===' AS '';
SELECT '' AS '';

SELECT
    'Total Cartes Grises' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    '✓' AS 'Statut'
FROM Carte_Grise
UNION ALL
SELECT
    'Total Véhicules' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) = 20 THEN '✓ Attendu: 20' ELSE '✗ Problème' END AS 'Statut'
FROM Vehicule
UNION ALL
SELECT
    'Total Modèles' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) = 6 THEN '✓ Attendu: 6 (2 par catégorie)' ELSE '✗ Problème' END AS 'Statut'
FROM Modele
UNION ALL
SELECT
    'Total Marques' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) = 6 THEN '✓ Attendu: 6' ELSE '✗ Problème' END AS 'Statut'
FROM Marque
UNION ALL
SELECT
    'Total Fabricants' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) = 6 THEN '✓ Attendu: 6' ELSE '✗ Problème' END AS 'Statut'
FROM Fabricant
UNION ALL
SELECT
    'Permis A1 utilisé' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) > 0 THEN '✓ Présent' ELSE '✗ Manquant' END AS 'Statut'
FROM Vehicule v
JOIN CategoriePermis cp ON v.id_permis = cp.id_permis
WHERE cp.permis = 'A1'
UNION ALL
SELECT
    'Permis A2 utilisé' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) > 0 THEN '✓ Présent' ELSE '✗ Manquant' END AS 'Statut'
FROM Vehicule v
JOIN CategoriePermis cp ON v.id_permis = cp.id_permis
WHERE cp.permis = 'A2'
UNION ALL
SELECT
    'Permis A utilisé' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) > 0 THEN '✓ Présent' ELSE '✗ Manquant' END AS 'Statut'
FROM Vehicule v
JOIN CategoriePermis cp ON v.id_permis = cp.id_permis
WHERE cp.permis = 'A'
UNION ALL
SELECT
    'Permis B utilisé' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) > 0 THEN '✓ Présent' ELSE '✗ Manquant' END AS 'Statut'
FROM Vehicule v
JOIN CategoriePermis cp ON v.id_permis = cp.id_permis
WHERE cp.permis = 'B'
UNION ALL
SELECT
    'Permis C utilisé' AS 'Statistique',
    COUNT(*) AS 'Valeur',
    CASE WHEN COUNT(*) > 0 THEN '✓ Présent' ELSE '✗ Manquant' END AS 'Statut'
FROM Vehicule v
JOIN CategoriePermis cp ON v.id_permis = cp.id_permis
WHERE cp.permis = 'C';

-- ============================================
-- SECTION 7: Vérification des formats
-- ============================================
SELECT '' AS '';
SELECT '=== VÉRIFICATION DES FORMATS ===' AS '';
SELECT '' AS '';

-- Vérification format numéros carte grise
SELECT
    'Format numéros carte grise' AS 'Vérification',
    COUNT(*) AS 'Total',
    SUM(CASE WHEN num REGEXP '^[0-9]{4}[A-Z]{2}[0-9]{5}$' THEN 1 ELSE 0 END) AS 'Valides',
    CASE
        WHEN COUNT(*) = SUM(CASE WHEN num REGEXP '^[0-9]{4}[A-Z]{2}[0-9]{5}$' THEN 1 ELSE 0 END)
        THEN '✓ Tous valides'
        ELSE '✗ Erreurs détectées'
    END AS 'Statut'
FROM Carte_Grise

UNION ALL

-- Vérification format immatriculations
SELECT
    'Format immatriculations' AS 'Vérification',
    COUNT(*) AS 'Total',
    SUM(CASE WHEN numero_immatriculation REGEXP '^[A-Z]{2}[0-9]{3}[A-Z]{2}$' THEN 1 ELSE 0 END) AS 'Valides',
    CASE
        WHEN COUNT(*) = SUM(CASE WHEN numero_immatriculation REGEXP '^[A-Z]{2}[0-9]{3}[A-Z]{2}$' THEN 1 ELSE 0 END)
        THEN '✓ Tous valides'
        ELSE '✗ Erreurs détectées'
    END AS 'Statut'
FROM Carte_Grise

UNION ALL

-- Vérification numéros de série uniques
SELECT
    'Numéros de série uniques' AS 'Vérification',
    COUNT(*) AS 'Total',
    COUNT(DISTINCT num_serie) AS 'Uniques',
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT num_serie)
        THEN '✓ Tous uniques'
        ELSE '✗ Doublons détectés'
    END AS 'Statut'
FROM Vehicule

UNION ALL

-- Vérification dates fabrication
SELECT
    'Dates fabrication valides' AS 'Vérification',
    COUNT(*) AS 'Total',
    SUM(CASE WHEN date_fabrication BETWEEN '2020-01-01' AND CURDATE() THEN 1 ELSE 0 END) AS 'Valides',
    CASE
        WHEN COUNT(*) = SUM(CASE WHEN date_fabrication BETWEEN '2020-01-01' AND CURDATE() THEN 1 ELSE 0 END)
        THEN '✓ Toutes valides'
        ELSE '✗ Dates invalides'
    END AS 'Statut'
FROM Vehicule;

-- ============================================
-- FIN DU TEST
-- ============================================
SELECT '' AS '';
SELECT '============================================' AS '';
SELECT 'FIN DU TEST DE CONFORMITÉ' AS '';
SELECT '============================================' AS '';
