package dao;

import configDB.ConexionSQLServer;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import modelos.AlertaPedido;
import modelos.AsignacionPendienteResultado;
import modelos.PedidoAsignado;
import modelos.PedidoAsignadoDetalle;
import modelos.SolicitudTarjetaPlus;

public class PedidoAsignadoDAO {

    /**
     * Lista los pedidos abiertos del agente para el día actual.
     *
     * @param staffID StaffID del usuario logueado.
     * @return Lista de pedidos asignados con sus detalles.
     */
    public List<PedidoAsignado> listarPedidosAbiertosPorAgente(String staffID) {
        return listarPedidosAbiertosPorAgente(staffID, null, null, null);
    }

    /**
     * Lista los pedidos abiertos del agente filtrando por fecha.
     * Si fecha es null, el SP toma el rango actual.
     *
     * @param staffID StaffID del usuario.
     * @param fecha Fecha a consultar. Puede ser null.
     * @return Lista de pedidos asignados con sus productos.
     */
    public List<PedidoAsignado> listarPedidosAbiertosPorAgente(String staffID, java.util.Date fecha) {
        return listarPedidosAbiertosPorAgente(staffID, fecha, null, null);
    }

    /**
     * Lista pedidos abiertos según rol del usuario.
     *
     * Reglas del SP:
     * rol 1 = ve pedidos que no sean farmacia.
     * rol 4 = ve todos.
     * rol 5 = supervisor ve pedidos de farmacias asignadas.
     * otros roles = ven solo su StaffID.
     *
     * @param staffID StaffID del usuario logueado o filtro de farmacia.
     * @param fecha Fecha filtro. Puede ser null.
     * @param rolUsuario Rol del usuario logueado.
     * @return Lista de pedidos asignados con sus detalles.
     */
    public List<PedidoAsignado> listarPedidosAbiertosPorAgente(
            String staffID,
            java.util.Date fecha,
            Integer rolUsuario
    ) {
        return listarPedidosAbiertosPorAgente(staffID, fecha, rolUsuario, null);
    }

    /**
     * Lista pedidos abiertos según rol del usuario.
     *
     * Para supervisor:
     * - staffID funciona como filtro de farmacia. Puede ir null para ver todas sus farmacias.
     * - supervisorNombre se compara contra VW_FARMACIAS_SUPERVISOR.Supervisor.
     *
     * @param staffID StaffID del agente o filtro de farmacia.
     * @param fecha Fecha filtro. Puede ser null.
     * @param rolUsuario Rol del usuario logueado.
     * @param supervisorNombre Nombre del supervisor logueado.
     * @return Lista de pedidos asignados con sus detalles.
     */
    public List<PedidoAsignado> listarPedidosAbiertosPorAgente(
            String staffID,
            java.util.Date fecha,
            Integer rolUsuario,
            String supervisorNombre
    ) {

        List<PedidoAsignado> lista = new ArrayList<>();

        String sql = "{ CALL dbo.SP_PEDIDOS_ABIERTOS_POR_AGENTE(?,?,?,?) }";

        Map<Long, PedidoAsignado> mapaPedidos = new LinkedHashMap<>();

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            if (staffID == null || staffID.trim().isEmpty()) {
                cs.setNull(1, Types.NVARCHAR);
            } else {
                cs.setString(1, staffID.trim());
            }

            if (fecha == null) {
                cs.setNull(2, Types.DATE);
            } else {
                cs.setDate(2, new Date(fecha.getTime()));
            }

            if (rolUsuario == null || rolUsuario <= 0) {
                cs.setNull(3, Types.INTEGER);
            } else {
                cs.setInt(3, rolUsuario);
            }

            if (supervisorNombre == null || supervisorNombre.trim().isEmpty()) {
                cs.setNull(4, Types.NVARCHAR);
            } else {
                cs.setString(4, supervisorNombre.trim());
            }

            try (ResultSet rs = cs.executeQuery()) {

                while (rs.next()) {

                    long idPedidoGestion = rs.getLong("id_pedido_gestion");

                    PedidoAsignado pedido = mapaPedidos.get(idPedidoGestion);

                    if (pedido == null) {
                        pedido = mapearPedido(rs);
                        mapaPedidos.put(idPedidoGestion, pedido);
                    }

                    long idDetalle = rs.getLong("id_pedido_gestion_detalle");

                    if (!rs.wasNull()) {
                        PedidoAsignadoDetalle detalle = mapearDetalle(rs);
                        pedido.addDetalle(detalle);
                    }
                }
            }

            lista.addAll(mapaPedidos.values());

        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        return lista;
    }

