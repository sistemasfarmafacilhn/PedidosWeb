package modelos;

import java.util.Date;

public class Agente {

    private int idUsuario;
    private String nombre;
    private String codigo;
    private String salt;
    private String hashPassword;
    private Date fechaCreacion;
    private int estado; // 0 = Desconectado, 1 = Disponible
    private int rol;
    private String staffID;
    private Date ultimaFechaActivo;
    private String tiempoActivo;
    private Integer tiempoActivoHoySegundos;
    private String tiempoActivoHoy;
    private int deleted; // 0 = Activo, 1 = Eliminado

    public Agente() {
    }

    public Agente(int idUsuario, String nombre, String codigo, String salt, String hashPassword,
                  Date fechaCreacion, int estado, int rol, String staffID, Date ultimaFechaActivo,
                  String tiempoActivo, Integer tiempoActivoHoySegundos, String tiempoActivoHoy,
                  int deleted) {
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

   public String getEstadoDescripcion() {
    if (estado == 1) {
        return "Disponible";
    }

    if (estado == 3) {
        return "Pausado";
    }

    return "Desconectado";
}

    public String getRolDescripcion() {
        if (rol == 1) {
            return "Administrador";
        }

        if (rol == 2) {
            return "Agente";
        }

        return "Otro";
    }

    public String getDeletedDescripcion() {
        return deleted == 1 ? "Eliminado" : "Activo";
    }
}