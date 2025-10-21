-- Description: Computes customer lifetime value (CLV), most frequent product, and sales rank.
-- Dataset: Northwind Traders
-- Week: 5 – Advanced relational aggregation and window functions

WITH order_sales AS (
  SELECT
    o.customer_id,
    o.order_id,
    SUM((od.unit_price * od.quantity * (1 - od.discount))::numeric) AS order_total
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY o.customer_id, o.order_id
),
customer_totals AS (
  SELECT
    c.customer_id,
    c.company_name,
    COUNT(os.order_id) AS total_orders,
    ROUND(SUM(os.order_total), 2) AS total_revenue,
    ROUND(AVG(os.order_total), 2) AS avg_order_value
  FROM customers c
  JOIN order_sales os ON c.customer_id = os.customer_id
  GROUP BY c.customer_id, c.company_name
),
top_products AS (
  SELECT
    o.customer_id,
    p.product_id,
    p.product_name,
    COUNT(*) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY COUNT(*) DESC) AS rn
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  JOIN products p ON od.product_id = p.product_id
  GROUP BY o.customer_id, p.product_id, p.product_name
),
ranked_customers AS (
  SELECT
    ct.*,
    RANK() OVER (ORDER BY ct.total_revenue DESC) AS revenue_rank
  FROM customer_totals ct
)
SELECT
  rc.customer_id,
  rc.company_name,
  rc.total_orders,
  rc.total_revenue,
  rc.avg_order_value,
  tp.product_name AS most_frequent_product,
  rc.revenue_rank
FROM ranked_customers rc
LEFT JOIN top_products tp
  ON rc.customer_id = tp.customer_id AND tp.rn = 1
ORDER BY rc.revenue_rank;
