DROP SCHEMA projet CASCADE;
-- schéma projet
CREATE SCHEMA projet;

-- table super_heros
CREATE TABLE IF NOT EXISTS projet.super_heros
(
	num_heros serial PRIMARY KEY,
	nom_heros varchar (50) NOT NULL CHECK (nom_heros != ''),
	nom_civil varchar (50) NOT NULL CHECK (nom_civil != ''),
	adresse_privee varchar(50) NOT NULL CHECK (adresse_privee != ''),
	origine varchar (50) NOT NULL CHECK (origine != ''),
	type_pouvoir text NOT NULL CHECK (type_pouvoir != ''),
	puissance_pouvoir integer NOT NULL CHECK (puissance_pouvoir > 0),
	faction varchar (8) NOT NULL CHECK (faction IN ('Marvelle', 'Décé')),
	actif char(1) NOT NULL DEFAULT 'O' CHECK (actif IN ('O', 'N')),
	derniere_coordonnee_x integer NOT NULL CHECK (derniere_coordonnee_x BETWEEN 0 AND 100),
	derniere_coordonnee_y integer NOT NULL CHECK (derniere_coordonnee_y BETWEEN 0 AND 100)
);

INSERT INTO projet.super_heros VALUES
	(DEFAULT, 'Le Docteur Dramas', 'Christophe Damas', 'ici', 'inconnue', 'xml', 1, 'Décé', DEFAULT, 0, 0),
	(DEFAULT, 'Madame Faire Mieux', 'Stéphanie Ferneeuw', 'ici', 'inconnue', 'uml', 2, 'Décé', DEFAULT, 25, 25),
	(DEFAULT, 'Gloriaux', 'Donatien Grolaux', 'ici', 'inconnue', 'javascript', 3, 'Marvelle', DEFAULT, 50, 50),
	(DEFAULT, 'Hulkriet', 'Bernard Henriet', 'ici', 'inconnue', 'c', 4, 'Marvelle', DEFAULT, 75, 75);

-- table agents
CREATE TABLE IF NOT EXISTS projet.agents
(
	num_agent serial PRIMARY KEY,
	nom_agent varchar (50) NOT NULL CHECK (nom_agent != ''),
	actif char (1) NOT NULL DEFAULT 'O' CHECK (actif IN ('O', 'N')),
	mdp_agent varchar (255) NOT NULL CHECK (mdp_agent != ''),
	nombre_enregistrement integer NOT NULL DEFAULT 0
);

-- table enregistrements
CREATE TABLE IF NOT EXISTS projet.enregistrements
(
	num_enregistrement serial PRIMARY KEY,
	date_enregistrement timestamp NOT NULL DEFAULT now() CHECK (date_enregistrement <= now()),
	coordonnee_x integer NOT NULL CHECK (coordonnee_x BETWEEN 0 AND 100),
	coordonnee_y integer NOT NULL CHECK (coordonnee_y BETWEEN 0 AND 100),
	agent integer NOT NULL REFERENCES projet.agents(num_agent),
	super_heros integer NOT NULL REFERENCES projet.super_heros (num_heros)
);

-- table combats
CREATE TABLE IF NOT EXISTS projet.combats
(
	num_combat serial PRIMARY KEY,
	date_combat timestamp NOT NULL DEFAULT now() CHECK (date_combat <= now()),
	coordonnee_x integer NOT NULL CHECK (coordonnee_x BETWEEN 0 AND 100),
	coordonnee_y integer NOT NULL CHECK (coordonnee_y BETWEEN 0 AND 100),
	agent integer NOT NULL REFERENCES projet.agents (num_agent)
);

-- table participants
CREATE TABLE IF NOT EXISTS projet.participants
(
	num_participant serial PRIMARY KEY,
	combat integer NOT NULL REFERENCES projet.combats (num_combat),
	super_heros integer REFERENCES projet.super_heros (num_heros),
	resultat char(7) NOT NULL CHECK (resultat IN ('perdant', 'gagnant', 'égalité'))
);

-- inscription_agent
CREATE OR REPLACE FUNCTION projet.inscription_agent(varchar (50), varchar (255)) RETURNS INTEGER AS $$
	DECLARE
		v_nom_agent ALIAS FOR $1;
		v_mdp_agent ALIAS FOR $2;
		id integer := 0;
	BEGIN
		INSERT INTO projet.agents VALUES (DEFAULT, v_nom_agent, DEFAULT, v_mdp_agent, DEFAULT)
		RETURNING num_agent INTO id;
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
-- SELECT * FROM projet.inscription_agent(?, ?);

