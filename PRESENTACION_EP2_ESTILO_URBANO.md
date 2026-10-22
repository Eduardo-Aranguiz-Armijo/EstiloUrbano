# GUION Y DIAPOSITIVAS: PRESENTACIÓN EJECUTIVA EP2
## TALLER DE BASE DE DATOS (BDY1103) - DUOC UC
### CASO: "ESTILO URBANO" (E-COMMERCE STREETWEAR)
**Expositor:** Eduardo Aránguiz  
**Ponderación:** 60% de la Evaluación Parcial N° 2  

---

## ESTRUCTURA DE LA PRESENTACIÓN (6 DIAPOSITIVAS)

```mermaid
flowchart LR
    D1["Diapositiva 1:\nContexto y Problema"] --> D2["Diapositiva 2:\nProcedimientos y Funciones"]
    D2 --> D3["Diapositiva 3:\nPackages (Público/Privado)"]
    D3 --> D4["Diapositiva 4:\nTriggers de Fila (:OLD/:NEW)"]
    D4 --> D5["Diapositiva 5:\nTriggers de Sentencia y Regla"]
    D5 --> D6["Diapositiva 6:\nDemostración y Conclusión"]
```

---

### DIAPOSITIVA 1: Portada y Contexto del Problema de Negocio
* **Título:** Automatización y Gobernanza Transaccional en Oracle Database: Caso "Estilo Urbano".
* **Subtítulo:** Evaluación Parcial N° 2 - Taller de Base de Datos (BDY1103).
* **Integrantes:** Eduardo Aránguiz, Luciano Zaninovic, Kevin Urbina.
* **Viñetas Clave en la Diapositiva:**
  - Tienda online de indumentaria urbana en expansión con alto volumen de pedidos.
  - **Problema previo:** Falta de auditoría en remuneraciones, riesgo de sueldos no autorizados y descontrol en la trazabilidad de los estados de compras.
  - **Objetivo de la solución:** Trasladar la inteligencia de negocio directamente al motor de base de datos Oracle mediante **PL/SQL robusto y desacoplado**.

> **🎙️ Lo que debes decir (Discurso):**  
> *"Buenos días profesor y compañeros. Hoy presentamos la solución en base de datos para 'Estilo Urbano'. En esta segunda etapa, nuestro objetivo fue garantizar que las operaciones más críticas del negocio —el pago de remuneraciones, la rentabilidad de la tienda y la trazabilidad de pedidos— no dependan de validaciones manuales ni de aplicaciones externas, sino que queden blindadas y automatizadas directamente en Oracle Database con PL/SQL"*.

---

### DIAPOSITIVA 2: Justificación de Procedimientos y Funciones Almacenadas
* **Título:** Procedimientos y Funciones: Procesamiento Masivo y Reutilización.
* **Viñetas Clave en la Diapositiva:**
  - **Procedimiento sin parámetros (`sp_reajuste_masivo_sueldos`):** Ejecuta reajustes salariales inflacionarios (4.5%) de forma masiva sobre todos los operadores activos con una sola instrucción.
  - **Procedimiento con parámetros (`sp_actualizar_sueldo_empleado`):** Garantiza modificaciones individuales controladas y seguras.
  - **Funciones (`fn_calcular_bono` y `fn_promedio_sueldo_trabajadores`):** Retornan cálculos puros y deterministas, integrables directamente en sentencias `SELECT`.
  - **Ventaja clave frente al docente:** Centralización de la lógica en el servidor, minimizando el tráfico de red y garantizando consistencia en los datos.

> **🎙️ Lo que debes decir (Discurso):**  
> *"Profesor, implementamos procedimientos y funciones con y sin parámetros para separar las responsabilidades. El procedimiento masivo aplica el reajuste del 4.5% a toda la nómina en una sola transacción sin necesidad de cursores lentos cliente-servidor. Por su parte, las funciones almacenadas nos permiten consultar indicadores en tiempo real dentro de cualquier consulta SQL, como el cálculo del bono mensual según el porcentaje de meta alcanzado"*.

---

### DIAPOSITIVA 3: Justificación de Packages (Constructores Públicos y Privados)
* **Título:** Modularidad y Encapsulamiento: Package `PKG_ESTILO_URBANO`.
* **Viñetas Clave en la Diapositiva:**
  - **Definición:** Agrupa procedimientos, funciones y constantes relacionadas bajo un mismo espacio de nombres.
  - **Constructor Público (`PACKAGE SPEC`):** Expone únicamente los métodos autorizados para la administración (`sp_actualizar_sueldo_empleado`, `fn_calcular_bono`, `fn_obtener_margen_financiero`).
  - **Constructor Privado (`PACKAGE BODY`):** Función `fn_es_trabajador_valido` oculta dentro del cuerpo. Valida internamente que el empleado exista y esté activo antes de cualquier operación.
  - **Beneficio:** Principio de encapsulamiento y modularidad; si cambia la regla interna, la interfaz externa no se rompe.

