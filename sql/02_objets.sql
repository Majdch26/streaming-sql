/* =====================================================================
   Fonctions, procédures et déclencheurs
   ===================================================================== */

SET NAMES utf8mb4;

DELIMITER $$

/* =====================================================================
   FONCTIONS
   ===================================================================== */

/* Empreinte SHA-256 d'un mot de passe salé */
CREATE FUNCTION f_hacher_mot_de_passe(in_sel CHAR(32), in_mot_de_passe VARCHAR(255))
RETURNS CHAR(64)
DETERMINISTIC NO SQL
BEGIN
    RETURN SHA2(CONCAT(in_sel, in_mot_de_passe), 256);
END$$

/* 1 si l'email et le mot de passe sont corrects, 0 sinon.
   On ne dit pas lequel des deux est faux, pour ne pas révéler
   quels emails ont un compte. */
CREATE FUNCTION f_verifier_connexion(in_email VARCHAR(255), in_mot_de_passe VARCHAR(255))
RETURNS TINYINT
READS SQL DATA
BEGIN
    DECLARE v_nb INT DEFAULT 0;

    SELECT COUNT(*) INTO v_nb
    FROM utilisateur
    WHERE email = in_email
      AND mot_de_passe_hash = f_hacher_mot_de_passe(sel, in_mot_de_passe);

    RETURN v_nb = 1;
END$$

/* Identifiant de l'utilisateur ayant cet email, -1 s'il n'existe pas */
CREATE FUNCTION f_get_utilisateur_par_email(in_email VARCHAR(255))
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_id INT DEFAULT -1;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_id = -1;

    SELECT id INTO v_id FROM utilisateur WHERE email = in_email;
    RETURN v_id;
END$$

/* 1 si l'utilisateur a un abonnement en cours aujourd'hui, 0 sinon,
   -1 si l'utilisateur n'existe pas. Calculé à partir des dates :
   aucune colonne à tenir à jour. */
CREATE FUNCTION f_abonnement_actif(in_id_utilisateur INT UNSIGNED)
RETURNS TINYINT
READS SQL DATA
BEGIN
    IF NOT EXISTS (SELECT 1 FROM utilisateur WHERE id = in_id_utilisateur) THEN
        RETURN -1;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM abonnement
        WHERE id_utilisateur = in_id_utilisateur
          AND CURRENT_DATE BETWEEN date_debut AND date_fin
    );
END$$

