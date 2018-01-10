#!/bin/sh
# But : preparer et exporter des fichiers json pour un departement directement
# importable dans la ban
# avec la commande ban import:init
################################################################################
# ARGUMENT :* $1 : repertoire dans lequel seront generes les json
#           * $2 : departement à traiter
################################################################################
# ENTREE : la base PostgreSQL temporaire dans laquelle ont ete importees
# les données des différentes sources dans les tables suivantes (France entiere):
# - insee_cog
# - poste_cp
# - dgfip_fantoir
# - dgfip_noms_cadastre
# - dgfip_housenumbers
# - ran_group
# - ran_housenumber
# - ign_municipality
# - ign_postcode
# - ign_group
# - ign_house_number
# - les aitf ????
##############################################################################
# SORTIE : les fichiers json dans $1 :
# - a completer
#############################################################################
#  Les donnees doivent etre dans la base PostgreSQL PGDATABASE (variable 
#  d'environnement)
#############################################################################
data_path=$1
dep=$2

if [ $# -lt 2 ]; then
        echo "Usage : export_json.sh <outPath> <dep>"
        exit 1
fi

#verification du repertoire data_path
mkdir ${data_path}
rm -r ${data_path}/${dep}
mkdir ${data_path}/${dep}

echo "\\\set ON_ERROR_STOP 1" > commandeTemp.sql
echo "\\\timing" >> commandeTemp.sql

###############################################################################
# MUNICIPALITY
# Extraction et export en json
echo "\COPY (select format('{\"type\":\"municipality\",\"insee\":\"%s\",\"name\":\"%s\"}',insee,name) from insee_cog WHERE insee like '${dep}%') to '${data_path}/${dep}/01_municipalities.json';" >> commandeTemp.sql

#####################################################################################
# POSTCODE
# extraction et export en json
echo "\COPY (select format('{\"type\":\"postcode\",\"postcode\":\"%s\",\"name\":\"%s\",\"municipality:insee\":\"%s\" ,\"complement\":\"%s\"}',co_postal,lb_l6,co_insee, lb_l5_nn) from poste_cp WHERE co_insee like '${dep}%' ) to '${data_path}/${dep}/02_postcodes.json';" >> commandeTemp.sql

#####################################################################################
# GROUP
# Creation de la table group${dep}
echo "drop table if exists group${dep};" >> commandeTemp.sql
echo "CREATE TABLE group${dep}(
	name character varying(200) NOT NULL,
	nom_norm varchar,
	alias character varying(255),
	kind character varying(64) NOT NULL,
	addressing character varying(16),
	fantoir character varying(255),
	laposte character varying(8),
	ign character varying(24),
	insee varchar NOT NULL,
	insee_old varchar,
	source_nom varchar,
	fantoir_name varchar,
	ign_name varchar,
	laposte_name varchar);" >> commandeTemp.sql
echo "CREATE INDEX idx_group_insee${dep} ON group${dep}(insee);" >> commandeTemp.sql

#########################
# Integration des groupes fantoirs du departement dans la table group${dep}
echo "INSERT INTO group${dep} (kind, insee, fantoir, name, fantoir_name, source_nom ) 
SELECT kind, code_insee, fantoir_9, f.name , f.name, 'FANTOIR' from dgfip_fantoir f, insee_cog where f.code_insee=insee_cog.insee and code_insee like '${dep}%' ;" >> commandeTemp.sql
# !!! Export des groupes fantoirs
echo "\COPY (select format('{\"type\":\"group\",\"group\":\"%s\",\"fantoir\":\"%s\",\"municipality:insee\":\"%s\",\"name\":\"%s\"}',kind,fantoir,insee, name) from group${dep}) to '${data_path}/${dep}/03_A_groups.json';" >> commandeTemp.sql


#################################
# GROUP IGN
# Extraction du departement
echo "DROP TABLE IF EXISTS group_ign${dep};" >> commandeTemp.sql
echo "CREATE TABLE group_ign${dep} AS SELECT * FROM ign_group WHERE code_insee like '${dep}%';" >> commandeTemp.sql
# index sur id_pseudo_fpb
echo "CREATE INDEX idx_group_ign${dep}_id_pseudo_fpb ON group_ign${dep}(id_pseudo_fpb);" >> commandeTemp.sql

#################################
# GROUPES IGN RETROUVES DANS FANTOIR
# complete les groups deja dans group${dep} ayant un id fantoir avec les infos des groups ign avec le meme id fantoir
# les infos ajoutées sont : ign, alias, addressing, insee_old
# Le nom et le nom normalisé deviennent celui de l'ign, idem pour le kind
# On met à jour source_nom avec 'IGN'
# On sauvegarde le nom fantoir si il est différent du nom ign (comparaison après normalisation
echo "UPDATE group${dep} SET ign=g.id_pseudo_fpb, addressing=g.addressing, alias=g.alias, laposte = g.id_poste, name=g.nom, nom_norm=g.nom_norm, source_nom='IGN', kind=g.kind, insee_old=g.insee_obs, ign_name = g.nom from group_ign${dep} g where g.id_fantoir=fantoir;" >> commandeTemp.sql

