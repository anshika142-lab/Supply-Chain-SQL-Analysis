This project is a SQL practice exercise based on a made-up supply chain business. 
The company buys products from suppliers, stores them in warehouses, and sells them to customers. 
The database has 13 linked tables covering suppliers, products, inventory, purchase orders, sales, shipments and returns, with synthetic data from 2024 to 2025.
On top of the data are 20 business questions, such as which product categories earn the best margin, which items are running out of stock, which suppliers deliver late, and which warehouse should receive the next order. Solving them covers the main SQL skills: joins, grouping, subqueries, CTEs, window functions, data cleaning, views, transactions and indexes.


The database has 13 tables covering 2024 to 2025:

Table	                                                                        What it stores	                                           
suppliers	                                                                    who we buy from	                                            
products	                                                                     what we sell	                                            
warehouses	                                                                where stock is kept	                                      
carriers	                                                                  delivery companies	                                                                                    
employees	                                                               staff and who reports to whom	                                                                           
customers	                                                                     who buys from us	                                                                                      
inventory	                                                                 stock in each warehouse	                                                                                
purchase_orders / po_items	                                              what we buy from suppliers	                                                       
sales_orders / order_items	                                                 what customers buy	                                                             
shipments	                                                                 deliveries to customers	                                                                               
returns	                                                                      items sent back	                                                                                           

Questions I solved
#	Question	                                                                    What I practiced
1	Revenue and margin by category                                    	     joins, GROUP BY, HAVING
2	Orders and revenue by region and segment	                             multiple joins, WITH ROLLUP
3	Low-stock alert                                                               	CASE, CTE
4	Supplier scorecard	                                                           CTEs, RANK()
5	Products never sold or not stocked	                               LEFT JOIN ... IS NULL, NOT EXISTS
16	Cleaning customer emails	                                              LOWER, TRIM, COALESCE
17	Overdue purchase orders	                                                dates, CASE buckets
18	Returns analysis	                                                pivot with CASE, INTERSECT, EXCEPT
19	Warehouse stock flow and org chart	                                  views, recursive CTE
20	Updating data, transactions, indexes	                               UPDATE, DELETE, COMMIT, EXPLAIN

Mistakes I made (and what I learned) 🙈

Honestly, I got a lot of red error marks. Here are the main ones so I don't repeat them:

Typos in column names - I wrote dicount_pct instead of discount_pct and price instead of unit_price. Now I check the column names in the Schemas panel first.
Brackets in a long formula- My margin % kept failing because I closed a bracket too early. I learned to count: +1 for every ( and -1 for every ), and it should end at 0. Clicking next to a bracket in Workbench highlights its partner.
Division before subtraction-100*SUM(rev) - SUM(cost) / SUM(rev) gives the wrong answer. It needs brackets: 100 * (rev - cost) / rev.
Forgot a table alias. I wrote so.order_id but never wrote sales_orders so in the JOIN.
A stray comma- One extra comma before INTERSECT made the whole query red.
Missing comma between columns and a . typed instead of , inside ROUND(...).
= NULL doesn't work. You have to write IS NULL.
Joining header and line tables inflates numbers- Orders have many lines, so I learned to use COUNT(DISTINCT order_id) and to total the lines first before joining.

My debugging tricks now: hover over the red mark, build the query in small steps, and run it often.
