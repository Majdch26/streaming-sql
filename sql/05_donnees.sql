/* =====================================================================
   Jeu de données de démonstration
   Les dates sont relatives à aujourd'hui : les abonnements de démo
   restent valides quel que soit le jour où le script est lancé.
   ===================================================================== */

SET NAMES utf8mb4;

/* ---------- Offres ---------- */
INSERT INTO offre (nom, prix_mensuel, nb_profils_max, qualite_max, disponible) VALUES
    ('Essentiel', 7.99, 1, 'HD', TRUE),
    ('Standard', 13.49, 2, 'HD', TRUE),
    ('Premium', 19.99, 4, '4K', TRUE),
    ('Découverte', 4.99, 1, 'SD', FALSE);

/* ---------- Films ---------- */
CALL p_ajouter_film('Inception', 'Un voleur infiltre les rêves de ses cibles pour y dérober leurs secrets.',
    '2010-07-16', 'Anglais', 'inception.jpg', 12, 'Science-fiction, Thriller', 148,
    'https://cdn.example.com/films/inception.mp4', @inception);
CALL p_ajouter_film('Le Fabuleux Destin d''Amélie Poulain', 'Une serveuse de Montmartre décide de changer la vie des gens qui l''entourent.',
    '2001-04-25', 'Français', 'amelie.jpg', 0, 'Comédie, Romance', 122,
    'https://cdn.example.com/films/amelie.mp4', @amelie);
CALL p_ajouter_film('Intouchables', 'Un aristocrate tétraplégique engage un jeune de banlieue comme aide à domicile.',
    '2011-11-02', 'Français', 'intouchables.jpg', 0, 'Comédie, Drame', 112,
    'https://cdn.example.com/films/intouchables.mp4', @intouchables);
CALL p_ajouter_film('Parasite', 'Une famille pauvre s''infiltre peu à peu au service d''une famille riche.',
    '2019-06-05', 'Coréen', 'parasite.jpg', 16, 'Thriller, Drame', 132,
    'https://cdn.example.com/films/parasite.mp4', @parasite);
CALL p_ajouter_film('Le Voyage de Chihiro', 'Une fillette se retrouve prisonnière d''un monde peuplé d''esprits.',
    '2001-07-20', 'Japonais', 'chihiro.jpg', 0, 'Animation, Fantastique', 125,
    'https://cdn.example.com/films/chihiro.mp4', @chihiro);
CALL p_ajouter_film('Interstellar', 'Des astronautes traversent un trou de ver pour trouver une nouvelle planète habitable.',
    '2014-11-05', 'Anglais', 'interstellar.jpg', 10, 'Science-fiction, Drame', 169,
    'https://cdn.example.com/films/interstellar.mp4', @interstellar);
CALL p_ajouter_film('La Haine', 'Vingt-quatre heures dans la vie de trois amis de banlieue après une nuit d''émeutes.',
    '1995-05-31', 'Français', 'la_haine.jpg', 12, 'Drame, Policier', 98,
    'https://cdn.example.com/films/la_haine.mp4', @haine);
CALL p_ajouter_film('Coco', 'Un garçon passionné de musique se retrouve au pays des morts.',
    '2017-11-29', 'Anglais', 'coco.jpg', 0, 'Animation, Famille', 105,
    'https://cdn.example.com/films/coco.mp4', @coco);
CALL p_ajouter_film('The Dark Knight', 'Batman affronte le Joker, qui sème le chaos à Gotham.',
    '2008-08-13', 'Anglais', 'dark_knight.jpg', 12, 'Action, Policier', 152,
    'https://cdn.example.com/films/dark_knight.mp4', @dark_knight);
CALL p_ajouter_film('Mad Max: Fury Road', 'Dans un désert post-apocalyptique, une course-poursuite pour échapper à un tyran.',
    '2015-05-14', 'Anglais', 'mad_max.jpg', 16, 'Action, Science-fiction', 120,
    'https://cdn.example.com/films/mad_max.mp4', @mad_max);

/* ---------- Séries et épisodes ---------- */
CALL p_ajouter_serie('Breaking Bad', 'Un professeur de chimie devient fabricant de drogue.',
    '2008-01-20', 'Anglais', 'breaking_bad.jpg', 16, 'Drame, Policier', @bb);
UPDATE serie SET terminee = TRUE WHERE id_video = @bb;
CALL p_ajouter_episode(@bb, 1, 1, 'Pilot', 'Walter White apprend qu''il est gravement malade.', 58,
    'https://cdn.example.com/series/bb/s1e1.mp4', 'bb_s1e1.jpg', @bb_s1e1);
