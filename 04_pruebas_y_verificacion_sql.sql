-- ============================================================================
-- SCRIPT DE PRUEBAS INTERACTIVAS Y COMPROBACIÓN EN ORACLE SQL DEVELOPER
-- EVALUACIÓN PARCIAL N° 2 (EP2) - CASO ESTILO URBANO
-- ============================================================================

SET SERVEROUTPUT ON;
SET LINESIZE 200;
SET PAGESIZE 100;

-- ----------------------------------------------------------------------------
-- CASO 1: MODIFICAR EL SUELDO DE UN EMPLEADO Y COMPROBAR EL TRIGGER AFTER
-- ----------------------------------------------------------------------------
PROMPT === 1.1 SUELDO ACTUAL DEL TRABAJADOR IGNACIO LÓPEZ ===;
SELECT id_usuario, rut, nombre || ' ' || apellido AS trabajador, sueldo_base
FROM USUARIO
WHERE id_usuario = 2;

PROMPT === 1.2 EJECUTANDO UPDATE EN USUARIO (SUELDO A $750.000) ===;
UPDATE USUARIO
SET sueldo_base = 750000
WHERE id_usuario = 2;
COMMIT;

PROMPT === 1.3 CONSULTA EN TABLA USUARIO CON EL NUEVO SUELDO ===;
SELECT id_usuario, rut, nombre || ' ' || apellido AS trabajador, sueldo_base AS nuevo_sueldo
FROM USUARIO
WHERE id_usuario = 2;

PROMPT === 1.4 REGISTRO GENERADO AUTOMÁTICAMENTE EN AUDITORIA_SUELDO_EMPLEADO ===;
SELECT id_auditoria,
       id_usuario,
       nombre_empleado,
       sueldo_antiguo,
       sueldo_nuevo,
       diferencia,
       tipo_movimiento,
       usuario_bd,
       TO_CHAR(fecha_modificacion, 'DD/MM/YYYY HH24:MI:SS') AS fecha
FROM AUDITORIA_SUELDO_EMPLEADO
WHERE id_usuario = 2
ORDER BY id_auditoria DESC;


-- ----------------------------------------------------------------------------
-- CASO 2: TRIGGER BEFORE (VALIDACIÓN DE SUELDO MÍNIMO $500.000)
-- ----------------------------------------------------------------------------
PROMPT === 2.1 INTENTO DE ASIGNAR SUELDO INFERIOR AL MÍNIMO ($350.000) ===;
PROMPT Descomenta la siguiente línea para comprobar el bloqueo ORA-20001:;
-- UPDATE USUARIO SET sueldo_base = 350000 WHERE id_usuario = 2;


-- ----------------------------------------------------------------------------
-- CASO 3: TRIGGER DE SENTENCIA (REGLA FINANCIERA: VENTAS VS SUELDOS)
-- ----------------------------------------------------------------------------
PROMPT === 3.1 BALANCE ACTUAL ENTRE VENTAS Y NÓMINA DE SUELDOS ===;
SELECT PKG_ESTILO_URBANO.fn_obtener_margen_financiero AS balance_financiero FROM DUAL;

PROMPT === 3.2 INTENTO DE AUMENTAR UN SUELDO A UN MONTO QUE EXCEDA LAS VENTAS ===;
PROMPT (Si intentamos subir el sueldo a $15.000.000, la nómina superará las ventas de la tienda);
PROMPT Descomenta la siguiente línea para comprobar el bloqueo ORA-20003:;
-- UPDATE USUARIO SET sueldo_base = 15000000 WHERE id_usuario = 2;


-- ----------------------------------------------------------------------------
-- CASO 4: CAMBIAR EL ESTADO DE UN PEDIDO Y VER EL TRACKING AUTOMÁTICO
-- ----------------------------------------------------------------------------
PROMPT === 4.1 ESTADO ACTUAL DEL PEDIDO 5003 ===;
SELECT p.id_pedido, p.nro_seguimiento, p.total_pedido, ep.nombre_estado
FROM PEDIDO p
JOIN ESTADO_PEDIDO ep ON p.id_estado = ep.id_estado
WHERE p.id_pedido = 5003;

PROMPT === 4.2 ACTUALIZANDO PEDIDO 5003 A ESTADO 4 (EN CAMINO) ===;
UPDATE PEDIDO
SET id_estado = 4
WHERE id_pedido = 5003;
COMMIT;

PROMPT === 4.3 HISTORIAL DE TRACKING GENERADO AUTOMÁTICAMENTE POR EL TRIGGER ===;
SELECT id_tracking, id_pedido, id_estado, TO_CHAR(fecha_evento, 'DD/MM/YYYY HH24:MI:SS') AS fecha, comentario
FROM HISTORIAL_TRACKING_PEDIDO
WHERE id_pedido = 5003
ORDER BY id_tracking DESC;

PROMPT === 4.4 AUDITORÍA A NIVEL DE SENTENCIA EN TABLA PEDIDO ===;
SELECT audit_id, tabla_afectada, operacion, usuario_bd, TO_CHAR(fecha_evento, 'DD/MM/YYYY HH24:MI:SS') AS fecha
FROM AUDITORIA_SENTENCIA_PEDIDO
ORDER BY audit_id DESC;


-- ----------------------------------------------------------------------------
-- CASO 5: PROBAR PROCEDIMIENTOS Y FUNCIONES DEL PACKAGE
-- ----------------------------------------------------------------------------
PROMPT === 5.1 REAJUSTE INFLACIONARIO MASIVO DEL 4.5% ===;
EXEC PKG_ESTILO_URBANO.sp_reajuste_masivo_sueldos;

PROMPT === 5.2 CONSULTA DE AUDITORÍA TRAS REAJUSTE MASIVO ===;
SELECT id_auditoria, nombre_empleado, sueldo_antiguo, sueldo_nuevo, diferencia, tipo_movimiento
FROM AUDITORIA_SUELDO_EMPLEADO
ORDER BY id_auditoria DESC;

PROMPT === 5.3 CONSULTA DE SUELDO PROMEDIO Y BONO VÍA FUNCIONES DEL PACKAGE ===;
SELECT PKG_ESTILO_URBANO.fn_promedio_sueldo_trabajadores AS sueldo_promedio_operadores,
       PKG_ESTILO_URBANO.fn_calcular_bono(2, 115) AS bono_por_cumplimiento_115pct
FROM DUAL;
