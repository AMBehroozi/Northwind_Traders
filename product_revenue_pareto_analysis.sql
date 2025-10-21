-- Product Pareto (80/20) analysis: which products drive most revenue
WITH product_revenue AS (
  SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(DISTINCT o.order_id) AS orders_count,
    SUM((od.unit_price * od.quantity * (1 - od.discount))::numeric) AS total_revenue,
    SUM(od.quantity) AS total_units,
    AVG(od.unit_price)::numeric(12,2) AS avg_unit_price
  FROM order_details od
  JOIN orders       o ON od.order_id = o.order_id
  JOIN products     p ON od.product_id = p.product_id
  JOIN categories   c ON p.category_id = c.category_id
  GROUP BY p.product_id, p.product_name, c.category_name
),
ranked AS (
  SELECT
    product_id,
    product_name,
    category_name,
    orders_count,
    total_units,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    SUM(total_revenue) OVER () AS grand_total_revenue,
    SUM(total_revenue) OVER (ORDER BY total_revenue DESC
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue
  FROM product_revenue
)
SELECT
  product_id,
  product_name,
  category_name,
  orders_count,
  total_units,
  ROUND(total_revenue, 2) AS total_revenue_usd,
  revenue_rank,
  ROUND(100 * total_revenue / grand_total_revenue, 2) AS contribution_pct,
  ROUND(100 * running_revenue / grand_total_revenue, 2) AS cumulative_pct
FROM ranked
-- uncomment ONE of the filters below, depending on what you want:
-- 1) show only products until we reach ~80% of revenue (Pareto front):
-- WHERE (running_revenue / grand_total_revenue) <= 0.80
-- 2) or simply show top N products by revenue:
-- WHERE revenue_rank <= 10
ORDER BY total_revenue DESC;
