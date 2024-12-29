DELIMITER $

CREATE PROCEDURE p_ajouter_video (
    IN in_titre VARCHAR(255),
    IN in_categorie VARCHAR(255),
    IN in_description VARCHAR(255),
    IN in_date_publication DATE,
    IN in_langue_originale VARCHAR(255),
    IN in_image VARCHAR(255),
    IN in_duree INT,
    IN in_url_video VARCHAR(255),
    IN in_type_video ENUM('film', 'serie', 'episode'),
    IN in_id_serie INT UNSIGNED,
    IN in_numero_episode INT,
    IN in_numero_saison INT,
    IN in_description_episode VARCHAR(255),
    IN in_titre_episode VARCHAR(255),
    IN in_image_episode VARCHAR(255)
)
BEGIN
    DECLARE v_id_video INT UNSIGNED;
    DECLARE v_serie_exist INT;

    /* Insérer la vidéo dans la table video */
    INSERT INTO video (
        titre, categorie, description, date_publication, langue_originale, image
    ) VALUES (
        in_titre, in_categorie, in_description, in_date_publication, in_langue_originale, in_image
    );

    /*Récupérer l'ID généré pour la vidéo */
    SELECT id 
    INTO v_id_video
	FROM video
    WHERE titre = in_titre
	AND langue_originale = in_langue_originale
	ORDER BY id
    LIMIT 1;

    /*Insérer dans la table film, serie ou episode selon le type de vidéo*/
    IF in_type_video = 'film' THEN
        INSERT INTO film (id_video, duree, url_video)
        VALUES (v_id_video, in_duree, in_url_video);

    ELSEIF in_type_video = 'serie' THEN
        INSERT INTO serie (id_video, duree)
        VALUES (v_id_video, in_duree);

    ELSEIF in_type_video = 'episode' THEN
        /*Vérifier si la série existe*/
        SELECT id_video
        INTO v_serie_exist
        FROM serie
        WHERE id_video = in_id_serie
        LIMIT 1;

        /*Si la série existe, insérer l'épisode*/
        IF v_serie_exist IS NOT NULL THEN
            INSERT INTO episode (
                id_serie, numero_episode, numero_saison, url_video, duree, description, titre, image_episode
            ) VALUES (
                in_id_serie, in_numero_episode, in_numero_saison, in_url_video, in_duree, in_description_episode, in_titre_episode, in_image_episode
            );
        ELSE
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'La série associée à cet épisode n''existe pas.';
        END IF;
    END IF;
END;
$
DELIMITER ;



DELIMITER $
CREATE PROCEDURE p_ajouter_soustitre(
    IN in_id_video_film INT UNSIGNED,    /* ID du film auquel le sous-titre est lié */
    IN in_id_episode INT UNSIGNED,       /* ID de l'épisode (si applicable) */
    IN in_langue VARCHAR(50),            /* Langue du sous-titre */
    IN in_url_fichier VARCHAR(255)       /* URL du fichier de sous-titres */
)
BEGIN
    DECLARE v_video_exists INT;
    DECLARE v_episode_exists INT;

    /* Vérifier si le film existe (si p_id_video_film est non NULL) */
    IF in_id_video_film IS NOT NULL THEN
        SELECT COUNT(*) 
        INTO v_video_exists
        FROM film
        WHERE id_video = in_id_video_film;
    ELSE
        SET v_video_exists = 1; /*Si p_id_video_film est NULL, on suppose qu'il n'y a pas de film */
    END IF;

    /* Vérifier si l'épisode existe (si p_id_episode est non NULL) */
    IF in_id_episode IS NOT NULL THEN
        SELECT COUNT(*) 
        INTO v_episode_exists
        FROM episode
        WHERE id = in_id_episode;
    ELSE
        SET v_episode_exists = 1; /*Si p_id_episode est NULL, on suppose qu'il n'y a pas d'épisode*/
    END IF;

    /*Si le film n'existe pas et que p_id_video_film n'est pas NULL, renvoyer une erreur*/
    IF in_id_video_film IS NOT NULL AND v_video_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Le film associé au sous-titre n''existe pas.';
    END IF;

    /*Si l'épisode n'existe pas et que p_id_episode n'est pas NULL, renvoyer une erreur*/
    IF in_id_episode IS NOT NULL AND v_episode_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'L''épisode associé au sous-titre n''existe pas.';
    END IF;

    /*Insérer le sous-titre*/
    INSERT INTO soustitre (id_video_film, id_episode, langue, url_fichier)
    VALUES (in_id_video_film, in_id_episode, in_langue, in_url_fichier);
    
