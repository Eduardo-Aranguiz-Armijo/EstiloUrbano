# GUION Y DIAPOSITIVAS: PRESENTACIÓN EJECUTIVA EP3
## TALLER DE BASE DE DATOS (BDY1103) - DUOC UC
### CASO: "ESTILO URBANO" (ARQUITECTURA HÍBRIDA ORACLE + MONGODB)
**Ponderación:** 60% de la Evaluación Parcial N° 3  
**Expositores:** Eduardo Aránguiz Armijo — Luciano Zaninovic — Kevin Urbina  
**Docente:** Cristian Medina  

---

## ESTRUCTURA DE LA PRESENTACIÓN (7 DIAPOSITIVAS)

```mermaid
flowchart LR
    D1["Diapositiva 1:\nPortada y Título"] --> D2["Diapositiva 2:\nContexto y Problema"]
    D2 --> D3["Diapositiva 3:\nRelacional vs No Relacional"]
    D3 --> D4["Diapositiva 4:\nJustificación y Trade-Offs"]
    D4 --> D5["Diapositiva 5:\nMatriz 4 Preguntas"]
    D5 --> D6["Diapositiva 6:\nCRUD en MongoDB"]
    D6 --> D7["Diapositiva 7:\nConclusión y Cierre"]
```

---

### DIAPOSITIVA 1: Portada y Presentación del Equipo
* **Título:** Arquitectura Híbrida de Base de Datos: Incorporación de MongoDB en "Estilo Urbano".
* **Subtítulo:** Evaluación Parcial N° 3 — Taller de Base de Datos (BDY1103).
* **Integrantes:** Eduardo Aránguiz, Luciano Zaninovic, Kevin Urbina.
* **Profesor:** Cristian Medina.

> **🎙️ Lo que debes decir (Discurso):**  
> *"Buenos días profesor y compañeros. Hoy presentamos la tercera y última etapa de nuestro proyecto semestral para la tienda de ropa urbana 'Estilo Urbano'. En esta evaluación hemos evolucionado nuestra base de datos relacional de Oracle hacia una arquitectura híbrida de Persistencia Políglota, incorporando una base de datos NoSQL documental como MongoDB para resolver de forma óptima el catálogo dinámico de prendas, mientras mantenemos la rigurosidad financiera y legal en Oracle Database."*  
> **⏱️ Tiempo:** 45 segundos.

---

### DIAPOSITIVA 2: Contexto de Negocio y Datos a Procesar
* **El Problema en Estilo Urbano:**
  - El catálogo de streetwear creció con productos de atributos heterogéneos: un *Hoodie oversize* requiere gramaje y medidas de torso; unas *Zapatillas* requieren talla numérica y tipo de suela; un *Banano táctico* requiere capacidad en litros y tela impermeable.
  - En Oracle relacional, esto obligaba a tener decenas de columnas vacías o tablas intermedias lentas con múltiples `JOIN`.
  - El tráfico web es desbalanceado: existen **500 visitas de navegación por cada 1 orden de compra**.
* **Información Relevante a Generar:**
  - Fichas de producto enriquecidas con entrega en sub-segundos, filtros en tiempo real y contadores de venta atómicos.

> **🎙️ Lo que debes decir (Discurso):**  
> *"El problema de fondo que enfrentamos en 'Estilo Urbano' es que la moda urbana no se adapta a esquemas estáticos. Un polerón oversize tiene tabla de medidas en centímetros y gramaje de algodón, mientras que unas zapatillas tienen talla de calzado 41 y suela EVA. En Oracle, esto nos obligaba a llenar tablas con valores nulos o hacer múltiples JOINs que ralentizaban la navegación. Además, las métricas nos muestran que los clientes consultan 500 veces el catálogo por cada compra que realizan. Necesitábamos un motor especializado en lectura ágil y atributos dinámicos."*  
> **⏱️ Tiempo:** 1 minuto 15 segundos.

---

### DIAPOSITIVA 3: Principales Diferencias: Relacional (Oracle) vs No Relacional (MongoDB)
* **Comparativa Fundamental:**
  - **Oracle (Relacional):** Estructura en tablas con filas/columnas; *Schema-on-Write* estricto; integridad referencial automática con claves foráneas; consistencia ACID absoluta.
  - **MongoDB (NoSQL Documental):** Colecciones con documentos jerárquicos BSON; *Schema-on-Read* polimórfico; subdocumentos embebidos; lecturas atómicas en un solo viaje a disco (*Single round-trip*).
* **Criterio de Aplicabilidad en la Empresa:**
  - Oracle para nómina, sueldos, impuestos (IVA 19%) y pagos Webpay Plus.
  - MongoDB para el catálogo web y las opiniones de clientes.

