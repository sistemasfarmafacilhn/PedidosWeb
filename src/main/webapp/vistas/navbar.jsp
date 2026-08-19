<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="modelos.Agente" %>

<%
    String nombre = "Invitado";
    String ctx = request.getContextPath();
    String uri = request.getRequestURI();

    int rol = 2;

    boolean esAdmin = false;
    boolean esAgenteFarmacia = false;
    boolean esVistaTotal = false;
    boolean esSupervisor = false;

    boolean puedeVerPedidosAdmin = false;
    boolean puedeVerGestionAgentes = false;

    if (session != null) {
        Object nombreSesion = session.getAttribute("nombre");
        if (nombreSesion != null) {
            nombre = nombreSesion.toString();
        }

        Object usuarioObj = session.getAttribute("usuarioObj");
        if (usuarioObj != null && usuarioObj instanceof Agente) {
            Agente agenteSesion = (Agente) usuarioObj;
            rol = agenteSesion.getRol();

            if (agenteSesion.getNombre() != null && !agenteSesion.getNombre().trim().isEmpty()) {
                nombre = agenteSesion.getNombre();
            }
        } else {
            Object rolSesion = session.getAttribute("rol");
            if (rolSesion != null) {
                try {
                    rol = Integer.parseInt(rolSesion.toString());
                } catch (NumberFormatException ex) {
                    rol = 2;
                }
            }
        }

        esAdmin = rol == 1;
        esAgenteFarmacia = rol == 3;
        esVistaTotal = rol == 4;
        esSupervisor = rol == 5;

        /*
            Admin y Vista Total ven la vista administrativa de pedidos.
            Supervisor no entra aquí porque no debe verse como admin general.
        */
        puedeVerPedidosAdmin = esAdmin || esVistaTotal;

        /*
            Supervisor sí debe poder entrar a Gestión de Agentes.
            Ahí el controller ya debe filtrar/limitar lo que puede ver o crear.
        */
        puedeVerGestionAgentes = esAdmin || esVistaTotal || esSupervisor;
    }

    boolean usarTemaVerde = esAgenteFarmacia || esSupervisor;

    String colorNavbar = usarTemaVerde ? "#00CF78" : "#00B4E7";
%>

<nav class="navbar navbar-expand-lg navbar-dark shadow-sm <%= usarTemaVerde ? "navbar-tema-verde" : "" %>"
     style="background-color:<%= colorNavbar %>;">
    <div class="container-fluid">

        <a class="navbar-brand fw-bold" href="<%= ctx %>/vistas/menu.jsp">
            Pedidos Web
        </a>

        <button class="navbar-toggler" type="button" data-bs-toggle="collapse"
                data-bs-target="#navbarMenu" aria-controls="navbarMenu"
                aria-expanded="false" aria-label="Menú">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navbarMenu">

            <ul class="navbar-nav me-auto mb-2 mb-lg-0">

                <% if (puedeVerPedidosAdmin) { %>

                    <li class="nav-item">
                        <a class="nav-link <%= uri.contains("/pedidos-agente") ? "active fw-semibold" : "" %>"
                           href="<%= ctx %>/pedidos-agente">
                            <i class="bi bi-list-check"></i>
                            <% if (esVistaTotal) { %>
                                Vista Total de Pedidos
                            <% } else { %>
                                Todos los Pedidos
                            <% } %>
                        </a>
                    </li>

                <% } else { %>

                    <li class="nav-item">
                        <a class="nav-link <%= uri.contains("/pedidos-agente") ? "active fw-semibold" : "" %>"
                           href="<%= ctx %>/pedidos-agente">
                            <i class="bi bi-bag-check"></i>
                            <% if (esAgenteFarmacia) { %>
                                Pedidos de agente de farmacia
                            <% } else if (esSupervisor) { %>
                                Pedidos supervisados
                            <% } else { %>
                                Mis Pedidos
                            <% } %>
                        </a>
                    </li>

                <% } %>

                <% if (puedeVerGestionAgentes) { %>

                    <li class="nav-item">
                        <a class="nav-link <%= uri.contains("/agente") && !uri.contains("/agente_password.jsp") ? "active fw-semibold" : "" %>"
                           href="<%= ctx %>/agente">
                            <i class="bi bi-people"></i>
                            <% if (esSupervisor) { %>
                                Agentes de farmacia
                            <% } else { %>
                                Gestión de Agentes
                            <% } %>
                        </a>
                    </li>

                <% } %>

                <li class="nav-item">
                    <a class="nav-link <%= uri.contains("/agente_password.jsp") ? "active fw-semibold" : "" %>"
                       href="<%= ctx %>/vistas/agente_password.jsp">
                        <i class="bi bi-key"></i> Cambiar Contraseña
                    </a>
                </li>

            </ul>

            <div class="d-flex align-items-center gap-3 text-white navbar-user-info">
                <span class="small fw-semibold">
                    <i class="bi bi-person-circle"></i> <%= nombre %>

                    <% if (esVistaTotal) { %>
                        <span class="badge bg-dark ms-1">Vista total</span>
                    <% } else if (esAdmin) { %>
                        <span class="badge bg-primary ms-1">Admin</span>
                    <% } else if (esSupervisor) { %>
                        <span class="badge badge-tema-verde-navbar ms-1">Supervisor</span>
                    <% } else if (esAgenteFarmacia) { %>
                        <span class="badge badge-tema-verde-navbar ms-1">Agente de farmacia</span>
                    <% } else { %>
                        <span class="badge bg-light text-dark ms-1">Agente</span>
                    <% } %>
                </span>

                <a href="<%= ctx %>/logout" class="btn btn-outline-light btn-sm btn-salir-navbar">
                    <i class="bi bi-box-arrow-right"></i> Salir
                </a>
            </div>

        </div>
    </div>
</nav>

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">

<style>
    .navbar-tema-verde {
        background-color: #00CF78 !important;
    }

    .navbar-tema-verde .navbar-brand,
    .navbar-tema-verde .nav-link,
    .navbar-tema-verde .navbar-user-info {
        color: #FFFFFF !important;
    }

    .navbar-tema-verde .nav-link.active,
    .navbar-tema-verde .nav-link:hover,
    .navbar-tema-verde .navbar-brand:hover {
        color: #FFFFFF !important;
        opacity: .85;
    }

    .navbar-tema-verde .badge-tema-verde-navbar {
        background-color: #00B4E7 !important;
        color: #ffffff !important;
    }

    .navbar-tema-verde .btn-salir-navbar {
        color: #FFFFFF !important;
        border-color: #FFFFFF !important;
    }

    .navbar-tema-verde .btn-salir-navbar:hover {
        background-color: #FFFFFF !important;
        color: #00CF78 !important;
    }

    .navbar-tema-verde .navbar-toggler {
        border-color: rgba(255, 255, 255, .45) !important;
    }
</style>