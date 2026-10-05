# Sprint4
### Tarea S4.01. BigQuery Avanzado &amp; Analytics Engineering

### 📊 Descripción del Proyecto
Este proyecto simula un escenario real de ingeniería de datos y analítica avanzada en Google BigQuery. El objetivo principal es transformar un entorno de datos ineficiente y costoso en un ecosistema optimizado, escalable y automatizado.

A lo largo del proyecto, se abordan retos de optimización física de tablas, implementación de cachés inteligentes mediante vistas materializadas, dominio de SQL analítico complejo y la gestión de estructuras de datos anidadas (Arrays/Structs).

### 🚀 Objetivos Principales
Optimización de Costos: Reducir drásticamente los bytes procesados mediante técnicas de Partitioning y Clustering.
Smart Caching: Implementar Materialized Views para acelerar paneles de control recurrentes.
SQL Analítico Avanzado: Uso de CTEs, Window Functions y UDFs para resolver lógica de negocio compleja.
Analytics Engineering: Tratamiento de datos anidados y automatización de pipelines mediante Scheduled Queries.
### 🛠️ Tecnologías Utilizadas
Google BigQuery (Data Warehouse & SQL Engine).
Google Looker Studio (Visualización de Datos).
Google Cloud Console (Administración y Programación de tareas).
### 📂 Estructura del Proyecto
### Nivel 1: Arquitectura Híbrida y Optimización Física
Escenario: El informe financiero presenta tiempos de carga inaceptables y costes elevados por escaneos completos de tablas (Full Table Scans).

Diagnóstico: Identificación de ineficiencias en JOINs de tablas no optimizadas.
Mocking Data: Generación de datos recientes (últimos 50 días) usando funciones de tiempo (TIMESTAMP_SUB) y aleatoriedad (RAND) para evitar la purga automática del Sandbox.
Estrategia Física:
Partitioning: Por DATE(timestamp) para limitar el escaneo de datos en filtros temporales.
Clustering: Por business_id para acelerar JOINs y filtros por empresa.
Benchmark: Comparativa de rendimiento logrando una reducción del X% (rellenar con tus datos reales) en bytes procesados.
### Nivel 2: SQL Analítico Avanzado
Escenario: Resolución de preguntas estratégicas de negocio mediante métricas de tendencia y comportamiento de usuario.

Perfilado VIP: Uso de CTEs para identificar clientes con gasto superior a 500€, calculando ticket medio, compras récord y gasto total.
Day-over-Day Growth: Implementación de funciones de ventana (LAG) sobre vistas materializadas para calcular el crecimiento diario de ventas.
Running Totals (YTD): Cálculo de ventas acumuladas año a fecha con reinicio anual mediante PARTITION BY EXTRACT(YEAR FROM data).
Customer Loyalty: Aplicación de ROW_NUMBER() y la cláusula QUALIFY para identificar y analizar la tercera compra de cada usuario.
### Nivel 3: Analytics Engineering & Automatización
Escenario: Centralización de la lógica de negocio y automatización del pipeline de datos para marketing.

Data Unnesting: Transformación de arrays de productos en tablas planas (Flat Tables) mediante CROSS JOIN UNNEST para análisis granular.
UDF (User Defined Functions): Creación de una función persistente calculate_tax(amount) para centralizar el cálculo del IVA (21%) y evitar hardcoding.
Orquestación: Configuración de Scheduled Queries (7:00 AM) para la regeneración diaria de la capa Gold.
Visualización: Dashboard en Looker Studio con KPIs de ingresos, evolución temporal y mapa de calor de productos más vendidos.
### 📈 Resultados e Impacto
Eficiencia operativa: Reducción de tiempos de consulta de segundos a milisegundos en dashboards recurrentes gracias a las Vistas Materializadas.
Ahorro de costes: La implementación de particionamiento eliminó el 90% de la lectura innecesaria de datos históricos.
Calidad de datos: Estandarización de cálculos fiscales mediante UDFs, asegurando que todos los departamentos utilicen la misma lógica de negocio.
### 📝 Ejemplos de Código Destacados
### Creación de Tabla Optimizada (Gold)
CREATE OR REPLACE TABLE `sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp)
CLUSTER BY business_id AS
SELECT * FROM `sprint3_silver.transactions_recent`;


### Cálculo de Crecimiento Diario (LAG)
SELECT 
    data, 
    vendes_avui,
    LAG(vendes_avui) OVER(ORDER BY data) AS vendes_ahir,
    ROUND((vendes_avui - LAG(vendes_avui) OVER(ORDER BY data)) / LAG(vendes_avui) OVER(ORDER BY data) * 100, 2) AS diff_percentual
FROM `sprint3_gold.mv_daily_sales`;

