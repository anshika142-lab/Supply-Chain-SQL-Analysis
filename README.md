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

