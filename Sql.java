import java.sql.*;

public class Sql {

    public void driver(){
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
    }

    //Connection a la db --> conn
    public Connection connecter(){
        String url="jdbc:postgresql://localhost/Projet";
        Connection conn=null;
        try {
            conn= DriverManager.getConnection(url,"cdamas14","azerty");
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        return conn;
    }
    //Si on fais un select, on recupere le select
    public void resultSet(Connection conn){
        try {
            Statement s = conn.createStatement();
            try(ResultSet rs= s.executeQuery("SELECT nom"+
                    "FROM exercice.utilisateurs;"){
                while(rs.next()) {
                    System.out.println(rs.getString(1));
                }
            }//les deux try seront catch par ce catch
        } catch (SQLException se) {
            se.printStackTrace();
            System.exit(1);
        }
    }
    /*
    public PreparedStatement resultSet(Connection conn){
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT nom"+
                    "FROM exercice.utilisateurs;");
            try(ResultSet rs= ps.executeQuery("SELECT nom"+
                    "FROM exercice.utilisateurs;"){
                while(rs.next()) {
                    System.out.println(rs.getString(1));
                }
            }//les deux try seront catch par ce catch
        } catch (SQLException se) {
            se.printStackTrace();
            System.exit(1);
        }
    }


     */

    public void inscription(Connection conn,String nom, String prenom, String email, String motDePasse, int bloc, boolean paeValide, int nbrCreditPAE, int nbrCreditValide ){
        try {
            PreparedStatement ps = conn.prepareStatement("INSERT INTO"+ "Projet.etudiants VALUES (DEFAULT,?,?,?,?,?,?,?,?);");
            ps.setString(1,nom);
            ps.setString(2,prenom);
            ps.setString(3,email);
            ps.setString(4,motDePasse);
            ps.setInt(5,bloc);
            ps.setBoolean(6,paeValide);
            ps.setInt(7,nbrCreditPAE);
            ps.setInt(8,nbrCreditValide);
            ps.executeUpdate();

        } catch (SQLException se) {
            System.out.println("Erreur lors de l’insertion !");
            se.printStackTrace();
            System.exit(1);
        }
    }

    public static void main(String[] args) {
        String sel=BCrypt.gensalt();
    }
}