#########################################
# GROUPS IGN NON RETROUVES DANS FANTOIR (avec l'id fantoir)
# Integration dans la table group${dep}
echo "INSERT INTO group${dep} (kind, ign, insee, addressing, alias, laposte, nom_norm, name, insee_old, ign_name, source_nom)
SELECT g.kind, g.id_pseudo_fpb, g.code_insee, g.addressing, g.alias, g.id_poste, g.nom_norm, g.nom, g.insee_obs, g.nom, 'IGN' from group_ign${dep} g left join group${dep} i on g.id_pseudo_fpb=i.ign where name is null and id_pseudo_fpb is not null;" >> commandeTemp.sql

# !!! Export des groupes ign
echo "\COPY (select format('{\"type\":\"group\",\"group\":\"%s\",\"municipality:insee\":\"%s\",\"name\":\"%s\",\"ign\":\"%s\"  %s %s %s}',kind,insee,name,ign, case when fantoir is not null then ',\"fantoir\": \"'||fantoir||'\"' end, case when alias is not null then ',\"alias\": \"'||alias||'\"' end, case when addressing is not null then ',\"addressing\": \"'||addressing||'\"' end) from group${dep} where ign is not null) to '${data_path}/${dep}/03_B_groups.json';" >> commandeTemp.sql

#######################################
# GROUP LAPOSTE 
# Extraction du departement
echo "DROP TABLE IF EXISTS group_ran${dep};" >> commandeTemp.sql
echo "CREATE TABLE group_ran${dep} AS SELECT * FROM ran_group WHERE co_insee like '${dep}%';" >> commandeTemp.sql

#################################
# GROUPES LA POSTE  RETROUVES DANS group${dep} via les appariements de l'IGN
# complete les groups deja dans group${dep} ayant un id poste
# si le nom normalise poste est différent du nom normalise retenu jusqu'à present, on met a jour les infos suivantes :
# name, nom_norm, kind, source_nom, diff_nom
echo "UPDATE group${dep} g set name=r.lb_voie, nom_norm=r.nom_norm, kind=r.kind, source_nom='LAPOSTE' from group_ran${dep} r where g.laposte=r.laposte and g.nom_norm <> r.nom_norm;" >> commandeTemp.sql
# on sauvegarde le nom de la poste
echo "UPDATE group${dep} g set laposte_name=r.lb_voie from group_ran${dep} r where g.laposte=r.laposte;" >> commandeTemp.sql

#####################################
# AJOUT DES GROUPES LAPOSTE NON RETROUVES 
echo "INSERT INTO group${dep} (kind, name, insee, laposte, nom_norm, insee_old, laposte_name, source_nom)
SELECT g.kind, g.lb_voie, g.co_insee, g.laposte, g.nom_norm, g.co_insee_l5, g.lb_voie, 'LAPOSTE'  from group_ran${dep} g left join group${dep} on g.laposte = group${dep}.laposte where insee is null; " >> commandeTemp.sql

# !!! Export des groupes La Poste
echo "\COPY (select format('{\"type\":\"group\",\"municipality:insee\":\"%s\" %s %s,\"laposte\":\"%s\" %s }',insee, case when fantoir is not null then ',\"fantoir\": \"'||fantoir||'\"' end, case when ign is not null then ',\"ign\": \"'||ign||'\"' end, laposte, case when source_nom = 'LAPOSTE' then ',\"name\": \"'||name||'\",\"group\": \"'||kind||'\"' end) from group${dep} where laposte is not null) to '${data_path}/${dep}/03_C_groups.json';" >> commandeTemp.sql


########################################
# NOMS CADASTRE 
# On retient les noms cadastre complet si le nom cadastre normalisé est egal au nom normalisé retenu jusqu'à présent
echo "UPDATE group${dep} g set name=v.voie_cadastre, source_nom='CADASTRE' from dgfip_noms_cadastre v where left(v.fantoir,9)=g.fantoir and v.fantoir is not null and v.nom_norm = g.nom_norm;" >> commandeTemp.sql

# !!! Export des groupes dont les noms ont été modifiés par le cadastre
echo "\COPY (select format('{\"type\":\"group\",\"fantoir\":\"%s\",\"name\":\"%s\"}',fantoir, name) from group${dep} WHERE source_nom='CADASTRE') to '${data_path}/${dep}/03_D_groups.json';" >> commandeTemp.sql

psql -e -f commandeTemp.sql

if [ $? -ne 0 ]
then
  echo "Erreur lors de l export des jsons"
  exit 1
fi

exit

