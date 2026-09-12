-- ============================================================================
-- ASIGNATURA: BDY1103 - TALLER DE BASE DE DATOS
-- EVALUACIÓN: EVALUACIÓN PARCIAL N° 1 (CASO SEMESTRAL)
-- PROYECTO   : TIENDA ONLINE "ESTILO URBANO" (E-COMMERCE)
-- ARCHIVO    : 01_esquema_estilo_urbano.sql
-- DESCRIPCIÓN: SCRIPT DDL (TABLAS, RESTRICCIONES) Y DML (DATOS DE PRUEBA)
-- MOTOR      : ORACLE DATABASE 19c / 21c / LIVESQL / CLOUD
-- ============================================================================

SET DEFINE OFF;

-- ----------------------------------------------------------------------------
-- 1. LIMPIEZA DE OBJETOS PREVIOS (BORRADO EN CASCADA SEGURO)
-- ----------------------------------------------------------------------------
BEGIN
    FOR t IN (
        SELECT table_name 
        FROM user_tables 
        WHERE table_name IN (
            'HISTORIAL_TRACKING_PEDIDO', 'DETALLE_PEDIDO', 'PEDIDO',
            'PRODUCTO', 'CATEGORIA', 'PROVEEDOR', 'DIRECCION_CLIENTE',
            'USUARIO', 'ROL', 'METODO_PAGO', 'ESTADO_PEDIDO',
            'RESUMEN_DESEMPENO_MENSUAL', 'LOG_ERRORES_SISTEMA'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- ----------------------------------------------------------------------------
-- 2. CREACIÓN DE TABLAS MAESTRAS Y DE SEGURIDAD
-- ----------------------------------------------------------------------------

-- Tabla de Roles del Sistema
CREATE TABLE ROL (
    id_rol          NUMBER(2)       CONSTRAINT pk_rol PRIMARY KEY,
    nombre_rol      VARCHAR2(30)    NOT NULL CONSTRAINT unq_rol_nombre UNIQUE,
    descripcion     VARCHAR2(150)   NOT NULL
);

-- Tabla de Usuarios (Administradores, Trabajadores/Operadores y Clientes)
CREATE TABLE USUARIO (
    id_usuario      NUMBER(6)       CONSTRAINT pk_usuario PRIMARY KEY,
    rut             VARCHAR2(12)    NOT NULL CONSTRAINT unq_usuario_rut UNIQUE,
    nombre          VARCHAR2(50)    NOT NULL,
    apellido        VARCHAR2(50)    NOT NULL,
    email           VARCHAR2(100)   NOT NULL CONSTRAINT unq_usuario_email UNIQUE,
    password_hash   VARCHAR2(128)   NOT NULL,
    telefono        VARCHAR2(20)    NOT NULL,
    id_rol          NUMBER(2)       NOT NULL CONSTRAINT fk_usuario_rol REFERENCES ROL(id_rol),
    meta_mensual    NUMBER(10)      DEFAULT 0, -- Aplica a trabajadores de fulfillment / ventas
    fecha_registro  DATE            DEFAULT SYSDATE NOT NULL,
    estado          VARCHAR2(1)     DEFAULT 'A' NOT NULL CONSTRAINT chk_usr_estado CHECK (estado IN ('A', 'I'))
);

-- Direcciones de Despacho registradas por los clientes
CREATE TABLE DIRECCION_CLIENTE (
    id_direccion    NUMBER(6)       CONSTRAINT pk_direccion PRIMARY KEY,
    id_usuario      NUMBER(6)       NOT NULL CONSTRAINT fk_dir_usuario REFERENCES USUARIO(id_usuario),
    calle_numero    VARCHAR2(100)   NOT NULL,
    depto_casa      VARCHAR2(30),
    comuna          VARCHAR2(50)    NOT NULL,
    ciudad          VARCHAR2(50)    NOT NULL,
    region          VARCHAR2(50)    NOT NULL,
    es_principal    VARCHAR2(1)     DEFAULT 'S' NOT NULL CONSTRAINT chk_dir_principal CHECK (es_principal IN ('S', 'N'))
);

-- ----------------------------------------------------------------------------
-- 3. PROVEEDORES, CATEGORÍAS Y CATÁLOGO DE PRODUCTOS (INVENTARIO)
-- ----------------------------------------------------------------------------

-- Proveedores oficiales de indumentaria urbana y calzado
CREATE TABLE PROVEEDOR (
    id_proveedor    NUMBER(4)       CONSTRAINT pk_proveedor PRIMARY KEY,
    rut             VARCHAR2(12)    NOT NULL CONSTRAINT unq_prov_rut UNIQUE,
    razon_social    VARCHAR2(100)   NOT NULL,
    contacto_nombre VARCHAR2(80)    NOT NULL,
    email           VARCHAR2(100)   NOT NULL,
    telefono        VARCHAR2(20)    NOT NULL,
    ciudad          VARCHAR2(50)    NOT NULL,
    estado          VARCHAR2(1)     DEFAULT 'A' NOT NULL CONSTRAINT chk_prov_estado CHECK (estado IN ('A', 'I'))
);

-- Categorías de prendas y accesorios
CREATE TABLE CATEGORIA (
    id_categoria    NUMBER(3)       CONSTRAINT pk_categoria PRIMARY KEY,
    nombre_categoria VARCHAR2(50)   NOT NULL CONSTRAINT unq_cat_nombre UNIQUE,
    descripcion     VARCHAR2(200)
);

-- Catálogo de productos con gestión de inventario, tallas variadas y stock crítico
CREATE TABLE PRODUCTO (
    id_producto     NUMBER(6)       CONSTRAINT pk_producto PRIMARY KEY,
    sku             VARCHAR2(30)    NOT NULL CONSTRAINT unq_prod_sku UNIQUE,
    nombre_producto VARCHAR2(100)   NOT NULL,
    id_categoria    NUMBER(3)       NOT NULL CONSTRAINT fk_prod_categoria REFERENCES CATEGORIA(id_categoria),
    id_proveedor    NUMBER(4)       NOT NULL CONSTRAINT fk_prod_proveedor REFERENCES PROVEEDOR(id_proveedor),
    talla           VARCHAR2(10)    NOT NULL CONSTRAINT chk_prod_talla CHECK (talla IN ('XS', 'S', 'M', 'L', 'XL', 'XXL', '39', '40', '41', '42', '43', 'ESTANDAR')),
    precio_unitario NUMBER(8)       NOT NULL CONSTRAINT chk_prod_precio CHECK (precio_unitario > 0), -- En Pesos Chilenos (CLP)
    stock_actual    NUMBER(5)       NOT NULL CONSTRAINT chk_prod_stock CHECK (stock_actual >= 0),
    stock_minimo    NUMBER(4)       DEFAULT 5 NOT NULL,
    estado          VARCHAR2(1)     DEFAULT 'A' NOT NULL CONSTRAINT chk_prod_estado CHECK (estado IN ('A', 'I'))
);

-- ----------------------------------------------------------------------------
-- 4. GESTIÓN DE PEDIDOS, PAGOS DIGITALES Y TRACKING ONLINE
-- ----------------------------------------------------------------------------

-- Métodos de Pago Digitales
CREATE TABLE METODO_PAGO (
    id_metodo       NUMBER(2)       CONSTRAINT pk_metodo_pago PRIMARY KEY,
    nombre_metodo   VARCHAR2(40)    NOT NULL CONSTRAINT unq_met_nombre UNIQUE,
    tipo            VARCHAR2(30)    NOT NULL -- Pasarela, Transferencia, etc.
);

-- Estados de seguimiento para el cliente en el E-Commerce
CREATE TABLE ESTADO_PEDIDO (
    id_estado       NUMBER(2)       CONSTRAINT pk_estado_pedido PRIMARY KEY,
    nombre_estado   VARCHAR2(30)    NOT NULL CONSTRAINT unq_est_nombre UNIQUE,
    descripcion     VARCHAR2(150)   NOT NULL
);

-- Órdenes de Pedido realizadas por los clientes (Montos en CLP)
CREATE TABLE PEDIDO (
    id_pedido       NUMBER(8)       CONSTRAINT pk_pedido PRIMARY KEY,
    nro_seguimiento VARCHAR2(25)    NOT NULL CONSTRAINT unq_ped_tracking UNIQUE,
    id_cliente      NUMBER(6)       NOT NULL CONSTRAINT fk_ped_cliente REFERENCES USUARIO(id_usuario),
    id_trabajador   NUMBER(6)       CONSTRAINT fk_ped_trabajador REFERENCES USUARIO(id_usuario), -- Operador responsable
    id_metodo_pago  NUMBER(2)       NOT NULL CONSTRAINT fk_ped_metodo REFERENCES METODO_PAGO(id_metodo),
    id_estado       NUMBER(2)       NOT NULL CONSTRAINT fk_ped_estado REFERENCES ESTADO_PEDIDO(id_estado),
    fecha_pedido    DATE            DEFAULT SYSDATE NOT NULL,
    total_neto      NUMBER(10)      NOT NULL, -- Pesos Chilenos (CLP)
    total_iva       NUMBER(10)      NOT NULL, -- IVA 19% CLP
    total_pedido    NUMBER(10)      NOT NULL CONSTRAINT chk_ped_total CHECK (total_pedido >= 0)
);

-- Detalle de productos por cada orden de pedido con talla comprada
CREATE TABLE DETALLE_PEDIDO (
    id_detalle      NUMBER(10)      CONSTRAINT pk_detalle_pedido PRIMARY KEY,
    id_pedido       NUMBER(8)       NOT NULL CONSTRAINT fk_det_pedido REFERENCES PEDIDO(id_pedido),
    id_producto     NUMBER(6)       NOT NULL CONSTRAINT fk_det_producto REFERENCES PRODUCTO(id_producto),
    talla_comprada  VARCHAR2(10)    NOT NULL, -- Talla seleccionada por el cliente (S, M, L, XL, 41, etc.)
    cantidad        NUMBER(4)       NOT NULL CONSTRAINT chk_det_cant CHECK (cantidad > 0),
    precio_unitario NUMBER(8)       NOT NULL, -- Pesos Chilenos (CLP)
    subtotal        NUMBER(10)      NOT NULL
);

-- Historial de Tracking para que el cliente consulte en vivo
CREATE TABLE HISTORIAL_TRACKING_PEDIDO (
    id_historial    NUMBER(10)      CONSTRAINT pk_historial_track PRIMARY KEY,
    id_pedido       NUMBER(8)       NOT NULL CONSTRAINT fk_hist_pedido REFERENCES PEDIDO(id_pedido),
    id_estado       NUMBER(2)       NOT NULL CONSTRAINT fk_hist_estado REFERENCES ESTADO_PEDIDO(id_estado),
    fecha_cambio    DATE            DEFAULT SYSDATE NOT NULL,
    observacion     VARCHAR2(250)
);

-- ----------------------------------------------------------------------------
-- 5. TABLAS AUXILIARES PARA AUDITORÍA Y PROCESAMIENTO PL/SQL (EP1)
-- ----------------------------------------------------------------------------

-- Tabla donde el Bloque PL/SQL almacenará los resultados del cálculo mensual
CREATE TABLE RESUMEN_DESEMPENO_MENSUAL (
    id_resumen          NUMBER(8) GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_resumen PRIMARY KEY,
    id_trabajador       NUMBER(6)       NOT NULL,
    nombre_trabajador   VARCHAR2(100)   NOT NULL,
    mes_proceso         NUMBER(2)       NOT NULL,
    anio_proceso        NUMBER(4)       NOT NULL,
    cantidad_pedidos    NUMBER(6)       NOT NULL,
    monto_total_ventas  NUMBER(12)      NOT NULL,
    meta_mensual        NUMBER(10)      NOT NULL,
    pct_cumplimiento    NUMBER(5, 2)    NOT NULL,
    tramo_bono          VARCHAR2(30)    NOT NULL,
    porcentaje_bono     NUMBER(4, 2)    NOT NULL,
    monto_bonificacion  NUMBER(10)      NOT NULL,
    fecha_calculo       DATE            DEFAULT SYSDATE NOT NULL
);

-- Tabla para almacenar el log de excepciones capturadas por el motor PL/SQL
CREATE TABLE LOG_ERRORES_SISTEMA (
    id_log              NUMBER(8) GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_log PRIMARY KEY,
    bloque_origen       VARCHAR2(60)    NOT NULL,
    codigo_oracle       NUMBER(8),
    mensaje_error       VARCHAR2(400)   NOT NULL,
    fecha_evento        DATE            DEFAULT SYSDATE NOT NULL,
    usuario_bd          VARCHAR2(30)    DEFAULT USER NOT NULL
);

-- ============================================================================
-- 6. POBLAMIENTO DE DATOS DE PRUEBA (DML COHERENTE PARA ORACLE)
-- ============================================================================

-- 1. Roles del Sistema
INSERT INTO ROL VALUES (1, 'ADMINISTRADOR', 'Control total de la plataforma, inventario, catálogos y reportes');
INSERT INTO ROL VALUES (2, 'TRABAJADOR', 'Operador de fulfillment, empaquetamiento, ventas online y despacho');
INSERT INTO ROL VALUES (3, 'CLIENTE', 'Usuario comprador de la tienda online con historial y tracking');

-- 2. Estados de Seguimiento de Pedidos
INSERT INTO ESTADO_PEDIDO VALUES (1, 'PENDIENTE_PAGO', 'Orden creada esperando comprobante o confirmación de pasarela');
INSERT INTO ESTADO_PEDIDO VALUES (2, 'PAGADO', 'Pago validado satisfactoriamente, orden lista para preparación');
INSERT INTO ESTADO_PEDIDO VALUES (3, 'EN_EMPAQUETAMIENTO', 'Trabajador preparando las prendas y embalando en bodega');
INSERT INTO ESTADO_PEDIDO VALUES (4, 'EN_CAMINO', 'Paquete entregado al servicio de courier hacia el cliente');
INSERT INTO ESTADO_PEDIDO VALUES (5, 'ENTREGADO', 'Pedido recibido con éxito por el cliente');
INSERT INTO ESTADO_PEDIDO VALUES (6, 'CANCELADO', 'Pedido anulado por falta de pago o solicitud del cliente');

-- 3. Métodos de Pago Digitales
INSERT INTO METODO_PAGO VALUES (1, 'Webpay Plus (Transbank)', 'Pasarela Débito/Crédito');
INSERT INTO METODO_PAGO VALUES (2, 'Mercado Pago', 'Billetera Digital y Tarjetas');
INSERT INTO METODO_PAGO VALUES (3, 'Transferencia Bancaria Directa', 'Validación Bancaria');

-- 4. Proveedores de Moda Urbana
INSERT INTO PROVEEDOR VALUES (101, '76.123.456-7', 'Confecciones Urban Textiles SpA', 'Matías Valenzuela', 'mvalenzuela@urbantextiles.cl', '+56987654321', 'Santiago', 'A');
INSERT INTO PROVEEDOR VALUES (102, '77.894.215-K', 'Streetwear Global Imports Ltda', 'Fernanda Soto', 'contacto@streetwearglobal.com', '+56976543210', 'Valparaíso', 'A');
INSERT INTO PROVEEDOR VALUES (103, '78.541.980-3', 'Sneakers y Street Footwear S.A.', 'Rodrigo Navarro', 'rnavarro@streetfootwear.cl', '+56965432109', 'Concepción', 'A');

-- 5. Categorías de Ropa Urbana
INSERT INTO CATEGORIA VALUES (1, 'Hoodies y Polerones Oversize', 'Polerones de algodón pesado estilo urbano');
INSERT INTO CATEGORIA VALUES (2, 'Poleras Street Graphic', 'Poleras manga corta con serigrafía y corte oversize');
INSERT INTO CATEGORIA VALUES (3, 'Pantalones Cargo y Joggers', 'Pantalones con bolsillos tácticos y ajuste tobillero');
INSERT INTO CATEGORIA VALUES (4, 'Sneakers Urbanos', 'Zapatillas de estilo urbano y skate');
INSERT INTO CATEGORIA VALUES (5, 'Gorros y Accesorios', 'Gorros beanie, jockey snapback y bananos urbanos');

-- 6. Catálogo de Productos (Precios en CLP y Tallas Variadas)
INSERT INTO PRODUCTO VALUES (201, 'HOOD-OVR-L',   'Hoodie Oversize Acid Wash Black',    1, 101, 'L',        39990, 45, 10, 'A');
INSERT INTO PRODUCTO VALUES (202, 'HOOD-GRN-XL',  'Hoodie Heavy Cotton Forest Green',   1, 101, 'XL',       42990, 30,  8, 'A');
INSERT INTO PRODUCTO VALUES (203, 'POL-GRAF-M',   'Polera Graphic Anime Tokyo Vibe',    2, 101, 'M',        21990, 60, 15, 'A');
INSERT INTO PRODUCTO VALUES (204, 'POL-RAW-S',    'Polera Boxy Fit Vintage White',      2, 101, 'S',        19990, 12, 10, 'A');
INSERT INTO PRODUCTO VALUES (205, 'CARG-BLK-M',   'Pantalón Cargo Táctico Obsidian',    3, 102, 'M',        45990, 25,  8, 'A');
INSERT INTO PRODUCTO VALUES (206, 'JOG-BEI-L',    'Jogger Streetwear Sand Beige',       3, 102, 'L',        34990,  4, 10, 'A'); -- En stock crítico
INSERT INTO PRODUCTO VALUES (207, 'SNK-RET-41',   'Zapatilla Urban Low Chunky White',   4, 103, '41',       69990, 18,  5, 'A');
INSERT INTO PRODUCTO VALUES (208, 'SNK-MID-42',   'Zapatilla High Top Skate Raven',     4, 103, '42',       74990, 14,  5, 'A');
INSERT INTO PRODUCTO VALUES (209, 'ACC-SNAP-U',   'Jockey Snapback Estilo Urbano Flat', 5, 102, 'ESTANDAR', 16990, 50, 10, 'A');
INSERT INTO PRODUCTO VALUES (210, 'ACC-BAN-U',    'Banano Táctico Crossbody Cordura',   5, 102, 'ESTANDAR', 22990, 35, 10, 'A');

-- 7. Usuarios: Administrador, Trabajadores y Clientes
-- Administrador General
INSERT INTO USUARIO VALUES (1, '15.234.567-8', 'Carlos', 'Gómez', 'admin@estilourbano.cl', 'pass_admin_hash_987', '+56911112222', 1, 0, DATE '2024-01-10', 'A');

-- Trabajadores / Operadores Digitales con metas mensuales (en CLP)
INSERT INTO USUARIO VALUES (2, '18.456.789-2', 'Ignacio', 'López', 'ilopez@estilourbano.cl', 'pass_usr_hash_1', '+56922223333', 2, 1500000, DATE '2024-02-01', 'A');
INSERT INTO USUARIO VALUES (3, '19.123.852-K', 'Valentina', 'Pérez', 'vperez@estilourbano.cl', 'pass_usr_hash_2', '+56933334444', 2, 2000000, DATE '2024-02-15', 'A');
INSERT INTO USUARIO VALUES (4, '17.654.321-4', 'Felipe', 'Morales', 'fmorales@estilourbano.cl', 'pass_usr_hash_3', '+56944445555', 2, 1200000, DATE '2024-03-01', 'A');
-- Trabajador con meta 0 para evidenciar manejo de excepción ZERO_DIVIDE de Oracle
INSERT INTO USUARIO VALUES (5, '20.987.654-3', 'Lucas', 'Ramírez', 'lramirez@estilourbano.cl', 'pass_usr_hash_4', '+56955556666', 2, 0, DATE '2024-08-01', 'A');
-- Trabajadora nueva sin ventas en el mes para evidenciar excepción de usuario EX_SIN_PEDIDOS
INSERT INTO USUARIO VALUES (6, '21.345.678-9', 'Camila', 'Silva', 'csilva@estilourbano.cl', 'pass_usr_hash_5', '+56966667777', 2, 1000000, DATE '2024-08-15', 'A');

-- Clientes registrados en la plataforma
INSERT INTO USUARIO VALUES (10, '19.876.543-2', 'Sebastián', 'Castro', 'scastro@gmail.com', 'clie_pass_1', '+56977778888', 3, 0, DATE '2024-05-10', 'A');
INSERT INTO USUARIO VALUES (11, '20.123.456-7', 'Martina', 'Díaz', 'mdiaz@yahoo.com', 'clie_pass_2', '+56988889999', 3, 0, DATE '2024-06-12', 'A');
INSERT INTO USUARIO VALUES (12, '18.999.111-3', 'Cristóbal', 'Rojas', 'crojas@hotmail.com', 'clie_pass_3', '+56999990000', 3, 0, DATE '2024-07-01', 'A');
INSERT INTO USUARIO VALUES (13, '22.444.555-1', 'Javiera', 'Torres', 'jtorres@outlook.com', 'clie_pass_4', '+56912349876', 3, 0, DATE '2024-07-20', 'A');

-- 8. Direcciones de Despacho de Clientes
INSERT INTO DIRECCION_CLIENTE VALUES (1, 10, 'Av. Providencia 1420', 'Depto 502', 'Providencia', 'Santiago', 'Metropolitana', 'S');
INSERT INTO DIRECCION_CLIENTE VALUES (2, 11, 'Calle Los Plátanos 874', NULL, 'Ñuñoa', 'Santiago', 'Metropolitana', 'S');
INSERT INTO DIRECCION_CLIENTE VALUES (3, 12, 'Av. Libertad 340', 'Torre B 1104', 'Viña del Mar', 'Valparaíso', 'Valparaíso', 'S');
INSERT INTO DIRECCION_CLIENTE VALUES (4, 13, 'Pje. Los Copihues 12', NULL, 'San Pedro de la Paz', 'Concepción', 'Biobío', 'S');

-- 9. Pedidos Registrados en la Tienda Online (Septiembre 2024)
-- Pedidos asignados a Ignacio López (id_trabajador = 2)
INSERT INTO PEDIDO VALUES (5001, 'TRK-EST-202409-001', 10, 2, 1, 5, DATE '2024-09-02', 71412, 13568, 84980);
INSERT INTO PEDIDO VALUES (5002, 'TRK-EST-202409-002', 11, 2, 2, 4, DATE '2024-09-04', 105874, 20116, 125990);
INSERT INTO PEDIDO VALUES (5003, 'TRK-EST-202409-003', 12, 2, 1, 3, DATE '2024-09-07', 147882, 28098, 175980);

-- Pedidos asignados a Valentina Pérez (id_trabajador = 3)
INSERT INTO PEDIDO VALUES (5004, 'TRK-EST-202409-004', 13, 3, 1, 5, DATE '2024-09-03', 121840, 23150, 144990);
INSERT INTO PEDIDO VALUES (5005, 'TRK-EST-202409-005', 10, 3, 3, 4, DATE '2024-09-06', 159647, 30333, 189980);
INSERT INTO PEDIDO VALUES (5006, 'TRK-EST-202409-006', 11, 3, 1, 2, DATE '2024-09-08', 75622, 14368, 89990);

-- Pedidos asignados a Felipe Morales (id_trabajador = 4)
INSERT INTO PEDIDO VALUES (5007, 'TRK-EST-202409-007', 12, 4, 2, 5, DATE '2024-09-05', 47050, 8940, 55990);

-- Pedidos asignados a Lucas Ramírez (id_trabajador = 5, meta = 0)
INSERT INTO PEDIDO VALUES (5008, 'TRK-EST-202409-008', 13, 5, 1, 3, DATE '2024-09-08', 33605, 6385, 39990);

-- 10. Detalle de los Pedidos (Precios en CLP y Tallas Variadas)
INSERT INTO DETALLE_PEDIDO VALUES (1, 5001, 201, 'L',        1, 39990, 39990);
INSERT INTO DETALLE_PEDIDO VALUES (2, 5001, 205, 'M',        1, 45990, 45990);

INSERT INTO DETALLE_PEDIDO VALUES (3, 5002, 208, '42',       1, 74990, 74990);
INSERT INTO DETALLE_PEDIDO VALUES (4, 5002, 209, 'ESTANDAR', 1, 16990, 16990);
INSERT INTO DETALLE_PEDIDO VALUES (5, 5002, 210, 'ESTANDAR', 1, 22990, 22990);

INSERT INTO DETALLE_PEDIDO VALUES (6, 5003, 207, '41',       2, 69990, 139980);
INSERT INTO DETALLE_PEDIDO VALUES (7, 5003, 203, 'M',        1, 21990, 21990);

INSERT INTO DETALLE_PEDIDO VALUES (8, 5004, 208, '42',       1, 74990, 74990);
INSERT INTO DETALLE_PEDIDO VALUES (9, 5004, 207, '41',       1, 69990, 69990);

INSERT INTO DETALLE_PEDIDO VALUES (10, 5005, 202, 'XL',      1, 42990, 42990);
INSERT INTO DETALLE_PEDIDO VALUES (11, 5005, 205, 'M',       2, 45990, 91980);
INSERT INTO DETALLE_PEDIDO VALUES (12, 5005, 209, 'ESTANDAR', 1, 16990, 16990);

INSERT INTO DETALLE_PEDIDO VALUES (13, 5006, 201, 'L',       2, 39990, 79980);
INSERT INTO DETALLE_PEDIDO VALUES (14, 5006, 204, 'S',       1, 19990, 19990);

INSERT INTO DETALLE_PEDIDO VALUES (15, 5007, 206, 'L',       1, 34990, 34990);
INSERT INTO DETALLE_PEDIDO VALUES (16, 5007, 203, 'M',       1, 21990, 21990);

INSERT INTO DETALLE_PEDIDO VALUES (17, 5008, 201, 'L',       1, 39990, 39990);

-- 11. Historial de Tracking para visualización del cliente en la Tienda Online
INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (1, 5001, 1, DATE '2024-09-02', 'Cliente generó el pedido desde la tienda online');
INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (2, 5001, 2, DATE '2024-09-02', 'Pago confirmado mediante Webpay Plus');
INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (3, 5001, 3, DATE '2024-09-02', 'Trabajador Ignacio López inició empaquetamiento en bodega');
INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (4, 5001, 4, DATE '2024-09-03', 'Paquete entregado a empresa de courier con número de seguimiento');
INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (5, 5001, 5, DATE '2024-09-04', 'Entregado en domicilio del cliente en Providencia');

INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (6, 5002, 2, DATE '2024-09-04', 'Pago confirmado por Mercado Pago');
INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (7, 5002, 3, DATE '2024-09-04', 'En proceso de embalaje y control de calidad');
INSERT INTO HISTORIAL_TRACKING_PEDIDO VALUES (8, 5002, 4, DATE '2024-09-05', 'En camino a domicilio');

COMMIT;

-- Mensaje de verificación final
PROMPT =========================================================================;
PROMPT BASE DE DATOS 'ESTILO URBANO' CREADA Y POBLADA EXITOSAMENTE EN ORACLE;
PROMPT =========================================================================;
