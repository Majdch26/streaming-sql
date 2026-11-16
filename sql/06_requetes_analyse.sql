/* =====================================================================
   Requêtes d'analyse (à lancer après 05_donnees.sql)
   Agrégations, jointures, sous-requêtes et fonctions de fenêtrage
   ===================================================================== */

SET NAMES utf8mb4;

/* 1. Les 3 vidéos les plus regardées de chaque catégorie (en minutes) */
SELECT categorie, rang, titre, minutes_regardees
FROM (
    SELECT c.nom AS categorie,
           p.titre,
           p.minutes_regardees,
           RANK() OVER (PARTITION BY c.id ORDER BY p.minutes_regardees DESC) AS rang
    FROM v_popularite_videos p
    JOIN video_categorie vc ON vc.id_video = p.id
    JOIN categorie c ON c.id = vc.id_categorie
) classement
WHERE rang <= 3
ORDER BY categorie, rang;

/* 2. Activité par semaine : visionnages, spectateurs distincts, heures regardées */
SELECT YEARWEEK(date_visionnage, 3) AS semaine,
       MIN(DATE(date_visionnage)) AS premier_jour,
       COUNT(*) AS visionnages,
       COUNT(DISTINCT id_profil) AS spectateurs,
       ROUND(SUM(minutes_vues) / 60, 1) AS heures
FROM visionnage
GROUP BY YEARWEEK(date_visionnage, 3)
ORDER BY semaine;

/* 3. Taux de complétion moyen par film (minutes vues / durée du film) */
SELECT v.titre,
       COUNT(*) AS visionnages,
       ROUND(100 * AVG(vi.minutes_vues / f.duree), 1) AS taux_completion_pct,
       ROUND(100 * AVG(vi.minutes_vues >= 0.9 * f.duree), 1) AS vus_en_entier_pct
FROM visionnage vi
JOIN film f ON f.id_video = vi.id_film
JOIN video v ON v.id = f.id_video
GROUP BY v.id, v.titre
ORDER BY taux_completion_pct DESC;

/* 4. Pour chaque série : combien de spectateurs ont commencé la saison 1
      et combien sont allés jusqu'au dernier épisode disponible */
SELECT v.titre,
       COUNT(DISTINCT CASE WHEN e.numero_saison = 1 AND e.numero_episode = 1 THEN vi.id_profil END)
           AS ont_commence,
       COUNT(DISTINCT CASE WHEN e.id = dernier.id THEN vi.id_profil END) AS dernier_episode_vu
FROM video v
JOIN episode e ON e.id_serie = v.id
JOIN (SELECT e1.id_serie, e1.id
        FROM episode e1
       WHERE NOT EXISTS (SELECT 1 FROM episode e2
                          WHERE e2.id_serie = e1.id_serie
                            AND (e2.numero_saison, e2.numero_episode) > (e1.numero_saison, e1.numero_episode))
     ) dernier ON dernier.id_serie = v.id
LEFT JOIN visionnage vi ON vi.id_episode = e.id
GROUP BY v.id, v.titre
ORDER BY v.titre;

/* 5. Temps passé par tranche d'âge des profils */
SELECT CASE
           WHEN p.age IS NULL THEN 'non renseigné'
           WHEN p.age < 13 THEN 'moins de 13 ans'
           WHEN p.age < 18 THEN '13 - 17 ans'
           WHEN p.age < 30 THEN '18 - 29 ans'
           WHEN p.age < 50 THEN '30 - 49 ans'
           ELSE '50 ans et plus'
       END AS tranche_age,
       COUNT(DISTINCT p.id) AS profils,
       ROUND(SUM(vi.minutes_vues) / 60, 1) AS heures,
       ROUND(SUM(vi.minutes_vues) / 60 / COUNT(DISTINCT p.id), 1) AS heures_par_profil
FROM profils p
JOIN visionnage vi ON vi.id_profil = p.id
GROUP BY tranche_age
ORDER BY MIN(COALESCE(p.age, 999));

/* 6. Revenu par offre et part de chaque offre dans le revenu mensuel */
SELECT offre,
       abonnes_actifs,
       revenu_mensuel,
       ROUND(100 * revenu_mensuel / SUM(revenu_mensuel) OVER (), 1) AS part_revenu_pct,
       chiffre_affaires_total
FROM v_statistiques_offres
ORDER BY revenu_mensuel DESC;

/* 7. Utilisateurs dont l'abonnement se termine dans les 30 prochains jours
      sans renouvellement prévu (à relancer) */
SELECT u.nom, u.email, o.nom AS offre, a.date_fin,
       DATEDIFF(a.date_fin, CURRENT_DATE) AS jours_restants
FROM abonnement a
JOIN utilisateur u ON u.id = a.id_utilisateur
JOIN offre o ON o.id = a.id_offre
WHERE CURRENT_DATE BETWEEN a.date_debut AND a.date_fin
  AND a.date_fin < CURRENT_DATE + INTERVAL 30 DAY
  AND NOT EXISTS (SELECT 1 FROM abonnement suivant
                   WHERE suivant.id_utilisateur = a.id_utilisateur
                     AND suivant.date_debut > a.date_fin)
ORDER BY a.date_fin;

/* 8. Anciens abonnés (aucun abonnement en cours) et date de leur départ */
SELECT u.nom, u.email, MAX(a.date_fin) AS fin_dernier_abonnement,
       DATEDIFF(CURRENT_DATE, MAX(a.date_fin)) AS jours_depuis_depart
FROM utilisateur u
JOIN abonnement a ON a.id_utilisateur = u.id
GROUP BY u.id, u.nom, u.email
HAVING MAX(a.date_fin) < CURRENT_DATE
ORDER BY fin_dernier_abonnement;

/* 9. Recommandations simples : vidéos que les profils ayant les mêmes favoris
      ont aussi ajoutées (pour le profil « Karim ») */
SELECT v.titre, COUNT(*) AS profils_en_commun
FROM favoris mes_favoris
JOIN favoris autres ON autres.id_video = mes_favoris.id_video
                   AND autres.id_profil <> mes_favoris.id_profil
JOIN favoris suggestion ON suggestion.id_profil = autres.id_profil
JOIN video v ON v.id = suggestion.id_video
WHERE mes_favoris.id_profil = (SELECT id FROM profils WHERE nom = 'Karim')
  AND suggestion.id_video NOT IN (SELECT id_video FROM favoris
                                   WHERE id_profil = mes_favoris.id_profil)
GROUP BY v.id, v.titre
ORDER BY profils_en_commun DESC, v.titre;
