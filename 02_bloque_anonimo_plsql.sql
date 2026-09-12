-- ============================================================================
-- ASIGNATURA : BDY1103 - TALLER DE BASE DE DATOS
-- EVALUACIÓN : EVALUACIÓN PARCIAL N° 1 (CASO SEMESTRAL)
-- PROYECTO    : TIENDA ONLINE "ESTILO URBANO" (E-COMMERCE)
-- INTEGRANTES: Eduardo Aránguiz - Luciano Zaninovic - Kevin Urbina
-- DOCENTE    : Cristian Medina
-- SEMESTRE   : 4° Semestre (2026)
-- FECHA      : 16 de Septiembre de 2026
-- ARCHIVO    : 02_bloque_anonimo_plsql.sql
-- DESCRIPCIÓN: BLOQUE ANÓNIMO PL/SQL COMPLETO CON:
--              1. Tipos de datos compuestos: RECORD y VARRAY
--              2. Cursores explícitos complejos con parámetros en Loops anidados
--              3. Control de excepciones predefinidas de Oracle y de usuario
--              4. Persistencia en RESUMEN_DESEMPENO_MENSUAL y LOG_ERRORES_SISTEMA
-- MOTOR      : ORACLE DATABASE 19c / 21c / LIVESQL
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;

DECLARE
    -- ========================================================================
    -- 1. DECLARACIÓN DE CONSTANTES Y PARÁMETROS DEL PROCESO
    -- ========================================================================
    c_mes_evaluado  CONSTANT NUMBER(2) := 9;    -- Septiembre
    c_anio_evaluado CONSTANT NUMBER(4) := 2026; -- 2026

    -- ========================================================================
    -- 2. TIPOS DE DATOS COMPUESTOS (RECORD Y VARRAY) - EXIGENCIA RÚBRICA
    -- ========================================================================
    
    -- A. VARRAY: Escalas porcentuales de bonificación según tramo de cumplimiento
    -- Tramo 1 (< 80%): Sin bono (0%)
    -- Tramo 2 (80% - 99%): 3% de bono
    -- Tramo 3 (100% - 119%): 7% de bono
    -- Tramo 4 (>= 120%): 12% de bono
    TYPE t_arreglo_tramos IS VARRAY(4) OF NUMBER(4, 2);
    v_escalas_bono t_arreglo_tramos := t_arreglo_tramos(0.00, 0.03, 0.07, 0.12);

    -- B. RECORD: Estructura en memoria para almacenar la ficha consolidada
    -- de desempeño mensual de cada operador/trabajador
    TYPE r_liquidacion_trabajador IS RECORD (
        id_trabajador       USUARIO.id_usuario%TYPE,
        rut_trabajador      USUARIO.rut%TYPE,
        nombre_completo     VARCHAR2(100),
        meta_mensual        USUARIO.meta_mensual%TYPE,
        total_pedidos       NUMBER(6) := 0,
        monto_total_ventas  NUMBER(12) := 0,
        pct_cumplimiento    NUMBER(5, 2) := 0,
        tramo_nombre        VARCHAR2(30),
        tasa_bono           NUMBER(4, 2) := 0,
        monto_bonificacion  NUMBER(10) := 0
    );

    -- Instancia del registro en memoria de trabajo
    v_resumen_op r_liquidacion_trabajador;

    -- ========================================================================
    -- 3. DECLARACIÓN DE EXCEPCIONES DEFINIDAS POR EL USUARIO
    -- ========================================================================
    ex_sin_pedidos_periodo  EXCEPTION; -- Cuando el trabajador activo no registra pedidos
    ex_meta_invalida        EXCEPTION; -- Cuando la meta mensual es negativa

    -- ========================================================================
    -- 4. CURSORES EXPLÍCITOS COMPLEJOS (CON Y SIN PARÁMETROS)
    -- ========================================================================
    
    -- CURSOR 1 (PADRE - Sin parámetros):
    -- Obtiene la lista de trabajadores activos (rol = 2) de la tienda online
    CURSOR cur_trabajadores IS
        SELECT u.id_usuario,
               u.rut,
               u.nombre || ' ' || u.apellido AS nombre_completo,
               u.meta_mensual
        FROM USUARIO u
        WHERE u.id_rol = 2 
          AND u.estado = 'A'
        ORDER BY u.id_usuario;

    -- CURSOR 2 (HIJO - Complejo con parámetros):
    -- Extrae los pedidos confirmados/procesados de un trabajador específico en el mes
    -- Realiza JOIN con METODO_PAGO y ESTADO_PEDIDO, filtrando por fecha y estados válidos
    CURSOR cur_pedidos_trabajador(
        p_id_trabajador NUMBER, 
        p_mes           NUMBER, 
        p_anio          NUMBER
    ) IS
        SELECT p.id_pedido,
               p.nro_seguimiento,
               p.fecha_pedido,
               p.total_pedido,
               mp.nombre_metodo AS metodo_pago,
               ep.nombre_estado AS estado_actual
        FROM PEDIDO p
        INNER JOIN METODO_PAGO mp  ON p.id_metodo_pago = mp.id_metodo
        INNER JOIN ESTADO_PEDIDO ep ON p.id_estado = ep.id_estado
        WHERE p.id_trabajador = p_id_trabajador
          AND EXTRACT(MONTH FROM p.fecha_pedido) = p_mes
          AND EXTRACT(YEAR FROM p.fecha_pedido)  = p_anio
          AND p.id_estado IN (2, 3, 4, 5) -- Pagado, Empaquetando, En camino, Entregado
        ORDER BY p.fecha_pedido;

    -- Variables de control y contadores generales
    v_total_trabajadores_proc NUMBER := 0;
    v_total_pedidos_global    NUMBER := 0;
    v_monto_global_ventas     NUMBER := 0;

    -- Variables para capturar código y mensaje de error (requisito Oracle PL/SQL)
    v_error_code              NUMBER;
    v_error_msg               VARCHAR2(400);

