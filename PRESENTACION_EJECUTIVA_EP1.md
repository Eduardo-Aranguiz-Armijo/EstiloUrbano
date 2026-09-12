# GUION Y PRESENTACIÓN EJECUTIVA: EVALUACIÓN PARCIAL N° 1
## TALLER DE BASE DE DATOS (BDY1103) - DUOC UC
### CASO: TIENDA ONLINE "ESTILO URBANO" (E-COMMERCE & DIGITAL RETAIL)

---

> **Ponderación de esta actividad:** 60% de la Evaluación Parcial 1.  
> **Objetivo:** Explicar y justificar técnicamente las decisiones de diseño en Oracle PL/SQL, demostrando dominio del problema de negocio, tipos compuestos (`RECORD` y `VARRAY`), cursores explícitos complejos con parámetros en bucles anidados, gestión de excepciones y la proyección arquitectónica de Procedimientos, Funciones, Paquetes y Triggers.

---

## ESTRUCTURA DE DIAPOSITIVAS Y GUION VERBAL

---

### DIAPOSITIVA 1: PORTADA Y PRESENTACIÓN DEL CASO
* **Título:** Transformación Digital y Automatización en Base de Datos: Caso "Estilo Urbano".
* **Subtítulo:** Evaluación Parcial 1 - Taller de Base de Datos (BDY1103).
* **Integrantes:** Eduardo Aránguiz, Luciano Zaninovic, Kevin Urbina.
* **Docente:** Cristian Medina.
* **Fecha:** 16 de septiembre de 2026.

> **🗣️ GUION VERBAL (Lo que debes decir):**  
> *"Buenos días/tardes profesor(a). Hoy presentaremos la primera etapa de nuestro proyecto semestral para la tienda de vestuario juvenil 'Estilo Urbano'. En esta evaluación abordaremos cómo la transición desde un modelo de ventas informal en redes sociales hacia una tienda online centralizada se sustenta técnicamente en el motor Oracle Database utilizando las capacidades avanzadas de programación procedural en PL/SQL."*

---

### DIAPOSITIVA 2: EL PROBLEMA DE NEGOCIO Y CONTEXTO
* **Visual:** Cuadro comparativo "Antes vs. Después" o diagrama de pérdida de clientes y quiebres de stock.
* **Puntos clave en pantalla:**
  * **Situación actual:** Ventas dispersas en Instagram Direct y WhatsApp Business.
  * **Dolores detectados:**
    * Pérdida recurrente de clientes por tiempos lentos de respuesta y chats traspapelados.
    * Descontrol de inventario: venta reiterada de prendas agotadas (quiebres de stock).
    * Gestión caótica con proveedores de insumos textiles y calzado sin alertas de reposición.
    * Imposibilidad de medir el desempeño real de los ejecutivos y liquidar bonos mensuales.
  * **La Solución:** Tienda Online con base de datos relacional y lógica de negocio automatizada en PL/SQL.

> **🗣️ GUION VERBAL:**  
> *"Estilo Urbano operaba vendiendo exclusivamente por chats de WhatsApp e Instagram. Esto provocaba tres problemas críticos: primero, la pérdida constante de ventas por falta de seguimiento; segundo, un descontrol total de inventario, vendiendo ropa que ya no estaba en bodega; y tercero, una relación desorganizada con los proveedores al no contar con umbrales de stock mínimo. Nuestra propuesta construye la base de datos de una Tienda Online formal con portal para clientes, tracking de pedidos en tiempo real y automatización de cierres mensuales en PL/SQL."*

---

