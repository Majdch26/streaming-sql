/* =====================================================================
   Rôles et droits (à exécuter dans la base « streaming »)
   - administrateur : tous les droits sur la base
   - abonne         : consulte le catalogue, gère ses profils et favoris
                      uniquement au travers des procédures
   - invite         : consulte le catalogue
   ===================================================================== */

CREATE ROLE IF NOT EXISTS streaming_administrateur, streaming_abonne, streaming_invite;

GRANT ALL PRIVILEGES ON streaming.* TO streaming_administrateur;

GRANT SELECT ON streaming.v_catalogue TO streaming_invite;
GRANT EXECUTE ON PROCEDURE streaming.p_chercher_video_par_titre TO streaming_invite;

GRANT SELECT ON streaming.v_catalogue TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_chercher_video_par_titre TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_catalogue_profil TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_ajouter_profil TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_ajouter_favori TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_supprimer_favoris_par_profil TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_recuperer_favoris_utilisateur TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_enregistrer_visionnage TO streaming_abonne;
GRANT EXECUTE ON PROCEDURE streaming.p_souscrire_abonnement TO streaming_abonne;

/* Exemple : un compte applicatif qui reçoit le rôle abonné
   CREATE USER 'appli'@'localhost' IDENTIFIED BY 'un-mot-de-passe-solide';
   GRANT streaming_abonne TO 'appli'@'localhost';
   SET DEFAULT ROLE streaming_abonne TO 'appli'@'localhost';    -- MySQL
   SET DEFAULT ROLE streaming_abonne FOR 'appli'@'localhost';   -- MariaDB
*/
