# ⚡ ESTILO URBANO — Official E-Commerce & Oracle Database Platform

Plataforma oficial de comercio electrónico y gestión de base de datos para la marca de streetwear **Estilo Urbano**, desarrollada para la asignatura **Taller de Base de Datos (BDY1103)** de **Duoc UC**.

🌐 **Demo en Vivo (GitHub Pages):** [https://eduardo-aranguiz-armijo.github.io/EstiloUrbano/](https://eduardo-aranguiz-armijo.github.io/EstiloUrbano/)

### 👥 Datos del Proyecto y Entrega
* **Integrantes:** Eduardo Aránguiz — Luciano Zaninovic — Kevin Urbina
* **Docente:** Cristian Medina
* **Nivel / Semestre:** 4° Semestre (2026)
* **Fecha de Entrega:** 16 de Septiembre de 2026 (Evaluación Parcial N° 1)

---

## 🚀 Características Principales

* **E-Commerce de Moda Urbana:** Catálogo dinámico de prendas streetwear (Hoodies oversize, poleras boxy fit, pantalones cargo, sneakers y accesorios), con selector de tallas y bolsa de compras interactiva.
* **Pasarela de Pago Segura (Webpay Plus / Transbank):**
  * Maqueta de tarjeta bancaria interactiva (con detección de franquicias Visa, Mastercard, AMEX y código de seguridad CVC/CVV).
  * Simulación en tiempo real de autorización con el banco emisor.
  * Comprobante oficial de venta (**Voucher Webpay Plus**) con N° de folio, código de autorización y desglose de cuotas en CLP.
* **Paneles Segregados por Rol:**
  * **👑 Administrador (`admin@estilourbano.cl` / `admin123`):** Gestión integral de catálogo (altas, bajas, fotos, precios, stock), proveedores oficiales y KPIs de ventas.
  * **📦 Trabajador (`ilopez@estilourbano.cl` / `trabajador123`):** Control logístico de despacho en 4 fases (*Pagado* -> *Empacando* -> *En Camino* -> *Entregado*), atención de dudas técnicas y monitoreo de reseñas.
  * **🛍️ Cliente (`scastro@gmail.com` / `cliente123`):** Portal privado con historial de órdenes, barra de tracking en vivo, calificación con estrellas y gestión de dirección.

---

## 🗄️ Arquitectura de Base de Datos (Oracle 23ai)

1. **[`01_esquema_estilo_urbano.sql`](01_esquema_estilo_urbano.sql):** Definición DDL y DML de tablas relacionales.
2. **[`02_bloque_anonimo_plsql.sql`](02_bloque_anonimo_plsql.sql):** Bloque anónimo PL/SQL con `RECORD`, `VARRAY`, cursores explícitos parametrizados en bucles anidados y excepciones.
3. **[`INFORME_EP1_ESTILO_URBANO.md`](INFORME_EP1_ESTILO_URBANO.md):** Informe académico formal completo según pauta oficial Duoc UC.
4. **[`PRESENTACION_EJECUTIVA_EP1.md`](PRESENTACION_EJECUTIVA_EP1.md):** Estructura de 10 diapositivas, guion verbal y banco de preguntas para defensa oral.

---

## 🔐 Credenciales de Prueba (Manual Login)

| Rol | Correo Electrónico | Contraseña | Nombre |
| :--- | :--- | :--- | :--- |
| **Administrador** | `admin@estilourbano.cl` | `admin123` | Carlos Gómez |
| **Trabajador** | `ilopez@estilourbano.cl` | `trabajador123` | Ignacio López |
| **Cliente** | `scastro@gmail.com` | `cliente123` | Sebastián Castro |

---

© 2026 Estilo Urbano SpA. Duoc UC — Escuela de Informática y Telecomunicaciones.