### DIAPOSITIVA 3: DATOS A PROCESAR E INFORMACIÓN GENERADA
* **Visual:** Esquema de entrada de datos (Inputs) $\rightarrow$ Procesamiento $\rightarrow$ Salida (Outputs).
* **Puntos clave en pantalla:**
  * **Datos de Entrada a procesar:**
    * Usuarios clasificados por roles (`ADMINISTRADOR`, `TRABAJADOR`, `CLIENTE`).
    * Pedidos online pagados del mes con sus totales netos, IVA y métodos de pago digital.
    * Metas mensuales asignadas a los trabajadores de fulfillment y despacho.
  * **Información Relevante Generada:**
    * Consolidado de ventas efectivas y cantidad de pedidos preparados por trabajador.
    * Porcentaje matemático de cumplimiento de metas individuales.
    * Clasificación automática en tramos de bonificación.
    * Monto en dinero a pagar por incentivo.
    * Log de auditoría de inconsistencias (`LOG_ERRORES_SISTEMA`).

> **🗣️ GUION VERBAL:**  
> *"Para resolver la gestión administrativa, identificamos como datos de entrada los pedidos confirmados por Webpay y Mercado Pago, junto a las metas fijadas a cada operador de bodega. A partir de esto, el bloque PL/SQL genera información de alto valor: el porcentaje de cumplimiento de metas, la tasa de bono correspondiente, el monto a liquidar y una tabla de auditoría con todas las alertas de negocio y errores de motor detectados."*

---

### DIAPOSITIVA 4: JUSTIFICACIÓN DE TIPOS DE DATOS COMPUESTOS (RECORD Y VARRAY)
* **Indicador Evaluado:** IE1.1.2 (15% ponderación).
* **Visual:** Fragmento de código resaltado con la estructura del `RECORD` y la declaración del `VARRAY`.
* **Puntos clave en pantalla:**
  * **RECORD (`r_liquidacion_trabajador`):**
    * Encapsula en un solo objeto de memoria PGA: datos del usuario, pedidos contados, ventas totales, porcentaje de cumplimiento y bono calculado.
    * *Justificación:* Evita declarar decenas de variables sueltas y garantiza atomicidad al insertar en la tabla de resumen.
  * **VARRAY (`t_arreglo_tramos`):**
    * Vector de tamaño fijo (4 posiciones): `(0.00, 0.03, 0.07, 0.12)`.
    * *Justificación:* Las 4 escalas de bonificación son fijas y acotadas. Acceder al arreglo en memoria PGA es significativamente más rápido que ejecutar consultas SQL repetitivas en cada iteración.

> **🗣️ GUION VERBAL:**  
> *"Para cumplir con el indicador de tipos de datos compuestos, implementamos un RECORD y un VARRAY. Justificamos el uso del RECORD porque nos permite empaquetar toda la ficha de liquidación del trabajador en una única estructura en memoria PGA, evitando el desorden de variables escalares y permitiendo un INSERT limpio. Por su parte, el VARRAY almacena los 4 porcentajes de comisión por tramo. Al ser una estructura de tamaño fijo y memoria contigua, el motor no necesita realizar consultas adicionales a disco en cada cálculo, logrando un ahorro sustancial en recursos de CPU y I/O."*

---

### DIAPOSITIVA 5: CURSORES EXPLÍCITOS COMPLEJOS Y BUCLES ANIDADOS
* **Indicador Evaluado:** IE1.2.2 (15% ponderación).
* **Visual:** Diagrama de flujo de los Loops Anidados (Cursor Padre $\rightarrow$ Cursor Hijo).
* **Puntos clave en pantalla:**
  * **Cursor Padre (`cur_trabajadores`):**
    * Extrae la nómina de trabajadores activos con rol operativo (`rol = 2`).
  * **Cursor Hijo Complejo con Parámetros (`cur_pedidos_trabajador`):**
    * Recibe 3 parámetros: `p_id_trabajador`, `p_mes`, `p_anio`.
    * Realiza múltiples `JOIN` (`PEDIDO`, `METODO_PAGO`, `ESTADO_PEDIDO`) filtrando solo pedidos válidos (`PAGADO`, `EN_EMPAQUETAMIENTO`, `EN_CAMINO`, `ENTREGADO`).
  * **Mecánica de Bucles Anidados (Nested Loops):**
    * Loop externo recorre cada empleado.
    * Loop interno abre dinámicamente el cursor hijo parametrizado con el ID del empleado en curso, totalizando ventas en tiempo real.

