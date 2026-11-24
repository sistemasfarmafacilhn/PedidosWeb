<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="modelos.Agente" %>
<%@ page import="modelos.ReportePedidoDelivery" %>

<%
    Agente agenteSesion = (Agente) session.getAttribute("usuarioObj");

    if (agenteSesion == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    List<ReportePedidoDelivery> pedidos = (List<ReportePedidoDelivery>) request.getAttribute("pedidos");
    List<Agente> agentesDelivery = (List<Agente>) request.getAttribute("agentesDelivery");

    String fechaInicio = (String) request.getAttribute("fechaInicio");
    String fechaFin = (String) request.getAttribute("fechaFin");
    String staffIDFiltro = (String) request.getAttribute("staffIDFiltro");
    Integer totalPedidos = (Integer) request.getAttribute("totalPedidos");

    if (fechaInicio == null) fechaInicio = "";
    if (fechaFin == null) fechaFin = "";
    if (staffIDFiltro == null) staffIDFiltro = "";
    if (totalPedidos == null) totalPedidos = 0;

    boolean hayFiltroFecha = !fechaInicio.trim().isEmpty() || !fechaFin.trim().isEmpty();

    java.text.SimpleDateFormat sdfFechaHora = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm");
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Pedidos Delivery</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">

    <style>
        body {
            background: #F2FBFE;
        }

        .page-wrapper {
            padding: 1.5rem;
        }

        .page-header-card {
            background: #ffffff;
            border-radius: 18px;
            border: 1px solid rgba(0,180,231,.15);
            box-shadow: 0 0.125rem 0.45rem rgba(0,180,231,.10);
            padding: 1.25rem;
            margin-bottom: 1.5rem;
        }

        .page-title {
            color: #00B4E7;
            font-weight: 800;
            margin-bottom: .15rem;
        }

        .page-subtitle {
            color: #0092BA;
            font-size: .95rem;
        }

        .content-card {
            background: #ffffff;
            border-radius: 18px;
            border: 1px solid rgba(0,180,231,.15);
            box-shadow: 0 0.125rem 0.45rem rgba(0,180,231,.10);
            overflow: hidden;
        }

        .btn-info-soft {
            background-color: #00B4E7;
            border-color: #00B4E7;
            color: #ffffff;
            font-weight: 600;
            border-radius: .65rem;
        }

        .btn-info-soft:hover {
            background-color: #0092BA;
            border-color: #0092BA;
            color: #ffffff;
        }

        .btn-exportar {
            background-color: #00CF78;
            border-color: #00CF78;
            color: #ffffff;
            font-weight: 600;
            border-radius: .65rem;
        }

        .btn-exportar:hover {
            background-color: #00A863;
            border-color: #00A863;
            color: #ffffff;
        }

        #tablaReporte thead th {
            background: #E8F8FD;
            color: #00B4E7;
            font-weight: 700;
            border-bottom: 1px solid rgba(0,180,231,.15);
        }
    </style>
</head>

<body>

<jsp:include page="/vistas/navbar.jsp" />

<div class="page-wrapper">

    <div class="page-header-card">
        <h3 class="page-title">Reporte de Pedidos Delivery</h3>
        <div class="page-subtitle">
            Solo pedidos tipo delivery (agentes de call center). Si no eliges un rango de fecha, se muestran los de hoy.
        </div>
    </div>

    <div class="content-card mb-4">
        <div class="p-3 p-md-4">
            <form method="GET" action="<%= request.getContextPath() %>/reporte-pedidos-delivery" class="row g-3 align-items-end">

                <div class="col-12 col-md-3">
                    <label class="form-label">Fecha inicio</label>
                    <input type="date" class="form-control" name="fecha_inicio" value="<%= fechaInicio %>">
                </div>

                <div class="col-12 col-md-3">
                    <label class="form-label">Fecha fin</label>
                    <input type="date" class="form-control" name="fecha_fin" value="<%= fechaFin %>">
                </div>

                <div class="col-12 col-md-3">
                    <label class="form-label">Agente (call center)</label>
                    <select class="form-select" name="staffIDFiltro">
                        <option value="">Todos los agentes</option>
                        <% if (agentesDelivery != null) {
                            for (Agente ag : agentesDelivery) {
                                String agStaffID = ag.getStaffID() != null ? ag.getStaffID() : "";
                                boolean seleccionado = !agStaffID.trim().isEmpty() && agStaffID.equals(staffIDFiltro);
                                if (!agStaffID.trim().isEmpty()) {
                        %>
                            <option value="<%= agStaffID %>" <%= seleccionado ? "selected" : "" %>>
                                <%= ag.getNombre() %>
                            </option>
                        <%
                                }
                            }
                        } %>
                    </select>
                </div>

                <div class="col-12 col-md-3 d-flex gap-2">
                    <button type="submit" class="btn btn-info-soft flex-fill">
                        <i class="bi bi-funnel"></i> Filtrar
                    </button>
                    <a href="<%= request.getContextPath() %>/reporte-pedidos-delivery"
                       class="btn btn-outline-secondary">
                        Limpiar
                    </a>
                </div>
            </form>

            <% if (!hayFiltroFecha) { %>
                <div class="form-text mt-2">
                    <i class="bi bi-info-circle"></i> No seleccionaste fecha, mostrando los pedidos de hoy.
                </div>
            <% } %>
        </div>
    </div>

    <div class="content-card">
        <div class="p-3 p-md-4">

            <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                <h6 class="m-0 text-info"><%= totalPedidos %> pedido(s) encontrado(s)</h6>

                <form method="GET" action="<%= request.getContextPath() %>/reporte-pedidos-delivery">
                    <input type="hidden" name="fecha_inicio" value="<%= fechaInicio %>">
                    <input type="hidden" name="fecha_fin" value="<%= fechaFin %>">
                    <input type="hidden" name="staffIDFiltro" value="<%= staffIDFiltro %>">
                    <input type="hidden" name="accion" value="exportar">

                    <button type="submit" class="btn btn-exportar" <%= totalPedidos == 0 ? "disabled" : "" %>>
                        <i class="bi bi-file-earmark-excel"></i> Exportar a Excel
                    </button>
                </form>
            </div>

            <% if (pedidos == null || pedidos.isEmpty()) { %>

                <div class="text-center text-muted py-5">
                    No hay pedidos delivery para el filtro seleccionado.
                </div>

            <% } else { %>

                <div class="table-responsive">
                    <table class="table table-sm table-bordered" id="tablaReporte">
                        <thead>
                            <tr>
                                <th>Fecha de asignación</th>
                                <th>Agente asignado</th>
                                <th>Cliente</th>
                                <th>Teléfono</th>
                                <th># de pedido</th>
                                <th>Total</th>
                                <th>Estado del pedido</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (ReportePedidoDelivery p : pedidos) { %>
                                <tr>
                                    <td><%= p.getFechaAsignacion() != null ? sdfFechaHora.format(p.getFechaAsignacion()) : "" %></td>
                                    <td><%= p.getNombreAgente() != null ? p.getNombreAgente() : "" %></td>
                                    <td><%= p.getCustomerName() != null ? p.getCustomerName() : "" %></td>
                                    <td><%= p.getCustomerPhone() != null ? p.getCustomerPhone() : "" %></td>
                                    <td><%= p.getNumeroPedidoSeguro() %></td>
                                    <td><%= p.getTotalSeguro() %></td>
                                    <td><%= p.getEstadoControlDescripcion() != null ? p.getEstadoControlDescripcion() : "" %></td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

            <% } %>

        </div>
    </div>

</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>
