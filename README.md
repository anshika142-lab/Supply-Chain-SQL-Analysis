This project is a SQL practice exercise based on a made-up supply chain business. 
The company buys products from suppliers, stores them in warehouses, and sells them to customers. 
The database has 13 linked tables covering suppliers, products, inventory, purchase orders, sales, shipments and returns, with synthetic data from 2024 to 2025.
On top of the data are 20 business questions, such as which product categories earn the best margin, which items are running out of stock, which suppliers deliver late, and which warehouse should receive the next order. Solving them covers the main SQL skills: joins, grouping, subqueries, CTEs, window functions, data cleaning, views, transactions and indexes.


The database has 13 tables covering 2024 to 2025:

Table	                                                      
suppliers                                       
products                                            
warehouses	                                     
carriers	                                                                                                                                               
employees	                                                                                                                                        
customers	                                                                                                                                                          
inventory	                                                             
purchase_orders / po_items	                                             	                                                       
sales_orders / order_items	                                                	                                                             
shipments	                                                                                                                                              
returns	                                                                                                                                                            

Business Problems
I.Basics: filtering, aggregation, grouping
1.Revenue overview. Calculate net revenue (after discount), gross margin, and margin % by product category. Show only categories with revenue above a threshold you choose, sorted highest first.
2.Regional demand. Which regions and customer segments drive the most orders, units sold and revenue? Include totals per region.
3.Low-stock alert. List every product and warehouse where stock is at or below the product’s reorder level. Label each as “Out of Stock”, “Critical” or “Low” and show a stock status summary count.
II.Joins
4.Supplier scorecard. For each supplier, show on-time delivery %, average days late or early, and fill rate (received vs ordered). Rank suppliers by reliability.
5.Dead stock. Find products that have never been sold, and products that exist in the catalogue but are not stocked in a given warehouse.
6.Customers with no activity. Find customers who have never ordered, or who ordered in 2024 but not in 2025.
7.Org chart. List each employee next to their manager’s name and role. Then find managers whose team salary cost exceeds a set amount.
III.Subqueries and CTEs
8.Above-average performers. Find products whose total sales exceed the average sales of products in their own category (correlated subquery).
9.Customer lifetime value. Using CTEs, calculate each customer’s total spend, number of orders, average order value and days since last order. Segment them into tiers such as VIP, Regular and At-risk.
10.Delivery performance by carrier. Compare carriers on SLA breach rate, average shipping cost per order and average delay. Flag which carrier mode is the most cost-effective.
IV.Window functions
11.Top sellers. Rank the top 3 products in each category by revenue per year. Handle ties explicitly and explain why you chose RANK, DENSE_RANK or ROW_NUMBER.
12.Trend analysis. Calculate monthly revenue, month-over-month growth %, a running year-to-date total, and a 3-month moving average.
13.Reorder frequency. For each customer, find the gap in days between consecutive orders, then find the average gap per segment.
14.Pareto analysis (ABC classification). Rank products by cumulative revenue share. Classify them as A (top 80%), B (next 15%) and C (the rest). Use NTILE as an alternative approach.
V.Date functions, strings and NULL handling
15.Seasonality. Compare revenue by quarter and day of week. Identify peak months and the busiest ship days.
16.Data cleaning. Standardise emails to lowercase, extract the email domain, replace missing emails with a placeholder, and count how many customers have unusable contact data.
17.Open order aging. For open and in-transit purchase orders, calculate how many days overdue they are. Bucket them into 0–7, 8–15 and 15+ days using CASE.
VI.Set operations and pivoting
18.Returns deep dive. Calculate return rate % by product, category and supplier. Pivot return reasons into columns (one column per reason) using conditional aggregation. Find products that are among both the top 10 sellers and the top 10 most returned (INTERSECT), and products that sell well but are never returned (EXCEPT).
VII.Advanced Analytics
19.Warehouse capacity and flow. Build a view showing, per warehouse, stock units, percent of capacity used, units sold and units received per month. Then recommend which warehouse should receive the next purchase order. Also use a recursive CTE to produce a full management chain from the CEO down to each employee.
20.Operational tasks (DML and performance). Do the following:
➢Create a reorder-suggestion table with INSERT … SELECT.
➢UPDATE supplier ratings based on on-time performance.
➢Wrap a stock transfer between two warehouses in a transaction.
➢DELETE outdated cancelled records.
➢Add indexes on the heaviest join columns and compare query plans with EXPLAIN before and after.

How did I solve the questions and did analysis
I started by calculating revenue and margin by product category, using joins, GROUP BY and HAVING.
I then analysed orders and revenue by region and customer segment, using multiple joins and WITH ROLLUP for subtotals. 
For inventory, I built a low-stock alert with CASE and a CTE, and I created a supplier scorecard that ranks suppliers with CTEs and RANK(). 
I also identified products that were never sold or not stocked in a warehouse, using LEFT JOIN ... IS NULL and NOT EXISTS. 
On the data side, I cleaned customer emails with LOWER, TRIM and COALESCE, and I flagged overdue purchase orders by grouping them into date-based CASE buckets.
I analysed product returns by pivoting the reasons with CASE and comparing lists with INTERSECT and EXCEPT. 
Finally, I built a warehouse stock flow view and an employee org chart using a recursive CTE, and I practised updating data, transactions and index tuning with UPDATE, DELETE, COMMIT and EXPLAIN.

