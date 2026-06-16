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
         * Solo agentes normales deben recibir alerta.
         * Admin rol = 1 ve todos, pero no debe recibir alerta individual.
         */
        if (agente.getRol() == 1) {
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

        PedidoAsignadoDAO dao = new PedidoAsignadoDAO();
        AlertaPedido alerta = dao.verificarNuevoPedidoAsignado(staffID, ultimoIdControlPedido);

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
                alerta.getFechaAsignacion() != null ? escapeJson(alerta.getFechaAsignacion().toString()) : ""
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
}