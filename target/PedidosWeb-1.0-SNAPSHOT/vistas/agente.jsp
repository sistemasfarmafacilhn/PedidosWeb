<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="modelos.Agente"%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Gestión de Agentes</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Bootstrap remoto -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- DataTables Bootstrap 5 -->
    <link href="https://cdn.datatables.net/2.0.8/css/dataTables.bootstrap5.css" rel="stylesheet">

    <!-- SweetAlert2 -->
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
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: .75rem;
            flex-wrap: wrap;
        }

        .content-card-title {
            color: #0dcaf0;
            font-weight: 700;
            margin: 0;
        }

        .content-card-subtitle {
            color: #6c757d;
            font-size: .875rem;
            margin: 0;
        }

        .table-card-body {
            padding: 1.25rem;
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

        .btn-outline-info-soft {
            border-color: #0dcaf0;
            color: #0dcaf0;
            font-weight: 600;
            border-radius: .65rem;
        }

        .btn-outline-info-soft:hover {
            background-color: #0dcaf0;
            color: #ffffff;
        }

        .btn-action {
            border-radius: .55rem;
            font-weight: 600;
        }

        .badge-disponible {
            background-color: #198754;
        }

        .badge-desconectado {
            background-color: #6c757d;
        }

        .badge-admin {
            background-color: #0d6efd;
        }

        .badge-agente {
            background-color: #0dcaf0;
            color: #212529;
        }

        .modal-content {
            border-radius: 18px;
            border: none;
            box-shadow: 0 0.5rem 1rem rgba(0,0,0,.15);
        }

        .modal-header {
            background: rgba(13,202,240,.16);
            border-left: 6px solid #0dcaf0;
            border-bottom: 1px solid rgba(0,0,0,.06);
        }

        .modal-title {
            color: #0dcaf0;
            font-weight: 700;
        }

        .form-label {
            color: #6c757d;
            font-weight: 600;
        }

        .form-control,
        .form-select {
            border-radius: .65rem;
        }

        .form-control:focus,
        .form-select:focus {
            border-color: #0dcaf0;
            box-shadow: 0 0 0 .2rem rgba(13,202,240,.20);
        }

        table.dataTable {
            border-collapse: separate !important;
            border-spacing: 0;
        }

        #tablaAgentes thead th {
            background: #e8f9fd;
            color: #0dcaf0;
            font-weight: 700;
            border-bottom: 1px solid rgba(0,0,0,.08);
        }

        #tablaAgentes tbody tr {
            vertical-align: middle;
        }

        #tablaAgentes tbody tr:hover {
            background-color: rgba(13,202,240,.07);
        }

        .dataTables_wrapper .dataTables_filter input,
        .dataTables_wrapper .dataTables_length select {
            border-radius: .65rem;
        }

        @media (max-width: 768px) {
            .page-wrapper {
                padding: 1rem;
            }

            .table-card-body {
                padding: .85rem;
            }

            .content-card-header {
                padding: .85rem;
            }
        }
    </style>
</head>

<body>

<jsp:include page="/vistas/navbar.jsp" />

<%
    List<Agente> agentes = (List<Agente>) request.getAttribute("agentes");

    String swalIcon = (String) session.getAttribute("swal_icon");
    String swalTitle = (String) session.getAttribute("swal_title");
    String swalText = (String) session.getAttribute("swal_text");

    if (swalIcon != null) {
        session.removeAttribute("swal_icon");
        session.removeAttribute("swal_title");
        session.removeAttribute("swal_text");
    }

    int totalAgentes = agentes != null ? agentes.size() : 0;
    int totalDisponibles = 0;
    int totalDesconectados = 0;
    int totalPausados = 0;
    int totalAdmins = 0;

    if (agentes != null) {
        for (Agente a : agentes) {
if (a.getEstado() == 1) {
    totalDisponibles++;
} else if (a.getEstado() == 3) {
    totalPausados++;
} else {
    totalDesconectados++;
}

            if (a.getRol() == 1) {
                totalAdmins++;
            }
        }
    }
%>