END;
$
DELIMITER ;


DELIMITER $
CREATE PROCEDURE p_ajouter_utilisateur_et_abonnement(
    IN in_nom_abonnement VARCHAR(255),
    IN in_prix DECIMAL(4,2),
    IN in_nb_profile_max INT,
    IN in_date_debut DATE,
    IN in_date_fin DATE,
    IN in_nom_utilisateur VARCHAR(255),
    IN in_email_utilisateur VARCHAR(255),
    IN in_mot_de_passe_utilisateur VARCHAR(255),
    IN in_date_creation DATE,
    IN in_abonnement_actif BOOLEAN
)
BEGIN
    DECLARE v_id_abonnement INT;
    DECLARE v_abonnement_exists INT;
    DECLARE v_user_exists INT;

    /*Vérifier si l'abonnement existe déjà*/
    SELECT id 
    INTO v_id_abonnement
    FROM abonnement
    WHERE nom = in_nom_abonnement;

    IF v_id_abonnement IS NULL THEN
        /*Si l'abonnement n'existe pas, l'ajouter*/
        INSERT INTO abonnement (nom, prix, nb_profile_max, date_debut, date_fin)
        VALUES (in_nom_abonnement, in_prix, in_nb_profile_max, in_date_debut, in_date_fin);

        /*Récupérer l'ID de l'abonnement nouvellement créé*/
        SELECT id 
        INTO v_id_abonnement
        FROM abonnement
        WHERE nom = in_nom_abonnement
        LIMIT 1;
    END IF;

    /*Vérifier si l'utilisateur existe déjà*/
    SELECT COUNT(*) 
    INTO v_user_exists
    FROM utilisateur
    WHERE email = in_email_utilisateur;

    IF v_user_exists > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'L''utilisateur avec cet email existe déjà.';
    END IF;

    /*Ajouter l'utilisateur avec l'abonnement existant ou nouvellement créé*/
    INSERT INTO utilisateur (id_abonnement, nom, email, mot_de_passe, date_creation, abonnement_actif)
    VALUES (v_id_abonnement, in_nom_utilisateur, in_email_utilisateur, in_mot_de_passe_utilisateur, in_date_creation, in_abonnement_actif);
END;
$
DELIMITER ;


DELIMITER $
CREATE PROCEDURE p_ajouter_profil(
    IN in_id_utilisateur INT,
    IN in_nom VARCHAR(255),
    IN in_age INT,
    IN in_avatar VARCHAR(255)
)
BEGIN
    DECLARE v_user_exists INT;

    /*Vérifier si l'utilisateur existe*/
    SELECT COUNT(*) 
    INTO v_user_exists
    FROM utilisateur
    WHERE id = in_id_utilisateur;

    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'L''utilisateur spécifié n''existe pas.';
    END IF;

    /*Ajouter le profil*/
    INSERT INTO profils (id_utilisateur, nom, age, avatar)
    VALUES (in_id_utilisateur, in_nom, in_age, in_avatar);
END ;
$
DELIMITER ;


DELIMITER $
CREATE PROCEDURE p_ajouter_favori(
    IN in_id_profil INT,
    IN in_id_video INT
)
BEGIN
    DECLARE v_video_exists INT;
    DECLARE v_profil_exists INT;
    

    /*Vérifier si la vidéo existe*/
    SELECT COUNT(*) 
    INTO v_video_exists
    FROM video
    WHERE id = in_id_video;

    IF v_video_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La vidéo spécifiée n''existe pas.';
    END IF;

    /*Vérifier si le profil existe*/
    SELECT COUNT(*) 
    INTO v_profil_exists
    FROM profils
    WHERE id = in_id_profil;

    IF v_profil_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Le profil spécifié n''existe pas.';
    END IF;

    

    /*Ajouter le favori*/
    INSERT INTO favoris (id_video, id_profil)
    VALUES (in_id_video, in_id_profil);
END ;
$
DELIMITER ;


