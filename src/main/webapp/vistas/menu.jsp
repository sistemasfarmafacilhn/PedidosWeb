<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelos.Agente" %>

<%
    Agente agenteSesion = (Agente) session.getAttribute("usuarioObj");

    if (agenteSesion == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    int rol = agenteSesion.getRol();
    String nombre = agenteSesion.getNombre() != null ? agenteSesion.getNombre() : "";
    String codigo = agenteSesion.getCodigo() != null ? agenteSesion.getCodigo() : "";

    boolean esAdmin = rol == 1;
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Menú Principal</title>

    <!-- Bootstrap 5 remoto -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- SweetAlert2 remoto -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        body {
            background: #f5f5f5;
        }

        .card-hover {
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }

        .card-hover:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
        }

        .main-card {
            border: none;
            border-radius: 18px;
        }

        .menu-card {
            border: 2px solid transparent;
            border-radius: 16px;
            background: #f0f0f0;
            height: 100%;
        }

        .menu-card .card-title {
            color: #0dcaf0;
            font-weight: 700;
            text-align: center;
        }

        .menu-card .card-text {
            color: #6c757d;
            font-size: 0.95rem;
            text-align: center;
        }

        .menu-icon {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: #e8f9fd;
            color: #0dcaf0;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
            font-weight: 700;
            margin: 0 auto 15px auto;
        }

        .section-title {
            font-weight: 700;
            color: #0dcaf0;
        }

        .btn-info-soft {
            background-color: #0dcaf0;
            border-color: #0dcaf0;
            color: #ffffff;
        }

        .btn-info-soft:hover {
            background-color: #31d2f2;
            border-color: #25cff2;
            color: #ffffff;
        }

        .top-bar {
            background: #ffffff;
            border-radius: 14px;
            box-shadow: 0 0.125rem 0.45rem rgba(0,0,0,.06);
            padding: 1rem;
            margin-bottom: 1.5rem;
        }

        .role-badge {
            font-size: .85rem;
        }
    </style>
</head>

<body class="bg-light">
<jsp:include page="/vistas/navbar.jsp" />
<div class="container py-4 py-md-5">



    <div class="row justify-content-center">
        <div class="col-12 col-xl-11">

            <div class="card shadow-sm card-hover main-card">
                <div class="card-body p-4 p-md-5">

                    <div class="text-center mb-5">
                        <h2 class="section-title mb-2">Menú Principal</h2>
                        <p class="text-muted mb-0">
                            Selecciona el módulo que deseas utilizar.
                        </p>
                    </div>

                    <div class="row g-4 justify-content-center">

                        <% if (esAdmin) { %>

                            <!-- ADMIN: TODOS LOS PEDIDOS -->
                            <div class="col-12 col-md-6 col-xl-4">
                                <div class="card menu-card card-hover h-100">
                                    <div class="card-body d-flex flex-column">
                                        <div class="menu-icon">TP</div>
                                        <h5 class="card-title">Todos los Pedidos</h5>
                                        <p class="card-text flex-grow-1">
                                            Consulta todos los pedidos asignados a los agentes, filtrados por fecha y estado.
                                        </p>
                                        <a href="<%= request.getContextPath() %>/pedidos-agente"
                                           class="btn btn-info-soft w-100">
                                            Ingresar
                                        </a>
                                    </div>
                                </div>
                            </div>

                            <!-- ADMIN: GESTIÓN DE AGENTES -->
                            <div class="col-12 col-md-6 col-xl-4">
                                <div class="card menu-card card-hover h-100">
                                    <div class="card-body d-flex flex-column">
                                        <div class="menu-icon">AG</div>
                                        <h5 class="card-title">Gestión de Agentes</h5>
                                        <p class="card-text flex-grow-1">
                                            Crea, edita, elimina lógicamente y administra el estado de los agentes.
                                        </p>
                                        <a href="<%= request.getContextPath() %>/agente"
                                           class="btn btn-info-soft w-100">
                                            Ingresar
                                        </a>
                                    </div>
                                </div>
                            </div>

                            <!-- ADMIN: CAMBIAR CONTRASEÑA -->
                            <div class="col-12 col-md-6 col-xl-4">
                                <div class="card menu-card card-hover h-100">
                                    <div class="card-body d-flex flex-column">
                                        <div class="menu-icon">PW</div>
                                        <h5 class="card-title">Cambiar Contraseña</h5>
                                        <p class="card-text flex-grow-1">
                                            Actualiza tu contraseña ingresando la contraseña actual y la nueva.
                                        </p>
                                        <a href="<%= request.getContextPath() %>/vistas/agente_password.jsp"
                                           class="btn btn-info-soft w-100">
                                            Ingresar
                                        </a>
                                    </div>
                                </div>
                            </div>

                        <% } else { %>

                            <!-- AGENTE: MIS PEDIDOS -->
                            <div class="col-12 col-md-6 col-xl-4">
                                <div class="card menu-card card-hover h-100">
                                    <div class="card-body d-flex flex-column">
                                        <div class="menu-icon">MP</div>
                                        <h5 class="card-title">Mis Pedidos</h5>
                                        <p class="card-text flex-grow-1">
                                            Consulta y gestiona los pedidos asignados a tu usuario para procesarlos.
                                        </p>
                                        <a href="<%= request.getContextPath() %>/pedidos-agente"
                                           class="btn btn-info-soft w-100">
                                            Ingresar
                                        </a>
                                    </div>
                                </div>
                            </div>

                            <!-- AGENTE: CAMBIAR CONTRASEÑA -->
                            <div class="col-12 col-md-6 col-xl-4">
                                <div class="card menu-card card-hover h-100">
                                    <div class="card-body d-flex flex-column">
                                        <div class="menu-icon">PW</div>
                                        <h5 class="card-title">Cambiar Contraseña</h5>
                                        <p class="card-text flex-grow-1">
                                            Actualiza tu contraseña ingresando la contraseña actual y la nueva.
                                        </p>
                                        <a href="<%= request.getContextPath() %>/vistas/agente_password.jsp"
                                           class="btn btn-info-soft w-100">
                                            Ingresar
                                        </a>
                                    </div>
                                </div>
                            </div>

                        <% } %>

                    </div>

                </div>
            </div>

        </div>
    </div>

</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>