-- verifie_insert_agent
CREATE OR REPLACE FUNCTION projet.verifie_insert_agent () RETURNS TRIGGER AS $$
	BEGIN
		IF EXISTS (SELECT * FROM projet.agents A WHERE A.nom_agent = NEW.nom_agent AND A.actif = 'O') THEN
			RAISE EXCEPTION 'Cet agent est déjà actif !';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_verif_insert_agent BEFORE INSERT ON projet.agents
	FOR EACH ROW EXECUTE PROCEDURE projet.verifie_insert_agent();

-- suppression_agent
CREATE OR REPLACE FUNCTION projet.suppression_agent (varchar (50)) RETURNS INTEGER AS $$
	DECLARE
		v_nom_agent ALIAS FOR $1;
		id INTEGER := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM projet.agents A WHERE A.nom_agent = v_nom_agent AND A.actif = 'O') THEN
			RAISE EXCEPTION 'pas d''agents à ce nom-là qui soit actif';
		END IF;
		UPDATE projet.agents A
		SET actif = 'N'
		WHERE A.nom_agent = v_nom_agent
		RETURNING A.num_agent INTO id;
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
-- SELECT * FROM projet.suppression_agent(?);

-- suppression_super_heros
CREATE OR REPLACE FUNCTION projet.suppression_super_heros (varchar (50)) RETURNS INTEGER AS $$
	DECLARE
		v_nom_heros ALIAS FOR $1;
		id INTEGER := 0;
	BEGIN
		UPDATE projet.super_heros SH
		SET actif = 'N'
		WHERE SH.nom_heros = v_nom_heros
		RETURNING SH.num_heros INTO id;
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
-- SELECT * FROM projet.suppression_super_heros(?);

-- enregistrement_super_heros
CREATE OR REPLACE FUNCTION projet.enregistrement_super_heros (integer, integer, integer, varchar (50)) RETURNS INTEGER AS $$
	DECLARE
		v_coordonnee_x ALIAS FOR $1;
		v_coordonnee_y ALIAS FOR $2;
		v_num_agent ALIAS FOR $3;
		v_nom_heros ALIAS FOR $4;
		v_num_heros integer;
		id integer := 0;
	BEGIN
		SELECT num_heros FROM projet.super_heros SH WHERE SH.nom_heros = v_nom_heros AND SH.actif = 'O' INTO v_num_heros;
		INSERT INTO projet.enregistrements
			VALUES (DEFAULT, DEFAULT, v_coordonnee_x, v_coordonnee_y, v_num_agent, v_num_heros)
			RETURNING num_enregistrement INTO id;
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
-- SELECT projet.enregistrement_super_heros (?, ?, ?, ?);

-- verifie_insert_enregistrement
CREATE OR REPLACE FUNCTION projet.verifie_insert_enregistrement () RETURNS TRIGGER AS $$
	BEGIN
		IF NOT EXISTS (SELECT * FROM projet.super_heros SH WHERE SH.num_heros = NEW.super_heros AND SH.actif = 'O') THEN
			RAISE EXCEPTION 'data_exception';
		END IF;
		IF EXISTS (SELECT * FROM projet.agents A WHERE A.num_agent = NEW.agent AND A.nom_agent = 'O') THEN
			RAISE EXCEPTION 'agent pas valide';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_verif_insert_enregistrement BEFORE INSERT ON projet.enregistrements
	FOR EACH ROW EXECUTE PROCEDURE projet.verifie_insert_enregistrement();
	
CREATE OR REPLACE FUNCTION projet.derniere_coordonnee () RETURNS TRIGGER AS $$
	BEGIN
		UPDATE projet.super_heros SH
		SET derniere_coordonnee_x = NEW.coordonnee_x,
			derniere_coordonnee_y = NEW.coordonnee_y
		WHERE SH.num_heros = NEW.super_heros;
		RETURN NEW;
	END;
$$LANGUAGE plpgsql;
CREATE TRIGGER trigger_derniere_position AFTER INSERT ON projet.enregistrements
	FOR EACH ROW EXECUTE PROCEDURE projet.derniere_coordonnee();

