package controladores;

import dao.AgenteDAO;
import dao.PedidoAsignadoDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import modelos.Agente;
import modelos.AsignacionPendienteResultado;
import modelos.PedidoAsignado;

@WebServlet("/pedidos-agente")
public class PedidoAsignadoController extends HttpServlet {

    // ============================================================
    // GET -> Mostrar pedidos abiertos del agente logueado
    // ============================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        cargarPedidos(request, response);
    }

    // ============================================================
    // POST -> Filtrar / cerrar / cancelar
    // ============================================================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String accion = request.getParameter("accion");

        if (accion == null || accion.trim().isEmpty()) {
            accion = "filtrar";
        }

        switch (accion) {
            case "cerrarPedido":
                cerrarPedido(request, response);
                break;

            case "cancelarPedido":
                cancelarPedido(request, response);
                break;
                
                    case "cambiarEstadoAgente":
        cambiarEstadoAgente(request, response);
        break;
        
        case "asignarPendientes":
    asignarPendientes(request, response);
    break;

            case "filtrar":
            default:
                cargarPedidos(request, response);
                break;
        }
    }

    // ============================================================
    // CARGAR PEDIDOS
    // ============================================================
private void cargarPedidos(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {

    HttpSession session = request.getSession(false);

    if (session == null || session.getAttribute("usuarioObj") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    Agente agente = (Agente) session.getAttribute("usuarioObj");

    Integer rolSesion = null;
    Object rolObj = session.getAttribute("rol");

    if (rolObj instanceof Integer) {
        rolSesion = (Integer) rolObj;
    } else if (rolObj != null) {
        try {
            rolSesion = Integer.parseInt(rolObj.toString());
        } catch (NumberFormatException ex) {
            rolSesion = agente.getRol();
        }
    } else {
        rolSesion = agente.getRol();
    }

    boolean esAdmin = rolSesion != null && rolSesion == 1;

    String staffID = agente.getStaffID();
    String staffIDFiltro = request.getParameter("staffIDFiltro");

    /*
     * rol = 1 Administrador
     * Admin puede ver todos o filtrar por StaffID desde combo.
     *
     * Agente normal siempre ve solo su propio StaffID.
     */
    if (esAdmin) {
        if (staffIDFiltro != null && !staffIDFiltro.trim().isEmpty()) {
            staffID = staffIDFiltro.trim();
        } else {
            staffID = null;
        }
    } else {
        if (staffID == null || staffID.trim().isEmpty()) {
            request.setAttribute("error", "El usuario logueado no tiene StaffID configurado.");
            request.getRequestDispatcher("/vistas/pedidos_agente.jsp").forward(request, response);
            return;
        }
    }

    String fechaStr = request.getParameter("fecha");
    Date fechaFiltro = null;

    if (fechaStr != null && !fechaStr.trim().isEmpty()) {
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            sdf.setLenient(false);
            fechaFiltro = sdf.parse(fechaStr.trim());
        } catch (ParseException ex) {
            request.setAttribute("error", "La fecha ingresada no es válida.");
            request.setAttribute("fechaSeleccionada", fechaStr);
            request.setAttribute("staffIDFiltro", staffIDFiltro == null ? "" : staffIDFiltro);
            request.getRequestDispatcher("/vistas/pedidos_agente.jsp").forward(request, response);
            return;
        }
    }

    PedidoAsignadoDAO pedidoDAO = new PedidoAsignadoDAO();
    List<PedidoAsignado> pedidos = pedidoDAO.listarPedidosAbiertosPorAgente(staffID, fechaFiltro);

    /*
     * Lista para combo del admin.
     */
    List<Agente> agentes = null;

    if (esAdmin) {
        AgenteDAO agenteDAO = new AgenteDAO();
        agentes = agenteDAO.listarAgentes();
    }

    request.setAttribute("pedidos", pedidos);
    request.setAttribute("agentes", agentes);
    request.setAttribute("staffID", staffID == null ? "" : staffID);
    request.setAttribute("staffIDFiltro", staffIDFiltro == null ? "" : staffIDFiltro);
    request.setAttribute("agenteNombre", agente.getNombre());
    request.setAttribute("fechaSeleccionada", fechaStr == null ? "" : fechaStr);

    request.getRequestDispatcher("/vistas/pedidos_agente.jsp").forward(request, response);
}

    // ============================================================
    // CERRAR PEDIDO
    // ============================================================
private void cerrarPedido(HttpServletRequest request, HttpServletResponse response)
        throws IOException {

    HttpSession session = request.getSession(false);

    if (session == null || session.getAttribute("usuarioObj") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String idControlStr = request.getParameter("id_control_pedido");
    long idControlPedido = parseLongOrDefault(idControlStr, 0);

    if (idControlPedido <= 0) {
        setSwal(request, "error", "Validación", "ID de control de pedido inválido.");
        response.sendRedirect(request.getContextPath() + "/pedidos-agente");
        return;
    }

    // Capturar los filtros actuales
    String fechaFiltro = request.getParameter("fecha");
    String staffIDFiltro = request.getParameter("staffIDFiltro");

    PedidoAsignadoDAO dao = new PedidoAsignadoDAO();

    PedidoAsignadoDAO.ResultadoOperacion res = dao.cambiarEstadoPedido(
            idControlPedido,
            "CERRAR",
            "Pedido cerrado por agente."
    );

    manejarResultado(
            request,
            res,
            "Pedido cerrado correctamente.",
            "No se pudo cerrar el pedido."
    );

    // Redirigir manteniendo filtros
    String redirectURL = request.getContextPath() + "/pedidos-agente";
    boolean hayParams = false;

    if (fechaFiltro != null && !fechaFiltro.trim().isEmpty()) {
        redirectURL += "?fecha=" + fechaFiltro.trim();
        hayParams = true;
    }

    if (staffIDFiltro != null && !staffIDFiltro.trim().isEmpty()) {
        redirectURL += hayParams ? "&staffIDFiltro=" : "?staffIDFiltro=";
        redirectURL += staffIDFiltro.trim();
    }

    response.sendRedirect(redirectURL);
}

    // ============================================================
    // CANCELAR PEDIDO
    // ============================================================
private void cancelarPedido(HttpServletRequest request, HttpServletResponse response)
        throws IOException {

    HttpSession session = request.getSession(false);

    if (session == null || session.getAttribute("usuarioObj") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String idControlStr = request.getParameter("id_control_pedido");
    String observacion = request.getParameter("observacion");

    long idControlPedido = parseLongOrDefault(idControlStr, 0);

    if (idControlPedido <= 0) {
        setSwal(request, "error", "Validación", "ID de control de pedido inválido.");
        response.sendRedirect(request.getContextPath() + "/pedidos-agente");
        return;
    }

    if (isBlank(observacion)) {
        setSwal(request, "error", "Validación", "Debe ingresar una observación para cancelar el pedido.");
        response.sendRedirect(request.getContextPath() + "/pedidos-agente");
        return;
    }

    PedidoAsignadoDAO dao = new PedidoAsignadoDAO();

    PedidoAsignadoDAO.ResultadoOperacion res = dao.cambiarEstadoPedido(
            idControlPedido,
            "CANCELAR",
            observacion
    );

    manejarResultado(
            request,
            res,
            "Pedido cancelado correctamente.",
            "No se pudo cancelar el pedido."
    );

    // Capturar los filtros actuales
    String fechaFiltro = request.getParameter("fecha");
    String staffIDFiltro = request.getParameter("staffIDFiltro");

    // Construir URL de redirección manteniendo los filtros
    String redirectURL = request.getContextPath() + "/pedidos-agente";
    boolean hayParams = false;

    if (fechaFiltro != null && !fechaFiltro.trim().isEmpty()) {
        redirectURL += "?fecha=" + fechaFiltro.trim();
        hayParams = true;
    }

    if (staffIDFiltro != null && !staffIDFiltro.trim().isEmpty()) {
        redirectURL += hayParams ? "&staffIDFiltro=" : "?staffIDFiltro=";
        redirectURL += staffIDFiltro.trim();
    }

    response.sendRedirect(redirectURL);
}

    // ============================================================
    // UTILIDADES
    // ============================================================
    private void manejarResultado(
            HttpServletRequest request,
            PedidoAsignadoDAO.ResultadoOperacion res,
            String mensajeExito,
            String mensajeErrorDefault
    ) {

        String status = res.status == null ? "" : res.status.trim();

        if ("success".equalsIgnoreCase(status) || "ok".equalsIgnoreCase(status)) {
            setSwal(request, "success", "Éxito", mensajeExito);
            return;
        }

        String msg = !isBlank(res.message)
                ? res.message
                : mensajeErrorDefault;

        setSwal(request, "error", "Error", msg);
    }

    private void setSwal(HttpServletRequest request, String icon, String title, String text) {
        request.getSession().setAttribute("swal_icon", icon);
        request.getSession().setAttribute("swal_title", title);
        request.getSession().setAttribute("swal_text", text);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
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
    // ============================================================
// CAMBIAR ESTADO DEL AGENTE
// ============================================================
private void cambiarEstadoAgente(HttpServletRequest request, HttpServletResponse response)
        throws IOException {

    HttpSession session = request.getSession(false);

    if (session == null || session.getAttribute("usuarioObj") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    Agente agente = (Agente) session.getAttribute("usuarioObj");

    String estadoStr = request.getParameter("estado");
    String password = request.getParameter("password");

    int estado = parseIntOrDefault(estadoStr, -1);

    if (estado != 0 && estado != 1 && estado != 3) {
        setSwal(request, "error", "Validación", "Estado inválido.");
        response.sendRedirect(request.getContextPath() + "/pedidos-agente");
        return;
    }

    AgenteDAO dao = new AgenteDAO();

    if (estado == 0) {
        if (isBlank(password)) {
            setSwal(request, "error", "Validación", "Debe ingresar su contraseña para desconectarse.");
            response.sendRedirect(request.getContextPath() + "/pedidos-agente");
            return;
        }

        boolean passwordCorrecta = dao.validarPasswordAgente(
                agente.getIdUsuario(),
                password
        );

        if (!passwordCorrecta) {
            setSwal(request, "error", "Validación", "Contraseña incorrecta. No se pudo desconectar.");
            response.sendRedirect(request.getContextPath() + "/pedidos-agente");
            return;
        }
    }

    AgenteDAO.ResultadoOperacion res = dao.cambiarEstadoAgente(
            agente.getIdUsuario(),
            estado
    );

    if ("success".equalsIgnoreCase(res.status)) {
        agente.setEstado(estado);
        session.setAttribute("usuarioObj", agente);

        if (estado == 1) {
            setSwal(request, "success", "Estado actualizado", "Ahora estás disponible para recibir pedidos.");
        } else if (estado == 3) {
            setSwal(request, "success", "Estado actualizado", "Ahora estás pausado y no recibirás nuevos pedidos.");
        } else {
            setSwal(request, "success", "Estado actualizado", "Ahora estás desconectado.");
        }
    } else {
        String msg = !isBlank(res.message)
                ? res.message
                : "No se pudo cambiar el estado del agente.";

        setSwal(request, "error", "Error", msg);
    }

    response.sendRedirect(request.getContextPath() + "/pedidos-agente");
}
private int parseIntOrDefault(String value, int defaultValue) {
    if (value == null || value.trim().isEmpty()) {
        return defaultValue;
    }

    try {
        return Integer.parseInt(value.trim());
    } catch (NumberFormatException ex) {
        return defaultValue;
    }
}
// ============================================================
// ASIGNAR PEDIDOS PENDIENTES MANUALMENTE - SOLO ADMIN
// ============================================================
private void asignarPendientes(HttpServletRequest request, HttpServletResponse response)
        throws IOException {

    HttpSession session = request.getSession(false);

    if (session == null || session.getAttribute("usuarioObj") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    Agente agente = (Agente) session.getAttribute("usuarioObj");

    if (agente.getRol() != 1) {
        setSwal(request, "error", "Acceso denegado", "Solo un administrador puede asignar pedidos pendientes.");
        response.sendRedirect(request.getContextPath() + "/pedidos-agente");
        return;
    }

    String cantidadStr = request.getParameter("cantidad");
    String staffIDDestino = request.getParameter("staffIDDestino");

    Integer cantidad = null;

    if (!isBlank(cantidadStr)) {
        int cantidadTmp = parseIntOrDefault(cantidadStr, 0);

        if (cantidadTmp > 0) {
            cantidad = cantidadTmp;
        }
    }

    Integer idUsuarioAdmin = agente.getIdUsuario();

    PedidoAsignadoDAO dao = new PedidoAsignadoDAO();

    AsignacionPendienteResultado res = dao.asignarPedidosPendientes(
            cantidad,
            staffIDDestino,
            idUsuarioAdmin
    );

    if (res != null && res.isSuccess()) {
        setSwal(
                request,
                "success",
                "Asignación completada",
                res.getMensaje() != null ? res.getMensaje() : "Pedidos pendientes asignados correctamente."
        );
    } else {
        String msg = res != null && !isBlank(res.getMensaje())
                ? res.getMensaje()
                : "No se pudieron asignar los pedidos pendientes.";

        setSwal(request, "error", "Error", msg);
    }

    response.sendRedirect(request.getContextPath() + "/pedidos-agente");
}
}