#####################################
# Ajout du champ source init
echo "ALTER TABLE group${dep} ADD COLUMN source_init varchar[];" >> commandeTemp.sql
echo "UPDATE group${dep} SET source_init = source_init || '{FANTOIR}' WHERE fantoir is not null;" >> commandeTemp.sql
echo "UPDATE group${dep} SET source_init = source_init || '{IGN}' WHERE ign is not null;" >> commandeTemp.sql
echo "UPDATE group${dep} SET source_init = source_init || '{LAPOSTE}' WHERE laposte is not null;" >> commandeTemp.sql

# indexes utiles pour la suite
echo "create index idx_group_fantoir${dep} on group${dep}(fantoir);" >> commandeTemp.sql
echo "create index idx_group_insee_old${dep} on group${dep}(insee_old);" >> commandeTemp.sql
echo "create index idx_group_ign${dep} on group${dep}(ign);" >> commandeTemp.sql
echo "create index idx_group_laposte${dep} on group${dep}(laposte);" >> commandeTemp.sql

##########################################
# AJOUT DES ANCIENNES COMMUNES DANS GROUP
# on ajoute les insee old pointees par les groupes, figurant dans la table fusion de commune mais pas le cog
echo "DROP TABLE IF EXISTS group_secondary${dep};" >> commandeTemp.sql
echo "CREATE TABLE group_secondary${dep} (insee varchar, name varchar, insee_old varchar, ign varchar);" >> commandeTemp.sql
echo "INSERT INTO group_secondary${dep}(insee,insee_old) 
SELECT g.insee,insee_old FROM group${dep} as g  left join insee_cog on (g.insee_old = insee_cog.insee) WHERE insee_old is not null and insee_cog.insee is null GROUP BY g.insee,insee_old ;" >> commandeTemp.sql
echo "UPDATE group_secondary${dep} SET name = f.nom_old from fusion_commune as f where f.insee_old = group_secondary${dep}.insee_old;" >> commandeTemp.sql
echo "DELETE FROM group_secondary${dep} WHERE name is null;" >> commandeTemp.sql
echo "UPDATE group_secondary${dep} SET ign = insee_old||'####';" >> commandeTemp.sql
echo "INSERT INTO group${dep} (name, kind, insee, ign) 
SELECT name, 'area', insee, ign FROM group_secondary${dep};" >> commandeTemp.sql


echo "UPDATE group${dep} SET name=regexp_replace(name,'\"','','g');" >> commandeTemp.sql

echo "\COPY (select format('{\"type\":\"group\",\"group\":\"%s\",\"municipality:insee\":\"%s\" %s ,\"name\":\"%s\" %s %s %s %s,\"attributes\":{\"source_init\":\"%s\",\"source_name_init\":\"%s\" %s %s %s} }',kind,insee, case when fantoir is not null then ',\"fantoir\": \"'||fantoir||'\"' end, name, case when ign is not null then ',\"ign\": \"'||ign||'\"' end, case when laposte is not null then ',\"laposte\": \"'||laposte||'\"' end, case when alias is not null then ',\"alias\": \"'||alias||'\"' end, case when addressing is not null then ',\"addressing\": \"'||addressing||'\"' end, source_init, source_nom, case when fantoir_name is not null then ',\"fantoir_name_init\":\"'||fantoir_name||'\"' end, case when ign_name is not null then ',\"ign_name_init\":\"'||ign_name||'\"' end, case when laposte_name is not null then ',\"laposte_name_init\":\"'||laposte_name||'\"' end) from group${dep}) to '${data_path}/${dep}/03_groups.json';" >> commandeTemp.sql


#################################################################################
# HOUSENUMBER
# Creation de la table housenumber${dep}
echo "DROP TABLE IF EXISTS housenumber${dep};" >> commandeTemp.sql
echo "CREATE TABLE housenumber${dep} (\"number\" varchar, ordinal varchar, cia varchar, laposte varchar, ign varchar, group_fantoir varchar, group_ign varchar, group_laposte varchar, postcode_code varchar, lb_l5 varchar, insee varchar, no_pile_doublon integer, ancestor_ign varchar, source_init varchar[] );" >> commandeTemp.sql

###################################
# Preparation de la table housenumber_bano
# Extraction du departement
echo "DROP TABLE IF EXISTS housenumber_bano${dep};" >> commandeTemp.sql
echo "CREATE TABLE housenumber_bano${dep} AS SELECT * FROM dgfip_housenumbers WHERE insee_com like '${dep}%';" >> commandeTemp.sql
# Creation de la colonne fantoir_hn
echo "ALTER TABLE  housenumber_bano${dep} ADD COLUMN fantoir_hn varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_bano${dep} SET fantoir_hn=left(fantoir,5)||left(right(fantoir,5),4);" >> commandeTemp.sql
# Creation de la colonne number
echo "ALTER TABLE  housenumber_bano${dep} ADD COLUMN number varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_bano${dep} SET number=left(numero||' ',strpos(numero||' ',' ')-1);" >> commandeTemp.sql
# Creation de la colonne ordinal
echo "ALTER TABLE  housenumber_bano${dep} ADD COLUMN ordinal varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_bano${dep} SET ordinal=upper(trim(right(numero||' ',-strpos(numero||' ',' '))));" >> commandeTemp.sql
# Creation de la colonne cia
echo "ALTER TABLE  housenumber_bano${dep} ADD COLUMN cia varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_bano${dep} SET cia=upper(format('%s_%s_%s_%s',left(fantoir,5),left(right(fantoir,5),4),number,ordinal));" >> commandeTemp.sql


