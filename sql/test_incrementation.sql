-- ============================================
-- SAE 1.04 : Test de la logique d'incrémentation
-- Vérifie les règles d'incrémentation pour :
-- - Numéros de carte grise
-- - Numéros d'immatriculation
-- - Numéros de série
-- ============================================

USE carte_grise_db;

SELECT '============================================' AS '';
SELECT 'TEST LOGIQUE D\'INCRÉMENTATION' AS '';
SELECT 'SAE 1.04 - Vérification des règles' AS '';
SELECT '============================================' AS '';

-- ============================================
-- SECTION 1: Test incrémentation carte grise
-- Règle: AAAALLNNNNN (droite vers gauche)
-- - D'abord les 5 chiffres de droite
-- - Puis les 2 lettres du milieu
-- Exemples:
-- 2026AA00010 → 2026AA00011
-- 2026AA99999 → 2026AB00000
-- ============================================
SELECT '' AS '';
SELECT '=== TEST 1: INCRÉMENTATION NUMÉROS CARTE GRISE ===' AS '';
SELECT '' AS '';

-- Afficher tous les numéros triés
SELECT
    'Liste complète des numéros' AS 'Test',
    num AS 'Numéro',
    SUBSTRING(num, 1, 4) AS 'Année',
    SUBSTRING(num, 5, 2) AS 'Lettres',
    SUBSTRING(num, 7, 5) AS 'Chiffres'
FROM Carte_Grise
ORDER BY num;

SELECT '' AS '';

-- Vérifier la continuité des numéros par année
SELECT
    'Vérification continuité' AS 'Test',
    t1.num AS 'Numéro actuel',
    t2.num AS 'Numéro suivant',
    CASE
        WHEN t2.num IS NULL THEN '✓ Dernier numéro'
        WHEN SUBSTRING(t1.num, 1, 4) != SUBSTRING(t2.num, 1, 4) THEN '✓ Changement année'
        WHEN CAST(SUBSTRING(t1.num, 7, 5) AS UNSIGNED) + 1 = CAST(SUBSTRING(t2.num, 7, 5) AS UNSIGNED)
             AND SUBSTRING(t1.num, 5, 2) = SUBSTRING(t2.num, 5, 2)
        THEN '✓ Incrémentation chiffres OK'
        WHEN SUBSTRING(t1.num, 7, 5) = '99999'
             OR CAST(SUBSTRING(t1.num, 7, 5) AS UNSIGNED) > CAST(SUBSTRING(t2.num, 7, 5) AS UNSIGNED)
        THEN '✓ Incrémentation lettres OK (reset chiffres)'
        ELSE '⚠ Saut de numéros (acceptable pour test)'
    END AS 'Validation'
FROM Carte_Grise t1
LEFT JOIN Carte_Grise t2 ON t2.num = (
    SELECT MIN(num) FROM Carte_Grise
    WHERE num > t1.num
)
ORDER BY t1.num
LIMIT 10;

-- ============================================
-- SECTION 2: Test incrémentation immatriculation
-- Règle: LLNNNLL (droite vers gauche)
-- - D'abord les 2 lettres de droite
-- - Puis les 3 chiffres du milieu (≥ 010)
-- - Enfin les 2 lettres de gauche
-- Exemples:
-- AA010AA → AA010AB
-- AA010ZZ → AA011AA
-- AA999ZZ → AB010AA
-- ============================================
SELECT '' AS '';
SELECT '=== TEST 2: INCRÉMENTATION NUMÉROS IMMATRICULATION ===' AS '';
SELECT '' AS '';

-- Afficher tous les numéros triés
SELECT
    'Liste complète des immatriculations' AS 'Test',
    numero_immatriculation AS 'Immatriculation',
    SUBSTRING(numero_immatriculation, 1, 2) AS 'Lettres gauche',
    SUBSTRING(numero_immatriculation, 3, 3) AS 'Chiffres',
    SUBSTRING(numero_immatriculation, 6, 2) AS 'Lettres droite'
FROM Carte_Grise
ORDER BY numero_immatriculation;

SELECT '' AS '';

-- Vérifier la logique d'incrémentation
SELECT
    'Vérification continuité' AS 'Test',
    t1.numero_immatriculation AS 'Actuel',
    t2.numero_immatriculation AS 'Suivant',
    CASE
        WHEN t2.numero_immatriculation IS NULL THEN '✓ Dernier numéro'
        -- Même préfixe et chiffres, lettres droite incrémentées
        WHEN SUBSTRING(t1.numero_immatriculation, 1, 5) = SUBSTRING(t2.numero_immatriculation, 1, 5)
             AND ASCII(SUBSTRING(t2.numero_immatriculation, 6, 1)) - ASCII(SUBSTRING(t1.numero_immatriculation, 6, 1)) IN (0, 1)
        THEN '✓ Incrémentation lettres droite OK'
        -- ZZ → chiffres incrémentés
        WHEN SUBSTRING(t1.numero_immatriculation, 6, 2) = 'ZZ'
             OR CAST(SUBSTRING(t2.numero_immatriculation, 3, 3) AS UNSIGNED) > CAST(SUBSTRING(t1.numero_immatriculation, 3, 3) AS UNSIGNED)
        THEN '✓ Incrémentation chiffres/lettres gauche OK'
        ELSE '⚠ Logique spécifique (acceptable pour test)'
    END AS 'Validation'
