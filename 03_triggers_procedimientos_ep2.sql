-- ============================================================================
-- ASIGNATURA : BDY1103 - TALLER DE BASE DE DATOS
-- EVALUACION : EVALUACION PARCIAL N 2 (EP2)
-- PROYECTO   : TIENDA ONLINE "ESTILO URBANO"
-- ARCHIVO    : 03_triggers_procedimientos_ep2.sql
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;

-- 1. Ventas Mayoristas (Columnas exactas: total_neto y total_iva)
MERGE INTO PEDIDO p
USING (SELECT 5010 AS id_pedido, 'TRK-EST-MAYOR-01' AS nro, 10 AS clie, 2 AS trab, 1 AS mp, 5 AS est, DATE '2026-09-10' AS fec, 3781513 AS neto, 718487 AS iva, 4500000 AS tot FROM dual) d
ON (p.id_pedido = d.id_pedido)
WHEN NOT MATCHED THEN
    INSERT (id_pedido, nro_seguimiento, id_cliente, id_trabajador, id_metodo_pago, id_estado, fecha_pedido, total_neto, total_iva, total_pedido)
    VALUES (d.id_pedido, d.nro, d.clie, d.trab, d.mp, d.est, d.fec, d.neto, d.iva, d.tot);

MERGE INTO PEDIDO p
USING (SELECT 5011 AS id_pedido, 'TRK-EST-MAYOR-02' AS nro, 11 AS clie, 3 AS trab, 2 AS mp, 5 AS est, DATE '2026-09-12' AS fec, 2941176 AS neto, 558824 AS iva, 3500000 AS tot FROM dual) d
ON (p.id_pedido = d.id_pedido)
WHEN NOT MATCHED THEN
    INSERT (id_pedido, nro_seguimiento, id_cliente, id_trabajador, id_metodo_pago, id_estado, fecha_pedido, total_neto, total_iva, total_pedido)
    VALUES (d.id_pedido, d.nro, d.clie, d.trab, d.mp, d.est, d.fec, d.neto, d.iva, d.tot);
COMMIT;

-- 2. Secuencia para tracking
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_HISTORIAL_TRACK';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
CREATE SEQUENCE SEQ_HISTORIAL_TRACK START WITH 100 INCREMENT BY 1;

-- 3. Trigger Tracking (Columnas exactas: id_historial, fecha_cambio, observacion)
CREATE OR REPLACE TRIGGER trg_tracking_cambio_estado_pedido
AFTER UPDATE OF id_estado ON PEDIDO
FOR EACH ROW
DECLARE
    v_desc_estado VARCHAR2(100);
BEGIN
    BEGIN
        SELECT nombre_estado INTO v_desc_estado FROM ESTADO_PEDIDO WHERE id_estado = :NEW.id_estado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_desc_estado := 'ESTADO ' || :NEW.id_estado;
    END;

    INSERT INTO HISTORIAL_TRACKING_PEDIDO (
        id_historial, id_pedido, id_estado, fecha_cambio, observacion
    ) VALUES (
        SEQ_HISTORIAL_TRACK.NEXTVAL,
        :NEW.id_pedido,
        :NEW.id_estado,
        SYSDATE,
        'Actualizacion automatica: El pedido cambio a ' || v_desc_estado || ' por usuario ' || USER
    );
END;
/

-- 4. Vistas de Abstracción para evitar términos robóticos
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

-- 5. Especificacion del Package PKG_ESTILO_URBANO
CREATE OR REPLACE PACKAGE PKG_ESTILO_URBANO IS
    c_version CONSTANT VARCHAR2(10) := '2.0-EP2';

    FUNCTION fn_calcular_bono(p_id_trabajador NUMBER, p_pct_meta NUMBER) RETURN NUMBER;
    FUNCTION fn_promedio_sueldo_trabajadores RETURN NUMBER;
    FUNCTION fn_obtener_margen_financiero RETURN VARCHAR2;

    PROCEDURE sp_actualizar_sueldo_empleado(p_id_trabajador NUMBER, p_nuevo_sueldo NUMBER);
    PROCEDURE sp_cambiar_estado_pedido(p_id_pedido NUMBER, p_nuevo_estado NUMBER);
    PROCEDURE sp_reajuste_masivo_sueldos;
END PKG_ESTILO_URBANO;
/

