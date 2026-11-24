package modelos;

public class MotivoCancelacion {

    private int idMotivo;
    private String descripcion;
    private String tipoEntrega;
    private int orden;

    public MotivoCancelacion() {
    }

    public int getIdMotivo() {
        return idMotivo;
    }

    public void setIdMotivo(int idMotivo) {
        this.idMotivo = idMotivo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getTipoEntrega() {
        return tipoEntrega;
    }

    public void setTipoEntrega(String tipoEntrega) {
        this.tipoEntrega = tipoEntrega;
    }

    public int getOrden() {
        return orden;
    }

    public void setOrden(int orden) {
        this.orden = orden;
    }

    public boolean isDelivery() {
        return "delivery".equalsIgnoreCase(tipoEntrega);
    }

    public boolean isPickup() {
        return "pickup".equalsIgnoreCase(tipoEntrega);
    }
}
