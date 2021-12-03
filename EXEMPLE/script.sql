DROP SCHEMA examen CASCADE;
CREATE SCHEMA examen;
CREATE TABLE IF NOT EXISTS examen.aventuriers
(
	num_aventurier serial PRIMARY KEY,
	nom_aventurier varchar (50) UNIQUE NOT NULL,
	nombre_enregistrement integer NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS examen.enregistrements
(
	num_enregistrement serial PRIMARY KEY,
	aventurier integer NOT NULL REFERENCES examen.aventuriers (num_aventurier),
	zone char (5) NOT NULL CHECK (zone SIMILAR TO '[[:azerty:]]{2}[0-9]{3}'),
	date_enregistrement timestamp NOT NULL DEFAULT date_trunc('hour', now())
);

CREATE OR REPLACE FUNCTION examen.reperage_aventurier (varchar (50), char (5)) RETURNS INTEGER AS $$
	DECLARE
		v_nom_aventurier ALIAS FOR $1;
		v_zone ALIAS FOR $2;
		id_aventurier INTEGER := 0;
		id_enregistrement INTEGER := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM examen.aventuriers A WHERE A.nom_aventurier = v_nom_aventurier) THEN
			INSERT INTO examen.aventuriers VALUES (DEFAULT, v_nom_aventurier, DEFAULT)
			RETURNING num_aventurier INTO id_aventurier;
		ELSE
			SELECT A.num_aventurier FROM examen.aventuriers A WHERE A.nom_aventurier = v_nom_aventurier INTO id_aventurier;
		END IF;
		INSERT INTO examen.enregistrements VALUES (DEFAULT, id_aventurier, v_zone, DEFAULT)
		RETURNING num_enregistrement INTO id_enregistrement;
		RETURN id_enregistrement;
	END;	
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION examen.verifie_enregistrement () RETURNS TRIGGER AS $$
	BEGIN
		IF EXISTS (SELECT * FROM examen.enregistrements E 
		WHERE E.zone = NEW.zone AND E.date_enregistrement = NEW.date_enregistrement AND E.aventurier = NEW.aventurier) THEN
			RAISE EXCEPTION 'Cet aventurier a déjà été repérer dans cette zone à cette heure';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_verifie_enregistrement BEFORE INSERT ON examen.enregistrements
	FOR EACH ROW EXECUTE PROCEDURE examen.verifie_enregistrement();
CREATE OR REPLACE FUNCTION examen.nombre_enregistrement () RETURNS TRIGGER AS $$
	DECLARE
		nombre INTEGER :=0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM examen.enregistrements E WHERE E.date_enregistrement = NEW.date_enregistrement AND E.aventurier = NEW.aventurier) THEN
			nombre := 1;
		END IF;
		UPDATE examen.aventuriers A
			SET nombre_enregistrement = nombre_enregistrement + nombre
			WHERE A.nom_aventurier = NEW.aventurier;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_nombre_enregistrement AFTER INSERT ON examen.enregistrements
	FOR EACH ROW EXECUTE PROCEDURE examen.nombre_enregistrement();
CREATE OR REPLACE VIEW examen.classement_occupation AS
	SELECT E.zone AS "Zone", A.nom_aventurier AS "Aventurier", to_char(E.date_enregistrement, 'DD/MM/YYYY HH') AS "Date", A.nombre_enregistrement AS "Nombre"
	FROM examen.enregistrements E INNER JOIN examen.aventuriers A ON A.num_aventurier = E.aventurier
	ORDER BY 3, 1, 2;