<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Sincronizar Agentes de Farmacia</title>

    <style>
        *{box-sizing:border-box}
        body{margin:0;background:#f4f6f9;font-family:Arial,sans-serif;color:#333}
        .container{max-width:700px;margin:70px auto;padding:20px}
        .card{background:#fff;border-radius:12px;padding:30px;box-shadow:0 4px 18px rgba(0,0,0,.08)}
        h2{margin-top:0;margin-bottom:10px}
        .descripcion{color:#666;line-height:1.5;margin-bottom:25px}
        .alert{padding:15px;border-radius:8px;margin-bottom:20px}
        .success{background:#e8f7ed;border:1px solid #a9dfb9;color:#176b34}
        .error{background:#fdecec;border:1px solid #f2b4b4;color:#9b1c1c}
        .resultados{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-top:15px}
        .resultado{background:rgba(255,255,255,.5);padding:10px;border-radius:6px;text-align:center}
        .resultado strong{display:block;font-size:22px;margin-bottom:4px}
        button{width:100%;border:0;border-radius:8px;padding:14px;font-size:16px;font-weight:bold;cursor:pointer;background:#198754;color:#fff}
        button:hover{opacity:.9}
        .advertencia{font-size:13px;color:#777;margin-top:15px;text-align:center}
    </style>
</head>

<body>

<div class="container">

    <div class="card">

        <h2>Sincronizar agentes de farmacia</h2>

        <div class="descripcion">
            Este proceso consulta los usuarios de farmacia configurados en HQ, determina la farmacia correspondiente mediante
            <strong>VW_FARMACIAS_SUPERVISOR</strong> y crea solamente los usuarios que todavía no existen en AGENTE.
            Las contraseñas serán almacenadas utilizando PBKDF2-HMAC-SHA256.
        </div>

        <%
            String tipo = (String) request.getAttribute("tipo");
            String mensaje = (String) request.getAttribute("mensaje");
            Integer encontrados = (Integer) request.getAttribute("encontrados");
            Integer insertados = (Integer) request.getAttribute("insertados");
            Integer omitidos = (Integer) request.getAttribute("omitidos");

            if (tipo != null && mensaje != null) {
        %>

        <div class="alert <%= "success".equals(tipo) ? "success" : "error" %>">

            <strong><%= "success".equals(tipo) ? "Proceso completado" : "Error durante la sincronización" %></strong>

            <div style="margin-top:8px;">
                <%= mensaje %>
            </div>

            <% if ("success".equals(tipo)) { %>

            <div class="resultados">
                <div class="resultado">
                    <strong><%= encontrados != null ? encontrados : 0 %></strong>
                    Encontrados
                </div>

                <div class="resultado">
                    <strong><%= insertados != null ? insertados : 0 %></strong>
                    Insertados
                </div>

                <div class="resultado">
                    <strong><%= omitidos != null ? omitidos : 0 %></strong>
                    Omitidos
                </div>
            </div>

            <% } %>

        </div>

        <% } %>

        <form method="POST" action="<%= request.getContextPath() %>/SincronizarAgentesFarmacia" onsubmit="return confirmarSincronizacion();">
            <button type="submit" id="btnSincronizar">Sincronizar usuarios de farmacia</button>
        </form>

        <div class="advertencia">
            Los usuarios existentes no serán modificados.
        </div>

    </div>

</div>

<script>
function confirmarSincronizacion(){
    if(!confirm("¿Desea sincronizar los usuarios de farmacia desde HQ?")) return false;
    const btn=document.getElementById("btnSincronizar");
    btn.disabled=true;
    btn.innerText="Sincronizando...";
    return true;
}
</script>

</body>
</html>