BEGIN
    -- Limpieza de ejecuciones anteriores para el mes analizado
    DELETE FROM RESUMEN_DESEMPENO_MENSUAL 
    WHERE mes_proceso = c_mes_evaluado 
      AND anio_proceso = c_anio_evaluado;

    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('  TIENDA ONLINE "ESTILO URBANO" - CIERRE MENSUAL Y LIQUIDACIÓN DE DESEMPEÑO   ');
    DBMS_OUTPUT.PUT_LINE('  PERIODO PROCESADO: ' || LPAD(c_mes_evaluado, 2, '0') || '/' || c_anio_evaluado);
    DBMS_OUTPUT.PUT_LINE('================================================================================');

    -- ========================================================================
    -- 5. BUCLES ANIDADOS SIMULTÁNEOS (NESTED LOOPS)
    -- ========================================================================

    -- LOOP EXTERNO: Itera sobre cada trabajador activo usando Cursor Padre
    FOR reg_trab IN cur_trabajadores LOOP
        
        -- Sub-bloque anónimo interno para encapsular excepciones por trabajador
        -- y permitir que el loop principal continúe procesando a los demás empleados
        BEGIN
            -- Reinicio de los campos del RECORD para el nuevo trabajador
            v_resumen_op.id_trabajador      := reg_trab.id_usuario;
            v_resumen_op.rut_trabajador     := reg_trab.rut;
            v_resumen_op.nombre_completo    := reg_trab.nombre_completo;
            v_resumen_op.meta_mensual       := reg_trab.meta_mensual;
            v_resumen_op.total_pedidos      := 0;
            v_resumen_op.monto_total_ventas := 0;
            v_resumen_op.pct_cumplimiento   := 0;
            v_resumen_op.tasa_bono          := 0;
            v_resumen_op.monto_bonificacion := 0;
            v_resumen_op.tramo_nombre       := 'SIN ASIGNAR';

            -- Validación de negocio: Meta negativa
            IF v_resumen_op.meta_mensual < 0 THEN
                RAISE ex_meta_invalida;
            END IF;

            -- LOOP INTERNO: Itera sobre los pedidos mediante el Cursor Hijo Parametrizado
            FOR reg_ped IN cur_pedidos_trabajador(reg_trab.id_usuario, c_mes_evaluado, c_anio_evaluado) LOOP
                v_resumen_op.total_pedidos      := v_resumen_op.total_pedidos + 1;
                v_resumen_op.monto_total_ventas := v_resumen_op.monto_total_ventas + reg_ped.total_pedido;
            END LOOP;

            -- Validación de negocio: Trabajador sin pedidos en el mes evaluado
            IF v_resumen_op.total_pedidos = 0 THEN
                RAISE ex_sin_pedidos_periodo;
            END IF;

            -- ----------------------------------------------------------------
            -- CÁLCULO DE CUMPLIMIENTO Y BONO USANDO EL VARRAY
            -- ----------------------------------------------------------------
            -- Provocará la excepción predefinida ZERO_DIVIDE si meta_mensual es 0
            v_resumen_op.pct_cumplimiento := ROUND((v_resumen_op.monto_total_ventas / v_resumen_op.meta_mensual) * 100, 2);

            -- Determinación de escala de bonificación mediante índice del VARRAY
            IF v_resumen_op.pct_cumplimiento < 80 THEN
                v_resumen_op.tramo_nombre := 'TRAMO 1 (< 80%)';
                v_resumen_op.tasa_bono    := v_escalas_bono(1); -- 0.00
            ELSIF v_resumen_op.pct_cumplimiento BETWEEN 80 AND 99.99 THEN
                v_resumen_op.tramo_nombre := 'TRAMO 2 (80% - 99%)';
                v_resumen_op.tasa_bono    := v_escalas_bono(2); -- 0.03 (3%)
            ELSIF v_resumen_op.pct_cumplimiento BETWEEN 100 AND 119.99 THEN
                v_resumen_op.tramo_nombre := 'TRAMO 3 (100% - 119%)';
                v_resumen_op.tasa_bono    := v_escalas_bono(3); -- 0.07 (7%)
            ELSE
                v_resumen_op.tramo_nombre := 'TRAMO 4 (>= 120%)';
                v_resumen_op.tasa_bono    := v_escalas_bono(4); -- 0.12 (12%)
            END IF;

            v_resumen_op.monto_bonificacion := ROUND(v_resumen_op.monto_total_ventas * v_resumen_op.tasa_bono);

            -- Persistencia del RECORD procesado en la tabla resumen
            INSERT INTO RESUMEN_DESEMPENO_MENSUAL (
                id_trabajador, nombre_trabajador, mes_proceso, anio_proceso,
                cantidad_pedidos, monto_total_ventas, meta_mensual,
                pct_cumplimiento, tramo_bono, porcentaje_bono, monto_bonificacion
            ) VALUES (
                v_resumen_op.id_trabajador,
                v_resumen_op.nombre_completo,
                c_mes_evaluado,
                c_anio_evaluado,
                v_resumen_op.total_pedidos,
                v_resumen_op.monto_total_ventas,
                v_resumen_op.meta_mensual,
                v_resumen_op.pct_cumplimiento,
                v_resumen_op.tramo_nombre,
                v_resumen_op.tasa_bono * 100,
                v_resumen_op.monto_bonificacion
            );

            -- Acumuladores de resumen gerencial
            v_total_trabajadores_proc := v_total_trabajadores_proc + 1;
            v_total_pedidos_global    := v_total_pedidos_global + v_resumen_op.total_pedidos;
            v_monto_global_ventas     := v_monto_global_ventas + v_resumen_op.monto_total_ventas;

            -- Despliegue en consola del registro exitoso
            DBMS_OUTPUT.PUT_LINE(
                '-> OK: Trabajador [' || RPAD(v_resumen_op.nombre_completo, 20) || '] ' ||
                'Pedidos: ' || LPAD(v_resumen_op.total_pedidos, 2) || ' | ' ||
                'Ventas: $' || TO_CHAR(v_resumen_op.monto_total_ventas, '999,999,999') || ' | ' ||
                'Cumpl: ' || LPAD(TO_CHAR(v_resumen_op.pct_cumplimiento, '990.99'), 7) || '% | ' ||
                'Bono (' || (v_resumen_op.tasa_bono * 100) || '%): $' || TO_CHAR(v_resumen_op.monto_bonificacion, '999,999,999')
            );

        -- ====================================================================
        -- 6. CONTROL INTEGRAL DE EXCEPCIONES
        -- ====================================================================
        EXCEPTION
            -- A. EXCEPCIÓN PREDEFINIDA ORACLE: ZERO_DIVIDE (División por cero)
            WHEN ZERO_DIVIDE THEN
                v_error_code := SQLCODE;
                DBMS_OUTPUT.PUT_LINE(
                    '** ALERTA ORACLE [ZERO_DIVIDE]: Trabajador ' || reg_trab.nombre_completo || 
                    ' tiene META = 0. Imposible calcular % cumplimiento.'
                );
                
                -- Registro en tabla de auditoría de errores
                INSERT INTO LOG_ERRORES_SISTEMA (bloque_origen, codigo_oracle, mensaje_error)
                VALUES (
                    'BLOQUE_ANONIMO_LIQUIDACION',
                    v_error_code,
                    'Error división por cero para trabajador ID ' || reg_trab.id_usuario || 
                    ' (' || reg_trab.nombre_completo || '). Meta mensual configurada en 0.'
                );

                -- Se inserta con cumplimiento 0% para no perder el registro de sus ventas
                INSERT INTO RESUMEN_DESEMPENO_MENSUAL (
                    id_trabajador, nombre_trabajador, mes_proceso, anio_proceso,
                    cantidad_pedidos, monto_total_ventas, meta_mensual,
                    pct_cumplimiento, tramo_bono, porcentaje_bono, monto_bonificacion
                ) VALUES (
                    reg_trab.id_usuario,
                    reg_trab.nombre_completo,
                    c_mes_evaluado,
                    c_anio_evaluado,
                    v_resumen_op.total_pedidos,
                    v_resumen_op.monto_total_ventas,
                    0,
                    0,
                    'TRAMO 0 (META NO DEFINIDA)',
                    0,
                    0
                );

            -- B. EXCEPCIÓN DEFINIDA POR EL USUARIO: Trabajador sin pedidos
            WHEN ex_sin_pedidos_periodo THEN
                DBMS_OUTPUT.PUT_LINE(
                    '** EXCEPCIÓN NEGOCIO [SIN_PEDIDOS]: Trabajador ' || reg_trab.nombre_completo || 
                    ' no registra pedidos pagados/preparados en ' || c_mes_evaluado || '/' || c_anio_evaluado
                );
                
                INSERT INTO LOG_ERRORES_SISTEMA (bloque_origen, codigo_oracle, mensaje_error)
                VALUES (
                    'BLOQUE_ANONIMO_LIQUIDACION',
                    -20001,
                    'Trabajador ID ' || reg_trab.id_usuario || ' (' || reg_trab.nombre_completo || 
                    ') activo sin actividad de ventas ni pedidos en el periodo evaluado.'
                );

            -- C. EXCEPCIÓN DEFINIDA POR EL USUARIO: Meta negativa
            WHEN ex_meta_invalida THEN
                DBMS_OUTPUT.PUT_LINE(
                    '** EXCEPCIÓN NEGOCIO [META_INVALIDA]: Trabajador ' || reg_trab.nombre_completo || 
                    ' posee una meta negativa ($' || reg_trab.meta_mensual || ').'
                );
                
                INSERT INTO LOG_ERRORES_SISTEMA (bloque_origen, codigo_oracle, mensaje_error)
                VALUES (
                    'BLOQUE_ANONIMO_LIQUIDACION',
                    -20002,
                    'Meta mensual inválida (menor a 0) detectada en usuario ID ' || reg_trab.id_usuario
                );

            -- D. CONTROL GENÉRICO DE CUALQUIER OTRA EXCEPCIÓN
            WHEN OTHERS THEN
                v_error_code := SQLCODE;
                v_error_msg  := SUBSTR(SQLERRM, 1, 300);
                DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || v_error_msg);
                INSERT INTO LOG_ERRORES_SISTEMA (bloque_origen, codigo_oracle, mensaje_error)
                VALUES (
                    'BLOQUE_ANONIMO_LIQUIDACION',
                    v_error_code,
                    'Fallo inesperado al procesar trabajador ID ' || reg_trab.id_usuario || ': ' || v_error_msg
                );
        END;

    END LOOP; -- Fin Cursor Padre

    COMMIT;

    -- ========================================================================
    -- 7. REPORTE GERENCIAL FINAL
    -- ========================================================================
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('RESUMEN GENERAL CONSOLIDADO:');
    DBMS_OUTPUT.PUT_LINE('  Total Trabajadores Procesados con Éxito : ' || v_total_trabajadores_proc);
    DBMS_OUTPUT.PUT_LINE('  Total Pedidos Online Procesados          : ' || v_total_pedidos_global);
    DBMS_OUTPUT.PUT_LINE('  Monto Total Ventas Consolidadas          : $' || TO_CHAR(v_monto_global_ventas, '999,999,999'));
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('PROCESAMIENTO PL/SQL COMPLETADO Y DATOS ALMACENADOS EXITOSAMENTE.');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        v_error_code := SQLCODE;
        v_error_msg  := SUBSTR(SQLERRM, 1, 300);
        DBMS_OUTPUT.PUT_LINE('** ERROR CRÍTICO GENERAL: ' || v_error_msg);
        INSERT INTO LOG_ERRORES_SISTEMA (bloque_origen, codigo_oracle, mensaje_error)
        VALUES ('BLOQUE_PRINCIPAL_FATAL', v_error_code, 'Aborto del bloque por error crítico: ' || v_error_msg);
        COMMIT;
END;
/

-- ============================================================================
-- 8. COMPROBACIÓN DE RESULTADOS TRAS LA EJECUCIÓN
-- ============================================================================
PROMPT
PROMPT TABLA RESUMEN DE DESEMPEÑO MENSUAL GENERADA:;
SELECT id_trabajador,
       nombre_trabajador,
       cantidad_pedidos,
       monto_total_ventas,
       meta_mensual,
       pct_cumplimiento || '%' AS cumplimiento,
       tramo_bono,
       porcentaje_bono || '%' AS pct_bono,
       monto_bonificacion
FROM RESUMEN_DESEMPENO_MENSUAL
ORDER BY monto_total_ventas DESC;

PROMPT
PROMPT LOG DE INCIDENCIAS Y EXCEPCIONES CAPTURADAS:;
SELECT id_log, bloque_origen, codigo_oracle, mensaje_error, fecha_evento
FROM LOG_ERRORES_SISTEMA
ORDER BY id_log;
