package dao;

import configDB.ConexionSQLServer;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import modelos.ReportePedidoDelivery;

public class ReportePedidoDeliveryDAO {

    /**
     * Lista pedidos delivery para el reporte de call center.
     *
     * @param fechaInicio Fecha inicial del rango. Puede ser null.
     * @param fechaFin Fecha final del rango. Puede ser null.
     * @param staffIDAgente StaffID del agente a filtrar. Puede ser null o vacio para todos.
     * @return Lista de pedidos delivery que cumplen el filtro.
     */
    public List<ReportePedidoDelivery> listarReporte(
            java.util.Date fechaInicio,
            java.util.Date fechaFin,
            String staffIDAgente
    ) {

        List<ReportePedidoDelivery> lista = new ArrayList<>();

        String sql = "{ CALL dbo.SP_REPORTE_PEDIDOS_DELIVERY_LISTAR(?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            if (fechaInicio == null) {
                cs.setNull(1, Types.DATE);
            } else {
                cs.setDate(1, new Date(fechaInicio.getTime()));
            }

            if (fechaFin == null) {
                cs.setNull(2, Types.DATE);
            } else {
                cs.setDate(2, new Date(fechaFin.getTime()));
            }

            if (staffIDAgente == null || staffIDAgente.trim().isEmpty()) {
                cs.setNull(3, Types.NVARCHAR);
            } else {
                cs.setString(3, staffIDAgente.trim());
            }

            try (ResultSet rs = cs.executeQuery()) {

                while (rs.next()) {

                    ReportePedidoDelivery item = new ReportePedidoDelivery();

                    item.setFechaAsignacion(rs.getTimestamp("fecha_asignacion"));
                    item.setNombreAgente(rs.getString("NombreAgente"));
                    item.setStaffID(rs.getString("StaffID"));
                    item.setCustomerName(rs.getString("CustomerName"));
                    item.setCustomerPhone(rs.getString("CustomerPhone"));
                    item.setOrderCode(rs.getString("OrderCode"));
                    item.setOrderIdWeb(rs.getString("OrderIdWeb"));
                    item.setTotal(rs.getBigDecimal("Total"));
                    item.setCurrency(rs.getString("Currency"));
                    item.setEstadoControl(rs.getInt("estado_control"));
                    item.setEstadoControlDescripcion(rs.getString("estado_control_descripcion"));

                    lista.add(item);
                }
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        return lista;
    }
}