# Insertion dans la table housenumber${dep}
echo "INSERT INTO housenumber${dep} (group_fantoir, group_ign, group_laposte, number, ordinal, insee, source_init)
SELECT g.fantoir, g.ign, g.laposte, h.number, h.ordinal, g.insee, '{DGFIP-BANO}' from housenumber_bano${dep} h, group${dep} g where fantoir_hn=g.fantoir group by g.fantoir, g.ign, g.laposte, h.number, h.ordinal, g.insee;" >> commandeTemp.sql


########################################
# PREPARATION HOUSENUMBER IGN
# Extraction du departement / suppression des doublons parfaits / suppression des detruits
echo "DROP TABLE IF EXISTS housenumber_ign${dep};" >> commandeTemp.sql
echo "CREATE TABLE housenumber_ign${dep} AS SELECT max(id) as id, max(id_poste) as id_poste, numero,rep,lon,lat,code_post,code_insee,id_pseudo_fpb,type_de_localisation,indice_de_positionnement,methode,designation_de_l_entree FROM ign_housenumber WHERE code_insee like '${dep}%' and detruit is null group by (numero,rep,lon,lat,code_post,code_insee,id_pseudo_fpb,type_de_localisation,indice_de_positionnement,methode,designation_de_l_entree);" >> commandeTemp.sql
# Passage en majuscule du rep
echo "UPDATE housenumber_ign${dep} SET rep = upper(rep);" >> commandeTemp.sql
#Marquage des doublons (meme numero et indice de repetition)
# etape1 : creation des piles de doublons sémantiques
echo "DROP TABLE IF EXISTS doublon_ign_${dep};" >> commandeTemp.sql
echo "CREATE TABLE doublon_ign_${dep} AS SELECT numero,rep,code_post,code_insee,id_pseudo_fpb,count(*) FROM housenumber_ign${dep} GROUP BY (numero,rep,code_post,code_insee,id_pseudo_fpb) HAVING COUNT(*) > 1;" >> commandeTemp.sql
echo "DROP SEQUENCE IF EXISTS seq_doublons_ign_${dep};" >> commandeTemp.sql
echo "CREATE SEQUENCE seq_doublons_ign_${dep};" >> commandeTemp.sql
echo "ALTER TABLE doublon_ign_${dep} ADD no_pile_doublon integer;" >> commandeTemp.sql
echo "UPDATE doublon_ign_${dep} SET no_pile_doublon = nextval('seq_doublons_ign_${dep}');" >> commandeTemp.sql

# etape 2 : marquage du numéro de piles doublons sémantiques sur les hns ign
echo "ALTER TABLE housenumber_ign${dep} ADD no_pile_doublon integer;" >> commandeTemp.sql
echo "UPDATE housenumber_ign${dep} AS hn SET no_pile_doublon = d.no_pile_doublon FROM doublon_ign_${dep} AS d WHERE 
	(hn.numero = d.numero and 
	 hn.rep = d.rep and 
	 hn.code_post = d.code_post and
	 hn.code_insee = d.code_insee and
	 hn.id_pseudo_fpb = d.id_pseudo_fpb);" >> commandeTemp.sql

# Creation de la colonne fantoir
echo "ALTER TABLE  housenumber_ign${dep} ADD COLUMN fantoir varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_ign${dep} SET fantoir=g.fantoir FROM group${dep} g WHERE housenumber_ign${dep}.id_pseudo_fpb=g.ign;" >> commandeTemp.sql


########################################
# HOUSENUMBER IGN GROUP RAPPROCHES
# Mise a jour du champ ign de housenumber${dep}
echo "update housenumber${dep} h set ign=i.id from housenumber_ign${dep} i where h.group_ign=i.id_pseudo_fpb and h.number=i.numero and h.ordinal=i.rep;" >> commandeTemp.sql
# Mise a jour de no_pile_doublon
echo "update housenumber${dep} h set no_pile_doublon=i.no_pile_doublon from housenumber_ign${dep} i where h.ign=i.id;" >> commandeTemp.sql

