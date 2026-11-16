/* =====================================================================
   Tests automatiques (base vide : 01_schema + 02_objets + 03_vues)
   Lancer avec : ./tests/lancer_tests.sh
   ===================================================================== */

SET NAMES utf8mb4;

CREATE TABLE resultat_test (
    num     INT AUTO_INCREMENT PRIMARY KEY,
    nom     VARCHAR(200) NOT NULL,
    reussi  BOOLEAN NOT NULL,
    detail  VARCHAR(500) NOT NULL DEFAULT ''
);

/* Les vérifications s'écrivent :
     INSERT INTO resultat_test (nom, reussi) SELECT 'description', condition;
   (et non par un CALL : MariaDB 10.11 plante quand un argument de CALL contient EXISTS) */

DELIMITER $$

/* Exécute une requête et vérifie qu'elle échoue avec un message contenant le texte attendu */
CREATE PROCEDURE verifier_erreur(IN in_nom VARCHAR(200), IN in_requete TEXT, IN in_attendu VARCHAR(200))
BEGIN
    DECLARE v_message TEXT DEFAULT NULL;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        GET DIAGNOSTICS CONDITION 1 v_message = MESSAGE_TEXT;

    SET @requete_test = in_requete;
    PREPARE requete FROM @requete_test;
    EXECUTE requete;
    DEALLOCATE PREPARE requete;

    INSERT INTO resultat_test (nom, reussi, detail)
    VALUES (in_nom,
            v_message IS NOT NULL AND v_message LIKE CONCAT('%', in_attendu, '%'),
            LEFT(COALESCE(v_message, 'aucune erreur'), 500));
END$$

DELIMITER ;


/* ---------------------------------------------------------------------
   Catalogue : films, séries, épisodes, catégories
   --------------------------------------------------------------------- */

CALL p_ajouter_film('Inception', 'Un voleur de rêves.', '2010-07-16', 'Anglais', 'i.jpg', 12,
                    'Science-fiction, Thriller', 148, 'https://e.com/inception', @inception);