    /**
     * Mapea el encabezado del pedido asignado.
     */
    private PedidoAsignado mapearPedido(ResultSet rs) throws SQLException {

        PedidoAsignado pedido = new PedidoAsignado();

        // Control
        pedido.setIdControlPedido(rs.getLong("id_control_pedido"));
        pedido.setStaffID(rs.getString("StaffID"));
        pedido.setNombreAgente(rs.getString("NombreAgente"));

        int rolAsignado = rs.getInt("RolAsignado");
        if (rs.wasNull()) {
            pedido.setRolAsignado(null);
        } else {
            pedido.setRolAsignado(rolAsignado);
        }

        pedido.setRolAsignadoDescripcion(rs.getString("RolAsignadoDescripcion"));

        pedido.setEstadoControl(rs.getInt("estado_control"));
        pedido.setEstadoControlDescripcion(rs.getString("estado_control_descripcion"));
        pedido.setFechaAsignacion(rs.getTimestamp("fecha_asignacion"));
        pedido.setFechaCierre(rs.getTimestamp("fecha_cierre"));
        pedido.setFechaCancelacion(rs.getTimestamp("fecha_cancelacion"));
        pedido.setObservacion(rs.getString("observacion"));

        // Encabezado
        pedido.setIdPedidoGestion(rs.getLong("id_pedido_gestion"));
        pedido.setIdPedidoWeb(rs.getLong("IdPedidoWeb"));
        pedido.setOrderIdWeb(rs.getString("OrderIdWeb"));
        pedido.setOrderCode(rs.getString("OrderCode"));

        int orderNumber = rs.getInt("OrderNumber");
        if (rs.wasNull()) {
            pedido.setOrderNumber(null);
        } else {
            pedido.setOrderNumber(orderNumber);
        }

        pedido.setCustomerName(rs.getString("CustomerName"));
        pedido.setCustomerPhone(rs.getString("CustomerPhone"));
        pedido.setCustomerEmail(rs.getString("CustomerEmail"));
        pedido.setCustomerIdentityDocument(rs.getString("CustomerIdentityDocument"));

        pedido.setDeliveryType(rs.getString("DeliveryType"));
        pedido.setRecipientName(rs.getString("RecipientName"));
        pedido.setDeliveryAddress(rs.getString("DeliveryAddress"));
        pedido.setDeliveryCity(rs.getString("DeliveryCity"));
        pedido.setDeliveryDepartment(rs.getString("DeliveryDepartment"));
        pedido.setDeliveryPhone(rs.getString("DeliveryPhone"));

        pedido.setBranchId(rs.getString("BranchId"));
        pedido.setBranchName(rs.getString("BranchName"));

        pedido.setContactName(rs.getString("ContactName"));
        pedido.setContactPhone(rs.getString("ContactPhone"));

        pedido.setPedidoSubtotal(rs.getBigDecimal("PedidoSubtotal"));
        pedido.setShipping(rs.getBigDecimal("Shipping"));
        pedido.setDiscount(rs.getBigDecimal("Discount"));
        pedido.setTotal(rs.getBigDecimal("Total"));
        pedido.setCurrency(rs.getString("Currency"));

        pedido.setPaymentMethod(rs.getString("PaymentMethod"));
        pedido.setPaymentStatus(rs.getString("PaymentStatus"));

        pedido.setHasTransfer(rs.getBoolean("HasTransfer"));
        pedido.setCallcenterRequired(rs.getBoolean("CallcenterRequired"));
        pedido.setCustomerNotes(rs.getString("CustomerNotes"));
        pedido.setCreatedAtWeb(rs.getTimestamp("CreatedAtWeb"));

        pedido.setFechaRecepcionLocal(rs.getTimestamp("fecha_recepcion_local"));
        pedido.setFechaFinalizacion(rs.getTimestamp("fecha_finalizacion"));

        pedido.setSolicitudTarjetaPlus(mapearSolicitudTarjetaPlus(rs));

        return pedido;
    }

