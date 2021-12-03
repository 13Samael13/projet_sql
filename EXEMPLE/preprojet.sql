DROP SCHEMA preprojet CASCADE;
CREATE SCHEMA preprojet;
-- Créez les tables en SQL.
CREATE TABLE IF NOT EXISTS preprojet.titulaires
(
	tit_id serial PRIMARY KEY,
	nom varchar (50) NOT NULL CHECK (nom SIMILAR TO '[[:alpha:]]+' AND char_length(nom) > 0),
	prenom varchar (50) NOT NULL CHECK (prenom SIMILAR TO '[[:alpha:]]+' AND char_length(prenom) > 0),
	mail varchar (100) NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS preprojet.comptebancaires
(
	id_compte char (10) PRIMARY KEY CHECK (id_compte SIMILAR TO '[0-9]{4}-[0-9]{5}'),
	titulaire integer NOT NULL REFERENCES preprojet.titulaires (tit_id)
);
CREATE TABLE IF NOT EXISTS preprojet.operations
(
	num_op serial PRIMARY KEY,
	source character (10) NOT NULL REFERENCES preprojet.comptebancaires (id_compte),
	destination char (10) NOT NULL REFERENCES preprojet.comptebancaires (id_compte),
	date_op timestamp DEFAULT now() NOT NULL CHECK (date_op <= now()),
	montant numeric (10, 2) NOT NULL CHECK (montant > 0),
	CHECK (source != destination)
);
CREATE INDEX pki_titulaire_ ON preprojet.comptebancaires USING btree (titulaire);
CREATE INDEX pki_op_source_ ON preprojet.operations USING btree (source);
CREATE INDEX pki_op_destination_ ON preprojet.operations USING btree (destination);
-- Insérez les tuples qui correspondent aux données ci-dessus.
INSERT INTO preprojet.titulaires VALUES
(DEFAULT, 'Damas', 'Christophe', 'christophe.damas@vinci.be'),
(DEFAULT, 'Grolaux', 'Donatien', 'donatien.grolaux@vinci.be'),
(DEFAULT, 'Ferneeuw', 'Stéphanie', 'stephanie.ferneeuw@vinci.be');
INSERT INTO preprojet.comptebancaires VALUES
('1234-56789', 1),
('5632-12564', 2),
('9876-87654', 1),
('7896-23565', 3),
('1236-02364', 2);
INSERT INTO preprojet.operations VALUES
(DEFAULT, '1234-56789', '5632-12564', '2006-12-01', 100),
(DEFAULT, '5632-12564', '1236-02364', '2006-12-02', 120),
(DEFAULT, '9876-87654', '7896-23565', '2006-12-03', 80),
(DEFAULT, '7896-23565', '9876-87654', '2006-12-04', 80),
(DEFAULT, '1236-02364', '7896-23565', '2006-12-05', 150),
(DEFAULT, '5632-12564', '1236-02364', '2006-12-06', 120),
(DEFAULT, '1234-56789', '5632-12564', '2006-12-07', 100),
(DEFAULT, '9876-87654', '7896-23565', '2006-12-08', 80),
(DEFAULT, '7896-23565', '9876-87654', '2006-12-09', 80);
-- Ecrivez la requête SQL permettant d'obtenir le tableau ci-dessus à partir de vos tables
-- normalisées (truc : triez par la date pour obtenir le même ordre).
CREATE VIEW preprojet.vue_globale AS
	SELECT TS.nom AS "Nom Source", TS.prenom AS "Prénom Source", CS.id_compte AS "Compte Source", TD.nom AS "Nom Destination",
	TD.prenom AS "Prénom Destination", CD.id_compte AS "Compte Destination", to_char(O.date_op, 'dd/mm/YYYY HH24:MI:SS') AS "Date Opération", O.montant AS "Montant"
	FROM preprojet.titulaires TS INNER JOIN preprojet.comptebancaires CS ON TS.tit_id = CS.titulaire
	INNER JOIN preprojet.operations O ON CS.id_compte = O.source
	INNER JOIN preprojet.comptebancaires CD ON CD.id_compte = O.destination
	INNER JOIN preprojet.titulaires TD ON TD.tit_id = CD.titulaire
	ORDER BY O.date_op;
SELECT * FROM preprojet.vue_globale;
-- Créez une procédure pour insérer une opération. La procédure prend en paramètre toutes
-- les données d’une opération, comme une ligne du tableau 1. La procédure doit vérifier
-- l’intégrité des données et effectuer toutes les modifications nécessaires dans la base de
-- données pour que l’opération y soit complètement insérée.
CREATE OR REPLACE FUNCTION preprojet.addOp(varchar (50), varchar (50), char (10), varchar (50), varchar (50), char (10), timestamp, numeric (10, 2)) RETURNS INTEGER AS $$
	DECLARE
		v_nom_source ALIAS FOR $1;
		v_prenom_source ALIAS FOR $2;
		v_compte_source ALIAS FOR $3;
		v_nom_destination ALIAS FOR $4;
		v_prenom_destination ALIAS FOR $5;
		v_compte_destination ALIAS FOR $6;
		v_date_op ALIAS FOR $7;
		v_montant ALIAS FOR $8;
		id INTEGER := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM preprojet.comptebancaires CS INNER JOIN preprojet.titulaires TS ON TS.tit_id = CS.titulaire
						WHERE CS.id_compte = v_compte_source AND TS.nom = v_nom_source AND TS.prenom = v_prenom_source) THEN
			RAISE foreign_key_violation;
		END IF;
		IF NOT EXISTS (SELECT * FROM preprojet.comptebancaires CD INNER JOIN preprojet.titulaires TD ON CD.titulaire = TD.tit_id
						WHERE CD.id_compte = v_compte_destination AND TD.nom = v_nom_destination AND TD.prenom = v_prenom_destination) THEN
			RAISE foreign_key_violation;
		END IF;
		INSERT INTO preprojet.operations
			VALUES (DEFAULT, v_compte_source, v_compte_destination, v_date_op, v_montant)
			RETURNING num_op INTO id;
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
SELECT * FROM preprojet.addOp('Damas', 'Christophe', '1234-56789', 'Grolaux', 'Donatien', '5632-12564', '2006-12-10', 15.5);
-- Créez une procédure pour modifier le montant d’une opération. La procédure prend en
-- paramètre toutes les données d’une opération, comme une ligne du tableau 1. La procédure
-- doit retrouver l’unique opération qui correspond à ces données mais en ignorant le montant.
-- Si elle n’en retrouve bien qu’une seule, alors le montant est mis à jour avec la valeur
-- correspondant passée en paramètre. Sinon une exception est levée.
CREATE OR REPLACE FUNCTION preprojet.updateOp(varchar (50), varchar (50), char (10), varchar (50), varchar (50), char (10), timestamp, numeric (10, 2)) RETURNS INTEGER AS $$
	DECLARE
		v_nom_source ALIAS FOR $1;
		v_prenom_source ALIAS FOR $2;
		v_compte_source ALIAS FOR $3;
		v_nom_destination ALIAS FOR $4;
		v_prenom_destination ALIAS FOR $5;
		v_compte_destination ALIAS FOR $6;
		v_date_op ALIAS FOR $7;
		v_montant ALIAS FOR $8;
		id INTEGER := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM preprojet.comptebancaires CS INNER JOIN preprojet.titulaires TS ON CS.titulaire = TS.tit_id
 					   WHERE CS.id_compte = v_compte_source AND TS.nom = v_nom_source AND TS.prenom = v_prenom_source) THEN
			RAISE foreign_key_violation;
		END IF;
		IF NOT EXISTS (SELECT * FROM preprojet.comptebancaires CD INNER JOIN preprojet.titulaires TD ON CD.titulaire = TD.tit_id
						WHERE CD.id_compte = v_compte_destination AND TD.nom = v_nom_destination AND TD.prenom = v_prenom_destination) THEN
			RAISE foreign_key_violation;
		END IF;
		IF 1 != (SELECT COUNT(O.*) FROM preprojet.titulaires TS INNER JOIN preprojet.comptebancaires CS ON TS.tit_id = CS.titulaire
				INNER JOIN preprojet.operations O ON O.source = CS.id_compte
				INNER JOIN preprojet.comptebancaires CD ON O.destination = CD.id_compte
				INNER JOIN preprojet.titulaires TD ON TD.tit_id = CD.titulaire
				WHERE O.date_op = v_date_op AND TD.nom = v_nom_destination AND TD.prenom = v_prenom_destination AND
				CD.id_compte = v_compte_destination AND TS.nom = v_nom_source AND TS.prenom = v_prenom_source
				AND CS.id_compte = v_compte_source) THEN
			RAISE data_exception;
		END IF;
		UPDATE preprojet.operations O
			SET montant = v_montant
			WHERE O.source = v_compte_source AND O.destination = v_compte_destination AND O.date_op = v_date_op
			RETURNING O.num_op INTO id;
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
SELECT * FROM preprojet.updateOp('Grolaux', 'Donatien', '1236-02364', 'Ferneeuw', 'Stéphanie', '7896-23565', '2006-12-05', 100);
-- Créez une procédure pour supprimer une opération. La procédure prend en paramètre
-- toutes les données d’une opération, comme une ligne du tableau 1. La procédure efface la
-- ou les opérations qui correspondent à ces données.
CREATE OR REPLACE FUNCTION preprojet.delOp(varchar (50), varchar (50), char (10), varchar (50), varchar (50), char (10), timestamp, numeric (10, 2)) RETURNS INTEGER AS $$
	DECLARE
		v_nom_source ALIAS FOR $1;
		v_prenom_source ALIAS FOR $2;
		v_compte_source ALIAS FOR $3;
		v_nom_destination ALIAS FOR $4;
		v_prenom_destination ALIAS FOR $5;
		v_compte_destination ALIAS FOR $6;
		v_date_op ALIAS FOR $7;
		v_montant ALIAS FOR $8;
		id INTEGER := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM preprojet.comptebancaires CS INNER JOIN preprojet.titulaires TS ON CS.titulaire = TS.tit_id
						WHERE CS.id_compte = v_compte_source AND TS.nom = v_nom_source AND TS.prenom = v_prenom_source) THEN
			RAISE foreign_key_violation;
		END IF;
		IF NOT EXISTS (SELECT * FROM preprojet.comptebancaires CD INNER JOIN preprojet.titulaires TD ON CD.titulaire = TD.tit_id
						WHERE CD.id_compte = v_compte_destination AND TD.nom = v_nom_destination AND TD.prenom = v_prenom_destination) THEN
			RAISE foreign_key_violation;
		END IF;
		IF NOT EXISTS (SELECT * FROM preprojet.operations O
				WHERE O.date_op = v_date_op AND O.montant = v_montant AND O.source = v_compte_source AND O.destination = v_compte_destination) THEN
			RAISE data_exception;
		END IF;
		DELETE FROM preprojet.operations O
			WHERE O.source = v_compte_source AND O.destination = v_compte_destination AND O.date_op = v_date_op AND O.montant = v_montant
			RETURNING O.num_op INTO id;
		RETURN id;
	END;