/* Nombre de profils autorisés : celui de l'offre en cours, 1 sans abonnement */
CREATE FUNCTION f_nb_profils_max(in_id_utilisateur INT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_max INT DEFAULT NULL;

    SELECT MAX(o.nb_profils_max) INTO v_max
    FROM abonnement a
    JOIN offre o ON o.id = a.id_offre
    WHERE a.id_utilisateur = in_id_utilisateur
      AND CURRENT_DATE BETWEEN a.date_debut AND a.date_fin;

    RETURN COALESCE(v_max, 1);
END$$

/* Nombre d'épisodes d'une série (0 si elle n'en a pas encore),
   -1 si l'identifiant n'est pas une série */
CREATE FUNCTION f_nombre_episodes(in_id_serie INT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
    IF NOT EXISTS (SELECT 1 FROM serie WHERE id_video = in_id_serie) THEN
        RETURN -1;
    END IF;

    RETURN (SELECT COUNT(*) FROM episode WHERE id_serie = in_id_serie);
END$$

/* Durée totale en minutes : durée du film, ou somme des épisodes d'une série.
   -1 si la vidéo n'existe pas. Le type est trouvé automatiquement. */
CREATE FUNCTION f_duree_totale(in_id_video INT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_type VARCHAR(10) DEFAULT NULL;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_type = NULL;

    SELECT type INTO v_type FROM video WHERE id = in_id_video;

    IF v_type IS NULL THEN
        RETURN -1;
    ELSEIF v_type = 'film' THEN
        RETURN (SELECT duree FROM film WHERE id_video = in_id_video);
    ELSE
        RETURN (SELECT COALESCE(SUM(duree), 0) FROM episode WHERE id_serie = in_id_video);
    END IF;
END$$


/* =====================================================================
   PROCÉDURES : catalogue
   ===================================================================== */

/* Associe une liste de catégories séparées par des virgules à une vidéo.
   Les catégories qui n'existent pas encore sont créées. */
CREATE PROCEDURE p_associer_categories(IN in_id_video INT UNSIGNED, IN in_categories VARCHAR(500))
BEGIN
    DECLARE v_reste VARCHAR(500) DEFAULT TRIM(COALESCE(in_categories, ''));
    DECLARE v_nom VARCHAR(50);
    DECLARE v_id_categorie INT UNSIGNED;

    WHILE v_reste <> '' DO
        SET v_nom = TRIM(SUBSTRING_INDEX(v_reste, ',', 1));
        IF LOCATE(',', v_reste) > 0 THEN
            SET v_reste = TRIM(SUBSTRING(v_reste, LOCATE(',', v_reste) + 1));
        ELSE
            SET v_reste = '';
        END IF;

        IF v_nom <> '' THEN
            INSERT IGNORE INTO categorie (nom) VALUES (v_nom);
            SELECT id INTO v_id_categorie FROM categorie WHERE nom = v_nom;
            INSERT IGNORE INTO video_categorie (id_video, id_categorie)
            VALUES (in_id_video, v_id_categorie);
        END IF;
    END WHILE;
END$$

CREATE PROCEDURE p_ajouter_film(
    IN  in_titre            VARCHAR(255),
    IN  in_description      VARCHAR(500),
    IN  in_date_publication DATE,
    IN  in_langue_originale VARCHAR(50),
    IN  in_image            VARCHAR(255),
    IN  in_age_minimum      TINYINT UNSIGNED,
    IN  in_categories       VARCHAR(500),
    IN  in_duree            SMALLINT UNSIGNED,
    IN  in_url_video        VARCHAR(255),
    OUT out_id_video        INT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Une vidéo avec ce titre et cette langue, ou cette URL, existe déjà.';
    END;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO video (titre, type, description, date_publication, langue_originale, image, age_minimum)
    VALUES (in_titre, 'film', in_description, in_date_publication, in_langue_originale, in_image,
            COALESCE(in_age_minimum, 0));
    SET out_id_video = LAST_INSERT_ID();

    INSERT INTO film (id_video, duree, url_video)
    VALUES (out_id_video, in_duree, in_url_video);

    CALL p_associer_categories(out_id_video, in_categories);

    COMMIT;
END$$

CREATE PROCEDURE p_ajouter_serie(
    IN  in_titre            VARCHAR(255),
    IN  in_description      VARCHAR(500),
    IN  in_date_publication DATE,
    IN  in_langue_originale VARCHAR(50),
    IN  in_image            VARCHAR(255),
    IN  in_age_minimum      TINYINT UNSIGNED,
    IN  in_categories       VARCHAR(500),
    OUT out_id_video        INT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Une vidéo avec ce titre et cette langue existe déjà.';
    END;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO video (titre, type, description, date_publication, langue_originale, image, age_minimum)
    VALUES (in_titre, 'serie', in_description, in_date_publication, in_langue_originale, in_image,
            COALESCE(in_age_minimum, 0));
    SET out_id_video = LAST_INSERT_ID();

    INSERT INTO serie (id_video) VALUES (out_id_video);

    CALL p_associer_categories(out_id_video, in_categories);

    COMMIT;
END$$

CREATE PROCEDURE p_ajouter_episode(
    IN  in_id_serie         INT UNSIGNED,
    IN  in_numero_saison    TINYINT UNSIGNED,
    IN  in_numero_episode   SMALLINT UNSIGNED,
    IN  in_titre            VARCHAR(255),
    IN  in_description      VARCHAR(500),
    IN  in_duree            SMALLINT UNSIGNED,
    IN  in_url_video        VARCHAR(255),
    IN  in_image_episode    VARCHAR(255),
    OUT out_id_episode      INT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cet épisode existe déjà dans la série, ou son URL est déjà utilisée.';

    IF NOT EXISTS (SELECT 1 FROM serie WHERE id_video = in_id_serie) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La série associée à cet épisode n''existe pas.';
    END IF;

    INSERT INTO episode (id_serie, numero_saison, numero_episode, titre, description,
                         duree, url_video, image_episode)
    VALUES (in_id_serie, in_numero_saison, in_numero_episode, in_titre, in_description,
            in_duree, in_url_video, in_image_episode);
    SET out_id_episode = LAST_INSERT_ID();
END$$

/* Un sous-titre pour un film OU un épisode (l'autre paramètre vaut NULL) */
CREATE PROCEDURE p_ajouter_soustitre(
    IN in_id_film       INT UNSIGNED,
    IN in_id_episode    INT UNSIGNED,
    IN in_langue        VARCHAR(50),
    IN in_url_fichier   VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un sous-titre existe déjà dans cette langue ou avec cette URL.';

    IF (in_id_film IS NULL) = (in_id_episode IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un sous-titre doit concerner soit un film, soit un épisode.';
    END IF;

    IF in_id_film IS NOT NULL AND NOT EXISTS (SELECT 1 FROM film WHERE id_video = in_id_film) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le film associé au sous-titre n''existe pas.';
    END IF;

    IF in_id_episode IS NOT NULL AND NOT EXISTS (SELECT 1 FROM episode WHERE id = in_id_episode) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'L''épisode associé au sous-titre n''existe pas.';
    END IF;

    IF NOT (in_url_fichier LIKE 'http://%' OR in_url_fichier LIKE 'https://%') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'L''URL du fichier de sous-titres doit commencer par http:// ou https://.';
    END IF;

    INSERT INTO soustitre (id_film, id_episode, langue, url_fichier)
    VALUES (in_id_film, in_id_episode, in_langue, in_url_fichier);
END$$

/* Recherche par titre, sans tenir compte des majuscules ni des accents.
   Renvoie toutes les vidéos dont le titre contient le texte (résultat vide si aucune). */
CREATE PROCEDURE p_chercher_video_par_titre(IN in_texte VARCHAR(255))
BEGIN
    SELECT v.id, v.titre, v.type, v.date_publication, v.langue_originale, v.age_minimum,
           GROUP_CONCAT(c.nom ORDER BY c.nom SEPARATOR ', ') AS categories
    FROM video v
    LEFT JOIN video_categorie vc ON vc.id_video = v.id
    LEFT JOIN categorie c ON c.id = vc.id_categorie
    WHERE v.titre LIKE CONCAT('%', in_texte, '%')
    GROUP BY v.id, v.titre, v.type, v.date_publication, v.langue_originale, v.age_minimum
    ORDER BY v.titre;
END$$

/* Les vidéos qu'un profil a le droit de voir, selon son âge */
CREATE PROCEDURE p_catalogue_profil(IN in_id_profil INT UNSIGNED)
BEGIN
    DECLARE v_age INT DEFAULT NULL;
    DECLARE v_existe INT DEFAULT 0;

    SELECT COUNT(*), MAX(age) INTO v_existe, v_age FROM profils WHERE id = in_id_profil;
    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le profil spécifié n''existe pas.';
    END IF;

    SELECT id, titre, type, categories, duree_minutes, age_minimum
    FROM v_catalogue
    WHERE v_age IS NULL OR age_minimum <= v_age
    ORDER BY date_publication DESC;
END$$


/* =====================================================================
   PROCÉDURES : comptes, abonnements, profils
   ===================================================================== */

CREATE PROCEDURE p_creer_utilisateur(
    IN  in_nom              VARCHAR(255),
    IN  in_email            VARCHAR(255),
    IN  in_mot_de_passe     VARCHAR(255),
    OUT out_id_utilisateur  INT UNSIGNED
)
BEGIN
    DECLARE v_sel CHAR(32);
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'L''utilisateur avec cet email existe déjà.';

    IF CHAR_LENGTH(in_mot_de_passe) < 8 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins 8 caractères.';
    END IF;

    SET v_sel = LEFT(SHA2(CONCAT(UUID(), RAND()), 256), 32);

    INSERT INTO utilisateur (nom, email, mot_de_passe_hash, sel)
    VALUES (in_nom, LOWER(TRIM(in_email)), f_hacher_mot_de_passe(v_sel, in_mot_de_passe), v_sel);
    SET out_id_utilisateur = LAST_INSERT_ID();
END$$

/* Souscrit un utilisateur à une offre pour un nombre de mois.
   L'abonnement commence aujourd'hui, ou à la fin de l'abonnement en cours
   s'il y en a un (renouvellement ou changement d'offre). */
CREATE PROCEDURE p_souscrire_abonnement(
    IN  in_id_utilisateur   INT UNSIGNED,
    IN  in_nom_offre        VARCHAR(50),
    IN  in_nb_mois          INT,
    OUT out_id_abonnement   INT UNSIGNED
)
BEGIN
    DECLARE v_id_offre INT UNSIGNED DEFAULT NULL;
    DECLARE v_prix DECIMAL(5,2);
    DECLARE v_debut DATE;
    DECLARE v_derniere_fin DATE;

    IF NOT EXISTS (SELECT 1 FROM utilisateur WHERE id = in_id_utilisateur) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''utilisateur spécifié n''existe pas.';
    END IF;

    IF in_nb_mois IS NULL OR in_nb_mois < 1 OR in_nb_mois > 24 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La durée doit être comprise entre 1 et 24 mois.';
    END IF;

    SELECT MAX(id), MAX(prix_mensuel) INTO v_id_offre, v_prix
    FROM offre
    WHERE nom = in_nom_offre AND disponible;

    IF v_id_offre IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cette offre n''existe pas ou n''est plus disponible.';
    END IF;

    SELECT MAX(date_fin) INTO v_derniere_fin
    FROM abonnement
    WHERE id_utilisateur = in_id_utilisateur;

    IF v_derniere_fin IS NOT NULL AND v_derniere_fin >= CURRENT_DATE THEN
        SET v_debut = v_derniere_fin + INTERVAL 1 DAY;
    ELSE
        SET v_debut = CURRENT_DATE;
    END IF;

    INSERT INTO abonnement (id_utilisateur, id_offre, date_debut, date_fin, prix_mensuel)
    VALUES (in_id_utilisateur, v_id_offre, v_debut,
            v_debut + INTERVAL in_nb_mois MONTH - INTERVAL 1 DAY, v_prix);
    SET out_id_abonnement = LAST_INSERT_ID();
END$$

CREATE PROCEDURE p_ajouter_profil(
    IN  in_id_utilisateur   INT UNSIGNED,
    IN  in_nom              VARCHAR(50),
    IN  in_age              TINYINT UNSIGNED,
    IN  in_avatar           VARCHAR(255),
    OUT out_id_profil       INT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un profil avec ce nom existe déjà pour cet utilisateur.';

    IF NOT EXISTS (SELECT 1 FROM utilisateur WHERE id = in_id_utilisateur) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''utilisateur spécifié n''existe pas.';
    END IF;

    INSERT INTO profils (id_utilisateur, nom, age, avatar)
    VALUES (in_id_utilisateur, in_nom, in_age, in_avatar);
    SET out_id_profil = LAST_INSERT_ID();
END$$


/* =====================================================================
   PROCÉDURES : favoris et visionnages
   ===================================================================== */

CREATE PROCEDURE p_ajouter_favori(IN in_id_profil INT UNSIGNED, IN in_id_video INT UNSIGNED)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ce favori existe déjà.';

    IF NOT EXISTS (SELECT 1 FROM video WHERE id = in_id_video) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La vidéo spécifiée n''existe pas.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM profils WHERE id = in_id_profil) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le profil spécifié n''existe pas.';
    END IF;

    INSERT INTO favoris (id_profil, id_video) VALUES (in_id_profil, in_id_video);
END$$

/* Supprime tous les favoris d'un profil et renvoie le nombre supprimé */
CREATE PROCEDURE p_supprimer_favoris_par_profil(IN in_id_profil INT UNSIGNED, OUT out_nb_supprimes INT)
BEGIN
    DELETE FROM favoris WHERE id_profil = in_id_profil;
    SET out_nb_supprimes = ROW_COUNT();
END$$

/* Tous les favoris de tous les profils d'un utilisateur, en un seul résultat */
CREATE PROCEDURE p_recuperer_favoris_utilisateur(IN in_id_utilisateur INT UNSIGNED)
BEGIN
    SELECT p.nom AS profil, v.id AS id_video, v.titre, v.type,
           GROUP_CONCAT(c.nom ORDER BY c.nom SEPARATOR ', ') AS categories,
           f.date_ajout
    FROM profils p
    JOIN favoris f ON f.id_profil = p.id
    JOIN video v ON v.id = f.id_video
    LEFT JOIN video_categorie vc ON vc.id_video = v.id
    LEFT JOIN categorie c ON c.id = vc.id_categorie
    WHERE p.id_utilisateur = in_id_utilisateur
    GROUP BY p.nom, v.id, v.titre, v.type, f.date_ajout
    ORDER BY p.nom, f.date_ajout DESC;
END$$

/* Enregistre qu'un profil a regardé un film OU un épisode */
CREATE PROCEDURE p_enregistrer_visionnage(
    IN in_id_profil     INT UNSIGNED,
    IN in_id_film       INT UNSIGNED,
    IN in_id_episode    INT UNSIGNED,
    IN in_minutes_vues  SMALLINT UNSIGNED
)
BEGIN
    IF (in_id_film IS NULL) = (in_id_episode IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Un visionnage concerne soit un film, soit un épisode.';
    END IF;

    INSERT INTO visionnage (id_profil, id_film, id_episode, minutes_vues)
    VALUES (in_id_profil, in_id_film, in_id_episode, in_minutes_vues);
END$$


/* =====================================================================
   DÉCLENCHEURS
   ===================================================================== */

/* Le nombre de profils ne peut pas dépasser celui permis par l'offre */
CREATE TRIGGER t_profils_nombre_max
BEFORE INSERT ON profils
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM profils WHERE id_utilisateur = NEW.id_utilisateur)
       >= f_nb_profils_max(NEW.id_utilisateur) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le nombre maximum de profils pour cet abonnement est atteint.';
    END IF;
END$$

/* Deux abonnements d'un même utilisateur ne peuvent pas se chevaucher */
CREATE TRIGGER t_abonnement_sans_chevauchement
BEFORE INSERT ON abonnement
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM abonnement
               WHERE id_utilisateur = NEW.id_utilisateur
                 AND date_debut <= NEW.date_fin
                 AND date_fin >= NEW.date_debut) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cet abonnement chevauche un abonnement existant.';
    END IF;
END$$

/* Une ligne de film doit correspondre à une vidéo de type film */
CREATE TRIGGER t_film_type
BEFORE INSERT ON film
FOR EACH ROW
BEGIN
    IF (SELECT type FROM video WHERE id = NEW.id_video) <> 'film' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cette vidéo n''est pas un film.';
    END IF;
END$$

/* Une ligne de série doit correspondre à une vidéo de type série */
CREATE TRIGGER t_serie_type
BEFORE INSERT ON serie
FOR EACH ROW
BEGIN
    IF (SELECT type FROM video WHERE id = NEW.id_video) <> 'serie' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cette vidéo n''est pas une série.';
    END IF;
END$$

/* On ne transforme pas un film en série (ou l'inverse) après coup */
CREATE TRIGGER t_video_type_fixe
BEFORE UPDATE ON video
FOR EACH ROW
BEGIN
    IF NEW.type <> OLD.type THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le type d''une vidéo ne peut pas être modifié.';
    END IF;
END$$

/* Un profil ne peut pas mettre en favori une vidéo interdite à son âge */
CREATE TRIGGER t_favoris_age
BEFORE INSERT ON favoris
FOR EACH ROW
BEGIN
    IF (SELECT age FROM profils WHERE id = NEW.id_profil)
       < (SELECT age_minimum FROM video WHERE id = NEW.id_video) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cette vidéo n''est pas autorisée pour l''âge de ce profil.';
    END IF;
END$$

/* Un visionnage respecte l'âge du profil et ne dépasse pas la durée de la vidéo */
CREATE TRIGGER t_visionnage_controle
BEFORE INSERT ON visionnage
FOR EACH ROW
BEGIN
    DECLARE v_duree INT;
    DECLARE v_age_minimum INT;

    IF NEW.id_film IS NOT NULL THEN
        SELECT f.duree, v.age_minimum INTO v_duree, v_age_minimum
        FROM film f JOIN video v ON v.id = f.id_video
        WHERE f.id_video = NEW.id_film;
    ELSE
        SELECT e.duree, v.age_minimum INTO v_duree, v_age_minimum
        FROM episode e JOIN video v ON v.id = e.id_serie
        WHERE e.id = NEW.id_episode;
    END IF;

    IF v_duree IS NOT NULL AND NEW.minutes_vues > v_duree THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Le temps de visionnage dépasse la durée de la vidéo.';
    END IF;

    IF (SELECT age FROM profils WHERE id = NEW.id_profil) < v_age_minimum THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cette vidéo n''est pas autorisée pour l''âge de ce profil.';
    END IF;
END$$

DELIMITER ;