###########################################
# HOUSENUMBER IGN GROUP NON RAPPROCHES
# Ajout des housenumber_ign non retrouves dans  housenumber${dep} (cles = fantoir, numero, dep) et dont le fantoir n'est pas nul
echo "INSERT INTO housenumber${dep} (ign, group_fantoir, group_ign, number, ordinal, no_pile_doublon, insee)
SELECT max(i.id), i.fantoir, i.id_pseudo_fpb, i.numero, i.rep, i.no_pile_doublon, code_insee from housenumber_ign${dep} i
left join housenumber${dep} h on (h.group_fantoir=i.fantoir and i.numero=h.number and i.rep=h.ordinal) where h.number is null and i.fantoir is not null group by i.fantoir, i.id_pseudo_fpb, i.numero, i.rep, i.no_pile_doublon, i.code_insee;" >> commandeTemp.sql
# Ajout dans la ban les housenumbers ign dont le fantoir est nul
echo "INSERT INTO housenumber${dep} (ign, group_ign, number, ordinal, no_pile_doublon, insee)
SELECT max(id), id_pseudo_fpb, numero, rep, no_pile_doublon, code_insee from housenumber_ign${dep} where fantoir is null group by id_pseudo_fpb, numero, rep, no_pile_doublon, code_insee;" >> commandeTemp.sql

########################################
# Mise à jour des champs la poste avec les données IGN
# Mise a jour du champ group_laposte de housenumber${dep}
echo "update housenumber${dep} h set group_laposte=g.laposte from group${dep} g where h.group_ign=g.ign;" >> commandeTemp.sql
# Mise a jour du champ laposte de housenumber${dep}
echo "update housenumber${dep} h set laposte=i.id_poste from housenumber_ign${dep} i where h.ign=i.id;" >> commandeTemp.sql

##################################################
# Mise à jour du code postal avec les adresses IGN
echo "update housenumber${dep} h set postcode_code=i.code_post from housenumber_ign${dep} i where h.ign=i.id and i.code_post in (select co_postal from postcode${dep});" >> commandeTemp.sql

######################################
# Creation d'un housenumber null pour chaque group laposte, pour stoker le cea de la voie poste
# Insertion dans la table housenumber${dep}
echo "INSERT INTO housenumber${dep} (group_laposte, laposte, postcode_code, insee)
SELECT g.laposte, r.cea, r.co_postal, r.co_insee from group_ran${dep} r, group${dep} g where g.laposte=r.laposte and lb_l5 is null;" >> commandeTemp.sql


#####################################
# Preparation de housenumber_ran
# Extraction du departement
echo "DROP TABLE IF EXISTS housenumber_ran${dep};" >> commandeTemp.sql
echo "CREATE TABLE housenumber_ran${dep} AS SELECT * FROM ran_housenumber WHERE co_insee like '${dep}%';" >> commandeTemp.sql
# Creation de la colonne group_laposte
echo "ALTER TABLE  housenumber_ran${dep} ADD COLUMN group_laposte varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_ran${dep} SET group_laposte=right('0000000'||co_voie,8);" >> commandeTemp.sql
# Passage à vide de l'indice de répétition pour être conforme aux autres sources
echo "UPDATE housenumber_ran${dep} SET lb_ext='' where lb_ext is null;" >> commandeTemp.sql


#####################################
# Mise a jour de laposte dans la table housenumber${dep}
echo "UPDATE housenumber${dep} h SET laposte=r.co_cea FROM housenumber_ran${dep} r WHERE r.group_laposte=h.group_laposte and h.number=r.no_voie and h.ordinal=r.lb_ext and h.laposte is null and not exists (select laposte from housenumber${dep} where laposte=r.co_cea);" >> commandeTemp.sql

# Mise a jour des postcodes dans la table housenumber${dep} à partir des données poste
echo "UPDATE housenumber${dep} h SET postcode_code=r.co_postal FROM housenumber_ran${dep} r WHERE r.co_cea=h.laposte and r.co_postal is not null;" >> commandeTemp.sql


#####################################
# HOUSENUMBERS LAPOSTE NON RAPPROCHES
# Insertion dans la table housenumber${dep}
echo "INSERT INTO housenumber${dep} (group_laposte, number, ordinal, postcode_code, laposte)
SELECT r.group_laposte, r.no_voie, r.lb_ext, r.co_postal, co_cea FROM housenumber_ran${dep} r left join housenumber${dep} h  on(r.co_cea=h.laposte) where insee is null;" >> commandeTemp.sql

# Quelques indexes utiles pour la suite
echo "create index idx_housenumber_group_fantoir${dep} on housenumber${dep}(group_fantoir);" >> commandeTemp.sql
echo "create index idx_housenumber_group_ign${dep} on housenumber${dep}(group_ign);" >> commandeTemp.sql
echo "create index idx_housenumber_group_laposte${dep} on housenumber${dep}(group_laposte);" >> commandeTemp.sql

# Ligne 5
# A partir des donnnées LP (on remonte a la ligne 5 contenu dans ran_group)
echo "UPDATE housenumber${dep} h SET lb_l5=g.lb_l5 FROM housenumber_ran${dep} r, group_ran${dep} g WHERE r.co_cea=h.laposte and r.co_voie=g.co_voie and g.lb_l5 is not null ;" >> commandeTemp.sql
# à partir de l'insee old des groupes que l'on retrouve dans postecode (on remonte par l'identitiant ign)
echo "UPDATE housenumber${dep} h SET lb_l5=c.lb_l5_nn FROM postcode${dep} c, group${dep} g WHERE h.group_ign = g.ign and g.insee_old = c.co_insee_anc and g.insee_old is not null and lb_l5 is not null and c.lb_l5_nn is not null ;" >> commandeTemp.sql

