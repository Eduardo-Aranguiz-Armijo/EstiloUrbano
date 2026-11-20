// ============================================================================
// ASIGNATURA : BDY1103 - TALLER DE BASE DE DATOS
// EVALUACIÓN : EVALUACIÓN PARCIAL N° 3 (EP3) - ARQUITECTURA HÍBRIDA
// PROYECTO    : TIENDA ONLINE "ESTILO URBANO" (E-COMMERCE STREETWEAR)
// INTEGRANTES: Eduardo Aránguiz - Luciano Zaninovic - Kevin Urbina
// DOCENTE    : Carlos Enrique Quintanilla Galleguillos
// MOTOR      : MONGODB 6.x / 7.x (MONGOSH / MONGODB COMPASS)
// ALCANCE    : CRUD COMPLETO SIN AGREGACIONES NI ÍNDICES (SEGÚN PAUTA DOCENTE)
// ============================================================================

// 1. SELECCIÓN DE BASE DE DATOS
use estilo_urbano_nosql;

// ----------------------------------------------------------------------------
// 2. LIMPIEZA PREVIA DE COLECCIONES (PARA EJECUCIÓN REPETIBLE)
// ----------------------------------------------------------------------------
db.productos.drop();
db.resenas.drop();
db.logs_actividad.drop();

// ============================================================================
// 3. OPERACIÓN CREATE (INSERCIÓN DE DOCUMENTOS)
// ============================================================================

// A. insertOne: Registrar una prenda streetwear con variantes y especificaciones dinámicas
// Contexto de Negocio: Alta de un Hoodie Acid Wash con tabla de tallas embebida.
db.productos.insertOne({
    _id: 101,
    codigo_oracle: 201, // Enlace con tabla PRODUCTO en Oracle
    sku: "HOOD-ACID-01",
    nombre: "Hoodie Oversize Acid Wash Black",
    categoria: "Hoodies",
    marca: "Estilo Urbano Signature",
    descripcion: "Polerón urbano corte oversize con lavado ácido artesanal y tela gruesa de 400 GSM.",
    precio: 39990,
    en_oferta: false,
    descuento_pct: 0,
    estado: "activo", // Borrado lógico: 'activo', 'descontinuado', 'agotado'
    fecha_creacion: ISODate("2026-09-01T10:00:00Z"),
    proveedor: {
        id_proveedor_oracle: 101,
        razon_social: "Confecciones Urban Textiles SpA",
        pais_origen: "Chile"
    },
    especificaciones: {
        material: "100% Algodón Rústico Heavyweight",
        corte: "Boxy / Drop Shoulder Oversize",
        gramaje: "400 GSM",
        estampado: "Serigrafía al tacto cero"
    },
    tallas_disponibles: [
        { talla: "S", stock: 15, medidas_cm: { pecho: 118, largo: 70 } },
        { talla: "M", stock: 25, medidas_cm: { pecho: 124, largo: 73 } },
        { talla: "L", stock: 20, medidas_cm: { pecho: 130, largo: 76 } },
        { talla: "XL", stock: 10, medidas_cm: { pecho: 136, largo: 79 } }
    ],
    total_visitas: 1450,
    unidades_vendidas: 84
});

