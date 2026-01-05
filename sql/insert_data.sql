-- ============================================
-- SAE 1.04 : Insertion des données de test
-- Base de données Carte Grise
-- ============================================

USE carte_grise_db;

-- ============================================
-- 1. Insertion des Catégories (tables de référence)
-- ============================================

-- Catégories de modèles
INSERT INTO CategorieModele (categorie) VALUES
('deux_roues'),
('automobile'),
('camion_leger');

-- Catégories de permis
INSERT INTO CategoriePermis (permis) VALUES
('A1'),
('A2'),
('A'),
('B'),
('C');

-- Classes environnementales (Crit'Air)
INSERT INTO ClasseEnvironnementVehicule (classe) VALUES
('0'),
('1'),
('2'),
('3'),
('4'),
('5');

-- ============================================
-- 2. Insertion des Fabricants (6 fabricants)
-- ============================================
INSERT INTO Fabricant (num_fabricant, nom) VALUES
('FAB001', 'Yamaha Motor Company'),
('FAB002', 'Renault Group'),
('FAB003', 'Peugeot'),
('FAB004', 'Volkswagen'),
('FAB005', 'Fiat Professional'),
('FAB006', 'Kawasaki Heavy Industries');

-- ============================================
-- 3. Insertion des Marques (6 marques)
-- ============================================
INSERT INTO Marque (nom, id_fabricant) VALUES
('Yamaha', 1),      -- Deux roues
('Kawasaki', 6),    -- Deux roues
('Renault', 2),     -- Automobiles
('Peugeot', 3),     -- Automobiles
('Volkswagen', 4),  -- Automobiles et camions
('Fiat', 5);        -- Camions légers

-- ============================================
-- 4. Insertion des Modèles (2 modèles par catégorie - EXACTEMENT)
-- ============================================

-- Deux roues (catégorie 1) - 2 modèles SEULEMENT
INSERT INTO Modele (nom, id_marque, id_categorie_modele) VALUES
('MT-07', 1, 1),           -- Yamaha MT-07 (deux_roues)
('Ninja 650', 2, 1);       -- Kawasaki Ninja 650 (deux_roues)

-- Automobiles (catégorie 2) - 2 modèles SEULEMENT
INSERT INTO Modele (nom, id_marque, id_categorie_modele) VALUES
('Clio V', 3, 2),          -- Renault Clio (automobile)
('208', 4, 2);             -- Peugeot 208 (automobile)

-- Camions légers (catégorie 3) - 2 modèles SEULEMENT
INSERT INTO Modele (nom, id_marque, id_categorie_modele) VALUES
('Transporter', 5, 3),     -- VW Transporter (camion_leger)
('Ducato', 6, 3);          -- Fiat Ducato (camion_leger)

-- ============================================
-- 5. Insertion des Propriétaires (12 propriétaires)
-- ============================================
INSERT INTO Proprietaire (nom, prenoms, adresse) VALUES
('Dupont', 'Jean Pierre', '12 Rue de la Paix, 06000 Nice'),
('Martin', 'Sophie Marie', '45 Avenue des Fleurs, 06100 Nice'),
('Bernard', 'Luc', '8 Boulevard Victor Hugo, 06300 Nice'),
('Dubois', 'Marie Claire', '23 Rue Pasteur, 06200 Nice'),
('Thomas', 'Paul Alexandre', '67 Avenue Jean Médecin, 06000 Nice'),
('Robert', 'Julie Anne', '34 Rue de France, 06000 Nice'),
('Petit', 'Michel', '91 Promenade des Anglais, 06000 Nice'),
('Richard', 'Isabelle', '15 Rue Masséna, 06000 Nice'),
('Durand', 'François Jacques', '52 Avenue Thiers, 06000 Nice'),
('Moreau', 'Catherine', '78 Rue Gioffredo, 06000 Nice'),
('Simon', 'Nicolas', '29 Boulevard Gambetta, 06000 Nice'),
('Laurent', 'Émilie Rose', '41 Rue de la Liberté, 06000 Nice');

-- ============================================
-- 6. Insertion des Véhicules (20 véhicules)
-- Répartition: 6 deux_roues, 10 automobiles, 4 camions_leger
-- Dates: 2020 à 2026
-- Permis: A1, A2, A, B, C
-- ============================================

-- Deux roues (6 véhicules) - Permis A1, A2, A
-- Modèles disponibles: 1=MT-07, 2=Ninja 650
INSERT INTO Vehicule (num_serie, date_fabrication, date_premiere_immatriculation, type_vehicule, cylindree, puissance_chevaux, puissance_cv,
                      poids_vide, poids_max_charge, places_assises, places_debout, nv_sonore, vitesse_moteur_tr_mn, vitesse_max,
                      emission_co2, id_modele, id_fabricant, id_classe_environnementale, id_permis) VALUES
-- Yamaha MT-07 (Permis A1 - petite cylindrée < 125cc simulée)
('FAB001202009000001', '2020-09-10', '2020-10-05', 'MTL', 125, 15, 11, 150, 350, 2, 0, 80.0, 9000, 110, 85.0, 1, 1, 3, 1),
('FAB001202403000001', '2024-03-15', '2024-04-10', 'MTL', 125, 15, 11, 150, 350, 2, 0, 80.0, 9000, 110, 83.5, 1, 1, 2, 1),
-- Yamaha MT-07 (Permis A2 - cylindrée moyenne)
('FAB001202105000001', '2021-05-20', '2021-06-15', 'MTL', 689, 47, 35, 182, 400, 2, 0, 85.5, 9000, 160, 98.5, 1, 1, 3, 2),
('FAB001202412000001', '2024-12-12', '2025-01-08', 'MTL', 689, 47, 35, 182, 400, 2, 0, 85.5, 9000, 160, 96.2, 1, 1, 2, 2),
-- Kawasaki Ninja 650 (Permis A - grosse cylindrée)
('FAB006202207000001', '2022-07-18', '2022-08-14', 'MTL', 649, 68, 50, 193, 410, 2, 0, 86.0, 10500, 180, 95.8, 2, 6, 3, 3),
('FAB006202411000001', '2024-11-25', '2024-12-20', 'MTL', 649, 68, 50, 193, 410, 2, 0, 86.0, 10500, 180, 94.3, 2, 6, 2, 3);

-- Automobiles (10 véhicules) - Permis B
-- Modèles disponibles: 3=Clio V, 4=208
INSERT INTO Vehicule (num_serie, date_fabrication, date_premiere_immatriculation, type_vehicule, cylindree, puissance_chevaux, puissance_cv,
                      poids_vide, poids_max_charge, places_assises, places_debout, nv_sonore, vitesse_moteur_tr_mn, vitesse_max,
                      emission_co2, id_modele, id_fabricant, id_classe_environnementale, id_permis) VALUES
-- Renault Clio V
('FAB002202002000001', '2020-02-14', '2020-03-11', 'VP', 999, 100, 74, 1050, 1550, 5, 0, 70.5, 6000, 170, 105.3, 3, 2, 3, 4),
('FAB002202105000001', '2021-05-12', '2021-06-08', 'VP', 999, 100, 74, 1050, 1550, 5, 0, 70.5, 6000, 170, 103.8, 3, 2, 2, 4),
('FAB002202208000001', '2022-08-30', '2022-09-25', 'VP', 999, 100, 74, 1050, 1550, 5, 0, 70.5, 6000, 170, 102.5, 3, 2, 2, 4),
('FAB002202403000002', '2024-03-19', '2024-04-15', 'VP', 999, 100, 74, 1050, 1550, 5, 0, 70.5, 6000, 170, 100.1, 3, 2, 1, 4),
('FAB002202410000001', '2024-10-07', '2024-11-02', 'VP', 999, 100, 74, 1050, 1550, 5, 0, 70.5, 6000, 170, 98.8, 3, 2, 1, 4),
-- Peugeot 208
('FAB003202011000001', '2020-11-05', '2020-12-01', 'VP', 1199, 100, 74, 1090, 1590, 5, 0, 71.0, 6200, 170, 108.7, 4, 3, 3, 4),
('FAB003202107000001', '2021-07-22', '2021-08-17', 'VP', 1199, 100, 74, 1090, 1590, 5, 0, 71.0, 6200, 170, 106.5, 4, 3, 2, 4),
('FAB003202304000001', '2023-04-18', '2023-05-14', 'VP', 1199, 100, 74, 1090, 1590, 5, 0, 71.0, 6200, 170, 104.2, 4, 3, 2, 4),
('FAB003202406000001', '2024-06-15', '2024-07-10', 'VP', 1199, 100, 74, 1090, 1590, 5, 0, 71.0, 6200, 170, 102.0, 4, 3, 1, 4),
('FAB003202412000001', '2024-12-28', '2025-01-25', 'VP', 1199, 100, 74, 1090, 1590, 5, 0, 71.0, 6200, 170, 100.5, 4, 3, 1, 4);

-- Camions légers (4 véhicules) - Permis C
-- Modèles disponibles: 5=Transporter, 6=Ducato
INSERT INTO Vehicule (num_serie, date_fabrication, date_premiere_immatriculation, type_vehicule, cylindree, puissance_chevaux, puissance_cv,
                      poids_vide, poids_max_charge, places_assises, places_debout, nv_sonore, vitesse_moteur_tr_mn, vitesse_max,
                      emission_co2, id_modele, id_fabricant, id_classe_environnementale, id_permis) VALUES
-- VW Transporter
('FAB004202008000001', '2020-08-20', '2020-09-15', 'CTTE', 1968, 150, 110, 3200, 4500, 3, 0, 75.0, 5000, 130, 198.5, 5, 4, 4, 5),
('FAB004202302000001', '2023-02-28', '2023-03-25', 'CTTE', 1968, 150, 110, 3200, 4500, 3, 0, 75.0, 5000, 130, 195.3, 5, 4, 4, 5),
-- Fiat Ducato
('FAB005202110000001', '2021-10-15', '2021-11-10', 'CTTE', 2287, 140, 103, 3100, 4400, 3, 0, 74.8, 4800, 130, 192.7, 6, 5, 4, 5),
('FAB005202406000001', '2024-06-12', '2024-07-08', 'CTTE', 2287, 140, 103, 3100, 4400, 3, 0, 74.8, 4800, 130, 190.2, 6, 5, 4, 5);

-- ============================================
-- 7. Insertion des Cartes Grises (20 cartes grises)
-- Dates: 2020 à 2026
-- ============================================
INSERT INTO Carte_Grise (num, numero_immatriculation, date_immatriculation, date_fin_validite,
                         conducteur_est_proprietaire, id_proprio, id_vehicule) VALUES
-- 2020 (4 cartes) - Véhicules: 1, 7, 12, 17
('2020AA00001', 'AA010AA', '2020-03-11', NULL, TRUE, 1, 7),   -- Clio 2020
('2020AA00002', 'AA011AB', '2020-09-15', NULL, TRUE, 2, 17),  -- Transporter 2020
('2020AA00003', 'AA012AC', '2020-10-05', NULL, FALSE, 3, 1),  -- MT-07 A1 2020
('2020AA00004', 'AA013AD', '2020-12-01', NULL, TRUE, 4, 12),  -- 208 2020
-- 2021 (4 cartes) - Véhicules: 3, 8, 13, 19
('2021AA00001', 'AB014AA', '2021-06-08', NULL, TRUE, 5, 8),   -- Clio 2021
('2021AA00002', 'AB015AB', '2021-06-15', NULL, FALSE, 6, 3),  -- MT-07 A2 2021
('2021AA00003', 'AB016AC', '2021-08-17', NULL, TRUE, 7, 13),  -- 208 2021
('2021AA00004', 'AB017AD', '2021-11-10', NULL, TRUE, 8, 19),  -- Ducato 2021
-- 2022 (3 cartes) - Véhicules: 5, 9
('2022AA00001', 'AC018AA', '2022-08-14', NULL, TRUE, 9, 5),   -- Ninja 2022
('2022AA00002', 'AC019AB', '2022-09-25', NULL, FALSE, 10, 9), -- Clio 2022
-- 2023 (3 cartes) - Véhicules: 14, 18
('2023AA00001', 'AD020AA', '2023-03-25', NULL, TRUE, 11, 18), -- Transporter 2023
('2023AA00002', 'AD021AB', '2023-05-14', NULL, TRUE, 12, 14), -- 208 2023
-- 2024 (3 cartes) - Véhicules: 6, 10
('2024AA00001', 'AE022AA', '2024-04-15', NULL, FALSE, 1, 10), -- Clio 2024
('2024AA00002', 'AE023AB', '2024-12-20', NULL, TRUE, 2, 6),   -- Ninja 2024
-- 2025 (2 cartes) - Véhicules: 2, 11, 15, 20
('2025AA00001', 'AF024AA', '2025-04-10', NULL, TRUE, 3, 2),   -- MT-07 A1 2025
('2025AA00002', 'AF025AB', '2025-07-08', NULL, FALSE, 4, 20), -- Ducato 2025
('2025AA00003', 'AF026AC', '2025-07-10', NULL, TRUE, 5, 15),  -- 208 2025
('2025AA00004', 'AF027AD', '2025-11-02', NULL, TRUE, 6, 11),  -- Clio 2025
-- 2026 (1 carte) - Véhicules: 4, 16
('2026AA00001', 'AG028AA', '2026-02-08', NULL, TRUE, 7, 4),   -- MT-07 A2 2026
('2026AA00002', 'AG029AB', '2026-03-25', NULL, FALSE, 8, 16); -- 208 2026

-- ============================================
-- 8. Insertion des Contrôles Techniques
-- Véhicules >= 4 ans d'ancienneté (2020, 2021, 2022)
-- ============================================

-- Contrôles pour véhicules de 2020 (6 ans en 2026 - doivent avoir des CTs)
INSERT INTO Controle_Technique (date_controle, num) VALUES
('2024-04-10', '2020AA00001'),  -- Clio 2020 (CT à 4 ans)
('2024-10-15', '2020AA00002'),  -- Transporter 2020 (CT à 4 ans)
('2025-03-12', '2020AA00003'),  -- MT-07 A1 2020 (2e CT à 5 ans)
('2024-12-20', '2020AA00004');  -- 208 2020 (CT à 4 ans)

-- Contrôles pour véhicules de 2021 (5 ans en 2026 - doivent avoir des CTs)
INSERT INTO Controle_Technique (date_controle, num) VALUES
('2025-07-10', '2021AA00001'),  -- Clio 2021 (CT à 4 ans)
('2025-07-20', '2021AA00002'),  -- MT-07 A2 2021 (CT à 4 ans)
('2025-09-15', '2021AA00003'),  -- 208 2021 (CT à 4 ans)
('2025-12-05', '2021AA00004');  -- Ducato 2021 (CT à 4 ans)

-- ============================================
-- Vérification des données insérées
-- ============================================
SELECT 'Données insérées avec succès!' AS Status;

-- Statistiques
SELECT
    (SELECT COUNT(*) FROM Fabricant) AS Fabricants,
    (SELECT COUNT(*) FROM Marque) AS Marques,
    (SELECT COUNT(*) FROM Modele) AS Modeles,
    (SELECT COUNT(*) FROM Proprietaire) AS Proprietaires,
    (SELECT COUNT(*) FROM Vehicule) AS Vehicules,
    (SELECT COUNT(*) FROM Carte_Grise) AS Cartes_Grises,
    (SELECT COUNT(*) FROM Controle_Technique) AS Controles_Techniques;
