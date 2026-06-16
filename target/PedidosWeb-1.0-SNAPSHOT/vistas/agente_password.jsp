<%@page contentType="text/html" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Cambiar Contraseña</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Bootstrap remoto -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- SweetAlert2 remoto -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        body {
            background: #f5f5f5;
        }

        .page-wrapper {
            padding: 1.5rem;
        }

        .page-header-card {
            background: #ffffff;
            border-radius: 18px;
            border: 1px solid rgba(0,0,0,.06);
            box-shadow: 0 0.125rem 0.45rem rgba(0,0,0,.06);
            padding: 1.25rem;
            margin-bottom: 1.5rem;
        }

        .page-title {
            color: #0dcaf0;
            font-weight: 800;
            margin-bottom: .15rem;
        }

        .page-subtitle {
            color: #6c757d;
            font-size: .95rem;
        }

        .content-card {
            background: #ffffff;
            border-radius: 18px;
            border: 1px solid rgba(0,0,0,.06);
            box-shadow: 0 0.125rem 0.45rem rgba(0,0,0,.06);
            overflow: hidden;
        }

        .content-card-header {
            background: rgba(13,202,240,.16);
            border-left: 6px solid #0dcaf0;
            padding: 1rem 1.25rem;
        }

        .content-card-title {
            color: #0dcaf0;
            font-weight: 700;
            margin: 0;
        }

        .content-card-subtitle {
            color: #6c757d;
            font-size: .875rem;
            margin: .15rem 0 0 0;
        }

        .content-card-body {
            padding: 1.5rem;
        }

        .btn-info-soft {
            background-color: #0dcaf0;
            border-color: #0dcaf0;
            color: #ffffff;
            font-weight: 600;
            border-radius: .65rem;
        }

        .btn-info-soft:hover {
            background-color: #31d2f2;
            border-color: #25cff2;
            color: #ffffff;
        }

        .btn-light-soft {
            background-color: #f8f9fa;
            border-color: rgba(0,0,0,.08);
            color: #6c757d;
            font-weight: 600;
            border-radius: .65rem;
        }

        .form-label {
            color: #6c757d;
            font-weight: 600;
        }

        .form-control {
            border-radius: .65rem;
        }

        .form-control:focus {
            border-color: #0dcaf0;
            box-shadow: 0 0 0 .2rem rgba(13,202,240,.20);
        }

        .password-rules {
            background: #e8f9fd;
            border: 1px solid rgba(13,202,240,.25);
            color: #6c757d;
            border-radius: .75rem;
            font-size: .9rem;
        }

        @media (max-width: 768px) {
            .page-wrapper {
                padding: 1rem;
            }

            .content-card-body {
                padding: 1rem;
            }
        }
    </style>
</head>

<body>

<jsp:include page="/vistas/navbar.jsp" />

<%
    String swalIcon = (String) session.getAttribute("swal_icon");
    String swalTitle = (String) session.getAttribute("swal_title");
    String swalText = (String) session.getAttribute("swal_text");

    if (swalIcon != null) {
        session.removeAttribute("swal_icon");
        session.removeAttribute("swal_title");
        session.removeAttribute("swal_text");
    }
%>

<div class="page-wrapper">

    <div class="page-header-card">
        <h3 class="page-title">Cambiar Contraseña</h3>
        <div class="page-subtitle">
            Actualiza tu contraseña ingresando tu contraseña actual y una nueva contraseña.
        </div>
    </div>

    <div class="row justify-content-center">
        <div class="col-12 col-md-8 col-lg-6">

            <div class="content-card">

                <div class="content-card-header">
                    <h6 class="content-card-title">Seguridad de la cuenta</h6>
                    <p class="content-card-subtitle">
                        La contraseña actual será validada antes de guardar el cambio.
                    </p>
                </div>

                <div class="content-card-body">

                    <form method="post"
                          action="<%= request.getContextPath() %>/agente"
                          onsubmit="return validarPassword();">

                        <input type="hidden" name="accion" value="cambiarPassword">

                        <div class="mb-3">
                            <label class="form-label">Contraseña actual</label>
                            <input type="password"
                                   name="password_actual"
                                   id="password_actual"
                                   class="form-control"
                                   autocomplete="current-password"
                                   required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nueva contraseña</label>
                            <input type="password"
                                   name="password"
                                   id="password"
                                   class="form-control"
                                   autocomplete="new-password"
                                   required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Confirmar nueva contraseña</label>
                            <input type="password"
                                   name="confirm_password"
                                   id="confirmPassword"
                                   class="form-control"
                                   autocomplete="new-password"
                                   required>
                        </div>

                        <div class="alert password-rules mb-4">
                            Debes ingresar tu contraseña actual. La nueva contraseña debe coincidir con la confirmación.
                        </div>

                        <div class="d-flex justify-content-end gap-2 flex-wrap">
                            <a href="<%= request.getContextPath() %>/vistas/menu.jsp" class="btn btn-light-soft">
                                Cancelar
                            </a>

                            <button type="submit" class="btn btn-info-soft">
                                Cambiar contraseña
                            </button>
                        </div>

                    </form>

                </div>
            </div>

        </div>
    </div>

</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    function validarPassword() {
        const passwordActual = document.getElementById('password_actual').value;
        const password = document.getElementById('password').value;
        const confirmPassword = document.getElementById('confirmPassword').value;

        if (!passwordActual || passwordActual.trim() === '') {
            Swal.fire({
                icon: 'error',
                title: 'Validación',
                text: 'Debe ingresar la contraseña actual.',
                confirmButtonColor: '#0dcaf0'
            });
            return false;
        }

        if (!password || password.trim() === '') {
            Swal.fire({
                icon: 'error',
                title: 'Validación',
                text: 'Debe ingresar la nueva contraseña.',
                confirmButtonColor: '#0dcaf0'
            });
            return false;
        }

        if (!confirmPassword || confirmPassword.trim() === '') {
            Swal.fire({
                icon: 'error',
                title: 'Validación',
                text: 'Debe confirmar la nueva contraseña.',
                confirmButtonColor: '#0dcaf0'
            });
            return false;
        }

        if (password !== confirmPassword) {
            Swal.fire({
                icon: 'error',
                title: 'Validación',
                text: 'La nueva contraseña y la confirmación no coinciden.',
                confirmButtonColor: '#0dcaf0'
            });
            return false;
        }

        if (passwordActual === password) {
            Swal.fire({
                icon: 'warning',
                title: 'Validación',
                text: 'La nueva contraseña no debería ser igual a la contraseña actual.',
                confirmButtonColor: '#0dcaf0'
            });
            return false;
        }

        return true;
    }
</script>

<% if (swalIcon != null) { %>
<script>
    Swal.fire({
        icon: '<%= swalIcon %>',
        title: '<%= swalTitle == null ? "" : swalTitle %>',
        text: '<%= swalText == null ? "" : swalText %>',
        confirmButtonColor: '#0dcaf0',
        confirmButtonText: 'Aceptar'
    });
</script>
<% } %>

</body>
</html>