// B. insertMany: Carga masiva de nueva colección de temporada
// Contexto de Negocio: Lanzamiento catálogo de primavera/invierno con diferentes esquemas.
db.productos.insertMany([
    {
        _id: 102,
        codigo_oracle: 203,
        sku: "POL-TOKYO-02",
        nombre: "Polera Graphic Anime Tokyo Vibe",
        categoria: "Poleras",
        marca: "Estilo Urbano Tokyo Series",
        descripcion: "Polera manga corta boxy fit con gráfico serigrafiado de estilo ciberpunk.",
        precio: 21990,
        en_oferta: false,
        descuento_pct: 0,
        estado: "activo",
        fecha_creacion: ISODate("2026-09-05T12:30:00Z"),
        proveedor: {
            id_proveedor_oracle: 101,
            razon_social: "Confecciones Urban Textiles SpA",
            pais_origen: "Chile"
        },
        especificaciones: {
            material: "100% Algodón Peinado 24/1",
            corte: "Boxy Fit Vintage",
            gramaje: "240 GSM",
            cuello: "Rib grueso de 3 cm"
        },
        tallas_disponibles: [
            { talla: "S", stock: 30, medidas_cm: { pecho: 110, largo: 68 } },
            { talla: "M", stock: 45, medidas_cm: { pecho: 116, largo: 71 } },
            { talla: "L", stock: 20, medidas_cm: { pecho: 122, largo: 74 } }
        ],
        total_visitas: 3200,
        unidades_vendidas: 150
    },
    {
        _id: 103,
        codigo_oracle: 207,
        sku: "SNK-CHUNKY-03",
        nombre: "Zapatilla Urban Low Chunky White",
        categoria: "Sneakers",
        marca: "Street Footwear Urban",
        descripcion: "Sneakers urbanos con plataforma chunky ligera y cuero sintético de alto impacto.",
        precio: 69990,
        en_oferta: false,
        descuento_pct: 0,
        estado: "activo",
        fecha_creacion: ISODate("2026-09-08T15:00:00Z"),
        proveedor: {
            id_proveedor_oracle: 103,
            razon_social: "Sneakers y Street Footwear S.A.",
            pais_origen: "Vietnam"
        },
        especificaciones: {
            capellada: "Cuero Microfibra y Malla Transpirable",
            suela: "Goma EVA inyectada antideslizante",
            tipo_ajuste: "Cordones reflectantes 3M",
            altura_plataforma: "4.5 cm"
        },
        tallas_disponibles: [
            { talla: "40", stock: 8 },
            { talla: "41", stock: 12 },
            { talla: "42", stock: 14 },
            { talla: "43", stock: 6 }
        ],
        total_visitas: 5120,
        unidades_vendidas: 42
    },
    {
        _id: 104,
        codigo_oracle: 210,
        sku: "ACC-BAN-CORD-04",
        nombre: "Banano Táctico Crossbody Cordura",
        categoria: "Accesorios",
        marca: "Estilo Urbano Tactical Gear",
        descripcion: "Banano cruzado impermeable de alta resistencia con correas militares ajustables.",
        precio: 22990,
        en_oferta: false,
        descuento_pct: 0,
        estado: "activo",
        fecha_creacion: ISODate("2026-09-10T09:15:00Z"),
        proveedor: {
            id_proveedor_oracle: 102,
            razon_social: "Streetwear Global Imports Ltda",
            pais_origen: "China"
        },
        especificaciones: {
            tejido: "Cordura 1000D resistente al agua",
            capacidad: "3.5 Litros",
            cierres: "YKK impermeables",
            compartimientos: 4
        },
        tallas_disponibles: [
            { talla: "ESTANDAR", stock: 40 }
        ],
        total_visitas: 890,
        unidades_vendidas: 35
    },
    {
        _id: 105,
        codigo_oracle: 999,
        sku: "TEMP-PRUEBA-99",
        nombre: "Producto Temporal de Pruebas",
        categoria: "Temporal",
        marca: "Test Brand",
        descripcion: "Registro de prueba para comprobar eliminación física y lógica.",
        precio: 9990,
        en_oferta: false,
        descuento_pct: 0,
        estado: "activo",
        fecha_creacion: ISODate("2026-09-11T11:00:00Z"),
        proveedor: {
            id_proveedor_oracle: 101,
            razon_social: "Confecciones Urban Textiles SpA",
            pais_origen: "Chile"
        },
        especificaciones: { nota: "Item de test" },
        tallas_disponibles: [{ talla: "M", stock: 5 }],
        total_visitas: 10,
        unidades_vendidas: 0
    }
]);

// ============================================================================
// 4. OPERACIÓN READ (CONSULTAS Y FILTROS)
// ============================================================================

// A. find: Listar productos activos de la categoría 'Hoodies' que cuesten menos de $45.000
// Contexto de Negocio: Filtro del catálogo web para clientes que buscan polerones accesibles.
print("=== 4.A CONSULTA: HOODIES ACTIVOS BAJO $45.000 ===");
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

