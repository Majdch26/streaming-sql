CREATE TABLE IF NOT EXISTS video (
	id INT UNSIGNED AUTO_INCREMENT,
    titre VARCHAR(255) NOT NULL,
    categorie VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    date_publication DATE NOT NULL,
    langue_originale VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL,
    CONSTRAINT pk_video PRIMARY KEY (id),
    INDEX idx_video_categorie(categorie),
    INDEX idx_video_date_publication(date_publication),
    INDEX idx_video_langue_originale(langue_originale),
    CONSTRAINT unq_video_titre_langue_originale UNIQUE idxunq_video_titre_langue_originale (titre, langue_originale)
);

CREATE TABLE IF NOT EXISTS film (
	id_video INT UNSIGNED NOT NULL,
	duree INT NOT NULL,
	url_video VARCHAR(255) NOT NULL,
    CONSTRAINT pk_film PRIMARY KEY (id_video),
	CONSTRAINT fk_film_id_video_video FOREIGN KEY (id_video) REFERENCES video (id) ON DELETE CASCADE,
	INDEX idx_film_duree(duree),
    CONSTRAINT unq_film_url_video UNIQUE idxunq_film_url_video (url_video)
);

CREATE TABLE IF NOT EXISTS serie (
	id_video INT UNSIGNED NOT NULL,
	duree INT NOT NULL,
	CONSTRAINT pk_serie PRIMARY KEY (id_video),
	CONSTRAINT fk_serie_id_video_video FOREIGN KEY (id_video) REFERENCES video (id) ON DELETE CASCADE,
	INDEX idx_serie_duree(duree)
);

CREATE TABLE IF NOT EXISTS episode (
	id INT UNSIGNED AUTO_INCREMENT,
    id_serie INT UNSIGNED NOT NULL,
	numero_episode INT NOT NULL,
    numero_saison INT NOT NULL,
	url_video VARCHAR(255) NOT NULL,
	duree INT NOT NULL,
	description VARCHAR(255) NOT NULL,
	titre VARCHAR(255) NOT NULL,
	image_episode VARCHAR(255) NOT NULL,
    CONSTRAINT pk_episode PRIMARY KEY (id),
	CONSTRAINT fk_episode_id_serie_serie FOREIGN KEY (id_serie) REFERENCES serie (id_video) ON DELETE CASCADE,
    INDEX idx_episode_numero_episode_numero_saison (numero_episode, numero_saison),
    INDEX idx_episode_duree (duree),
    CONSTRAINT unq_episode_url_video UNIQUE idxunq_episode_url_video (url_video),
    CONSTRAINT unq_episode_titre_id_serie UNIQUE idxunq_episode_titre_id_serie (titre, id_serie)
);

CREATE TABLE IF NOT EXISTS soustitre (
	id INT UNSIGNED AUTO_INCREMENT,
	id_video_film INT UNSIGNED,
	id_episode INT UNSIGNED,
	langue VARCHAR(50) NOT NULL,
	url_fichier VARCHAR(255) NOT NULL,
    CONSTRAINT pk_soustitre PRIMARY KEY (id),
	CONSTRAINT fk_soustitre_id_video_film_film FOREIGN KEY (id_video_film) REFERENCES film(id_video) ON DELETE CASCADE,
	CONSTRAINT fk_soustitre_id_episode_episode FOREIGN KEY (id_episode) REFERENCES episode(id) ON DELETE CASCADE,
    INDEX idx_soustitre_langue (langue),
    INDEX idx_soustitre_id_video_film (id_video_film),
    INDEX idx_soustitre_id_episode (id_episode),
    CONSTRAINT unq_soustitre_url_fichier UNIQUE idxunq_soustitre_url_fichier (url_fichier),
	CONSTRAINT chk_soustitre_id_video_film_id_episode CHECK ((id_video_film IS NOT NULL AND id_episode IS NULL)
	OR (id_video_film IS NULL AND id_episode IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS abonnement (
	id INT UNSIGNED AUTO_INCREMENT,
	nom VARCHAR(255) NOT NULL,
	prix DECIMAL(4,2) NOT NULL,
	nb_profile_max INT NOT NULL DEFAULT 1,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    CONSTRAINT pk_abonnement PRIMARY KEY (id),
    INDEX idx_abonnement_prix (prix),
    INDEX idx_abonnement_date_debut (date_debut),
    INDEX idx_abonnement_date_fin (date_fin),
    CONSTRAINT unq_abonnement_nom UNIQUE idxunq_abonnement_nom (nom),
    CONSTRAINT chk_abonnement_prix CHECK (prix >= 0),
    CONSTRAINT chk_abonnement_nb_profile_max CHECK (nb_profile_max > 0)
);

CREATE TABLE IF NOT EXISTS utilisateur (
	id INT UNSIGNED AUTO_INCREMENT,
	id_abonnement INT UNSIGNED NOT NULL,
	nom VARCHAR(255) NOT NULL,
	email VARCHAR(255) NOT NULL,
	mot_de_passe VARCHAR(255) NOT NULL,
	date_creation DATE NOT NULL,
	abonnement_actif BOOLEAN NOT NULL,
    CONSTRAINT pk_utilisateur PRIMARY KEY (id),
	CONSTRAINT fk_utilisateur_id_abonnement_abonnement FOREIGN KEY (id_abonnement) REFERENCES abonnement(id) ON DELETE CASCADE,
	INDEX idx_utilisateur_date_creation (date_creation),
	INDEX idx_utilisateur_abonnement_actif (abonnement_actif),
    CONSTRAINT unq_utilisateur_email UNIQUE idxunq_utilisateur_email (email)
);

CREATE TABLE IF NOT EXISTS profils (
	id INT UNSIGNED AUTO_INCREMENT,
	id_utilisateur INT UNSIGNED NOT NULL,
	nom VARCHAR(255) NOT NULL,
	age INT,
	avatar VARCHAR(255),
    CONSTRAINT pk_profils PRIMARY KEY (id),
	CONSTRAINT fk_profils_id_utilisateur_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur (id) ON DELETE CASCADE,
    CONSTRAINT chk_profils_age CHECK (age >= 0),
    CONSTRAINT unq_profils_nom_id_utilisateur UNIQUE idxunq_profils_nom_id_utilisateur (nom, id_utilisateur)
);

CREATE TABLE IF NOT EXISTS favoris (
	id INT UNSIGNED AUTO_INCREMENT,
	id_video INT UNSIGNED NOT NULL,
	id_profil INT UNSIGNED NOT NULL,
    CONSTRAINT pk_favoris PRIMARY KEY (id),
	CONSTRAINT fk_favoris_id_video_video FOREIGN KEY (id_video) REFERENCES video(id) ON DELETE CASCADE,
	CONSTRAINT fk_favoris_id_profil_profils FOREIGN KEY (id_profil) REFERENCES profils (id) ON DELETE CASCADE,
	CONSTRAINT unq_favoris_id_video_id_profil UNIQUE idxunq_favoris_id_video_id_profil (id_video, id_profil)
);