# Colonne CIA
echo "update housenumber${dep} set cia=upper(format('%s_%s_%s_%s',left(group_fantoir,5),right(group_fantoir,4),number, coalesce(ordinal,''))) where group_fantoir is not null;" >> commandeTemp.sql

# traitement des fusions de communes : les anciennes communes sont mis en groupe secondaire des hn (ancestors) : 3 jointures différentes (hn -> group fantoir, hn -> group ign, hn -> group la poste)
echo "update housenumber${dep} h set ancestor_ign=s.ign from group${dep} g, group_secondary${dep} s where h.group_fantoir=g.fantoir and g.insee_old||'####'=s.ign;" >> commandeTemp.sql 
echo "update housenumber${dep} h set ancestor_ign=s.ign from group${dep} g, group_secondary${dep} s where h.group_ign=g.ign and g.insee_old||'####'=s.ign;" >> commandeTemp.sql
echo "update housenumber${dep} h set ancestor_ign=s.ign from group${dep} g, group_secondary${dep} s where h.group_laposte=g.laposte and g.insee_old||'####'=s.ign;" >> commandeTemp.sql
#echo "update housenumber${dep} h set insee=g.insee from group${dep} g where h.group_ign=g.ign and h.group_fantoir is null;" >> commandeTemp.sql
#echo "update housenumber${dep} h set insee=g.insee from group${dep} g where h.group_laposte=g.laposte and h.group_fantoir is null and h.group_ign is null;" >> commandeTemp.sql
#echo "update housenumber${dep} h set old_insee=g.old_insee from group${dep} g where h.group_ign=g.ign and h.group_fantoir is null;" >> commandeTemp.sql
#echo "update housenumber${dep} h set old_insee=g.old_insee from group${dep} g where h.group_laposte=g.laposte and h.group_fantoir is null and h.group_ign is null;" >> commandeTemp.sql

#####################################
# Ajout du champ source init
echo "UPDATE housenumber${dep} SET source_init = source_init || '{IGN}' WHERE ign is not null;" >> commandeTemp.sql
echo "UPDATE housenumber${dep} SET source_init = source_init || '{LAPOSTE}' WHERE laposte is not null;" >> commandeTemp.sql


# EXPORT EN JSON
# hn lie au group via fantoir
echo "\COPY (select format('{\"type\":\"housenumber\", \"group:fantoir\":\"%s\", \"cia\":\"%s\" %s %s, \"numero\":\"%s\", \"ordinal\": \"%s\" %s %s %s}', group_fantoir, cia, case when ign is not null then ',\"ign\": \"'||ign||'\"' end, case when laposte is not null then ',\"laposte\": \"'||laposte||'\"' end, number, ordinal, case when postcode_code is not null then ',\"postcode:code\": \"'||postcode_code||'\", \"municipality:insee\": \"'||insee||'\", \"postcode:complement\":\"'||lb_l5||'\"' end ,case when ancestor_ign is not null then ',\"ancestor:ign\":\"'||ancestor_ign||'\"' end, ',\"attributes\":{\"source_init\":\"'||array_to_string(source_init,'|')||'\"}') from housenumber${dep} where group_fantoir is not null) to '${data_path}/${dep}/04_housenumbers.json';" >> commandeTemp.sql
# hn lie au group via identifiant ign (si fantoir vide)
echo "\COPY (select format('{\"type\":\"housenumber\", \"cia\": \"\", \"group:ign\":\"%s\" , \"ign\": \"%s\", \"numero\":\"%s\", \"ordinal\":\"%s\" %s %s %s}', group_ign, ign, number, ordinal, case when postcode_code is not null then ',\"postcode:code\": \"'||postcode_code||'\", \"municipality:insee\": \"'||insee||'\", \"postcode:complement\":\"'||lb_l5||'\"' end, case when ancestor_ign is not null then ',\"ancestor:ign\":\"'||ancestor_ign||'\"' end,',\"attributes\":{\"source_init\":\"'||array_to_string(source_init,'|')||'\"}') from housenumber${dep} where group_ign is not null and group_fantoir is null) to '${data_path}/${dep}/05_housenumbers.json';" >> commandeTemp.sql
# hn lie au group via identifiant la poste et (si fantoir/ign groupe vide)
echo "\COPY (select format('{\"type\":\"housenumber\", \"cia\": \"\", \"group:laposte\":\"%s\", \"laposte\":\"%s\", \"numero\": \"%s\", \"ordinal\":\"%s\" %s %s %s}', group_laposte, laposte, number, ordinal, case when postcode_code is not null then ',\"postcode:code\": \"'||postcode_code||'\", \"municipality:insee\": \"'||insee||'\", \"postcode:complement\":\"'||lb_l5||'\"' end, case when ancestor_ign is not null then ',\"ancestor:ign\":\"'||ancestor_ign||'\"' end,',\"attributes\":{\"source_init\":\"'||array_to_string(source_init,'|')||'\"}') from housenumber${dep} where group_laposte is not null and group_ign is null and group_fantoir is null) to '${data_path}/${dep}/06_housenumbers.json';" >> commandeTemp.sql


