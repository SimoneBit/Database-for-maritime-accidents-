--TEST TRIGGER 6 ControlloSpostamentoPersonale
update personale
set nomestruttura = 'Guardia di Finanza', cittastruttura = 'Carrara', inizioservizioattuale = now()
where matricola = 52

--TEST TRIGGER 8 Controllo corpi passati
update personale
set nomestruttura = 'Comando Stazione Navale Taranto', cittastruttura = 'Taranto'
where matricola = 2