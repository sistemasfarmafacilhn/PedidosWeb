package controladores;

import dao.AgenteDAO;
import dao.ReportePedidoDeliveryDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import modelos.Agente;
import modelos.ReportePedidoDelivery;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Modulo de reporte/exportacion de pedidos delivery para
 * Administrador (rol=1) y Vista Total (rol=4).
 */
@WebServlet("/reporte-pedidos-delivery")
public class ReportePedidosDeliveryController extends HttpServlet {

    private static final SimpleDateFormat SDF_FECHA = new SimpleDateFormat("yyyy-MM-dd");
    private static final SimpleDateFormat SDF_FECHA_HORA = new SimpleDateFormat("dd/MM/yyyy HH:mm");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("usuarioObj") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Integer rolSesion = obtenerRolSesion(session);

        if (rolSesion == null || (rolSesion != 1 && rolSesion != 4)) {
            request.setAttribute("error", "No tiene permiso para acceder a este módulo.");
            request.getRequestDispatcher("/vistas/menu.jsp").forward(request, response);
            return;
        }

        String fechaInicioStr = request.getParameter("fecha_inicio");
        String fechaFinStr = request.getParameter("fecha_fin");
        String staffIDFiltro = request.getParameter("staffIDFiltro");
        String accion = request.getParameter("accion");

        Date fechaInicio = parsearFecha(fechaInicioStr);
        Date fechaFin = parsearFecha(fechaFinStr);

        ReportePedidoDeliveryDAO dao = new ReportePedidoDeliveryDAO();
        List<ReportePedidoDelivery> pedidos = dao.listarReporte(fechaInicio, fechaFin, staffIDFiltro);

        if ("exportar".equalsIgnoreCase(accion)) {
            exportarExcel(response, pedidos);
            return;
        }

        AgenteDAO agenteDAO = new AgenteDAO();
        List<Agente> agentesDelivery = agenteDAO.listarAgentes(null, null, null, null, 2, 0, null);

        request.setAttribute("pedidos", pedidos);
        request.setAttribute("agentesDelivery", agentesDelivery);
        request.setAttribute("fechaInicio", fechaInicioStr == null ? "" : fechaInicioStr);
        request.setAttribute("fechaFin", fechaFinStr == null ? "" : fechaFinStr);
        request.setAttribute("staffIDFiltro", staffIDFiltro == null ? "" : staffIDFiltro);
        request.setAttribute("totalPedidos", pedidos.size());

        request.getRequestDispatcher("/vistas/reporte_pedidos_delivery.jsp").forward(request, response);
    }

    private void exportarExcel(HttpServletResponse response, List<ReportePedidoDelivery> pedidos)
            throws IOException {

        try (XSSFWorkbook workbook = new XSSFWorkbook()) {

            Sheet sheet = workbook.createSheet("Pedidos Delivery");

            CellStyle estiloEncabezado = crearEstiloEncabezado(workbook);
            CellStyle estiloCelda = crearEstiloCelda(workbook);

            String[] columnas = {
                "Fecha de asignación", "Agente asignado", "Cliente",
                "Teléfono", "# de pedido", "Total", "Estado del pedido"
            };

            Row filaEncabezado = sheet.createRow(0);

            for (int i = 0; i < columnas.length; i++) {
                org.apache.poi.ss.usermodel.Cell celda = filaEncabezado.createCell(i);
                celda.setCellValue(columnas[i]);
                celda.setCellStyle(estiloEncabezado);
            }

            int numeroFila = 1;

            for (ReportePedidoDelivery p : pedidos) {

                Row fila = sheet.createRow(numeroFila++);

                String fechaTexto = p.getFechaAsignacion() != null
                        ? SDF_FECHA_HORA.format(p.getFechaAsignacion())
                        : "";

                escribirCelda(fila, 0, fechaTexto, estiloCelda);
                escribirCelda(fila, 1, p.getNombreAgente(), estiloCelda);
                escribirCelda(fila, 2, p.getCustomerName(), estiloCelda);
                escribirCelda(fila, 3, p.getCustomerPhone(), estiloCelda);
                escribirCelda(fila, 4, p.getNumeroPedidoSeguro(), estiloCelda);
                escribirCelda(fila, 5, p.getTotalSeguro(), estiloCelda);
                escribirCelda(fila, 6, p.getEstadoControlDescripcion(), estiloCelda);
            }

            for (int i = 0; i < columnas.length; i++) {
                sheet.autoSizeColumn(i);
            }

            String nombreArchivo = "pedidos_delivery_" + new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + ".xlsx";

            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader(
                    "Content-Disposition",
                    "attachment; filename=\"" + nombreArchivo + "\"; filename*=UTF-8''"
                            + URLEncoder.encode(nombreArchivo, StandardCharsets.UTF_8.toString())
            );

            try (OutputStream out = response.getOutputStream()) {
                workbook.write(out);
            }
        }
    }

    private void escribirCelda(Row fila, int indice, String valor, CellStyle estilo) {
        org.apache.poi.ss.usermodel.Cell celda = fila.createCell(indice);
        celda.setCellValue(valor != null ? valor : "");
        celda.setCellStyle(estilo);
    }

    private CellStyle crearEstiloEncabezado(XSSFWorkbook workbook) {

        XSSFCellStyle estilo = workbook.createCellStyle();

        XSSFFont fuente = workbook.createFont();
        fuente.setBold(true);
        estilo.setFont(fuente);

        estilo.setBorderTop(BorderStyle.THIN);
        estilo.setBorderBottom(BorderStyle.THIN);
        estilo.setBorderLeft(BorderStyle.THIN);
        estilo.setBorderRight(BorderStyle.THIN);
        estilo.setAlignment(org.apache.poi.ss.usermodel.HorizontalAlignment.CENTER);

        return estilo;
    }

    private CellStyle crearEstiloCelda(XSSFWorkbook workbook) {

        XSSFCellStyle estilo = workbook.createCellStyle();

        estilo.setBorderTop(BorderStyle.THIN);
        estilo.setBorderBottom(BorderStyle.THIN);
        estilo.setBorderLeft(BorderStyle.THIN);
        estilo.setBorderRight(BorderStyle.THIN);

        return estilo;
    }

    private Date parsearFecha(String valor) {

        if (valor == null || valor.trim().isEmpty()) {
            return null;
        }

        try {
            SDF_FECHA.setLenient(false);
            return SDF_FECHA.parse(valor.trim());
        } catch (ParseException ex) {
            return null;
        }
    }

    private Integer obtenerRolSesion(HttpSession session) {

        Object rolObj = session.getAttribute("rol");

        if (rolObj instanceof Integer) {
            return (Integer) rolObj;
        }

        if (rolObj != null) {
            try {
                return Integer.parseInt(rolObj.toString());
            } catch (NumberFormatException ex) {
                return null;
            }
        }

        Object usuarioObj = session.getAttribute("usuarioObj");

        if (usuarioObj instanceof Agente) {
            return ((Agente) usuarioObj).getRol();
        }

        return null;
    }
}
