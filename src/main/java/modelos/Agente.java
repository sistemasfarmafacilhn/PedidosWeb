package modelos;

import java.util.Date;

public class Agente {

    private int idUsuario;
    private String nombre;
    private String codigo;
    private String salt;
    private String hashPassword;
    private Date fechaCreacion;

    // 0 = Desconectado, 1 = Disponible, 3 = Pausado
    private int estado;

    /*
     * Roles:
     * 1 = Administrador
     * 2 = Agente
     * 3 = Agente de farmacia
     * 4 = Vista total
     * 5 = Supervisor
     */
    private int rol;

    private String staffID;
    private Date ultimaFechaActivo;
    private String tiempoActivo;
    private Integer tiempoActivoHoySegundos;
    private String tiempoActivoHoy;

    // 0 = Activo, 1 = Eliminado
    private int deleted;

    public Agente() {
    }

    public Agente(
            int idUsuario,
            String nombre,
            String codigo,
            String salt,
            String hashPassword,
            Date fechaCreacion,
            int estado,
            int rol,
            String staffID,
            Date ultimaFechaActivo,
            String tiempoActivo,
            Integer tiempoActivoHoySegundos,
            String tiempoActivoHoy,
            int deleted
    ) {
        this.idUsuario = idUsuario;
        this.nombre = nombre;
        this.codigo = codigo;
        this.salt = salt;
        this.hashPassword = hashPassword;
        this.fechaCreacion = fechaCreacion;
        this.estado = estado;
        this.rol = rol;
        this.staffID = staffID;
        this.ultimaFechaActivo = ultimaFechaActivo;
        this.tiempoActivo = tiempoActivo;
        this.tiempoActivoHoySegundos = tiempoActivoHoySegundos;
        this.tiempoActivoHoy = tiempoActivoHoy;
        this.deleted = deleted;
    }

    public int getIdUsuario() {
        return idUsuario;
    }

    public void setIdUsuario(int idUsuario) {
        this.idUsuario = idUsuario;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public String getSalt() {
        return salt;
    }

    public void setSalt(String salt) {
        this.salt = salt;
    }

    public String getHashPassword() {
        return hashPassword;
    }

    public void setHashPassword(String hashPassword) {
        this.hashPassword = hashPassword;
    }

    public Date getFechaCreacion() {
        return fechaCreacion;
    }

    public void setFechaCreacion(Date fechaCreacion) {
        this.fechaCreacion = fechaCreacion;
    }

    public int getEstado() {
        return estado;
    }

    public void setEstado(int estado) {
        this.estado = estado;
    }

    public int getRol() {
        return rol;
    }

    public void setRol(int rol) {
        this.rol = rol;
    }

    public String getStaffID() {
        return staffID;
    }

    public void setStaffID(String staffID) {
        this.staffID = staffID;
    }

    public Date getUltimaFechaActivo() {
        return ultimaFechaActivo;
    }

    public void setUltimaFechaActivo(Date ultimaFechaActivo) {
        this.ultimaFechaActivo = ultimaFechaActivo;
    }

    public String getTiempoActivo() {
        return tiempoActivo;
    }

    public void setTiempoActivo(String tiempoActivo) {
        this.tiempoActivo = tiempoActivo;
    }

    public Integer getTiempoActivoHoySegundos() {
        return tiempoActivoHoySegundos;
    }

    public void setTiempoActivoHoySegundos(Integer tiempoActivoHoySegundos) {
        this.tiempoActivoHoySegundos = tiempoActivoHoySegundos;
    }

    public String getTiempoActivoHoy() {
        return tiempoActivoHoy;
    }

    public void setTiempoActivoHoy(String tiempoActivoHoy) {
        this.tiempoActivoHoy = tiempoActivoHoy;
    }

    public int getDeleted() {
        return deleted;
    }

    public void setDeleted(int deleted) {
        this.deleted = deleted;
    }

    // ============================================================
    // Métodos auxiliares
    // ============================================================

    public String getEstadoDescripcion() {
        switch (estado) {
            case 1:
                return "Disponible";
            case 3:
                return "Pausado";
            default:
                return "Desconectado";
        }
    }

    public String getRolDescripcion() {
        switch (rol) {
            case 1:
                return "Administrador";
            case 2:
                return "Agente";
            case 3:
                return "Agente de farmacia";
            case 4:
                return "Vista total";
            case 5:
                return "Supervisor";
            default:
                return "Otro";
        }
    }

    public String getDeletedDescripcion() {
        return deleted == 1 ? "Eliminado" : "Activo";
    }

    public boolean isAdministrador() {
        return rol == 1;
    }

    public boolean isAgente() {
        return rol == 2;
    }

    public boolean isFarmacia() {
        return rol == 3;
    }

    public boolean isAgenteFarmacia() {
        return rol == 3;
    }

    public boolean isVistaTotal() {
        return rol == 4;
    }

    public boolean isSupervisor() {
        return rol == 5;
    }
}