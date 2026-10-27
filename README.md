# SQL Supply Chain Analytics Project

## **Project Overview**

This project is a SQL practice exercise based on a fictional supply chain business. The company purchases products from suppliers, stores them in warehouses, and sells them to customers.

The database consists of **13 interconnected tables** containing synthetic data from **2024 to 2025**. The project focuses on solving 20 real-world business problems using SQL to analyse sales, inventory, procurement, supplier performance, customer behaviour, and warehouse operations.

**Key Objectives:**
- Analyse revenue, gross margin, and product profitability.
- Identify low-stock products and inventory replenishment requirements.
- Evaluate supplier reliability and delivery performance.
- Understand customer purchasing behaviour and regional demand.
- Analyse shipping costs, delivery delays, and product returns.
- Optimise warehouse capacity and inventory flow.
- Practise SQL data manipulation, transactions, and query performance tuning.

## **Database Structure**

The database contains the following tables:

- `suppliers`
- `products`
- `warehouses`
- `carriers`
- `employees`
- `customers`
- `inventory`
- `purchase_orders`
- `po_items`
- `sales_orders`
- `order_items`
- `shipments`
- `returns`

**Data Coverage:** 2024–2025  
**Total Tables:** 13

## **Business Problems Solved**

### **I. Basics: Filtering, Aggregation, and Grouping**

1. **Revenue Overview:** Calculate net revenue after discounts, gross margin, and margin percentage by product category. Filter categories using a revenue threshold and rank them by performance.
2. **Regional Demand:** Analyse orders, units sold, and revenue by region and customer segment, including regional subtotals.
3. **Low-Stock Alert:** Identify products at or below their reorder levels across warehouses. Categorise stock as Out of Stock, Critical, or Low, and summarise inventory status.

### **II. Joins**

4. **Supplier Scorecard:** Calculate supplier on-time delivery percentage, average delivery delay, and fill rate. Rank suppliers by reliability.
5. **Dead Stock:** Identify products that have never been sold and products missing from specific warehouse inventories.
6. **Customers with No Activity:** Find customers who have never placed an order and those who ordered in 2024 but not in 2025.
7. **Organisational Chart:** Display employees alongside their managers and roles. Identify managers whose teams exceed a specified salary cost.

### **III. Subqueries and CTEs**

8. **Above-Average Performers:** Identify products whose total sales exceed the average sales of products in their respective categories using correlated subqueries.
9. **Customer Lifetime Value:** Use Common Table Expressions (CTEs) to calculate customer spending, order count, average order value, and days since the last order. Segment customers into VIP, Regular, and At-risk categories.
10. **Delivery Performance by Carrier:** Compare carriers based on SLA breach rate, average shipping cost per order, and average delivery delay. Identify the most cost-effective carrier mode.

### **IV. Window Functions**

11. **Top Sellers:** Rank the top three products in each category by annual revenue. Handle ties using `RANK()`, `DENSE_RANK()`, or `ROW_NUMBER()`.
12. **Trend Analysis:** Calculate monthly revenue, month-over-month growth percentage, year-to-date running totals, and three-month moving averages.
13. **Order Frequency:** Calculate the number of days between consecutive customer orders and determine the average order gap by customer segment.
14. **Pareto Analysis (ABC Classification):** Calculate cumulative revenue share and classify products into A (top 80%), B (next 15%), and C (remaining products). Explore `NTILE()` as an alternative classification approach.

### **V. Date Functions, Strings, and NULL Handling**

15. **Seasonality Analysis:** Compare revenue by quarter and day of the week. Identify peak revenue months and the busiest shipping days.
16. **Data Cleaning:** Standardise customer emails using lowercase conversion and trimming, extract email domains, replace missing emails with placeholders, and identify unusable contact information.
17. **Open Order Aging:** Calculate overdue days for open and in-transit purchase orders. Categorise orders into 0–7, 8–15, and 15+ day buckets using `CASE`.

### **VI. Set Operations and Pivoting**

18. **Returns Analysis:** Calculate return rates by product, category, and supplier. Pivot return reasons into separate columns using conditional aggregation. Compare top-selling and most-returned products using `INTERSECT` and `EXCEPT`.

