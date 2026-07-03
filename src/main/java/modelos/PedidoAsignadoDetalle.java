package modelos;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class PedidoAsignadoDetalle {

    private long idPedidoGestionDetalle;
    private Long idDetalleWeb;

    private String sku;
    private String nombre;
    private BigDecimal quantity;
    private BigDecimal unitPrice;
    private BigDecimal subtotal;

    private boolean isCanje;
    private String canjePromocion;
    private String descuentoTipo;

    private Timestamp fechaRegistroDetalle;

    public PedidoAsignadoDetalle() {
    }

    public long getIdPedidoGestionDetalle() {
        return idPedidoGestionDetalle;
    }

    public void setIdPedidoGestionDetalle(long idPedidoGestionDetalle) {
        this.idPedidoGestionDetalle = idPedidoGestionDetalle;
    }

    public Long getIdDetalleWeb() {
        return idDetalleWeb;
    }

    public void setIdDetalleWeb(Long idDetalleWeb) {
        this.idDetalleWeb = idDetalleWeb;
    }

    public String getSku() {
        return sku;
    }

    public void setSku(String sku) {
        this.sku = sku;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public BigDecimal getQuantity() {
        return quantity;
    }

    public void setQuantity(BigDecimal quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }

    public BigDecimal getSubtotal() {
        return subtotal;
    }

    public void setSubtotal(BigDecimal subtotal) {
        this.subtotal = subtotal;
    }

    public boolean isCanje() {
        return isCanje;
    }

    public void setCanje(boolean canje) {
        isCanje = canje;
    }

    public String getCanjePromocion() {
        return canjePromocion;
    }

    public void setCanjePromocion(String canjePromocion) {
        this.canjePromocion = canjePromocion;
    }

    public String getDescuentoTipo() {
        return descuentoTipo;
    }

    public void setDescuentoTipo(String descuentoTipo) {
        this.descuentoTipo = descuentoTipo;
    }

    public Timestamp getFechaRegistroDetalle() {
        return fechaRegistroDetalle;
    }

    public void setFechaRegistroDetalle(Timestamp fechaRegistroDetalle) {
        this.fechaRegistroDetalle = fechaRegistroDetalle;
    }
}