CALL p_ajouter_episode(@bb, 1, 2, 'Cat''s in the Bag...', 'Walter et Jesse doivent faire disparaître les preuves.', 48,
    'https://cdn.example.com/series/bb/s1e2.mp4', 'bb_s1e2.jpg', @bb_s1e2);
CALL p_ajouter_episode(@bb, 1, 3, '...And the Bag''s in the River', 'Walter hésite sur le sort de leur prisonnier.', 48,
    'https://cdn.example.com/series/bb/s1e3.mp4', 'bb_s1e3.jpg', @bb_s1e3);
CALL p_ajouter_episode(@bb, 2, 1, 'Seven Thirty-Seven', 'Walter et Jesse craignent la réaction de leur distributeur.', 47,
    'https://cdn.example.com/series/bb/s2e1.mp4', 'bb_s2e1.jpg', @bb_s2e1);
CALL p_ajouter_episode(@bb, 2, 2, 'Grilled', 'Une journée de captivité dans le désert.', 46,
    'https://cdn.example.com/series/bb/s2e2.mp4', 'bb_s2e2.jpg', @bb_s2e2);

CALL p_ajouter_serie('Dark', 'Des disparitions d''enfants révèlent les secrets de quatre familles d''une petite ville.',
    '2017-12-01', 'Allemand', 'dark.jpg', 16, 'Science-fiction, Thriller', @dark);
UPDATE serie SET terminee = TRUE WHERE id_video = @dark;
CALL p_ajouter_episode(@dark, 1, 1, 'Secrets', 'Un garçon disparaît dans la forêt de Winden.', 52,
    'https://cdn.example.com/series/dark/s1e1.mp4', 'dark_s1e1.jpg', @dark_s1e1);
CALL p_ajouter_episode(@dark, 1, 2, 'Lies', 'Jonas découvre un passage dans les grottes.', 44,
    'https://cdn.example.com/series/dark/s1e2.mp4', 'dark_s1e2.jpg', @dark_s1e2);
CALL p_ajouter_episode(@dark, 1, 3, 'Past and Present', 'Le passé de la ville refait surface.', 45,
    'https://cdn.example.com/series/dark/s1e3.mp4', 'dark_s1e3.jpg', @dark_s1e3);

CALL p_ajouter_serie('Lupin', 'Un homme s''inspire d''Arsène Lupin pour venger son père.',
    '2021-01-08', 'Français', 'lupin.jpg', 12, 'Policier, Action', @lupin);
CALL p_ajouter_episode(@lupin, 1, 1, 'Chapitre 1', 'Un vol audacieux au musée du Louvre.', 47,
    'https://cdn.example.com/series/lupin/s1e1.mp4', 'lupin_s1e1.jpg', @lupin_s1e1);
CALL p_ajouter_episode(@lupin, 1, 2, 'Chapitre 2', 'Assane remonte la piste des responsables.', 43,
    'https://cdn.example.com/series/lupin/s1e2.mp4', 'lupin_s1e2.jpg', @lupin_s1e2);
CALL p_ajouter_episode(@lupin, 1, 3, 'Chapitre 3', 'Une évasion de prison minutieusement préparée.', 45,
    'https://cdn.example.com/series/lupin/s1e3.mp4', 'lupin_s1e3.jpg', @lupin_s1e3);

CALL p_ajouter_serie('Arcane', 'Deux sœurs se retrouvent dans des camps opposés entre deux villes rivales.',
    '2021-11-06', 'Anglais', 'arcane.jpg', 12, 'Animation, Action', @arcane);
CALL p_ajouter_episode(@arcane, 1, 1, 'Welcome to the Playground', 'Quatre orphelins tentent un cambriolage.', 39,
    'https://cdn.example.com/series/arcane/s1e1.mp4', 'arcane_s1e1.jpg', @arcane_s1e1);
CALL p_ajouter_episode(@arcane, 1, 2, 'Some Mysteries Are Better Left Unsolved', 'Un jeune inventeur fait une découverte dangereuse.', 40,
    'https://cdn.example.com/series/arcane/s1e2.mp4', 'arcane_s1e2.jpg', @arcane_s1e2);