-- inscription_super_heros
CREATE OR REPLACE FUNCTION projet.inscription_super_heros (integer, varchar (50), varchar (50), varchar (50), varchar (50), text, integer, varchar (8), integer, integer) RETURNS INTEGER AS $$
	DECLARE
		v_num_agent ALIAS FOR $1;
		v_nom_heros ALIAS FOR $2;
		v_nom_civil ALIAS FOR $3;
		v_adresse_privee ALIAS FOR $4;
		v_origine ALIAS FOR $5;
		v_type_pouvoir ALIAS FOR $6;
		v_puissance_pouvoir ALIAS FOR $7;
		v_faction ALIAS FOR $8;
		v_coordonnee_x ALIAS FOR $9;
		v_coordonnee_y ALIAS FOR $10;
		id INTEGER := 0;
	BEGIN
		INSERT INTO projet.super_heros
			VALUES (DEFAULT, v_nom_heros, v_nom_civil, v_adresse_privee, v_origine, v_type_pouvoir, v_puissance_pouvoir, v_faction, DEFAULT, v_coordonnee_x, v_coordonnee_y)
		RETURNING num_heros INTO id;
		INSERT INTO projet.enregistrements VALUES (DEFAULT, DEFAULT, v_coordonnee_x, v_coordonnee_y, v_num_agent, id);
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
-- SELECT * FROM projet.inscription_super_heros(?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- verifie_super_heros
CREATE OR REPLACE FUNCTION projet.verifie_super_heros () RETURNS TRIGGER AS $$
	BEGIN
		IF (TG_OP = 'INSERT') THEN
			IF EXISTS (SELECT * FROM projet.super_heros SH WHERE SH.nom_heros = NEW.nom_heros AND SH.actif = 'O') THEN
				RAISE EXCEPTION 'Héros déjà vivant';
			END IF;
		END IF;
		IF (TG_OP = 'UPDATE') THEN
			IF NOT EXISTS (SELECT * FROM projet.super_heros SH WHERE SH.nom_heros = NEW.nom_heros) THEN
				RAISE EXCEPTION 'pas de super-héros à ce nom-là';
			END IF;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_verify_insert_super_heros BEFORE INSERT OR UPDATE ON projet.super_heros
	FOR EACH ROW EXECUTE PROCEDURE projet.verifie_super_heros();
	
-- rapport_combat
CREATE OR REPLACE FUNCTION projet.rapport_combat(integer, integer, integer) RETURNS INTEGER AS $$
	DECLARE
			v_coordonnee_x ALIAS FOR $1;
			v_coordonnee_y ALIAS FOR $2;
			v_agent ALIAS FOR $3;
			id_combat INTEGER := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM projet.combats CO WHERE CO.coordonnee_x = v_coordonnee_x AND CO.coordonnee_y = v_coordonnee_y AND CO.agent = v_agent) THEN
			INSERT INTO projet.combats VALUES (DEFAULT, DEFAULT, v_coordonnee_x, v_coordonnee_y, v_agent)
			RETURNING num_combat INTO id_combat;
		ELSE
			SELECT CO.num_combat FROM projet.combats CO WHERE CO.coordonnee_x = v_coordonnee_x AND CO.coordonnee_y = v_coordonnee_y AND CO.agent = v_agent INTO id_combat;
		END IF;
		RETURN id_combat;
	END;
$$ LANGUAGE plpgsql;

-- verifie_insert_combat
CREATE OR REPLACE FUNCTION projet.verifie_insert_combat () RETURNS TRIGGER AS $$
	BEGIN
		IF EXISTS (SELECT * FROM projet.combats CO WHERE CO.coordonnee_x = NEW.coordonnee_x AND CO.coordonnee_y = NEW.coordonnee_y AND CO.agent = NEW.agent) THEN
			RAISE EXCEPTION 'Combat déjà enregistré';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_verify_combat BEFORE INSERT ON projet.combats
	FOR EACH ROW EXECUTE PROCEDURE projet.verifie_insert_combat();

