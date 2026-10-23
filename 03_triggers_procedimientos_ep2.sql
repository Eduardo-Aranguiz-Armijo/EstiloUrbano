-- ============================================================================
-- ASIGNATURA : BDY1103 - TALLER DE BASE DE DATOS
-- EVALUACION : EVALUACION PARCIAL N° 2 (EP2)
-- PROYECTO   : TIENDA ONLINE "ESTILO URBANO" (E-COMMERCE & DIGITAL FULFILLMENT)
-- INTEGRANTES: Eduardo Aránguiz - Luciano Zaninovic - Kevin Urbina
-- DOCENTE    : Cristian Medina
-- SEMESTRE   : 4° Semestre (2026)
-- ARCHIVO    : 03_triggers_procedimientos_ep2.sql
-- DESCRIPCIÓN: SCRIPT MAESTRO DE PROCEDIMIENTOS, FUNCIONES, PACKAGES Y TRIGGERS
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;

-- ============================================================================
-- 1. CARGA DE VENTAS MAYORISTAS (PARA BALANCE FINANCIERO Y SOLVENCIA)
-- ============================================================================
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

-- ============================================================================
-- 2. TABLAS Y SECUENCIAS DE AUDITORÍA HISTÓRICA
-- ============================================================================

-- Secuencias
BEGIN
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN ('SEQ_HISTORIAL_TRACK', 'SEQ_AUDIT_SUELDO', 'SEQ_AUDIT_SENTENCIA')) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/
CREATE SEQUENCE SEQ_HISTORIAL_TRACK START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE SEQ_AUDIT_SUELDO START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_AUDIT_SENTENCIA START WITH 1 INCREMENT BY 1;

-- Tabla de Auditoría de Sueldos (Poblada por Trigger de Fila AFTER con :OLD y :NEW)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE AUDITORIA_SUELDO_EMPLEADO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
CREATE TABLE AUDITORIA_SUELDO_EMPLEADO (
    id_auditoria        NUMBER(8)       CONSTRAINT pk_audit_sueldo PRIMARY KEY,
    id_usuario          NUMBER(6)       NOT NULL,
    sueldo_antiguo      NUMBER(10)      NOT NULL,
    sueldo_nuevo        NUMBER(10)      NOT NULL,
    diferencia          NUMBER(10)      NOT NULL,
    tipo_modificacion   VARCHAR2(20)    NOT NULL, -- 'AUMENTO', 'DISMINUCION' o 'SIN_CAMBIO'
    usuario_db          VARCHAR2(50)    NOT NULL,
    fecha_modificacion  DATE            DEFAULT SYSDATE NOT NULL
);

-- Tabla de Auditoría Operacional a Nivel de Sentencia
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE AUDITORIA_SENTENCIA_PEDIDO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
CREATE TABLE AUDITORIA_SENTENCIA_PEDIDO (
    id_auditoria        NUMBER(8)       CONSTRAINT pk_audit_sentencia PRIMARY KEY,
    operacion_dml       VARCHAR2(20)    NOT NULL,
    tabla_afectada      VARCHAR2(30)    DEFAULT 'PEDIDO' NOT NULL,
    usuario_db          VARCHAR2(50)    NOT NULL,
    fecha_operacion     DATE            DEFAULT SYSDATE NOT NULL,
    observacion         VARCHAR2(200)
);

-- ============================================================================
-- 3. TRIGGERS A NIVEL DE FILA (FOR EACH ROW)
-- ============================================================================

-- Trigger 1 (Fila BEFORE): Validación Preventiva de Sueldo Mínimo Legal ($500.000)
CREATE OR REPLACE TRIGGER trg_valida_sueldo_empleado
BEFORE INSERT OR UPDATE OF sueldo_base ON USUARIO
FOR EACH ROW
BEGIN
    IF :NEW.id_rol IN (1, 2) THEN -- Administradores o Trabajadores
        IF :NEW.sueldo_base < 500000 THEN
            RAISE_APPLICATION_ERROR(-20001, 
                'ORA-20001: El sueldo base ($' || TO_CHAR(:NEW.sueldo_base, 'FM999,999,999') || 
                ') no puede ser inferior al sueldo mínimo legal de $500.000.');
        END IF;
    END IF;
END;
/