####################################################################################################
# POSITIONS
echo "DROP TABLE IF EXISTS position${dep};" >> commandeTemp.sql
echo "CREATE TABLE position${dep} (name varchar, lon varchar, lat varchar, housenumber_cia varchar, housenumber_ign varchar, housenumber_laposte varchar, kind varchar, positioning varchar, ign varchar, laposte varchar,no_pile_doublon integer, source_init varchar);" >> commandeTemp.sql

#########################################
# POSITION IGN
echo "ALTER TABLE housenumber_ign${dep} ADD COLUMN cia varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_ign${dep} SET cia=format('%s_%s_%s_%s',left(fantoir,5), right(fantoir,4),numero, rep) where fantoir is not null;" >> commandeTemp.sql
# Creation de la colonne kind et positioning
echo "ALTER TABLE housenumber_ign${dep} ADD kind text;" >> commandeTemp.sql
echo "ALTER TABLE housenumber_ign${dep} ADD pos text;" >> commandeTemp.sql
echo "UPDATE housenumber_ign${dep} SET kind = CASE WHEN indice_de_positionnement = '5' THEN 'area' WHEN type_de_localisation = 'A la plaque' THEN 'entrance' WHEN type_de_localisation = 'Projetée du centre parcelle' THEN 'segment' WHEN type_de_localisation LIKE 'A la zone%' THEN 'area' WHEN type_de_localisation = 'Interpolée' THEN 'segment' ELSE 'unknown' END;" >> commandeTemp.sql
echo "UPDATE housenumber_ign${dep} SET pos = CASE WHEN type_de_localisation = 'Projetée du centre parcelle' THEN 'projection' WHEN type_de_localisation = 'Interpolée' THEN 'interpolation' ELSE 'other' END;" >> commandeTemp.sql
# Insertion dans la table des kind entrance
# 	Passe 1 : on ajoute une position par hn (on ne traite pas les piles)
echo "INSERT INTO position${dep} (housenumber_cia, lon, lat, housenumber_ign, kind, positioning, ign, no_pile_doublon, source_init)
SELECT i.cia, lon, lat, i.id, i.kind, i.pos ,i.id, i.no_pile_doublon, 'IGN' FROM housenumber_ign${dep} i, housenumber${dep} h where i.id=h.ign and (i.kind not like 'segment' and i.kind not like 'unknown') and i.no_pile_doublon is null;" >> commandeTemp.sql
#       Passe 2 : on ajoute les piles
echo "INSERT INTO position${dep} (housenumber_cia, lon, lat, housenumber_ign, kind, positioning, ign, no_pile_doublon, source_init)
SELECT i.cia, i.lon, i.lat, h.ign, i.kind, i.pos ,i.id, i.no_pile_doublon, 'IGN' FROM housenumber${dep} h left join housenumber_ign${dep} i on (h.no_pile_doublon=i.no_pile_doublon) where (i.kind not like 'segment' and i.kind not like 'unknown') and h.no_pile_doublon is not null;" >> commandeTemp.sql


##########################################
# POSITION DGFIP
# racroché au housenumber grace au cia
# Creation des colonnes x et y
echo "ALTER TABLE  housenumber_bano${dep} ADD COLUMN x varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_bano${dep} SET x=round(lon::numeric,7)::text;" >> commandeTemp.sql
echo "ALTER TABLE  housenumber_bano${dep} ADD COLUMN y varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_bano${dep} SET y=round(lat::numeric,7)::text;" >> commandeTemp.sql
# Insertion dans la table position des positions bano pour les hn qui n'ont pas de positions ou pas de positions entrance 
echo "CREATE INDEX idx_housenumber_ign_position${dep} ON position${dep}(housenumber_ign);" >> commandeTemp.sql
echo "INSERT INTO position${dep} (housenumber_cia, lon, lat, kind, positioning, source_init )
SELECT b.cia, b.x, b.y, 'entrance', 'other', 'DGFIP-BANO' FROM housenumber_bano${dep} b join (select cia from housenumber${dep} h left join position${dep} p on (p.housenumber_ign = h.ign) where p.kind not like 'entrance' or p.kind is null) as j on b.cia = j.cia;" >> commandeTemp.sql