> **🎙️ Lo que debes decir (Discurso):**  
> *"Las diferencias entre ambos mundos marcan su propósito en la empresa. Oracle trabaja con Schema-on-Write y transacciones ACID multi-tabla, lo que lo hace intocable para nuestras finanzas, contratos y pasarela Webpay. Por el contrario, MongoDB opera con Schema-on-Read y documentos BSON jerárquicos. En lugar de hacer JOINs entre cuatro tablas para mostrar una polera, MongoDB trae la foto, la descripción, las especificaciones técnicas y las tallas disponibles en una sola lectura a disco, reduciendo drásticamente la latencia en la tienda online."*  
> **⏱️ Tiempo:** 1 minuto 30 segundos.

---

### DIAPOSITIVA 4: Justificación Técnica con la Matriz de Decisión y Trade-Offs
* **Justificación de Negocio (2 Criterios con Datos del Caso):**
  1. *Polimorfismo de Atributos:* Cada prenda almacena únicamente sus especificaciones técnicas reales sin columnas huérfanas.
  2. *Lectura Intensiva (500:1):* Renderizado instantáneo de la ficha web en un solo viaje BSON.
  3. *"Es flexible" no basta:* La flexibilidad sin control genera inconsistencias. Solo se adopta donde la velocidad comercial supera a la normalización.
* **Lo que se Pierde frente a Oracle (Trade-Offs Explícitos):**
  - Sin integridad referencial automática (MongoDB no valida si un `id_proveedor` existe en otra colección).
  - Sin restricciones CHECK nativas del motor (como `stock >= 0` o `sueldo >= 500.000`).
  - Sin triggers transaccionales multiobjeto automáticos.

> **🎙️ Lo que debes decir (Discurso):**  
> *"Profesor, de acuerdo con lo visto en clase, justificar MongoDB diciendo simplemente que 'es flexible' no es suficiente. Nosotros aplicamos dos criterios de la matriz de decisión con datos reales de nuestro caso: primero, el polimorfismo de atributos para nuestras prendas streetwear; y segundo, el patrón de lectura intensiva de 500 visitas por cada venta. Ahora bien, como ingenieros reconocemos explícitamente lo que perdemos frente a Oracle: perdemos la integridad referencial automática, las restricciones CHECK en el motor y los triggers transaccionales multi-tabla. Por esa razón no migramos todo a MongoDB; construimos una arquitectura híbrida donde cada motor hace lo que mejor sabe hacer."*  
> **⏱️ Tiempo:** 1 minuto 45 segundos.

---

### DIAPOSITIVA 5: Modelamiento Documental: Matriz de las 4 Preguntas
* **Aplicación de las 4 Preguntas Oficiales:**
  - *Producto ➔ Tallas y Stock:* ¿Se leen juntos? SÍ. ¿Se comparten? NO. ¿Cambian solos? NO. ¿Crecen sin fin? NO (máx 6 tallas). ➔ **EMBEBER (Embedding)** en arreglo de subdocumentos.
  - *Producto ➔ Especificaciones:* ¿Se leen juntos? SÍ. ¿Se comparten? NO. ¿Cambian solos? NO. ¿Crecen sin fin? NO (3-5 campos). ➔ **EMBEBER (Embedding)** en subdocumento.
  - *Producto ➔ Proveedor:* ¿Se leen juntos en web? NO. ¿Se comparten? SÍ (muchas prendas por taller). ¿Cambian solos? SÍ. ➔ **REFERENCIA EXTENDIDA** (`id_proveedor_oracle` + `razon_social`).
  - *Producto ➔ Reseñas:* ¿Crecen sin límite? SÍ (riesgo de superar 16 MB). ➔ **REFERENCIAR** en colección externa.

> **🎙️ Lo que debes decir (Discurso):**  
> *"Para diseñar el documento BSON aplicamos rigurosamente la tabla de las 4 preguntas de la asignatura. Para las tallas y especificaciones de la prenda, como siempre se leen juntas, no se comparten y no crecen sin límite, decidimos EMBEBERLAS. Esto nos permite pintar los botones de tallas en el frontend sin consultas adicionales. Para el proveedor aplicamos el patrón de Referencia Extendida: guardamos el ID de Oracle y la razón social para consultar rápido sin duplicar todo el contacto. Y para las reseñas decidimos referenciarlas en una colección separada para evitar que un producto viral rompa el límite físico de 16 megabytes por documento."*  
> **⏱️ Tiempo:** 1 minuto 30 segundos.

---

### DIAPOSITIVA 6: Operaciones CRUD en MongoDB (Contexto Real)
* **CREATE:**
  - `insertOne`: Alta de prenda individual con tallas embebidas (`Hoodie Acid Wash`).
  - `insertMany`: Publicación masiva de nueva colección de temporada.
