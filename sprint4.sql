-- Nivel 1, Ejercicio 1
SELECT  t.*, c.company_name, c.country
FROM 
    `sprint3-analytics-reneb.sprint3_bronze.transactions_raw` AS t
JOIN 
    `sprint3-analytics-reneb.sprint3_bronze.companies_raw` AS c 
    ON t.business_id = c.company_id
WHERE DATE(t.timestamp) = '2022-03-12' AND c.country = 'Germany';

-- creación tabla transactions_recent
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_silver.transactions_recent`
AS
SELECT
  * EXCEPT (timestamp),
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL CAST(RAND() * 50 AS INT64) DAY)
    AS timestamp
FROM `sprint3-analytics-reneb.sprint3_silver.transactions_clean`;

-- creación de tabla optimizada transactions_optimized
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_gold.fact_transactions_optimized`
  PARTITION BY DATE(timestamp) CLUSTER BY company_id
AS
SELECT * FROM `sprint3-analytics-reneb.sprint3_silver.transactions_recent`;

-- paso 1 tabla no particionada
SELECT 
    * 
FROM 
    `sprint3-analytics-reneb.sprint3_silver.transactions_recent`
WHERE 
    timestamp >= TIMESTAMP("2026-08-31");
    
    -- paso 2 tabla particionada
SELECT 
    * 
FROM 
    `sprint3-analytics-reneb.sprint3_gold.fact_transactions_optimized`
WHERE 
    timestamp >= TIMESTAMP("2026-08-31");
    
    -- crear vista 
    CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-reneb.sprint3_gold.mv_daily_sales`
AS
SELECT
    DATE(timestamp) AS sales_date,
    SUM(amount) AS total_sales,
    COUNT(*) AS total_transactions
FROM
    `sprint3-analytics-reneb.sprint3_gold.fact_transactions_optimized`
WHERE declined = 0
GROUP BY
    1;
    
    -- cpnsulta vista
    SELECT * FROM `sprint3-analytics-reneb.sprint3_gold.mv_daily_sales`
ORDER BY sales_date DESC;

-- Nivel 2, Ejercicio 1
WITH VIP_Stats AS (
    SELECT
    user_id,ROUND(SUM(amount),2) AS total_gastado,COUNT(transaction_id) AS num_compras,ROUND(AVG(amount), 2) AS tiquet_media,
    MAX(amount) AS max_compra
    FROM`sprint3-analytics-reneb.sprint3_gold.fact_transactions_optimized`
    
    WHERE declined = 0
 GROUP BY user_id
    HAVING total_gastado >= 500 )

SELECT v.user_id, CONCAT(u.name, ' ', u.surname) AS nom_complet,u.email, v.num_compras, v.tiquet_media,
v.max_compra,v.total_gastado
FROM VIP_Stats AS v
JOIN `sprint3-analytics-reneb.sprint3_silver.users_combined`AS u
    ON v.user_id = u.user_id
ORDER BY  v.total_gastado DESC;

-- Ejercicio 2
WITH
  sales_lag AS (
    SELECT
      sales_date AS Data,
      total_sales AS Vendes_Avui,
      LAG(total_sales) OVER (ORDER BY sales_date) AS Vendes_Ahir
    FROM `sprint3-analytics-reneb.sprint3_gold.mv_daily_sales`
  )
SELECT
  Data,
  ROUND(Vendes_Avui, 2) AS Vendes_Avui,
  ROUND(Vendes_Ahir, 2) AS Vendes_Ahir,
  ROUND(SAFE_DIVIDE(Vendes_Avui - Vendes_Ahir, Vendes_Ahir) * 100, 2)
    AS Diff_Percentual
FROM sales_lag
ORDER BY Data DESC;

-- Ejercicio 3 
SELECT
sales_date AS Data,
ROUND(CAST(total_sales AS NUMERIC), 2) AS Vendes_del_Dia,
ROUND(SUM(CAST(total_sales AS NUMERIC))
OVER (PARTITION BY EXTRACT(YEAR FROM sales_date)
ORDER BY sales_date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS Vendes_Acumulades_YTD
FROM `sprint3-analytics-reneb.sprint3_gold.mv_daily_sales`
ORDER BY Data DESC;

-- Ejercicio 4 
WITH
  RankedPurchases AS (
    SELECT user_id, timestamp AS fecha_3a_compra, amount AS importe_3a_compra,
      ROW_NUMBER()
        OVER (PARTITION BY user_id ORDER BY timestamp ASC) AS purchase_rank,
      AVG(amount)
        OVER (
          PARTITION BY user_id
          ORDER BY timestamp ASC
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_3_primeras
    FROM `sprint3-analytics-reneb.sprint3_gold.fact_transactions_optimized`
    WHERE declined = 0
    QUALIFY purchase_rank = 3 )
SELECT
  r.user_id, CONCAT(u.name, ' ', u.surname) AS nom_complet, u.email, r.fecha_3a_compra,
  ROUND(CAST(r.importe_3a_compra AS NUMERIC), 2) AS importe_3a_compra,
  ROUND(CAST(r.media_3_primeras AS NUMERIC), 2) AS media_3_primeras
FROM RankedPurchases r
JOIN `sprint3-analytics-reneb.sprint3_silver.users_combined` u
  ON r.user_id = u.user_id
ORDER BY media_3_primeras DESC;

-- Nivel 3, Ejercicio 1
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_gold.dim_transactions_flat` AS
SELECT t.transaction_id, t.timestamp, t.user_id, p.product_id, t.amount AS total_ticket_amount, t.declined, p.name AS product_name,
p.price AS individual_price,t.card_id,t.company_id

FROM `sprint3-analytics-reneb.sprint3_silver.transactions_clean` AS t

CROSS JOIN UNNEST(t.product_ids) AS individual_product_id

JOIN `sprint3-analytics-reneb.sprint3_silver.products_clean` AS p
ON individual_product_id  = p.product_id ;

-- Ejercicio 2 
SELECT
  product_name,
  COUNT(product_id) AS unidades_vendidas,
  COUNT(DISTINCT transaction_id) AS numero_transacciones
FROM `sprint3-analytics-reneb.sprint3_gold.dim_transactions_flat`
GROUP BY product_id, product_name
ORDER BY unidades_vendidas DESC
LIMIT 5;


-- Ejercicio 3
-- creacion de función
CREATE OR REPLACE FUNCTION `sprint3-analytics-reneb.sprint3_gold.calculate_tax_amount`(
  importe_base FLOAT64, tipo_impositivo FLOAT64)
RETURNS FLOAT64
AS (
  ROUND(importe_base * tipo_impositivo, 2)
);

-- creación de tabla con nueva columna
CREATE OR REPLACE TABLE `sprint3-analytics-reneb.sprint3_gold.dim_transactions_flat`
AS
SELECT
  transaction_id, timestamp, user_id, product_id, total_ticket_amount,declined, product_name,
 individual_price,card_id, company_id,
  ROUND(
    individual_price + `sprint3-analytics-reneb.sprint3_gold.calculate_tax_amount`(
      individual_price, 0.21),
    2)
    AS product_price_tax_inc
FROM `sprint3-analytics-reneb.sprint3_gold.dim_transactions_flat`;







