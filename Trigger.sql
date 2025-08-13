/*TRIGGER 1*/
CREATE OR REPLACE FUNCTION	militarecongedo()
	returns trigger as $$
DECLARE
	DC timestamp;
	DS timestamp;
	dif interval;
BEGIN
	select datacongedo into DC
	from personale
	where matricola= new.personale;
	
	select dataeorainizio into DS
	from soccorso
	where codice = new.soccorso;
	
	dif= age (DC, DS);
	
	if DC is not null and dif < '0 years 0 months 0 days 0 hours 0 minutes' then
	raise exception 'Il membro del personale % è in congedo', NEW.personale;
	end if;
Return new;
END;
$$
language plpgsql;
	
	
create OR replace trigger ControlloPartecipazioneSoccorso
after insert on partecipazione
for each row
execute function militarecongedo();

/*TRIGGER 2*/
CREATE OR REPLACE FUNCTION PresenzaStruttura() returns trigger as $$
BEGIN
if (exists (select Codice from soccorso
	where codice not in (select soccorso from fornisce))) then
	RAISE EXCEPTION 'Struttura di risposta mancante';
end if;
return NEW;
END $$ LANGUAGE plpgsql;

	
create trigger PresenzaFornisce
after insert on Soccorso
for each row 
execute procedure PresenzaStruttura();

create trigger PresenzaFornisce
after delete on Struttura
for each row execute procedure PresenzaStruttura();

/*TRIGGER 3*/
CREATE OR REPLACE FUNCTION PresenzaNavi() returns trigger as $$
BEGIN
if exists(select C.codice
	from sinistro S join (select codice, count(*) as nt from coinvolgimento group by codice) AS C
	on(S.codice = C.codice)
	where S.nnavicoinvolte <> C.nt) then	
	RAISE EXCEPTION 'Numero navi coinvolte errato';
end if;
return NEW;
END $$ LANGUAGE plpgsql;

	
create trigger PresenzaCoinvolgimento
after insert on Sinistro
for each row 
execute procedure PresenzaNavi();

create trigger PresenzaCoinvolgimento
after delete on Navi
for each row execute procedure PresenzaNavi();

/*TRIGGER 4*/
CREATE OR REPLACE FUNCTION	CalcoloMezzi()
	returns trigger as $$
DECLARE
	nnavi integer;
	naerei integer;
	nmezzi integer;
BEGIN
	select count(*) into nnavi
	from utilizzonavi
	where soccorso = new.soccorso;
	
	select count(*) into naerei
	from utilizzoaerei
	where soccorso = new.soccorso;
	
	nmezzi = nnavi+naerei;
	
 	update soccorso 	
	set nmezziimpiegati = nmezzi
	where codice = new.soccorso;
RETURN new;
END;
$$ 
language plpgsql;


create OR replace trigger CalcoloMezziImpiegatiA 
	after update or insert on utilizzoaerei
	for each row
execute procedure CalcoloMezzi();


create OR replace trigger CalcoloMezziImpiegatiN
	after insert or update on utilizzonavi 
	for each row
execute procedure CalcoloMezzi();

/*TRIGGER 5*/
CREATE OR REPLACE FUNCTION	CalcoloTempo()
	returns trigger as $$
DECLARE
	dos timestamp;
BEGIN
	select dataeorasinistro into dos
	from sinistro
	where sinistro.codice = new.codice;
	new.temporisposta = AGE(new.dataeorainizio, dos);
RETURN new;
END;
$$ 
language plpgsql;

create OR replace trigger CalcoloTempoRisposta 
	before insert on soccorso 
	for each row
execute function CalcoloTempo();

/*TRIGGER 6*/
CREATE OR REPLACE FUNCTION	CreazionePrestavaServizioSuSpostamento()
	returns trigger as $$
BEGIN
	insert into prestavaservizio(matricola, datainizio, datafine, nomestruttura, cittastruttura)
	values (old.matricola, old.inizioservizioattuale, now() ,old.nomestruttura, old.cittastruttura); 
RETURN new;
END $$ language plpgsql;



create OR replace trigger ControlloSpostamentoPersonale
before update of nomestruttura, cittastruttura, inizioservizioattuale on personale 
for each row
execute function CreazionePrestavaServizioSuSpostamento();

/*TRIGGER 7*/
CREATE OR REPLACE FUNCTION	ControlloDisponibilita()
	returns trigger as $$
DECLARE 
	occupato 	integer;
	finito 		timestamp;
BEGIN
	select count(*) into occupato
	from utilizzonavi U join soccorso S on(U.soccorso = S.codice)
	where (U.nave = new.nave) and (S.dataeorafine is null);
	
	select dataeorafine into finito
	from soccorso
	where codice = new.soccorso ;
	
	IF (occupato >= 1) AND (finito is null) THEN
	RAISE EXCEPTION 'Nave gia occupata';
	END IF;
RETURN new;
END $$ language plpgsql;



create OR replace trigger ControlloSpostamentoPersonale
before insert on utilizzonavi
for each row
execute function ControlloDisponibilita();

/*TRIGGER 8*/
CREATE OR REPLACE FUNCTION	ControlloCorpo()
	returns trigger as $$
DECLARE 
	corpoV varchar(120);
	corpoN varchar(120);
BEGIN
	select distinct corpodiappartenenza INTO corpoV
	from struttura S 
	where (nome = old.nomestruttura) AND (citta = old.cittastruttura);
	
	select distinct corpodiappartenenza INTO corpoN
	from struttura 
	where (nome = new.nomestruttura) AND (citta = new.cittastruttura);
	
	IF corpoV <> corpoN THEN
	RAISE EXCEPTION 'Un membro del personale non può cambiare corpo di appartenenza';
	END IF;
RETURN new;

END $$ language plpgsql;


create OR replace trigger ControlloCorpiPassati
before update of nomestruttura, cittastruttura on personale 
for each row
execute function ControlloCorpo();
