package modelos;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class ReportePedidoDelivery {

    private Timestamp fechaAsignacion;
    private String nombreAgente;
    private String staffID;
    private String customerName;
    private String customerPhone;
    private String orderCode;
    private String orderIdWeb;
    private BigDecimal total;
    private String currency;
    private int estadoControl;
    private String estadoControlDescripcion;

    public ReportePedidoDelivery() {
    }

    public Timestamp getFechaAsignacion() {
        return fechaAsignacion;
    }

    public void setFechaAsignacion(Timestamp fechaAsignacion) {
        this.fechaAsignacion = fechaAsignacion;
    }

    public String getNombreAgente() {
        return nombreAgente;
    }

    public void setNombreAgente(String nombreAgente) {
        this.nombreAgente = nombreAgente;
    }

    public String getStaffID() {
        return staffID;
    }

    public void setStaffID(String staffID) {
        this.staffID = staffID;
    }

    public String getCustomerName() {
        return customerName;
    }

    public void setCustomerName(String customerName) {
        this.customerName = customerName;
    }

    public String getCustomerPhone() {
        return customerPhone;
    }

    public void setCustomerPhone(String customerPhone) {
        this.customerPhone = customerPhone;
    }

    public String getOrderCode() {
        return orderCode;
    }

    public void setOrderCode(String orderCode) {
        this.orderCode = orderCode;
    }

    public String getOrderIdWeb() {
        return orderIdWeb;
    }

    public void setOrderIdWeb(String orderIdWeb) {
        this.orderIdWeb = orderIdWeb;
    }

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getTotalSeguro() {
        String moneda = currency != null && !currency.trim().isEmpty() ? currency.trim() : "HNL";
        BigDecimal valor = total != null ? total : BigDecimal.ZERO;

        return moneda + " " + valor.toString();
    }

    public int getEstadoControl() {
        return estadoControl;
    }

    public void setEstadoControl(int estadoControl) {
        this.estadoControl = estadoControl;
    }

    public String getEstadoControlDescripcion() {
        return estadoControlDescripcion;
    }

    public void setEstadoControlDescripcion(String estadoControlDescripcion) {
        this.estadoControlDescripcion = estadoControlDescripcion;
    }

    public String getNumeroPedidoSeguro() {
        if (orderCode != null && !orderCode.trim().isEmpty()) {
            return orderCode;
        }

        return orderIdWeb != null ? orderIdWeb : "";
    }
}
