#!/bin/sh
# Crée la base « streaming » avec ses tables, objets, vues, rôles et données de démonstration.
#
# Utilisation : ./installer.sh [commande client]
#   ./installer.sh                       -> mysql -u root
#   ./installer.sh "mysql -u root -p"
#   ./installer.sh "mariadb -u root"
set -e

CLIENT=${1:-"mysql -u root"}
DIR=$(cd "$(dirname "$0")" && pwd)
SQL="$CLIENT --default-character-set=utf8mb4"

$SQL -e "DROP DATABASE IF EXISTS streaming; CREATE DATABASE streaming CHARACTER SET utf8mb4;"
for f in 01_schema 02_objets 03_vues 04_roles 05_donnees; do
    $SQL streaming < "$DIR/sql/$f.sql"
    echo "$f.sql : OK"
done

echo
$SQL --table streaming -e "SELECT id, titre, type, categories, duree_minutes FROM v_catalogue;"
echo "Base « streaming » prête. Requêtes d'analyse : $CLIENT streaming < sql/06_requetes_analyse.sql"
