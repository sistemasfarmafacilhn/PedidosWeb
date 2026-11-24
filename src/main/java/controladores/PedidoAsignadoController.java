package controladores;

import dao.AgenteDAO;
import dao.MotivoCancelacionDAO;
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
import modelos.FarmaciaSupervisor;
import modelos.MotivoCancelacion;
import modelos.PedidoAsignado;

@WebServlet("/pedidos-agente")
public class PedidoAsignadoController extends HttpServlet {

    // ============================================================
    // GET -> Mostrar pedidos abiertos del usuario logueado
    // ============================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        cargarPedidos(request, response);
    }

    // ============================================================
    // POST -> Filtrar / cerrar / cancelar / estado / asignar pendientes
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

        Integer rolSesion = obtenerRolSesion(session, agente);

        boolean esAdmin = rolSesion != null && rolSesion == 1;
        boolean esVistaTotal = rolSesion != null && rolSesion == 4;
        boolean esSupervisor = rolSesion != null && rolSesion == 5;

        String staffID = agente.getStaffID();
        String staffIDFiltro = request.getParameter("staffIDFiltro");

        if (staffIDFiltro != null && !staffIDFiltro.trim().isEmpty()) {
            staffIDFiltro = staffIDFiltro.trim();
        } else {
            staffIDFiltro = "";
        }

        /*
         * Reglas:
         *
         * rol = 1 Administrador:
         *      Puede ver todos los pedidos que NO sean farmacia.
         *      Puede filtrar por StaffID desde combo.
         *
         * rol = 4 Vista total:
         *      Puede ver todos los pedidos, incluyendo farmacias.
         *      Puede filtrar por StaffID desde combo.
         *
         * rol = 5 Supervisor:
         *      Puede ver pedidos de farmacias asignadas a su supervisión.
         *      Puede filtrar por StaffID/farmacia desde combo.
         *      Se manda supervisorNombre al SP para validar contra VW_FARMACIAS_SUPERVISOR.Supervisor.
         *
         * rol = 2 Agente:
         *      Solo ve su propio StaffID.
         *
         * rol = 3 Agente de farmacia:
         *      Solo ve su propio StaffID, que corresponde al BranchId/StoreID.
         */
        if (esAdmin || esVistaTotal) {

            if (!staffIDFiltro.trim().isEmpty()) {
                staffID = staffIDFiltro.trim();
            } else {
                staffID = null;
            }

        } else if (esSupervisor) {

            /*
             * Para supervisor:
             * staffID se usa como filtro de farmacia.
             * NULL = todas sus farmacias.
             * S0002 = solo esa farmacia, siempre que le pertenezca.
             */
            if (!staffIDFiltro.trim().isEmpty()) {
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

            staffID = staffID.trim();
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
                request.setAttribute("staffIDFiltro", staffIDFiltro);
                request.getRequestDispatcher("/vistas/pedidos_agente.jsp").forward(request, response);
                return;
            }
        }

        PedidoAsignadoDAO pedidoDAO = new PedidoAsignadoDAO();

        String supervisorNombre = null;

        if (esSupervisor) {
            supervisorNombre = agente.getNombre();
        }

        List<PedidoAsignado> pedidos = pedidoDAO.listarPedidosAbiertosPorAgente(
                staffID,
                fechaFiltro,
                rolSesion,
                supervisorNombre
        );

        /*
         * Lista para combo del admin o vista total.
         */
        List<Agente> agentes = null;

        if (esAdmin || esVistaTotal) {
            AgenteDAO agenteDAO = new AgenteDAO();
            agentes = agenteDAO.listarAgentes(rolSesion);
        }

        /*
         * Lista de farmacias asignadas al supervisor.
         */
        List<FarmaciaSupervisor> farmaciasSupervisor = null;

        if (esSupervisor) {
            AgenteDAO agenteDAO = new AgenteDAO();
            farmaciasSupervisor = agenteDAO.listarFarmaciasPorSupervisor(agente.getNombre());
        }

        MotivoCancelacionDAO motivoDAO = new MotivoCancelacionDAO();
        List<MotivoCancelacion> motivosCancelacion = motivoDAO.listarActivos();

        request.setAttribute("pedidos", pedidos);
        request.setAttribute("agentes", agentes);
        request.setAttribute("farmaciasSupervisor", farmaciasSupervisor);
        request.setAttribute("motivosCancelacion", motivosCancelacion);

        request.setAttribute("staffID", staffID == null ? "" : staffID);
        request.setAttribute("staffIDFiltro", staffIDFiltro == null ? "" : staffIDFiltro);
        request.setAttribute("agenteNombre", agente.getNombre());
        request.setAttribute("fechaSeleccionada", fechaStr == null ? "" : fechaStr);
        request.setAttribute("rolSesion", rolSesion == null ? 0 : rolSesion);
        request.setAttribute("esSupervisor", esSupervisor);

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

        String fechaFiltro = request.getParameter("fecha");
        String staffIDFiltro = request.getParameter("staffIDFiltro");

        PedidoAsignadoDAO dao = new PedidoAsignadoDAO();

        PedidoAsignadoDAO.ResultadoOperacion res = dao.cambiarEstadoPedido(
                idControlPedido,
                "CERRAR",
                "Pedido Facturado"
        );

        manejarResultado(
                request,
                res,
                "Pedido cerrado correctamente.",
                "No se pudo cerrar el pedido."
        );

        response.sendRedirect(construirRedirectPedidos(request, fechaFiltro, staffIDFiltro));
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

        String fechaFiltro = request.getParameter("fecha");
        String staffIDFiltro = request.getParameter("staffIDFiltro");

        PedidoAsignadoDAO dao = new PedidoAsignadoDAO();

        PedidoAsignadoDAO.ResultadoOperacion res = dao.cambiarEstadoPedido(
                idControlPedido,
                "CANCELAR",
                observacion.trim()
        );

        manejarResultado(
                request,
                res,
                "Pedido cancelado correctamente.",
                "No se pudo cancelar el pedido."
        );

        response.sendRedirect(construirRedirectPedidos(request, fechaFiltro, staffIDFiltro));
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

        if (res != null && "success".equalsIgnoreCase(res.status)) {
            agente.setEstado(estado);
            session.setAttribute("usuarioObj", agente);
            session.setAttribute("rol", agente.getRol());

            if (estado == 1) {
                setSwal(request, "success", "Estado actualizado", "Ahora estás disponible para recibir pedidos.");
            } else if (estado == 3) {
                setSwal(request, "success", "Estado actualizado", "Ahora estás pausado y no recibirás nuevos pedidos.");
            } else {
                setSwal(request, "success", "Estado actualizado", "Ahora estás desconectado.");
            }
        } else {
            String msg = res != null && !isBlank(res.message)
                    ? res.message
                    : "No se pudo cambiar el estado del agente.";

            setSwal(request, "error", "Error", msg);
        }

        response.sendRedirect(request.getContextPath() + "/pedidos-agente");
    }

    // ============================================================
    // ASIGNAR PEDIDOS PENDIENTES MANUALMENTE - ADMIN / ROL 4
    // ============================================================
    private void asignarPendientes(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("usuarioObj") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Agente agente = (Agente) session.getAttribute("usuarioObj");
        Integer rolSesion = obtenerRolSesion(session, agente);

        if (rolSesion == null || (rolSesion != 1 && rolSesion != 4)) {
            setSwal(request, "error", "Acceso denegado", "Solo un administrador o usuario con vista total puede asignar pedidos pendientes.");
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

    // ============================================================
    // UTILIDADES
    // ============================================================
    private void manejarResultado(
            HttpServletRequest request,
            PedidoAsignadoDAO.ResultadoOperacion res,
            String mensajeExito,
            String mensajeErrorDefault
    ) {

        if (res == null) {
            setSwal(request, "error", "Error", mensajeErrorDefault);
            return;
        }

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

    private Integer obtenerRolSesion(HttpSession session, Agente agente) {
        Integer rolSesion = null;

        Object rolObj = session.getAttribute("rol");

        if (rolObj instanceof Integer) {
            rolSesion = (Integer) rolObj;
        } else if (rolObj != null) {
            try {
                rolSesion = Integer.parseInt(rolObj.toString());
            } catch (NumberFormatException ex) {
                rolSesion = null;
            }
        }

        if (rolSesion == null && agente != null) {
            rolSesion = agente.getRol();
        }

        return rolSesion;
    }

    private String construirRedirectPedidos(
            HttpServletRequest request,
            String fechaFiltro,
            String staffIDFiltro
    ) {

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

        return redirectURL;
    }
}