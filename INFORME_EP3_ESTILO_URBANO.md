# DUOC UC — ESCUELA DE INFORMÁTICA Y TELECOMUNICACIONES
## INGENIERÍA EN INFORMÁTICA / ANALISTA PROGRAMADOR
### BDY1103: TALLER DE BASE DE DATOS

---

# INFORME TÉCNICO: ARQUITECTURA HÍBRIDA DE BASE DE DATOS
## INCORPORACIÓN DE BASE DE DATOS DOCUMENTAL (MONGODB) AL E-COMMERCE "ESTILO URBANO"

```
                              DuocUC
               Escuela de Informática y Telecomunicaciones

                                INFORME:
     ARQUITECTURA HÍBRIDA DE BASE DE DATOS EN EL COMERCIO ELECTRÓNICO
                    CASO DE ESTUDIO: "ESTILO URBANO"

           Alumnos: Eduardo Aránguiz Armijo
                    Luciano Zaninovic
                    Kevin Urbina
           Profesor: Carlos Enrique Quintanilla Galleguillos
           Asignatura: BDY1103 - Taller de Base de Datos
           Semestre: Cuarto Semestre (2026)
           Fecha: Noviembre de 2026
```

---

## ÍNDICE GENERAL

1. [INTRODUCCIÓN](#1-introducción)
   - 1.1 Contexto y Evolución del Proyecto
   - 1.2 Objetivo General
   - 1.3 Objetivos Específicos
2. [MARCO CONCEPTUAL: MODELO RELACIONAL VS. MODELO NO RELACIONAL](#2-marco-conceptual-modelo-relacional-vs-modelo-no-relacional)
   - 2.1 Modelo Relacional (SQL / Oracle Database)
   - 2.2 Modelo No Relacional Basado en Documentos (NoSQL / MongoDB)
   - 2.3 Cuadro Comparativo de Diferencias Fundamentales
3. [JUSTIFICACIÓN DE LA ARQUITECTURA HÍBRIDA Y ELECCIÓN DE MONGODB](#3-justificación-de-la-arquitectura-híbrida-y-elección-de-mongodb)
   - 3.1 Criterios de la Matriz de Decisión Aplicados a "Estilo Urbano"
   - 3.2 ¿Por qué "Es flexible" por sí solo no basta?
   - 3.3 Lo que se Gana con MongoDB
   - 3.4 Lo que se Pierde frente a Oracle Database (Trade-Offs Explícitos)
4. [DIVISIÓN DE RESPONSABILIDADES: ORACLE VS. MONGODB](#4-división-de-responsabilidades-oracle-vs-mongodb)
   - 4.1 Qué se Mantiene en Oracle Database
   - 4.2 Qué se Migra a MongoDB
   - 4.3 Estrategia de Enlace e Interoperabilidad entre Ambos Motores
   - 4.4 Justificación Técnica: ¿Por qué MongoDB asume el Catálogo y NO las Finanzas/Nómina?
   - 4.5 Justificación bajo Metodología 3NF: ¿Por qué Oracle hace Finanzas/RRHH y NO el Catálogo?
   - 4.6 Caso Crítico de Negocio: ¿Por qué NUNCA Gestionar Empleados, Sueldos y Nómina en MongoDB?
   - 4.7 Articulación Arquitectónica bajo el Marco Ágil Scrum
5. [MODELAMIENTO DOCUMENTAL Y MATRIZ DE LAS 4 PREGUNTAS](#5-modelamiento-documental-y-matriz-de-las-4-preguntas)
   - 5.1 Metodología de las 4 Preguntas
   - 5.2 Análisis de Relaciones de Negocio en "Estilo Urbano"
   - 5.3 Estructura del Documento Final JSON/BSON
6. [IMPLEMENTACIÓN TÉCNICA DEL CRUD EN MONGODB (CONTEXTO REAL)](#6-implementación-técnica-del-crud-en-mongodb-contexto-real)
   - 6.1 Operación CREATE (`insertOne` y `insertMany`)
   - 6.2 Operación READ (`find` y `findOne`)
   - 6.3 Operación UPDATE (`$set`, `$inc`, `updateOne` y `updateMany`)
   - 6.4 Operación DELETE (`deleteOne`, `deleteMany` y Borrado Lógico con `$set`)
7. [EVALUACIÓN CRÍTICA: VENTAJAS Y DESVENTAJAS DE MONGODB](#7-evaluación-crítica-ventajas-y-desventajas-de-mongodb)
   - 7.1 Ventajas Competitivas en la Empresa
   - 7.2 Desventajas y Riesgos Operacionales
8. [CONCLUSIONES](#8-conclusiones)
9. [REFERENCIAS BIBLIOGRÁFICAS (FORMATO APA)](#9-referencias-bibliográficas-formato-apa)

---

## 1. INTRODUCCIÓN

### 1.1 Contexto y Evolución del Proyecto
La plataforma de comercio electrónico **"Estilo Urbano"** nació con el propósito de comercializar vestuario y calzado streetwear orientado a un público juvenil en Chile. En las fases anteriores (EP1 y EP2), el sistema fue soportado íntegramente por un motor relacional **Oracle Database 21c/23ai** (Oracle Corporation, 2024a), resolviendo con éxito la consistencia financiera, el cálculo de comisiones, el control de nómina y los disparadores de solvencia mediante programación procedural avanzada en PL/SQL (Oracle Corporation, 2024b).

No obstante, al expandir la tienda hacia la venta masiva multicanal, surgieron importantes desafíos técnicos:
1. **Heterogeneidad de atributos en el catálogo:** Las prendas streetwear poseen especificaciones incompatibles entre sí (tablas de medidas en centímetros para polerones oversize, tallas numéricas 39-44 y material de suela para zapatillas, y capacidad en litros para accesorios tácticos). En Oracle, esto exigía decenas de columnas con valores nulos o un modelo *Entity-Attribute-Value (EAV)* ineficiente.
2. **Desbalance extremo entre lectura y escritura:** En el retail digital, por cada compra finalizada (escritura en Oracle), existen más de 500 consultas de navegación de catálogo (lecturas concurrentes). Ejecutar consultas con múltiples `JOIN` relacionales para renderizar cada ficha de producto degrada el rendimiento de la base de datos principal.

Por estos motivos, se determinó transformar la solución en una **Arquitectura Híbrida de Persistencia Políglota** (Fowler & Sadalage, 2012), delegando el catálogo dinámico de prendas a **MongoDB Server y MongoDB Compass** (MongoDB Inc., 2026a, 2026b) y conservando el núcleo financiero, fiscal y de remuneraciones en **Oracle Database** (Oracle Corporation, 2024a).

### 1.2 Objetivo General
Diseñar e implementar una arquitectura de datos híbrida para el e-commerce "Estilo Urbano", integrando una base de datos NoSQL documental (MongoDB) para la gestión ágil del catálogo de productos y desacoplando dicha carga del motor relacional transaccional (Oracle Database).

### 1.3 Objetivos Específicos
1. Comparar técnicamente los paradigmas relacional y no relacional, identificando fortalezas, debilidades y compensaciones (*trade-offs*) (Codd, 1970; Fowler & Sadalage, 2012).
2. Justificar la adopción de MongoDB mediante criterios formales de la matriz de decisión aplicados al caso real de streetwear (MongoDB Inc., 2026c).
3. Modelar la colección `productos` utilizando la matriz de las 4 preguntas para decidir fundamentadamente entre embeber, referenciar o usar referencia extendida (MongoDB Inc., 2026c).
4. Desarrollar las operaciones fundamentales de manipulación de datos (CRUD) en MongoDB cumpliendo con las políticas de negocio y diferenciando el borrado físico del borrado lógico (MongoDB Inc., 2026a, 2026c).

---

## 2. MARCO CONCEPTUAL: MODELO RELACIONAL VS. MODELO NO RELACIONAL

### 2.1 Modelo Relacional (SQL / Oracle Database)
El modelo relacional, propuesto formalmente por Edgar F. Codd en 1970, organiza la información en tablas bidimensionales compuestas por filas (tuplas) y columnas (atributos) (Codd, 1970). Su pilar fundamental es la normalización (1FN a BCNF), diseñada para eliminar redundancias y garantizar la consistencia absoluta de los datos.

* **Propiedades ACID:** Atomicidad, Consistencia, Aislamiento (*Isolation*) y Durabilidad (Oracle Corporation, 2024a).
* **Esquema Estricto (*Schema-on-Write*):** La estructura de las tablas, tipos de datos, restricciones `CHECK`, `NOT NULL` y claves foráneas deben definirse rigurosamente antes de insertar el primer registro.

### 2.2 Modelo No Relacional Basado en Documentos (NoSQL / MongoDB)
El paradigma NoSQL documental almacena la información en unidades autocontenidas denominadas **documentos BSON** (Binary JSON), agrupados dentro de **colecciones** (MongoDB Inc., 2026c). En este modelo, los datos que se consultan juntos se almacenan juntos (Fowler & Sadalage, 2012).

* **Esquema Dinámico (*Schema-on-Read* / Polimórfico):** Diferentes documentos dentro de una misma colección pueden poseer atributos y estructuras anidadas distintas según su naturaleza.
* **Teorema CAP:** MongoDB prioriza típicamente la Consistencia y la Tolerancia al Particionamiento (CP), ofreciendo alta disponibilidad y particionamiento horizontal nativo (*sharding*) (Fowler & Sadalage, 2012).

### 2.3 Cuadro Comparativo de Diferencias Fundamentales

| Dimensión de Comparación | Oracle Database (Relacional) | MongoDB (NoSQL Documental) |
| :--- | :--- | :--- |
| **Estructura de Almacenamiento** | Tablas, Filas y Columnas normalizadas. | Colecciones y Documentos jerárquicos BSON/JSON. |
| **Definición de Esquema** | Estático y rígido (*Schema-on-Write* con DDL). | Dinámico y flexible (*Schema-on-Read*). |
| **Relaciones entre Entidades** | Claves Foráneas (`FOREIGN KEY`) con comprobación estricta en el motor. | Documentos embebidos (subdocumentos/arreglos) o referencias manuales (`_id`). |
| **Operaciones de Lectura** | Requiere sentencias `JOIN` para recombinar tablas normalizadas. | Lectura atómica de documentos completos en un solo viaje a disco (*Single round-trip*). |
| **Transaccionalidad** | Garantía ACID implacable a nivel multi-tabla por defecto. | ACID a nivel de documento único; transacciones multi-documento con mayor sobrecarga. |
| **Mecanismo de Escalabilidad** | Predominantemente vertical (*Scale-Up*: más CPU y RAM). | Horizontal nativo (*Scale-Out*: distribución mediante *Sharding*). |
| **Reglas de Integridad** | Disparadores (`TRIGGERS`), restricciones `CHECK` y `UNIQUE` en el motor. | Validación delegada a la capa de aplicación o mediante validadores JSON Schema. |

*Fuente: Elaboración propia basado en Codd (1970), Fowler y Sadalage (2012), MongoDB Inc. (2026c) y Duoc UC (2026).*

---

## 3. JUSTIFICACIÓN DE LA ARQUITECTURA HÍBRIDA Y ELECCIÓN DE MONGODB

### 3.1 Criterios de la Matriz de Decisión Aplicados a "Estilo Urbano"
Para seleccionar qué tecnología utilizar, no basta con decir que *"MongoDB es rápido y moderno"*. En la ingeniería de software profesional y de acuerdo a los criterios de validación docente de Duoc UC, la decisión debe sostenerse sobre datos concretos del caso de negocio:

```mermaid
flowchart TD
    Req["Requerimientos de Negocio en Estilo Urbano"]
    Req --> C1["Criterio 1:\nPolimorfismo y Variabilidad de Atributos"]
    Req --> C2["Criterio 2:\nPatrón de Acceso de Lectura Intensiva"]
    
    C1 --> Mongo["Adopción de MongoDB\n(Catálogo de Streetwear y Reseñas)"]
    C2 --> Mongo
    
    Req --> C3["Criterio 3:\nIntegridad Fiscal, Nómina y Auditoría"]
    C3 --> Oracle["Permanencia en Oracle Database\n(Pedidos, Facturación, Sueldos)"]
```

#### Criterio 1: Polimorfismo y Heterogeneidad de Atributos del Streetwear
* **Dato del Caso:** En "Estilo Urbano" se comercializan 5 categorías radicalmente diferentes:
  1. *Hoodies Oversize:* Requieren campos como gramaje de algodón (GSM), tabla de medidas en centímetros (pecho, largo, hombro) y tipo de capucha.
  2. *Sneakers:* Requieren talla de calzado numérica chilena (39 a 44), tipo de suela (goma EVA vulcanizada) y caña (High/Mid/Low).
  3. *Bananos y Accesorios:* Requieren capacidad en litros (3.5 L), material impermeable (Cordura 1000D) y cantidad de compartimientos.
* **Impacto Técnico:** En Oracle, obligaba a crear una tabla `PRODUCTO` con decenas de columnas vacías o implementar un modelo EAV (*Entity-Attribute-Value*) que requiere múltiples `JOIN` para reconstruir una sola prenda. En MongoDB, cada producto es un documento JSON que contiene únicamente los atributos pertinentes bajo el campo embebido `especificaciones`.

#### Criterio 2: Patrón de Acceso Lectura-Intensiva (*Read-Heavy Workload*)
* **Dato del Caso:** La métrica de tráfico del e-commerce muestra que existen **500 visitas al catálogo por cada 1 orden de compra confirmada**.
* **Impacto Técnico:** En Oracle, mostrar la página principal o la ficha de un producto demandaba ejecutar un `JOIN` entre `PRODUCTO`, `CATEGORIA`, `PROVEEDOR` y una tabla auxiliar de tallas. En MongoDB, el documento del producto se obtiene mediante una única búsqueda por clave primaria (`_id` o `sku`), trayendo imágenes, especificaciones técnicas y tallas disponibles en una sola operación de E/S.

### 3.2 ¿Por qué "Es flexible" por sí solo no basta?
Afirmar únicamente que *"MongoDB es flexible"* es un argumento insuficiente porque:
1. La flexibilidad sin disciplina conduce al caos de datos: si cada desarrollador guarda nombres de atributos distintos (`precio`, `costo`, `valor_venta`), la aplicación falla.
2. Si un problema de negocio requiere consistencia financiera estricta (como el balance de ventas contra sueldos en la EP2), la flexibilidad de MongoDB se convierte en una debilidad al no forzar tipos ni restricciones `CHECK` en el motor de forma nativa.

Por ello, MongoDB se justifica únicamente en las áreas de la empresa donde la **variabilidad del catálogo** y la **velocidad de lectura** superan la necesidad de relaciones normalizadas.

### 3.3 Lo que se Gana con MongoDB
1. **Velocidad de Renderizado Web:** El frontend en JavaScript consume directamente el formato BSON/JSON devuelto por MongoDB, sin transformaciones complejas en el backend.
2. **Evolución sin Migraciones DDL Invasivas:** Si la marca lanza una nueva línea de chaquetas con "resistencia térmica en grados Celsius", el atributo se añade inmediatamente al nuevo documento sin ejecutar `ALTER TABLE` que bloquee la tabla productiva.
3. **Escalabilidad Horizontal:** Capacidad de fragmentar (*sharding*) el catálogo por categoría o región geográfica en múltiples servidores económicos.

### 3.4 Lo que se Pierde frente a Oracle Database (Trade-Offs Explícitos)

> [!WARNING]
> La adopción de MongoDB implica renunciar conscientemente a varias garantías que Oracle ofrece por defecto:
>
> 1. **Pérdida de Integridad Referencial Automática:** MongoDB no valida que un `id_proveedor` o un `id_usuario` referenciado exista realmente. Si una aplicación inserta un producto asignado al proveedor inexistente `9999`, MongoDB lo registrará sin advertencia.
> 2. **Pérdida de Restricciones CHECK Nativas del Motor:** Restricciones como `sueldo_base >= 500000` o `stock_actual >= 0` deben ser garantizadas por la aplicación o mediante validadores JSON Schema adicionales.
> 3. **Ausencia de Triggers Transaccionales Multiobjeto:** No existen disparadores automáticos nativos que comparen tablas distintas al instante (como el trigger `trg_valida_solvencia_sueldos` de Oracle que calcula la nómina contra las ventas).
> 4. **Consistencia Eventual:** En entornos distribuidos con varios nodos, las lecturas secundarias pueden entregar datos ligeramente desfasados frente a la escritura principal.

---

## 4. DIVISIÓN DE RESPONSABILIDADES: ORACLE VS. MONGODB

La solución implementa una **Arquitectura Híbrida** en la cual cada base de datos atiende exclusivamente el dominio para el cual fue diseñada:

```mermaid
flowchart LR
    Client["Cliente / Tienda Web\n(GitHub Pages)"]
    
    subgraph NoSQL ["Capa NoSQL: MongoDB (Velocidad & Catálogo)"]
        MongoCatalog[("Colección: productos\n- Ropa Streetwear\n- Tallas y Stock Operativo\n- Atributos Dinámicos\n- Especificaciones")]
        MongoReviews[("Colección: resenas\n- Comentarios de Clientes\n- Calificación 1-5 estrellas")]
    end
    
    subgraph Relacional ["Capa SQL: Oracle Database (Gobernanza & Finanzas)"]
        OraUsers[("Tabla: USUARIO\n- Cuentas y Roles\n- Sueldos RRHH y Metas")]
        OraOrders[("Tabla: PEDIDO / DETALLE\n- Folio Legal Webpay\n- Facturación con IVA 19%")]
        OraAudit[("Tablas: AUDITORIA / TRACKING\n- Disparadores Triggers\n- Reglas de Solvencia")]
    end
    
    Client -->|1. Navegación y Filtros (Lectura Rápida)| MongoCatalog
    Client -->|2. Reseñas y Opiniones| MongoReviews
    Client -->|3. Checkout y Pago Seguro Webpay| OraOrders
    
    OraOrders -.->|Enlace mediante id_producto / sku| MongoCatalog
    OraUsers -.->|Enlace mediante id_usuario_oracle| MongoReviews
```

### 4.1 Qué se Mantiene en Oracle Database
* **Módulo de Recursos Humanos y Nómina (`USUARIO`, `ROL`):** Datos contractuales, sueldos base, metas de venta y auditoría de cambios salariales (`AUDITORIA_SUELDO_EMPLEADO`).
* **Módulo Financiero y Facturación (`PEDIDO`, `DETALLE_PEDIDO`):** Transacciones bancarias formalizadas con Webpay Plus, cálculo de IVA (19%), totales en CLP y números de folio tributario inmutables.
* **Gobernanza y Disparadores (`TRIGGERS` y `PACKAGE`):** Validación preventiva de sueldo mínimo legal ($500.000) y control de solvencia financiera (nómina de sueldos no puede superar las ventas totales de la empresa).

### 4.2 Qué se Migra a MongoDB
* **Catálogo de Prendas y Variantes (`productos`):** Títulos, descripciones comerciales, fotografías, atributos específicos (corte, gramaje, tejido) y variantes de tallas con stock operativo para compra rápida.
* **Interacciones y Reseñas (`resenas`):** Calificaciones por estrellas (1 a 5), opiniones de clientes y fotografías de compradores usando las prendas.

### 4.3 Estrategia de Enlace e Interoperabilidad entre Ambos Motores
Para garantizar la comunicación entre ambos mundos sin duplicar información sensible:
1. **Identificadores Numéricos Compartidos:** Cada documento de la colección `productos` en MongoDB incluye el campo `codigo_oracle: 201`, correspondiente a la clave primaria `id_producto` en la tabla `PRODUCTO` de Oracle.
2. **Flujo de Venta Desacoplado:**
   - El cliente navega y añade ítems al carrito desde **MongoDB**.
   - Al pulsar "Pagar con Webpay", el backend toma los `codigo_oracle` y registra la orden en la tabla `PEDIDO` de **Oracle Database** con plena garantía transaccional ACID.
   - Tras confirmarse el pago en Oracle, se ejecuta una instrucción `$inc` en MongoDB para decrementar el stock operativo en la colección `productos`.

### 4.4 Justificación Técnica: ¿Por qué MongoDB asume el Catálogo y NO las Finanzas/Nómina?
La asignación de responsabilidades a MongoDB responde a dos pilares técnicos irremplazables, así como a la prevención deliberada de riesgos operacionales:

1. **Lo que SÍ hace MongoDB y su Justificación:**
   - **Polimorfismo Real de Atributos:** En el streetwear juvenil, cada tipología de vestuario posee especificaciones incompatibles (polerones oversize con gramaje de algodón 400 GSM y corte boxy; zapatillas con suela de caucho vulcanizado y amortiguación de aire; bananos tácticos con capacidad en litros). En MongoDB, cada documento almacena únicamente sus propios atributos en el subdocumento embebido `especificaciones`, evitando el anti-patrón relacional EAV (*Entity-Attribute-Value*) o tablas dispersas llenas de valores nulos (MongoDB Inc., 2026c).
   - **Desbalance Extremo de Accesos (Patrón 500:1):** En el comercio electrónico masivo, se registran más de 500 consultas de navegación de catálogo por cada transacción finalizada. Al incrustar el arreglo `tallas_disponibles` con stock dentro del documento del producto, una sola lectura en memoria resuelve toda la ficha técnica de la prenda sin ejecutar `JOINs` (Fowler & Sadalage, 2012).
2. **Lo que NO debe hacer MongoDB (Riesgos Evitados en Finanzas y Nómina):**
   - **Pérdida de Integridad Referencial Declarativa:** MongoDB no provee restricciones nativas de clave foránea (`FOREIGN KEY`) ni chequeos declarativos a nivel de motor. Si la facturación se alojara en NoSQL, cualquier anomalía o bug en el código de backend podría originar boletas huérfanas o registros contables sin cliente.
   - **Riesgo de Inconsistencia en Fondos y Remuneraciones:** Las transacciones financieras y el pago de salarios exigen aislamiento estricto y atomicidad pura. La consistencia eventual (*Eventual Consistency*) es inaceptable para contratos laborales o cálculo del IVA (19%) fiscalizable ante el Servicio de Impuestos Internos (SII) (Codd, 1970; Fowler & Sadalage, 2012).
   - **Inexistencia de Disparadores Multiobjeto para Solvencia:** MongoDB no dispone de triggers transaccionales nativos para abortar una transacción global si la suma de la nómina supera las ventas de la empresa (Oracle Corporation, 2024b).

### 4.5 Justificación bajo Metodología 3NF: ¿Por qué Oracle hace Finanzas/RRHH y NO el Catálogo?
El modelo relacional en Oracle Database 21c/23ai (Oracle Corporation, 2024a) fue normalizado estrictamente hasta la **Tercera Forma Normal (3NF)** (Codd, 1970):

1. **Lo que SÍ hace Oracle Database bajo 3NF:**
   - **Dependencia Funcional Estricta de la Clave:** En 3NF, todo atributo no clave depende de forma directa, completa y exclusiva de la clave primaria (sin dependencias transitivas) (Codd, 1970).
     - En `ORDEN_COMPRA` y `DETALLE_ORDEN`, el precio unitario histórico de venta queda congelado e inmutable asociado al folio de compra, sin depender de futuras modificaciones de precio en el catálogo.
     - En `USUARIO`, `TIPO_USUARIO` y salarios, la remuneración contractual y metas dependen directamente de la cédula/ID del empleado, garantizando que un cambio en la definición de un cargo no altere transitivamente el contrato del trabajador.
   - **Eliminación Absoluta de Anomalías:** La 3NF erradica anomalías de inserción (imposible registrar un cobro sin cliente y folio legal válido), anomalías de actualización (modificar un valor no corrompe balances contables de meses anteriores) y anomalías de borrado (eliminar transacciones operativas no destruye el registro histórico tributario del IVA) (Codd, 1970).
   - **Gobernanza mediante Triggers PL/SQL:** El motor valida de forma preventiva el sueldo mínimo legal ($500.000), evalúa la solvencia presupuestaria frente a ventas totales y registra cada modificación salarial en `AUDITORIA_SUELDO_EMPLEADO` (Oracle Corporation, 2024b).
2. **Lo que NO debe hacer Oracle Database (Problemas Evitados en el Catálogo):**
   - **Degeneración del Esquema por Atributos Volátiles:** Forzar la normalización en 3NF para ropa streetwear exige crear múltiples tablas puente (`PRODUCTO_ATRIBUTO`, `VALORES_TALLA`), complejizando las consultas con múltiples `JOINs`.
   - **Saturación del Pool de Conexiones:** En eventos de alto tráfico (como CyberDay), miles de usuarios consultando la vitrina saturarían los procesos dedicados de Oracle, bloqueando las conexiones de los usuarios que intentan procesar su pago en Webpay (Fowler & Sadalage, 2012).

### 4.6 Caso Crítico de Negocio: ¿Por qué NUNCA Gestionar Empleados, Sueldos y Nómina en MongoDB?
Una de las decisiones arquitectónicas fundamentales y de mayor impacto en "Estilo Urbano" fue prohibir explícitamente la gestión de recursos humanos, sueldos y contratos en MongoDB, manteniéndolos en Oracle bajo control PL/SQL (Oracle Corporation, 2024b). Esta decisión se fundamenta en cuatro pilares técnicos y de cumplimiento legal en Chile:

1. **Ausencia de Triggers Transaccionales Síncronos (Gobernanza Preventiva):**  
   En Oracle SQL, el motor ejecuta disparadores `BEFORE UPDATE` como `trg_valida_sueldo_minimo` y `trg_valida_solvencia_sueldos` (Oracle Corporation, 2024b). Si un usuario intenta asignar una remuneración inferior al mínimo legal ($500.000) o si un incremento salarial hace que la nómina total supere las ventas de la empresa, Oracle aborta la operación directamente en el motor mediante `RAISE_APPLICATION_ERROR`. En MongoDB no existen triggers nativos síncronos dentro del motor de base de datos (MongoDB Inc., 2026c); cualquier error de validación en la capa web o una modificación manual descuidada desde la consola mongosh o MongoDB Compass (MongoDB Inc., 2026a, 2026b) escribiría un sueldo de $1 o cifras ilegales sin ningún bloqueo a nivel de almacenamiento.

2. **Exigencia Legal de Auditoría Inmutable (Inspección del Trabajo):**  
   La legislación laboral chilena y las normas de auditoría de RRHH exigen trazabilidad absoluta de cada modificación en las remuneraciones de los trabajadores. En Oracle, el trigger de auditoría inserta de manera automática, atómica e ineludible en la tabla `AUDITORIA_SUELDO_EMPLEADO` el sueldo anterior, el sueldo nuevo, el usuario que efectuó el cambio y la marca de tiempo (`TIMESTAMP`) (Oracle Corporation, 2024b). Nadie puede saltarse este registro. En MongoDB, la auditoría dependería de que el desarrollador recuerde escribir código de log en la aplicación; cualquier actualización directa a la base de datos no dejaría rastro, invalidando la posición de la empresa ante fiscalizaciones laborales o juicios contractuales.

3. **Integridad Referencial Estricta (`FOREIGN KEY`) vs. Datos Huérfanos:**  
   Bajo la Tercera Forma Normal (3NF) de Oracle (Codd, 1970), la tabla `USUARIO` está formalmente vinculada a `TIPO_USUARIO` (Rol) mediante una clave foránea forzada por el motor. Es físicamente imposible registrar un empleado con un rol inexistente o eliminar un cargo que tenga trabajadores asignados. En MongoDB, al no existir integridad foránea mandatoria, un error tipográfico en un documento (`{"rol": "SuperVendedr"}`) generaría registros corruptos y desajustes en la jerarquía administrativa.

4. **Transaccionalidad ACID Pura frente al Dinero Real:**  
   El catálogo de ropa admite consistencia eventual sin riesgo alguno para la empresa (que una foto tarde unos milisegundos en refrescarse no perjudica a nadie) (Fowler & Sadalage, 2012). En contraste, los salarios de las personas, las leyes sociales (AFP, Fonasa/Isapre) y las retenciones tributarias del SII exigen propiedades ACID inmediatas y absolutas. No se pueden permitir lecturas sucias (*dirty reads*) ni actualizaciones concurrentes ambiguas cuando se procesa la planilla mensual de pago de remuneraciones.

### 4.7 Articulación Arquitectónica bajo el Marco Ágil Scrum
En el ciclo de desarrollo bajo la metodología **Scrum**, el Product Backlog del proyecto se descompuso estratégicamente separando los requerimientos por dominio de negocio:

* **Sprint 1 & 2 — Núcleo Financiero, Legal y Administrativo (Oracle PL/SQL en 3NF):**
  - *User Stories:* Gestión de nómina, control preventivo de sueldo mínimo legal, cálculo de solvencia financiera de la empresa y emisión de órdenes transaccionales.
  - *Criterio de Aceptación (Definition of Done):* Cumplimiento estricto de 3NF, integridad referencial con claves foráneas activas y disparadores de auditoría validados.
* **Sprint 3 — Catálogo de Moda Urbana, Experiencia de Usuario y Escalabilidad (MongoDB NoSQL):**
  - *User Stories:* Fichas dinámicas de vestuario con especificaciones de tejido, tabla de medidas en centímetros, selección de tallas en tiempo real y módulo de reseñas de compradores.
  - *Criterio de Aceptación (Definition of Done):* Tiempos de respuesta inferiores a 100 ms en navegación, esquema BSON flexible que admite nuevas colecciones sin migraciones DDL de base de datos y enlace bidireccional por `codigo_oracle`.

---

## 5. MODELAMIENTO DOCUMENTAL Y MATRIZ DE LAS 4 PREGUNTAS

### 5.1 Metodología de las 4 Preguntas
Para decidir con rigurosidad académica si los datos relacionados deben **Embeberse (*Embedding*)**, **Referenciarse (*Referencing*)** o utilizar el **Patrón de Referencia Extendida (*Extended Reference*)**, se aplican las 4 preguntas oficiales del modelado en MongoDB (MongoDB Inc., 2026c):

1. **¿Se leen juntos la gran mayoría de las veces?**
2. **¿Se comparten con otros documentos de la base de datos?**
3. **¿Tienen un ciclo de vida propio e independiente?**
4. **¿Crecen sin límite predecible (*Unbounded Growth*) superando los 16 MB por documento?**

### 5.2 Análisis de Relaciones de Negocio en "Estilo Urbano"

| Relación Analizada | 1. ¿Se leen juntos? | 2. ¿Se comparten? | 3. ¿Cambian por su cuenta? | 4. ¿Crecen sin límite? | Decisión de Diseño | Justificación Técnica |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Producto ➔ Variantes de Tallas y Stock** | **SÍ** (Siempre que se ve una polera se necesita saber si hay S, M o L). | **NO** (El stock de una talla le pertenece únicamente a ese modelo). | **NO** (Se modifican cuando se gestiona la prenda). | **NO** (Una prenda streetwear tiene máximo 5 a 6 tallas). | **EMBEBER (Embedding)** | Se incrusta un arreglo de subdocumentos `tallas_disponibles` dentro del producto. Maximiza el rendimiento de lectura. |
| **Producto ➔ Especificaciones Técnicas (Material, Corte, GSM)** | **SÍ** (Se exhiben en la ficha técnica para el comprador). | **NO** (Son exclusivas de cada tipo de prenda). | **NO** (Nacen y mueren con el producto). | **NO** (Son entre 3 y 6 atributos fijos por ítem). | **EMBEBER (Embedding)** | Subdocumento `especificaciones` directo. Permite polimorfismo puro sin tablas puente. |
| **Producto ➔ Proveedor Fabricante** | **NO** (El cliente final en la web no necesita ver el RUT ni contacto del taller textil). | **SÍ** (Un mismo taller de confección provee decenas de prendas). | **SÍ** (El proveedor puede cambiar su razón social, teléfono o dirección de forma autónoma). | **NO** (Es un solo proveedor por prenda). | **REFERENCIA EXTENDIDA (Extended Reference)** | Se almacena el `id_proveedor_oracle` y únicamente el campo que más se consulta (`razon_social`). Evita hacer búsquedas adicionales pero no duplica todo el contacto. |
| **Producto ➔ Reseñas de Clientes (Reviews)** | **SÍ** (Se leen al pie de la página del producto). | **NO** (La opinión va dirigida a ese modelo). | **RARA VEZ** (El cliente opina una vez). | **SÍ (Riesgo)** (Un producto muy viral puede recibir decenas de miles de opiniones y vulnerar el límite de 16MB de BSON). | **REFERENCIAR (Referencing)** | Se mantienen en una colección separada `resenas` con el campo `producto_id`, manteniendo la colección `productos` liviana y veloz. |

*Fuente: Elaboración propia según metodología oficial de modelado de datos de MongoDB Inc. (2026c).*

### 5.3 Estructura del Documento Final JSON/BSON
```json
{
  "_id": 101,
  "codigo_oracle": 201,
  "sku": "HOOD-ACID-01",
  "nombre": "Hoodie Oversize Acid Wash Black",
  "categoria": "Hoodies",
  "marca": "Estilo Urbano Signature",
  "precio": 39990,
  "en_oferta": false,
  "descuento_pct": 0,
  "estado": "activo",
  "fecha_creacion": "2026-09-01T10:00:00Z",
  "proveedor": {
    "id_proveedor_oracle": 101,
    "razon_social": "Confecciones Urban Textiles SpA",
    "pais_origen": "Chile"
  },
  "especificaciones": {
    "material": "100% Algodón Rústico Heavyweight",
    "corte": "Boxy / Drop Shoulder Oversize",
    "gramaje": "400 GSM",
    "estampado": "Serigrafía al tacto cero"
  },
  "tallas_disponibles": [
    { "talla": "S", "stock": 15, "medidas_cm": { "pecho": 118, "largo": 70 } },
    { "talla": "M", "stock": 25, "medidas_cm": { "pecho": 124, "largo": 73 } },
    { "talla": "L", "stock": 20, "medidas_cm": { "pecho": 130, "largo": 76 } },
    { "talla": "XL", "stock": 10, "medidas_cm": { "pecho": 136, "largo": 79 } }
  ],
  "total_visitas": 1450,
  "unidades_vendidas": 84
}
```

---

## 6. IMPLEMENTACIÓN TÉCNICA DEL CRUD EN MONGODB (CONTEXTO REAL)

> [!IMPORTANT]
> **Alcance de la Asignatura:** Conforme a las directrices docentes impartidas en clase y la documentación técnica oficial (MongoDB Inc., 2026a, 2026c), todos los scripts se implementan en JavaScript de `mongosh` y la herramienta gráfica MongoDB Compass (MongoDB Inc., 2026b) **manteniéndose dentro del alcance del curso: sin índices personalizados ni agregaciones avanzadas**. Todas las fechas se registran obligatoriamente con el constructor formal `ISODate`.

### 6.1 Operación CREATE (Inserción de Documentos)

#### Caso Real A: `insertOne` (Ingreso de prenda con esquema polimórfico)
* **Necesidad del Negocio:** La bodega central recibe el nuevo *Hoodie Acid Wash Black*, con especificaciones de tela pesada y tabla de tallas.
* **Instrucción en MongoDB:**
```javascript
db.productos.insertOne({
    _id: 101,
    codigo_oracle: 201,
    sku: "HOOD-ACID-01",
    nombre: "Hoodie Oversize Acid Wash Black",
    categoria: "Hoodies",
    marca: "Estilo Urbano Signature",
    descripcion: "Polerón urbano corte oversize con lavado ácido artesanal y tela gruesa de 400 GSM.",
    precio: 39990,
    en_oferta: false,
    descuento_pct: 0,
    estado: "activo",
    fecha_creacion: ISODate("2026-09-01T10:00:00Z"),
    proveedor: {
        id_proveedor_oracle: 101,
        razon_social: "Confecciones Urban Textiles SpA",
        pais_origen: "Chile"
    },
    especificaciones: {
        material: "100% Algodón Rústico Heavyweight",
        corte: "Boxy / Drop Shoulder Oversize",
        gramaje: "400 GSM"
    },
    tallas_disponibles: [
        { talla: "S", stock: 15, medidas_cm: { pecho: 118, largo: 70 } },
        { talla: "M", stock: 25, medidas_cm: { pecho: 124, largo: 73 } },
        { talla: "L", stock: 20, medidas_cm: { pecho: 130, largo: 76 } }
    ],
    total_visitas: 1450,
    unidades_vendidas: 84
});
```
* **Resultado:** `{ acknowledged: true, insertedId: 101 }`.

#### Caso Real B: `insertMany` (Carga masiva de nueva temporada)
* **Necesidad del Negocio:** Publicar simultáneamente una polera gráfica anime, unas zapatillas chunky y un banano táctico, cada uno con especificaciones totalmente disímiles.
* **Instrucción en MongoDB:**
```javascript
db.productos.insertMany([
    {
        _id: 102,
        codigo_oracle: 203,
        sku: "POL-TOKYO-02",
        nombre: "Polera Graphic Anime Tokyo Vibe",
        categoria: "Poleras",
        precio: 21990,
        estado: "activo",
        fecha_creacion: ISODate("2026-09-05T12:30:00Z"),
        especificaciones: { material: "Algodón 24/1", cuello: "Rib 3cm" },
        tallas_disponibles: [{ talla: "M", stock: 45 }, { talla: "L", stock: 20 }]
    },
    {
        _id: 103,
        codigo_oracle: 207,
        sku: "SNK-CHUNKY-03",
        nombre: "Zapatilla Urban Low Chunky White",
        categoria: "Sneakers",
        precio: 69990,
        estado: "activo",
        fecha_creacion: ISODate("2026-09-08T15:00:00Z"),
        especificaciones: { suela: "Goma EVA", plataforma: "4.5 cm" },
        tallas_disponibles: [{ talla: "41", stock: 12 }, { talla: "42", stock: 14 }]
    }
]);
```
* **Resultado:** `{ acknowledged: true, insertedIds: { '0': 102, '1': 103 } }`.

---

### 6.2 Operación READ (Consultas y Filtros)

#### Caso Real A: `find` con filtros compuestos y proyección
* **Necesidad del Negocio:** El cliente entra a la categoría *"Hoodies"* y aplica el filtro *"Precios menores a $45.000"*.
* **Instrucción en MongoDB:**
```javascript
db.productos.find(
    { 
        categoria: "Hoodies", 
        precio: { $lt: 45000 }, 
        estado: "activo" 
    },
    { 
        nombre: 1, 
        precio: 1, 
        "especificaciones.corte": 1, 
        tallas_disponibles: 1 
    }
);
```

#### Caso Real B: `findOne` por SKU
* **Necesidad del Negocio:** Carga instantánea de la ficha de detalle de producto cuando el usuario escanea un código QR en tienda física o pincha un enlace directo.
* **Instrucción en MongoDB:**
```javascript
db.productos.findOne(
    { sku: "SNK-CHUNKY-03" }
);
```

---

### 6.3 Operación UPDATE (Modificaciones con `$set` y `$inc`)

#### Caso Real A: `updateOne` con `$set` (Actualización de datos puntuales)
* **Necesidad del Negocio:** Ajustar el precio de venta y la descripción del producto ID 101 tras renegociar con el proveedor.
* **Instrucción en MongoDB:**
```javascript
db.productos.updateOne(
    { _id: 101 },
    { 
        $set: { 
            precio: 37990, 
            descripcion: "Polerón oversize lavado ácido (Rebajado de temporada).",
            fecha_actualizacion: ISODate("2026-09-12T14:00:00Z")
        } 
    }
);
```

#### Caso Real B: `updateOne` con `$inc` (Operación atómica de contadores y ventas)
* **Necesidad del Negocio:** Tras una venta en la tienda, incrementar el contador acumulado de unidades vendidas y el número de visitas **sin necesidad de leer el valor previo en memoria**, eliminando condiciones de carrera (*Race Conditions*).
* **Instrucción en MongoDB:**
```javascript
db.productos.updateOne(
    { _id: 101 },
    { 
        $inc: { 
            unidades_vendidas: 1,
            total_visitas: 1
        } 
    }
);
```

#### Caso Real C: `updateMany` con `$set` (Campaña comercial masiva / CyberDay)
* **Necesidad del Negocio:** Aplicar un 15% de descuento a todas las poleras del catálogo por inicio del CyberDay.
* **Instrucción en MongoDB:**
```javascript
db.productos.updateMany(
    { categoria: "Poleras", estado: "activo" },
    { 
        $set: { 
            en_oferta: true, 
            descuento_pct: 15,
            campana: "CYBERDAY 2026"
        } 
    }
);
```

---

### 6.4 Operación DELETE y Justificación del Borrado Lógico

#### Caso Real A: `deleteOne` (Eliminación física puntual)
* **Uso en la Empresa:** Eliminar un registro de prueba ingresado accidentalmente por el administrador o un producto duplicado que jamás tuvo ventas.
* **Instrucción en MongoDB:**
```javascript
db.productos.deleteOne({ _id: 105 });
```

#### Caso Real B: `deleteMany` (Depuración masiva de pruebas)
* **Uso en la Empresa:** Limpiar todos los documentos creados durante las fases de test con categoría temporal.
* **Instrucción en MongoDB:**
```javascript
db.productos.deleteMany({ categoria: "Temporal" });
```

#### Caso Real C: Borrado Lógico con `$set` (Alternativa Segura Obligatoria)

> [!IMPORTANT]
> **Justificación Empresarial:** En una plataforma de comercio electrónico real, **nunca se debe utilizar `deleteOne` o `deleteMany` sobre productos que hayan tenido compras registradas**. Si se elimina físicamente una prenda, los pedidos históricos en Oracle quedarían huérfanos de información de catálogo y se perderían las métricas para auditoría y reposición.
>
> Por esta razón, la política de negocio de "Estilo Urbano" dictamina la **anulación lógica** mediante `$set`, marcando la prenda como descontinuada y registrando el motivo y la fecha exacta de salida:

```javascript
db.productos.updateOne(
    { _id: 104 },
    { 
        $set: { 
            estado: "descontinuado",
            motivo_baja: "Agotado en fábrica por proveedor, fin de línea de producción",
            fecha_baja: ISODate("2026-09-15T18:00:00Z")
        } 
    }
);
```

---

## 7. EVALUACIÓN CRÍTICA: VENTAJAS Y DESVENTAJAS DE MONGODB

### 7.1 Ventajas Competitivas en la Empresa
1. **Modelado Natural y Polimórfico:** Permite convivir productos con estructuras disímiles en una sola colección, eliminando esquemas relacionales complejos con decenas de columnas nulas.
2. **Desempeño en Lectura:** Al estar los datos embebidos (tallas, medidas, especificaciones), se obtienen mediante una sola operación de lectura sin la sobrecarga de múltiples `JOIN`.
3. **Productividad en Desarrollo:** El formato BSON es prácticamente idéntico al JSON utilizado por el navegador web y las API REST, agilizando el desarrollo del frontend.
4. **Agilidad ante el Cambio Comercial:** Agregar promociones, campañas o nuevas etiquetas no requiere planificar costosos tiempos de inactividad de base de datos (*downtime*).

### 7.2 Desventajas y Riesgos Operacionales
1. **Ausencia de Integridad Referencial Nativa:** MongoDB no impide que se ingresen identificadores de clientes o proveedores inexistentes; toda la responsabilidad recae en el código de la aplicación.
2. **Riesgo de Inconsistencias por Falta de Esquema Rígido:** Si no existe gobernanza en el equipo de desarrollo, pueden guardarse campos mal escritos (ej. `precio_clp` en lugar de `precio`), generando errores de visualización.
3. **Mayor Consumo de Almacenamiento:** Al almacenar las claves de cada campo en cada documento individual (`"nombre"`, `"precio"`, etc.), el volumen en disco y memoria RAM es sustancialmente mayor que en un motor relacional compacto.
4. **No Apto para Nómina y Facturación Legal:** Para la liquidación de sueldos o emisión de comprobantes fiscales (donde un error de cuadratura de $1 peso invalida el balance contable), Oracle Database sigue siendo insustituible.

---

## 8. CONCLUSIONES

1. **La coexistencia vence a la exclusividad:** El desarrollo de la Evaluación Parcial N° 3 demostró que el debate *"SQL vs. NoSQL"* no es una competencia excluyente, sino una decisión de ingeniería arquitectónica (*Polyglot Persistence*). Ningún motor resuelve de forma óptima todos los problemas de una empresa.
2. **Oracle como baluarte financiero:** Oracle Database demostró ser el motor idóneo para el núcleo tributario, la facturación con Webpay Plus, el cálculo de comisiones y el cumplimiento de leyes laborales chilenas (sueldo mínimo con triggers preventivos), garantizando transaccionalidad ACID y trazabilidad inquebrantable.
3. **MongoDB como motor de agilidad comercial:** MongoDB resolvió con elegancia la heterogeneidad del catálogo de ropa urbana streetwear, reduciendo la latencia de consulta web y permitiendo la coexistencia de prendas con especificaciones técnicas polimórficas sin degradar el rendimiento.
4. **Modelado fundamentado:** La matriz de las 4 preguntas demostró que la decisión de embeber tallas y referenciar proveedores no responde a caprichos de desarrollo, sino a patrones claros de acceso a datos, aislamiento del ciclo de vida y prevención del desborde de almacenamiento.

---

## 9. REFERENCIAS BIBLIOGRÁFICAS (FORMATO APA 7MA EDICIÓN)

* Codd, E. F. (1970). *A Relational Model of Data for Large Shared Data Banks*. Communications of the ACM, 13(6), 377–387. https://doi.org/10.1145/362384.362685
* Duoc UC. (2026). *Guía Didáctica de la Asignatura BDY1103: Taller de Base de Datos*. Escuela de Informática y Telecomunicaciones, Duoc UC.
* Duoc UC Bibliotecas. (2024). *Manual de Formato de Informes y Presentaciones Académicas*. Sistema de Bibliotecas Duoc UC. https://bibliotecas.duoc.cl/documentos-academicos-y-presentaciones/formato-informes
* Fowler, M., & Sadalage, P. J. (2012). *NoSQL Distilled: A Brief Guide to the Emerging World of Polyglot Persistence*. Addison-Wesley Professional.
* MongoDB Inc. (2026a). *MongoDB Database Server y mongosh shell* (Versión 7.0) [Software de base de datos no relacional]. MongoDB Corporation. https://www.mongodb.com
* MongoDB Inc. (2026b). *MongoDB Compass* (Versión 1.43) [Software de interfaz gráfica para gestión de documentos]. MongoDB Corporation. https://www.mongodb.com/products/compass
* MongoDB Inc. (2026c). *MongoDB Documentation: Data Modeling Introduction and CRUD Operations* (v7.0). MongoDB Manual. https://www.mongodb.com/docs/manual/core/data-modeling-introduction/
* OpenJS Foundation. (2024). *Node.js JavaScript Runtime Environment* (Versión 20.x) [Software de entorno de ejecución]. https://nodejs.org
* Oracle Corporation. (2024a). *Oracle Database 21c Enterprise Edition y Autonomous Database* [Software de base de datos relacional]. Oracle Corporation. https://www.oracle.com/database/
* Oracle Corporation. (2024b). *Oracle Database PL/SQL Language Reference 21c*. Oracle Help Center. https://docs.oracle.com/en/database/oracle/oracle-database/21/lnpls/
* Python Software Foundation. (2024). *Python Language Reference y PyMongo Driver* (Versión 3.12) [Software de programación y conector de base de datos]. https://www.python.org
* Tailwind Labs. (2024). *Tailwind CSS Framework* (Versión 3.4) [Software de diseño y estilos web]. https://tailwindcss.com
