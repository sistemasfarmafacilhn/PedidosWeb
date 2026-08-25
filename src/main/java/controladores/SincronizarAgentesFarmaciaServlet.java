package controladores;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import configDB.ConexionSQLServer;
import utilidades.PasswordUtil;

@WebServlet(name = "SincronizarAgentesFarmaciaServlet", urlPatterns = {"/SincronizarAgentesFarmacia"})
public class SincronizarAgentesFarmaciaServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/vistas/sincronizarAgentesFarmacia.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        String sqlOrigen =
            "SELECT DISTINCT " +
            "U.USUARIO AS nombre, " +
            "U.USUARIO AS codigo, " +
            "U.CONTRASENIA AS password_plano, " +
            "R.STOREID AS StaffID " +
            "FROM [192.168.50.9,1433\\HQ].[HQ_CosavalLS].[dbo].[TBL_AE_PharmacyUsuarios_Login] U " +
            "INNER JOIN dbo.VW_FARMACIAS_SUPERVISOR R " +
            "ON R.CENTRO COLLATE DATABASE_DEFAULT = U.STOREID COLLATE DATABASE_DEFAULT " +
            "WHERE U.ROLE = 'FF' " +
            "AND U.USUARIO IS NOT NULL " +
            "AND LTRIM(RTRIM(U.USUARIO)) <> '' " +
            "AND U.CONTRASENIA IS NOT NULL " +
            "AND LTRIM(RTRIM(U.CONTRASENIA)) <> '' " +
            "AND NOT EXISTS (" +
                "SELECT 1 " +
                "FROM dbo.AGENTE A " +
                "WHERE A.codigo COLLATE DATABASE_DEFAULT = U.USUARIO COLLATE DATABASE_DEFAULT" +
            ")";

        String sqlInsert =
            "INSERT INTO dbo.AGENTE(nombre,codigo,salt,hash_password,StaffID,rol) " +
            "SELECT ?,?,?,?,?,3 " +
            "WHERE NOT EXISTS (" +
                "SELECT 1 " +
                "FROM dbo.AGENTE " +
                "WHERE codigo COLLATE DATABASE_DEFAULT = ? COLLATE DATABASE_DEFAULT" +
            ")";

        int encontrados = 0;
        int insertados = 0;
        int omitidos = 0;

        Connection conLectura = null;
        Connection conEscritura = null;

        try {

            conLectura = new ConexionSQLServer().getConnection();
            conEscritura = new ConexionSQLServer().getConnection();

            conEscritura.setAutoCommit(false);

            try (PreparedStatement psOrigen = conLectura.prepareStatement(sqlOrigen);
                 ResultSet rs = psOrigen.executeQuery();
                 PreparedStatement psInsert = conEscritura.prepareStatement(sqlInsert)) {

                while (rs.next()) {

                    encontrados++;

                    String nombre = rs.getString("nombre");
                    String codigo = rs.getString("codigo");
                    String passwordPlano = rs.getString("password_plano");
                    String staffID = rs.getString("StaffID");

                    if (nombre != null) nombre = nombre.trim();
                    if (codigo != null) codigo = codigo.trim();
                    if (passwordPlano != null) passwordPlano = passwordPlano.trim();
                    if (staffID != null) staffID = staffID.trim();

                    if (codigo == null || codigo.isEmpty()
                            || passwordPlano == null || passwordPlano.isEmpty()
                            || staffID == null || staffID.isEmpty()) {

                        omitidos++;
                        continue;
                    }

                    PasswordUtil.Result h = PasswordUtil.hashForStorage(passwordPlano);

                    psInsert.setString(1, nombre);
                    psInsert.setString(2, codigo);
                    psInsert.setString(3, h.saltB64);
                    psInsert.setString(4, h.hashB64);
                    psInsert.setString(5, staffID);
                    psInsert.setString(6, codigo);

                    int filas = psInsert.executeUpdate();

                    if (filas > 0) {
                        insertados++;
                    } else {
                        omitidos++;
                    }
                }

                conEscritura.commit();

                request.setAttribute("tipo", "success");
                request.setAttribute("mensaje", "Sincronización completada correctamente.");
                request.setAttribute("encontrados", encontrados);
                request.setAttribute("insertados", insertados);
                request.setAttribute("omitidos", omitidos);
            }

        } catch (Exception ex) {

            try {
                if (conEscritura != null) conEscritura.rollback();
            } catch (SQLException ignored) {
            }

            request.setAttribute("tipo", "error");
            request.setAttribute("mensaje", ex.getMessage());
            request.setAttribute("encontrados", encontrados);
            request.setAttribute("insertados", 0);
            request.setAttribute("omitidos", omitidos);

        } finally {

            try {
                if (conLectura != null) conLectura.close();
            } catch (SQLException ignored) {
            }

            try {
                if (conEscritura != null) conEscritura.close();
            } catch (SQLException ignored) {
            }
        }

        request.getRequestDispatcher("/vistas/sincronizarAgentesFarmacia.jsp").forward(request, response);
    }
}