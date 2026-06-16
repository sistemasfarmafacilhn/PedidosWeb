package dao;

import configDB.ConexionSQLServer;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import modelos.Agente;
import utilidades.PasswordUtil;

public class AgenteDAO {

    public static class ResultadoOperacion {

        public String status;       // success, error
        public String message;      // mensaje del SP
        public Integer idGenerado;  // id_usuario o null si falla

        public ResultadoOperacion(String status, String message, Integer idGenerado) {
            this.status = status;
            this.message = message;
            this.idGenerado = idGenerado;
        }
    }

    /**
     * ACCIONES DEL SP_AGENTE_MANTENIMIENTO:
     * 1 = Insertar
     * 2 = Editar
     * 3 = Eliminar lógico
     * 4 = Cambiar contraseña
     */
    private static final int ACCION_INSERTAR = 1;
    private static final int ACCION_EDITAR = 2;
    private static final int ACCION_ELIMINAR_LOGICO = 3;
    private static final int ACCION_CAMBIAR_PASSWORD = 4;

    /**
     * Inserta un agente nuevo.
     * Si no viene salt/hash, se genera usando PasswordUtil con el codigo como password inicial.
     */
    public ResultadoOperacion insertarAgente(Agente agente) {

        String sql = "{ CALL dbo.SP_AGENTE_MANTENIMIENTO(?,?,?,?,?,?,?,?,?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            String salt = agente.getSalt();
            String hash = agente.getHashPassword();

            if (salt == null || salt.trim().isEmpty()
                    || hash == null || hash.trim().isEmpty()) {

                PasswordUtil.Result h = PasswordUtil.hashForStorage(agente.getCodigo());
                salt = h.saltB64;
                hash = h.hashB64;
            }

            cs.setInt(1, ACCION_INSERTAR);
            cs.setNull(2, Types.INTEGER); // @id_usuario
            cs.setString(3, agente.getNombre());
            cs.setString(4, agente.getCodigo());
            cs.setString(5, salt);
            cs.setString(6, hash);
            cs.setInt(7, agente.getEstado());
            cs.setInt(8, agente.getRol());
            cs.setString(9, agente.getStaffID());

            cs.registerOutParameter(10, Types.NVARCHAR); // @mensaje
            cs.registerOutParameter(11, Types.INTEGER);  // @resultado

            cs.execute();

            int resultado = cs.getInt(11);
            String mensaje = cs.getString(10);

            if (resultado > 0) {
                return new ResultadoOperacion("success", mensaje, resultado);
            }

            return new ResultadoOperacion("error", mensaje, null);

        } catch (SQLException ex) {
            return new ResultadoOperacion("error", ex.getMessage(), null);
        }
    }

    /**
     * Edita datos generales del agente.
     * No cambia contraseña.
     */
    public ResultadoOperacion editarAgente(Agente agente) {

        String sql = "{ CALL dbo.SP_AGENTE_MANTENIMIENTO(?,?,?,?,?,?,?,?,?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            cs.setInt(1, ACCION_EDITAR);
            cs.setInt(2, agente.getIdUsuario());
            cs.setString(3, agente.getNombre());
            cs.setString(4, agente.getCodigo());

            cs.setNull(5, Types.NVARCHAR); // salt no aplica
            cs.setNull(6, Types.NVARCHAR); // hash_password no aplica

            cs.setInt(7, agente.getEstado());
            cs.setInt(8, agente.getRol());
            cs.setString(9, agente.getStaffID());

            cs.registerOutParameter(10, Types.NVARCHAR); // @mensaje
            cs.registerOutParameter(11, Types.INTEGER);  // @resultado

            cs.execute();

            int resultado = cs.getInt(11);
            String mensaje = cs.getString(10);

            if (resultado > 0) {
                return new ResultadoOperacion("success", mensaje, resultado);
            }

            return new ResultadoOperacion("error", mensaje, null);

        } catch (SQLException ex) {
            return new ResultadoOperacion("error", ex.getMessage(), null);
        }
    }

    /**
     * Eliminado lógico del agente.
     * Pone deleted = 1 y estado = 0 desde el SP.
     */
    public ResultadoOperacion eliminarAgente(int idUsuario) {

        String sql = "{ CALL dbo.SP_AGENTE_MANTENIMIENTO(?,?,?,?,?,?,?,?,?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            cs.setInt(1, ACCION_ELIMINAR_LOGICO);
            cs.setInt(2, idUsuario);

            cs.setNull(3, Types.VARCHAR);   // nombre
            cs.setNull(4, Types.NVARCHAR);  // codigo
            cs.setNull(5, Types.NVARCHAR);  // salt
            cs.setNull(6, Types.NVARCHAR);  // hash_password
            cs.setNull(7, Types.INTEGER);   // estado
            cs.setNull(8, Types.INTEGER);   // rol
            cs.setNull(9, Types.NVARCHAR);  // StaffID

            cs.registerOutParameter(10, Types.NVARCHAR); // @mensaje
            cs.registerOutParameter(11, Types.INTEGER);  // @resultado

            cs.execute();

            int resultado = cs.getInt(11);
            String mensaje = cs.getString(10);

            if (resultado > 0) {
                return new ResultadoOperacion("success", mensaje, resultado);
            }

            return new ResultadoOperacion("error", mensaje, null);

        } catch (SQLException ex) {
            return new ResultadoOperacion("error", ex.getMessage(), null);
        }
    }

    /**
     * Cambia la contraseña del agente.
     * Recibe la contraseña plana, genera salt/hash y llama al SP.
     */
