-- ============================================
-- SAE 1.04 : Création Base de Données Carte Grise
-- Script de création des tables - MySQL
-- ============================================

-- Suppression des tables si elles existent (ordre inverse des dépendances)
DROP TABLE IF EXISTS Controle_Technique;
DROP TABLE IF EXISTS Carte_Grise;
DROP TABLE IF EXISTS Vehicule;
DROP TABLE IF EXISTS Modele;
DROP TABLE IF EXISTS ClasseEnvironnementVehicule;
DROP TABLE IF EXISTS CategoriePermis;
DROP TABLE IF EXISTS CategorieModele;
DROP TABLE IF EXISTS Proprietaire;
DROP TABLE IF EXISTS Marque;
DROP TABLE IF EXISTS Fabricant;

-- ============================================
-- Table: Fabricant
-- ============================================
CREATE TABLE Fabricant (
    id_fabricant INT AUTO_INCREMENT,
    num_fabricant VARCHAR(10) NOT NULL UNIQUE,
    nom VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_fabricant)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: Marque
-- ============================================
CREATE TABLE Marque (
    id_marque INT AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    id_fabricant INT NOT NULL,
    PRIMARY KEY (id_marque),
    FOREIGN KEY (id_fabricant) REFERENCES Fabricant(id_fabricant)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: Proprietaire
-- ============================================
CREATE TABLE Proprietaire (
    id_proprio INT AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    prenoms VARCHAR(200) NOT NULL,
    adresse VARCHAR(255) NOT NULL,
    PRIMARY KEY (id_proprio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: CategorieModele
-- ============================================
CREATE TABLE CategorieModele (
    id_categorie_modele INT AUTO_INCREMENT,
    categorie VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_categorie_modele),
    UNIQUE (categorie),
    CONSTRAINT chk_categorie CHECK (categorie IN ('deux_roues', 'automobile', 'camion_leger'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: CategoriePermis
-- ============================================
CREATE TABLE CategoriePermis (
    id_permis INT AUTO_INCREMENT,
    permis VARCHAR(10) NOT NULL,
    PRIMARY KEY (id_permis),
    UNIQUE (permis),
    CONSTRAINT chk_permis CHECK (permis IN ('A1', 'A2', 'A', 'B', 'C'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: ClasseEnvironnementVehicule
-- ============================================
CREATE TABLE ClasseEnvironnementVehicule (
    id_classe_environnementale INT AUTO_INCREMENT,
    classe VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_classe_environnementale),
    UNIQUE (classe),
    CONSTRAINT chk_classe_env CHECK (classe IN ('0', '1', '2', '3', '4', '5'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: Modele
-- ============================================
CREATE TABLE Modele (
    id_modele INT AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    id_marque INT NOT NULL,
    id_categorie_modele INT NOT NULL,
    PRIMARY KEY (id_modele),
    FOREIGN KEY (id_marque) REFERENCES Marque(id_marque)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_categorie_modele) REFERENCES CategorieModele(id_categorie_modele)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: Vehicule
-- ============================================
CREATE TABLE Vehicule (
    id_vehicule INT AUTO_INCREMENT,
    num_serie VARCHAR(20) NOT NULL UNIQUE,  -- E: Numéro de série (NumFabricant+Année+Mois+6 chiffres)
    date_fabrication DATE NOT NULL,
    date_premiere_immatriculation DATE NOT NULL,
    type_vehicule VARCHAR(10),  -- D2: Type du véhicule (VP, CTTE, etc.)
    cylindree INT UNSIGNED,
    puissance_chevaux INT UNSIGNED,
    puissance_cv INT UNSIGNED,
    poids_vide INT UNSIGNED,
    poids_max_charge INT UNSIGNED,
    places_assises TINYINT UNSIGNED,
    places_debout TINYINT UNSIGNED,
    nv_sonore DECIMAL(5,2),
    vitesse_moteur_tr_mn INT UNSIGNED,  -- U2: Vitesse max du moteur en tr/mn
    vitesse_max INT UNSIGNED,  -- Vitesse maximale du véhicule en km/h
    emission_co2 DECIMAL(6,2),
    id_modele INT NOT NULL,
    id_fabricant INT NOT NULL,
    id_classe_environnementale INT NOT NULL,
    id_permis INT NOT NULL,
    PRIMARY KEY (id_vehicule),

    -- Contrainte: date de fabrication >= 01/01/2020 (la limite supérieure est gérée par trigger)
    CONSTRAINT chk_date_fabrication_min
        CHECK (date_fabrication >= '2020-01-01'),

    -- Contrainte: date première immatriculation >= date fabrication
    CONSTRAINT chk_date_immat_apres_fabrication
        CHECK (date_premiere_immatriculation >= date_fabrication),

    -- Contrainte: poids max >= poids vide
    CONSTRAINT chk_poids_coherent
        CHECK (poids_max_charge >= poids_vide),

    FOREIGN KEY (id_modele) REFERENCES Modele(id_modele)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_fabricant) REFERENCES Fabricant(id_fabricant)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_classe_environnementale) REFERENCES ClasseEnvironnementVehicule(id_classe_environnementale)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_permis) REFERENCES CategoriePermis(id_permis)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: Carte_Grise
-- ============================================
CREATE TABLE Carte_Grise (
    num VARCHAR(20),
    numero_immatriculation VARCHAR(15) NOT NULL,
    date_immatriculation DATE NOT NULL,
    date_fin_validite DATE,
    conducteur_est_proprietaire BOOLEAN DEFAULT TRUE,
    id_proprio INT NOT NULL,
    id_vehicule INT NOT NULL,
    PRIMARY KEY (num),
    UNIQUE (numero_immatriculation),

    -- Contrainte: format numéro carte grise (AnneéeLettresChiffres)
    CONSTRAINT chk_format_num_carte
        CHECK (num REGEXP '^[0-9]{4}[A-Z]{2}[0-9]{5}$'),

    -- Contrainte: format numéro immatriculation (AA-123-AA)
    CONSTRAINT chk_format_immat
        CHECK (numero_immatriculation REGEXP '^[A-Z]{2}[0-9]{3}[A-Z]{2}$'),

    -- Contrainte: date immatriculation entre 2020 et 2026
    CONSTRAINT chk_date_immat_range
        CHECK (date_immatriculation BETWEEN '2020-01-01' AND '2026-12-31'),

    FOREIGN KEY (id_proprio) REFERENCES Proprietaire(id_proprio)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_vehicule) REFERENCES Vehicule(id_vehicule)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Table: Controle_Technique
-- ============================================
CREATE TABLE Controle_Technique (
    id_controle INT AUTO_INCREMENT,
    date_controle DATE NOT NULL,
    num VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_controle),

    FOREIGN KEY (num) REFERENCES Carte_Grise(num)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- Trigger: Vérification date fabrication avant INSERT
-- ============================================
DELIMITER //

CREATE TRIGGER before_insert_vehicule
BEFORE INSERT ON Vehicule
FOR EACH ROW
BEGIN
    IF NEW.date_fabrication < '2020-01-01' OR NEW.date_fabrication > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La date de fabrication doit être entre 01/01/2020 et aujourd''hui';
    END IF;
END//

-- ============================================
-- Trigger: Vérification date fabrication avant UPDATE
-- ============================================
CREATE TRIGGER before_update_vehicule
BEFORE UPDATE ON Vehicule
FOR EACH ROW
BEGIN
    IF NEW.date_fabrication < '2020-01-01' OR NEW.date_fabrication > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La date de fabrication doit être entre 01/01/2020 et aujourd''hui';
    END IF;
END//

DELIMITER ;

-- ============================================
-- Message de confirmation
-- ============================================
SELECT 'Tables créées avec succès pour la base de données Carte Grise' AS Status;