DELIMITER $
CREATE PROCEDURE p_supprimer_favoris_par_profil(
    IN in_id_profil INT
)
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_id_favori INT;
    DECLARE FAVORIS_CURSOR CURSOR FOR 
        SELECT id
        FROM favoris
        WHERE id_profil = in_id_profil;

    DECLARE CONTINUE HANDLER 
    FOR NOT FOUND 
    SET v_done = 1;

    OPEN FAVORIS_CURSOR;

    favoris_loop: LOOP
        FETCH FAVORIS_CURSOR
        INTO v_id_favori;
        IF v_done THEN
            LEAVE favoris_loop;
        END IF;

        -- Supprimer chaque favori pour ce profil
        DELETE FROM favoris 
        WHERE id = v_id_favori;
    END LOOP;

    CLOSE FAVORIS_CURSOR;
END ;
$
DELIMITER ;


DELIMITER $
CREATE PROCEDURE p_recuperer_favoris_utilisateur(
    IN in_id_utilisateur INT
)
BEGIN
    DECLARE v_id_favori INT;
    DECLARE v_id_video INT;
    DECLARE v_titre VARCHAR(255);
    DECLARE v_categorie VARCHAR(255);
    DECLARE v_done INT DEFAULT 0;

    /* Déclaration du curseur */
    DECLARE favoris_cursor CURSOR FOR
        SELECT id, id_video
        FROM favoris
        WHERE id_profil IN (
            SELECT id
            FROM profils
            WHERE id_utilisateur = in_id_utilisateur
        );

    DECLARE CONTINUE HANDLER 
    FOR NOT FOUND 
    SET v_done = 1;

    OPEN favoris_cursor;

    /*Afficher tous les favoris*/
    favoris_loop: LOOP
        FETCH favoris_cursor 
        INTO v_id_favori, v_id_video;
        IF v_done THEN
            LEAVE favoris_loop;
        END IF;

        /*Afficher les informations du favori (id_favori, id_video, titre_video, categorie_video)*/
        SELECT v_id_favori AS id_favori, 
               v_id_video AS id_video, 
               titre AS titre_video, 
               categorie AS categorie_video
        FROM video
        WHERE id = v_id_video;
    END LOOP;

    CLOSE favoris_cursor;
END ;
$
DELIMITER ;


DELIMITER $

CREATE PROCEDURE p_chercher_video_par_titre (
    IN in_titre VARCHAR(255)
)
BEGIN
    DECLARE v_id_video INT UNSIGNED;
    DECLARE v_titre VARCHAR(255);
    DECLARE v_categorie VARCHAR(255);
    DECLARE v_date_publication DATE;
    DECLARE v_langue_originale VARCHAR(255);

    /*Récupérer les informations de la vidéo*/
    SELECT 
        id, titre, categorie, date_publication, langue_originale
    INTO 
        v_id_video, v_titre, v_categorie, v_date_publication, v_langue_originale
    FROM video
    WHERE titre = in_titre
    LIMIT 1;

    /*Si la vidéo existe, afficher les informations de la vidéo*/
    IF v_id_video IS NOT NULL THEN
        SELECT 
            v_id_video AS id_video,
            v_titre AS titre,
            v_categorie,
            v_date_publication,
            v_langue_originale;
    ELSE
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Vidéo non trouvée avec ce titre.';
    END IF;
END;
$
DELIMITER ;


DELIMITER $

CREATE FUNCTION f_nombre_episodes(
    in_id_serie INT
) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_nombre_episodes INT DEFAULT 0;
    DECLARE v_serie_exists INT DEFAULT 0;

    /*Vérifier si la série existe dans la table 'episode'*/
    SELECT COUNT(*) 
    INTO v_serie_exists
    FROM episode
    WHERE id_serie = in_id_serie;

    /*Si la série n'existe pas, retourner -1*/
    IF v_serie_exists = 0 THEN
        RETURN -1;
    END IF;

    /*Calcul du nombre d'épisodes pour une série donnée*/
    SELECT COUNT(*)
    INTO v_nombre_episodes
    FROM episode
    WHERE id_serie = in_id_serie;

    /*Retourner le nombre d'épisodes*/
    RETURN v_nombre_episodes;
END ;
$
DELIMITER ;


DELIMITER $

