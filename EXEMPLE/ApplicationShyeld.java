import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;
import java.util.regex.Pattern;

import org.mindrot.jbcrypt.BCrypt;

public class ApplicationShyeld {

	private String url = "jdbc:postgresql://localhost/dbdvanden15?user=postgres&password=123456";
	private Connection conn = null;
	private PreparedStatement inscriptionAgent;
	private PreparedStatement suppressionAgent;
	private PreparedStatement suppressionSuperHeros;
	private PreparedStatement perteVisibilite;
	private PreparedStatement avertissement;
	private PreparedStatement historique;
	private PreparedStatement listeAgents;
	private PreparedStatement listeSuperHeros;
	private PreparedStatement classementSuperHerosVictoire;
	private PreparedStatement classementSuperHerosDefaite;
	private PreparedStatement classementAgents;
	private PreparedStatement historiqueCombats;
	private final static Scanner sc = new Scanner(System.in);

	static {
		sc.useDelimiter(Pattern.compile("\n|\r\n"));
	}

	public ApplicationShyeld() {
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
			inscriptionAgent = conn.prepareStatement("SELECT * FROM projet.inscription_agent (?,?);");
			suppressionAgent = conn.prepareStatement("SELECT * FROM projet.suppression_agent(?);");
			suppressionSuperHeros = conn.prepareStatement("SELECT * FROM projet.suppression_super_heros(?);");
			perteVisibilite = conn.prepareStatement("SELECT * FROM projet.liste_super_heros_disparus;");
			avertissement = conn.prepareStatement("SELECT * FROM projet.liste_zones_dangereuses;");
			historique = conn.prepareStatement("SELECT * FROM projet.historique_agent  WHERE \"Nom Agent\" = ? AND \"Date Enregistrement\" BETWEEN to_timestamp(?, 'dd/mm/YYYY') AND to_timestamp(?, 'dd/mm/YYYY');");
			listeAgents = conn.prepareStatement("SELECT * FROM projet.agents A;");
			listeSuperHeros = conn.prepareStatement("SELECT SH.nom_heros, SH.actif FROM projet.super_heros SH;");
			classementSuperHerosVictoire = conn.prepareStatement("SELECT * FROM projet.classement_super_heros_victoire;");
			classementSuperHerosDefaite = conn.prepareStatement("SELECT * FROM projet.classement_defaite;");
			classementAgents = conn.prepareStatement("SELECT * FROM projet.agent_reperage;");
			historiqueCombats = conn.prepareStatement("SELECT * FROM projet.historique_combat WHERE \"Date du combat\" BETWEEN to_timestamp(?, 'dd/mm/YYYY') AND to_timestamp(?, 'dd/mm/YYYY');");
		} catch (SQLException e) {
			System.out.println("Erreur lors de la preparation des statement");
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
		ApplicationShyeld p = new ApplicationShyeld();
		System.out.println("Bienvenue dans l'application SHYELD");
		int choix, compteur;
		String[] table_choix = { "Inscrire un agent", "Supprimer un agent", "Information sur la perte de visibilité",
				"Suppression d'un Super Héros", "Liste des zones dangereuses", "Historique des relevés d'un agent",
				"Classement des super-héros en fonction de leurs victoires","Classement des super-héros en fonction de leurs défaites",
				"Clasement des agents selon leurs enregistrements", "Historique des combats" };
		do {
			compteur = 1;
			System.out.println("Que voulez-vous faire ?");
			for (String c : table_choix) {
				System.out.println(compteur + " : " + c);
				compteur++;
			}
			choix = sc.nextInt();
			switch (choix) {
			case 1:
				p.inscriptionAgent();
				break;
			case 2:
				p.listeAgents();
				p.suppressionAgent();
				break;
			case 3:
				p.infoVisibilite();
				break;
			case 4:
				p.listeSuperHeros();
				p.suppressionSuperHeros();
				break;
			case 5:
				p.listeZoneDangereuse();
				break;
			case 6:
				p.historique();
				break;
			case 7:
				p.classementSuperHerosVictoire();
				break;
			case 8:
				p.classementSuperHerosDefaite();
				break;
			case 9 :
				p.classementAgents();
				break;
			case 10 :
				p.historiqueCombats();
				break; 
			default:
				break;
			}
			System.out.println();
		} while (choix >= 1 && choix <= table_choix.length);
		p.close();
	}
	private void listeSuperHeros() {
		try {
			try (ResultSet rs = listeSuperHeros.executeQuery()) {
				while(rs.next()) {
					System.out.println(rs.getString(1) + " est " + (("O".equals(rs.getString(2))) ? "actif" : "inactif"));
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void listeAgents () {
		try {
			try (ResultSet rs = listeAgents.executeQuery()) {
				while (rs.next()) {
					System.out.println("Agent n°" + rs.getInt(1) + " répondant au nom de " + rs.getString(2) + " et actif = \"" + rs.getString(3) + "\"");
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void inscriptionAgent() {
		System.out.println("Entrez le nom de l'agent");
		String nom = sc.next();
		System.out.println("Entrez son mdp");
		String mdp = sc.next();
		String mdpHash = BCrypt.hashpw(mdp, BCrypt.gensalt(10)); 
		try {
			inscriptionAgent.setString(1, nom);
			inscriptionAgent.setString(2, mdpHash);
			inscriptionAgent.executeQuery();
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}
	
	private void classementAgents () {
		try {
			try (ResultSet rs = classementAgents.executeQuery()) {
				while (rs.next()) {
					System.out.println(rs.getString(1) + " a fait " + rs.getInt(2) + " enregistrements !");
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}
	
	private void historiqueCombats () {
		try {
			System.out.println("Date de début sous le format dd/mm/yyyy");
			String dateDebut = sc.next();
			System.out.println("Date de fin");
			String dateFin = sc.next();
			historiqueCombats.setString(1, dateDebut);
			historiqueCombats.setString(2, dateFin);
			try (ResultSet rs = historiqueCombats.executeQuery()) {
				while (rs.next()) {
					System.out.println(rs.getString(1) + " est le " + rs.getString(2) + " du combat se déroulant le " + rs.getString(3));
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}
	

	private void suppressionAgent() {
		System.out.println("Entrez le nom de l'agent à supprimer");
		String nom = sc.next();
		try {
			suppressionAgent.setString(1, nom);
			suppressionAgent.executeQuery();
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void infoVisibilite() {
		try {
			try (ResultSet rs = perteVisibilite.executeQuery()) {
				while (rs.next()) {
					System.out.println(rs.getString(1) + " a été vu pour la derniere fois le " + rs.getTimestamp(4) + " aux coordonnées (" + rs.getInt(2) + ";" + rs.getInt(3) + ")");
				}
			}
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
	
	private void classementSuperHerosVictoire () {
		System.out.println("Tableau des gagnants :");
		try {
			try (ResultSet rs = classementSuperHerosVictoire.executeQuery()) {
				while (rs.next()) {
					System.out.println(rs.getString(1) + " a gagné " + rs.getInt(2) + " fois !");
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
		
	}
	
	private void classementSuperHerosDefaite () {
		System.out.println("Tableau des perdants :");
		try {
			try (ResultSet rs = classementSuperHerosDefaite.executeQuery()) {
				while (rs.next()) {
					System.out.println(rs.getString(1) + " a perdu " + rs.getInt(2) + " fois !");
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void historique() {
		System.out.println("Entrez le nom de l'agent dont vous voulez obtenir l'historique");
		String nom = sc.next();
		System.out.println("Date de debut sous le format dd/mm/YYYY");
		String dateDebut = sc.next();
		System.out.println("Date de fin");
		String dateFin = sc.next();
		try {
			historique.setString(1, nom);
			historique.setString(2, dateDebut);
			historique.setString(3, dateFin);
			try (ResultSet rs = historique.executeQuery()) {
				while (rs.next()) {
					System.out.println(rs.getString(1) + " aux coordonnées (" + rs.getInt(3) + ";" + rs.getInt(4) + ") à la date du " + rs.getString(5));
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}

	private void listeZoneDangereuse() {
		try {
			try (ResultSet rs = avertissement.executeQuery()) {
				int compteur = 1;
				while (rs.next()) {
					System.out.println("Zone dangereuse n°" + compteur + " se trouvant aux coordonnées (" + rs.getInt(1) + ";" + rs.getInt(2) + ") et (" + rs.getInt(3) + ";" + rs.getInt(4) + ")");
					compteur++;
				}
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage().split("\n")[0]);
		}
	}
}