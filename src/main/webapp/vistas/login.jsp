<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String error = (String) request.getAttribute("error");
    String valCodigo = (String) request.getAttribute("val_codigo");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Iniciar sesión</title>

    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Bootstrap Icons opcional -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">

    <style>
        body {
            background: #f5f6fa;
        }

        .card-hover {
            transition: transform 0.15s ease, box-shadow 0.15s ease;
            border-radius: 16px;
            border: none;
        }

        .card-hover:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
        }

        .logo {
            max-width: 95px;
        }

        .system-title {
            color: #0dcaf0;
            font-weight: 700;
        }

        .btn-login {
            background-color: #0dcaf0;
            border-color: #0dcaf0;
            color: white;
            font-weight: 600;
        }

        .btn-login:hover {
            background-color: #0bb5d6;
            border-color: #0bb5d6;
            color: white;
        }

        .input-group-text {
            background-color: #f8f9fa;
        }
    </style>
</head>

<body class="d-flex align-items-center justify-content-center min-vh-100 bg-light">

    <div class="container">
        <div class="row justify-content-center">
            <div class="col-12 col-sm-8 col-md-5 col-lg-4">

                <div class="card shadow-sm card-hover">
                    <div class="card-body p-4">

                        <!-- Logo -->
                        <div class="text-center mb-3">
                            <img src="<%=request.getContextPath()%>/images/logo.png"
                                 alt="Logo"
                                 class="img-fluid logo">
                        </div>

                        <h3 class="text-center mb-1 system-title">Pedidos Web</h3>
                        <p class="text-center text-muted mb-4">
                            Inicio de sesión
                        </p>

                        <% if (error != null) { %>
                            <div class="alert alert-danger text-center" role="alert">
                                <%= error %>
                            </div>
                        <% } %>

                        <form method="post" action="<%=request.getContextPath()%>/login">

                            <div class="mb-3">
                                <label for="codigo" class="form-label">Código de usuario</label>
                                <div class="input-group">
                                    <span class="input-group-text">
                                        <i class="bi bi-person"></i>
                                    </span>
                                    <input type="text"
                                           class="form-control"
                                           id="codigo"
                                           name="codigo"
                                           value="<%= (valCodigo != null ? valCodigo : "") %>"
                                           autocomplete="username"
                                           autofocus
                                           required>
                                </div>
                            </div>

                            <div class="mb-3">
                                <label for="password" class="form-label">Contraseña</label>
                                <div class="input-group">
                                    <span class="input-group-text">
                                        <i class="bi bi-lock"></i>
                                    </span>
                                    <input type="password"
                                           class="form-control"
                                           id="password"
                                           name="password"
                                           autocomplete="current-password"
                                           required>
                                </div>
                            </div>

                            <button type="submit" class="btn btn-login w-100">
                                Iniciar sesión
                            </button>

                        </form>

                    </div>
                </div>

                <div class="text-center mt-3">
                    <small class="text-muted">
                        Sistema de gestión de pedidos web
                    </small>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>