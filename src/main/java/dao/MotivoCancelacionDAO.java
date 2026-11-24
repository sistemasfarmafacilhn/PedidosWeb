package dao;

import configDB.ConexionSQLServer;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import modelos.MotivoCancelacion;

public class MotivoCancelacionDAO {

    /**
     * Lista los motivos de cancelación activos, ordenados por tipo de
     * entrega (pickup/delivery) y orden de despliegue.
     */
    public List<MotivoCancelacion> listarActivos() {

        List<MotivoCancelacion> lista = new ArrayList<>();

        String sql = "{ CALL dbo.SP_MOTIVOS_CANCELACION_LISTAR }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql);
             ResultSet rs = cs.executeQuery()) {

            while (rs.next()) {

                MotivoCancelacion motivo = new MotivoCancelacion();

                motivo.setIdMotivo(rs.getInt("id_motivo"));
                motivo.setDescripcion(rs.getString("descripcion"));
                motivo.setTipoEntrega(rs.getString("tipo_entrega"));
                motivo.setOrden(rs.getInt("orden"));

                lista.add(motivo);
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        return lista;
    }
}