-- 6. Cuerpo del Package PKG_ESTILO_URBANO
CREATE OR REPLACE PACKAGE BODY PKG_ESTILO_URBANO IS

    FUNCTION fn_es_trabajador_valido(p_id_trabajador NUMBER) RETURN BOOLEAN IS
        v_existe NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO v_existe FROM USUARIO WHERE id_usuario = p_id_trabajador AND id_rol = 2 AND estado = 'A';
        RETURN (v_existe > 0);
    END fn_es_trabajador_valido;

    FUNCTION fn_calcular_bono(p_id_trabajador NUMBER, p_pct_meta NUMBER) RETURN NUMBER IS
        v_sueldo_actual NUMBER;
        v_bono          NUMBER := 0;
    BEGIN
        SELECT sueldo_base INTO v_sueldo_actual FROM USUARIO WHERE id_usuario = p_id_trabajador;
        IF p_pct_meta >= 120 THEN v_bono := ROUND(v_sueldo_actual * 0.12);
        ELSIF p_pct_meta >= 100 THEN v_bono := ROUND(v_sueldo_actual * 0.07);
        ELSIF p_pct_meta >= 80 THEN v_bono := ROUND(v_sueldo_actual * 0.03);
        ELSE v_bono := 0; END IF;
        RETURN v_bono;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN 0;
    END fn_calcular_bono;

    FUNCTION fn_promedio_sueldo_trabajadores RETURN NUMBER IS
        v_promedio NUMBER := 0;
    BEGIN
        SELECT NVL(ROUND(AVG(sueldo_base)), 0) INTO v_promedio FROM USUARIO WHERE id_rol = 2 AND estado = 'A';
        RETURN v_promedio;
    END fn_promedio_sueldo_trabajadores;

    FUNCTION fn_obtener_margen_financiero RETURN VARCHAR2 IS
        v_ingresos NUMBER := 0;
        v_sueldos  NUMBER := 0;
        v_margen   NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(total_pedido), 0) INTO v_ingresos FROM PEDIDO WHERE id_estado IN (2,3,4,5);
        SELECT NVL(SUM(sueldo_base), 0) INTO v_sueldos FROM USUARIO WHERE id_rol = 2 AND estado = 'A';
        v_margen := v_ingresos - v_sueldos;
        RETURN 'Ventas: $' || TO_CHAR(v_ingresos, 'FM999,999,999') || 
               ' | Sueldos: $' || TO_CHAR(v_sueldos, 'FM999,999,999') || 
               ' | Ganancia Libre: $' || TO_CHAR(v_margen, 'FM999,999,999');
    END fn_obtener_margen_financiero;

    PROCEDURE sp_actualizar_sueldo_empleado(p_id_trabajador NUMBER, p_nuevo_sueldo NUMBER) IS
    BEGIN
        IF NOT fn_es_trabajador_valido(p_id_trabajador) THEN
            DBMS_OUTPUT.PUT_LINE('AVISO: El ID ' || p_id_trabajador || ' no corresponde a un trabajador activo.');
            RETURN;
        END IF;
        UPDATE USUARIO SET sueldo_base = p_nuevo_sueldo WHERE id_usuario = p_id_trabajador;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('OK: Sueldo del trabajador ' || p_id_trabajador || ' actualizado a $' || p_nuevo_sueldo);
    END sp_actualizar_sueldo_empleado;

    PROCEDURE sp_cambiar_estado_pedido(p_id_pedido NUMBER, p_nuevo_estado NUMBER) IS
    BEGIN
        UPDATE PEDIDO SET id_estado = p_nuevo_estado WHERE id_pedido = p_id_pedido;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('OK: Pedido #' || p_id_pedido || ' actualizado al estado ' || p_nuevo_estado);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('ERROR al actualizar pedido: ' || SQLERRM);
    END sp_cambiar_estado_pedido;

    PROCEDURE sp_reajuste_masivo_sueldos IS
        c_pct_reajuste CONSTANT NUMBER := 0.045;
        v_cont NUMBER := 0;
    BEGIN
        UPDATE USUARIO SET sueldo_base = ROUND(sueldo_base * (1 + c_pct_reajuste)) WHERE id_rol = 2 AND estado = 'A';
        v_cont := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('OK: Reajuste masivo aplicado a ' || v_cont || ' trabajadores.');
    END sp_reajuste_masivo_sueldos;

END PKG_ESTILO_URBANO;
/

PROMPT =========================================================================;
PROMPT BASE DE DATOS Y COMPONENTES EP2 100% COMPILADOS CON EXITO;
PROMPT =========================================================================;