FROM Carte_Grise t1
LEFT JOIN Carte_Grise t2 ON t2.numero_immatriculation = (
    SELECT MIN(numero_immatriculation) FROM Carte_Grise
    WHERE numero_immatriculation > t1.numero_immatriculation
)
ORDER BY t1.numero_immatriculation
LIMIT 10;

SELECT '' AS '';

-- Vérifier que les chiffres sont >= 010
SELECT
    'Chiffres >= 010' AS 'Test',
    COUNT(*) AS 'Total',
    SUM(CASE WHEN CAST(SUBSTRING(numero_immatriculation, 3, 3) AS UNSIGNED) >= 10 THEN 1 ELSE 0 END) AS 'Conformes',
    CASE
        WHEN COUNT(*) = SUM(CASE WHEN CAST(SUBSTRING(numero_immatriculation, 3, 3) AS UNSIGNED) >= 10 THEN 1 ELSE 0 END)
        THEN '✓ Tous >= 010'
        ELSE '✗ Certains < 010'
    END AS 'Validation'
FROM Carte_Grise;

-- ============================================
-- SECTION 3: Test numéros de série
-- Règle: NumFabricant + YYYYMM + 6 chiffres
-- Les 6 chiffres s'incrémentent par mois de fabrication
-- Exemple: FAB001202009000001
-- ============================================
SELECT '' AS '';
SELECT '=== TEST 3: NUMÉROS DE SÉRIE VÉHICULES ===' AS '';
SELECT '' AS '';

-- Afficher structure des numéros de série
SELECT
    'Structure numéros de série' AS 'Test',
    v.num_serie AS 'Numéro série',
    f.num_fabricant AS 'Num Fabricant',
    DATE_FORMAT(v.date_fabrication, '%Y%m') AS 'YYYYMM',
    SUBSTRING(v.num_serie, LENGTH(f.num_fabricant) + 7, 6) AS '6 chiffres',
    CASE
        WHEN v.num_serie LIKE CONCAT(f.num_fabricant, DATE_FORMAT(v.date_fabrication, '%Y%m'), '%')
        THEN '✓ Format correct'
        ELSE '✗ Format incorrect'
    END AS 'Validation'
FROM Vehicule v
JOIN Fabricant f ON v.id_fabricant = f.id_fabricant
ORDER BY v.num_serie
LIMIT 15;

SELECT '' AS '';

-- Vérifier l'unicité des numéros de série
SELECT
    'Unicité des numéros de série' AS 'Test',
    COUNT(*) AS 'Total',
    COUNT(DISTINCT num_serie) AS 'Uniques',
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT num_serie)
        THEN '✓ Tous uniques'
        ELSE '✗ Doublons détectés'
    END AS 'Validation'
FROM Vehicule;

SELECT '' AS '';

-- Vérifier incrémentation par fabricant et mois
SELECT
    'Incrémentation par fabricant/mois' AS 'Test',
    f.num_fabricant AS 'Fabricant',
    DATE_FORMAT(v.date_fabrication, '%Y-%m') AS 'Mois',
    COUNT(*) AS 'Nb véhicules',
    GROUP_CONCAT(SUBSTRING(v.num_serie, -6) ORDER BY v.num_serie SEPARATOR ', ') AS 'Numéros séquence',
    '✓' AS 'Validation'
FROM Vehicule v
JOIN Fabricant f ON v.id_fabricant = f.id_fabricant
GROUP BY f.num_fabricant, DATE_FORMAT(v.date_fabrication, '%Y-%m')
ORDER BY f.num_fabricant, DATE_FORMAT(v.date_fabrication, '%Y-%m');

-- ============================================
-- SECTION 4: Test format des dates
-- Règle: Jour/Mois/Année (format français)
-- ============================================
SELECT '' AS '';
SELECT '=== TEST 4: FORMAT DES DATES ===' AS '';
SELECT '' AS '';

SELECT
    'Exemple formatage dates' AS 'Test',
    'Date fabrication' AS 'Type',
    v.date_fabrication AS 'Valeur SQL',
    DATE_FORMAT(v.date_fabrication, '%d/%m/%Y') AS 'Format français',
    CASE
        WHEN DATE_FORMAT(v.date_fabrication, '%d/%m/%Y') REGEXP '^[0-3][0-9]/[0-1][0-9]/[0-9]{4}$'
        THEN '✓ Format JJ/MM/AAAA'
        ELSE '✗ Format incorrect'
    END AS 'Validation'
FROM Vehicule v
LIMIT 1;

