#!/bin/bash
ORIGINAL_GZIPPED_DB_NAME="${1:-db.sql.gz}"

DB="temp_database_with_super_unique_name"
RESULT_DIR="result"
RESULT_FILENAME="result.sql"
RESULT_GZIP_FILENAME="result.sql.gz"
DB_USER=postgres

#  &> /dev/null — не выводить сообщения в консоль
echo '== I guess you have enough free space on your HDD'
echo '== Drop temporary database if exists'
psql -U $DB_USER -c "DROP DATABASE IF EXISTS $DB" &> /dev/null

echo '== Creating temp database'
psql -U $DB_USER -c "CREATE DATABASE $DB" &> /dev/null

echo '== Restoring dump into temp database [its very long process]'
echo 'Delete file and db if you interrupted execution!'
gzip -dc $ORIGINAL_GZIPPED_DB_NAME | psql $DB &> /dev/null

echo "== Perfoming actions from files:"
for action in actions/*.sql; do
  echo $action
  psql -U $DB_USER -f $action --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on $DB &> /dev/null
done

echo "== Result dumping in the $RESULT_DIR folder"
mkdir -p $RESULT_DIR
cd $RESULT_DIR

pg_dump $DB > $RESULT_FILENAME

echo "== Result compressing"
gzip -c $RESULT_FILENAME > $RESULT_GZIP_FILENAME

read -r -p "Do you want to drop temporary database used for script? [Y/n]" response
response=${response,,} # lowercase
if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
   psql -U $DB_USER -c "DROP DATABASE IF EXISTS $DB" &> /dev/null
fi
