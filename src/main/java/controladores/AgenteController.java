package controladores;

import dao.AgenteDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;
import modelos.Agente;
import utilidades.PasswordUtil;

@WebServlet("/agente")
public class AgenteController extends HttpServlet {

    // ============================================================
    // GET -> Mostrar listado / formulario de agentes
    // ============================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        AgenteDAO dao = new AgenteDAO();

        // Por defecto lista agentes activos
        List<Agente> agentes = dao.listarAgentes();

        request.setAttribute("agentes", agentes);

        // Cambia esta ruta según tu JSP real
        request.getRequestDispatcher("/vistas/agente.jsp").forward(request, response);
    }

    // ============================================================
    // POST -> insertar / editar / eliminar / cambiar password / cambiar estado
    // ============================================================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");

        String accion = request.getParameter("accion");

        if (accion == null || accion.trim().isEmpty()) {
            accion = "insertar";
        }

        switch (accion) {
            case "insertar":
                insertarAgente(request, response);
                break;

            case "editar":
                editarAgente(request, response);
                break;

            case "eliminar":
                eliminarAgente(request, response);
                break;

            case "cambiarPassword":
                cambiarPassword(request, response);
                break;

            case "cambiarEstado":
                cambiarEstado(request, response);
                break;

            default:
                setSwal(request, "error", "Error", "Acción no válida.");
                response.sendRedirect(request.getContextPath() + "/agente");
                break;
        }
    }

    // ============================================================
    // INSERTAR AGENTE
    // ============================================================
    private void insertarAgente(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String nombre = request.getParameter("nombre");
        String codigo = request.getParameter("codigo");
        String password = request.getParameter("password");
        String estadoStr = request.getParameter("estado");
        String rolStr = request.getParameter("rol");
        String staffID = request.getParameter("StaffID");

        if (isBlank(nombre)) {
            setSwal(request, "error", "Validación", "El nombre es obligatorio.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        if (isBlank(codigo)) {
            setSwal(request, "error", "Validación", "El código es obligatorio.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        if (isBlank(password)) {
            setSwal(request, "error", "Validación", "La contraseña es obligatoria.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        int estado = parseIntOrDefault(estadoStr, 0); // 0 = Desconectado
        int rol = parseIntOrDefault(rolStr, 2);       // 2 = Agente

        if (estado != 0 && estado != 1) {
            setSwal(request, "error", "Validación", "Estado inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        PasswordUtil.Result h = PasswordUtil.hashForStorage(password);

        Agente agente = new Agente();
        agente.setNombre(nombre.trim());
        agente.setCodigo(codigo.trim());
        agente.setSalt(h.saltB64);
        agente.setHashPassword(h.hashB64);
        agente.setEstado(estado);
        agente.setRol(rol);
        agente.setStaffID(isBlank(staffID) ? null : staffID.trim());
        agente.setDeleted(0);

        AgenteDAO dao = new AgenteDAO();
        AgenteDAO.ResultadoOperacion res = dao.insertarAgente(agente);

        manejarResultado(
                request,
                res,
                "Agente insertado correctamente.",
                "No se pudo insertar el agente."
        );

        response.sendRedirect(request.getContextPath() + "/agente");
    }

    // ============================================================
    // EDITAR AGENTE
    // ============================================================
    private void editarAgente(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String idUsuarioStr = request.getParameter("id_usuario");
        String nombre = request.getParameter("nombre");
        String codigo = request.getParameter("codigo");
        String estadoStr = request.getParameter("estado");
        String rolStr = request.getParameter("rol");
        String staffID = request.getParameter("StaffID");

        int idUsuario = parseIntOrDefault(idUsuarioStr, 0);

        if (idUsuario <= 0) {
            setSwal(request, "error", "Validación", "ID de agente inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        if (isBlank(nombre)) {
            setSwal(request, "error", "Validación", "El nombre es obligatorio.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        if (isBlank(codigo)) {
            setSwal(request, "error", "Validación", "El código es obligatorio.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        int estado = parseIntOrDefault(estadoStr, 0);
        int rol = parseIntOrDefault(rolStr, 2);

        if (estado != 0 && estado != 1) {
            setSwal(request, "error", "Validación", "Estado inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        Agente agente = new Agente();
        agente.setIdUsuario(idUsuario);
        agente.setNombre(nombre.trim());
        agente.setCodigo(codigo.trim());
        agente.setEstado(estado);
        agente.setRol(rol);
        agente.setStaffID(isBlank(staffID) ? null : staffID.trim());

        AgenteDAO dao = new AgenteDAO();
        AgenteDAO.ResultadoOperacion res = dao.editarAgente(agente);

        manejarResultado(
                request,
                res,
                "Agente actualizado correctamente.",
                "No se pudo actualizar el agente."
        );

        response.sendRedirect(request.getContextPath() + "/agente");
    }

    // ============================================================
    // ELIMINAR LÓGICO
    // ============================================================
    private void eliminarAgente(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String idUsuarioStr = request.getParameter("id_usuario");
        int idUsuario = parseIntOrDefault(idUsuarioStr, 0);

        if (idUsuario <= 0) {
            setSwal(request, "error", "Validación", "ID de agente inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        AgenteDAO dao = new AgenteDAO();
        AgenteDAO.ResultadoOperacion res = dao.eliminarAgente(idUsuario);

        manejarResultado(
                request,
                res,
                "Agente eliminado correctamente.",
                "No se pudo eliminar el agente."
        );

        response.sendRedirect(request.getContextPath() + "/agente");
    }

    // ============================================================
    // CAMBIAR CONTRASEÑA
    // ============================================================
private void cambiarPassword(HttpServletRequest request, HttpServletResponse response)
        throws IOException {

    HttpSession session = request.getSession(false);

    if (session == null || session.getAttribute("usuarioObj") == null) {
        setSwal(request, "error", "Sesión expirada", "Debes iniciar sesión nuevamente.");
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    Agente agenteSesion = (Agente) session.getAttribute("usuarioObj");

    int idUsuario = agenteSesion.getIdUsuario();

    String passwordActual = request.getParameter("password_actual");
    String nuevaPassword = request.getParameter("password");
    String confirmarPassword = request.getParameter("confirm_password");

    if (idUsuario <= 0) {
        setSwal(request, "error", "Validación", "No se pudo identificar el usuario de la sesión.");
        response.sendRedirect(request.getContextPath() + "/vistas/agente_password.jsp");
        return;
    }

    if (isBlank(passwordActual)) {
        setSwal(request, "error", "Validación", "Debe ingresar la contraseña actual.");
        response.sendRedirect(request.getContextPath() + "/vistas/agente_password.jsp");
        return;
    }

    if (isBlank(nuevaPassword)) {
        setSwal(request, "error", "Validación", "Debe ingresar la nueva contraseña.");
        response.sendRedirect(request.getContextPath() + "/vistas/agente_password.jsp");
        return;
    }

    if (isBlank(confirmarPassword)) {
        setSwal(request, "error", "Validación", "Debe confirmar la nueva contraseña.");
        response.sendRedirect(request.getContextPath() + "/vistas/agente_password.jsp");
        return;
    }

    if (!nuevaPassword.equals(confirmarPassword)) {
        setSwal(request, "error", "Validación", "La nueva contraseña y la confirmación no coinciden.");
        response.sendRedirect(request.getContextPath() + "/vistas/agente_password.jsp");
        return;
    }

    if (passwordActual.equals(nuevaPassword)) {
        setSwal(request, "warning", "Validación", "La nueva contraseña no debería ser igual a la actual.");
        response.sendRedirect(request.getContextPath() + "/vistas/agente_password.jsp");
        return;
    }

    AgenteDAO dao = new AgenteDAO();
    AgenteDAO.ResultadoOperacion res = dao.cambiarPassword(idUsuario, passwordActual, nuevaPassword);

    manejarResultado(
            request,
            res,
            "Contraseña actualizada correctamente.",
            "No se pudo cambiar la contraseña."
    );

    response.sendRedirect(request.getContextPath() + "/vistas/agente_password.jsp");
}

    // ============================================================
    // CAMBIAR ESTADO DISPONIBLE / DESCONECTADO
    // ============================================================
private void cambiarEstado(HttpServletRequest request, HttpServletResponse response)
        throws IOException {

    String idUsuarioStr = request.getParameter("id_usuario");
    String estadoStr = request.getParameter("estado");

    int idUsuario = parseIntOrDefault(idUsuarioStr, 0);
    int estado = parseIntOrDefault(estadoStr, -1);

    if (idUsuario <= 0) {
        setSwal(request, "error", "Validación", "ID de agente inválido.");
        response.sendRedirect(request.getContextPath() + "/agente");
        return;
    }

    if (estado != 0 && estado != 1 && estado != 3) {
        setSwal(request, "error", "Validación", "Estado inválido.");
        response.sendRedirect(request.getContextPath() + "/agente");
        return;
    }

    AgenteDAO dao = new AgenteDAO();
    AgenteDAO.ResultadoOperacion res = dao.cambiarEstadoAgente(idUsuario, estado);

    String mensajeExito;

    if (estado == 1) {
        mensajeExito = "Agente marcado como disponible.";
    } else if (estado == 3) {
        mensajeExito = "Agente marcado como pausado.";
    } else {
        mensajeExito = "Agente marcado como desconectado.";
    }

    manejarResultado(
            request,
            res,
            mensajeExito,
            "No se pudo cambiar el estado del agente."
    );

    response.sendRedirect(request.getContextPath() + "/agente");
}

    // ============================================================
    // UTILIDADES
    // ============================================================
    private void manejarResultado(
            HttpServletRequest request,
            AgenteDAO.ResultadoOperacion res,
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

        if (msg.toLowerCase().contains("existe")
                || msg.toLowerCase().contains("duplicado")
                || msg.toLowerCase().contains("duplicate")) {

            setSwal(request, "warning", "Duplicado", msg);
        } else {
            setSwal(request, "error", "Error", msg);
        }
    }

    private void setSwal(HttpServletRequest request, String icon, String title, String text) {
        request.getSession().setAttribute("swal_icon", icon);
        request.getSession().setAttribute("swal_title", title);
        request.getSession().setAttribute("swal_text", text);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
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
}