$$ LANGUAGE plpgsql;
SELECT * FROM preprojet.delOp('Grolaux', 'Donatien', '1236-02364', 'Ferneeuw', 'Stéphanie', '7896-23565', '2006-12-05', 100);
-- Créez une procédure qui affiche l’évolution d’un compte bancaire au cours du temps. Le
-- paramètre de la procédure est le numéro du compte bancaire. A chaque fois qu’il y a une
-- opération avec ce compte, une ligne affiche la date de l’opération, avec qui cette opération
-- se fait et quelle est la balance du compte suite à cette dernière.
CREATE TYPE preprojet.listeLignesOperations
	AS (date_op timestamp, nom_autre_compte varchar (50), prenom_autre_compte varchar (50), autre_compte char (10), balance numeric (10, 2));
CREATE OR REPLACE FUNCTION preprojet.evolCompte(char (10)) RETURNS SETOF preprojet.listeLignesOperations AS $$
	DECLARE
		v_compte_bancaire ALIAS FOR $1;
		sortie RECORD;
		operation RECORD;
		autre_compte RECORD;
		v_balance numeric (10, 2) := 0;
	BEGIN
		IF NOT EXISTS (SELECT * FROM preprojet.comptebancaires CB WHERE CB.id_compte = v_compte_bancaire) THEN
			RAISE data_exception;
		END IF;
		FOR operation IN SELECT * FROM preprojet.operations O 
		WHERE  O.source = v_compte_bancaire OR O.destination = v_compte_bancaire
		ORDER BY O.date_op LOOP
			IF (operation.source = v_compte_bancaire) THEN
				v_balance := v_balance - operation.montant;
				SELECT * FROM preprojet.comptebancaires CB INNER JOIN preprojet.titulaires T ON T.tit_id = CB.titulaire WHERE CB.id_compte = operation.destination INTO autre_compte;
			ELSE
				v_balance := v_balance + operation.montant;
				SELECT * FROM preprojet.comptebancaires CB INNER JOIN preprojet.titulaires T ON T.tit_id = CB.titulaire WHERE CB.id_compte = operation.source INTO autre_compte;
			END IF;
			SELECT operation.date_op, autre_compte.nom, autre_compte.prenom, autre_compte.id_compte, v_balance INTO sortie;
			RETURN NEXT sortie;
		END LOOP;
		RETURN;
	END;