<div class="page-wrapper">

    <div class="page-header-card">
        <div class="d-flex justify-content-between align-items-center flex-wrap gap-3">
            <div>
                <h3 class="page-title">Gestión de Agentes</h3>
                <div class="page-subtitle">
                    Administración de usuarios/agentes del sistema de pedidos web.
                </div>
            </div>

            <div class="d-flex flex-wrap gap-2 align-items-center">
                <span class="badge bg-info text-dark fs-6">
                    <%= totalAgentes %> agentes
                </span>

                <span class="badge bg-success fs-6">
                    <%= totalDisponibles %> disponibles
                </span>

                <span class="badge bg-secondary fs-6">
                    <%= totalDesconectados %> desconectados
                </span>
                <span class="badge bg-warning text-dark fs-6">
    <%= totalPausados %> pausados
</span>

                <button class="btn btn-info-soft" data-bs-toggle="modal" data-bs-target="#modalNuevoAgente">
                    Nuevo Agente
                </button>
            </div>
        </div>
    </div>

    <div class="content-card">
        <div class="content-card-header">
            <div>
                <h6 class="content-card-title">Listado de agentes</h6>
                <p class="content-card-subtitle">
                    Consulta, edita, elimina lógicamente o cambia disponibilidad de los agentes.
                </p>
            </div>

            <span class="badge bg-primary">
                <%= totalAdmins %> administrador(es)
            </span>
        </div>

        <div class="table-card-body">
            <div class="table-responsive">
                <table id="tablaAgentes" class="table table-striped table-hover align-middle w-100">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nombre</th>
                            <th>Código</th>
                            <th>StaffID</th>
                            <th>Estado</th>
                            <th>Tiempo activo</th>
                            <th>Rol</th>
                            <th>Fecha creación</th>
                            <th class="text-center">Acciones</th>
                        </tr>
                    </thead>

                    <tbody>
                        <%
                            if (agentes != null) {
                                for (Agente a : agentes) {
                        %>
                        <tr>
                            <td><%= a.getIdUsuario() %></td>
                            <td><%= a.getNombre() == null ? "" : a.getNombre() %></td>
                            <td><%= a.getCodigo() == null ? "" : a.getCodigo() %></td>
                            <td><%= a.getStaffID() == null ? "" : a.getStaffID() %></td>

<td>
    <% if (a.getEstado() == 1) { %>
        <span class="badge badge-disponible">Disponible</span>
    <% } else if (a.getEstado() == 3) { %>
        <span class="badge bg-warning text-dark">Pausado</span>
    <% } else { %>
        <span class="badge badge-desconectado">Desconectado</span>
    <% } %>
</td>
<td>
    <% if (a.getEstado() == 1 && a.getUltimaFechaActivo() != null) { %>

        <div class="small">
            <div>
                <span class="text-muted">Actual:</span>
                <span class="badge bg-light text-dark border tiempo-activo"
                      data-inicio="<%= a.getUltimaFechaActivo().getTime() %>">
                    <%= a.getTiempoActivo() == null ? "00h 00m 00s" : a.getTiempoActivo() %>
                </span>
            </div>

            <div class="mt-1">
                <span class="text-muted">Hoy:</span>
                <span class="badge bg-info text-dark tiempo-activo-hoy"
                      data-inicio="<%= a.getUltimaFechaActivo().getTime() %>"
                      data-hoy-segundos="<%= a.getTiempoActivoHoySegundos() == null ? 0 : a.getTiempoActivoHoySegundos() %>">
                    <%= a.getTiempoActivoHoy() == null ? "00h 00m 00s" : a.getTiempoActivoHoy() %>
                </span>
            </div>
        </div>

    <% } else { %>

        <div class="small">
            <div>
                <span class="text-muted">Actual:</span>
                <span class="text-muted">00h 00m 00s</span>
            </div>

            <div class="mt-1">
                <span class="text-muted">Hoy:</span>
                <span class="badge bg-info text-dark">
                    <%= a.getTiempoActivoHoy() == null ? "00h 00m 00s" : a.getTiempoActivoHoy() %>
                </span>
            </div>
        </div>

    <% } %>
</td>

<td>
    <% if (a.getRol() == 1) { %>
        <span class="badge badge-admin">Administrador</span>
    <% } else { %>
        <span class="badge badge-agente">Agente</span>
    <% } %>
</td>

                            <td><%= a.getFechaCreacion() == null ? "" : a.getFechaCreacion() %></td>

                            <td class="text-center">
                                <div class="d-flex justify-content-center flex-wrap gap-1">

                                    <button class="btn btn-sm btn-warning btn-action"
                                            onclick="abrirEditar(
                                                    '<%= a.getIdUsuario() %>',
                                                    '<%= a.getNombre() == null ? "" : a.getNombre().replace("'", "\\'") %>',
                                                    '<%= a.getCodigo() == null ? "" : a.getCodigo().replace("'", "\\'") %>',
                                                    '<%= a.getStaffID() == null ? "" : a.getStaffID().replace("'", "\\'") %>',
                                                    '<%= a.getEstado() %>',
                                                    '<%= a.getRol() %>'
                                                    )">
                                        Editar
                                    </button>

                                    <form method="post"
                                          action="<%= request.getContextPath() %>/agente"
                                          class="d-inline"
                                          onsubmit="return confirmarEliminar(event, this);">
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="id_usuario" value="<%= a.getIdUsuario() %>">
                                        <button type="submit" class="btn btn-sm btn-danger btn-action">
                                            Eliminar
                                        </button>
                                    </form>

<form method="post"
      action="<%= request.getContextPath() %>/agente"
      class="d-inline">
    <input type="hidden" name="accion" value="cambiarEstado">
    <input type="hidden" name="id_usuario" value="<%= a.getIdUsuario() %>">
    <input type="hidden" name="estado" value="<%= a.getEstado() == 1 ? 0 : 1 %>">
    <button type="submit"
            class="btn btn-sm btn-action <%= a.getEstado() == 1 ? "btn-outline-dark" : "btn-outline-success" %>">
        <%= a.getEstado() == 1 ? "Desconectar" : "Conectar" %>
    </button>
</form>

<% if (a.getEstado() == 1) { %>
    <form method="post"
          action="<%= request.getContextPath() %>/agente"
          class="d-inline">
        <input type="hidden" name="accion" value="cambiarEstado">
        <input type="hidden" name="id_usuario" value="<%= a.getIdUsuario() %>">
        <input type="hidden" name="estado" value="3">
        <button type="submit" class="btn btn-sm btn-warning btn-action">
            Pausar
        </button>
    </form>
<% } %>

                                </div>
                            </td>
                        </tr>
                        <%
                                }
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Modal Nuevo Agente -->
<div class="modal fade" id="modalNuevoAgente" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <form method="post" action="<%= request.getContextPath() %>/agente" class="modal-content">

            <input type="hidden" name="accion" value="insertar">

            <div class="modal-header">
                <h5 class="modal-title">Nuevo Agente</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>

            <div class="modal-body">
                <div class="row g-3">

                    <div class="col-md-6">
                        <label class="form-label">Nombre</label>
                        <input type="text" name="nombre" class="form-control" maxlength="300" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Código / Usuario</label>
                        <input type="text" name="codigo" class="form-control" maxlength="50" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Contraseña inicial</label>
                        <input type="password" name="password" class="form-control" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">StaffID</label>
                        <input type="text" name="StaffID" class="form-control" maxlength="50">
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Estado</label>
<select name="estado" class="form-select">
    <option value="0">Desconectado</option>
    <option value="1">Disponible</option>
    <option value="3">Pausado</option>
