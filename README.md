# 🧮 Northwind Analytics for PostgreSQL

This repository contains a fully populated **Northwind sample database** for PostgreSQL, along with a curated collection of **advanced analytical SQL queries**.  
It’s designed for **data engineering and data analytics practice**, focusing on query optimization, relational joins, and window functions.

---

## 📘 Overview

The Northwind database models a fictional company that sells products around the world.  
This version has been adapted for **PostgreSQL**, with a clean schema and all foreign key constraints preserved.

You can use it to:
- Practice writing and optimizing SQL queries.
- Explore multi-table joins, CTEs, and window functions.
- Build data engineering or BI portfolio projects.

---

## 📂 Repository Structure

| File | Description |
|------|--------------|
| `create_and_filling_tables.sql` | Creates all Northwind tables and populates them with sample data. |
| `ERD.png` | Entity–Relationship Diagram of the database schema. |
| `employee_sales_performance.sql` | Reports total orders and sales revenue per employee, including average order value and ranking. |
| `customer_lifetime_value_analysis.sql` | Calculates customer lifetime value (CLV), order frequency, and most frequently purchased product. |
| `product_revenue_pareto_analysis.sql` | Identifies top products contributing to ~80% of total revenue (Pareto principle). |
| `monthly_category_revenue.sql` | Summarizes monthly revenue by product category (ideal for time-series analysis). |
| `region_category_performance.sql` | Complex multi-table query reporting Region × Category performance with suppliers, discounts, and top shippers. |
| `README.md` | Project documentation (this file). |