$$ LANGUAGE plpgsql;
SELECT * FROM preprojet.evolCompte('1236-02364') EC WHERE EC.balance > 0;
-- Pour chaque compte en banque, ajoutez un champ balance_total. Ce champ contiendra la
-- balance du compte en banque (somme de tous les montants dont ce compte est destinataire
-- moins la somme de tous les montants dont ce compte est l’origine). Créez un trigger pour
-- mettre ce champ à jour automatiquement.
ALTER TABLE preprojet.comptebancaires
	ADD COLUMN balance_totale numeric (10, 2) DEFAULT 0;
CREATE OR REPLACE FUNCTION preprojet.updateBalanceTotale() RETURNS TRIGGER AS $$
	BEGIN
		IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
			UPDATE preprojet.comptebancaires CS
				SET balance_totale = balance_totale - NEW.montant
				WHERE CS.id_compte = NEW.source;
			UPDATE preprojet.comptebancaires CD
				SET balance_totale = balance_totale + NEW.montant
				WHERE CD.id_compte = NEW.destination;
			IF (TG_OP = 'INSERT') THEN
				RETURN NEW;
			END IF;
		END IF;
		IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
			UPDATE preprojet.comptebancaires CS
				SET balance_totale = balance_totale + OLD.montant
				WHERE CS.id_compte = OLD.source;
			UPDATE preprojet.comptebancaires CD
				SET balance_totale = balance_totale - OLD.montant
				WHERE CD.id_compte = OLD.destination;
			RETURN NULL;
		END IF;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_balance_totale AFTER INSERT OR UPDATE OR DELETE ON preprojet.operations
		FOR EACH ROW EXECUTE PROCEDURE preprojet.updateBalanceTotale();
