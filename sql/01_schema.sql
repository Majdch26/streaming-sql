/* =====================================================================
   Plateforme de vidéo streaming - création des tables
   Compatible MySQL 8.0+ et MariaDB 10.5+
   ===================================================================== */

SET NAMES utf8mb4;

/* ---------- Catalogue ---------- */

CREATE TABLE categorie (
    id      INT UNSIGNED AUTO_INCREMENT,
    nom     VARCHAR(50) NOT NULL,
    CONSTRAINT pk_categorie PRIMARY KEY (id),
    CONSTRAINT unq_categorie_nom UNIQUE (nom)
);

/* Une vidéo est soit un film, soit une série (colonne type).
   Les épisodes ne sont pas des vidéos : ils appartiennent à une série. */
CREATE TABLE video (
    id                  INT UNSIGNED AUTO_INCREMENT,
    titre               VARCHAR(255) NOT NULL,
    type                ENUM('film', 'serie') NOT NULL,
    description         VARCHAR(500) NOT NULL,
    date_publication    DATE NOT NULL,
    langue_originale    VARCHAR(50) NOT NULL,
    image               VARCHAR(255) NOT NULL,
    age_minimum         TINYINT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT pk_video PRIMARY KEY (id),
    CONSTRAINT unq_video_titre_langue UNIQUE (titre, langue_originale),
    CONSTRAINT chk_video_age_minimum CHECK (age_minimum IN (0, 10, 12, 16, 18)),
    INDEX idx_video_type (type),
    INDEX idx_video_date_publication (date_publication),
    INDEX idx_video_langue_originale (langue_originale)
);

/* Une vidéo peut avoir plusieurs catégories (relation N-N) */
CREATE TABLE video_categorie (
    id_video        INT UNSIGNED NOT NULL,
    id_categorie    INT UNSIGNED NOT NULL,
    CONSTRAINT pk_video_categorie PRIMARY KEY (id_video, id_categorie),
    CONSTRAINT fk_video_categorie_video FOREIGN KEY (id_video) REFERENCES video (id) ON DELETE CASCADE,
    CONSTRAINT fk_video_categorie_categorie FOREIGN KEY (id_categorie) REFERENCES categorie (id) ON DELETE CASCADE,
    INDEX idx_video_categorie_categorie (id_categorie)
);

CREATE TABLE film (
    id_video    INT UNSIGNED NOT NULL,
    duree       SMALLINT UNSIGNED NOT NULL,
    url_video   VARCHAR(255) NOT NULL,
    CONSTRAINT pk_film PRIMARY KEY (id_video),
    CONSTRAINT fk_film_video FOREIGN KEY (id_video) REFERENCES video (id) ON DELETE CASCADE,
    CONSTRAINT unq_film_url_video UNIQUE (url_video),
    CONSTRAINT chk_film_duree CHECK (duree > 0),
    INDEX idx_film_duree (duree)
);

CREATE TABLE serie (
    id_video    INT UNSIGNED NOT NULL,
    terminee    BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_serie PRIMARY KEY (id_video),
    CONSTRAINT fk_serie_video FOREIGN KEY (id_video) REFERENCES video (id) ON DELETE CASCADE
);

CREATE TABLE episode (
    id              INT UNSIGNED AUTO_INCREMENT,
    id_serie        INT UNSIGNED NOT NULL,
    numero_saison   TINYINT UNSIGNED NOT NULL,
    numero_episode  SMALLINT UNSIGNED NOT NULL,
    titre           VARCHAR(255) NOT NULL,
    description     VARCHAR(500) NOT NULL,
    duree           SMALLINT UNSIGNED NOT NULL,
    url_video       VARCHAR(255) NOT NULL,
    image_episode   VARCHAR(255) NOT NULL,
    CONSTRAINT pk_episode PRIMARY KEY (id),
    CONSTRAINT fk_episode_serie FOREIGN KEY (id_serie) REFERENCES serie (id_video) ON DELETE CASCADE,
    CONSTRAINT unq_episode_position UNIQUE (id_serie, numero_saison, numero_episode),
    CONSTRAINT unq_episode_url_video UNIQUE (url_video),
    CONSTRAINT chk_episode_numero_saison CHECK (numero_saison > 0),
    CONSTRAINT chk_episode_numero_episode CHECK (numero_episode > 0),
    CONSTRAINT chk_episode_duree CHECK (duree > 0)
);

/* Un sous-titre appartient soit à un film, soit à un épisode */
CREATE TABLE soustitre (
    id              INT UNSIGNED AUTO_INCREMENT,
    id_film         INT UNSIGNED NULL,
    id_episode      INT UNSIGNED NULL,
    langue          VARCHAR(50) NOT NULL,
    url_fichier     VARCHAR(255) NOT NULL,
    CONSTRAINT pk_soustitre PRIMARY KEY (id),
    CONSTRAINT fk_soustitre_film FOREIGN KEY (id_film) REFERENCES film (id_video) ON DELETE CASCADE,
    CONSTRAINT fk_soustitre_episode FOREIGN KEY (id_episode) REFERENCES episode (id) ON DELETE CASCADE,
    CONSTRAINT unq_soustitre_url_fichier UNIQUE (url_fichier),
    CONSTRAINT unq_soustitre_film_langue UNIQUE (id_film, langue),
    CONSTRAINT unq_soustitre_episode_langue UNIQUE (id_episode, langue),
    CONSTRAINT chk_soustitre_cible CHECK ((id_film IS NULL) <> (id_episode IS NULL)),
    CONSTRAINT chk_soustitre_url CHECK (url_fichier LIKE 'http://%' OR url_fichier LIKE 'https://%')
);