</select>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Rol</label>
                        <select name="rol" class="form-select">
                            <option value="2">Agente</option>
                            <option value="1">Administrador</option>
                        </select>
                    </div>

                </div>
            </div>

            <div class="modal-footer">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
                <button type="submit" class="btn btn-info-soft">Guardar</button>
            </div>

        </form>
    </div>
</div>

<!-- Modal Editar Agente -->
<div class="modal fade" id="modalEditarAgente" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <form method="post" action="<%= request.getContextPath() %>/agente" class="modal-content">

            <input type="hidden" name="accion" value="editar">
            <input type="hidden" name="id_usuario" id="edit_id_usuario">

            <div class="modal-header">
                <h5 class="modal-title">Editar Agente</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>

            <div class="modal-body">
                <div class="row g-3">

                    <div class="col-md-6">
                        <label class="form-label">Nombre</label>
                        <input type="text" name="nombre" id="edit_nombre" class="form-control" maxlength="300" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Código / Usuario</label>
                        <input type="text" name="codigo" id="edit_codigo" class="form-control" maxlength="50" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">StaffID</label>
                        <input type="text" name="StaffID" id="edit_StaffID" class="form-control" maxlength="50">
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">Estado</label>
<select name="estado" id="edit_estado" class="form-select">
    <option value="0">Desconectado</option>
    <option value="1">Disponible</option>
    <option value="3">Pausado</option>