-- rapport_combat_indiviuel
CREATE OR REPLACE FUNCTION projet.rapport_combat_individuel(integer, varchar (50), char (7)) RETURNS INTEGER AS $$
	DECLARE
		v_combat ALIAS FOR $1;
		v_nom_heros ALIAS FOR $2;
		v_resultat ALIAS FOR $3;
		v_super_heros INTEGER := 0;
		id_participant INTEGER := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM projet.combats CO WHERE CO.num_combat = v_combat) THEN
			RAISE foreign_key_violation;
		END IF;
		IF NOT EXISTS (SELECT * FROM projet.super_heros SH WHERE SH.actif = 'O' AND SH.nom_heros = v_nom_heros) THEN
			RAISE foreign_key_violation;
		END IF;
		SELECT SH.num_heros FROM projet.super_heros SH WHERE SH.actif = 'O' AND SH.nom_heros = v_nom_heros INTO v_super_heros;
		IF NOT EXISTS (SELECT * FROM projet.participants PA WHERE PA.combat = v_combat AND PA.super_heros = v_super_heros) THEN
			INSERT INTO projet.participants VALUES (DEFAULT, v_combat, v_super_heros, v_resultat)
			RETURNING num_participant INTO id_participant;
		ELSE
			SELECT PA.num_participant FROM projet.participants PA WHERE PA.combat = v_combat AND PA.super_heros = v_super_heros INTO id_participant;
		END IF;
		RETURN id_participant;
	END;
$$ LANGUAGE plpgsql;

-- stat_agent()
CREATE OR REPLACE FUNCTION projet.stat_agent () RETURNS TRIGGER AS $$
	BEGIN
		UPDATE projet.agents A
		SET nombre_enregistrement = nombre_enregistrement + 1
		WHERE A.num_agent = NEW.agent;
		RETURN NULL;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_stat_agent AFTER INSERT ON projet.enregistrements
	FOR EACH ROW EXECUTE PROCEDURE projet.stat_agent();

-- verifie_combat
CREATE OR REPLACE FUNCTION projet.verifie_combat (integer) RETURNS INTEGER AS $$
	DECLARE
		v_num_combat ALIAS FOR $1;
	BEGIN
		IF NOT EXISTS (SELECT * FROM projet.super_heros SH1, projet.participants PA1,
		projet.combats CO, projet.participants PA2, projet.super_heros SH2 
		WHERE SH1.num_heros = PA1.super_heros AND SH2.num_heros = PA2.super_heros
		AND CO.num_combat = v_num_combat AND SH1.faction != SH2.faction) THEN
			RAISE EXCEPTION 'Combat invalide !';
		END IF;
		RETURN	v_num_combat;
	END;
$$ LANGUAGE plpgsql;

-- liste_zones
CREATE OR REPLACE VIEW projet.liste_zones_dangereuses AS
	SELECT DISTINCT ER.coordonnee_x AS "Coordonnée X", ER.coordonnee_y AS "Coordonée Y", ER2.coordonnee_x, ER2.coordonnee_y
	FROM projet.enregistrements ER, projet.enregistrements ER2, projet.super_heros SH, projet.super_heros SH2
	WHERE ER.super_heros = SH.num_heros AND SH2.num_heros = ER2.super_heros AND ER.date_enregistrement >= now() - interval '10 day' AND ER2.date_enregistrement >= now() - interval '10 day'
	AND SH.actif = 'O' AND SH2.faction != SH.faction AND SH2.actif = 'O' 
	AND ((ER.coordonnee_x = ER2.coordonnee_x + 1 AND ER.coordonnee_y = ER2.coordonnee_y) OR (ER.coordonnee_x = ER2.coordonnee_x AND ER2.coordonnee_y = ER.coordonnee_y + 1) OR (ER.coordonnee_x = ER2.coordonnee_x AND ER.coordonnee_y = ER2.coordonnee_y));
SELECT * FROM projet.liste_zones_dangereuses;

-- historique_agent
CREATE OR REPLACE VIEW projet.historique_agent AS
	SELECT SH.nom_heros AS "Nom Super Héros", A.nom_agent AS "Nom Agent", ER.coordonnee_x AS "Coordonnée X", 
	ER.coordonnee_y AS "Coordonnée Y", to_char(ER.date_enregistrement, 'DD/MM/YYYY') AS "Date Enregistrement"
	FROM projet.super_heros SH INNER JOIN projet.enregistrements ER ON ER.super_heros = SH.num_heros
	INNER JOIN projet.agents A ON A.num_agent = ER.agent
	ORDER BY 5;