    /**
     * Mapea la solicitud de Tarjeta Plus asociada al pedido, cuando el pedido
     * contiene alguno de los SKU de tarjeta (FF1005363 / FF1005364).
     * Devuelve null si el pedido no tiene solicitud asociada.
     */
    private SolicitudTarjetaPlus mapearSolicitudTarjetaPlus(ResultSet rs) throws SQLException {

        String solicitudOrderCode = rs.getString("SolicitudOrderCode");

        if (rs.wasNull() || solicitudOrderCode == null || solicitudOrderCode.trim().isEmpty()) {
            return null;
        }

        SolicitudTarjetaPlus solicitud = new SolicitudTarjetaPlus();

        solicitud.setOrderCode(solicitudOrderCode);
        solicitud.setCardSku(rs.getString("CardSku"));
        solicitud.setTipoTarjeta(rs.getString("TipoTarjeta"));
        solicitud.setFullName(rs.getString("FullName"));
        solicitud.setIdentityDocument(rs.getString("IdentityDocument"));
        solicitud.setEmail(rs.getString("Email"));
        solicitud.setPhone(rs.getString("Phone"));
        solicitud.setBirthdate(rs.getTimestamp("Birthdate"));
        solicitud.setLocationDepartment(rs.getString("LocationDepartment"));
        solicitud.setLocationCity(rs.getString("LocationCity"));
        solicitud.setLocationAddress(rs.getString("LocationAddress"));

        return solicitud;
    }

    /**
     * Mapea el detalle/producto del pedido asignado.
     */
    private PedidoAsignadoDetalle mapearDetalle(ResultSet rs) throws SQLException {

        PedidoAsignadoDetalle detalle = new PedidoAsignadoDetalle();

        detalle.setIdPedidoGestionDetalle(rs.getLong("id_pedido_gestion_detalle"));

        long idDetalleWeb = rs.getLong("IdDetalleWeb");
        if (rs.wasNull()) {
            detalle.setIdDetalleWeb(null);
        } else {
            detalle.setIdDetalleWeb(idDetalleWeb);
        }

        detalle.setSku(rs.getString("Sku"));
        detalle.setNombre(rs.getString("ProductoNombre"));
        detalle.setQuantity(rs.getBigDecimal("Quantity"));
        detalle.setUnitPrice(rs.getBigDecimal("UnitPrice"));
        detalle.setSubtotal(rs.getBigDecimal("ProductoSubtotal"));

        detalle.setCanje(rs.getBoolean("IsCanje"));
        detalle.setCanjePromocion(rs.getString("CanjePromocion"));
        detalle.setDescuentoTipo(rs.getString("DescuentoTipo"));

        detalle.setFechaRegistroDetalle(rs.getTimestamp("FechaRegistroDetalle"));

        return detalle;
    }

    public static class ResultadoOperacion {

        public String status;
        public String message;
        public Integer resultado;

        public ResultadoOperacion(String status, String message, Integer resultado) {
            this.status = status;
            this.message = message;
            this.resultado = resultado;
        }
    }

