-- Description: Monthly revenue by product category (Northwind)
-- Params: change the year filter as needed

WITH order_lines AS (
  SELECT
    o.order_id,
    date_trunc('month', o.order_date)::date AS month,
    (od.unit_price * od.quantity * (1 - od.discount))::numeric AS line_revenue,
    p.category_id
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  JOIN products p       ON od.product_id = p.product_id
  WHERE o.order_date >= DATE '1997-01-01' AND o.order_date < DATE '1998-01-01'  -- adjust year
),
cat_month AS (
  SELECT
    ol.month,
    c.category_name,
    SUM(ol.line_revenue) AS total_revenue
  FROM order_lines ol
  JOIN categories c ON ol.category_id = c.category_id
  GROUP BY ol.month, c.category_name
)
SELECT
  month,
  category_name,
  ROUND(total_revenue, 2) AS total_revenue_usd
FROM cat_month
ORDER BY month, category_name;
