package controladores;

import dao.AgenteDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import modelos.Agente;

@WebServlet("/login")
public class LoginController extends HttpServlet {

    // ============================================================
    // GET -> Mostrar login
    // ============================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/vistas/login.jsp").forward(request, response);
    }

    // ============================================================
    // POST -> Validar login
    // ============================================================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String codigo = request.getParameter("codigo");
        String password = request.getParameter("password");

        if (codigo == null || codigo.trim().isEmpty()
                || password == null || password.trim().isEmpty()) {

            request.setAttribute("error", "Debes ingresar tu código de usuario y contraseña.");
            request.setAttribute("val_codigo", codigo);
            request.getRequestDispatcher("/vistas/login.jsp").forward(request, response);
            return;
        }

        AgenteDAO agenteDAO = new AgenteDAO();
        Agente agente = agenteDAO.validarLoginPorCodigo(codigo, password);

        if (agente == null) {
            request.setAttribute("error", "Código o contraseña incorrectos.");
            request.setAttribute("val_codigo", codigo);
            request.getRequestDispatcher("/vistas/login.jsp").forward(request, response);
            return;
        }

        if (agente.getDeleted() == 1) {
            request.setAttribute("error", "Tu usuario fue eliminado. Contacta al administrador.");
            request.setAttribute("val_codigo", codigo);
            request.getRequestDispatcher("/vistas/login.jsp").forward(request, response);
            return;
        }

        /*
         * estado:
         * 0 = Desconectado / No disponible
         * 1 = Disponible
         *
         * Para login, recomiendo permitir entrar aunque esté en 0,
         * y marcarlo disponible automáticamente.
         */


        HttpSession sesionVieja = request.getSession(false);
        if (sesionVieja != null) {
            sesionVieja.invalidate();
        }

        HttpSession sesion = request.getSession(true);

        sesion.setAttribute("usuario", agente.getCodigo());
        sesion.setAttribute("usuarioObj", agente);
        sesion.setAttribute("id_usuario", agente.getIdUsuario());
        sesion.setAttribute("nombre", agente.getNombre());
        sesion.setAttribute("codigo", agente.getCodigo());
        sesion.setAttribute("rol", agente.getRol());
        sesion.setAttribute("StaffID", agente.getStaffID());

        if (agente.getRol() == 1) {
            response.sendRedirect(request.getContextPath() + "/vistas/menu.jsp");
        } else if (agente.getRol() == 2) {
            response.sendRedirect(request.getContextPath() + "/vistas/menu.jsp");
        } else {
            response.sendRedirect(request.getContextPath() + "/vistas/menu.jsp");
        }
    }
}