#!/bin/sh
# Lance les tests dans une base temporaire, puis vérifie que l'installation
# complète (données, requêtes d'analyse, suppression) s'exécute sans erreur.
#
# Utilisation : ./tests/lancer_tests.sh [commande client]
#   ./tests/lancer_tests.sh                      -> mysql -u root
#   ./tests/lancer_tests.sh "mariadb -u root"
#   ./tests/lancer_tests.sh "mysql -u root -p"
set -e

CLIENT=${1:-"mysql -u root"}
BASE=streaming_tests
DIR=$(cd "$(dirname "$0")/.." && pwd)
SQL="$CLIENT --default-character-set=utf8mb4"

echo "== Tests unitaires"
$SQL -e "DROP DATABASE IF EXISTS $BASE; CREATE DATABASE $BASE CHARACTER SET utf8mb4;"
for f in 01_schema 02_objets 03_vues; do
    $SQL $BASE < "$DIR/sql/$f.sql"
done
$SQL --table $BASE < "$DIR/tests/tests.sql"
ECHECS=$($SQL -N $BASE -e "SELECT COUNT(*) FROM resultat_test WHERE NOT reussi")

echo "== Installation complète avec les données de démonstration"
$SQL -e "DROP DATABASE IF EXISTS $BASE; CREATE DATABASE $BASE CHARACTER SET utf8mb4;"
for f in 01_schema 02_objets 03_vues 05_donnees 06_requetes_analyse suppression; do
    $SQL $BASE < "$DIR/sql/$f.sql" > /dev/null
    echo "   $f.sql : OK"
done
RESTE=$($SQL -N -e "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = '$BASE'")
RESTE=$((RESTE + $($SQL -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$BASE'")))
$SQL -e "DROP DATABASE $BASE;"

if [ "$RESTE" -ne 0 ]; then
    echo "suppression.sql a laissé $RESTE objet(s)"
    exit 1
fi
if [ "$ECHECS" -ne 0 ]; then
    echo "$ECHECS test(s) en échec"
    exit 1
fi
echo "Tout est correct."