public ResultadoOperacion cambiarPassword(int idUsuario, String passwordActual, String nuevaPassword) {

    if (idUsuario <= 0) {
        return new ResultadoOperacion("error", "ID de agente inválido.", null);
    }

    if (passwordActual == null || passwordActual.trim().isEmpty()) {
        return new ResultadoOperacion("error", "Debe ingresar la contraseña actual.", null);
    }

    if (nuevaPassword == null || nuevaPassword.trim().isEmpty()) {
        return new ResultadoOperacion("error", "Debe ingresar la nueva contraseña.", null);
    }

    String sqlConsulta =
            "SELECT salt, hash_password "
          + "FROM dbo.AGENTE "
          + "WHERE id_usuario = ? "
          + "AND deleted = 0";

    String sqlCambio = "{ CALL dbo.SP_AGENTE_MANTENIMIENTO(?,?,?,?,?,?,?,?,?,?,?) }";

    try (Connection con = new ConexionSQLServer().getConnection()) {

        String saltActual;
        String hashActual;

        try (PreparedStatement ps = con.prepareStatement(sqlConsulta)) {

            ps.setInt(1, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return new ResultadoOperacion("error", "El agente no existe o está eliminado.", null);
                }

                saltActual = rs.getString("salt");
                hashActual = rs.getString("hash_password");
            }
        }

        boolean passwordValida = PasswordUtil.verify(passwordActual, saltActual, hashActual);

        if (!passwordValida) {
            return new ResultadoOperacion("error", "La contraseña actual es incorrecta.", null);
        }

        PasswordUtil.Result nuevoHash = PasswordUtil.hashForStorage(nuevaPassword);

        try (CallableStatement cs = con.prepareCall(sqlCambio)) {

            cs.setInt(1, ACCION_CAMBIAR_PASSWORD);
            cs.setInt(2, idUsuario);

            cs.setNull(3, Types.VARCHAR);   // nombre
            cs.setNull(4, Types.NVARCHAR);  // codigo
            cs.setString(5, nuevoHash.saltB64);
            cs.setString(6, nuevoHash.hashB64);
            cs.setNull(7, Types.INTEGER);   // estado
            cs.setNull(8, Types.INTEGER);   // rol
            cs.setNull(9, Types.NVARCHAR);  // StaffID

            cs.registerOutParameter(10, Types.NVARCHAR); // @mensaje
            cs.registerOutParameter(11, Types.INTEGER);  // @resultado

            cs.execute();

            int resultado = cs.getInt(11);
            String mensaje = cs.getString(10);

            if (resultado > 0) {
                return new ResultadoOperacion("success", mensaje, resultado);
            }

            return new ResultadoOperacion("error", mensaje, null);
        }

    } catch (SQLException ex) {
        return new ResultadoOperacion("error", ex.getMessage(), null);
    }
}

    /**
     * Lista agentes usando SP_AGENTE_LISTAR.
     */
    public List<Agente> listarAgentes() {
        return listarAgentes(null, null, null, null, null, 0, null);
    }

    /**
     * Lista agentes con filtros opcionales.
     *
     * @param idUsuario null para todos
     * @param codigo null para todos
     * @param staffID null para todos
     * @param estado null para todos, 0 desconectado, 1 disponible
     * @param rol null para todos
     * @param deleted 0 activos, 1 eliminados, null todos
     * @param busqueda búsqueda por nombre/codigo/StaffID
     */
    public List<Agente> listarAgentes(
            Integer idUsuario,
            String codigo,
            String staffID,
            Integer estado,
            Integer rol,
            Integer deleted,
            String busqueda
    ) {

        List<Agente> lista = new ArrayList<>();

        String sql = "{ CALL dbo.SP_AGENTE_LISTAR(?,?,?,?,?,?,?) }";

        try (Connection con = new ConexionSQLServer().getConnection();
             CallableStatement cs = con.prepareCall(sql)) {

            if (idUsuario == null) {
                cs.setNull(1, Types.INTEGER);
            } else {
                cs.setInt(1, idUsuario);
            }

            if (codigo == null || codigo.trim().isEmpty()) {
                cs.setNull(2, Types.NVARCHAR);
            } else {
                cs.setString(2, codigo.trim());
            }

            if (staffID == null || staffID.trim().isEmpty()) {
                cs.setNull(3, Types.NVARCHAR);
            } else {
                cs.setString(3, staffID.trim());
            }

            if (estado == null) {
                cs.setNull(4, Types.INTEGER);
            } else {
                cs.setInt(4, estado);
            }

            if (rol == null) {
                cs.setNull(5, Types.INTEGER);
            } else {
                cs.setInt(5, rol);
            }

            if (deleted == null) {
                cs.setNull(6, Types.INTEGER);
            } else {
                cs.setInt(6, deleted);
            }

            if (busqueda == null || busqueda.trim().isEmpty()) {
                cs.setNull(7, Types.NVARCHAR);
            } else {
                cs.setString(7, busqueda.trim());
            }

            try (ResultSet rs = cs.executeQuery()) {
                while (rs.next()) {
                    Agente agente = mapearAgenteListado(rs);
                    lista.add(agente);
                }
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        return lista;
    }

    /**
     * Busca un agente específico por id.
     */
    public Agente obtenerAgentePorId(int idUsuario) {

        List<Agente> lista = listarAgentes(idUsuario, null, null, null, null, null, null);

        if (lista.isEmpty()) {
            return null;
        }

        return lista.get(0);
    }

    /**
     * Valida login por código.
     * Esta consulta va directo a AGENTE porque necesita salt y hash_password,
     * campos que no deben devolverse en SP_AGENTE_LISTAR.
     */
    public Agente validarLoginPorCodigo(String codigo, String plainPassword) {

        if (codigo == null || plainPassword == null) {
            return null;
        }

        String sql =
                "SELECT id_usuario, nombre, codigo, salt, hash_password, fecha_creacion, estado, rol, StaffID, deleted "
              + "FROM dbo.AGENTE "
              + "WHERE codigo = ? "
              + "AND deleted = 0";

        try (Connection con = new ConexionSQLServer().getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, codigo.trim());

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return null;
                }

                String saltB64 = rs.getString("salt");
                String hashB64 = rs.getString("hash_password");

                boolean valido = PasswordUtil.verify(plainPassword, saltB64, hashB64);

                if (!valido) {
                    return null;
                }

                Agente agente = new Agente();
                agente.setIdUsuario(rs.getInt("id_usuario"));
                agente.setNombre(rs.getString("nombre"));
                agente.setCodigo(rs.getString("codigo"));
                agente.setSalt(saltB64);
                agente.setHashPassword(hashB64);
                agente.setFechaCreacion(rs.getTimestamp("fecha_creacion"));
                agente.setEstado(rs.getInt("estado"));
                agente.setRol(rs.getInt("rol"));
                agente.setStaffID(rs.getString("StaffID"));
                agente.setDeleted(rs.getInt("deleted"));

                return agente;
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
            return null;
        }
    }

    /**
     * Cambia disponibilidad del agente:
     * 0 = Desconectado
     * 1 = Disponible
     */
    
    
    
    
    
    public boolean validarPasswordAgente(int idUsuario, String plainPassword) {

    if (idUsuario <= 0 || plainPassword == null || plainPassword.trim().isEmpty()) {
        return false;
    }

    String sql =
            "SELECT salt, hash_password "
          + "FROM dbo.AGENTE "
          + "WHERE id_usuario = ? "
          + "AND deleted = 0";

    try (Connection con = new ConexionSQLServer().getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, idUsuario);

        try (ResultSet rs = ps.executeQuery()) {

            if (!rs.next()) {
                return false;
            }

            String saltB64 = rs.getString("salt");
            String hashB64 = rs.getString("hash_password");

            if (saltB64 == null || hashB64 == null) {
                return false;
            }

            return PasswordUtil.verify(plainPassword, saltB64, hashB64);
        }

    } catch (SQLException ex) {
        ex.printStackTrace();
        return false;
    }
}
public ResultadoOperacion cambiarEstadoAgente(int idUsuario, int estado) {

    if (idUsuario <= 0) {
        return new ResultadoOperacion("error", "ID de agente inválido.", null);
    }

    if (estado != 0 && estado != 1 && estado != 3) {
        return new ResultadoOperacion(
                "error",
                "Estado inválido. Use 0=Desconectado, 1=Disponible, 3=Pausado.",
                null
        );
    }

    String sql = "{ CALL dbo.SP_AGENTE_CAMBIAR_ESTADO(?,?,?,?) }";

    try (Connection con = new ConexionSQLServer().getConnection();
         CallableStatement cs = con.prepareCall(sql)) {

        cs.setInt(1, idUsuario);
        cs.setInt(2, estado);

        cs.registerOutParameter(3, Types.NVARCHAR); // @mensaje
        cs.registerOutParameter(4, Types.INTEGER);  // @resultado

        cs.execute();

        String mensaje = cs.getString(3);
        int resultado = cs.getInt(4);

        if (resultado > 0) {
            return new ResultadoOperacion("success", mensaje, resultado);
        }

        return new ResultadoOperacion("error", mensaje, resultado);

    } catch (SQLException ex) {
        return new ResultadoOperacion("error", ex.getMessage(), null);
    }
}

public ResultadoOperacion cambiarEstadoAgente(int idUsuario, int estado, String password) {
    return cambiarEstadoAgente(idUsuario, estado);
}
    /**
     * Mapea el resultado de SP_AGENTE_LISTAR.
     * El SP no devuelve salt/hash por seguridad.
     */
private Agente mapearAgenteListado(ResultSet rs) throws SQLException {

    Agente agente = new Agente();

    agente.setIdUsuario(rs.getInt("id_usuario"));
    agente.setNombre(rs.getString("nombre"));
    agente.setCodigo(rs.getString("codigo"));

    agente.setFechaCreacion(rs.getTimestamp("fecha_creacion"));

    agente.setEstado(rs.getInt("estado"));
    agente.setRol(rs.getInt("rol"));
    agente.setStaffID(rs.getString("StaffID"));

    agente.setUltimaFechaActivo(rs.getTimestamp("ultima_fecha_activo"));
    agente.setTiempoActivo(rs.getString("TiempoActivo"));

    agente.setTiempoActivoHoySegundos(rs.getInt("TiempoActivoHoySegundos"));
    agente.setTiempoActivoHoy(rs.getString("TiempoActivoHoy"));

    agente.setDeleted(rs.getInt("deleted"));

    return agente;
}
    
}