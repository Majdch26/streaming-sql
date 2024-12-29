DROP TABLE IF EXISTS favoris;
DROP TABLE IF EXISTS profils;
DROP TABLE IF EXISTS utilisateur;
DROP TABLE IF EXISTS abonnement;
DROP TABLE IF EXISTS soustitre;
DROP TABLE IF EXISTS episode;
DROP TABLE IF EXISTS serie;
DROP TABLE IF EXISTS film;
DROP TABLE IF EXISTS video;

DROP PROCEDURE IF EXISTS p_ajouter_video;
DROP PROCEDURE IF EXISTS p_ajouter_soustitre;
DROP PROCEDURE IF EXISTS p_ajouter_utilisateur_et_abonnement;
DROP PROCEDURE IF EXISTS p_ajouter_profil;
DROP PROCEDURE IF EXISTS p_ajouter_favori;
DROP PROCEDURE IF EXISTS p_supprimer_favoris_par_profil;
DROP PROCEDURE IF EXISTS p_recuperer_favoris_utilisateur;
DROP PROCEDURE IF EXISTS p_chercher_video_par_titre;

DROP FUNCTION IF EXISTS f_nombre_episodes;
DROP FUNCTION IF EXISTS f_duree_totale;
DROP FUNCTION IF EXISTS f_get_utilisateur_par_email;
DROP FUNCTION IF EXISTS f_abonnement_actif;
DROP FUNCTION IF EXISTS f_verifier_connexion;