-- Trigger 2 (Fila AFTER): Auditoría Completa de Sueldos con :OLD y :NEW
CREATE OR REPLACE TRIGGER trg_audit_sueldo_cambios
AFTER UPDATE OF sueldo_base ON USUARIO
FOR EACH ROW
DECLARE
    v_tipo VARCHAR2(20);
    v_dif  NUMBER;
BEGIN
    v_dif := :NEW.sueldo_base - :OLD.sueldo_base;
    IF v_dif > 0 THEN
        v_tipo := 'AUMENTO';
    ELSIF v_dif < 0 THEN
        v_tipo := 'DISMINUCION';
    ELSE
        v_tipo := 'SIN_CAMBIO';
    END IF;

    INSERT INTO AUDITORIA_SUELDO_EMPLEADO (
        id_auditoria, id_usuario, sueldo_antiguo, sueldo_nuevo,
        diferencia, tipo_modificacion, usuario_db, fecha_modificacion
    ) VALUES (
        SEQ_AUDIT_SUELDO.NEXTVAL,
        :NEW.id_usuario,
        :OLD.sueldo_base,
        :NEW.sueldo_base,
        v_dif,
        v_tipo,
        USER,
        SYSDATE
    );
END;
/

-- Trigger 3 (Fila AFTER): Trazabilidad Automática de Cambio de Estado en Pedidos
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
        'Actualización automática: El pedido cambió a ' || v_desc_estado || ' por usuario ' || USER
    );
END;
/

-- ============================================================================
-- 4. TRIGGERS A NIVEL DE SENTENCIA (CONTROL FINANCIERO Y AUDITORÍA GLOBAL)
-- ============================================================================

-- Trigger 4 (Sentencia AFTER): Control de Solvencia Financiera (Ventas vs Sueldos)
-- Evita el error ORA-04091: mutating table al ejecutarse a nivel de sentencia
CREATE OR REPLACE TRIGGER trg_valida_solvencia_sueldos
AFTER INSERT OR UPDATE OF sueldo_base ON USUARIO
DECLARE
    v_total_sueldos NUMBER := 0;
    v_total_ventas  NUMBER := 0;
BEGIN
    -- Suma total de masa salarial activa de la empresa
    SELECT NVL(SUM(sueldo_base), 0) INTO v_total_sueldos 
    FROM USUARIO 
    WHERE id_rol = 2 AND estado = 'A';

    -- Suma total de ventas confirmadas en pedidos
    SELECT NVL(SUM(total_pedido), 0) INTO v_total_ventas 
    FROM PEDIDO 
    WHERE id_estado IN (2, 3, 4, 5);

    -- Si la nómina supera las ventas totales, se cancela la transacción
    IF v_total_sueldos > v_total_ventas THEN
        RAISE_APPLICATION_ERROR(-20003, 
            'ORA-20003: CONTROL FINANCIERO BLOQUEADO: La nómina total de sueldos ($' || 
            TO_CHAR(v_total_sueldos, 'FM999,999,999') || ') supera las ventas totales de la empresa ($' || 
            TO_CHAR(v_total_ventas, 'FM999,999,999') || '). Transacción revertida.');
    END IF;
END;
/

-- Trigger 5 (Sentencia AFTER): Auditoría Operacional DML sobre PEDIDO
CREATE OR REPLACE TRIGGER trg_sentencia_audit_pedido
AFTER INSERT OR UPDATE OR DELETE ON PEDIDO
DECLARE
    v_op VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_op := 'INSERT';
    ELSIF UPDATING THEN
        v_op := 'UPDATE';
    ELSIF DELETING THEN
        v_op := 'DELETE';
    END IF;

    INSERT INTO AUDITORIA_SENTENCIA_PEDIDO (
        id_auditoria, operacion_dml, tabla_afectada, usuario_db, fecha_operacion, observacion
    ) VALUES (
        SEQ_AUDIT_SENTENCIA.NEXTVAL,
        v_op,
        'PEDIDO',
        USER,
        SYSDATE,
        'Sentencia masiva ejecutada exitosamente a nivel de bloque en PEDIDO'
    );
END;
/

-- ============================================================================
-- 5. VISTAS DE ABSTRACCIÓN PROFESIONAL (HUMANIZACIÓN DE IDENTIFICADORES)
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

