<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Collections" %>
<%@ page import="modelos.PedidoAsignado" %>
<%@ page import="modelos.PedidoAsignadoDetalle" %>
<%@ page import="modelos.Agente" %>
<%@ page import="modelos.FarmaciaSupervisor" %>
<%@ page import="java.math.BigDecimal" %>

<%
    modelos.Agente agenteSesion = (modelos.Agente) session.getAttribute("usuarioObj");

    int rolAgente = agenteSesion != null ? agenteSesion.getRol() : 2;

    boolean esAdmin = rolAgente == 1;
    boolean esFarmacia = rolAgente == 3;
    boolean esVistaTotal = rolAgente == 4;
    boolean esSupervisor = rolAgente == 5;

    boolean mostrarSucursalComoAsignado = esFarmacia || esSupervisor;
    boolean usarTemaVerde = esFarmacia || esSupervisor;

    /*
        rol 1 = Administrador: ve pedidos que no sean agente de farmacia.
        rol 4 = Vista total: ve todos, incluyendo agentes de farmacia.
        rol 2 = Agente: gestiona sus pedidos.
        rol 3 = Agente de farmacia: gestiona sus pickup.
        rol 5 = Supervisor: ve pedidos de sus centros/sucursales asignadas.
    */
    boolean mostrarAccionesPedido = !esAdmin && !esVistaTotal;
    boolean mostrarEstadoAgente = rolAgente == 2;
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <title>
            <%= esFarmacia ? "Pedidos de agente de farmacia" : esSupervisor ? "Pedidos supervisados" : "Mis Pedidos Asignados" %>
        </title>

        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

        <style>
            #loader-overlay {
                position: fixed;
                inset: 0;
                background: rgba(255,255,255,0.85);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 999999;
            }

            body.loaded #loader-overlay {
                display: none;
            }

            .loader-content {
                text-align: center;
            }

            .loader-text {
                margin-top: 10px;
                font-weight: 500;
                color: #00B4E7;
            }

            body {
                background: #F2FBFE;
            }

            .card-hover {
                transition: transform 0.15s ease, box-shadow 0.15s ease;
            }

            .card-hover:hover {
                transform: translateY(-3px);
                box-shadow: 0 0.5rem 1rem rgba(0,180,231,0.20);
            }

            .pedido-card {
                background: #E8F8FD;
                border: 1px solid rgba(0,180,231,.12);
                border-radius: .9rem;
                overflow: hidden;
            }

            .pedido-card .card-footer {
                background: #F2FBFE !important;
            }

            .pedido-header {
                display: flex;
                justify-content: space-between;
                align-items: flex-start;
                gap: .75rem;
                flex-wrap: wrap;
            }

            .badge-estado {
                font-size: .85rem;
                padding: .45rem .6rem;
            }

            .info-line {
                display: flex;
                justify-content: space-between;
                gap: 10px;
                padding: 2px 0;
            }

            .info-line .k {
                color: #0092BA;
            }

            .info-line .v {
                font-weight: 500;
                text-align: right;
                max-width: 70%;
                overflow-wrap: anywhere;
            }

            .estado-box {
                border: 1px solid rgba(0,180,231,.12);
                border-radius: .75rem;
                overflow: hidden;
                background: #fff;
            }

            .estado-abierto {
                border-left: 6px solid #00B4E7;
            }

            .estado-abierto .estado-header {
                background: #E8F8FD;
            }

            .estado-cerrado {
                border-left: 6px solid #198754;
            }

            .estado-cerrado .estado-header {
                background: rgba(25,135,84,.16);
            }

            .estado-cancelado {
                border-left: 6px solid #dc3545;
            }

            .estado-cancelado .estado-header {
                background: rgba(220,53,69,.16);
            }

            .estado-header {
                padding: 1rem;
                display: flex;
                justify-content: space-between;
                align-items: center;
                flex-wrap: wrap;
                gap: .5rem;
            }

            .estado-scroll {
                max-height: 680px;
                overflow-y: auto;
                padding-right: 4px;
            }

            .estado-scroll::-webkit-scrollbar {
                width: 6px;
            }

            .estado-scroll::-webkit-scrollbar-thumb {
                background: #00B4E7;
                border-radius: 10px;
            }

            .estado-scroll::-webkit-scrollbar-track {
                background: #E8F8FD;
            }

            .producto-table th {
                font-size: .82rem;
                color: #0092BA;
            }

            .producto-table td {
                font-size: .86rem;
                vertical-align: middle;
            }

            .text-order {
                color: #00B4E7;
                font-weight: 700;
            }

            .total-box {
                background: #ffffff;
                border: 1px solid rgba(0,180,231,.15);
                border-radius: .75rem;
                padding: .75rem;
            }

            .empty-state {
                background: #fff;
                border-radius: .75rem;
                box-shadow: 0 0.125rem 0.45rem rgba(0,180,231,.10);
                padding: 2rem;
                text-align: center;
                color: #0092BA;
            }

            .pedido-item.oculto-estado {
                display: none !important;
            }

            .modal-header-solicitud {
                background: #E8F8FD;
                border-left: 6px solid #00B4E7;
            }

            .modal-header-solicitud .modal-title {
                color: #00B4E7;
                font-weight: 700;
            }

            .btn-solicitud-tarjeta {
                background: linear-gradient(135deg, #00B4E7, #00CF78);
                border: none;
                color: #ffffff;
                font-weight: 700;
                letter-spacing: .01em;
                animation: pulseSolicitud 1.8s infinite;
            }

            .btn-solicitud-tarjeta:hover,
            .btn-solicitud-tarjeta:focus {
                color: #ffffff;
                filter: brightness(1.08);
            }

            @keyframes pulseSolicitud {
                0% {
                    box-shadow: 0 0 0 0 rgba(0, 180, 231, .45);
                }
                70% {
                    box-shadow: 0 0 0 9px rgba(0, 180, 231, 0);
                }
                100% {
                    box-shadow: 0 0 0 0 rgba(0, 180, 231, 0);
                }
            }

            .solicitud-modal-body {
                background: #F2FBFE;
            }

            .solicitud-section {
                background: #ffffff;
                border: 1px solid rgba(0, 180, 231, .15);
                border-radius: .75rem;
                padding: 1rem 1.1rem;
                margin-bottom: .9rem;
            }

            .solicitud-section:last-child {
                margin-bottom: 0;
            }

            .solicitud-section-title {
                font-size: .72rem;
                text-transform: uppercase;
                letter-spacing: .05em;
                font-weight: 700;
                color: #00B4E7;
                margin-bottom: .75rem;
                display: flex;
                align-items: center;
                gap: .4rem;
            }

            .solicitud-fields-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: .1rem 1rem;
            }

            .solicitud-field {
                margin-bottom: .65rem;
            }

            .solicitud-field.full {
                grid-column: 1 / -1;
            }

            .solicitud-field .label {
                font-size: .72rem;
                color: #0092BA;
                font-weight: 600;
                margin-bottom: .1rem;
            }

            .solicitud-field .value {
                font-size: .92rem;
                font-weight: 600;
                word-break: break-word;
            }

            .solicitud-field .value.empty {
                color: #9db3ba;
                font-weight: 400;
                font-style: italic;
            }

            .modal-footer-solicitud {
                background: #ffffff;
                border-top: 1px solid rgba(0, 180, 231, .15);
            }

            .btn-inscribir {
                background-color: #00CF78;
                border-color: #00CF78;
                color: #ffffff;
                font-weight: 700;
            }

            .btn-inscribir:hover {
                background-color: #00A863;
                border-color: #00A863;
                color: #ffffff;
            }

            @media (max-width: 480px) {
                .solicitud-fields-grid {
                    grid-template-columns: 1fr;
                }
            }

            .acciones-footer {
                padding-top: 12px;
                padding-bottom: 4px;
            }


            /* ============================================================
               TEMA VERDE
               rol = 3 Agente de farmacia
               rol = 5 Supervisor
               Color principal: #00CF78
               ============================================================ */

            body.vista-farmacia {
                background: #E5FBF0;
            }

            body.vista-farmacia .loader-text {
                color: #00CF78 !important;
            }

            body.vista-farmacia .spinner-border.text-info {
                color: #00CF78 !important;
            }

            body.vista-farmacia .text-info,
            body.vista-farmacia .text-order {
                color: #00A863 !important;
            }

            body.vista-farmacia .btn-info {
                background-color: #00CF78 !important;
                border-color: #00CF78 !important;
                color: #ffffff !important;
            }

            body.vista-farmacia .btn-outline-info {
                color: #00A863 !important;
                border-color: #00CF78 !important;
            }

            body.vista-farmacia .btn-outline-info:hover,
            body.vista-farmacia .btn-outline-info.active {
                background-color: #00CF78 !important;
                border-color: #00CF78 !important;
                color: #ffffff !important;
            }

            body.vista-farmacia .badge.bg-info {
                background-color: #00CF78 !important;
                color: #ffffff !important;
            }

            body.vista-farmacia .estado-abierto {
                border-left-color: #00CF78 !important;
            }

            body.vista-farmacia .estado-abierto .estado-header {
                background: #E5FBF0 !important;
            }

            body.vista-farmacia .estado-scroll::-webkit-scrollbar-thumb {
                background: #00CF78 !important;
            }

            body.vista-farmacia .table-info {
                --bs-table-bg: #E5FBF0;
                --bs-table-color: #00693D;
                border-color: rgba(0, 207, 120, .45);
            }

            body.vista-farmacia .total-box {
                border-color: rgba(0, 207, 120, .45);
            }

            body.vista-farmacia .pedido-card {
                background: #E5FBF0;
                border-color: rgba(0, 207, 120, .40);
            }

            body.vista-farmacia .pedido-card .card-footer {
                background: #E5FBF0 !important;
            }

            body.vista-farmacia .bg-white {
                background-color: #ffffff !important;
            }

            body.vista-farmacia .empty-state {
                background: #ffffff;
            }

            body.vista-farmacia .modal-header-solicitud {
                background: #E5FBF0 !important;
                border-left-color: #00CF78 !important;
            }

            body.vista-farmacia .modal-header-solicitud .modal-title {
                color: #00A863 !important;
            }

            body.vista-farmacia .solicitud-section-title {
                color: #00A863 !important;
            }

            body.vista-farmacia .solicitud-field .label {
                color: #00A863 !important;
            }

            @media (max-width: 576px) {
                .estado-header {
                    padding: .75rem;
                }

                .pedido-card .card-body {
                    padding: .9rem;
                }

                .info-line {
                    flex-direction: column;
                    gap: 0;
                }

                .info-line .v {
                    text-align: left;
                    max-width: 100%;
                }

                .btn-group {
                    width: 100%;
                }

                .btn-group .btn {
                    flex: 1;
                }
            }
        </style>
    </head>

    <body class="<%= usarTemaVerde ? "vista-farmacia" : "" %>">

        <jsp:include page="/vistas/navbar.jsp" />

        <div id="loader-overlay">
            <div class="loader-content">
                <div class="spinner-border text-info" style="width:3rem;height:3rem;" role="status"></div>
                <div class="loader-text">Cargando pedidos...</div>
            </div>
        </div>

        <%
            List<PedidoAsignado> pedidos = (List<PedidoAsignado>) request.getAttribute("pedidos");

            String staffID = (String) request.getAttribute("staffID");
            String agenteNombre = (String) request.getAttribute("agenteNombre");
            String fechaSeleccionada = (String) request.getAttribute("fechaSeleccionada");
            String error = (String) request.getAttribute("error");

            List<Agente> agentes = (List<Agente>) request.getAttribute("agentes");
            List<FarmaciaSupervisor> farmaciasSupervisor =
                    (List<FarmaciaSupervisor>) request.getAttribute("farmaciasSupervisor");

            if (farmaciasSupervisor == null) {
                farmaciasSupervisor = Collections.emptyList();
            }

            String staffIDFiltro = (String) request.getAttribute("staffIDFiltro");

            if (staffID == null) {
                staffID = "";
            }

            if (agenteNombre == null) {
                agenteNombre = "";
            }

            if (fechaSeleccionada == null) {
                fechaSeleccionada = "";
            }

            if (staffIDFiltro == null) {
                staffIDFiltro = "";
            }

            int totalPedidos = pedidos != null ? pedidos.size() : 0;
            int totalAbiertos = 0;
            int totalCerrados = 0;
            int totalCancelados = 0;

            if (pedidos != null) {
                for (PedidoAsignado p : pedidos) {
                    if (p.getEstadoControl() == 0) {
                        totalAbiertos++;
                    } else if (p.getEstadoControl() == 1) {
                        totalCerrados++;
                    } else if (p.getEstadoControl() == 2) {
                        totalCancelados++;
                    }
                }
            }

            int estadoAgente = 0;
            int nuevoEstadoAgente = 1;
            String textoEstadoAgente = "Desconectado";
            String claseEstadoAgente = "btn-outline-success";
            String textoBotonEstadoAgente = "Cambiar a Disponible";

            if (agenteSesion != null) {
                estadoAgente = agenteSesion.getEstado();

                if (estadoAgente == 1) {
                    nuevoEstadoAgente = 0;
                    textoEstadoAgente = "Disponible";
                    claseEstadoAgente = "btn-outline-danger";
                    textoBotonEstadoAgente = "Cambiar a Desconectado";
                } else if (estadoAgente == 3) {
                    nuevoEstadoAgente = 1;
                    textoEstadoAgente = "Pausado";
                    claseEstadoAgente = "btn-outline-success";
                    textoBotonEstadoAgente = "Cambiar a Disponible";
                } else {
                    nuevoEstadoAgente = 1;
                    textoEstadoAgente = "Desconectado";
                    claseEstadoAgente = "btn-outline-success";
                    textoBotonEstadoAgente = "Cambiar a Disponible";
                }
            }
        %>

        <div class="container-fluid py-4 px-2 px-md-4">

            <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
                <div>
                    <h3 class="m-0 text-info">
                        <%= esFarmacia ? "Pedidos de agente de farmacia" : esSupervisor ? "Pedidos supervisados" : "Mis Pedidos Asignados" %>
                    </h3>

                    <div class="text-muted small">
                        <%= esFarmacia ? "Agente de farmacia" : esSupervisor ? "Supervisor" : "Agente" %>: <strong><%= agenteNombre %></strong>

                        <% if (!staffID.trim().isEmpty()) { %>
                            | StaffID: <strong><%= staffID %></strong>
                        <% } %>

                        <% if (mostrarEstadoAgente) { %>
                            | Estado: <strong><%= textoEstadoAgente %></strong>
                        <% } else if (esFarmacia) { %>
                            | Rol: <strong>Agente de farmacia</strong>
                        <% } else if (esSupervisor) { %>
                            | Rol: <strong>Supervisor</strong>
                        <% } else if (esVistaTotal) { %>
                            | Rol: <strong>Vista total</strong>
                        <% } else { %>
                            | Rol: <strong>Administrador</strong>
                        <% } %>
                    </div>
                </div>

                <div class="d-flex flex-wrap gap-2 align-items-center">

                    <% if (mostrarEstadoAgente) { %>

                        <form method="POST"
                              action="<%= request.getContextPath() %>/pedidos-agente"
                              class="m-0 form-sin-loader"
                              onsubmit="return confirmarCambioEstadoAgente(event, this);">

                            <input type="hidden" name="accion" value="cambiarEstadoAgente">
                            <input type="hidden" name="estado" value="<%= nuevoEstadoAgente %>">
                            <input type="hidden" name="password" class="passwordEstadoAgente" value="">

                            <button type="submit" class="btn btn-sm <%= claseEstadoAgente %>">
                                <%= textoBotonEstadoAgente %>
                            </button>
                        </form>

                        <% if (estadoAgente == 1) { %>
                            <form method="POST"
                                  action="<%= request.getContextPath() %>/pedidos-agente"
                                  class="m-0 form-sin-loader"
                                  onsubmit="return confirmarPausarAgente(event, this);">

                                <input type="hidden" name="accion" value="cambiarEstadoAgente">
                                <input type="hidden" name="estado" value="3">

                                <button type="submit" class="btn btn-sm btn-warning text-dark">
                                    Pausar
                                </button>
                            </form>
                        <% } %>

                    <% } else if (esAdmin || esVistaTotal) { %>

                        <form method="POST"
                              action="<%= request.getContextPath() %>/pedidos-agente"
                              class="m-0 form-sin-loader"
                              onsubmit="return confirmarAsignarPendientes(event, this);">

                            <input type="hidden" name="accion" value="asignarPendientes">
                            <input type="hidden" name="cantidad" value="">
                            <input type="hidden" name="staffIDDestino" value="">

                            <button type="submit" class="btn btn-sm btn-info text-white">
                                Asignar pendientes
                            </button>
                        </form>

                    <% } %>

                    <span class="badge bg-info text-dark fs-6" id="badgeTituloEstado">
                        <%= totalAbiertos %> abiertos
                    </span>
                </div>
            </div>

            <div class="bg-white rounded-3 shadow-sm p-3 mb-4">
                <form class="row g-3 align-items-end"
                      method="POST"
                      action="<%= request.getContextPath() %>/pedidos-agente">

                    <input type="hidden" name="accion" value="filtrar">

                    <div class="col-12 col-md-3">
                        <label class="form-label">Fecha de asignación</label>
                        <input type="date"
                               class="form-control"
                               name="fecha"
                               value="<%= fechaSeleccionada %>">
                    </div>

                    <% if (esAdmin || esVistaTotal) { %>
                        <div class="col-12 col-md-4">
                            <label class="form-label">Agente</label>
                            <select class="form-select" name="staffIDFiltro">
                                <option value="">Todos los agentes</option>

                                <% if (agentes != null) {
                                    for (Agente ag : agentes) {
                                        String agStaffID = ag.getStaffID() != null ? ag.getStaffID() : "";
                                        String agNombre = ag.getNombre() != null ? ag.getNombre() : "";
                                        boolean seleccionado = agStaffID.equals(staffIDFiltro);

                                        boolean mostrarEnCombo = !agStaffID.trim().isEmpty();

                                        if (esAdmin && ag.getRol() == 3) {
                                            mostrarEnCombo = false;
                                        }

                                        if (mostrarEnCombo) {
                                %>
                                            <option value="<%= agStaffID %>" <%= seleccionado ? "selected" : "" %>>
                                                <%= agStaffID %> - <%= agNombre %>
                                                <% if (ag.getRol() == 3) { %>
                                                    (Agente de farmacia)
                                                <% } else if (ag.getRol() == 4) { %>
                                                    (Vista total)
                                                <% } else if (ag.getRol() == 5) { %>
                                                    (Supervisor)
                                                <% } %>
                                            </option>
                                <%
                                        }
                                    }
                                } %>
                            </select>
                        </div>
                    <% } else if (esSupervisor) { %>
                        <div class="col-12 col-md-5">
                            <label class="form-label">Farmacia supervisada</label>
                            <select class="form-select" name="staffIDFiltro">
                                <option value="">Todas mis farmacias</option>

                                <% for (FarmaciaSupervisor f : farmaciasSupervisor) {
                                    String store = f.getStoreID() == null ? "" : f.getStoreID();
                                    String centro = f.getCentro() == null ? "" : f.getCentro();
                                    String name = f.getName() == null ? "" : f.getName();
                                    boolean seleccionado = store.equalsIgnoreCase(staffIDFiltro);
                                %>
                                    <option value="<%= store %>" <%= seleccionado ? "selected" : "" %>>
                                        <%= store %> - <%= centro %> - <%= name %>
                                    </option>
                                <% } %>
                            </select>

                            <% if (farmaciasSupervisor.isEmpty()) { %>
                                <div class="form-text text-danger">
                                    No tiene farmacias asignadas para supervisar.
                                </div>
                            <% } else { %>
                            <% } %>
                        </div>
                    <% } else { %>
                        <input type="hidden" name="staffIDFiltro" value="">
                    <% } %>

                    <div class="col-12 col-md-2 d-grid">
                        <button type="submit" class="btn btn-info text-white">
                            Filtrar
                        </button>
                    </div>

                    <%
                        java.time.LocalDate hoy = java.time.LocalDate.now();
                        String fechaHoy = hoy.toString();
                    %>

                    <div class="col-12 col-md-2 d-grid">
                        <a href="<%= request.getContextPath() %>/pedidos-agente?fecha=<%= fechaHoy %>"
                           class="btn btn-outline-secondary">
                            Hoy
                        </a>
                    </div>

                    <div class="col-12 col-md-2 d-grid">
                        <a href="<%= request.getContextPath() %>/pedidos-agente"
                           class="btn btn-outline-secondary">
                            Limpiar filtros
                        </a>
                    </div>
                </form>
            </div>

            <div class="bg-white rounded-3 shadow-sm p-3 mb-4">
                <div class="d-flex flex-wrap gap-2 align-items-center justify-content-between">

                    <div class="d-flex flex-wrap gap-2 align-items-center">
                        <% if (!mostrarAccionesPedido) { %>
                            <button type="button"
                                    id="btnToggleAsignacion"
                                    class="btn btn-sm btn-outline-secondary"
                                    onclick="toggleAsignacion()">
                                Ver sin asignar
                            </button>
                        <% } %>

                        <small class="text-muted" id="textoFiltroAsignacion">
                            Mostrando pedidos asignados
                        </small>
                    </div>

                    <div class="btn-group btn-group-sm flex-wrap" role="group" aria-label="Filtro de estado">
                        <button type="button"
                                class="btn btn-info text-white filtro-estado active"
                                data-estado="0"
                                onclick="filtrarPorEstado(0, this)">
                            Abiertos
                            <span class="badge bg-light text-dark ms-1"><%= totalAbiertos %></span>
                        </button>

                        <button type="button"
                                class="btn btn-outline-success filtro-estado"
                                data-estado="1"
                                onclick="filtrarPorEstado(1, this)">
                            Cerrados
                            <span class="badge bg-success text-white ms-1"><%= totalCerrados %></span>
                        </button>

                        <button type="button"
                                class="btn btn-outline-danger filtro-estado"
                                data-estado="2"
                                onclick="filtrarPorEstado(2, this)">
                            Cancelados
                            <span class="badge bg-danger text-white ms-1"><%= totalCancelados %></span>
                        </button>
                    </div>

                </div>
            </div>

            <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="alert alert-danger">
                    <%= error %>
                </div>
            <% } %>

            <% if (pedidos == null || pedidos.isEmpty()) { %>

                <div class="empty-state">
                    <h5 class="mb-2">No hay pedidos disponibles</h5>
                    <p class="mb-0">
                        No hay pedidos para la fecha seleccionada.
                    </p>
                </div>

            <% } else { %>

                <div class="estado-box estado-abierto h-100" id="estadoBoxPedidos">
                    <div class="estado-header">
                        <div>
                            <div class="fw-semibold text-info" id="tituloEstadoPedidos">Pedidos abiertos</div>
                            <div class="text-muted small" id="descripcionEstadoPedidos">
                                Pedidos pendientes de facturación, gestión o cierre. Vista actual: pedidos asignados.
                            </div>
                        </div>

                        <span class="badge bg-info text-dark" id="contadorEstadoPedidos"><%= totalAbiertos %></span>
                    </div>

                    <div class="p-3 estado-scroll">
                        <div class="row g-3" id="contenedorPedidos">

                            <%
                                for (PedidoAsignado p : pedidos) {
                                    String collapseId = "det_" + String.valueOf(p.getIdPedidoGestion()).replaceAll("[^a-zA-Z0-9]", "");

                                    BigDecimal total = p.getTotal();
                                    BigDecimal subtotal = p.getPedidoSubtotal();
                                    BigDecimal shipping = p.getShipping();
                                    BigDecimal discount = p.getDiscount();

                                    String totalTxt = total != null ? total.toString() : "0.00";
                                    String subtotalTxt = subtotal != null ? subtotal.toString() : "0.00";
                                    String shippingTxt = shipping != null ? shipping.toString() : "0.00";
                                    String discountTxt = discount != null ? discount.toString() : "0.00";

                                    List<PedidoAsignadoDetalle> detalles = p.getDetalles();
                                    int totalProductos = detalles != null ? detalles.size() : 0;

                                    String badgeEstadoClass = "bg-info text-dark";
                                    if (p.getEstadoControl() == 1) {
                                        badgeEstadoClass = "bg-success text-white";
                                    } else if (p.getEstadoControl() == 2) {
                                        badgeEstadoClass = "bg-danger text-white";
                                    }

                                    String pedidoCardClass = "pedido-card card-hover h-100 shadow-sm";
                            %>

                            <div class="col-12 col-md-6 col-xl-4 pedido-item"
                                 data-estado="<%= p.getEstadoControl() %>"
                                 data-id-control="<%= p.getIdControlPedido() %>"
                                 data-staffid="<%= p.getStaffID() != null ? p.getStaffID() : "" %>">

                                <div class="card <%= pedidoCardClass %>">

                                    <div class="card-body">

                                        <div class="pedido-header">
                                            <div>
                                                <h6 class="mb-1">
                                                    <span class="text-order">Pedido:</span>
                                                    <span><%= p.getOrderCode() != null ? p.getOrderCode() : p.getOrderIdWeb() %></span>
                                                </h6>

                                                <div class="text-muted small">
                                                    Web ID: <%= p.getOrderIdWeb() != null ? p.getOrderIdWeb() : "" %>
                                                </div>

                                                <div class="text-muted small">
                                                    Asignado: <%= p.getFechaAsignacion() != null ? p.getFechaAsignacion() : "" %>
                                                </div>

                                                <% if (p.getFechaCierre() != null) { %>
                                                    <div class="text-muted small">
                                                        Cerrado: <%= p.getFechaCierre() %>
                                                    </div>
                                                <% } %>

                                                <% if (p.getFechaCancelacion() != null) { %>
                                                    <div class="text-muted small">
                                                        Cancelado: <%= p.getFechaCancelacion() %>
                                                    </div>
                                                <% } %>
                                            </div>

                                            <div class="d-flex flex-column align-items-end gap-1">
                                                <span class="badge <%= badgeEstadoClass %> badge-estado">
                                                    <%= p.getEstadoControlDescripcion() != null ? p.getEstadoControlDescripcion() : "Abierto" %>
                                                </span>

                                                <% if (p.getDeliveryType() != null) { %>
                                                    <% if ("delivery".equalsIgnoreCase(p.getDeliveryType())) { %>
                                                        <span class="badge bg-danger text-white">En Domicilio</span>
                                                    <% } else if ("pickup".equalsIgnoreCase(p.getDeliveryType())) { %>
                                                        <span class="badge bg-danger text-white">En Tienda</span>
                                                    <% } %>
                                                <% } %>

                                                <% if (p.isHasTransfer()) { %>
                                                    <span class="badge bg-warning text-dark">Traslado</span>
                                                <% } %>

                                                <% if ("approved".equalsIgnoreCase(p.getPaymentStatus())) { %>
                                                    <span class="badge bg-success text-white">Pago Aprobado en la Web</span>
                                                <% } %>

                                                <% if (p.isCallcenterRequired()) { %>
                                                    <span class="badge bg-danger text-white">Callcenter</span>
                                                <% } %>
                                            </div>
                                        </div>

                                        <% if (p.isTieneSolicitudTarjetaPlus()) { %>
                                            <button type="button"
                                                    class="btn btn-sm btn-solicitud-tarjeta w-100 mt-2"
                                                    data-bs-toggle="modal"
                                                    data-bs-target="#solicitud_<%= collapseId %>">
                                                <i class="bi bi-credit-card-2-front-fill"></i> Solicitud Tarjeta Plus
                                            </button>
                                        <% } %>

                                        <hr class="my-2">

                                        <div class="info-line">
                                            <div class="k">
                                                <%= mostrarSucursalComoAsignado ? "Sucursal" : "Agente asignado" %>
                                            </div>
                                            <div class="v">
                                                <% if (mostrarSucursalComoAsignado) { %>
                                                    <%= p.getBranchName() != null && !p.getBranchName().trim().isEmpty()
                                                            ? p.getBranchName()
                                                            : "Sin sucursal" %>
                                                <% } else { %>
                                                    <%= p.getNombreAgente() != null && !p.getNombreAgente().trim().isEmpty()
                                                            ? p.getNombreAgente()
                                                            : "Sin asignar" %>
                                                <% } %>
                                            </div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Cliente</div>
                                            <div class="v"><%= p.getCustomerName() != null ? p.getCustomerName() : "" %></div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Identificación</div>
                                            <div class="v"><%= p.getCustomerIdentityDocument() != null ? p.getCustomerIdentityDocument() : "" %></div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Teléfono</div>
                                            <div class="v"><%= p.getCustomerPhone() != null ? p.getCustomerPhone() : "" %></div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Persona que recibe</div>
                                            <div class="v"><%= p.getContactName() != null ? p.getContactName() : "" %></div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Tel. receptor</div>
                                            <div class="v"><%= p.getContactPhone() != null ? p.getContactPhone() : "" %></div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Ciudad</div>
                                            <div class="v"><%= p.getDeliveryCity() != null ? p.getDeliveryCity() : "" %></div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Departamento</div>
                                            <div class="v"><%= p.getDeliveryDepartment() != null ? p.getDeliveryDepartment() : "" %></div>
                                        </div>

                                        <div class="info-line">
                                            <div class="k">Dirección</div>
                                            <div class="v"><%= p.getDeliveryAddress() != null ? p.getDeliveryAddress() : "" %></div>
                                        </div>

                                        <% if (!mostrarSucursalComoAsignado) { %>
                                            <div class="info-line">
                                                <div class="k">Sucursal</div>
                                                <div class="v"><%= p.getBranchName() != null ? p.getBranchName() : "" %></div>
                                            </div>
                                        <% } %>

                                        <div class="info-line">
                                            <div class="k">Pago</div>
                                            <div class="v">
                                                <%= p.getPaymentMethod() != null ? p.getPaymentMethod() : "" %>
                                                <% if (p.getPaymentStatus() != null && !p.getPaymentStatus().trim().isEmpty()) { %>
                                                    / <%= p.getPaymentStatus() %>
                                                <% } %>
                                            </div>
                                        </div>

                                        <div class="mt-3 total-box">
                                            <div class="info-line">
                                                <div class="k">Subtotal</div>
                                                <div class="v">L. <%= subtotalTxt %></div>
                                            </div>
                                            <div class="info-line">
                                                <div class="k">Envío</div>
                                                <div class="v">L. <%= shippingTxt %></div>
                                            </div>
                                            <div class="info-line">
                                                <div class="k">Descuento</div>
                                                <div class="v">L. <%= discountTxt %></div>
                                            </div>
                                            <hr class="my-2">
                                            <div class="info-line">
                                                <div class="k fw-bold">Total</div>
                                                <div class="v fw-bold text-info">
                                                    <%= p.getCurrency() != null ? p.getCurrency() : "HNL" %>
                                                    <%= totalTxt %>
                                                </div>
                                            </div>
                                        </div>

                                        <% if (p.getCustomerNotes() != null && !p.getCustomerNotes().trim().isEmpty()) { %>
                                            <div class="alert alert-warning mt-3 mb-0 py-2">
                                                <small>
                                                    <strong>Nota cliente:</strong>
                                                    <%= p.getCustomerNotes() %>
                                                </small>
                                            </div>
                                        <% } %>

                                        <% if (p.getObservacion() != null && !p.getObservacion().trim().isEmpty()) { %>
                                            <div class="alert alert-secondary mt-3 mb-0 py-2">
                                                <small>
                                                    <strong>Observación:</strong>
                                                    <%= p.getObservacion() %>
                                                </small>
                                            </div>
                                        <% } %>

                                        <div class="mt-3">
                                            <a class="text-decoration-none small"
                                               data-bs-toggle="collapse"
                                               href="#<%= collapseId %>"
                                               role="button">
                                                Ver productos (<%= totalProductos %>)
                                            </a>

                                            <div class="collapse mt-2" id="<%= collapseId %>">
                                                <div class="border rounded p-2 bg-light">

                                                    <% if (detalles == null || detalles.isEmpty()) { %>
                                                        <div class="text-center text-muted small py-2">
                                                            Este pedido no tiene productos cargados.
                                                        </div>
                                                    <% } else { %>

                                                        <div class="table-responsive">
                                                            <table class="table table-sm table-bordered producto-table mb-0">
                                                                <thead class="table-info">
                                                                    <tr>
                                                                        <th>Código</th>
                                                                        <th>Producto</th>
                                                                        <th>Descuento</th>
                                                                        <th class="text-end">Cant.</th>
                                                                        <th class="text-end">Precio</th>
                                                                        <th class="text-end">Subtotal</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <%
                                                                        for (PedidoAsignadoDetalle d : detalles) {
                                                                    %>
                                                                        <tr>
                                                                            <td><%= d.getSku() != null ? d.getSku() : "" %></td>
                                                                            <td>
                                                                                <%= d.getNombre() != null ? d.getNombre() : "" %>

                                                                                <% if (d.isCanje()) { %>
                                                                                    <div>
                                                                                        <span class="badge bg-warning text-dark">
                                                                                            Canje
                                                                                        </span>
                                                                                        <% if (d.getCanjePromocion() != null) { %>
                                                                                            <small class="text-muted">
                                                                                                <%= d.getCanjePromocion() %>
                                                                                            </small>
                                                                                        <% } %>
                                                                                    </div>
                                                                                <% } %>
                                                                            </td>

                                                                            <td>
                                                                                <% if (d.getDescuentoTipo() != null && !d.getDescuentoTipo().trim().isEmpty()) { %>
                                                                                    <span class="badge bg-success text-white">
                                                                                        <%= d.getDescuentoTipo() %>
                                                                                    </span>
                                                                                <% } else { %>
                                                                                    <span class="text-muted small">Sin descuento</span>
                                                                                <% } %>
                                                                            </td>

                                                                            <td class="text-end"><%= d.getQuantity() != null ? d.getQuantity() : "" %></td>
                                                                            <td class="text-end">L. <%= d.getUnitPrice() != null ? d.getUnitPrice() : "0.00" %></td>
                                                                            <td class="text-end">L. <%= d.getSubtotal() != null ? d.getSubtotal() : "0.00" %></td>
                                                                        </tr>
                                                                    <%
                                                                        }
                                                                    %>
                                                                </tbody>
                                                            </table>
                                                        </div>

                                                    <% } %>

                                                </div>
                                            </div>
                                        </div>

                                    </div>

                                    <% if (mostrarAccionesPedido) { %>
                                        <div class="card-footer border-0 pt-0">
                                            <div class="acciones-footer">

                                                <% if (p.getEstadoControl() == 0) { %>

                                                    <div class="d-grid gap-2">

                                                        <button type="button"
                                                                class="btn btn-outline-info"
                                                                data-bs-toggle="collapse"
                                                                data-bs-target="#<%= collapseId %>">
                                                            Productos
                                                        </button>

                                                        <form method="POST"
                                                              action="<%= request.getContextPath() %>/pedidos-agente"
                                                              class="m-0">
                                                            <input type="hidden" name="accion" value="cerrarPedido">
                                                            <input type="hidden" name="id_control_pedido" value="<%= p.getIdControlPedido() %>">
                                                            <input type="hidden" name="id_pedido_gestion" value="<%= p.getIdPedidoGestion() %>">
                                                            <input type="hidden" name="fecha" value="<%= fechaSeleccionada %>">
                                                            <input type="hidden" name="staffIDFiltro" value="<%= staffIDFiltro %>">

                                                            <button type="button"
                                                                    class="btn btn-success w-100"
                                                                    onclick="confirmarCerrarPedido(this)">
                                                                Cerrar pedido
                                                            </button>
                                                        </form>

                                                        <form method="POST"
                                                              action="<%= request.getContextPath() %>/pedidos-agente"
                                                              class="m-0">
                                                            <input type="hidden" name="accion" value="cancelarPedido">
                                                            <input type="hidden" name="id_control_pedido" value="<%= p.getIdControlPedido() %>">
                                                            <input type="hidden" name="id_pedido_gestion" value="<%= p.getIdPedidoGestion() %>">
                                                            <input type="hidden" name="observacion" class="observacionCancelacion">
                                                            <input type="hidden" name="fecha" value="<%= fechaSeleccionada %>">
                                                            <input type="hidden" name="staffIDFiltro" value="<%= staffIDFiltro %>">

                                                            <button type="button"
                                                                    class="btn btn-outline-danger w-100"
                                                                    onclick="confirmarCancelarPedido(this)">
                                                                Cancelar pedido
                                                            </button>
                                                        </form>

                                                    </div>

                                                <% } else { %>

                                                    <div class="alert alert-light border text-center mb-0">
                                                        <small class="text-muted">
                                                            Pedido <%= p.getEstadoControlDescripcion() != null ? p.getEstadoControlDescripcion().toLowerCase() : "" %>.
                                                            No requiere acción.
                                                        </small>
                                                    </div>

                                                <% } %>

                                            </div>
                                        </div>
                                    <% } %>

                                </div>
                            </div>

                            <% if (p.isTieneSolicitudTarjetaPlus()) {
                                modelos.SolicitudTarjetaPlus solicitud = p.getSolicitudTarjetaPlus();

                                String stOrderCode = solicitud.getOrderCode() != null && !solicitud.getOrderCode().trim().isEmpty() ? solicitud.getOrderCode() : null;
                                String stCardSku = solicitud.getCardSku() != null && !solicitud.getCardSku().trim().isEmpty() ? solicitud.getCardSku() : null;
                                String stTipo = solicitud.getTipoTarjeta() != null && !solicitud.getTipoTarjeta().trim().isEmpty() ? solicitud.getTipoTarjeta() : null;
                                String stNombre = solicitud.getFullName() != null && !solicitud.getFullName().trim().isEmpty() ? solicitud.getFullName() : null;
                                String stIdentidad = solicitud.getIdentityDocument() != null && !solicitud.getIdentityDocument().trim().isEmpty() ? solicitud.getIdentityDocument() : null;
                                String stCorreo = solicitud.getEmail() != null && !solicitud.getEmail().trim().isEmpty() ? solicitud.getEmail() : null;
                                String stTelefono = solicitud.getPhone() != null && !solicitud.getPhone().trim().isEmpty() ? solicitud.getPhone() : null;
                                String stFechaNac = solicitud.getBirthdate() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy").format(solicitud.getBirthdate()) : null;
                                String stDepto = solicitud.getLocationDepartment() != null && !solicitud.getLocationDepartment().trim().isEmpty() ? solicitud.getLocationDepartment() : null;
                                String stCiudad = solicitud.getLocationCity() != null && !solicitud.getLocationCity().trim().isEmpty() ? solicitud.getLocationCity() : null;
                                String stDireccion = solicitud.getLocationAddress() != null && !solicitud.getLocationAddress().trim().isEmpty() ? solicitud.getLocationAddress() : null;
                            %>
                                <div class="modal fade" id="solicitud_<%= collapseId %>" tabindex="-1" aria-hidden="true">
                                    <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable">
                                        <div class="modal-content">
                                            <div class="modal-header modal-header-solicitud">
                                                <h6 class="modal-title">
                                                    <i class="bi bi-credit-card-2-front-fill me-2"></i>Solicitud Tarjeta Plus
                                                </h6>
                                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                                            </div>

                                            <div class="modal-body solicitud-modal-body">

                                                <div class="solicitud-section">
                                                    <div class="solicitud-section-title">
                                                        <i class="bi bi-file-earmark-text"></i> Datos de la solicitud
                                                    </div>
                                                    <div class="solicitud-fields-grid">
                                                        <div class="solicitud-field">
                                                            <div class="label">Código de solicitud</div>
                                                            <div class="value <%= stOrderCode == null ? "empty" : "" %>"><%= stOrderCode != null ? stOrderCode : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field">
                                                            <div class="label">SKU de tarjeta</div>
                                                            <div class="value <%= stCardSku == null ? "empty" : "" %>"><%= stCardSku != null ? stCardSku : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field full">
                                                            <div class="label">Tipo de trámite</div>
                                                            <div class="value <%= stTipo == null ? "empty" : "" %>"><%= stTipo != null ? stTipo : "Sin datos" %></div>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="solicitud-section">
                                                    <div class="solicitud-section-title">
                                                        <i class="bi bi-person-badge"></i> Datos del solicitante
                                                    </div>
                                                    <div class="solicitud-fields-grid">
                                                        <div class="solicitud-field full">
                                                            <div class="label">Nombre completo</div>
                                                            <div class="value <%= stNombre == null ? "empty" : "" %>"><%= stNombre != null ? stNombre : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field">
                                                            <div class="label">Identificación</div>
                                                            <div class="value <%= stIdentidad == null ? "empty" : "" %>"><%= stIdentidad != null ? stIdentidad : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field">
                                                            <div class="label">Fecha de nacimiento</div>
                                                            <div class="value <%= stFechaNac == null ? "empty" : "" %>"><%= stFechaNac != null ? stFechaNac : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field">
                                                            <div class="label">Correo</div>
                                                            <div class="value <%= stCorreo == null ? "empty" : "" %>"><%= stCorreo != null ? stCorreo : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field">
                                                            <div class="label">Teléfono</div>
                                                            <div class="value <%= stTelefono == null ? "empty" : "" %>"><%= stTelefono != null ? stTelefono : "Sin datos" %></div>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="solicitud-section">
                                                    <div class="solicitud-section-title">
                                                        <i class="bi bi-geo-alt"></i> Ubicación
                                                    </div>
                                                    <div class="solicitud-fields-grid">
                                                        <div class="solicitud-field">
                                                            <div class="label">Departamento</div>
                                                            <div class="value <%= stDepto == null ? "empty" : "" %>"><%= stDepto != null ? stDepto : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field">
                                                            <div class="label">Ciudad</div>
                                                            <div class="value <%= stCiudad == null ? "empty" : "" %>"><%= stCiudad != null ? stCiudad : "Sin datos" %></div>
                                                        </div>
                                                        <div class="solicitud-field full">
                                                            <div class="label">Dirección</div>
                                                            <div class="value <%= stDireccion == null ? "empty" : "" %>"><%= stDireccion != null ? stDireccion : "Sin datos" %></div>
                                                        </div>
                                                    </div>
                                                </div>

                                            </div>

                                            <div class="modal-footer modal-footer-solicitud">
                                                <a href="http://192.168.50.90:8080/FacturaExtranjero/cliente-hq"
                                                   target="_blank"
                                                   rel="noopener"
                                                   class="btn btn-inscribir w-100">
                                                    <i class="bi bi-box-arrow-up-right"></i> Inscribir
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            <% } %>

                            <%
                                }
                            %>

                        </div>

                        <div class="empty-state mt-3 d-none" id="emptyEstadoActual">
                            <h5 class="mb-2" id="emptyTituloEstado">No hay pedidos</h5>
                            <p class="mb-0" id="emptyTextoEstado">
                                No hay pedidos para el estado seleccionado.
                            </p>
                        </div>

                    </div>
                </div>

            <% } %>

        </div>

        <%
            String icon = (String) session.getAttribute("swal_icon");
            String title = (String) session.getAttribute("swal_title");
            String text = (String) session.getAttribute("swal_text");

            session.removeAttribute("swal_icon");
            session.removeAttribute("swal_title");
            session.removeAttribute("swal_text");

            if (icon != null && title != null && text != null) {
                icon = icon.replace("\\", "\\\\").replace("\"", "\\\"");
                title = title.replace("\\", "\\\\").replace("\"", "\\\"");
                text = text.replace("\\", "\\\\").replace("\"", "\\\"")
                        .replace("\n", "\\n").replace("\r", "");
        %>
                <script>
                    Swal.fire({
                        icon: "<%= icon %>",
                        title: "<%= title %>",
                        text: "<%= text %>",
                        confirmButtonColor: "<%= usarTemaVerde ? "#00CF78" : "#00B4E7" %>",
                        confirmButtonText: "Aceptar"
                    });
                </script>
        <%
            }
        %>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

        <script>
            const contextPath = "<%= request.getContextPath() %>";
            const pollingPedidosActivo = <%= mostrarAccionesPedido ? "true" : "false" %>;
            const usarTemaVerde = <%= usarTemaVerde ? "true" : "false" %>;
            const colorPrincipal = usarTemaVerde ? "#00CF78" : "#00B4E7";

            let ultimoIdControlPedido = 0;
            let verificandoNuevoPedido = false;
            let modoAsignacionActual = "ASIGNADOS";

            function mostrarLoader() {
                document.body.classList.remove("loaded");
                const loader = document.getElementById("loader-overlay");
                if (loader) {
                    loader.style.display = "flex";
                }
            }

            function ocultarLoader() {
                document.body.classList.add("loaded");
                const loader = document.getElementById("loader-overlay");
                if (loader) {
                    loader.style.display = "none";
                }
            }

            document.body.classList.remove("loaded");

            window.addEventListener("load", function () {
                ocultarLoader();
            });

            document.addEventListener("DOMContentLoaded", function () {
                document.querySelectorAll("form").forEach(f => {
                    f.addEventListener("submit", function () {
                        if (!f.classList.contains("form-sin-loader")) {
                            mostrarLoader();
                        }
                    });
                });

                actualizarTextoAsignacion();
                inicializarUltimoIdControlPedido();

                if (pollingPedidosActivo) {
                    verificarNuevoPedidoAsignado();
                    setInterval(verificarNuevoPedidoAsignado, 10000);
                }

                const btnAbiertos = document.querySelector('.filtro-estado[data-estado="0"]');
                const estadoBoxPedidos = document.getElementById("estadoBoxPedidos");

                if (btnAbiertos && estadoBoxPedidos) {
                    filtrarPorEstado(0, btnAbiertos);
                }
            });

            function filtrarPorEstado(estado, btn) {
                const items = document.querySelectorAll(".pedido-item");
                const estadoBox = document.getElementById("estadoBoxPedidos");
                const emptyBox = document.getElementById("emptyEstadoActual");
                const emptyTitulo = document.getElementById("emptyTituloEstado");
                const emptyTexto = document.getElementById("emptyTextoEstado");

                let contador = 0;

                items.forEach(item => {
                    const estadoItem = parseInt(item.getAttribute("data-estado"));
                    const staffID = item.getAttribute("data-staffid");

                    let cumpleEstado = estadoItem === estado;
                    let cumpleAsignacion = true;

                    if (estadoItem === 0) {
                        if (modoAsignacionActual === "ASIGNADOS") {
                            cumpleAsignacion = staffID !== null && staffID.trim() !== "";
                        }
                        if (modoAsignacionActual === "SIN_ASIGNAR") {
                            cumpleAsignacion = staffID === null || staffID.trim() === "";
                        }
                    }

                    if (cumpleEstado && cumpleAsignacion) {
                        item.classList.remove("oculto-estado");
                        item.classList.remove("d-none");
                        contador++;
                    } else {
                        item.classList.add("oculto-estado");
                    }
                });

                document.querySelectorAll(".filtro-estado").forEach(b => {
                    b.classList.remove("active", "btn-info", "btn-success", "btn-danger", "text-white");
                    b.classList.remove("btn-outline-info", "btn-outline-success", "btn-outline-danger");

                    const estadoBtn = parseInt(b.getAttribute("data-estado"));
                    if (estadoBtn === 0) {
                        b.classList.add("btn-outline-info");
                    } else if (estadoBtn === 1) {
                        b.classList.add("btn-outline-success");
                    } else if (estadoBtn === 2) {
                        b.classList.add("btn-outline-danger");
                    }
                });

                btn.classList.add("active", "text-white");

                if (estadoBox) {
                    estadoBox.classList.remove("estado-abierto", "estado-cerrado", "estado-cancelado");
                    if (estado === 0) {
                        estadoBox.classList.add("estado-abierto");
                    }
                    if (estado === 1) {
                        estadoBox.classList.add("estado-cerrado");
                    }
                    if (estado === 2) {
                        estadoBox.classList.add("estado-cancelado");
                    }
                }

                if (estado === 0) {
                    document.getElementById("tituloEstadoPedidos").innerText = "Pedidos abiertos";
                    document.getElementById("descripcionEstadoPedidos").innerText = descripcionAsignacion("Pedidos pendientes de facturación, gestión o cierre.");
                    document.getElementById("badgeTituloEstado").innerText = contador + " abiertos";

                    if (emptyTitulo) {
                        emptyTitulo.innerText = "No hay pedidos abiertos";
                    }

                    if (emptyTexto) {
                        emptyTexto.innerText = textoEmptyAsignacion("No tienes pedidos abiertos para la fecha seleccionada.");
                    }
                }

                if (estado === 1) {
                    document.getElementById("tituloEstadoPedidos").innerText = "Pedidos cerrados";
                    document.getElementById("descripcionEstadoPedidos").innerText = descripcionAsignacion("Pedidos ya gestionados y cerrados.");
                    document.getElementById("badgeTituloEstado").innerText = contador + " cerrados";

                    if (emptyTitulo) {
                        emptyTitulo.innerText = "No hay pedidos cerrados";
                    }

                    if (emptyTexto) {
                        emptyTexto.innerText = textoEmptyAsignacion("No tienes pedidos cerrados para la fecha seleccionada.");
                    }
                }

                if (estado === 2) {
                    document.getElementById("tituloEstadoPedidos").innerText = "Pedidos cancelados";
                    document.getElementById("descripcionEstadoPedidos").innerText = descripcionAsignacion("Pedidos cancelados durante la gestión.");
                    document.getElementById("badgeTituloEstado").innerText = contador + " cancelados";

                    if (emptyTitulo) {
                        emptyTitulo.innerText = "No hay pedidos cancelados";
                    }

                    if (emptyTexto) {
                        emptyTexto.innerText = textoEmptyAsignacion("No tienes pedidos cancelados para la fecha seleccionada.");
                    }
                }

                document.getElementById("contadorEstadoPedidos").innerText = contador;

                if (emptyBox) {
                    if (contador === 0) {
                        emptyBox.classList.remove("d-none");
                    } else {
                        emptyBox.classList.add("d-none");
                    }
                }

                actualizarTextoAsignacion();
            }

            function toggleAsignacion() {
                if (modoAsignacionActual === "ASIGNADOS") {
                    modoAsignacionActual = "SIN_ASIGNAR";
                } else {
                    modoAsignacionActual = "ASIGNADOS";
                }

                const btnEstadoActivo = document.querySelector(".filtro-estado.active");

                if (btnEstadoActivo) {
                    const estado = parseInt(btnEstadoActivo.getAttribute("data-estado"));
                    filtrarPorEstado(estado, btnEstadoActivo);
                }

                actualizarTextoAsignacion();
            }

            function actualizarTextoAsignacion() {
                const btnToggle = document.getElementById("btnToggleAsignacion");
                const texto = document.getElementById("textoFiltroAsignacion");

                if (modoAsignacionActual === "ASIGNADOS") {
                    if (btnToggle) {
                        btnToggle.innerText = "Ver sin asignar";
                        btnToggle.classList.remove("btn-outline-info");
                        btnToggle.classList.add("btn-outline-secondary");
                    }

                    if (texto) {
                        texto.innerText = "Mostrando pedidos asignados";
                    }
                } else {
                    if (btnToggle) {
                        btnToggle.innerText = "Ver asignados";
                        btnToggle.classList.remove("btn-outline-secondary");
                        btnToggle.classList.add("btn-outline-info");
                    }

                    if (texto) {
                        texto.innerText = "Mostrando pedidos sin asignar";
                    }
                }
            }

            function descripcionAsignacion(textoBase) {
                if (modoAsignacionActual === "SIN_ASIGNAR") {
                    return textoBase + " Vista actual: pedidos sin asignar.";
                }

                return textoBase + " Vista actual: pedidos asignados.";
            }

            function textoEmptyAsignacion(textoBase) {
                if (modoAsignacionActual === "SIN_ASIGNAR") {
                    return "No hay pedidos sin asignar para este estado y fecha.";
                }

                return textoBase;
            }

            function confirmarCerrarPedido(btn) {
                const form = btn.closest("form");

                Swal.fire({
                    title: "¿Cerrar pedido?",
                    text: "El pedido será marcado como cerrado.",
                    icon: "question",
                    showCancelButton: true,
                    confirmButtonText: "Sí, cerrar",
                    cancelButtonText: "Cancelar",
                    confirmButtonColor: "#198754",
                    cancelButtonColor: "#6c757d"
                }).then((result) => {
                    if (result.isConfirmed) {
                        mostrarLoader();
                        form.submit();
                    }
                });
            }

            function confirmarCancelarPedido(btn) {
                const form = btn.closest("form");
                const inputObservacion = form.querySelector(".observacionCancelacion");

                Swal.fire({
                    title: "¿Cancelar pedido?",
                    text: "Esta acción marcará el pedido como cancelado.",
                    icon: "warning",
                    input: "textarea",
                    inputLabel: "Motivo de cancelación",
                    inputPlaceholder: "Ejemplo: Cliente no contestó, producto no disponible...",
                    inputAttributes: {
                        maxlength: 500
                    },
                    showCancelButton: true,
                    confirmButtonText: "Sí, cancelar",
                    cancelButtonText: "No",
                    confirmButtonColor: "#dc3545",
                    cancelButtonColor: "#6c757d",
                    preConfirm: (value) => {
                        if (!value || value.trim() === "") {
                            Swal.showValidationMessage("Debes ingresar un motivo de cancelación.");
                            return false;
                        }
                        return value;
                    }
                }).then((result) => {
                    if (result.isConfirmed) {
                        inputObservacion.value = result.value || "";
                        mostrarLoader();
                        form.submit();
                    }
                });
            }

            function confirmarPausarAgente(e, form) {
                e.preventDefault();

                Swal.fire({
                    title: "¿Pausar Shift?",
                    text: "El agente quedará pausado y no recibirá nuevos pedidos.",
                    icon: "warning",
                    showCancelButton: true,
                    confirmButtonText: "Sí, pausar",
                    cancelButtonText: "Cancelar",
                    confirmButtonColor: "#ffc107",
                    cancelButtonColor: "#6c757d"
                }).then((result) => {
                    if (result.isConfirmed) {
                        mostrarLoader();
                        form.submit();
                    }
                });

                return false;
            }

            function confirmarCambioEstadoAgente(e, form) {
                e.preventDefault();

                const estado = form.querySelector('input[name="estado"]').value;
                const inputPassword = form.querySelector('input[name="password"]');

                if (estado === "0") {
                    Swal.fire({
                        title: "Confirmar desconexión",
                        text: "Ingrese su contraseña para desconectarse.",
                        icon: "warning",
                        input: "password",
                        inputPlaceholder: "Contraseña",
                        inputAttributes: {
                            autocapitalize: "off",
                            autocomplete: "current-password"
                        },
                        showCancelButton: true,
                        confirmButtonText: "Desconectarme",
                        cancelButtonText: "Cancelar",
                        confirmButtonColor: "#212529",
                        cancelButtonColor: "#6c757d",
                        preConfirm: (value) => {
                            if (!value || value.trim() === "") {
                                Swal.showValidationMessage("Debe ingresar su contraseña.");
                                return false;
                            }

                            return value;
                        }
                    }).then((result) => {
                        if (result.isConfirmed) {
                            if (inputPassword) {
                                inputPassword.value = result.value;
                            }

                            mostrarLoader();
                            form.submit();
                        }
                    });

                    return false;
                }

                let texto = "El agente quedará disponible para recibir nuevos pedidos.";

                if (estado === "3") {
                    texto = "El agente quedará pausado y no recibirá nuevos pedidos.";
                }

                Swal.fire({
                    title: "¿Cambiar estado?",
                    text: texto,
                    icon: "question",
                    showCancelButton: true,
                    confirmButtonText: "Sí, cambiar",
                    cancelButtonText: "Cancelar",
                    confirmButtonColor: colorPrincipal,
                    cancelButtonColor: "#6c757d"
                }).then((result) => {
                    if (result.isConfirmed) {
                        if (inputPassword) {
                            inputPassword.value = "";
                        }

                        mostrarLoader();
                        form.submit();
                    }
                });

                return false;
            }

            function inicializarUltimoIdControlPedido() {
                ultimoIdControlPedido = 0;

                document.querySelectorAll(".pedido-item").forEach(item => {
                    const id = parseInt(item.getAttribute("data-id-control"));

                    if (!isNaN(id) && id > ultimoIdControlPedido) {
                        ultimoIdControlPedido = id;
                    }
                });
            }

            function verificarNuevoPedidoAsignado() {
                if (!pollingPedidosActivo) {
                    return;
                }

                if (verificandoNuevoPedido) {
                    return;
                }

                verificandoNuevoPedido = true;

                const fechaAlerta = "<%= fechaSeleccionada != null ? fechaSeleccionada : "" %>";

                let urlAlerta = contextPath + "/pedidos-alerta?ultimoIdControlPedido=" + ultimoIdControlPedido;

                if (fechaAlerta && fechaAlerta.trim() !== "") {
                    urlAlerta += "&fecha=" + encodeURIComponent(fechaAlerta);
                }

                fetch(urlAlerta, {
                    method: "GET",
                    cache: "no-store"
                })
                    .then(response => {
                        if (!response.ok) {
                            throw new Error("Error HTTP " + response.status);
                        }
                        return response.json();
                    })
                    .then(data => {
                        if (!data || !data.nuevo) {
                            return;
                        }

                        const nuevoId = parseInt(data.idControlPedido);

                        if (!isNaN(nuevoId) && nuevoId > ultimoIdControlPedido) {
                            ultimoIdControlPedido = nuevoId;
                        }

                        reproducirSonidoNuevoPedido();

                        Swal.fire({
                            icon: "info",
                            title: "Nuevo pedido asignado",
                            html:
                                "<div class='text-start'>" +
                                    "<div><strong>Pedido:</strong> " + escaparHtml(data.orderCode || data.orderIdWeb || "") + "</div>" +
                                    "<div><strong>Cliente:</strong> " + escaparHtml(data.customerName || "") + "</div>" +
                                    "<div><strong>Teléfono:</strong> " + escaparHtml(data.customerPhone || "") + "</div>" +
                                    "<div><strong>Total:</strong> L. " + escaparHtml(data.total || "0.00") + "</div>" +
                                "</div>",
                            confirmButtonColor: colorPrincipal,
                            confirmButtonText: "Ver pedido",
                            allowOutsideClick: false
                        }).then(() => {
                            mostrarLoader();
                            window.location.reload();
                        });
                    })
                    .catch(error => {
                        console.error("Error verificando nuevo pedido:", error);
                    })
                    .finally(() => {
                        verificandoNuevoPedido = false;
                    });
            }

            function reproducirSonidoNuevoPedido() {
                try {
                    const audioContext = new (window.AudioContext || window.webkitAudioContext)();

                    const volumen = 0.65;
                    const duracionTono = 0.45;
                    const pausa = 0.18;

                    const tonos = [
                        880, 1046, 880,
                        1046, 1318, 1046,
                        880, 1046, 1318
                    ];

                    tonos.forEach((frecuencia, index) => {
                        const inicio = audioContext.currentTime + index * (duracionTono + pausa);
                        const fin = inicio + duracionTono;

                        const oscillator = audioContext.createOscillator();
                        const gainNode = audioContext.createGain();

                        oscillator.type = "square";
                        oscillator.frequency.setValueAtTime(frecuencia, inicio);

                        gainNode.gain.setValueAtTime(0.001, inicio);
                        gainNode.gain.linearRampToValueAtTime(volumen, inicio + 0.03);
                        gainNode.gain.exponentialRampToValueAtTime(0.001, fin);

                        oscillator.connect(gainNode);
                        gainNode.connect(audioContext.destination);

                        oscillator.start(inicio);
                        oscillator.stop(fin);
                    });

                } catch (e) {
                    console.warn("No se pudo reproducir sonido:", e);
                }
            }

            function confirmarAsignarPendientes(e, form) {
                e.preventDefault();

                Swal.fire({
                    title: "Asignar pedidos pendientes",
                    text: "Ingrese cuántos pedidos pendientes desea asignar. Si lo deja vacío, se asignarán todos los posibles.",
                    icon: "question",
                    input: "number",
                    inputPlaceholder: "Ejemplo: 5",
                    inputAttributes: {
                        min: 1,
                        step: 1
                    },
                    showCancelButton: true,
                    confirmButtonText: "Asignar",
                    cancelButtonText: "Cancelar",
                    confirmButtonColor: colorPrincipal,
                    cancelButtonColor: "#6c757d",
                    preConfirm: (value) => {
                        if (value && parseInt(value) <= 0) {
                            Swal.showValidationMessage("La cantidad debe ser mayor a 0.");
                            return false;
                        }

                        if (value && !Number.isInteger(Number(value))) {
                            Swal.showValidationMessage("La cantidad debe ser un número entero.");
                            return false;
                        }

                        return value;
                    }
                }).then((result) => {
                    if (result.isConfirmed) {
                        const cantidadInput = form.querySelector('input[name="cantidad"]');

                        if (cantidadInput) {
                            cantidadInput.value = result.value ? result.value : "";
                        }

                        mostrarLoader();
                        form.submit();
                    }
                });

                return false;
            }

            function escaparHtml(value) {
                if (value === null || value === undefined) {
                    return "";
                }

                return String(value)
                    .replaceAll("&", "&amp;")
                    .replaceAll("<", "&lt;")
                    .replaceAll(">", "&gt;")
                    .replaceAll('"', "&quot;")
                    .replaceAll("'", "&#039;");
            }
        </script>

    </body>
</html>