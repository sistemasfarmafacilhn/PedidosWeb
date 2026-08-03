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
import modelos.FarmaciaSupervisor;
import utilidades.PasswordUtil;

@WebServlet("/agente")
public class AgenteController extends HttpServlet {

// ============================================================
// GET -> Mostrar listado / formulario de agentes
// ============================================================
@Override
protected void doGet(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {

    HttpSession session = request.getSession(false);

    if (session == null || session.getAttribute("usuarioObj") == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    Agente agenteSesion = (Agente) session.getAttribute("usuarioObj");
    Integer rolSesion = obtenerRolSesion(session, agenteSesion);

    AgenteDAO dao = new AgenteDAO();

    String staffIDFiltro = request.getParameter("staffIDFiltro");

    if (isBlank(staffIDFiltro)) {
        staffIDFiltro = request.getParameter("StaffID");
    }

    if (isBlank(staffIDFiltro)) {
        staffIDFiltro = request.getParameter("staffID");
    }

    if (!isBlank(staffIDFiltro)) {
        staffIDFiltro = staffIDFiltro.trim();
    } else {
        staffIDFiltro = null;
    }

    List<Agente> agentes;

    /*
     * Regla aplicada en SP_AGENTE_LISTAR:
     * rol 4 = ve todos los agentes.
     * rol 5 = supervisor, solo ve agentes de farmacia de sus centros asignados.
     * otros roles = comportamiento normal.
     *
     * Para supervisor:
     * - Se manda agenteSesion.getNombre() para comparar con VW_FARMACIAS_SUPERVISOR.Supervisor.
     * - Si staffIDFiltro viene lleno, solo lista agentes de esa farmacia.
     */
    if (rolSesion != null && rolSesion == 5) {

        String supervisor = agenteSesion.getNombre();

        agentes = dao.listarAgentes(
                null,
                null,
                staffIDFiltro,
                null,
                null,
                0,
                null,
                rolSesion,
                supervisor
        );

        List<FarmaciaSupervisor> farmaciasSupervisor =
                dao.listarFarmaciasPorSupervisor(supervisor);

        request.setAttribute("farmaciasSupervisor", farmaciasSupervisor);
        request.setAttribute("esSupervisor", true);

    } else {

        agentes = dao.listarAgentes(
                null,
                null,
                staffIDFiltro,
                null,
                null,
                0,
                null,
                rolSesion,
                null
        );

        request.setAttribute("farmaciasSupervisor", null);
        request.setAttribute("esSupervisor", false);
    }

    request.setAttribute("agentes", agentes);
    request.setAttribute("rolSesion", rolSesion);
    request.setAttribute("staffIDFiltro", staffIDFiltro);

    request.getRequestDispatcher("/vistas/agente.jsp").forward(request, response);
}

    // ============================================================
    // POST -> insertar / editar / eliminar / cambiar password / cambiar estado
    // ============================================================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("usuarioObj") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

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

        HttpSession session = request.getSession(false);
        Agente agenteSesion = session != null ? (Agente) session.getAttribute("usuarioObj") : null;
        Integer rolSesion = obtenerRolSesion(session, agenteSesion);

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

        int estado = parseIntOrDefault(estadoStr, 0);
        int rol = parseIntOrDefault(rolStr, 2);

        /*
         * Regla para Supervisor:
         * Si el usuario logueado es rol 5 = Supervisor:
         * - Solo puede crear usuarios rol 3 = Farmacia.
         * - El estado se fuerza a 0 = Desconectado.
         * - StaffID debe ser el STOREID de una farmacia asignada al supervisor.
         */
        if (rolSesion != null && rolSesion == 5) {

            rol = 3;
            estado = 0;

            if (isBlank(staffID)) {
                setSwal(request, "error", "Validación", "Debe seleccionar una farmacia asignada.");
                response.sendRedirect(request.getContextPath() + "/agente");
                return;
            }

            AgenteDAO daoValidacion = new AgenteDAO();

            List<FarmaciaSupervisor> farmaciasAsignadas =
                    daoValidacion.listarFarmaciasPorSupervisor(agenteSesion.getNombre());

            boolean farmaciaPermitida = false;

            for (FarmaciaSupervisor f : farmaciasAsignadas) {
                if (f.getStoreID() != null
                        && f.getStoreID().trim().equalsIgnoreCase(staffID.trim())) {
                    farmaciaPermitida = true;
                    break;
                }
            }

            if (!farmaciaPermitida) {
                setSwal(
                        request,
                        "error",
                        "No autorizado",
                        "La farmacia seleccionada no está asignada a su supervisión."
                );
                response.sendRedirect(request.getContextPath() + "/agente");
                return;
            }
        }

        if (!estadoValido(estado)) {
            setSwal(request, "error", "Validación", "Estado inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        /*
         * Roles:
         * 1 = Administrador
         * 2 = Agente
         * 3 = Farmacia
         * 4 = Vista total
         * 5 = Supervisor
         */
        if (!rolValido(rol)) {
            setSwal(request, "error", "Validación", "Rol inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        /*
         * Seguridad backend:
         * Solo rol 4 = Vista total puede crear usuarios con rol 5 = Supervisor.
         */
        if (rol == 5 && !esVistaTotal(rolSesion)) {
            setSwal(
                    request,
                    "error",
                    "No autorizado",
                    "Solo usuarios Vista total pueden crear supervisores."
            );
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

        HttpSession session = request.getSession(false);
        Agente agenteSesion = session != null ? (Agente) session.getAttribute("usuarioObj") : null;
        Integer rolSesion = obtenerRolSesion(session, agenteSesion);

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

        if (!estadoValido(estado)) {
            setSwal(request, "error", "Validación", "Estado inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        /*
         * Roles:
         * 1 = Administrador
         * 2 = Agente
         * 3 = Farmacia
         * 4 = Vista total
         * 5 = Supervisor
         */
        if (!rolValido(rol)) {
            setSwal(request, "error", "Validación", "Rol inválido.");
            response.sendRedirect(request.getContextPath() + "/agente");
            return;
        }

        /*
         * Seguridad backend:
         * Solo rol 4 = Vista total puede asignar rol 5 = Supervisor.
         */
        if (rol == 5 && !esVistaTotal(rolSesion)) {
            setSwal(
                    request,
                    "error",
                    "No autorizado",
                    "Solo usuarios Vista total pueden asignar el rol Supervisor."
            );
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
    // CAMBIAR ESTADO DISPONIBLE / DESCONECTADO / PAUSADO
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

        if (!estadoValido(estado)) {
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

    private boolean estadoValido(int estado) {
        return estado == 0 || estado == 1 || estado == 3;
    }

    private boolean rolValido(int rol) {
        return rol == 1 || rol == 2 || rol == 3 || rol == 4 || rol == 5;
    }

    private boolean esVistaTotal(Integer rolSesion) {
        return rolSesion != null && rolSesion == 4;
    }

    private Integer obtenerRolSesion(HttpSession session, Agente agenteSesion) {
        Integer rolSesion = null;

        if (session != null) {
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
        }

        if (rolSesion == null && agenteSesion != null) {
            rolSesion = agenteSesion.getRol();
        }

        return rolSesion;
    }
}