CREATE FUNCTION f_duree_totale(
	in_id_video INT, 
    in_is_film BOOLEAN
) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_duree_totale INT DEFAULT 0;
    DECLARE v_existe INT DEFAULT 0;

    /*Vérifier si le film ou la série existe*/
    IF in_is_film THEN
        SELECT COUNT(*) 
        INTO v_existe
        FROM film
        WHERE id_video = in_id_video;

        /*Si le film n'existe pas, retourner -1*/
        IF v_existe = 0 THEN
            RETURN -1;
        END IF;

        /*Récupérer la durée du film*/
        SELECT duree 
        INTO v_duree_totale
        FROM film
        WHERE id_video = in_id_video;
    ELSE
        SELECT COUNT(*) 
        INTO v_existe
        FROM episode
        WHERE id_serie = in_id_video;

        /*Si la série n'existe pas, retourner -1*/
        IF v_existe = 0 THEN
            RETURN -1;
        END IF;

        /*Calculer la durée totale des épisodes de la série*/
        SELECT SUM(duree) 
        INTO v_duree_totale
        FROM episode
        WHERE id_serie = in_id_video;
    END IF;

    /*Retourner la durée totale*/
    RETURN v_duree_totale;
END ;
$
DELIMITER ;


DELIMITER $

CREATE FUNCTION f_get_utilisateur_par_email(
	in_email VARCHAR(255)
) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_id_utilisateur INT DEFAULT -1;

    DECLARE CONTINUE HANDLER FOR NOT FOUND 
        SET v_id_utilisateur = -1;

    /*Sélectionner l'ID de l'utilisateur par son email*/
    SELECT id 
    INTO v_id_utilisateur
    FROM utilisateur
    WHERE email = in_email;

    /*Retourner l'ID de l'utilisateur (ou -1 si non trouvé)*/
    RETURN v_id_utilisateur;
END ;
$
DELIMITER ;


DELIMITER $

CREATE FUNCTION f_abonnement_actif(
	in_id_utilisateur INT
)
RETURNS TINYINT
DETERMINISTIC
BEGIN
    DECLARE abonnement_en_cours TINYINT DEFAULT 0;
    DECLARE v_utilisateur_existe INT DEFAULT 0;

	/*Gestion des erreurs : si aucun abonnement n'est trouvé*/
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET abonnement_en_cours = 0;
	
    /*Vérification si l'utilisateur existe*/
    SELECT COUNT(*) 
    INTO v_utilisateur_existe
    FROM utilisateur
    WHERE id = in_id_utilisateur;

    /*Si l'utilisateur n'existe pas, retourner -1*/
    IF v_utilisateur_existe = 0 THEN
        RETURN -1;
    END IF;
    
    /*Vérifier si l'utilisateur a un abonnement actif*/
    SELECT IF(date_fin > CURRENT_DATE, 1, 0) 
    INTO abonnement_en_cours
    FROM abonnement
    WHERE id = (SELECT id_abonnement FROM utilisateur WHERE id = in_id_utilisateur);

    /*Mettre à jour la colonne 'abonnement_actif' dans la table utilisateur*/
    UPDATE utilisateur
    SET abonnement_actif = abonnement_en_cours
    WHERE id = in_id_utilisateur;

    /*Retourner la valeur de l'abonnement actif (1 pour actif, 0 pour inactif)*/
    RETURN abonnement_en_cours;
END ;
$
DELIMITER ;


DELIMITER $

CREATE FUNCTION f_verifier_connexion (
	in_user_email VARCHAR(255), 
	in_user_mot_de_passe VARCHAR(255)
) 
RETURNS VARCHAR(255) 
DETERMINISTIC
BEGIN
    DECLARE message VARCHAR(255);
    DECLARE v_mot_de_passe VARCHAR(255);

    /*Vérifier si l'email existe*/
    SELECT mot_de_passe 
    INTO v_mot_de_passe
    FROM utilisateur
    WHERE email = in_user_email
    LIMIT 1;

    /*Si l'email n'existe pas*/
    IF v_mot_de_passe IS NULL THEN
        SET message = 'Email incorrect';
    /*Si le mot de passe est incorrect*/
    ELSEIF v_mot_de_passe != in_user_mot_de_passe THEN
        SET message = 'Mot de passe incorrect';
    /*Si l'email et le mot de passe sont corrects*/
    ELSE
        SET message = 'Mot de passe correct';
    END IF;

    RETURN message;
END ;
$
DELIMITER ;