> **🗣️ GUION VERBAL:**  
> *"El núcleo del procesamiento se diseñó mediante dos cursores explícitos en loops anidados simultáneos. El cursor padre itera por la lista de trabajadores activos. Dentro de ese bucle, llamamos al cursor hijo parametrizado pasándole el ID del trabajador y el periodo de septiembre 2026. Este cursor hijo es complejo porque combina tres tablas con filtros de estados transaccionales. Esta arquitectura con parámetros es óptima para grandes volúmenes de datos, ya que aprovecha los índices relacionales de la base de datos y solo carga en memoria los pedidos específicos de cada operador, evitando lecturas globales de tablas pesadas."*

---

### DIAPOSITIVA 6: GESTIÓN INTEGRAL DE EXCEPCIONES (ORACLE Y USUARIO)
* **Indicador Evaluado:** IE1.3.2 (15% ponderación).
* **Visual:** Tabla comparativa de excepciones capturadas y captura del log en `LOG_ERRORES_SISTEMA`.
* **Puntos clave en pantalla:**
  * **Excepción Predefinida de Oracle:**
    * `ZERO_DIVIDE` (ORA-01476): Se captura cuando un operador posee `meta_mensual = 0`. Evita la caída del proceso, asigna tramo neutro y almacena la advertencia.
  * **Excepciones Definidas por el Usuario:**
    * `ex_sin_pedidos_periodo`: Se dispara con `RAISE` si el trabajador no registró ventas en el mes.
    * `ex_meta_invalida`: Se dispara si la meta tiene un monto negativo.
  * **Estrategia de Sub-Bloque Autónomo:**
    * El bloque `BEGIN ... EXCEPTION ... END` se ubica **dentro** del bucle principal. Si un trabajador falla, el error se aísla en el log y el proceso continúa sin detenerse.

> **🗣️ GUION VERBAL:**  
> *"Un aspecto crítico de la rúbrica es el control de excepciones. Controlamos la excepción predefinida ZERO_DIVIDE, la cual se gatilla si un trabajador tiene meta configurada en cero, evitando que el cálculo colapse. Además, definimos excepciones personalizadas de negocio, como 'ex_sin_pedidos_periodo', para alertar cuando un trabajador activo no tuvo actividad comercial. Lo más relevante es que colocamos el bloque de excepciones dentro del bucle del trabajador: si el empleado número 3 tiene un error, este se registra en la tabla de log y el sistema continúa procesando al empleado número 4 sin interrumpir la liquidación mensual."*

---

### DIAPOSITIVA 7: DEMOSTRACIÓN DE RESULTADOS
* **Visual:** Capturas de la ejecución en consola SQL Developer (`DBMS_OUTPUT`), la tabla `RESUMEN_DESEMPENO_MENSUAL` y la tabla `LOG_ERRORES_SISTEMA`.
* **Puntos clave en pantalla:**
  * Ejecución exitosa de operadores que cumplieron meta (ej. Ignacio López y Valentina Pérez con tramos superiores de bonificación).
  * Evidencia de captura de `ZERO_DIVIDE` para el trabajador Lucas Ramírez (meta = 0).
  * Evidencia de excepción de negocio para Camila Silva (sin pedidos en el mes).
  * Cero registros duplicados o abortos de transacción.

> **🗣️ GUION VERBAL:**  
> *"En pantalla observamos la ejecución real en Oracle SQL Developer. Vemos cómo los trabajadores con desempeño sobresaliente alcanzaron los tramos 3 y 4 del VARRAY, calculando sus bonos de forma exacta. Asimismo, se evidencia cómo la trabajadora nueva sin ventas gatilló nuestra excepción de negocio, y el operador con meta cero fue atrapado por ZERO_DIVIDE, quedando ambos eventos registrados con fecha y código en nuestra tabla de auditoría sin detener el proceso."*