* **READ:**
  - `find`: Filtro compuesto por categoría y precio (`db.productos.find({ categoria: 'Hoodies', precio: { $lt: 45000 } })`).
  - `findOne`: Carga de ficha técnica exacta por código SKU.
* **UPDATE ($set y $inc):**
  - `$set`: Rebaja de precio puntual o cambio de descripción.
  - `$inc`: **Descuento atómico de stock e incremento de visitas** tras una venta, sin leer previamente el valor en memoria (elimina condiciones de carrera).
* **DELETE vs BORRADO LÓGICO:**
  - `deleteOne` y `deleteMany`: Solo para limpiar datos temporales de prueba.
  - **Borrado Lógico con `$set` (Política Obligatoria):** En retail real jamás se borra físicamente una prenda vendida; se marca como `{ estado: 'descontinuado', fecha_baja: ISODate() }` para preservar la trazabilidad histórica de pedidos en Oracle.

> **🎙️ Lo que debes decir (Discurso):**  
> *"En el archivo '05_mongodb_estilo_urbano.js' implementamos el CRUD completo sin agregaciones ni índices, tal como lo exige el alcance del curso. Destacamos en el Update el uso del operador atómico $inc, que nos permite descontar stock en el servidor al momento de la compra sin riesgo de condiciones de carrera. Y en cuanto a la eliminación, justificamos que el borrado físico solo se usa para datos temporales de prueba; en el negocio real aplicamos borrado lógico con $set pasando el producto a estado 'descontinuado', porque si borráramos el documento físicamente romperíamos la trazabilidad de las ventas históricas que están registradas en Oracle."*  
> **⏱️ Tiempo:** 1 minuto 45 segundos.

---

### DIAPOSITIVA 7: Conclusiones y Demostración Práctica
* **Conclusiones Principales:**
  - Coexistencia exitosa: Persistencia Políglota estándar de la industria.
  - Oracle mantiene la solvencia y cumplimiento legal chileno; MongoDB entrega agilidad al catálogo y navegación web.
  - Modelado formal sostenido en requerimientos y patrones de acceso.
* **Paso a Demostración:**
  - Ejecución en vivo del script `05_mongodb_estilo_urbano.js` en mongosh / MongoDB Compass.

> **🎙️ Lo que debes decir (Discurso):**  
> *"En conclusión, la integración de MongoDB demostró que la persistencia políglota no es una moda, sino una necesidad de ingeniería cuando el volumen y la heterogeneidad de los datos lo exigen. Logramos una tienda con catálogo ultra-rápido y flexible sin arriesgar ni un solo peso de nuestra contabilidad en Oracle. A continuación, demostraremos en vivo la ejecución de nuestro script en MongoDB Compass y mongosh. Muchas gracias y quedamos atentos a sus preguntas."*  
> **⏱️ Tiempo:** 45 segundos.

---

## ❓ BANCO DE PREGUNTAS DEL PROFESOR CRISTIAN MEDINA (CON RESPUESTAS EXACTAS)

1. **¿Cómo se comunican Oracle y MongoDB si están en motores distintos?**
   > *"Profesor, se enlazan mediante identificadores estables de negocio: en MongoDB cada producto tiene el atributo `codigo_oracle: 201`. Cuando el cliente pulsa pagar en la web, el backend toma ese ID y crea la transacción en Oracle en las tablas `PEDIDO` y `DETALLE_PEDIDO`. Una vez que el pago Webpay se confirma con éxito en Oracle, el backend envía un comando `$inc: { unidades_vendidas: 1, stock: -1 }` a MongoDB para mantener el catálogo sincronizado."*

2. **¿Por qué no guardaron las reseñas embebidas dentro del producto si se leen juntas?**
   > *"Por el riesgo de crecimiento desmedido o 'Unbounded Growth'. Aunque se leen juntas en la interfaz, un producto exitoso puede acumular 50.000 comentarios con fotos. Si las embebiéramos, el documento superaría el límite de 16 MB que impone el formato BSON en MongoDB y la base de datos rechazaría las escrituras."*

3. **¿Cuál es la diferencia entre usar $set y asignar el documento completo en un update?**
   > *"Si hacemos un reemplazo sin `$set`, MongoDB sobreescribe todo el documento eliminando los campos que no incluyamos. El operador `$set` modifica exclusivamente los campos especificados (por ejemplo el precio o el estado) dejando intactas las especificaciones técnicas y las tallas embebidas."*

4. **¿Por qué usaron $inc en vez de hacer un find, restarle 1 al stock en JavaScript y luego hacer un $set?**
   > *"Porque hacerlo en dos pasos desde JavaScript genera una condición de carrera (Race Condition) si dos clientes compran la última prenda al mismo segundo. El operador `$inc` es una operación atómica que ejecuta el motor directamente en memoria en el servidor, garantizando que el contador se actualice de forma segura sin lecturas previas."*