</select>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">Rol</label>
                        <select name="rol" id="edit_rol" class="form-select">
                            <option value="2">Agente</option>
                            <option value="1">Administrador</option>
                        </select>
                    </div>

                </div>
            </div>

            <div class="modal-footer">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancelar</button>
                <button type="submit" class="btn btn-warning">Actualizar</button>
            </div>

        </form>
    </div>
</div>

<!-- JS remoto -->
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script src="https://cdn.datatables.net/2.0.8/js/dataTables.js"></script>
<script src="https://cdn.datatables.net/2.0.8/js/dataTables.bootstrap5.js"></script>

<script>
    $(document).ready(function () {
        $('#tablaAgentes').DataTable({
            language: {
                url: 'https://cdn.datatables.net/plug-ins/2.0.8/i18n/es-ES.json'
            },
            pageLength: 10,
            order: [[0, 'desc']]
        });

        window.__inicioPaginaMs = new Date().getTime();

        actualizarTiemposActivos();
        setInterval(actualizarTiemposActivos, 1000);
    });

    function abrirEditar(idUsuario, nombre, codigo, staffID, estado, rol) {
        document.getElementById('edit_id_usuario').value = idUsuario;
        document.getElementById('edit_nombre').value = nombre;
        document.getElementById('edit_codigo').value = codigo;
        document.getElementById('edit_StaffID').value = staffID;
        document.getElementById('edit_estado').value = estado;
        document.getElementById('edit_rol').value = rol;

        const modal = new bootstrap.Modal(document.getElementById('modalEditarAgente'));
        modal.show();
    }

    function confirmarEliminar(e, form) {
        e.preventDefault();

        Swal.fire({
            title: '¿Eliminar agente?',
            text: 'El agente será eliminado lógicamente.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sí, eliminar',
            cancelButtonText: 'Cancelar',
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d'
        }).then((result) => {
            if (result.isConfirmed) {
                form.submit();
            }
        });

        return false;
    }

    function formatearDuracion(totalSegundos) {
        if (isNaN(totalSegundos) || totalSegundos < 0) {
            totalSegundos = 0;
        }

        const horas = Math.floor(totalSegundos / 3600);
        const minutos = Math.floor((totalSegundos % 3600) / 60);
        const segundos = totalSegundos % 60;

        return String(horas).padStart(2, "0") + "h " +
               String(minutos).padStart(2, "0") + "m " +
               String(segundos).padStart(2, "0") + "s";
    }

    function actualizarTiemposActivos() {
        const ahoraMs = new Date().getTime();
        const segundosDesdeCarga = Math.floor((ahoraMs - window.__inicioPaginaMs) / 1000);

        document.querySelectorAll(".tiempo-activo").forEach(el => {
            const inicioMs = parseInt(el.getAttribute("data-inicio"));

            if (isNaN(inicioMs)) {
                el.textContent = "00h 00m 00s";
                return;
            }

            const totalSegundos = Math.floor((ahoraMs - inicioMs) / 1000);
            el.textContent = formatearDuracion(totalSegundos);
        });

        document.querySelectorAll(".tiempo-activo-hoy").forEach(el => {
            const hoySegundosBase = parseInt(el.getAttribute("data-hoy-segundos"));

            if (isNaN(hoySegundosBase)) {
                el.textContent = "00h 00m 00s";
                return;
            }

            /*
             * TiempoActivoHoySegundos viene del SP calculado al momento
             * de cargar la página. Si el agente sigue disponible,
             * aquí solo sumamos los segundos transcurridos desde la carga.
             */
            const totalHoy = hoySegundosBase + segundosDesdeCarga;

            el.textContent = formatearDuracion(totalHoy);
        });
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