    public ResultadoOperacion cambiarEstadoPedido(long idControlPedido, String accion, String observacion) {

        if (idControlPedido <= 0) {
            return new ResultadoOperacion("error", "ID de control de pedido inválido.", null);
        }

        if (accion == null || accion.trim().isEmpty()) {
            return new ResultadoOperacion("error", "Debe indicar la acción del pedido.", null);
        }

        accion = accion.trim().toUpperCase();

        if (!accion.equals("CERRAR") && !accion.equals("CANCELAR")) {
            return new ResultadoOperacion("error", "Acción inválida. Use CERRAR o CANCELAR.", null);
        }

        if (accion.equals("CANCELAR") && (observacion == null || observacion.trim().isEmpty())) {
            return new ResultadoOperacion("error", "Debe ingresar una observación para cancelar el pedido.", null);
        }

        String sql = "{ CALL dbo.SP_PEDIDO_CONTROL_CAMBIAR_ESTADO(?,?,?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            cs.setLong(1, idControlPedido);
            cs.setString(2, accion);

            if (observacion == null || observacion.trim().isEmpty()) {
                cs.setNull(3, Types.NVARCHAR);
            } else {
                cs.setString(3, observacion.trim());
            }

            cs.registerOutParameter(4, Types.NVARCHAR);
            cs.registerOutParameter(5, Types.INTEGER);

            cs.execute();

            String mensaje = cs.getString(4);
            int resultado = cs.getInt(5);

            if (resultado > 0) {
                return new ResultadoOperacion("success", mensaje, resultado);
            }

            return new ResultadoOperacion("error", mensaje, resultado);

        } catch (SQLException ex) {
            return new ResultadoOperacion("error", ex.getMessage(), null);
        }
    }

    public AlertaPedido verificarNuevoPedidoAsignado(String staffID, long ultimoIdControlPedido, java.util.Date fecha) {

        AlertaPedido alerta = new AlertaPedido();
        alerta.setNuevo(false);

        if (staffID == null || staffID.trim().isEmpty()) {
            return alerta;
        }

        String sql = "{ CALL dbo.SP_PEDIDOS_ALERTA_AGENTE(?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            cs.setString(1, staffID.trim());
            cs.setLong(2, ultimoIdControlPedido);

            if (fecha == null) {
                cs.setNull(3, Types.DATE);
            } else {
                cs.setDate(3, new java.sql.Date(fecha.getTime()));
            }

            try (ResultSet rs = cs.executeQuery()) {

                if (rs.next()) {
                    alerta.setNuevo(rs.getBoolean("nuevo"));

                    long idControl = rs.getLong("id_control_pedido");
                    if (!rs.wasNull()) {
                        alerta.setIdControlPedido(idControl);
                    }

                    long idPedidoGestion = rs.getLong("id_pedido_gestion");
                    if (!rs.wasNull()) {
                        alerta.setIdPedidoGestion(idPedidoGestion);
                    }

                    alerta.setOrderIdWeb(rs.getString("OrderIdWeb"));
                    alerta.setOrderCode(rs.getString("OrderCode"));
                    alerta.setCustomerName(rs.getString("CustomerName"));
                    alerta.setCustomerPhone(rs.getString("CustomerPhone"));
                    alerta.setTotal(rs.getBigDecimal("Total"));
                    alerta.setFechaAsignacion(rs.getTimestamp("fecha_asignacion"));
                }
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
            alerta.setNuevo(false);
        }

        return alerta;
    }

    public AsignacionPendienteResultado asignarPedidosPendientes(
            Integer cantidad,
            String staffIDDestino,
            Integer idUsuarioAdmin
    ) {

        AsignacionPendienteResultado resultadoOperacion = new AsignacionPendienteResultado();

        resultadoOperacion.setCantidad(cantidad == null ? 0 : cantidad);
        resultadoOperacion.setStaffIDDestino(staffIDDestino);
        resultadoOperacion.setIdUsuarioAdmin(idUsuarioAdmin);

        String sql = "{ CALL dbo.SP_PEDIDO_CONTROL_ASIGNAR_PENDIENTES(?,?,?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            if (cantidad == null || cantidad <= 0) {
                cs.setNull(1, Types.INTEGER);
            } else {
                cs.setInt(1, cantidad);
            }

            if (staffIDDestino == null || staffIDDestino.trim().isEmpty()) {
                cs.setNull(2, Types.NVARCHAR);
            } else {
                cs.setString(2, staffIDDestino.trim());
            }

            if (idUsuarioAdmin == null || idUsuarioAdmin <= 0) {
                cs.setNull(3, Types.INTEGER);
            } else {
                cs.setInt(3, idUsuarioAdmin);
            }

            cs.registerOutParameter(4, Types.NVARCHAR);
            cs.registerOutParameter(5, Types.INTEGER);

            cs.execute();

            String mensaje = cs.getString(4);
            int resultado = cs.getInt(5);

            resultadoOperacion.setResultado(resultado);
            resultadoOperacion.setMensaje(mensaje);

            if (resultado >= 0) {
                resultadoOperacion.setStatus("success");
            } else {
                resultadoOperacion.setStatus("error");
            }

        } catch (SQLException ex) {
            resultadoOperacion.setStatus("error");
            resultadoOperacion.setResultado(-99);
            resultadoOperacion.setMensaje(ex.getMessage());
        }

        return resultadoOperacion;
    }
}