/* ---------- Comptes et abonnements ---------- */

/* Les offres commerciales (Essentiel, Standard, Premium...) */
CREATE TABLE offre (
    id              INT UNSIGNED AUTO_INCREMENT,
    nom             VARCHAR(50) NOT NULL,
    prix_mensuel    DECIMAL(5,2) NOT NULL,
    nb_profils_max  TINYINT UNSIGNED NOT NULL DEFAULT 1,
    qualite_max     ENUM('SD', 'HD', '4K') NOT NULL DEFAULT 'HD',
    disponible      BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_offre PRIMARY KEY (id),
    CONSTRAINT unq_offre_nom UNIQUE (nom),
    CONSTRAINT chk_offre_prix CHECK (prix_mensuel >= 0),
    CONSTRAINT chk_offre_nb_profils CHECK (nb_profils_max BETWEEN 1 AND 10)
);

/* Le mot de passe n'est jamais stocké : seulement son empreinte SHA-256 salée */
CREATE TABLE utilisateur (
    id                  INT UNSIGNED AUTO_INCREMENT,
    nom                 VARCHAR(255) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    mot_de_passe_hash   CHAR(64) NOT NULL,
    sel                 CHAR(32) NOT NULL,
    date_creation       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_utilisateur PRIMARY KEY (id),
    CONSTRAINT unq_utilisateur_email UNIQUE (email),
    CONSTRAINT chk_utilisateur_email CHECK (email LIKE '%_@_%._%'),
    INDEX idx_utilisateur_date_creation (date_creation)
);

/* Chaque souscription d'un utilisateur à une offre, avec ses propres dates.
   Le prix payé est conservé même si le prix de l'offre change ensuite. */
CREATE TABLE abonnement (
    id              INT UNSIGNED AUTO_INCREMENT,
    id_utilisateur  INT UNSIGNED NOT NULL,
    id_offre        INT UNSIGNED NOT NULL,
    date_debut      DATE NOT NULL,
    date_fin        DATE NOT NULL,
    prix_mensuel    DECIMAL(5,2) NOT NULL,
    CONSTRAINT pk_abonnement PRIMARY KEY (id),
    CONSTRAINT fk_abonnement_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id) ON DELETE CASCADE,
    CONSTRAINT fk_abonnement_offre FOREIGN KEY (id_offre) REFERENCES offre (id),
    CONSTRAINT chk_abonnement_dates CHECK (date_fin >= date_debut),
    CONSTRAINT chk_abonnement_prix CHECK (prix_mensuel >= 0),
    INDEX idx_abonnement_utilisateur_dates (id_utilisateur, date_debut, date_fin),
    INDEX idx_abonnement_date_fin (date_fin)
);

CREATE TABLE profils (
    id              INT UNSIGNED AUTO_INCREMENT,
    id_utilisateur  INT UNSIGNED NOT NULL,
    nom             VARCHAR(50) NOT NULL,
    age             TINYINT UNSIGNED NULL,
    avatar          VARCHAR(255) NULL,
    CONSTRAINT pk_profils PRIMARY KEY (id),
    CONSTRAINT fk_profils_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id) ON DELETE CASCADE,
    CONSTRAINT unq_profils_utilisateur_nom UNIQUE (id_utilisateur, nom),
    CONSTRAINT chk_profils_age CHECK (age <= 120)
);

CREATE TABLE favoris (
    id_profil   INT UNSIGNED NOT NULL,
    id_video    INT UNSIGNED NOT NULL,
    date_ajout  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_favoris PRIMARY KEY (id_profil, id_video),
    CONSTRAINT fk_favoris_profil FOREIGN KEY (id_profil) REFERENCES profils (id) ON DELETE CASCADE,
    CONSTRAINT fk_favoris_video FOREIGN KEY (id_video) REFERENCES video (id) ON DELETE CASCADE,
    INDEX idx_favoris_video (id_video)
);

/* Historique de visionnage : un film ou un épisode regardé par un profil */
CREATE TABLE visionnage (
    id                  INT UNSIGNED AUTO_INCREMENT,
    id_profil           INT UNSIGNED NOT NULL,
    id_film             INT UNSIGNED NULL,
    id_episode          INT UNSIGNED NULL,
    date_visionnage     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    minutes_vues        SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT pk_visionnage PRIMARY KEY (id),
    CONSTRAINT fk_visionnage_profil FOREIGN KEY (id_profil) REFERENCES profils (id) ON DELETE CASCADE,
    CONSTRAINT fk_visionnage_film FOREIGN KEY (id_film) REFERENCES film (id_video) ON DELETE CASCADE,
    CONSTRAINT fk_visionnage_episode FOREIGN KEY (id_episode) REFERENCES episode (id) ON DELETE CASCADE,
    CONSTRAINT chk_visionnage_cible CHECK ((id_film IS NULL) <> (id_episode IS NULL)),
    INDEX idx_visionnage_profil_date (id_profil, date_visionnage),
    INDEX idx_visionnage_date (date_visionnage)
);
