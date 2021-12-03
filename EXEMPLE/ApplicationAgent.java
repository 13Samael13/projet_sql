import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;
import java.util.regex.Pattern;

import org.mindrot.jbcrypt.BCrypt;

public class ApplicationAgent {

	private String url = "jdbc:postgresql://localhost/dbdvanden15?user=postgres&password=123456";
	private Connection conn = null;
	private PreparedStatement connectionAgent;
	private PreparedStatement informationSuperHeros;
	private PreparedStatement inscriptionSuperHeros;
	private PreparedStatement rapportCombat;
	private PreparedStatement rapportCombatParHeros;
	private PreparedStatement enregistrementSuperHeros;
	private PreparedStatement verifieCombat;
	private PreparedStatement listeSuperHeros;
	private PreparedStatement suppressionSuperHeros;
	private final static Scanner sc = new Scanner(System.in);
	private int idAgent = 0;

	static {
		sc.useDelimiter(Pattern.compile("\n|\r\n"));
	}

	public ApplicationAgent() {
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			System.out.println(e.getMessage().split("\n")[0]);
			System.exit(1);
		}
		try {
			conn = DriverManager.getConnection(url);
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
			System.exit(1);
		}
		try {
			connectionAgent = conn.prepareStatement("SELECT A.num_agent, A.nom_agent, A.mdp_agent FROM projet.agents A WHERE A.nom_agent = ? AND A.actif = 'O';");
			informationSuperHeros = conn.prepareStatement("SELECT SH.nom_heros, SH.nom_civil, SH.adresse_privee, SH.origine, SH.type_pouvoir, SH.puissance_pouvoir, SH.faction, SH.derniere_coordonnee_x, SH.derniere_coordonnee_y FROM projet.super_heros SH WHERE SH.nom_heros = ?;");
			inscriptionSuperHeros = conn.prepareStatement("SELECT * FROM projet.inscription_super_heros (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);");
			rapportCombat = conn.prepareStatement("SELECT * FROM projet.rapport_combat (?, ?, ?);");
			rapportCombatParHeros = conn.prepareStatement("SELECT * FROM projet.rapport_combat_individuel (?, ?, ?);");
			enregistrementSuperHeros = conn.prepareStatement(" SELECT * FROM projet.enregistrement_super_heros (?,?,?,?);");
			verifieCombat = conn.prepareStatement("SELECT * FROM projet.verifie_combat(?);");
			listeSuperHeros = conn.prepareStatement("SELECT SH.nom_heros FROM projet.super_heros SH WHERE SH.actif = 'O';");
			suppressionSuperHeros = conn.prepareStatement("SELECT * FROM projet.suppression_super_heros (?);");
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
			System.exit(1);
		}
	}

	public void close() {
		try {
			conn.close();
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	public static void main(String[] args) {
		ApplicationAgent p = new ApplicationAgent();
		p.connectionAgent();
		int choix, compteur;
		String[] table_choix = { "Demander de l'information sur un super héros", "Écrire un rapport de combat",
				"Enregistrer un super-héros", "Supprimer un super-héros" };
		do {
			compteur = 1;
			System.out.println("Que voulez vous faire");
			for (String c : table_choix) {
				System.out.println(compteur + " : " + c);
				compteur++;
			}
			choix = sc.nextInt();
			switch (choix) {
			case 1:
				p.listeSuperHeros();
				p.information();
				break;
			case 2:
				p.rapportDeCombat();
				break;
			case 3:
				p.enregistrerSuperHeros();
				break;
			case 4:
				p.listeSuperHeros();
				p.suppressionSuperHeros();
				break;
			default:
				break;
			}
			System.out.println();
		} while (choix >= 1 && choix <= table_choix.length);
		p.close();
	}

	private void connectionAgent() {
		int nbreConnexionMax = 5;
		try {
			do {
				System.out.println("Entrez votre nom");
				String nomAgent = sc.next();
				System.out.println("Entrez votre mdp");
				String mdp = sc.next();
				connectionAgent.setString(1, nomAgent);
				try (ResultSet rs = connectionAgent.executeQuery()) {
					while (rs.next()) {
						if (BCrypt.checkpw(mdp,  rs.getString(3))) {
							idAgent = rs.getInt(1);
							System.out.println("Vous êtes connecté en tant que " +  rs.getString(2) + "\n");
							return;
						} else {
							System.out.println("Mot de passe incorrect");
						}
					}
					if(nbreConnexionMax > 1) {
						System.out.println("Authentification échouée, veuillez recommencer");
					}
					nbreConnexionMax--;
				}
			} while (idAgent == 0 && nbreConnexionMax > 0);
			if(nbreConnexionMax == 0) {
				System.out.println("Vous avez dépasser le nombre d'essais de connexion possible !");
				System.exit(1);
			}
			System.out.println();
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void suppressionSuperHeros() {
		System.out.println("Entrez le nom du super-héros à supprimer");
		String nom = sc.next();
		try {
			suppressionSuperHeros.setString(1, nom);
			suppressionSuperHeros.executeQuery();
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void listeSuperHeros() {
		try {
			try (ResultSet rs = listeSuperHeros.executeQuery()) {
				System.out.println("Liste des Super-Héros :");
				System.out.println();
				while (rs.next()) {
					System.out.println(rs.getString(1));
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void information() {
		System.out.println("Quel est le super-héros dont vous voulez connnaître ses informations ?");
		String nomHeros = sc.next();
		try {
			informationSuperHeros.setString(1, nomHeros);
			try (ResultSet rs = informationSuperHeros.executeQuery()) {
				while (rs.next()) {
					System.out.println("Nom du héros : " + rs.getString(1) + "\nNom civil : " + rs.getString(2)
							+ "\nAdresse privée : " + rs.getString(3) + "\nOrigine : " + rs.getString(4)
							+ "\nType de pouvoir : " + rs.getString(5) + "\nPuissance de pouvoir : " + rs.getInt(6)
							+ "\nFaction : " + rs.getString(7) + "\nDernière Coordonnée : " + rs.getInt(8) + ";"
							+ rs.getInt(9));
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void enregistrerSuperHeros(String nom, int coordX, int coordY){
		try {
			enregistrementSuperHeros.setInt(1, coordX);
			enregistrementSuperHeros.setInt(2, coordY);
			enregistrementSuperHeros.setInt(3, idAgent);
			enregistrementSuperHeros.setString(4, nom);
			enregistrementSuperHeros.executeQuery();
		} catch (SQLException e) {
			if (e.getMessage().contains("ERREUR: data_exception")) {
				System.out.println("Le super-héros, "  + nom + ", n'existe pas dans la base de données !");
				inscriptionSuperHeros(nom, coordX, coordY);
			}
		}
	}
	
	private void enregistrerSuperHeros() {
		System.out.println("Entrez le nom du super-héros à enregister");
		String nom = sc.next();
		System.out.println("Entrez les coordonnées");
		int coordX = sc.nextInt();
		int coordY = sc.nextInt();
		enregistrerSuperHeros(nom, coordX, coordY);
	}

	private void inscriptionSuperHeros(String nomSuperHeros, int coordX, int coordY) {
		System.out.println("Entrez le nom civil du super-héros à enregister");
		String nomCivil = sc.next();
		System.out.println("Entrez son adresse privée");
		String adresse = sc.next();
		System.out.println("Entrez son origine");
		String origine = sc.next();
		System.out.println("Entrez son type de pouvoir");
		String typePouvoir = sc.next();
		System.out.println("Entrez la puissance du pouvoir");
		int puissance = sc.nextInt();
		System.out.println("Entrez sa faction (Marvelle ou Décé)");
		String faction = sc.next();
		try {
			inscriptionSuperHeros.setInt(1, idAgent);
			inscriptionSuperHeros.setString(2, nomSuperHeros);
			inscriptionSuperHeros.setString(3, nomCivil);
			inscriptionSuperHeros.setString(4, adresse);
			inscriptionSuperHeros.setString(5, origine);
			inscriptionSuperHeros.setString(6, typePouvoir);
			inscriptionSuperHeros.setInt(7, puissance);
			inscriptionSuperHeros.setString(8, faction);
			inscriptionSuperHeros.setInt(9, coordX);
			inscriptionSuperHeros.setInt(10, coordY);
			inscriptionSuperHeros.executeQuery();
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void rapportDeCombat() {
		System.out.println("Dans quelle zone ?");
		int coordX = sc.nextInt();
		int coordY = sc.nextInt();
		String[] tableauEnregistrements = null;
		try {
			int idCombat = -1;
			conn.setAutoCommit(false);
			rapportCombat.setInt(1, coordX);
			rapportCombat.setInt(2, coordY);
			rapportCombat.setInt(3, idAgent);
			ResultSet rs = rapportCombat.executeQuery();
			if (rs.next()) {
				idCombat = rs.getInt(1);
			}
			System.out.println("Combien de participants ?");
			int i = sc.nextInt();
			tableauEnregistrements = new String[i];
			for (int j = 1; j <= i; j++) {
				System.out.println("Entrez le nom du super-héros n°" + j);
				String nom = sc.next();
				System.out.println("Quel est son résultat ?");
				String resultat = sc.next();
				rapportCombatParHeros.setInt(1, idCombat);
				rapportCombatParHeros.setString(2, nom);
				rapportCombatParHeros.setString(3, resultat);
				rapportCombatParHeros.executeQuery();
				tableauEnregistrements[j - 1] = nom;
			}
			verifieCombat.setInt(1, idCombat);
			verifieCombat.executeQuery();
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		} finally {
			try {
				conn.setAutoCommit(true);
				for (String sh : tableauEnregistrements) {
					enregistrerSuperHeros(sh, coordX, coordY);
				}
			} catch (SQLException e) {
				System.out.println(e.getMessage().split("\n")[0]);
			}
		}
	}
}