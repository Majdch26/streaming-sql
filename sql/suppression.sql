/* Supprime tous les objets de la base (dans l'ordre des dépendances) */

DROP VIEW IF EXISTS v_popularite_videos, v_statistiques_offres, v_utilisateurs, v_catalogue;

DROP PROCEDURE IF EXISTS p_associer_categories;
DROP PROCEDURE IF EXISTS p_ajouter_film;
DROP PROCEDURE IF EXISTS p_ajouter_serie;
DROP PROCEDURE IF EXISTS p_ajouter_episode;
DROP PROCEDURE IF EXISTS p_ajouter_soustitre;
DROP PROCEDURE IF EXISTS p_chercher_video_par_titre;
DROP PROCEDURE IF EXISTS p_catalogue_profil;
DROP PROCEDURE IF EXISTS p_creer_utilisateur;
DROP PROCEDURE IF EXISTS p_souscrire_abonnement;
DROP PROCEDURE IF EXISTS p_ajouter_profil;
DROP PROCEDURE IF EXISTS p_ajouter_favori;
DROP PROCEDURE IF EXISTS p_supprimer_favoris_par_profil;
DROP PROCEDURE IF EXISTS p_recuperer_favoris_utilisateur;
DROP PROCEDURE IF EXISTS p_enregistrer_visionnage;

/* Les déclencheurs sont supprimés avec leurs tables */
DROP TABLE IF EXISTS visionnage, favoris, profils, abonnement, utilisateur, offre,
                     soustitre, episode, serie, film, video_categorie, video, categorie;

DROP FUNCTION IF EXISTS f_hacher_mot_de_passe;
DROP FUNCTION IF EXISTS f_verifier_connexion;
DROP FUNCTION IF EXISTS f_get_utilisateur_par_email;
DROP FUNCTION IF EXISTS f_abonnement_actif;
DROP FUNCTION IF EXISTS f_nb_profils_max;
DROP FUNCTION IF EXISTS f_nombre_episodes;
DROP FUNCTION IF EXISTS f_duree_totale;
