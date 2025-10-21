-- Orders handled per employee with total orders and sales value
SELECT
    e.employee_id,
    e.last_name || ', ' || e.first_name AS employee_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM((od.unit_price * od.quantity * (1 - od.discount))::numeric), 2) AS total_sales_usd,
    ROUND(AVG((od.unit_price * od.quantity * (1 - od.discount))::numeric), 2) AS avg_order_value_usd
FROM employees AS e
JOIN orders AS o
    ON e.employee_id = o.employee_id
JOIN order_details AS od
    ON o.order_id = od.order_id
GROUP BY e.employee_id, e.last_name, e.first_name
ORDER BY total_sales_usd DESC;