INSERT INTO resultat_test (nom, reussi) SELECT 'ajout film : identifiant renvoyé', COALESCE(@inception IS NOT NULL, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'ajout film : type film', COALESCE((SELECT type FROM video WHERE id = @inception) = 'film', FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'ajout film : ligne dans film', COALESCE((SELECT duree FROM film WHERE id_video = @inception) = 148, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'ajout film : 2 catégories créées', COALESCE((SELECT COUNT(*) FROM categorie) = 2, FALSE);

CALL p_ajouter_film('Parasite', 'Deux familles.', '2019-06-05', 'Coréen', 'p.jpg', 16,
                    ' Drame, , Thriller ,', 132, 'https://e.com/parasite', @parasite);
INSERT INTO resultat_test (nom, reussi) SELECT 'catégories : espaces et vides ignorés, Thriller réutilisée', COALESCE((SELECT COUNT(*) FROM categorie) = 3
              AND (SELECT COUNT(*) FROM video_categorie WHERE id_video = @parasite) = 2, FALSE);

CALL verifier_erreur('film en double (titre + langue) refusé',
    'CALL p_ajouter_film(''Inception'', ''x'', ''2010-01-01'', ''Anglais'', ''x.jpg'', 0, NULL, 100, ''https://e.com/autre'', @x)',
    'existe déjà');
CALL verifier_erreur('URL de film en double refusée',
    'CALL p_ajouter_film(''Nouveau film'', ''x'', ''2020-01-01'', ''Anglais'', ''x.jpg'', 0, ''Drame'', 100, ''https://e.com/inception'', @x)',
    'existe déjà');
INSERT INTO resultat_test (nom, reussi) SELECT 'erreur : la transaction est annulée (aucune vidéo orpheline)', COALESCE((SELECT COUNT(*) FROM video) = 2 AND NOT EXISTS (SELECT 1 FROM video WHERE titre = 'Nouveau film'), FALSE);
CALL verifier_erreur('durée de film nulle refusée',
    'CALL p_ajouter_film(''Film vide'', ''x'', ''2020-01-01'', ''Français'', ''x.jpg'', 0, NULL, 0, ''https://e.com/vide'', @x)',
    'chk_film_duree');
INSERT INTO resultat_test (nom, reussi) SELECT 'durée nulle : rien n''est inséré', COALESCE(NOT EXISTS (SELECT 1 FROM video WHERE titre = 'Film vide'), FALSE);
CALL verifier_erreur('âge minimum invalide refusé',
    'CALL p_ajouter_film(''Film 7 ans'', ''x'', ''2020-01-01'', ''Français'', ''x.jpg'', 7, NULL, 90, ''https://e.com/7'', @x)',
    'chk_video_age_minimum');

CALL p_ajouter_film('Inception', 'Version française.', '2010-07-21', 'Français', 'i.jpg', 12,
                    NULL, 148, 'https://e.com/inception-vf', @inception_vf);
INSERT INTO resultat_test (nom, reussi) SELECT 'même titre dans une autre langue accepté', COALESCE(@inception_vf IS NOT NULL, FALSE);

CALL p_ajouter_serie('Breaking Bad', 'Un professeur de chimie.', '2008-01-20', 'Anglais', 'bb.jpg', 16,
                     'Drame', @bb);
CALL p_ajouter_serie('The Office', 'Un bureau.', '2005-03-24', 'Anglais', 'o.jpg', 0, 'Comédie', @office);
CALL p_ajouter_serie('Série vide', 'Pas encore d''épisode.', '2026-01-01', 'Français', 'v.jpg', 0, NULL, @vide);
INSERT INTO resultat_test (nom, reussi) SELECT 'ajout série : type serie + ligne dans serie', COALESCE((SELECT type FROM video WHERE id = @bb) = 'serie'
              AND EXISTS (SELECT 1 FROM serie WHERE id_video = @bb), FALSE);

SET @nb_videos = (SELECT COUNT(*) FROM video);
CALL p_ajouter_episode(@bb, 1, 1, 'Pilot', 'Diagnostic.', 58, 'https://e.com/bb/1-1', 'e.jpg', @bb_1_1);
CALL p_ajouter_episode(@bb, 1, 2, 'Cat''s in the Bag...', 'Suite.', 48, 'https://e.com/bb/1-2', 'e.jpg', @bb_1_2);
CALL p_ajouter_episode(@bb, 2, 1, 'Seven Thirty-Seven', 'Saison 2.', 47, 'https://e.com/bb/2-1', 'e.jpg', @bb_2_1);
INSERT INTO resultat_test (nom, reussi) SELECT 'les épisodes ne sont plus ajoutés dans la table video', COALESCE((SELECT COUNT(*) FROM video) = @nb_videos, FALSE);

CALL p_ajouter_episode(@office, 1, 1, 'Pilot', 'Premier jour.', 23, 'https://e.com/office/1-1', 'e.jpg', @office_1_1);
INSERT INTO resultat_test (nom, reussi) SELECT 'deux séries peuvent avoir un épisode « Pilot »', COALESCE(@office_1_1 IS NOT NULL, FALSE);

CALL verifier_erreur('épisode d''une série inexistante refusé',
    'CALL p_ajouter_episode(9999, 1, 1, ''x'', ''x'', 30, ''https://e.com/x'', ''x.jpg'', @x)',
    'n''existe pas');
CALL verifier_erreur('épisode rattaché à un film refusé',
    CONCAT('CALL p_ajouter_episode(', @inception, ', 1, 1, ''x'', ''x'', 30, ''https://e.com/x'', ''x.jpg'', @x)'),
    'n''existe pas');
CALL verifier_erreur('épisode en double (même saison et numéro) refusé',
    CONCAT('CALL p_ajouter_episode(', @bb, ', 1, 1, ''Autre'', ''x'', 30, ''https://e.com/bb/doublon'', ''x.jpg'', @x)'),
    'existe déjà');
CALL verifier_erreur('saison 0 refusée',
    CONCAT('CALL p_ajouter_episode(', @bb, ', 0, 9, ''x'', ''x'', 30, ''https://e.com/bb/0'', ''x.jpg'', @x)'),
    'chk_episode_numero_saison');

INSERT INTO resultat_test (nom, reussi) SELECT 'f_nombre_episodes : série avec 3 épisodes', COALESCE(f_nombre_episodes(@bb) = 3, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_nombre_episodes : série sans épisode = 0', COALESCE(f_nombre_episodes(@vide) = 0, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_nombre_episodes : un film = -1', COALESCE(f_nombre_episodes(@inception) = -1, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_nombre_episodes : identifiant inconnu = -1', COALESCE(f_nombre_episodes(9999) = -1, FALSE);

INSERT INTO resultat_test (nom, reussi) SELECT 'f_duree_totale : film', COALESCE(f_duree_totale(@inception) = 148, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_duree_totale : série = somme des épisodes', COALESCE(f_duree_totale(@bb) = 58 + 48 + 47, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_duree_totale : série vide = 0', COALESCE(f_duree_totale(@vide) = 0, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_duree_totale : identifiant inconnu = -1', COALESCE(f_duree_totale(9999) = -1, FALSE);

CALL verifier_erreur('déclencheur : une série ne peut pas devenir un film',
    CONCAT('INSERT INTO film (id_video, duree, url_video) VALUES (', @bb, ', 50, ''https://e.com/triche'')'),
    'pas un film');
CALL verifier_erreur('déclencheur : un film ne peut pas devenir une série',
    CONCAT('INSERT INTO serie (id_video) VALUES (', @inception, ')'),
    'pas une série');
CALL verifier_erreur('déclencheur : le type d''une vidéo est figé',
    CONCAT('UPDATE video SET type = ''serie'' WHERE id = ', @inception),
    'ne peut pas être modifié');

INSERT INTO resultat_test (nom, reussi) SELECT 'recherche insensible aux majuscules et aux accents', COALESCE((SELECT COUNT(*) FROM video WHERE titre LIKE '%breaking%') = 1
              AND (SELECT COUNT(*) FROM video WHERE titre LIKE '%serie vide%') = 1, FALSE);
CALL verifier_erreur('p_chercher_video_par_titre sans résultat : pas d''erreur',
    'CALL p_chercher_video_par_titre(''titre introuvable'')', 'ZZZ');
UPDATE resultat_test SET reussi = (detail = 'aucune erreur') WHERE nom LIKE 'p_chercher_video_par_titre sans%';


/* ---------------------------------------------------------------------
   Sous-titres
   --------------------------------------------------------------------- */

CALL p_ajouter_soustitre(@inception, NULL, 'Français', 'https://e.com/st/inception_fr.srt');
CALL p_ajouter_soustitre(NULL, @bb_1_1, 'Français', 'https://e.com/st/bb_1_1_fr.srt');
INSERT INTO resultat_test (nom, reussi) SELECT 'sous-titres ajoutés pour un film et un épisode', COALESCE((SELECT COUNT(*) FROM soustitre) = 2, FALSE);

CALL verifier_erreur('sous-titre sans film ni épisode refusé',
    'CALL p_ajouter_soustitre(NULL, NULL, ''Français'', ''https://e.com/st/rien.srt'')', 'soit un film');
CALL verifier_erreur('sous-titre pour un film ET un épisode refusé',
    CONCAT('CALL p_ajouter_soustitre(', @inception, ', ', @bb_1_1, ', ''Anglais'', ''https://e.com/st/deux.srt'')'),
    'soit un film');
CALL verifier_erreur('sous-titre avec une URL ftp refusé',
    CONCAT('CALL p_ajouter_soustitre(', @inception, ', NULL, ''Anglais'', ''ftp://e.com/st.srt'')'), 'http');
CALL verifier_erreur('sous-titre pour un film inexistant refusé',
    'CALL p_ajouter_soustitre(9999, NULL, ''Anglais'', ''https://e.com/st/x.srt'')', 'n''existe pas');
CALL verifier_erreur('deux sous-titres dans la même langue refusés',
    CONCAT('CALL p_ajouter_soustitre(', @inception, ', NULL, ''Français'', ''https://e.com/st/autre.srt'')'),
    'existe déjà');
CALL verifier_erreur('contrainte CHECK : URL invalide refusée même sans la procédure',
    CONCAT('INSERT INTO soustitre (id_film, langue, url_fichier) VALUES (', @inception, ', ''Italien'', ''fichier.srt'')'),
    'chk_soustitre_url');


/* ---------------------------------------------------------------------
   Utilisateurs et connexion
   --------------------------------------------------------------------- */

CALL p_creer_utilisateur('Bob Martin', '  Bob.Martin@Example.com ', 'MotDePasse123', @bob);
CALL p_creer_utilisateur('Alice', 'alice@example.com', 'MotDePasse123', @alice);
CALL p_creer_utilisateur('Nadia', 'nadia@example.com', 'UnAutreMotDePasse', @nadia);

INSERT INTO resultat_test (nom, reussi) SELECT 'email enregistré en minuscules et sans espaces', COALESCE((SELECT email FROM utilisateur WHERE id = @bob) = 'bob.martin@example.com', FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'mot de passe jamais stocké en clair', COALESCE(NOT EXISTS (SELECT 1 FROM utilisateur WHERE mot_de_passe_hash LIKE '%MotDePasse%')
              AND (SELECT CHAR_LENGTH(mot_de_passe_hash) FROM utilisateur WHERE id = @bob) = 64, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'même mot de passe, empreintes différentes (sel)', COALESCE((SELECT mot_de_passe_hash FROM utilisateur WHERE id = @bob)
              <> (SELECT mot_de_passe_hash FROM utilisateur WHERE id = @alice), FALSE);

INSERT INTO resultat_test (nom, reussi) SELECT 'connexion : bon mot de passe', COALESCE(f_verifier_connexion('bob.martin@example.com', 'MotDePasse123') = 1, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'connexion : mauvais mot de passe', COALESCE(f_verifier_connexion('bob.martin@example.com', 'motdepasse123') = 0, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'connexion : email inconnu', COALESCE(f_verifier_connexion('inconnu@example.com', 'MotDePasse123') = 0, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'connexion : le mot de passe d''un autre compte ne marche pas', COALESCE(f_verifier_connexion('nadia@example.com', 'MotDePasse123') = 0, FALSE);

CALL verifier_erreur('mot de passe trop court refusé',
    'CALL p_creer_utilisateur(''X'', ''x@example.com'', ''court'', @x)', '8 caractères');
CALL verifier_erreur('email déjà utilisé refusé (majuscules comprises)',
    'CALL p_creer_utilisateur(''Bob 2'', ''BOB.MARTIN@example.com'', ''MotDePasse123'', @x)', 'existe déjà');
CALL verifier_erreur('email mal formé refusé',
    'CALL p_creer_utilisateur(''X'', ''pas-un-email'', ''MotDePasse123'', @x)', 'chk_utilisateur_email');

INSERT INTO resultat_test (nom, reussi) SELECT 'f_get_utilisateur_par_email : trouvé', COALESCE(f_get_utilisateur_par_email('alice@example.com') = @alice, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_get_utilisateur_par_email : inconnu = -1', COALESCE(f_get_utilisateur_par_email('x@example.com') = -1, FALSE);


/* ---------------------------------------------------------------------
   Offres et abonnements
   --------------------------------------------------------------------- */

INSERT INTO offre (nom, prix_mensuel, nb_profils_max, qualite_max, disponible) VALUES
    ('Essentiel', 7.99, 1, 'HD', TRUE),
    ('Standard', 13.49, 2, 'HD', TRUE),
    ('Ancienne', 4.99, 1, 'SD', FALSE);

INSERT INTO resultat_test (nom, reussi) SELECT 'f_abonnement_actif : sans abonnement = 0', COALESCE(f_abonnement_actif(@bob) = 0, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_abonnement_actif : utilisateur inconnu = -1', COALESCE(f_abonnement_actif(9999) = -1, FALSE);

CALL p_souscrire_abonnement(@bob, 'Standard', 12, @ab1);
INSERT INTO resultat_test (nom, reussi) SELECT 'souscription : commence aujourd''hui, dure 12 mois', COALESCE((SELECT date_debut = CURRENT_DATE
                      AND date_fin = CURRENT_DATE + INTERVAL 12 MONTH - INTERVAL 1 DAY
               FROM abonnement WHERE id = @ab1), FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'souscription : prix de l''offre recopié', COALESCE((SELECT prix_mensuel FROM abonnement WHERE id = @ab1) = 13.49, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'f_abonnement_actif : avec abonnement = 1', COALESCE(f_abonnement_actif(@bob) = 1, FALSE);

CALL p_souscrire_abonnement(@bob, 'Essentiel', 1, @ab2);
INSERT INTO resultat_test (nom, reussi) SELECT 'renouvellement : commence le lendemain de la fin du précédent', COALESCE((SELECT date_debut FROM abonnement WHERE id = @ab2)
              = (SELECT date_fin FROM abonnement WHERE id = @ab1) + INTERVAL 1 DAY, FALSE);

UPDATE offre SET prix_mensuel = 14.99 WHERE nom = 'Standard';
INSERT INTO resultat_test (nom, reussi) SELECT 'changement de prix : les abonnements en cours gardent leur prix', COALESCE((SELECT prix_mensuel FROM abonnement WHERE id = @ab1) = 13.49, FALSE);

CALL verifier_erreur('offre inconnue refusée',
    CONCAT('CALL p_souscrire_abonnement(', @alice, ', ''Gratuite'', 1, @x)'), 'n''existe pas');
CALL verifier_erreur('offre qui n''est plus disponible refusée',
    CONCAT('CALL p_souscrire_abonnement(', @alice, ', ''Ancienne'', 1, @x)'), 'plus disponible');
CALL verifier_erreur('durée de 0 mois refusée',
    CONCAT('CALL p_souscrire_abonnement(', @alice, ', ''Essentiel'', 0, @x)'), 'entre 1 et 24');
CALL verifier_erreur('abonnement pour un utilisateur inconnu refusé',
    'CALL p_souscrire_abonnement(9999, ''Essentiel'', 1, @x)', 'n''existe pas');
CALL verifier_erreur('déclencheur : abonnements qui se chevauchent refusés',
    CONCAT('INSERT INTO abonnement (id_utilisateur, id_offre, date_debut, date_fin, prix_mensuel) ',
           'SELECT ', @bob, ', id, CURRENT_DATE + INTERVAL 1 MONTH, CURRENT_DATE + INTERVAL 2 MONTH, 7.99 ',
           'FROM offre WHERE nom = ''Essentiel'''),
    'chevauche');

INSERT INTO abonnement (id_utilisateur, id_offre, date_debut, date_fin, prix_mensuel)
SELECT @nadia, id, CURRENT_DATE - INTERVAL 3 MONTH, CURRENT_DATE - INTERVAL 1 DAY, 7.99
FROM offre WHERE nom = 'Essentiel';
INSERT INTO resultat_test (nom, reussi) SELECT 'abonnement terminé hier : plus actif', COALESCE(f_abonnement_actif(@nadia) = 0, FALSE);


/* ---------------------------------------------------------------------
   Profils
   --------------------------------------------------------------------- */

CALL p_ajouter_profil(@alice, 'Alice', 30, NULL, @p_alice);
CALL verifier_erreur('sans abonnement : un seul profil autorisé',
    CONCAT('CALL p_ajouter_profil(', @alice, ', ''Second'', 20, NULL, @x)'), 'maximum');

CALL p_ajouter_profil(@bob, 'Bob', 38, 'a.png', @p_bob);
CALL p_ajouter_profil(@bob, 'Lucas', 8, 'b.png', @p_lucas);
INSERT INTO resultat_test (nom, reussi) SELECT 'offre Standard : 2 profils acceptés', COALESCE((SELECT COUNT(*) FROM profils WHERE id_utilisateur = @bob) = 2, FALSE);
CALL verifier_erreur('offre Standard : 3e profil refusé',
    CONCAT('CALL p_ajouter_profil(', @bob, ', ''Emma'', 14, NULL, @x)'), 'maximum');
INSERT INTO offre (nom, prix_mensuel, nb_profils_max) VALUES ('Famille', 19.99, 4);
CALL p_souscrire_abonnement(@nadia, 'Famille', 1, @x);
CALL p_ajouter_profil(@nadia, 'Nadia', 25, NULL, @p_nadia);
CALL verifier_erreur('deux profils du même nom refusés',
    CONCAT('CALL p_ajouter_profil(', @nadia, ', ''Nadia'', 40, NULL, @x)'), 'existe déjà');
CALL verifier_erreur('profil pour un utilisateur inconnu refusé',
    'CALL p_ajouter_profil(9999, ''X'', 20, NULL, @x)', 'n''existe pas');
CALL verifier_erreur('âge supérieur à 120 refusé',
    CONCAT('CALL p_ajouter_profil(', @nadia, ', ''Doyen'', 121, NULL, @x)'), 'chk_profils_age');


/* ---------------------------------------------------------------------
   Favoris
   --------------------------------------------------------------------- */

CALL p_ajouter_favori(@p_bob, @inception);
CALL p_ajouter_favori(@p_bob, @bb);
CALL p_ajouter_favori(@p_lucas, @office);
INSERT INTO resultat_test (nom, reussi) SELECT 'favoris ajoutés', COALESCE((SELECT COUNT(*) FROM favoris) = 3, FALSE);

CALL verifier_erreur('favori en double refusé',
    CONCAT('CALL p_ajouter_favori(', @p_bob, ', ', @inception, ')'), 'existe déjà');
CALL verifier_erreur('favori sur une vidéo inexistante refusé',
    CONCAT('CALL p_ajouter_favori(', @p_bob, ', 9999)'), 'vidéo spécifiée n''existe pas');
CALL verifier_erreur('favori pour un profil inexistant refusé',
    CONCAT('CALL p_ajouter_favori(9999, ', @inception, ')'), 'profil spécifié n''existe pas');
CALL verifier_erreur('un enfant de 8 ans ne peut pas ajouter une série 16+',
    CONCAT('CALL p_ajouter_favori(', @p_lucas, ', ', @bb, ')'), 'âge');

CALL p_supprimer_favoris_par_profil(@p_bob, @nb_supprimes);
INSERT INTO resultat_test (nom, reussi) SELECT 'suppression des favoris d''un profil : nombre renvoyé', COALESCE(@nb_supprimes = 2, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'suppression : les favoris des autres profils sont gardés', COALESCE((SELECT COUNT(*) FROM favoris) = 1 AND EXISTS (SELECT 1 FROM favoris WHERE id_profil = @p_lucas), FALSE);


/* ---------------------------------------------------------------------
   Visionnages
   --------------------------------------------------------------------- */

CALL p_enregistrer_visionnage(@p_bob, @inception, NULL, 120);
CALL p_enregistrer_visionnage(@p_bob, NULL, @bb_1_1, 58);
INSERT INTO resultat_test (nom, reussi) SELECT 'visionnages enregistrés', COALESCE((SELECT COUNT(*) FROM visionnage) = 2, FALSE);

CALL verifier_erreur('visionnage plus long que le film refusé',
    CONCAT('CALL p_enregistrer_visionnage(', @p_bob, ', ', @inception, ', NULL, 200)'), 'dépasse');
CALL verifier_erreur('visionnage sans film ni épisode refusé',
    CONCAT('CALL p_enregistrer_visionnage(', @p_bob, ', NULL, NULL, 10)'), 'soit un film');
CALL verifier_erreur('un enfant de 8 ans ne peut pas regarder un épisode 16+',
    CONCAT('CALL p_enregistrer_visionnage(', @p_lucas, ', NULL, ', @bb_1_1, ', 10)'), 'âge');


/* ---------------------------------------------------------------------
   Vues
   --------------------------------------------------------------------- */

INSERT INTO resultat_test (nom, reussi) SELECT 'v_catalogue : durée, saisons et épisodes d''une série', COALESCE((SELECT duree_minutes = 153 AND nb_saisons = 2 AND nb_episodes = 3
                 FROM v_catalogue WHERE id = @bb), FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'v_catalogue : catégories regroupées', COALESCE((SELECT categories FROM v_catalogue WHERE id = @inception) = 'Science-fiction, Thriller', FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'v_utilisateurs : offre en cours et abonnement actif', COALESCE((SELECT offre_en_cours = 'Standard' AND abonnement_actif = 1 FROM v_utilisateurs WHERE id = @bob), FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'v_utilisateurs : pas de colonne mot de passe', COALESCE(NOT EXISTS (SELECT 1 FROM information_schema.columns
                           WHERE table_schema = DATABASE() AND table_name = 'v_utilisateurs'
                             AND column_name LIKE '%passe%'), FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'v_statistiques_offres : revenu mensuel de l''offre Standard', COALESCE((SELECT revenu_mensuel FROM v_statistiques_offres WHERE offre = 'Standard') = 13.49, FALSE);
INSERT INTO resultat_test (nom, reussi) SELECT 'v_popularite_videos : minutes d''une série = somme de ses épisodes', COALESCE((SELECT minutes_regardees FROM v_popularite_videos WHERE id = @bb) = 58, FALSE);


/* ---------------------------------------------------------------------
   Suppressions en cascade
   --------------------------------------------------------------------- */

DELETE FROM video WHERE id = @bb;
INSERT INTO resultat_test (nom, reussi) SELECT 'supprimer une série supprime ses épisodes, sous-titres et visionnages', COALESCE(NOT EXISTS (SELECT 1 FROM episode WHERE id_serie = @bb)
              AND NOT EXISTS (SELECT 1 FROM soustitre WHERE id_episode = @bb_1_1)
              AND NOT EXISTS (SELECT 1 FROM visionnage WHERE id_episode = @bb_1_1), FALSE);

DELETE FROM utilisateur WHERE id = @bob;
INSERT INTO resultat_test (nom, reussi) SELECT 'supprimer un utilisateur supprime ses abonnements, profils et visionnages', COALESCE(NOT EXISTS (SELECT 1 FROM abonnement WHERE id_utilisateur = @bob)
              AND NOT EXISTS (SELECT 1 FROM profils WHERE id_utilisateur = @bob)
              AND NOT EXISTS (SELECT 1 FROM visionnage WHERE id_profil = @p_bob), FALSE);

CALL verifier_erreur('une offre utilisée par des abonnements ne peut pas être supprimée',
    'DELETE FROM offre WHERE nom = ''Essentiel''', 'foreign key');


/* ---------------------------------------------------------------------
   Bilan
   --------------------------------------------------------------------- */

SELECT num, nom, detail FROM resultat_test WHERE NOT reussi ORDER BY num;
SELECT CONCAT(SUM(reussi), ' / ', COUNT(*), ' tests réussis') AS bilan FROM resultat_test;