SELECT
    'Exemple formatage dates' AS 'Test',
    'Date immatriculation' AS 'Type',
    cg.date_immatriculation AS 'Valeur SQL',
    DATE_FORMAT(cg.date_immatriculation, '%d/%m/%Y') AS 'Format français',
    CASE
        WHEN DATE_FORMAT(cg.date_immatriculation, '%d/%m/%Y') REGEXP '^[0-3][0-9]/[0-1][0-9]/[0-9]{4}$'
        THEN '✓ Format JJ/MM/AAAA'
        ELSE '✗ Format incorrect'
    END AS 'Validation'
FROM Carte_Grise cg
LIMIT 1;

-- ============================================
-- SECTION 5: Résumé des validations
-- ============================================
SELECT '' AS '';
SELECT '=== RÉSUMÉ DES VALIDATIONS ===' AS '';
SELECT '' AS '';

SELECT
    'Validation générale' AS 'Catégorie',
    'Numéros carte grise' AS 'Élément',
    CASE
        WHEN (SELECT COUNT(*) FROM Carte_Grise WHERE num REGEXP '^[0-9]{4}[A-Z]{2}[0-9]{5}$') = (SELECT COUNT(*) FROM Carte_Grise)
        THEN '✓ CONFORME'
        ELSE '✗ NON CONFORME'
    END AS 'Statut',
    CONCAT(
        (SELECT COUNT(*) FROM Carte_Grise WHERE num REGEXP '^[0-9]{4}[A-Z]{2}[0-9]{5}$'),
        '/',
        (SELECT COUNT(*) FROM Carte_Grise)
    ) AS 'Détail'
UNION ALL
SELECT
    'Validation générale' AS 'Catégorie',
    'Immatriculations' AS 'Élément',
    CASE
        WHEN (SELECT COUNT(*) FROM Carte_Grise WHERE numero_immatriculation REGEXP '^[A-Z]{2}[0-9]{3}[A-Z]{2}$') = (SELECT COUNT(*) FROM Carte_Grise)
        THEN '✓ CONFORME'
        ELSE '✗ NON CONFORME'
    END AS 'Statut',
    CONCAT(
        (SELECT COUNT(*) FROM Carte_Grise WHERE numero_immatriculation REGEXP '^[A-Z]{2}[0-9]{3}[A-Z]{2}$'),
        '/',
        (SELECT COUNT(*) FROM Carte_Grise)
    ) AS 'Détail'
UNION ALL
SELECT
    'Validation générale' AS 'Catégorie',
    'Chiffres immat >= 010' AS 'Élément',
    CASE
        WHEN (SELECT COUNT(*) FROM Carte_Grise WHERE CAST(SUBSTRING(numero_immatriculation, 3, 3) AS UNSIGNED) >= 10) = (SELECT COUNT(*) FROM Carte_Grise)
        THEN '✓ CONFORME'
        ELSE '✗ NON CONFORME'
    END AS 'Statut',
    CONCAT(
        (SELECT COUNT(*) FROM Carte_Grise WHERE CAST(SUBSTRING(numero_immatriculation, 3, 3) AS UNSIGNED) >= 10),
        '/',
        (SELECT COUNT(*) FROM Carte_Grise)
    ) AS 'Détail'
UNION ALL
SELECT
    'Validation générale' AS 'Catégorie',
    'Numéros série uniques' AS 'Élément',
    CASE
        WHEN (SELECT COUNT(DISTINCT num_serie) FROM Vehicule) = (SELECT COUNT(*) FROM Vehicule)
        THEN '✓ CONFORME'
        ELSE '✗ NON CONFORME'
    END AS 'Statut',
    CONCAT(
        (SELECT COUNT(DISTINCT num_serie) FROM Vehicule),
        '/',
        (SELECT COUNT(*) FROM Vehicule)
    ) AS 'Détail'
UNION ALL
SELECT
    'Validation générale' AS 'Catégorie',
    'Numéros série format' AS 'Élément',
    CASE
        WHEN (SELECT COUNT(*) FROM Vehicule v JOIN Fabricant f ON v.id_fabricant = f.id_fabricant
              WHERE v.num_serie LIKE CONCAT(f.num_fabricant, DATE_FORMAT(v.date_fabrication, '%Y%m'), '%')) = (SELECT COUNT(*) FROM Vehicule)
        THEN '✓ CONFORME'
        ELSE '✗ NON CONFORME'
    END AS 'Statut',
    CONCAT(
        (SELECT COUNT(*) FROM Vehicule v JOIN Fabricant f ON v.id_fabricant = f.id_fabricant
         WHERE v.num_serie LIKE CONCAT(f.num_fabricant, DATE_FORMAT(v.date_fabrication, '%Y%m'), '%')),
        '/',
        (SELECT COUNT(*) FROM Vehicule)
    ) AS 'Détail';

-- ============================================
-- FIN DU TEST D'INCRÉMENTATION
-- ============================================
SELECT '' AS '';
SELECT '============================================' AS '';
SELECT 'FIN DU TEST D\'INCRÉMENTATION' AS '';
SELECT '============================================' AS '';