/* ---------- Sous-titres ---------- */
CALL p_ajouter_soustitre(@inception, NULL, 'Français', 'https://cdn.example.com/st/inception_fr.srt');
CALL p_ajouter_soustitre(@inception, NULL, 'Anglais', 'https://cdn.example.com/st/inception_en.srt');
CALL p_ajouter_soustitre(@parasite, NULL, 'Français', 'https://cdn.example.com/st/parasite_fr.srt');
CALL p_ajouter_soustitre(@chihiro, NULL, 'Français', 'https://cdn.example.com/st/chihiro_fr.srt');
CALL p_ajouter_soustitre(NULL, @bb_s1e1, 'Français', 'https://cdn.example.com/st/bb_s1e1_fr.srt');
CALL p_ajouter_soustitre(NULL, @dark_s1e1, 'Français', 'https://cdn.example.com/st/dark_s1e1_fr.srt');
CALL p_ajouter_soustitre(NULL, @lupin_s1e1, 'Anglais', 'https://cdn.example.com/st/lupin_s1e1_en.srt');

/* ---------- Utilisateurs, abonnements, profils ---------- */
CALL p_creer_utilisateur('Bob Martin', 'bob.martin@example.com', 'MotDePasse!2024', @bob);
CALL p_creer_utilisateur('Léa Dubois', 'lea.dubois@example.com', 'Soleil-et-Lune-42', @lea);
CALL p_creer_utilisateur('Karim Benali', 'karim.benali@example.com', 'CafeCroissant99', @karim);
CALL p_creer_utilisateur('Sophie Laurent', 'sophie.laurent@example.com', 'Montagne#Bleue7', @sophie);
CALL p_creer_utilisateur('Hugo Petit', 'hugo.petit@example.com', 'VeloRouge2025', @hugo);
CALL p_creer_utilisateur('Inès Moreau', 'ines.moreau@example.com', 'Plage&Sable33', @ines);
CALL p_creer_utilisateur('Thomas Girard', 'thomas.girard@example.com', 'AncienClient01', @thomas);
CALL p_creer_utilisateur('Nadia Haddad', 'nadia.haddad@example.com', 'SansAbonnement8', @nadia);

/* Abonnements passés (historique), insérés avec leurs dates réelles */
INSERT INTO abonnement (id_utilisateur, id_offre, date_debut, date_fin, prix_mensuel)
SELECT @bob, id, CURRENT_DATE - INTERVAL 9 MONTH, CURRENT_DATE - INTERVAL 6 MONTH - INTERVAL 1 DAY, 12.99
FROM offre WHERE nom = 'Standard';
INSERT INTO abonnement (id_utilisateur, id_offre, date_debut, date_fin, prix_mensuel)
SELECT @bob, id, CURRENT_DATE - INTERVAL 6 MONTH, CURRENT_DATE - INTERVAL 1 MONTH - INTERVAL 1 DAY, 12.99
FROM offre WHERE nom = 'Standard';
INSERT INTO abonnement (id_utilisateur, id_offre, date_debut, date_fin, prix_mensuel)
SELECT @thomas, id, CURRENT_DATE - INTERVAL 8 MONTH, CURRENT_DATE - INTERVAL 2 MONTH - INTERVAL 1 DAY, 4.99
FROM offre WHERE nom = 'Découverte';
INSERT INTO abonnement (id_utilisateur, id_offre, date_debut, date_fin, prix_mensuel)
SELECT @lea, id, CURRENT_DATE - INTERVAL 4 MONTH, CURRENT_DATE - INTERVAL 1 DAY, 7.99
FROM offre WHERE nom = 'Essentiel';

/* Abonnements en cours */
CALL p_souscrire_abonnement(@bob, 'Premium', 12, @a);
CALL p_souscrire_abonnement(@lea, 'Standard', 6, @a);
CALL p_souscrire_abonnement(@karim, 'Essentiel', 1, @a);
CALL p_souscrire_abonnement(@sophie, 'Premium', 12, @a);
CALL p_souscrire_abonnement(@hugo, 'Standard', 3, @a);
CALL p_souscrire_abonnement(@ines, 'Essentiel', 6, @a);

CALL p_ajouter_profil(@bob, 'Bob', 38, 'avatar1.png', @p_bob);
CALL p_ajouter_profil(@bob, 'Emma', 14, 'avatar2.png', @p_emma);
CALL p_ajouter_profil(@bob, 'Lucas', 8, 'avatar3.png', @p_lucas);
CALL p_ajouter_profil(@lea, 'Léa', 27, 'avatar4.png', @p_lea);
CALL p_ajouter_profil(@lea, 'Maxime', 29, 'avatar5.png', @p_maxime);
CALL p_ajouter_profil(@karim, 'Karim', 22, 'avatar1.png', @p_karim);
CALL p_ajouter_profil(@sophie, 'Sophie', 45, 'avatar2.png', @p_sophie);
CALL p_ajouter_profil(@sophie, 'Jules', 17, 'avatar3.png', @p_jules);
CALL p_ajouter_profil(@sophie, 'Chloé', 11, 'avatar4.png', @p_chloe);
CALL p_ajouter_profil(@hugo, 'Hugo', 31, 'avatar5.png', @p_hugo);
CALL p_ajouter_profil(@ines, 'Inès', 24, 'avatar1.png', @p_ines);
CALL p_ajouter_profil(@thomas, 'Thomas', 52, 'avatar2.png', @p_thomas);