> **🎙️ Lo que debes decir (Discurso):**  
> *"La rúbrica nos exigía constructores públicos y privados. En nuestro package `PKG_ESTILO_URBANO`, la especificación define los métodos que cualquier sistema puede consumir. Pero dentro del body dejamos la función privada `fn_es_trabajador_valido`. Esto asegura que nadie desde afuera pueda alterar un sueldo si el usuario no es un operador activo, manteniendo la base de datos modular, limpia y segura"*.

---

### DIAPOSITIVA 4: Triggers a Nivel de Fila (Control BEFORE y Auditoría AFTER)
* **Título:** Integridad Fila por Fila con Disparadores (`FOR EACH ROW`).
* **Viñetas Clave en la Diapositiva:**
  - **Trigger BEFORE (`trg_valida_sueldo_empleado`):** Valida antes de insertar o modificar que ningún sueldo sea menor al mínimo legal ($500.000). Bloqueo preventivo con `RAISE_APPLICATION_ERROR(-20001)`.
  - **Trigger AFTER (`trg_audit_sueldo_cambios`):** Utiliza los pseudorregistros `:OLD` y `:NEW` para poblar la tabla `AUDITORIA_SUELDO_EMPLEADO`, calculando variación neta, fecha y usuario responsable.
  - **Trigger AFTER (`trg_tracking_cambio_estado_pedido`):** Cada vez que un pedido cambia de estado (`PAGADO` ➔ `EN_EMPAQUETAMIENTO` ➔ `EN_CAMINO`), inserta automáticamente la bitácora en `HISTORIAL_TRACKING_PEDIDO`.

> **🎙️ Lo que debes decir (Discurso):**  
> *"A nivel de fila implementamos la directiva `FOR EACH ROW`. Elegimos un trigger BEFORE para la regla legal de sueldo mínimo porque debemos frenar la transacción antes de que toque la tabla. Y usamos triggers AFTER para auditoría de sueldos y tracking de compras, porque requerimos los valores confirmados `:OLD` y `:NEW` para registrar la trazabilidad histórica completa sin margen de manipulación humana"*.

---

### DIAPOSITIVA 5: Triggers a Nivel de Sentencia y Regla Financiera
* **Título:** Control Global y Resolución de Tablas Mutantes (Nivel de Sentencia).
* **Viñetas Clave en la Diapositiva:**
  - **Concepto:** Se ejecutan una sola vez por cada instrucción DML global, sin importar cuántas filas se actualicen.
  - **Trigger 1 (`trg_sentencia_audit_pedido`):** Auditoría operacional de sentencias masivas (INSERT, UPDATE, DELETE).
  - **Trigger 2 (`trg_valida_solvencia_sueldos`):** **Regla Financiera de Negocio**. Compara la suma total de sueldos de la empresa `SUM(sueldo_base)` contra las ventas totales `SUM(total_pedido)`.
  - **Por qué de Sentencia:** Evita el error crítico `ORA-04091: mutating table` al evaluar agregaciones totales al finalizar la transacción completa.

> **🎙️ Lo que debes decir (Discurso):**  
> *"Uno de los mayores desafíos en PL/SQL es el control de agregaciones globales. Nuestro trigger de sentencia `trg_valida_solvencia_sueldos` garantiza que la nómina total nunca supere los ingresos de la tienda. Si una actualización de sueldos pone en riesgo financiero a Estilo Urbano, la sentencia completa se aborta con error `ORA-20003`. Al ser a nivel de sentencia, Oracle nos permite leer la tabla completa sin sufrir el error de tabla mutante"*.

---

### DIAPOSITIVA 6: Conclusiones e Impacto en el Negocio
* **Título:** Conclusiones y Demostración en Vivo.
* **Viñetas Clave en la Diapositiva:**
  - **Cumplimiento total:** 100% de los indicadores de logro de la pauta EP2 (Procedimientos, Funciones, Packages públicos/privados, Triggers fila y sentencia).
  - **Impacto:** Gobernanza total de datos, blindaje contra quiebres financieros y auditoría de extremo a extremo.
  - **Paso a demostración práctica:** Ejecución de pruebas en vivo en Oracle SQL Developer.

> **🎙️ Lo que debes decir (Discurso):**  
> *"En conclusión, la solución desarrollada para 'Estilo Urbano' demuestra cómo un diseño avanzado en PL/SQL transforma una base de datos de un simple almacén pasivo a un motor inteligente y autónomo. A continuación, demostraremos en vivo la ejecución de estos 5 componentes en Oracle SQL Developer. Quedamos atentos a sus preguntas. Muchas gracias"*.
