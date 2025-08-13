DROP TABLE IF EXISTS sinistro CASCADE;
DROP TABLE IF EXISTS navi CASCADE;
DROP TABLE IF EXISTS aerei CASCADE;
DROP TABLE IF EXISTS struttura CASCADE;
DROP TABLE IF EXISTS personale CASCADE;
DROP TABLE IF EXISTS responsabile;
DROP TABLE IF EXISTS soccorso CASCADE;
DROP TABLE IF EXISTS conseguenze;
DROP TABLE IF EXISTS coinvolgimento;
DROP TABLE IF EXISTS utilizzoaerei;
DROP TABLE IF EXISTS utilizzonavi;
DROP TABLE IF EXISTS fornisce;
DROP TABLE IF EXISTS partecipazione;
DROP TABLE IF EXISTS prestavaservizio;
DROP TABLE IF EXISTS localita CASCADE;

CREATE TABLE localita
(
	citta 			varchar(35) not null,
	provincia 		varchar(30) not null,
	regione 		varchar(25) not null,
	primary key(citta)
);

CREATE TABLE struttura
(
	nome 				varchar(120) not null,
	citta 				varchar(35) not null
						references localita(citta)
						on update cascade
						on delete cascade,
	indirizzo 			varchar(120) not null,
	corpodiappartenenza varchar(120) not null,
	telefono 			varchar(15) not null,
	email 				varchar(100),
	primary key(nome, citta)
);

CREATE TABLE sinistro
(
	codice 				varchar(30) primary key,
	dataeorasinistro 	timestamp not null,
	nnavicoinvolte		integer not null,
	tipologia 			varchar(50) not null,
	causa 				varchar(50) not null,
	coordinate 			varchar(30),
	citta 				varchar(35)
						references localita(citta)
						on update cascade
						on delete set null
);

CREATE TABLE soccorso
(
	codice 				varchar(30) not null unique, 
	dataeorainizio  	timestamp not null,
	dataeorafine	 	timestamp,
	nmezziimpiegati 	integer,
	temporisposta 		interval,
	foreign key(codice) 
		references sinistro(codice)
		on update cascade
		on delete cascade
	
);

CREATE TABLE responsabile
(
	codicefiscale 	varchar(16) primary key,
	nome 			varchar(120) not null,
	cognome			varchar(120) not null,
	datadinascita 	date not null
);

CREATE TABLE navi
(
	matricola 			varchar(30) primary key,
	nome				varchar(120),
	tipologia 			varchar(30) not null,
	immersione			numeric(4,2),
	bandiera 			varchar(58) not null,
	equipaggio 			integer not null,
	lunghezza 			decimal(6,2),
	larghezza 			decimal(6,2),
	peso 				integer,
	velocità 			integer,
	dataimpostazione 	date,
	responsabile 		varchar(16)
		references responsabile(codicefiscale)
		on update cascade
		on delete set null,
	nomestruttura 			varchar(120),
	cittastruttura 			varchar(35),
	foreign key(nomestruttura, cittastruttura) 
		references struttura(nome, citta)
		on update cascade
		on delete set null
);

CREATE TABLE aerei
(
	matricola 				varchar(30) primary key,
	tipologia 				varchar(30) not null,
	quota 					integer,
	equipaggio 				integer not null,
	lunghezza 				decimal(6,2),
	larghezza 				decimal(6,2),
	peso 					integer,
	velocità 				integer,
	potenza 				integer,
	dataimpostazione 		date,	
	nomestruttura 			varchar(120),
	cittastruttura 			varchar(35),
	foreign key(nomestruttura, cittastruttura) 
		references struttura(nome, citta)
		on update cascade
		on delete set null
);

CREATE TABLE personale
(
	matricola 				serial primary key,
	nome 					varchar(120) not null,
	cognome 				varchar(120) not null,
	datadinascita 			date not null,
	codicefiscale			varchar(16) not null,
	grado 					varchar(120) not null,
	datacongedo 			date,
	inizioservizioattuale	date,
	nomestruttura 			varchar(120),
	cittastruttura 			varchar(35),
	foreign key(nomestruttura, cittastruttura) 
		references struttura(nome, citta)
		on update cascade
		on delete set null
);

CREATE TABLE conseguenze
(
	codice			varchar(30) primary key,
	nferiti 		integer,
	nmorti 			integer,
	area 			decimal(6,2),
	foreign key(codice)
		references sinistro(codice)
		on update cascade
		on delete cascade
);

CREATE TABLE prestavaservizio
(
	matricola 		integer not null
			references personale(matricola),
	datainizio 		date,
	datafine 		date not null,
	nomestruttura 	varchar(135) not null,
	cittastruttura 	varchar(35) not null,
	foreign key(nomestruttura, cittastruttura) 
		references struttura(nome, citta)
		on update cascade
		on delete cascade,
	primary key(matricola, nomestruttura, cittastruttura, datafine)
	
);

CREATE TABLE utilizzonavi
(
	soccorso 		varchar(30) not null 
					references soccorso(codice)
					on update cascade
					on delete cascade,
	nave 			varchar(9) not null 
					references navi(matricola)
					on update cascade
					on delete cascade,
	primary key(soccorso, nave)
);

CREATE TABLE utilizzoaerei
(
	soccorso 	varchar(30) not null 
				references soccorso(codice)
				on update cascade
				on delete cascade,
	aereo 		varchar(9) not null
				references aerei(matricola)
				on update cascade
				on delete cascade,
	primary key(soccorso, aereo)
);


CREATE TABLE fornisce
(
	soccorso 			varchar(30) not null
						references soccorso(codice)
						on update cascade
						on delete cascade
						deferrable initially deferred,
	nomestruttura 		varchar(120) not null,
	cittastruttura		varchar(35) not null,
						foreign key(nomestruttura, cittastruttura) 
						references struttura(nome, citta)
						on update cascade
						on delete cascade
						deferrable initially deferred,
	primary key(soccorso, nomestruttura, cittastruttura)
);

CREATE TABLE partecipazione
(
	soccorso 	varchar(30) not null
				references soccorso(codice)
				on update cascade
				on delete cascade,
	personale 	integer not null
				references personale(matricola)
				on update cascade
				on delete cascade,
	primary key(soccorso, personale)
);

CREATE TABLE coinvolgimento
(
	nave 				varchar(9) not null
						references navi(matricola)
						on update cascade
						on delete cascade
						deferrable initially deferred,
	codice 				varchar(30) not null
						references sinistro(codice)
						on update cascade
						on delete cascade
						deferrable initially deferred,
	primary key(nave, codice)
);