-- ============================================================================
-- 6. ESPECIFICACIÓN DEL PACKAGE PKG_ESTILO_URBANO (PÚBLICA)
-- ============================================================================

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

-- ============================================================================
-- 7. CUERPO DEL PACKAGE PKG_ESTILO_URBANO (PRIVADO / ENCAPSULADO)
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY PKG_ESTILO_URBANO IS

    -- Constructor / Función Privada: Valida que el ID pertenezca a un trabajador activo
    FUNCTION fn_es_trabajador_valido(p_id_trabajador NUMBER) RETURN BOOLEAN IS
        v_existe NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO v_existe 
        FROM USUARIO 
        WHERE id_usuario = p_id_trabajador AND id_rol = 2 AND estado = 'A';
        RETURN (v_existe > 0);
    END fn_es_trabajador_valido;

    -- Función Pública: Cálculo del bono según porcentaje de cumplimiento de meta comercial
    FUNCTION fn_calcular_bono(p_id_trabajador NUMBER, p_pct_meta NUMBER) RETURN NUMBER IS
        v_sueldo_actual NUMBER;
        v_bono          NUMBER := 0;
    BEGIN
        SELECT sueldo_base INTO v_sueldo_actual FROM USUARIO WHERE id_usuario = p_id_trabajador;
        IF p_pct_meta >= 120 THEN 
            v_bono := ROUND(v_sueldo_actual * 0.12);
        ELSIF p_pct_meta >= 100 THEN 
            v_bono := ROUND(v_sueldo_actual * 0.07);
        ELSIF p_pct_meta >= 80 THEN 
            v_bono := ROUND(v_sueldo_actual * 0.03);
        ELSE 
            v_bono := 0; 
        END IF;
        RETURN v_bono;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN 0;
    END fn_calcular_bono;

    -- Función Pública: Promedio salarial de la plantilla operativa
    FUNCTION fn_promedio_sueldo_trabajadores RETURN NUMBER IS
        v_promedio NUMBER := 0;
    BEGIN
        SELECT NVL(ROUND(AVG(sueldo_base)), 0) INTO v_promedio 
        FROM USUARIO 
        WHERE id_rol = 2 AND estado = 'A';
        RETURN v_promedio;
    END fn_promedio_sueldo_trabajadores;

    -- Función Pública: Balance financiero global y solvencia
    FUNCTION fn_obtener_margen_financiero RETURN VARCHAR2 IS
        v_ingresos NUMBER := 0;
        v_sueldos  NUMBER := 0;
        v_margen   NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(total_pedido), 0) INTO v_ingresos FROM PEDIDO WHERE id_estado IN (2, 3, 4, 5);
        SELECT NVL(SUM(sueldo_base), 0) INTO v_sueldos FROM USUARIO WHERE id_rol = 2 AND estado = 'A';
        v_margen := v_ingresos - v_sueldos;
        RETURN 'Ventas: $' || TO_CHAR(v_ingresos, 'FM999,999,999') || 
               ' | Sueldos: $' || TO_CHAR(v_sueldos, 'FM999,999,999') || 
               ' | Ganancia Libre: $' || TO_CHAR(v_margen, 'FM999,999,999');
    END fn_obtener_margen_financiero;

    -- Procedimiento con Parámetros: Modificación controlada de sueldo
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

    -- Procedimiento: Actualización del ciclo de vida del pedido
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

    -- Procedimiento sin Parámetros: Reajuste masivo inflacionario (4.5%)
    PROCEDURE sp_reajuste_masivo_sueldos IS
        c_pct_reajuste CONSTANT NUMBER := 0.045;
        v_cont NUMBER := 0;
    BEGIN
        UPDATE USUARIO 
        SET sueldo_base = ROUND(sueldo_base * (1 + c_pct_reajuste)) 
        WHERE id_rol = 2 AND estado = 'A';
        v_cont := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('OK: Reajuste masivo aplicado a ' || v_cont || ' trabajadores.');
    END sp_reajuste_masivo_sueldos;

END PKG_ESTILO_URBANO;
/

PROMPT =========================================================================;
PROMPT BASE DE DATOS Y COMPONENTES EP2 100% COMPILADOS CON EXITO;
PROMPT =========================================================================;
