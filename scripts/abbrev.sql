--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: abbrev; Type: TABLE; Schema: public; Owner: -
--
DROP TABLE IF EXISTS abbrev;
CREATE TABLE abbrev (
    txt_long text,
    txt_court text
);


--
-- Data for Name: abbrev; Type: TABLE DATA; Schema: public; Owner: -
--

COPY abbrev (txt_long, txt_court) FROM stdin;
(ACH|ANCIEN CHEMIN|CHE|CHEM|CHEMIN) (AN|ANC|ANCIEN) (CH|CHE|CHEM|CHEMIN)	ACH
CHE ANC	ACH
(ART|ANCIENNE ROUTE|RTE|ROUTE) (AN|ANC|ANCIEN|ANCIENNE) (RTE|ROUTE)	ART
RTE ANC	ART
ANCIEN CHEMIN	ACH
ANCIENNE ROUTE	ART
ANC RTE	ART
ADJUDANT	ADJ
AERODROME	AER
AFRIQUE (DU) NORD	AFN
A F N	AFN
AGGLOMERATION	AGL
ALLEE	ALL
ALLEES	ALL
ALL ALLEE	ALL
ALL ALLEES	ALL
ALGERIE	ALG
ANCIEN	ANC
ANCIENNE	ANC
ANCIENS	ANC
ANCIENNES	ANC
ANGLE	ANGL
ARCADE	ARC
AUTOROUTE	AUT
AV AVENUE	AV
AVENUE	AV
VC BOUCLE	BCLE
BOUCLE	BCLE
BOULEVARD	BD
BLVD	BD
BERGE	BER
BORD	BORD
BARRIERE	BRE
BOURG	BRG
BRETELLE	BRTL
BASSIN	BSN
BASTIDE	BSTD
CARRER	CAE
CARRIERA	CAE
CALLE	CALL
CAMIN	CAMI
CANAL	CAN
CARREFOUR	CAR
CARRIERE	CARE
CASERNE	CASR
CHEMIN COMMUNAL	CC
CHEMIN DEPARTEMENTAL	CD
CHEMIN DEPATEMENTAL	CD
COMMANDANT	CDT
CHEMIN FORESTIER	CF
CR DIT CHEMIN	CH
CR CR NO	CR
CR CR N	CR
CR CR	CR
CR N	CR
CHASSE	CHA
CHEMIN RURAL DIT CHEM	CHE
CHEMIN RURAL DIT CHEMIN	CHE
CHEM	CHE
CHEMIN	CHE
CHEMINEMENT	CHE
CHALET	CHL
CHAMP	CHP
CHAMPS	CHP
CHPS	CHP
CHAUSSEE	CHS
CHATEAU	CHT
CHATEAUX	CHT
CHEMIN VICINAL	CHV
CITE CITE	CITE
CITE CITES	CITES
COURSIVE	CIVE
COULOIR	CLR
COBATTA	COMB
COMBATTANT	COMB
COMBATTANTS	COMB
CORNICHE	COR
CORON	CORO
CAMPING	CPG
CAPITAINE	CPT
CHEMIN RURAL DIT	CR
CHEMIN RURAL	CR
CHEMI RURAL	CR
(CHEMIN|CHE) RURAL	CR
CR DIT	CR
COURS	CRS
CROIX	CRX
CONTOUR	CTR
CENTRE	CTRE
(C|CTRE|CENTR|CENTRE|CC CENTRE|CRE|CTR|ESP|ESPA|ESPLANADE) COMMERCIAL	CCAL
CHEMIN VICINAL	CV
DARSE	DARS
DESSUS	DSU
DEVIATION	DEVI
DIVISION BLINDEE	DB
DIGUE	DIG
DIVISION	DIV
DIV INFANTERIE	DI
DIV INFANTERIE MARINE	DIM
DIVISION FRANCAISE LIBRE	DFL
DOMAINE	DOM
DOCTEUR	DR
DRAILLE	DRA
DESCENTE	DSC
ECART	ECA
ECLU	ECL
ECLUSE	ECL
EMBRANCHEMENT	EMBR
ENCLOS	ENC
ENFANTS	ENFTS
RUE DITE ENTREE	ENTREE
ENCLAVE	ENV
ESCALIER	ESC
ESP ESPLANADE	ESP
ESPLANADE	ESP
ESPACE	ESPA
ETANG	ETNG
FOND	FD
FORESTIERE	FOREST
FORESTIERE	FOREST
FAUBOURG	FG
FBG	FG
FAUB	FG
FONTAINE	FON
FOSSE	FOS
FERME	FRM
FERM	FRM
GALERIE	GAL
GENERAL	GAL
GARE	GARE
GRAND BOULEVARD	GBD
GRAND	GD
GRANDE	GDE
GRANDES	GDES
GRANDS	GDS
GEN	GAL
GOUVERNEUR	GOUV
GRAND PLACE	GPL
((GD|GDE|GRANDE|GRAND) RUE|GR |RUE )((GD|GDE|GRANDE|GRAND) RUE|GR)	GR
(GR|GRAND|GRANDE) (GR|GRANDE|RUE)	GR
GR GDE RUE	GR
VC GD RUE	GR
GROU(PE| PE|P)	GRP
GR(P|PE)	GRP
GR SCOL	GRP SCOL
(GPE|GROU|GROUP|GROUPE|GRP|GRPE|GR|G) SCOL(|A|AI|AIR|AIRE)	GRP SCOL
HABITATION	HAB
HAMEAU	HAM
HALLE	HLE
HALAGE	HLG
HLM	HLM
HAUT	HT
HAUTE	HTE
HAUTES	HTES
HAUTS	HTS
IMMEUBLE	IMM
IMPASSE	IMP
JARDIN	JARD
JARDINS	JARD
JETEE	JTE
LA FAYETTE	LAFAYETTE
LEVEE	LEVE
LICES	LICE
LIGNE	LIGN
LOTISSEMENT	LOT
LIEUTENANT	LT
LIEUT	LT
LTN	LT
MAIL	MAIL
MAISON	MAI
MARECHAL	MAL
MARCHE	MAR
MAS	MAS
MONSEIGNEUR	MGR
MOULIN(S)	MLN
MOUL	MLN
MARINA	MRN
MONTEE	MTE
MONT	MT
MONTS	MT
NOUVELLE ROUTE	NTE
NOTRE DAME	ND
N D	ND
N NO	N
N NATIONALE N	N
NEUVE	NVE
PETITE AVENUE PET AVE	PAE
PETITE AVENUE PTE AVE	PAE
PAE PET AVE	PAE
PAE PTE AVE	PAE
PETITE AVENUE	PAE
PARC	PARC
VOIE COMMUNALE PGE	PAS
PAS PGE	PAS
PASSAGE PGE	PAS
VC PGE	PAS
PASSAGE	PAS
PGE	PAS
PASSE	PASS
PETIT CHEMIN PT CHEM	PCH
PETIT CHEMIN PT CHEMIN	PCH
PETIT CHEMIN PETIT CHEM	PCH
PCH PET CHE	PCH
PCH PETIT CHEMIN	PCH
PETIT CHEMIN	PCH
PRESIDENT	PDT
PASSAGE	PGE
PHARE	PHAR
PISTE	PIST
PARKING	PKG
PLACA	PL
(PL) PLA	PL
PLACE	PL
PLAGE	PLAG
PLACIS	PLCI
PASSERELLE	PLE
PLAINE	PLN
PLATEAU	PLT
POINTE	PNT
PONT	PONT
PORTIQUE	PORQ
POSTE	POST
POTERNE	POT
PROFESSEUR	PROF
PROMENADE	PROM
PETITE ROUTE	PRT
PARVIS	PRV
PASTEUR	PAST
POINT	PT
PETITE ALLEE PTE ALL	PTA
PETITE ALLEE PTE ALLEE	PTA
PETITE ALLEE	PTA
PORTE	PTE
PETITE RUE PETITE RUE	PTR
PETITE RUE PTE RUE	PTR
PTR PETITE RUE	PTR
PTR PTE RUE	PTR
RUE (PETITE|PTE) RUE	PTR
PETITE RUE	PTR
PLACETTE	PTTE
QUARTIER	QRT
QRT	QUA
QUARTIER	QUA
QUAI	QUAI
RACCOURCI	RAC
RAVIN	RAV
ROUTE DEPARTEMENTALE	RD
RAIDILLON	RDL
REGIMENT	RGT
REGT	RGT
REMPART	REM
RESIDENCE	RES
RESIDENCES	RES
RGT INFANTERIE	RI
RGT ARTILLERIE	RA
REGIM	RGT
REGIMENT	RGT
R I A	RIA
RIVE	RIVE
CHEMIN RURAL DIT RUELLE	RLE
RUELLE	RLE
ROCADE	ROC
RAMPE	RPE
ROND POINT ROND POINT	RPT
RPT ROND POINT	RPT
ROND POINT	RPT
ROND-POINT	RPT
RD PT	RPT
ROTONDE	RTD
ROUTE	RTE
RUE RUE	RUE
RUETTE	RUET
RUISSEAU	RUIS
RUELLETTE	RULT
RAVINE	RVE
SAS	SAS
SCOLA(|I|IR|IRE)	SCOL
VOIE COMMUNALE STR	SEN
VC STE	SEN
VC STR	SEN
SENTE	SEN
SENTIER	SEN
SQUARE	SQ
SAINT	ST
STADE	STDE
SAINTE	STE
TOUR	TOUR
TERRE PLEIN	TPL
(TRA) TRAVERSE	TRA
TRABOULE	TRAB
TERRAIN	TRN
TERTRE	TRT
TERRASSE	TSSE
TUNNEL	TUN
VAL	VAL
VALLON	VALL
VOIE COMMUNALE	VC
VIEUX CHEMIN VIEUX CHEMIN	VCHE
VCHE VIEUX CHEMIN	VCHE
VIEUX CHEMIN	VCHE
VENELLE	VEN
VILLAGE	VGE
VIA	VIA
VC VIADUC	VIAD
VIADUC	VIAD
VILLE	VIL
VILLA	VLA
CHEMIN RURAL DIT VOIE	VOIE
VOIE COMMUNALE DITE VOIE	VOIE
VOIE COMMUNALE DITE	VOIE
VOIE COMMUNALE VOIE	VOIE
VC VOIE	VOIE
VOIE	VOIE
VOIRIE	VOIR
VOUTE	VOUT
VOYEUL	VOY
VIEILLE ROUTE	VTE
VIEUX	VX
ZONE ACTIVITE	ZA
ZONE ACTIVITES	ZA
ZONE ARTISANALE	ZA
ZA	ZA
ZONE AMENAGEMENT CONCERTE	ZAC
ZAC	ZAC
ZAD	ZAD
ZONE INDUSTRIELLE	ZI
ZONE INDUST	ZI
ZI	ZI
ZONE	ZONE
ZUP	ZUP
UN	1
DEUX	2
TROIS	3
QUATRE	4
CINQ	5
SIX	6
SEPT	7
HUIT	8
NEUF	9
DIX	10
ONZE	11
DOUZE	12
TREIZE	13
QUATORZE	14
QUINZE	15
SEIZE	16
DIX SEPT	17
DIX HUIT	18
DIX NEUF	19
VINGT	20
VINGTS	20
VING TROIS	23
PREMIER	1E
PREMIERE	1E
DEUXIEME	2E
TROISIEME	3E
QUATRIEME	4E
CINQUIEME	5E
SIXIEME	6E
SEPTIEME	7E
HUITIEME	8E
NEUVIEME	9E
DIXIEME	10E
ONZIEME	11E
DOUZIEME	12E
TREIZIEME	13E
QUATORZIEME	14E
QUINZIEME	15E
SEIZIEME	16E
VINGTIEME	20E
CENTIEME	100E
JANVIER	JAN
JANV	JAN
FEVRIER	FEV
JUILLET	JUIL
OCTOBRE	OCT
SEPTEMB	SEPTEMBRE
NOVEMBRE	NOV
DECEMBRE	DEC
\.


--
-- PostgreSQL database dump complete
--

