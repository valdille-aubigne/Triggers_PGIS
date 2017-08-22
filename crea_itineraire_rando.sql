-- Function: public.perso_crea_itineraire_rando()

-- DROP FUNCTION public.perso_crea_itineraire_rando();

CREATE OR REPLACE FUNCTION public.perso_crea_itineraire_rando()
  RETURNS trigger AS
$BODY$ 
DECLARE
i integer;

BEGIN

CREATE TABLE tempiti AS SELECT itineraire, iti_nom, url,gpx from rando.itineraire;

delete from rando.itineraire ;

FOR i IN select distinct itineraire from rando.iti_troncon LOOP
	insert into rando.itineraire (iti_long, geom, iti_chemin, itineraire, iti_nom, url, gpx, iti_duree)
	select round(cast(sum(st_length(rando.troncon.geom)*coeff)/1000 as numeric),2), st_linemerge(st_setsrid(st_union(rando.troncon.geom),2154)), 
		round(cast(avg(tabtemp.che)*100/sum(st_length(rando.troncon.geom)*coeff) as numeric),2), tempiti.itineraire, tempiti.iti_nom, tempiti.url, tempiti.gpx,
		extract(hour from to_timestamp(sum(st_length(rando.troncon.geom)*coeff)/1.1111))-1||'h'||extract(minute from to_timestamp(sum(st_length(rando.troncon.geom)*coeff)/1.1111))
	from tempiti, rando.iti_troncon, rando.troncon, (
		select sum(st_length(rando.troncon.geom)*coeff) as che
		from rando.iti_troncon, rando.troncon 
		where rando.troncon.id_tro = rando.iti_troncon.id_tro and rando.iti_troncon.itineraire = i and nat_voie <> 'ROU' group by rando.iti_troncon.itineraire) tabtemp
	where rando.troncon.id_tro = rando.iti_troncon.id_tro and rando.iti_troncon.itineraire = i and tempiti.itineraire = i
	group by rando.iti_troncon.itineraire, tempiti.itineraire, tempiti.iti_nom, tempiti.url, tempiti.gpx
	;
	
END LOOP;

DROP TABLE tempiti ;

RETURN new;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.perso_crea_itineraire_rando()
  OWNER TO postgres;