---

### DIAPOSITIVA 8: EVALUACIÓN ARQUITECTÓNICA FUTURA: PROCEDIMIENTOS, FUNCIONES, PAQUETES Y TRIGGERS
* **Indicador Evaluado:** IE1.4.2 (15% ponderación).
* **Visual:** Diagrama de paquetes (`PKG_GESTION_VENTAS`, `PKG_INVENTARIO_PROVEEDORES`) y Triggers de inventario.
* **Puntos clave en pantalla:**
  * **Procedimientos Almacenados:** Automatización batch de cierres contables y liquidaciones periódicas invocables por cronogramas (`DBMS_SCHEDULER`).
  * **Funciones Almacenadas:** Reutilización de algoritmos de cálculo de impuestos (IVA), costos de despacho y verificación de stock unitario reutilizables en sentencias SQL.
  * **Paquetes PL/SQL (`PACKAGES`):**
    * Modularización del código separando especificación de cuerpo.
    * Encapsulamiento de variables de sesión y eliminación de recompilaciones en cascada.
  * **Triggers:**
    * `TRG_DESCUENTO_STOCK_PEDIDO`: Rebaja automática de inventario al confirmar pago, evitando sobreventas.
    * `TRG_AUDITORIA_TRACKING`: Inserción transparente de eventos de seguimiento para el cliente.

> **🗣️ GUION VERBAL:**  
> *"Para las siguientes entregas del semestre, evaluamos la evolución de este bloque anónimo hacia objetos permanentes en base de datos. Los procedimientos almacenados asumirán las liquidaciones batch recurrentes. Las funciones encapsularán el cálculo de descuentos e IVA para ser usadas tanto en PL/SQL como en consultas SQL. Agruparemos toda esta lógica en dos grandes paquetes: PKG_GESTION_VENTAS y PKG_INVENTARIO_PROVEEDORES, lo que nos brinda modularidad, encapsulamiento y evita recompilaciones en cascada. Finalmente, los Triggers serán vitales para actualizar automáticamente el stock tras cada venta aprobada y alimentar el historial de tracking del cliente en tiempo real."*

---

### DIAPOSITIVA 9: RIESGOS, LIMITACIONES Y SEGURIDAD
* **Visual:** Matriz de mitigación de riesgos técnicos.
* **Puntos clave en pantalla:**
  * **Triggers y Tablas Mutantes (`ORA-04091`):** Riesgo de sobreutilizar triggers para reglas complejas. *Mitigación:* Limitar triggers solo a auditoría y delegar lógica transaccional a paquetes.
  * **Concurrencia y Bloqueos en Ventas Masivas:** Riesgo de bloqueos de stock en eventos de alta demanda. *Mitigación:* Actualización ordenada de registros y transacciones cortas.
  * **Seguridad de Acceso:** Uso de privilegios definidos (`AUTHID DEFINER`), impidiendo que los usuarios de la web tengan permisos directos de escritura sobre las tablas maestras.

> **🗣️ GUION VERBAL:**  
> *"Es fundamental considerar los riesgos técnicos. El uso excesivo de triggers puede derivar en tablas mutantes o latencia innecesaria; por ello, establecimos la buena práctica de usar triggers únicamente para auditoría y ajustes simples de inventario. A nivel de concurrencia y seguridad, aislamos el acceso del portal web mediante privilegios de ejecución sobre paquetes, protegiendo las tablas subyacentes contra inyecciones SQL o modificaciones directas no autorizadas."*

---

