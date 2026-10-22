-- ============================================================================
-- SCRIPT DE PRUEBAS INTERACTIVAS Y COMPROBACIÓN EN ORACLE SQL DEVELOPER
-- EVALUACIÓN PARCIAL N° 2 (EP2) - CASO ESTILO URBANO
-- ============================================================================

SET SERVEROUTPUT ON;
SET LINESIZE 200;
SET PAGESIZE 100;

-- ============================================================================
-- 0. VISTAS PROFESIONALES DE ABSTRACCIÓN (TRABAJADORES Y CLIENTES)
-- Permite consultar datos usando ID_TRABAJADOR e ID_CLIENTE en vez del genérico ID_USUARIO
-- ============================================================================
CREATE OR REPLACE VIEW V_TRABAJADORES AS
SELECT 
    id_usuario AS id_trabajador,
    rut,
    nombre,
    apellido,
    nombre || ' ' || apellido AS trabajador,
    email,
    telefono,
    sueldo_base,
    estado
FROM USUARIO
WHERE id_rol = 2;

CREATE OR REPLACE VIEW V_CLIENTES AS
SELECT 
    id_usuario AS id_cliente,
    rut,
    nombre,
    apellido,
    nombre || ' ' || apellido AS cliente,
    email,
    telefono,
    estado
FROM USUARIO
WHERE id_rol = 3;

-- ----------------------------------------------------------------------------
-- CASO 1: MODIFICAR EL SUELDO DE UN TRABAJADOR Y COMPROBAR EL TRIGGER AFTER
-- ----------------------------------------------------------------------------
PROMPT === 1.1 SUELDO ACTUAL DEL TRABAJADOR IGNACIO LÓPEZ ===;
SELECT id_usuario AS id_trabajador, 
       rut, 
       nombre || ' ' || apellido AS trabajador, 
       TO_CHAR(sueldo_base, '$999G999G999') AS sueldo_base
FROM USUARIO
WHERE id_usuario = 2;

PROMPT === 1.2 EJECUTANDO UPDATE EN USUARIO (SUELDO A $750.000) ===;
UPDATE USUARIO
SET sueldo_base = 750000
WHERE id_usuario = 2;
COMMIT;

PROMPT === 1.3 CONSULTA EN TABLA CON EL NUEVO SUELDO ===;
SELECT id_usuario AS id_trabajador, 
       rut, 
       nombre || ' ' || apellido AS trabajador, 
       TO_CHAR(sueldo_base, '$999G999G999') AS nuevo_sueldo
FROM USUARIO
WHERE id_usuario = 2;

PROMPT === 1.4 REGISTRO GENERADO AUTOMÁTICAMENTE EN AUDITORIA_SUELDO_EMPLEADO ===;
SELECT id_auditoria,
       id_usuario AS id_trabajador,
       TO_CHAR(sueldo_antiguo, '$999G999G999') AS sueldo_antiguo,
       TO_CHAR(sueldo_nuevo, '$999G999G999') AS sueldo_nuevo,
       TO_CHAR(diferencia, '$999G999G999') AS diferencia,
       tipo_modificacion,
       usuario_db,
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
SELECT p.id_pedido, 
       p.nro_seguimiento, 
       p.id_cliente,
       p.id_trabajador,
       TO_CHAR(p.total_pedido, '$999G999G999') AS total, 
       ep.nombre_estado
FROM PEDIDO p
JOIN ESTADO_PEDIDO ep ON p.id_estado = ep.id_estado
WHERE p.id_pedido = 5003;

PROMPT === 4.2 ACTUALIZANDO PEDIDO 5003 A ESTADO 4 (EN CAMINO) ===;
UPDATE PEDIDO
SET id_estado = 4
WHERE id_pedido = 5003;
COMMIT;

PROMPT === 4.3 HISTORIAL DE TRACKING GENERADO AUTOMÁTICAMENTE POR EL TRIGGER ===;
SELECT id_historial, 
       id_pedido, 
       id_estado, 
       TO_CHAR(fecha_cambio, 'DD/MM/YYYY HH24:MI:SS') AS fecha, 
       observacion
FROM HISTORIAL_TRACKING_PEDIDO
WHERE id_pedido = 5003
ORDER BY id_historial DESC;


-- ----------------------------------------------------------------------------
-- CASO 5: PROBAR PROCEDIMIENTOS Y FUNCIONES DEL PACKAGE
-- ----------------------------------------------------------------------------
PROMPT === 5.1 REAJUSTE INFLACIONARIO MASIVO DEL 4.5% ===;
EXEC PKG_ESTILO_URBANO.sp_reajuste_masivo_sueldos;

PROMPT === 5.2 CONSULTA EN VISTA V_TRABAJADORES TRAS REAJUSTE MASIVO ===;
SELECT id_trabajador, rut, trabajador, TO_CHAR(sueldo_base, '$999G999G999') AS sueldo_reajustado
FROM V_TRABAJADORES;

PROMPT === 5.3 CONSULTA DE SUELDO PROMEDIO Y BONO VÍA FUNCIONES DEL PACKAGE ===;
SELECT TO_CHAR(PKG_ESTILO_URBANO.fn_promedio_sueldo_trabajadores, '$999G999G999') AS sueldo_promedio_planta,
       TO_CHAR(PKG_ESTILO_URBANO.fn_calcular_bono(2, 115), '$999G999G999') AS bono_meta_115pct
FROM DUAL;