# Insertion dans la table position des positions bano si elles sont eloignees de plus de 5 m des positions déjà existantes
echo "INSERT INTO position${dep} (housenumber_cia, lon, lat, kind, positioning, source_init)
SELECT b.cia, b.x, b.y, 'entrance', 'other', 'DGFIP-BANO' FROM housenumber_bano${dep} b join position${dep} p on (b.cia=p.housenumber_cia) where st_distance(ST_GeographyFromText('POINT('||p.lon||' '||p.lat||')'),ST_GeographyFromText('POINT('||b.x||' '||b.y||')'))>5;" >> commandeTemp.sql

##########################################
# POSITION IGN
# Insertion dans la table des positions ign "segment" si il n'y a pas de position entrance dejà présente (en 2 passes sans pile puis pile)
# on commence par faire une table temporaire avec les housenumbers qui n'ont pas de position entrance
echo "DROP TABLE IF EXISTS housenumber_without_entrance${dep};" >> commandeTemp.sql
echo "CREATE TABLE housenumber_without_entrance${dep} AS SELECT * FROM housenumber${dep};" >> commandeTemp.sql
echo "DELETE FROM housenumber_without_entrance${dep} WHERE ign IN (SELECT housenumber_ign FROM position${dep} where kind like 'entrance' );" >>  commandeTemp.sql
echo "DELETE FROM housenumber_without_entrance${dep} WHERE cia in (select housenumber_cia from position${dep} where kind like 'entrance' );" >> commandeTemp.sql
echo "DELETE  FROM housenumber_without_entrance${dep} WHERE no_pile_doublon is not null;" >>  commandeTemp.sql

# Creation de la colonne name
echo "ALTER TABLE housenumber_ign${dep} ADD COLUMN name varchar;" >> commandeTemp.sql
echo "UPDATE housenumber_ign${dep} SET name=designation_de_l_entree where designation_de_l_entree not like '';" >> commandeTemp.sql

echo "INSERT INTO position${dep} (housenumber_cia, lon, lat, housenumber_ign, kind, positioning, ign, name, source_init)
SELECT i.cia, i.lon, i.lat, i.id, i.kind, i.pos, i.id, i.name, 'IGN' FROM housenumber_ign${dep} i join housenumber_without_entrance${dep} as j on i.id=j.ign where i.kind like 'segment' and i.no_pile_doublon is null;" >> commandeTemp.sql

# Rebelote avec les piles
echo "DROP TABLE IF EXISTS housenumber_without_entrance${dep};" >> commandeTemp.sql
echo "CREATE TABLE housenumber_without_entrance${dep} AS SELECT * FROM housenumber${dep};" >> commandeTemp.sql
echo "DELETE FROM housenumber_without_entrance${dep} WHERE ign IN (SELECT housenumber_ign FROM position${dep} where kind like 'entrance' );" >>  commandeTemp.sql
echo "DELETE FROM housenumber_without_entrance${dep} WHERE cia in (select housenumber_cia from position${dep} where kind like 'entrance' );" >> commandeTemp.sql
echo "DELETE  FROM housenumber_without_entrance${dep} WHERE no_pile_doublon is null;" >>  commandeTemp.sql

echo "INSERT INTO position${dep} (housenumber_cia, lon, lat, housenumber_ign, kind, positioning, ign, source_init)
SELECT i.cia, i.lon, i.lat, j.ign, i.kind, i.pos, i.id, 'IGN' FROM housenumber_ign${dep} i join housenumber_without_entrance${dep} as j on (i.no_pile_doublon=j.no_pile_doublon) where i.kind like 'segment' and i.no_pile_doublon is not null;" >> commandeTemp.sql


echo "\COPY (select format('{\"type\":\"position\", \"kind\":\"%s\" %s, \"positioning\":\"%s\", \"housenumber:cia\": \"%s\", \"ign\": \"%s\",\"geometry\": {\"type\":\"Point\",\"coordinates\":[%s,%s]} %s}',kind, case when name is not null then ',\"name\":\"'||name||'\"' end, positioning, housenumber_cia, ign, lon, lat,',\"attributes\":{\"source_init\":\"'||source_init||'\"}') from position${dep} where housenumber_cia is not null) to '${data_path}/${dep}/07_positions.json';" >> commandeTemp.sql 
echo "\COPY (select format('{\"type\":\"position\", \"kind\":\"%s\" %s, \"positioning\":\"%s\", \"housenumber:ign\": \"%s\", \"ign\": \"%s\",\"geometry\": {\"type\":\"Point\",\"coordinates\":[%s,%s]} %s}', kind, case when name is not null then ',\"name\":\"'||name||'\"' end, positioning, housenumber_ign, ign, lon, lat, ',\"attributes\":{\"source_init\":\"'||source_init||'\"}') from position${dep} where housenumber_cia is null and housenumber_ign is not null) to '${data_path}/${dep}/08_positions.json';" >> commandeTemp.sql

psql -e -f commandeTemp.sql

if [ $? -ne 0 ]
then
  echo "Erreur lors de l export des jsons"
  exit 1
fi

exit

rm commandeTemp.sql

echo "FIN"

