package controladores;

import dao.PedidoAsignadoDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import modelos.Agente;
import modelos.AlertaPedido;

@WebServlet("/pedidos-alerta")
public class PedidoAlertaController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("usuarioObj") == null) {
            response.getWriter().write("{\"nuevo\":false,\"sesion\":false}");
            return;
        }

        Agente agente = (Agente) session.getAttribute("usuarioObj");

        /*
            Roles:
            1 = Administrador
            2 = Agente / Delivery
            3 = Farmacia
            4 = Vista total

            Solo rol 2 y rol 3 deben recibir alerta individual.
            Rol 1 y rol 4 no deben recibir alerta.
        */
        if (agente.getRol() == 1 || agente.getRol() == 4) {
            response.getWriter().write("{\"nuevo\":false,\"admin\":true}");
            return;
        }

        String staffID = agente.getStaffID();

        if (staffID == null || staffID.trim().isEmpty()) {
            response.getWriter().write("{\"nuevo\":false,\"sinStaffID\":true}");
            return;
        }

        String ultimoIdStr = request.getParameter("ultimoIdControlPedido");
        long ultimoIdControlPedido = parseLongOrDefault(ultimoIdStr, 0);

        /*
            Fecha que viene desde el JSP.
            Debe venir en formato yyyy-MM-dd.

            Si viene vacía o inválida, se manda NULL al SP
            y el SP usa su rango por defecto.
        */
        String fechaStr = request.getParameter("fecha");
        Date fechaFiltro = parseDateOrNull(fechaStr);

        PedidoAsignadoDAO dao = new PedidoAsignadoDAO();
        AlertaPedido alerta = dao.verificarNuevoPedidoAsignado(
                staffID,
                ultimoIdControlPedido,
                fechaFiltro
        );

        String json = construirJson(alerta);

        response.getWriter().write(json);
    }

    private String construirJson(AlertaPedido alerta) {

        if (alerta == null || !alerta.isNuevo()) {
            return "{\"nuevo\":false}";
        }

        String total = "0.00";

        BigDecimal totalPedido = alerta.getTotal();
        if (totalPedido != null) {
            total = totalPedido.toPlainString();
        }

        StringBuilder sb = new StringBuilder();

        sb.append("{");
        sb.append("\"nuevo\":true,");
        sb.append("\"idControlPedido\":").append(alerta.getIdControlPedido()).append(",");
        sb.append("\"idPedidoGestion\":").append(alerta.getIdPedidoGestion()).append(",");
        sb.append("\"orderIdWeb\":\"").append(escapeJson(alerta.getOrderIdWeb())).append("\",");
        sb.append("\"orderCode\":\"").append(escapeJson(alerta.getOrderCode())).append("\",");
        sb.append("\"customerName\":\"").append(escapeJson(alerta.getCustomerName())).append("\",");
        sb.append("\"customerPhone\":\"").append(escapeJson(alerta.getCustomerPhone())).append("\",");
        sb.append("\"total\":\"").append(escapeJson(total)).append("\",");
        sb.append("\"fechaAsignacion\":\"").append(
                alerta.getFechaAsignacion() != null
                        ? escapeJson(alerta.getFechaAsignacion().toString())
                        : ""
        ).append("\"");
        sb.append("}");

        return sb.toString();
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }

        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    private long parseLongOrDefault(String value, long defaultValue) {
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }

        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    private Date parseDateOrNull(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            sdf.setLenient(false);
            return sdf.parse(value.trim());
        } catch (ParseException ex) {
            return null;
        }
    }
}