DELIMITER $
CREATE TRIGGER verif_max_profils
BEFORE INSERT ON profils
FOR EACH ROW
BEGIN
    DECLARE v_nb_profiles INT;
    DECLARE v_nb_max_profiles INT;
    DECLARE v_id_abonnement INT;
    DECLARE v_profile_exists INT;
    
	/*Vérifier si le profil existe déjà pour cet utilisateur*/
    SELECT COUNT(*) 
    INTO v_profile_exists
    FROM profils
    WHERE id_utilisateur = NEW.id_utilisateur
    AND nom = NEW.nom;

    IF v_profile_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un profil avec ce nom existe déjà pour cet utilisateur.';
    END IF;
    
    /*Obtenir le nombre de profils existants pour l'utilisateur*/
    SELECT COUNT(*) 
    INTO v_nb_profiles
    FROM profils
    WHERE id_utilisateur = NEW.id_utilisateur;

    /*Obtenir l'ID de l'abonnement de l'utilisateur*/
    SELECT id_abonnement 
    INTO v_id_abonnement
    FROM utilisateur
    WHERE id = NEW.id_utilisateur;

    /*Obtenir le nombre maximum de profils autorisés pour cet abonnement*/
    SELECT nb_profile_max 
    INTO v_nb_max_profiles
    FROM abonnement
    WHERE id = v_id_abonnement;

    /*Vérifier si le nombre maximum est atteint*/
    IF v_nb_profiles >= v_nb_max_profiles THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Le nombre maximum de profils pour cet utilisateur est atteint.';
    END IF;
END ;
$
DELIMITER ;


DELIMITER $
CREATE TRIGGER verifier_doublon_favoris
BEFORE INSERT ON favoris
FOR EACH ROW
BEGIN
    DECLARE v_favori_existe INT;

    /*Vérifier si le favori existe déjà*/
    SELECT COUNT(*) 
    INTO v_favori_existe
    FROM favoris
    WHERE id_video = NEW.id_video AND id_profil = NEW.id_profil;

    IF v_favori_existe > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ce favori existe déjà.';
    END IF;
    
END;
$
DELIMITER ;


DELIMITER $

CREATE TRIGGER t_verifier_titre_video
BEFORE INSERT ON video
FOR EACH ROW
BEGIN
    DECLARE v_video_count INT;

    /*Vérifier s'il existe déjà une vidéo avec le même titre et la même langue*/
    SELECT COUNT(*)
    INTO v_video_count
    FROM video
    WHERE titre = NEW.titre
    AND langue_originale = NEW.langue_originale;

    /*Si une vidéo avec le même titre et la même langue existe, lever une erreur*/
    IF v_video_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Une vidéo avec ce titre et cette langue existe déjà.';
    END IF;
END;
$
DELIMITER ;

DELIMITER $

CREATE TRIGGER t_verifier_url_soustitre
BEFORE INSERT ON soustitre
FOR EACH ROW
BEGIN
    /*Vérifier si l'URL commence par "http://" ou "https://"*/
    IF NOT (NEW.url_fichier LIKE 'http%' AND (NEW.url_fichier LIKE 'http://%' OR NEW.url_fichier LIKE 'https://%')) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L\'URL du fichier de sous-titres n\'est pas valide. Elle doit commencer par "http://" ou "https://".';
    END IF;
END;
$
DELIMITER ;

CALL p_ajouter_video(
    'Inception',                   /* titre */
    'Science Fiction, Thriller',   /* categorie */
    'Un voleur qui vole des secrets à travers le subconscient.', /* description */
    '2010-07-16',                  /* date_publication */
    'Anglais',                     /* langue_originale */
    'inception.jpg',               /* image */
    148,                           /* duree (en minutes) */
    'https://www.example.com/inception', /* url_video */
    'film',                        /* type_video */
    NULL,                          /* id_serie (pas utilisé pour un film) */
    NULL,                          /* numero_episode (pas utilisé pour un film) */
    NULL,                          /* numero_saison (pas utilisé pour un film) */
    NULL,                          /* description_episode (pas utilisé pour un film) */
    NULL,                          /* titre_episode (pas utilisé pour un film) */
    NULL                           /* image_episode (pas utilisé pour un film) */
);

