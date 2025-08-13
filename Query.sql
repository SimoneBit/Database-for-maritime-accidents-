--Query 1
select tipologia, avg(temporisposta) as mediatemporisposta, avg(nmezziimpiegati) as mediamezzi, avg(persone) as mediapersone, avg(tempo) as mediatempodurata
from soccorso So join sinistro Si
			on(So.codice = Si.codice)
          join (select soccorso, count(personale) as persone
                   from partecipazione
                   group by soccorso) as P
         on(So.codice = P.soccorso)
join (select codice, age(dataeorafine, dataeorainizio) as tempo
                      from soccorso) as T
             on(So.codice = T.codice)
group by tipologia;

--Query 2
select count(*)
from Soccorso soc 
where soc.codice in(select soccorso
					from utilizzonavi U
					where U.nave in (select matricola
									 from Navi N 
									 where exists (select nome, citta											
													from Struttura S
													where S.nome=N.nomestruttura 
												   	and S.citta=N.cittastruttura 
												   	and S.corpodiappartenenza='Guardia Costiera'))) 
and soc.dataeorainizio>'2000-01-01 00:00:00' 
and soc.dataeorafine<'2022-06-06 23:59:59';

--Query 3
select N.matricola, S.nome, S.citta, S.corpodiappartenenza
from navi N join struttura S 
			on (N.nomeStruttura = S.nome AND N.cittastruttura = S.citta)
where S.corpodiappartenenza = 'Marina Militare'
union
select A.matricola, S.nome, S.citta, S.corpodiappartenenza
from aerei A join struttura S 
			on (A.nomeStruttura = S.nome AND A.cittastruttura = S.citta)
where S.corpodiappartenenza = 'Marina Militare'

--Query 4
select matricola, tipologia, nomestruttura, cittastruttura
from navi N  join utilizzonavi U on (N.matricola = U.nave)
join soccorso S on(U.soccorso = S.codice)
where S.dataeorafine is null and N.cittastruttura = any(select citta 
													from localita
													where provincia = 'Genova');
													
--Query 5
select Sso.soccorso, So.corpodiappartenenza 
from ((select Sc.soccorso as soccorso
		from (select distinct F.soccorso, S.corpodiappartenenza
			  from fornisce F join struttura S 
			  on (F.nomeStruttura = S.nome AND F.cittastruttura = S.citta)) as Sc
		group by Sc.soccorso
		HAVING (count(*) >1)) as Sso
		join (select distinct F.soccorso as soccorso, S.corpodiappartenenza 
			from fornisce F join struttura S 
			on (F.nomeStruttura = S.nome AND F.cittastruttura = S.citta)) as So
		on (Sso.soccorso = So.soccorso))
		
--Vista e Query
create view MediaTipologia (codice, nmorti, tipologia, media, numtip) as
select Co.codice, Co.nmorti, M.tipologia, media, (select count(*)
														from Sinistro S
														where S.tipologia = M.tipologia)
from Sinistro S join (select tipologia,avg(nmorti) as media
                                   from Sinistro S join conseguenze C
									on (S.codice = C.codice)
                                   group by tipologia) as M
           				 on (S.tipologia = M.tipologia)
		join Conseguenze Co 
		on(S.codice = Co.codice);
		
		
		
select *
from MediaTipologia
where media= all(select max(media)
				 from MediaTipologia)
and nmorti = any(select max(nmorti)
				from MediaTipologia);

		