// B. findOne: Buscar la ficha técnica de un producto exacto por su SKU
// Contexto de Negocio: Carga de la página de detalle cuando el cliente hace clic en una zapatilla.
print("=== 4.B CONSULTA PUNTUAL: FICHA DE ZAPATILLA POR SKU ===");
db.productos.findOne(
    { sku: "SNK-CHUNKY-03" }
);

// C. find: Buscar productos que tengan stock disponible en talla 'L'
// Contexto de Negocio: Filtro por talla seleccionada por el comprador.
print("=== 4.C CONSULTA: PRODUCTOS CON DISPONIBILIDAD EN TALLA L ===");
db.productos.find(
    { 
        "tallas_disponibles": { 
            $elemMatch: { talla: "L", stock: { $gt: 0 } } 
        },
        estado: "activo"
    },
    { nombre: 1, categoria: 1, precio: 1, tallas_disponibles: 1 }
);

// ============================================================================
// 5. OPERACIÓN UPDATE (MODIFICACIONES CON $set Y $inc)
// ============================================================================

// A. updateOne con $set: Actualizar precio y descripción de un producto puntual
// Contexto de Negocio: Ajuste comercial por renegociación de costo con el proveedor.
print("=== 5.A UPDATEONE CON $SET: CAMBIO DE PRECIO Y DESCRIPCIÓN ===");
db.productos.updateOne(
    { _id: 101 },
    { 
        $set: { 
            precio: 37990, 
            descripcion: "Polerón urbano corte oversize con lavado ácido artesanal (Precio rebajado de temporada).",
            fecha_actualizacion: ISODate("2026-09-12T14:00:00Z")
        } 
    }
);

// B. updateOne con $inc: Incrementar visitas y decrementar stock por venta
// Contexto de Negocio: Simula la compra de una unidad (descuenta stock sin leer antes y suma 1 visita).
print("=== 5.B UPDATEONE CON $INC: DESCUENTO ATÓMICO DE STOCK Y SUMA DE VENTA ===");
db.productos.updateOne(
    { _id: 101 },
    { 
        $inc: { 
            unidades_vendidas: 1,
            total_visitas: 1
        } 
    }
);

// C. updateMany con $set: Aplicar campaña de descuento masivo (CyberDay / Liquidación)
// Contexto de Negocio: Descuento del 15% a toda la categoría 'Poleras'.
print("=== 5.C UPDATEMANY CON $SET: APLICAR CAMPAÑA CYBERDAY EN POLERAS ===");
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

// ============================================================================
// 6. OPERACIÓN DELETE Y BORRADO LÓGICO
// ============================================================================

// A. deleteOne: Eliminación física de un producto puntual de prueba
// Contexto de Negocio: Borrar un ítem temporal que nunca se publicó ni tuvo ventas.
print("=== 6.A DELETEONE: ELIMINACIÓN FÍSICA DE ITEM TEMPORAL ===");
db.productos.deleteOne({ _id: 105 });

// B. deleteMany: Depuración de registros temporales obsoletos
// Contexto de Negocio: Limpieza de registros con categoría 'Temporal' o datos de staging.
print("=== 6.B DELETEMANY: LIMPIEZA DE CATEGORÍAS TEMPORALES ===");
db.productos.deleteMany({ categoria: "Temporal" });

// C. BORRADO LÓGICO CON $set (ALTERNATIVA OBLIGATORIA EN COMERCIO REAL)
// Justificación: Nunca se debe borrar físicamente una prenda que ya tuvo órdenes asociadas
// en Oracle ni historial de visitas, porque rompería la trazabilidad histórica de ventas.
print("=== 6.C BORRADO LÓGICO: DESCONTINUAR PRENDA SIN PERDER HISTORIAL ===");
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

// ----------------------------------------------------------------------------
// VERIFICACIÓN FINAL: LISTAR PRODUCTOS ACTIVOS TRAS LAS OPERACIONES
// ----------------------------------------------------------------------------
print("=== ESTADO FINAL DE LA COLECCIÓN PRODUCTOS ===");
db.productos.find({}, { nombre: 1, precio: 1, en_oferta: 1, descuento_pct: 1, estado: 1 });
