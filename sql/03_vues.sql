/* =====================================================================
   Vues : ce que l'application et les analyses lisent
   ===================================================================== */

SET NAMES utf8mb4;

/* Catalogue complet : une ligne par film ou série, avec ses catégories,
   sa durée, son nombre de saisons et d'épisodes, et sa popularité */
CREATE OR REPLACE VIEW v_catalogue AS
SELECT v.id,
       v.titre,
       v.type,
       (SELECT GROUP_CONCAT(c.nom ORDER BY c.nom SEPARATOR ', ')
          FROM video_categorie vc JOIN categorie c ON c.id = vc.id_categorie
         WHERE vc.id_video = v.id) AS categories,
       v.date_publication,
       v.langue_originale,
       v.age_minimum,
       CASE v.type
           WHEN 'film' THEN f.duree
           ELSE (SELECT COALESCE(SUM(e.duree), 0) FROM episode e WHERE e.id_serie = v.id)
       END AS duree_minutes,
       CASE v.type
           WHEN 'serie' THEN (SELECT COUNT(DISTINCT e.numero_saison) FROM episode e WHERE e.id_serie = v.id)
       END AS nb_saisons,
       CASE v.type
           WHEN 'serie' THEN (SELECT COUNT(*) FROM episode e WHERE e.id_serie = v.id)
       END AS nb_episodes,
       (SELECT COUNT(*) FROM favoris fa WHERE fa.id_video = v.id) AS nb_favoris
FROM video v
LEFT JOIN film f ON f.id_video = v.id;

/* Utilisateurs avec leur abonnement en cours (sans les mots de passe) */
CREATE OR REPLACE VIEW v_utilisateurs AS
SELECT u.id,
       u.nom,
       u.email,
       u.date_creation,
       o.nom AS offre_en_cours,
       a.date_fin AS fin_abonnement,
       a.id IS NOT NULL AS abonnement_actif,
       (SELECT COUNT(*) FROM profils p WHERE p.id_utilisateur = u.id) AS nb_profils
FROM utilisateur u
LEFT JOIN abonnement a ON a.id_utilisateur = u.id
                      AND CURRENT_DATE BETWEEN a.date_debut AND a.date_fin
LEFT JOIN offre o ON o.id = a.id_offre;

/* Pour chaque offre : abonnés actifs, revenu mensuel et chiffre d'affaires total */
CREATE OR REPLACE VIEW v_statistiques_offres AS
SELECT o.nom AS offre,
       o.prix_mensuel,
       COUNT(DISTINCT CASE WHEN CURRENT_DATE BETWEEN a.date_debut AND a.date_fin
                           THEN a.id_utilisateur END) AS abonnes_actifs,
       COALESCE(SUM(CASE WHEN CURRENT_DATE BETWEEN a.date_debut AND a.date_fin
                         THEN a.prix_mensuel END), 0) AS revenu_mensuel,
       COALESCE(SUM(a.prix_mensuel * (TIMESTAMPDIFF(MONTH, a.date_debut, a.date_fin) + 1)), 0)
           AS chiffre_affaires_total
FROM offre o
LEFT JOIN abonnement a ON a.id_offre = o.id
GROUP BY o.id, o.nom, o.prix_mensuel;

/* Popularité des vidéos : spectateurs distincts, minutes regardées, favoris */
CREATE OR REPLACE VIEW v_popularite_videos AS
SELECT v.id,
       v.titre,
       v.type,
       COUNT(DISTINCT vi.id_profil) AS spectateurs,
       COALESCE(SUM(vi.minutes_vues), 0) AS minutes_regardees,
       (SELECT COUNT(*) FROM favoris fa WHERE fa.id_video = v.id) AS nb_favoris
FROM video v
LEFT JOIN episode e ON e.id_serie = v.id
LEFT JOIN visionnage vi ON vi.id_film = v.id OR vi.id_episode = e.id
GROUP BY v.id, v.titre, v.type;
