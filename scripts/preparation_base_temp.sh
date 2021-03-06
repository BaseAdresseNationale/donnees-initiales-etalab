#!/bin/sh
# But : preparer la base postgresql de travail en y ajoutant la table des 
# abbreviations et la table des communes fusionnées
################################################################################
# ARGUMENT :  
################################################################################
# ENTREE : les fichiers  
# - abbre.csv : les abbreviations
# - fusion_commune.sql : les fusions de commune
##############################################################################
# SORTIE : les tables PostgreSQL suivantes :
# - abbrev
# - fusion_commune
#############################################################################

BinPath=`dirname $0`

# creation de la table des abbreviations de type de voie
echo "DROP TABLE IF EXISTS abbrev_type_voie;" > commandeTemp.sql
echo "CREATE TABLE abbrev_type_voie
(
  nom_court character varying,
  nom_long character varying,
  nom_min character varying,
  kind character varying,
  code character varying
); " >> commandeTemp.sql
echo "\COPY abbrev_type_voie FROM '${BinPath}/abbrev_type_voie.csv' WITH CSV HEADER DELIMITER ';';" >> commandeTemp.sql

psql -f commandeTemp.sql

if [ $? -ne 0 ]
then
   echo "Erreur lors de l import des fichiers csv des abbreviations de type de voie"
   exit 1
fi

# création de la table des abbréviations pour le pasage libelle long -> libelle court
psql -f ${BinPath}/abbrev.sql
if [ $? -ne 0 ]
then
   echo "Erreur lors de la creation de la table des abbreviations pour passage libelles long -> libelles court"
   exit 1
fi

rm commandeTemp.sql



# creation de la table des fusions de communes
psql -f ${BinPath}/fusion_commune.sql
if [ $? -ne 0 ]
then
   echo "Erreur lors de la creation de la table fusion_commune"
   exit 1
fi

echo "FIN"

