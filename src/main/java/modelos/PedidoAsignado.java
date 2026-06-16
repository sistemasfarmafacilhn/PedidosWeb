package modelos;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class PedidoAsignado {

    private long idControlPedido;
    private String staffID;
    private String nombreAgente;
    private int estadoControl;
    private String estadoControlDescripcion;
    private Timestamp fechaAsignacion;
    private Timestamp fechaCierre;
    private Timestamp fechaCancelacion;
    private String observacion;

    private long idPedidoGestion;
    private long idPedidoWeb;
    private String orderIdWeb;
    private String orderCode;
    private Integer orderNumber;

    private String customerName;
    private String customerPhone;
    private String customerEmail;
    private String customerIdentityDocument;

    private String deliveryType;
    private String recipientName;
    private String deliveryAddress;
    private String deliveryCity;
    private String deliveryDepartment;
    private String deliveryPhone;

    private String branchId;
    private String branchName;
    private String contactName;
    private String contactPhone;

    private BigDecimal pedidoSubtotal;
    private BigDecimal shipping;
    private BigDecimal discount;
    private BigDecimal total;
    private String currency;

    private String paymentMethod;
    private String paymentStatus;

    private boolean hasTransfer;
    private boolean callcenterRequired;
    private String customerNotes;
    private Timestamp createdAtWeb;

    private Timestamp fechaRecepcionLocal;
    private Timestamp fechaFinalizacion;

    private List<PedidoAsignadoDetalle> detalles = new ArrayList<>();

    public PedidoAsignado() {
    }

    public long getIdControlPedido() {
        return idControlPedido;
    }

    public void setIdControlPedido(long idControlPedido) {
        this.idControlPedido = idControlPedido;
    }

    public String getStaffID() {
        return staffID;
    }

    public void setStaffID(String staffID) {
        this.staffID = staffID;
    }

    public String getNombreAgente() {
        return nombreAgente;
    }

    public void setNombreAgente(String nombreAgente) {
        this.nombreAgente = nombreAgente;
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

    public Timestamp getFechaAsignacion() {
        return fechaAsignacion;
    }

    public void setFechaAsignacion(Timestamp fechaAsignacion) {
        this.fechaAsignacion = fechaAsignacion;
    }

    public Timestamp getFechaCierre() {
        return fechaCierre;
    }

    public void setFechaCierre(Timestamp fechaCierre) {
        this.fechaCierre = fechaCierre;
    }

    public Timestamp getFechaCancelacion() {
        return fechaCancelacion;
    }

    public void setFechaCancelacion(Timestamp fechaCancelacion) {
        this.fechaCancelacion = fechaCancelacion;
    }

    public String getObservacion() {
        return observacion;
    }

    public void setObservacion(String observacion) {
        this.observacion = observacion;
    }

    public long getIdPedidoGestion() {
        return idPedidoGestion;
    }

    public void setIdPedidoGestion(long idPedidoGestion) {
        this.idPedidoGestion = idPedidoGestion;
    }

    public long getIdPedidoWeb() {
        return idPedidoWeb;
    }

    public void setIdPedidoWeb(long idPedidoWeb) {
        this.idPedidoWeb = idPedidoWeb;
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

    public Integer getOrderNumber() {
        return orderNumber;
    }

    public void setOrderNumber(Integer orderNumber) {
        this.orderNumber = orderNumber;
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

    public String getCustomerEmail() {
        return customerEmail;
    }

    public void setCustomerEmail(String customerEmail) {
        this.customerEmail = customerEmail;
    }

    public String getCustomerIdentityDocument() {
        return customerIdentityDocument;
    }

    public void setCustomerIdentityDocument(String customerIdentityDocument) {
        this.customerIdentityDocument = customerIdentityDocument;
    }

    public String getDeliveryType() {
        return deliveryType;
    }

    public void setDeliveryType(String deliveryType) {
        this.deliveryType = deliveryType;
    }

    public String getRecipientName() {
        return recipientName;
    }

    public void setRecipientName(String recipientName) {
        this.recipientName = recipientName;
    }

    public String getDeliveryAddress() {
        return deliveryAddress;
    }

    public void setDeliveryAddress(String deliveryAddress) {
        this.deliveryAddress = deliveryAddress;
    }

    public String getDeliveryCity() {
        return deliveryCity;
    }

    public void setDeliveryCity(String deliveryCity) {
        this.deliveryCity = deliveryCity;
    }

    public String getDeliveryDepartment() {
        return deliveryDepartment;
    }

    public void setDeliveryDepartment(String deliveryDepartment) {
        this.deliveryDepartment = deliveryDepartment;
    }

    public String getDeliveryPhone() {
        return deliveryPhone;
    }

    public void setDeliveryPhone(String deliveryPhone) {
        this.deliveryPhone = deliveryPhone;
    }

    public String getBranchId() {
        return branchId;
    }

    public void setBranchId(String branchId) {
        this.branchId = branchId;
    }

    public String getBranchName() {
        return branchName;
    }

    public void setBranchName(String branchName) {
        this.branchName = branchName;
    }

    public String getContactName() {
        return contactName;
    }

    public void setContactName(String contactName) {
        this.contactName = contactName;
    }

    public String getContactPhone() {
        return contactPhone;
    }

    public void setContactPhone(String contactPhone) {
        this.contactPhone = contactPhone;
    }

    public BigDecimal getPedidoSubtotal() {
        return pedidoSubtotal;
    }

    public void setPedidoSubtotal(BigDecimal pedidoSubtotal) {
        this.pedidoSubtotal = pedidoSubtotal;
    }

    public BigDecimal getShipping() {
        return shipping;
    }

    public void setShipping(BigDecimal shipping) {
        this.shipping = shipping;
    }

    public BigDecimal getDiscount() {
        return discount;
    }

    public void setDiscount(BigDecimal discount) {
        this.discount = discount;
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

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }

    public boolean isHasTransfer() {
        return hasTransfer;
    }

    public void setHasTransfer(boolean hasTransfer) {
        this.hasTransfer = hasTransfer;
    }

    public boolean isCallcenterRequired() {
        return callcenterRequired;
    }

    public void setCallcenterRequired(boolean callcenterRequired) {
        this.callcenterRequired = callcenterRequired;
    }

    public String getCustomerNotes() {
        return customerNotes;
    }

    public void setCustomerNotes(String customerNotes) {
        this.customerNotes = customerNotes;
    }

    public Timestamp getCreatedAtWeb() {
        return createdAtWeb;
    }

    public void setCreatedAtWeb(Timestamp createdAtWeb) {
        this.createdAtWeb = createdAtWeb;
    }

    public Timestamp getFechaRecepcionLocal() {
        return fechaRecepcionLocal;
    }

    public void setFechaRecepcionLocal(Timestamp fechaRecepcionLocal) {
        this.fechaRecepcionLocal = fechaRecepcionLocal;
    }

    public Timestamp getFechaFinalizacion() {
        return fechaFinalizacion;
    }

    public void setFechaFinalizacion(Timestamp fechaFinalizacion) {
        this.fechaFinalizacion = fechaFinalizacion;
    }

    public List<PedidoAsignadoDetalle> getDetalles() {
        return detalles;
    }

    public void setDetalles(List<PedidoAsignadoDetalle> detalles) {
        this.detalles = detalles;
    }

    public void addDetalle(PedidoAsignadoDetalle detalle) {
        this.detalles.add(detalle);
    }
}