-- File: region_category_performance.sql
-- Description: Region × Category performance with revenue, orders, discount, suppliers, and top shipper.
-- Dataset: Northwind Traders (PostgreSQL dialect)

WITH
-- 1) Choose a single "primary" territory per employee to avoid double-counting.
employee_primary_territory AS (
  SELECT employee_id, territory_id
  FROM (
    SELECT
      et.employee_id,
      et.territory_id,
      ROW_NUMBER() OVER (PARTITION BY et.employee_id ORDER BY et.territory_id) AS rn
    FROM employee_territories et
  ) x
  WHERE rn = 1
),

-- 2) Enrich territories with their Region name
employee_region AS (
  SELECT
    ept.employee_id,
    r.region_description AS region_name
  FROM employee_primary_territory ept
  JOIN territories t ON ept.territory_id = t.territory_id
  JOIN region r      ON t.region_id = r.region_id
),

-- 3) Order lines (filter for a specific year)
order_lines AS (
  SELECT
    o.order_id,
    o.employee_id,
    o.order_date::date AS order_date,
    o.ship_via,
    od.product_id,
    (od.unit_price * od.quantity * (1 - od.discount))::numeric AS line_revenue,
    od.discount::numeric AS line_discount,
    od.quantity
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  WHERE o.order_date >= make_date(1997, 1, 1)
    AND o.order_date <  make_date(1998, 1, 1)
),

-- 4) Enrich lines with product/category/supplier and employee region
lines_enriched AS (
  SELECT
    ol.order_id,
    ol.employee_id,
    er.region_name,
    ol.order_date,
    ol.ship_via,
    c.category_id,
    c.category_name,
    p.product_id,
    s.supplier_id,
    ol.quantity,
    ol.line_revenue,
    ol.line_discount
  FROM order_lines ol
  JOIN products   p  ON ol.product_id = p.product_id
  JOIN categories c  ON p.category_id = c.category_id
  JOIN suppliers  s  ON p.supplier_id = s.supplier_id
  LEFT JOIN employee_region er ON ol.employee_id = er.employee_id
),

-- 5) Revenue by shipper to find the top shipper per Region×Category
shipper_rev AS (
  SELECT
    le.region_name,
    le.category_id,
    le.category_name,
    o.ship_via,
    SUM(le.line_revenue) AS rev_by_shipper
  FROM lines_enriched le
  JOIN orders o ON le.order_id = o.order_id
  GROUP BY le.region_name, le.category_id, le.category_name, o.ship_via
),

ranked_shipper AS (
  SELECT
    sr.*,
    SUM(sr.rev_by_shipper) OVER (PARTITION BY sr.region_name, sr.category_id) AS region_cat_total,
    ROW_NUMBER() OVER (
      PARTITION BY sr.region_name, sr.category_id
      ORDER BY sr.rev_by_shipper DESC
    ) AS rn
  FROM shipper_rev sr
),

top_shipper AS (
  SELECT
    rs.region_name,
    rs.category_id,
    rs.category_name,
    rs.ship_via,
    rs.rev_by_shipper,
    rs.region_cat_total,
    ROUND(100 * rs.rev_by_shipper / NULLIF(rs.region_cat_total, 0), 2) AS top_shipper_pct
  FROM ranked_shipper rs
  WHERE rs.rn = 1
),

-- 6) Main Region×Category KPIs
region_category AS (
  SELECT
    le.region_name,
    le.category_id,
    le.category_name,
    COUNT(DISTINCT le.order_id) AS orders_count,
    SUM(le.line_revenue)        AS total_revenue,
    SUM(le.quantity)            AS total_units,
    CASE
      WHEN SUM(le.line_revenue) = 0 THEN NULL
      ELSE ROUND(SUM(le.line_discount * le.line_revenue) / SUM(le.line_revenue), 4)
    END AS revenue_weighted_discount,
    COUNT(DISTINCT le.supplier_id) AS distinct_suppliers
  FROM lines_enriched le
  GROUP BY le.region_name, le.category_id, le.category_name
),

ranked_region_category AS (
  SELECT
    rc.*,
    ROUND(
      CASE WHEN rc.orders_count = 0 THEN NULL
           ELSE (rc.total_revenue / rc.orders_count)
      END
    , 2) AS avg_order_value,
    RANK() OVER (PARTITION BY rc.region_name ORDER BY rc.total_revenue DESC) AS revenue_rank_in_region
  FROM region_category rc
)

SELECT
  rrc.region_name,
  rrc.category_id,
  rrc.category_name,
  rrc.orders_count,
  ROUND(rrc.total_revenue, 2) AS total_revenue_usd,
  rrc.avg_order_value,
  rrc.total_units,
  rrc.revenue_weighted_discount AS avg_discount_weighted,
  rrc.distinct_suppliers,
  ts.ship_via AS top_shipper_id,
  ts.top_shipper_pct,
  rrc.revenue_rank_in_region
FROM ranked_region_category rrc
LEFT JOIN top_shipper ts
  ON rrc.region_name = ts.region_name
 AND rrc.category_id = ts.category_id
ORDER BY rrc.region_name NULLS LAST, rrc.revenue_rank_in_region, rrc.category_name;
