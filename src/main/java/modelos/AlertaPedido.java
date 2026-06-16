package modelos;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class AlertaPedido {

    private boolean nuevo;
    private long idControlPedido;
    private long idPedidoGestion;
    private String orderIdWeb;
    private String orderCode;
    private String customerName;
    private String customerPhone;
    private BigDecimal total;
    private Timestamp fechaAsignacion;

    public AlertaPedido() {
    }

    public boolean isNuevo() {
        return nuevo;
    }

    public void setNuevo(boolean nuevo) {
        this.nuevo = nuevo;
    }

    public long getIdControlPedido() {
        return idControlPedido;
    }

    public void setIdControlPedido(long idControlPedido) {
        this.idControlPedido = idControlPedido;
    }

    public long getIdPedidoGestion() {
        return idPedidoGestion;
    }

    public void setIdPedidoGestion(long idPedidoGestion) {
        this.idPedidoGestion = idPedidoGestion;
    }

    public String getOrderIdWeb() {
        return orderIdWeb;
    }

    public void setOrderIdWeb(String orderIdWeb) {
        this.orderIdWeb = orderIdWeb;
    }

    public String getOrderCode() {
        return orderCode;
    }

    public void setOrderCode(String orderCode) {
        this.orderCode = orderCode;
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

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }

    public Timestamp getFechaAsignacion() {
        return fechaAsignacion;
    }

    public void setFechaAsignacion(Timestamp fechaAsignacion) {
        this.fechaAsignacion = fechaAsignacion;
    }
}