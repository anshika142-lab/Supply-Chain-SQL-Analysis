# My First SQL Project: Supply Chain Analysis 📦

Hi! I'm [Your Name], and this is the first SQL project I've ever tried. I'm learning SQL to move into data analysis, and I picked supply chain because it has a lot of real business questions: stock running out, late suppliers, returns, delivery delays.

This repo has my queries, what I learned, and the mistakes I made along the way. It's not perfect, but I'm proud I finished a good chunk of it.

---

## What is this project about?

I worked with a practice database for a made-up company that buys products from suppliers, stores them in warehouses, and sells them to customers. The data is **fake (synthetic)**, so no real company is involved.

I solved business questions like:
- Which product categories make the most money and the best margin?
- Which products are running out of stock?
- Which suppliers deliver late?
- Which products get returned the most?
- Which warehouse should receive the next purchase order?

---

## The data

The database has **13 tables** covering 2024 to 2025:

| Table | What it stores | Rows |
|---|---|---|
| suppliers | who we buy from | 12 |
| products | what we sell | 35 |
| warehouses | where stock is kept | 6 |
| carriers | delivery companies | 6 |
| employees | staff and who reports to whom | 46 |
| customers | who buys from us | 250 |
| inventory | stock in each warehouse | 184 |
| purchase_orders / po_items | what we buy from suppliers | 400 / 839 |
| sales_orders / order_items | what customers buy | 3,500 / 10,437 |
| shipments | deliveries to customers | 3,338 |
| returns | items sent back | 388 |

The tricky part for me was understanding how the tables connect. Drawing the relationships on paper first really helped. For example, to get a product's category for a sale I had to go `order_items → products`, and for a customer's region I had to go `order_items → sales_orders → customers`.

---

## Tools I used

- MySQL 8
- MySQL Workbench
- A lot of Googling 😅

---

## How to run it

1. Create a database: `CREATE DATABASE supply_chain;`
2. Run the file `supply_chain_dataset.sql` in MySQL Workbench (File → Open SQL Script → click the lightning bolt).
3. Check it worked:
   ```sql
   SELECT COUNT(*) FROM sales_orders;  -- should give 3500
   ```

Running the file again resets all the data, which is handy when I mess something up.

---

## Questions I solved

| # | Question | What I practised |
|---|---|---|
| 1 | Revenue and margin by category | joins, `GROUP BY`, `HAVING` |
| 2 | Orders and revenue by region and segment | multiple joins, `WITH ROLLUP` |
| 3 | Low-stock alert | `CASE`, CTE |
| 4 | Supplier scorecard | CTEs, `RANK()` |
| 5 | Products never sold or not stocked | `LEFT JOIN ... IS NULL`, `NOT EXISTS` |
| 16 | Cleaning customer emails | `LOWER`, `TRIM`, `COALESCE` |
| 17 | Overdue purchase orders | dates, `CASE` buckets |
| 18 | Returns analysis | pivot with `CASE`, `INTERSECT`, `EXCEPT` |
| 19 | Warehouse stock flow and org chart | views, recursive CTE |
| 20 | Updating data, transactions, indexes | `UPDATE`, `DELETE`, `COMMIT`, `EXPLAIN` |

**Still to do:** questions 6 to 15 (customers with no activity, window functions for trends and rankings, ABC analysis, seasonality). I'll add them as I finish them.

---

## What I found

- **Electronics** makes the most revenue (about 13.2M), but **Packaging** has the best margin (about 32%).
- **South** is the biggest region, and **Retail** is the top customer segment everywhere.
- About **half of the stock alerts are completely out of stock**, which surprised me.
- Suppliers all fill orders about equally well, but they differ a lot in **on-time delivery**. Cairo Chemicals was the worst.
- 24 customers (about 10%) have **no email**, so marketing couldn't reach them.
- Most open purchase orders are already overdue.
- **Electronics returns** are mostly because of quality issues, and **Packaging returns** are mostly damage.

---

## Mistakes I made (and what I learned) 🙈

Honestly, I got a lot of red error marks. Here are the main ones so I don't repeat them:

1. **Typos in column names.** I wrote `dicount_pct` instead of `discount_pct` and `price` instead of `unit_price`. Now I check the column names in the Schemas panel first.
2. **Brackets in a long formula.** My margin % kept failing because I closed a bracket too early. I learned to count: +1 for every `(` and -1 for every `)`, and it should end at 0. Clicking next to a bracket in Workbench highlights its partner.
3. **Division before subtraction.** `100*SUM(rev) - SUM(cost) / SUM(rev)` gives the wrong answer. It needs brackets: `100 * (rev - cost) / rev`.
4. **Forgot a table alias.** I wrote `so.order_id` but never wrote `sales_orders so` in the `JOIN`.
5. **A stray comma.** One extra comma before `INTERSECT` made the whole query red.
6. **Missing comma between columns** and a `.` typed instead of `,` inside `ROUND(...)`.
7. **`= NULL` doesn't work.** You have to write `IS NULL`.
8. **Joining header and line tables inflates numbers.** Orders have many lines, so I learned to use `COUNT(DISTINCT order_id)` and to total the lines first before joining.

My debugging tricks now: hover over the red mark, build the query in small steps, and run it often.

---

## Things that were hard for me

- **Window functions** (`RANK() OVER (...)`) took a while to click. The idea that they keep every row but add a calculation next to it finally made it make sense.
- **Recursive CTEs.** The org chart query looked like magic at first. Reading it as "start with the CEO, then keep adding people who report to someone already found" helped.
- **WHERE vs HAVING.** `WHERE` filters rows before grouping, and `HAVING` filters after.
- **Transactions.** I understand them now: either both stock updates happen or neither does.

---

## What I want to do next

- Finish questions 6 to 15, especially the window function ones.
- Try the same queries in PostgreSQL to see what syntax changes.
- Build a simple dashboard from these results in Power BI or Tableau.
- Write my queries without looking at hints first.

---

## Folder structure

```
supply-chain-sql/
├── README.md
├── data/
│   └── supply_chain_dataset.sql
└── solutions/
    ├── q01_revenue_margin.sql
    ├── q02_regional_demand.sql
    └── ...
```

---

## Thanks / Credits

- The dataset is synthetic and was generated for practice.
- I used an AI assistant (Claude) as a tutor while learning. It helped me understand the questions, explained my errors, and checked my queries. I ran and tested everything myself in MySQL Workbench. [Edit this line to describe your own process honestly.]

If you have feedback or tips for a beginner, I'd love to hear them!

📧 [your email] | 🔗 [your LinkedIn / GitHub]