SELECT * FROM preprojet.comptebancaires;
SELECT * FROM preprojet.addOp('Damas', 'Christophe', '1234-56789', 'Grolaux', 'Donatien', '5632-12564', '2006-12-10', 15.5);
SELECT * FROM preprojet.comptebancaires;
-- Pour chaque personne, ajoutez un champ balance_utilisateur. Ce champ contiendra la
-- somme des balances de tous ses comptes. Créez un trigger pour mettre ce champ à jour
-- automatiquement.
ALTER TABLE preprojet.titulaires
	ADD COLUMN balance_utilisateur numeric (10, 2) DEFAULT 0;
CREATE OR REPLACE FUNCTION preprojet.updateBalanceUtilisateur() RETURNS TRIGGER AS $$
	BEGIN
		IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
			UPDATE preprojet.titulaires T
				SET balance_utilisateur = balance_utilisateur + NEW.balance_totale
				WHERE NEW.titulaire = T.tit_id;
			IF(TG_OP = 'INSERT') THEN
				RETURN NEW;
			END IF;
		END IF;
		IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
			UPDATE preprojet.titulaires T
				SET balance_utilisateur = balance_utilisateur - OLD.balance_totale
				WHERE OLD.titulaire = T.tit_id;
			RETURN NULL;
		END IF;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_balance_utilisateur AFTER INSERT OR UPDATE OR DELETE ON preprojet.comptebancaires
		FOR EACH ROW EXECUTE PROCEDURE preprojet.updateBalanceUtilisateur();
SELECT * FROM preprojet.titulaires;
SELECT * FROM preprojet.addOp('Damas', 'Christophe', '1234-56789', 'Grolaux', 'Donatien', '5632-12564', '2006-12-10', 15.5);
SELECT * FROM preprojet.titulaires;
GRANT SELECT ON TABLE preprojet.titulaires, preprojet.comptebancaires, preprojet.operations, preprojet.vue_globale TO PUBLIC;
ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;