<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="modelos.Agente" %>

<%
    String nombre = "Invitado";
    String ctx = request.getContextPath();
    String uri = request.getRequestURI();

    int rol = 2;

    boolean esAdmin = false;
    boolean esFarmacia = false;
    boolean esVistaTotal = false;
    boolean puedeVerMenuAdmin = false;

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
        esFarmacia = rol == 3;
        esVistaTotal = rol == 4;
        puedeVerMenuAdmin = esAdmin || esVistaTotal;
    }

    String colorNavbar = esFarmacia ? "#a7c957" : "#0dcaf0";
    String colorTextoFarmacia = esFarmacia ? "#1f2d0b" : "#ffffff";
%>

<nav class="navbar navbar-expand-lg navbar-dark shadow-sm <%= esFarmacia ? "navbar-farmacia" : "" %>"
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

                <% if (puedeVerMenuAdmin) { %>

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

                    <li class="nav-item">
                        <a class="nav-link <%= uri.contains("/agente") && !uri.contains("/agente_password.jsp") ? "active fw-semibold" : "" %>"
                           href="<%= ctx %>/agente">
                            <i class="bi bi-people"></i> Gestión de Agentes
                        </a>
                    </li>

                    <li class="nav-item">
                        <a class="nav-link <%= uri.contains("/agente_password.jsp") ? "active fw-semibold" : "" %>"
                           href="<%= ctx %>/vistas/agente_password.jsp">
                            <i class="bi bi-key"></i> Cambiar Contraseña
                        </a>
                    </li>

                <% } else { %>

                    <li class="nav-item">
                        <a class="nav-link <%= uri.contains("/pedidos-agente") ? "active fw-semibold" : "" %>"
                           href="<%= ctx %>/pedidos-agente">
                            <i class="bi bi-bag-check"></i>
                            <% if (esFarmacia) { %>
                                Pedidos de Farmacia
                            <% } else { %>
                                Mis Pedidos
                            <% } %>
                        </a>
                    </li>

                    <li class="nav-item">
                        <a class="nav-link <%= uri.contains("/agente_password.jsp") ? "active fw-semibold" : "" %>"
                           href="<%= ctx %>/vistas/agente_password.jsp">
                            <i class="bi bi-key"></i> Cambiar Contraseña
                        </a>
                    </li>

                <% } %>

            </ul>

            <div class="d-flex align-items-center gap-3 text-white navbar-user-info">
                <span class="small fw-semibold">
                    <i class="bi bi-person-circle"></i> <%= nombre %>

                    <% if (esVistaTotal) { %>
                        <span class="badge bg-dark ms-1">Vista total</span>
                    <% } else if (esAdmin) { %>
                        <span class="badge bg-primary ms-1">Admin</span>
                    <% } else if (esFarmacia) { %>
                        <span class="badge badge-farmacia-navbar ms-1">Farmacia</span>
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
    .navbar-farmacia {
        background-color: #a7c957 !important;
    }

    .navbar-farmacia .navbar-brand,
    .navbar-farmacia .nav-link,
    .navbar-farmacia .navbar-user-info {
        color: #1f2d0b !important;
    }

    .navbar-farmacia .nav-link.active,
    .navbar-farmacia .nav-link:hover,
    .navbar-farmacia .navbar-brand:hover {
        color: #1f2d0b !important;
        opacity: .85;
    }

    .navbar-farmacia .badge-farmacia-navbar {
        background-color: #6f8f24 !important;
        color: #ffffff !important;
    }

    .navbar-farmacia .btn-salir-navbar {
        color: #1f2d0b !important;
        border-color: #1f2d0b !important;
    }

    .navbar-farmacia .btn-salir-navbar:hover {
        background-color: #1f2d0b !important;
        color: #ffffff !important;
    }

    .navbar-farmacia .navbar-toggler {
        border-color: rgba(31, 45, 11, .45) !important;
    }
</style>