/* ---------- Favoris ---------- */
CALL p_ajouter_favori(@p_bob, @inception);
CALL p_ajouter_favori(@p_bob, @bb);
CALL p_ajouter_favori(@p_bob, @dark_knight);
CALL p_ajouter_favori(@p_emma, @arcane);
CALL p_ajouter_favori(@p_emma, @lupin);
CALL p_ajouter_favori(@p_lucas, @coco);
CALL p_ajouter_favori(@p_lucas, @chihiro);
CALL p_ajouter_favori(@p_lea, @amelie);
CALL p_ajouter_favori(@p_lea, @parasite);
CALL p_ajouter_favori(@p_lea, @dark);
CALL p_ajouter_favori(@p_maxime, @bb);
CALL p_ajouter_favori(@p_karim, @inception);
CALL p_ajouter_favori(@p_karim, @interstellar);
CALL p_ajouter_favori(@p_sophie, @intouchables);
CALL p_ajouter_favori(@p_sophie, @lupin);
CALL p_ajouter_favori(@p_jules, @mad_max);
CALL p_ajouter_favori(@p_chloe, @chihiro);
CALL p_ajouter_favori(@p_hugo, @dark);
CALL p_ajouter_favori(@p_hugo, @bb);
CALL p_ajouter_favori(@p_ines, @amelie);

/* ---------- Historique de visionnage ----------
   Généré de façon déterministe sur les 90 derniers jours, en respectant
   l'âge de chaque profil (les mêmes données sur MySQL et MariaDB). */
DROP PROCEDURE IF EXISTS p_generer_visionnages;
DELIMITER $$
CREATE PROCEDURE p_generer_visionnages(IN in_nb INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_nb_profils INT;
    DECLARE v_nb_contenus INT;
    DECLARE v_profil INT UNSIGNED;
    DECLARE v_age INT;
    DECLARE v_film INT UNSIGNED;
    DECLARE v_episode INT UNSIGNED;
    DECLARE v_duree INT;
    DECLARE v_age_min INT;

    DROP TEMPORARY TABLE IF EXISTS tmp_contenu;
    CREATE TEMPORARY TABLE tmp_contenu (
        num INT PRIMARY KEY, id_film INT UNSIGNED, id_episode INT UNSIGNED, duree INT, age_minimum INT);
    INSERT INTO tmp_contenu
    SELECT ROW_NUMBER() OVER (ORDER BY c.id_film, c.id_episode) - 1, c.id_film, c.id_episode, c.duree, c.age_minimum
    FROM (SELECT f.id_video AS id_film, NULL AS id_episode, f.duree, v.age_minimum
            FROM film f JOIN video v ON v.id = f.id_video
          UNION ALL
          SELECT NULL, e.id, e.duree, v.age_minimum
            FROM episode e JOIN video v ON v.id = e.id_serie) c;

    SELECT COUNT(*) INTO v_nb_profils FROM profils;
    SELECT COUNT(*) INTO v_nb_contenus FROM tmp_contenu;

    WHILE i < in_nb DO
        SELECT id, COALESCE(age, 99) INTO v_profil, v_age
        FROM (SELECT id, age, ROW_NUMBER() OVER (ORDER BY id) - 1 AS n FROM profils) p
        WHERE n = MOD(i * 7 + i DIV 3, v_nb_profils);

        SELECT id_film, id_episode, duree, age_minimum INTO v_film, v_episode, v_duree, v_age_min
        FROM tmp_contenu WHERE num = MOD(i * 13 + i DIV 5, v_nb_contenus);

        IF v_age >= v_age_min THEN
            INSERT INTO visionnage (id_profil, id_film, id_episode, date_visionnage, minutes_vues)
            VALUES (v_profil, v_film, v_episode,
                    NOW() - INTERVAL MOD(i * 37, 90) DAY - INTERVAL MOD(i * 53, 600) MINUTE,
                    GREATEST(5, v_duree - MOD(i * 11, v_duree)));
        END IF;
        SET i = i + 1;
    END WHILE;

    DROP TEMPORARY TABLE tmp_contenu;
END$$
DELIMITER ;

CALL p_generer_visionnages(600);
DROP PROCEDURE p_generer_visionnages;