-- SELECT * FROM projet.historique_agent WHERE "Nom Agent" = ? AND "Date Enregistrement" BETWEEN ? AND ?;

-- heros_combat
CREATE OR REPLACE VIEW projet.heros_combat AS
	SELECT SH.nom_heros AS "Nom héros", PA.resultat AS "Résultat du combat"
	FROM projet.super_heros SH INNER JOIN projet.participants PA ON PA.super_heros = SH.num_heros
	INNER JOIN projet.combats CO ON PA.combat = CO.num_combat
	ORDER BY CO.date_combat, SH.nom_heros;
SELECT * FROM projet.heros_combat;
	
-- agent_reperage
CREATE OR REPLACE VIEW projet.agent_reperage AS
	SELECT A.nom_agent AS "Nom de l'agent", COUNT(ER.*) AS "Total des enregistrements"
	FROM projet.agents A INNER JOIN projet.enregistrements ER ON ER.agent = A.num_agent
	GROUP BY A.nom_agent
	ORDER BY 2;
SELECT * FROM projet.agent_reperage;

-- historique_combat
CREATE OR REPLACE VIEW projet.historique_combat AS
	SELECT SH.nom_heros AS "Nom du héros", PA.resultat AS "Résultat du combat", to_char(CO.date_combat, 'DD/MM/YYYY') AS "Date du combat"
	FROM projet.super_heros SH INNER JOIN projet.participants PA ON PA.super_heros = SH.num_heros
	INNER JOIN projet.combats CO ON PA.combat = CO.num_combat
	ORDER BY CO.date_combat, PA.resultat, SH.nom_heros;
-- SELECT * FROM projet.historique_combat WHERE "Date du combat" BETWEEN ? AND ?;

-- liste_super_heros_disparus
CREATE OR REPLACE VIEW projet.liste_super_heros_disparus AS
	SELECT SH.nom_heros AS "Nom du héros", ER.coordonnee_x "Coordonnée X", ER.coordonnee_y AS "Coordonnée Y", to_char(ER.date_enregistrement, 'DD/MM/YYYY') AS "Date de l'enregistrement"
	FROM projet.super_heros SH INNER JOIN projet.enregistrements ER ON ER.super_heros = SH.num_heros
	WHERE ER.date_enregistrement <= now() - interval '15 day';
SELECT * FROM projet.liste_super_heros_disparus;

-- classement_super_heros_victoire
CREATE OR REPLACE VIEW projet.classement_super_heros_victoire AS
	SELECT SH.nom_heros AS "Nom du héros", COUNT(PA.*) AS "Nombre de victoires"
	FROM projet.super_heros SH, projet.participants PA
	WHERE PA.super_heros = SH.num_heros AND PA.resultat = 'gagnant'
	GROUP BY SH.nom_heros;
SELECT * FROM projet.classement_super_heros_victoire;

-- classement_super_heros_defaite
CREATE OR REPLACE VIEW projet.classement_super_heros_defaite AS
	SELECT SH.nom_heros AS "Nom du héros", COUNT(PA.*) AS "Nombre de défaites" 
	FROM projet.super_heros SH, projet.participants PA
	WHERE PA.super_heros = SH.num_heros AND PA.resultat = 'perdant'
	GROUP BY SH.nom_heros;
SELECT * FROM projet.classement_super_heros_defaite;

GRANT CONNECT ON DATABASE dbmandre16 TO dvanden15;
GRANT USAGE ON SCHEMA projet TO dvanden15;
GRANT USAGE ON SEQUENCE projet.super_heros_num_heros_seq, projet.combats_num_combat_seq, projet.participants_num_participant_seq, projet.enregistrements_num_enregistrement_seq TO dvanden15;
GRANT SELECT ON projet.super_heros, projet.agents, projet.enregistrements, projet.combats, projet.participants TO dvanden15;
GRANT INSERT ON projet.super_heros, projet.enregistrements, projet.combats, projet.participants TO dvanden15;
GRANT UPDATE (nombre_enregistrement) ON TABLE projet.agents TO dvanden15;
GRANT UPDATE (actif, derniere_coordonnee_x, derniere_coordonnee_y) ON TABLE projet.super_heros TO dvanden15;