### DIAPOSITIVA 10: CONCLUSIONES
* **Visual:** Resumen de beneficios tangibles para "Estilo Urbano".
* **Puntos clave en pantalla:**
  * Superación del modelo informal de ventas por redes sociales gracias a una arquitectura relacional sólida.
  * Procesamiento en memoria de alto rendimiento mediante tipos compuestos y cursores anidados eficientes.
  * Robustez transaccional garantizada por un manejo integral de excepciones.
  * Hoja de ruta clara para la implementación de paquetes y triggers en la Evaluación Parcial 2.

> **🗣️ GUION VERBAL:**  
> *"En conclusión, el proyecto 'Estilo Urbano' resuelve de raíz los dolores de pérdida de clientes, quiebres de stock y falta de métricas que sufría la empresa en redes sociales. Demostramos que PL/SQL no es solo para consultas simples, sino un motor procedural capaz de gestionar liquidaciones complejas, aplicar reglas de negocio y resistir fallos en tiempo de ejecución. Dejamos sentadas las bases para evolucionar hacia una arquitectura orientada a paquetes y disparadores en la siguiente etapa. Quedamos a su disposición para responder sus preguntas. Muchas gracias."*

---

## BANCO DE PREGUNTAS TÍPICAS DEL PROFESOR Y CÓMO RESPONDERLAS

### Pregunta 1: *"¿Por qué eligieron un VARRAY en vez de una Tabla Anidada (Nested Table) o una tabla física para los tramos de bono?"*
* **Respuesta modelo:**  
  *"Elegimos un `VARRAY` porque la política de comisiones de la empresa cuenta con un límite máximo conocido y acotado de tramos (exactamente 4 escalas). El `VARRAY` almacena sus elementos de forma contigua en memoria y preserva el orden de sus índices, consumiendo menos recursos de PGA. Si la cantidad de tramos fuera dinámica o indeterminada, habríamos utilizado una Tabla Anidada o una tabla relacional."*

### Pregunta 2: *"¿Qué ventaja técnica tiene pasar parámetros al cursor hijo en vez de hacer un solo cursor con GROUP BY?"*
* **Respuesta modelo:**  
  *"El cursor hijo con parámetros nos permite recorrer el detalle específico de las órdenes dentro del ciclo de vida de cada trabajador, facilitando la aplicación de validaciones intermedias fila a fila —como detectar si un empleado no tiene pedidos y disparar una excepción personalizada sin que afecte a los demás—. Además, permite al optimizador de Oracle utilizar los índices sobre `id_trabajador` y fecha, evitando escaneos de tabla completa (`Full Table Scan`)."*

### Pregunta 3: *"¿Por qué colocaron el bloque de excepciones adentro del bucle FOR en lugar de dejarlo al final del bloque anónimo?"*
* **Respuesta modelo:**  
  *"Si dejamos el bloque de excepciones al final del programa principal, cualquier error en un solo trabajador (como una división por cero) abortaría el bloque completo, dejando a los demás trabajadores sin procesar y obligando a un ROLLBACK total. Al colocar un sub-bloque anónimo dentro del loop, encapsulamos el error: capturamos la falla, la registramos en `LOG_ERRORES_SISTEMA`, insertamos un registro neutro y el bucle continúa normalmente con el siguiente trabajador."*

### Pregunta 4: *"¿Cómo evitarán el error de tabla mutante (ORA-04091) cuando implementen los Triggers en la siguiente fase?"*
* **Respuesta modelo:**  
  *"El error de tabla mutante ocurre cuando un trigger de nivel de fila (`FOR EACH ROW`) intenta consultar o modificar la misma tabla que disparó el evento. En nuestro diseño, el trigger sobre `PEDIDO` no modificará la tabla `PEDIDO`, sino tablas externas (`PRODUCTO` e `HISTORIAL_TRACKING_PEDIDO`). Si en algún momento requiriéramos validar el conjunto completo de pedidos, utilizaremos un Compound Trigger (Disparador Compuesto) introducido en Oracle 11g, el cual permite compartir variables entre las secciones `BEFORE`, `EACH ROW` y `AFTER` sin generar mutación."*