### **VII. Advanced Analytics and Operations**

19. **Warehouse Capacity and Flow:** Create a view showing stock units, capacity utilisation percentage, monthly units sold, and monthly units received for each warehouse. Recommend a warehouse for the next purchase order and use a recursive CTE to build the employee management hierarchy from the CEO downward.
20. **Operational Tasks and Performance Tuning:** 
    - Create a reorder-suggestion table using `INSERT ... SELECT`.
    - Update supplier ratings based on on-time delivery performance.
    - Execute a stock transfer between two warehouses within a transaction.
    - Delete outdated cancelled records.
    - Add indexes to frequently joined columns and compare execution plans using `EXPLAIN`.

## **SQL Concepts and Techniques Used**

The project covers the following SQL concepts:

- **Filtering and Sorting:** `WHERE`, `ORDER BY`, `DISTINCT`
- **Aggregation:** `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
- **Grouping:** `GROUP BY`, `HAVING`, `WITH ROLLUP`
- **Joins:** `INNER JOIN`, `LEFT JOIN`, multi-table joins
- **Subqueries:** Correlated subqueries, `EXISTS`, `NOT EXISTS`
- **Common Table Expressions:** `WITH`, multiple CTEs, recursive CTEs
- **Window Functions:** `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()`, running totals, moving averages
- **Date Functions:** Date differences, date extraction, monthly and quarterly analysis
- **String Functions:** `LOWER()`, `TRIM()`, email domain extraction
- **NULL Handling:** `COALESCE()` and missing-value treatment
- **Conditional Logic:** `CASE WHEN`
- **Set Operations:** `INTERSECT`, `EXCEPT`
- **Data Manipulation:** `INSERT`, `UPDATE`, `DELETE`
- **Database Objects:** Views, tables, and indexes
- **Transactions:** `START TRANSACTION`, `COMMIT`, and `ROLLBACK`
- **Performance Tuning:** `EXPLAIN` and index optimisation

## **Approach and Analysis**

I approached the project by solving practical business problems step by step, starting with basic sales analysis and progressing to advanced SQL techniques.

- **Revenue and Profitability Analysis:** Calculated net revenue and gross margin by product category using joins, `GROUP BY`, and `HAVING`.
- **Regional Sales Analysis:** Analysed order volume, units sold, and revenue by region and customer segment using multiple joins and `WITH ROLLUP` for subtotals.
- **Inventory Monitoring:** Developed low-stock alerts using `CASE` expressions and CTEs to identify products requiring replenishment.
- **Supplier Performance Analysis:** Built supplier scorecards using CTEs and `RANK()` to evaluate delivery reliability, delays, and fill rates.
- **Inventory and Product Availability:** Identified never-sold products and products missing from warehouse inventory using `LEFT JOIN ... IS NULL` and `NOT EXISTS`.
- **Customer Data Cleaning:** Standardised email addresses using `LOWER()`, `TRIM()`, and `COALESCE()`, and identified missing or unusable contact information.
- **Purchase Order Aging:** Calculated overdue days and categorised open purchase orders into date-based buckets using `CASE`.
- **Returns Analysis:** Pivoted return reasons using conditional aggregation and compared product lists using `INTERSECT` and `EXCEPT`.
- **Warehouse and Organisational Analysis:** Created a warehouse stock-flow view and generated the employee management hierarchy using a recursive CTE.
- **Database Operations and Optimisation:** Practised data updates, deletions, transaction management, and index tuning using `UPDATE`, `DELETE`, `COMMIT`, and `EXPLAIN`.

## **Business Value**

This project demonstrates how SQL can be applied to practical supply chain and business analytics scenarios to:

- Improve inventory visibility and replenishment decisions.
- Identify profitable product categories and high-performing products.
- Monitor supplier and carrier performance.
- Understand customer demand and purchasing patterns.
- Reduce operational inefficiencies and improve warehouse utilisation.
- Maintain cleaner data and improve query performance.

## **Skills Demonstrated**

**SQL | Supply Chain Analytics | Sales Analysis | Inventory Management | Procurement Analytics | Data