CALL p_ajouter_video(
    'Breaking Bad',                /* titre */
    'Drame, Crime',                /* categorie */
    'Un professeur de chimie se transforme en baron de la drogue.', /* description */
    '2008-01-20',                  /* date_publication */
    'Anglais',                     /* langue_originale */
    'breaking_bad.jpg',            /* image */
    60,                            /* duree (durée moyenne des épisodes en minutes) */
    NULL,                          /* url_video (pas utilisé pour une série) */
    'serie',                       /* type_video */
    NULL,                          /* id_serie (pas utilisé pour une série) */
    NULL,                          /* numero_episode (pas utilisé pour une série) */
    NULL,                          /* numero_saison (pas utilisé pour une série) */
    NULL,                          /* description_episode (pas utilisé pour une série) */
    NULL,                          /* titre_episode (pas utilisé pour une série) */
    NULL                           /* image_episode (pas utilisé pour une série) */
);

CALL p_ajouter_video(
    'Pilot',                       /* titre */
    'Drame, Crime',                /* categorie */
    'Le premier épisode de la série où Walter White commence son voyage criminel.', /* description */
    '2008-01-20',                  /* date_publication */
    'Anglais',                     /* langue_originale */
    'breaking_bad_pilot.jpg',      /* image */
    58,                            /* duree (en minutes) */
    'https://www.example.com/breaking_bad_pilot', /* url_video */
    'episode',                     /* type_video */
    2,                             /* id_serie (ID de la série) */
    1,                             /* numero_episode (numéro de l'épisode dans la saison) */
    1,                             /* numero_saison (numéro de la saison) */
    'Le premier épisode de Breaking Bad.', /* description_episode */
    'Pilot',                       /* titre_episode */
    'breaking_bad_pilot_image.jpg' /* image_episode */
);

CALL p_ajouter_video(
    'Cat''s in the Bag...',        /* titre */
    'Drame, Crime',                /* categorie */
    'Walter et Jesse font face aux conséquences de leur premier deal.', /* description */
    '2008-01-27',                  /* date_publication */
    'Anglais',                     /* langue_originale */
    'cats_in_the_bag.jpg',         /* image */
    48,                            /* duree (en minutes) */
    'https://www.example.com/cats_in_the_bag', /* p_url_video */
    'episode',                     /* type_video */
    2,                             /* id_serie (ID de la série) */
    2,                             /* numero_episode (numéro de l'épisode dans la saison) */
    1,                             /* numero_saison (numéro de la saison) */
    'Le deuxième épisode de Breaking Bad.', /* description_episode */
    'Cat''s in the Bag...',        /* titre_episode */
    'cats_in_the_bag_image.jpg'    /* image_episode */
);

CALL p_ajouter_soustitre(1, NULL, 'Anglais', 'https://www.example.com/inception_en.srt');
CALL p_ajouter_soustitre(NULL, 1, 'Anglais', 'https://www.example.com/breaking_bad_pilot_en.srt');

CALL p_ajouter_utilisateur_et_abonnement(
    'Basic',                     /* p_nom_abonnement */
    9.99,                        /* p_prix */
    2,                           /* p_nb_profile_max */
    '2024-12-26',
    '2025-12-26',
    'Bob Martin',                /* p_nom_utilisateur */
    'bob.martin@example.com',    /* p_email_utilisateur */
    'mypassword',                /* p_mot_de_passe_utilisateur */
    '2024-12-26',                /* p_date_creation */
    TRUE                         /* p_abonnement_actif */
);

CALL p_ajouter_profil(1, 'Profil1', 25, 'avatar1.png');
CALL p_ajouter_profil(1, 'Profil2', 18, 'avatar2.png');

CALL p_ajouter_favori(1, 2);
CALL p_ajouter_favori(1, 3);
CALL p_ajouter_favori(1, 4);

CALL P_recuperer_favoris_utilisateur(1);
CALL p_supprimer_favoris_par_profil(1);

CALL p_chercher_video_par_titre('Breaking Bad');
CALL p_chercher_video_par_titre('Inception');

SELECT f_nombre_episodes(2) AS nombre_episodes;
SELECT f_nombre_episodes(99) AS nombre_episodes;
SELECT f_duree_totale(1, TRUE);
SELECT f_duree_totale(2, FALSE);
SELECT f_abonnement_actif(1);
SELECT f_abonnement_actif(99);
SELECT f_get_utilisateur_par_email('bob.martin@example.com');