package modelos;

public class AsignacionPendienteResultado {

    private String status;
    private String mensaje;
    private int resultado;
    private int cantidad;
    private String staffIDDestino;
    private Integer idUsuarioAdmin;

    public AsignacionPendienteResultado() {
    }

    public AsignacionPendienteResultado(String status, String mensaje, int resultado) {
        this.status = status;
        this.mensaje = mensaje;
        this.resultado = resultado;
    }

    public AsignacionPendienteResultado(String status, String mensaje, int resultado,
                                        int cantidad, String staffIDDestino, Integer idUsuarioAdmin) {
        this.status = status;
        this.mensaje = mensaje;
        this.resultado = resultado;
        this.cantidad = cantidad;
        this.staffIDDestino = staffIDDestino;
        this.idUsuarioAdmin = idUsuarioAdmin;
    }

    public boolean isSuccess() {
        return "success".equalsIgnoreCase(status) || resultado > 0;
    }

    public boolean isError() {
        return "error".equalsIgnoreCase(status) || resultado < 0;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public int getResultado() {
        return resultado;
    }

    public void setResultado(int resultado) {
        this.resultado = resultado;
    }

    public int getCantidad() {
        return cantidad;
    }

    public void setCantidad(int cantidad) {
        this.cantidad = cantidad;
    }

    public String getStaffIDDestino() {
        return staffIDDestino;
    }

    public void setStaffIDDestino(String staffIDDestino) {
        this.staffIDDestino = staffIDDestino;
    }

    public Integer getIdUsuarioAdmin() {
        return idUsuarioAdmin;
    }

    public void setIdUsuarioAdmin(Integer idUsuarioAdmin) {
        this.idUsuarioAdmin = idUsuarioAdmin;
    }
}