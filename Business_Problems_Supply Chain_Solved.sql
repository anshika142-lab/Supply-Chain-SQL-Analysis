-- Business Analysis
-- Revenue overview:Calculate net revenue (after discount), gross margin, and margin % by product category. 
-- Show only categories with revenue above a threshold you choose, sorted highest first.
SELECT
   p.category,
   COUNT(DISTINCT so.order_id)          AS total_orders,
   SUM(oi.quantity)                     AS units_sold,
   ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2) AS net_revenue,
   ROUND(SUM(oi.quantity*p.unit_cost),2)  AS total_cost,
   ROUND(SUM(oi.quantity * oi.unit_price * (1-oi.discount_pct))- SUM(oi.quantity * p.unit_cost),2) AS gross_margin,
  ROUND(100*(SUM(oi.quantity * oi.unit_price * (1-oi.discount_pct))
- SUM(oi.quantity * p.unit_cost))
/SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2) AS margin_pct
   FROM order_items oi
   JOIN sales_orders so 
   ON so.order_id = oi.order_id
   JOIN products p
   ON p.product_id = oi.product_id
   WHERE so.status <> 'Cancelled'
   GROUP BY p.category
   HAVING SUM(oi.quantity * oi.unit_price *(1-oi.discount_pct)) > 1000000
   ORDER BY net_revenue DESC;
   
-- Which regions and customer segments drive the most orders, units sold and revenue? Include totals per region.
SELECT
    CASE WHEN GROUPING(c.region) = 1 THEN 'ALL REGIONS'
         ELSE c.region END                                               AS region,
    CASE WHEN GROUPING(c.region) = 1 THEN 'Grand Total'
         WHEN GROUPING(c.segment) = 1 THEN 'Region Total'
         ELSE c.segment END                                              AS segment,
    COUNT(DISTINCT so.order_id)                                          AS total_orders,
    SUM(oi.quantity)                                                     AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2)   AS net_revenue
FROM order_items oi
JOIN sales_orders so ON so.order_id    = oi.order_id
JOIN customers    c  ON c.customer_id  = so.customer_id
WHERE so.status <> 'Cancelled'
GROUP BY c.region, c.segment WITH ROLLUP
ORDER BY GROUPING(c.region), c.region, GROUPING(c.segment), net_revenue DESC;

-- List every product and warehouse where stock is at or below the product’s reorder level. 
-- Label each as “Out of Stock”, “Critical” or “Low” and show a stock status summary count.
SELECT
    w.warehouse_name,
    p.product_name,
    p.category,
    i.quantity_on_hand,
    p.reorder_level,
    p.reorder_level - i.quantity_on_hand          AS shortfall,
    CASE
        WHEN i.quantity_on_hand = 0                      THEN 'Out of Stock'
        WHEN i.quantity_on_hand <= 0.5 * p.reorder_level THEN 'Critical'
        ELSE 'Low'
    END                                           AS stock_status
FROM inventory  i
JOIN products   p ON p.product_id   = i.product_id
JOIN warehouses w ON w.warehouse_id = i.warehouse_id
WHERE i.quantity_on_hand <= p.reorder_level
ORDER BY
    CASE
        WHEN i.quantity_on_hand = 0                      THEN 1
        WHEN i.quantity_on_hand <= 0.5 * p.reorder_level THEN 2
        ELSE 3
    END,
    shortfall DESC;
    
    WITH alerts AS (
    SELECT
        CASE
            WHEN i.quantity_on_hand = 0                      THEN 'Out of Stock'
            WHEN i.quantity_on_hand <= 0.5 * p.reorder_level THEN 'Critical'
            ELSE 'Low'
        END AS stock_status
    FROM inventory i
    JOIN products  p ON p.product_id = i.product_id
    WHERE i.quantity_on_hand <= p.reorder_level
)
SELECT
    stock_status,
    COUNT(*)                                          AS alert_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_alerts
FROM alerts
GROUP BY stock_status
ORDER BY alert_count DESC;
   
-- 4. Supplier scorecard: For each supplier, show on-time delivery %, average days late or early, and fill rate (received vs ordered). 
-- Rank suppliers by reliability.
WITH po_perf AS (               -- delivery timing, one row per supplier
    SELECT
        supplier_id,
        COUNT(*)                                                        AS received_pos,
        SUM(CASE WHEN received_date <= expected_date THEN 1 ELSE 0 END) AS on_time_pos,
        AVG(DATEDIFF(received_date, expected_date))                     AS avg_days_late
    FROM purchase_orders
    WHERE status = 'Received'
    GROUP BY supplier_id
),
fill AS (                       -- quantities, one row per supplier
    SELECT
        po.supplier_id,
        SUM(pi.quantity_received) AS units_received,
        SUM(pi.quantity_ordered)  AS units_ordered
    FROM purchase_orders po
    JOIN po_items        pi ON pi.po_id = po.po_id
    WHERE po.status = 'Received'
    GROUP BY po.supplier_id
),
score AS (
    SELECT
        s.supplier_name,
        s.country,
        s.rating,
        pp.received_pos,
        ROUND(100.0 * pp.on_time_pos / pp.received_pos, 1) AS on_time_pct,
        ROUND(pp.avg_days_late, 1)                         AS avg_days_late,
        ROUND(100.0 * f.units_received / f.units_ordered, 1) AS fill_rate_pct
    FROM suppliers s
    JOIN po_perf pp ON pp.supplier_id = s.supplier_id
    JOIN fill    f  ON f.supplier_id  = s.supplier_id
)
SELECT
    RANK() OVER (ORDER BY (on_time_pct + fill_rate_pct) / 2 DESC) AS reliability_rank,
    supplier_name,
    country,
    rating,
    received_pos,
    on_time_pct,
    avg_days_late,
    fill_rate_pct,
    ROUND((on_time_pct + fill_rate_pct) / 2, 1)                   AS reliability_score
FROM score
ORDER BY reliability_rank;

-- 5. Dead stock:Find products that have never been sold, and products that exist in the catalogue but are not stocked in a 
-- given warehouse.

SELECT p.product_id, p.product_name, p.category
FROM products p
LEFT JOIN order_items oi 
ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;

SELECT p.product_id, p.product_name, p.category
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items  oi
    JOIN sales_orders so ON so.order_id = oi.order_id
    WHERE oi.product_id = p.product_id
      AND so.status <> 'Cancelled'
);

SELECT
    w.warehouse_name,
    p.product_name,
    p.category
FROM warehouses w
CROSS JOIN products p
LEFT JOIN inventory i
       ON i.warehouse_id = w.warehouse_id
      AND i.product_id   = p.product_id
WHERE i.product_id IS NULL
ORDER BY w.warehouse_name, p.product_name;

SELECT
    w.warehouse_name,
    p.product_name,
    i.quantity_on_hand
FROM inventory  i
JOIN products   p ON p.product_id   = i.product_id
JOIN warehouses w ON w.warehouse_id = i.warehouse_id
WHERE i.quantity_on_hand > 0
  AND NOT EXISTS (
        SELECT 1
        FROM sales_orders so
        JOIN order_items  oi ON oi.order_id = so.order_id
        WHERE so.warehouse_id = i.warehouse_id
          AND oi.product_id   = i.product_id
          AND so.status      <> 'Cancelled'
          AND so.order_date  >= DATE_SUB((SELECT MAX(order_date) FROM sales_orders),
                                         INTERVAL 90 DAY)
      )
ORDER BY i.quantity_on_hand DESC;


-- 6. Customers with no activity:Find customers who have never ordered, or who ordered in 2024 but not in 2025.
SELECT
    c.customer_id,
    c.customer_name
FROM customers c
LEFT JOIN sales_orders so
    ON c.customer_id = so.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING
    COUNT(so.order_id) = 0
    OR (
        SUM(CASE
            WHEN so.order_date >= '2024-01-01'
             AND so.order_date < '2025-01-01'
            THEN 1 ELSE 0
        END) > 0
        AND
        SUM(CASE
            WHEN so.order_date >= '2025-01-01'
             AND so.order_date < '2026-01-01'
            THEN 1 ELSE 0
        END) = 0
    );
-- 7. Org chart. List each employee next to their manager’s name and role. 
-- Then find managers whose team salary cost exceeds a set amount.
SELECT
    e.full_name AS employee_name,
    e.job_role AS employee_role,
    m.full_name AS manager_name,
    m.job_role AS manager_role
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id
ORDER BY m.full_name, e.full_name;

SELECT
    m.employee_id AS manager_id,
    m.full_name AS manager_name,
    m.job_role AS manager_role,
    SUM(e.salary) AS team_salary_cost
FROM employees e
JOIN employees m
    ON e.manager_id = m.employee_id
GROUP BY
    m.employee_id,
    m.full_name,
    m.job_role
HAVING SUM(e.salary) > 200000
ORDER BY team_salary_cost DESC;

-- 8. Above-average performers: Find products whose total sales exceed the average sales of products in their own category. 
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_sales
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
HAVING SUM(oi.quantity * oi.unit_price) >
    (
        SELECT AVG(product_sales)
        FROM (
            SELECT
                p2.product_id,
                SUM(oi2.quantity * oi2.unit_price) AS product_sales
            FROM products p2
            JOIN order_items oi2
                ON p2.product_id = oi2.product_id
            WHERE p2.category = p.category
            GROUP BY p2.product_id
        ) AS category_products
    )
ORDER BY total_sales DESC;

-- 9. Customer lifetime value: Using CTEs, calculate each customer’s total spend, number of orders, average order value 
-- and days since last order. Segment them into tiers such as VIP, Regular and At-risk.
-- Step 1: Calculate the value of each order
 SELECT
        so.customer_id,
        so.order_id,
        so.order_date,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS order_value
FROM sales_orders so
JOIN order_items oi
ON so.order_id = oi.order_id
WHERE so.status <> 'Cancelled'
GROUP BY
        so.customer_id,
        so.order_id,
        so.order_date
);
SELECT *
FROM customer_orders
LIMIT 10;

-- Step 2: Calculate customer-level metrics
customer_summary AS (
    SELECT
        customer_id,
        SUM(order_value) AS total_spend,
        COUNT(order_id) AS number_of_orders,
        AVG(order_value) AS average_order_value,
        DATEDIFF(
            CURDATE(),
            MAX(order_date)
        ) AS days_since_last_order
    FROM customer_orders
    GROUP BY customer_id
)

-- Step 3: Assign customer tiers
SELECT
    c.customer_id,
    c.customer_name,
    COALESCE(cs.total_spend, 0) AS total_spend,
    COALESCE(cs.number_of_orders, 0) AS number_of_orders,
    ROUND(cs.average_order_value, 2) AS average_order_value,
    cs.days_since_last_order,
    CASE
        WHEN cs.customer_id IS NULL THEN 'At-risk'
        WHEN cs.days_since_last_order > 90 THEN 'At-risk'
        WHEN cs.total_spend >= 100000
             AND cs.number_of_orders >= 5 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_tier
FROM customers c
LEFT JOIN customer_summary cs
    ON c.customer_id = cs.customer_id
ORDER BY total_spend DESC;

-- 10. Delivery performance by carrier: Compare carriers on SLA breach rate, average shipping cost per order and average delay. 
-- Flag which carrier mode is the most cost-effective.
SELECT
    s.carrier_id,
    COUNT(DISTINCT s.order_id) AS total_orders,

    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN s.delivery_date > s.promised_date
            THEN s.order_id
        END) / NULLIF(COUNT(DISTINCT s.order_id), 0),
        2
    ) AS sla_breach_rate_pct,

    ROUND(
        SUM(s.shipping_cost) / NULLIF(COUNT(DISTINCT s.order_id), 0),
        2
    ) AS avg_shipping_cost_per_order,

    ROUND(
        AVG(
            GREATEST(
                DATEDIFF(
                    s.delivery_date,
                    s.promised_date
                ),
                0
            )
        ),
        2
    ) AS avg_delay_days

FROM shipments s
WHERE s.delivery_date IS NOT NULL
GROUP BY s.carrier_id 
ORDER BY
    sla_breach_rate_pct ASC,
    avg_shipping_cost_per_order ASC,
    avg_delay_days ASC;
    
WITH carrier_metrics AS (
    SELECT
        carrier_id,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(
            100.0 * COUNT(DISTINCT CASE
                WHEN delivery_date > promised_date
                THEN order_id
            END) / NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS sla_breach_rate_pct,
        ROUND(
            SUM(shipping_cost) /
            NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS avg_shipping_cost_per_order,
        ROUND(
            AVG(GREATEST(
                DATEDIFF(delivery_date, promised_date),
                0
            )),
            2
        ) AS avg_delay_days
    FROM shipments
    WHERE delivery_date IS NOT NULL
    GROUP BY carrier_id
)
SELECT
    *,
    CASE
        WHEN sla_breach_rate_pct <= 5
         AND avg_shipping_cost_per_order < (
             SELECT AVG(avg_shipping_cost_per_order)
             FROM carrier_metrics
         )
        THEN 'Cost-effective'
        ELSE 'Review'
    END AS carrier_flag
FROM carrier_metrics
ORDER BY sla_breach_rate_pct, avg_shipping_cost_per_order;

-- 11. Top sellers: Rank the top 3 products in each category by revenue per year. 
-- Handle ties explicitly and explain why you chose RANK, DENSE_RANK or ROW_NUMBER.
WITH product_yearly_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        YEAR(so.order_date) AS sales_year,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN sales_orders so
        ON oi.order_id = so.order_id
    GROUP BY
        p.category,
        p.product_id,
        p.product_name,
        YEAR(so.order_date)
),
ranked_products AS (
    SELECT
        category,
        product_id,
        product_name,
        sales_year,
        total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category, sales_year
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM product_yearly_revenue
)
SELECT
    category,
    sales_year,
    product_id,
    product_name,
    total_revenue,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 3
ORDER BY
    sales_year,
    category,
    revenue_rank;
-- 12. Trend analysis: Calculate monthly revenue, month-over-month growth %, a running year-to-date total, and a 3-month moving average.
WITH monthly_revenue AS (
    SELECT
        YEAR(so.order_date) AS sales_year,
        MONTH(so.order_date) AS sales_month,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS revenue
    FROM sales_orders so
    JOIN order_items oi
        ON so.order_id = oi.order_id
    GROUP BY
        YEAR(so.order_date),
        MONTH(so.order_date)
),

revenue_trends AS (
    SELECT
        sales_year,
        sales_month,
        revenue,

        LAG(revenue) OVER (
            ORDER BY sales_year, sales_month
        ) AS previous_month_revenue,

        SUM(revenue) OVER (
            PARTITION BY sales_year
            ORDER BY sales_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ytd_revenue,

        AVG(revenue) OVER (
            ORDER BY sales_year, sales_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3_months

    FROM monthly_revenue
)

SELECT
    sales_year,
    sales_month,
    ROUND(revenue, 2) AS monthly_revenue,

    ROUND(
        (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_pct,

    ROUND(ytd_revenue, 2) AS ytd_revenue,

    ROUND(moving_avg_3_months, 2) AS moving_avg_3_months

FROM revenue_trends
ORDER BY sales_year, sales_month;


-- 13. Reorder frequency: For each customer, find the gap in days between consecutive orders, then find the average gap per segment.
WITH customer_order_gaps AS (
SELECT
        so.customer_id,
        c.segment,
        so.order_id,
        so.order_date,

        LAG(so.order_date) OVER (
            PARTITION BY so.customer_id
            ORDER BY so.order_date, so.order_id
        ) AS previous_order_date

    FROM sales_orders so
    JOIN customers c
        ON so.customer_id = c.customer_id
),

order_gaps AS (
SELECT
        customer_id,
        segment,
        order_id,
        order_date,
        previous_order_date,

        DATEDIFF(
            order_date,
            previous_order_date
        ) AS gap_days

FROM customer_order_gaps
)

SELECT
    segment,
    COUNT(*) AS total_order_gaps,
    ROUND(AVG(gap_days), 2) AS average_gap_days
FROM order_gaps
WHERE gap_days IS NOT NULL
GROUP BY segment
ORDER BY average_gap_days;

-- 14. Pareto analysis (ABC classification): Rank products by cumulative revenue share. 
-- Classify them as A (top 80%), B (next 15%) and C (the rest). Use NTILE as an alternative approach.
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        p.product_id,
        p.product_name
),

revenue_share AS (
    SELECT
        product_id,
        product_name,
        total_revenue,

        SUM(total_revenue) OVER () AS overall_revenue,

        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue

    FROM product_revenue
),

abc_analysis AS (
    SELECT
        product_id,
        product_name,
        total_revenue,

        ROUND(
            total_revenue / NULLIF(overall_revenue, 0) * 100,
            2
        ) AS revenue_share_pct,

        ROUND(
            cumulative_revenue / NULLIF(overall_revenue, 0) * 100,
            2
        ) AS cumulative_revenue_share_pct

    FROM revenue_share
)

SELECT
    product_id,
    product_name,
    ROUND(total_revenue, 2) AS total_revenue,
    revenue_share_pct,
    cumulative_revenue_share_pct,

    CASE
        WHEN cumulative_revenue_share_pct <= 80 THEN 'A'
        WHEN cumulative_revenue_share_pct <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_class

FROM abc_analysis
ORDER BY total_revenue DESC, product_id;

-- 15. Seasonality : Compare revenue by quarter and day of week. Identify peak months and the busiest ship days.
SELECT
    YEAR(so.order_date) AS sales_year,
    QUARTER(so.order_date) AS sales_quarter,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)),
        2
    ) AS total_revenue,
    COUNT(DISTINCT so.order_id) AS total_orders
FROM sales_orders so
JOIN order_items oi
    ON so.order_id = oi.order_id
GROUP BY
    YEAR(so.order_date),
    QUARTER(so.order_date)
ORDER BY
    sales_year,
    sales_quarter;

SELECT
    DAYNAME(so.order_date) AS day_of_week,
    DAYOFWEEK(so.order_date) AS day_number,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)),
        2
    ) AS total_revenue,
    COUNT(DISTINCT so.order_id) AS total_orders
FROM sales_orders so
JOIN order_items oi
    ON so.order_id = oi.order_id
GROUP BY
    DAYNAME(so.order_date),
    DAYOFWEEK(so.order_date)
ORDER BY
    day_number;
    
SELECT
    MONTH(so.order_date) AS month_number,
    MONTHNAME(so.order_date) AS month_name,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)),
        2
    ) AS total_revenue
FROM sales_orders so
JOIN order_items oi
    ON so.order_id = oi.order_id
GROUP BY
    MONTH(so.order_date),
    MONTHNAME(so.order_date)
ORDER BY
    total_revenue DESC;
    
SELECT
    DAYNAME(actual_ship_date) AS ship_day,
    DAYOFWEEK(actual_ship_date) AS day_number,
    COUNT(*) AS total_shipments
FROM shipments
WHERE actual_ship_date IS NOT NULL
GROUP BY
    DAYNAME(actual_ship_date),
    DAYOFWEEK(actual_ship_date)
ORDER BY
    total_shipments DESC;

-- 16. Data cleaning: Standardise emails to lowercase, extract the email domain, replace missing emails with a placeholder, 
-- and count how many customers have unusable contact data.
-- Part 1 - clean the emails and extract the domain
SELECT
    customer_id,
    customer_name,
    email                                             AS original_email,
    COALESCE(LOWER(TRIM(NULLIF(email, ''))),
             CONCAT('no-email-', customer_id, '@placeholder.invalid')) AS clean_email,
    SUBSTRING_INDEX(LOWER(TRIM(email)), '@', -1)      AS email_domain,
    CASE
        WHEN email IS NULL OR TRIM(email) = '' OR email NOT LIKE '%_@_%.__%'
            THEN 'Unusable'
        ELSE 'Valid'
    END                                               AS email_status
FROM customers
ORDER BY customer_id;

-- Part 2: count the unusable contact data
SELECT
    COUNT(*)                                                    AS total_customers,
    SUM(CASE WHEN email IS NULL OR TRIM(email) = ''
                  OR email NOT LIKE '%_@_%.__%'
             THEN 1 ELSE 0 END)                                 AS unusable_emails,
    ROUND(100.0 * SUM(CASE WHEN email IS NULL OR TRIM(email) = ''
                                OR email NOT LIKE '%_@_%.__%'
                           THEN 1 ELSE 0 END) / COUNT(*), 1)    AS unusable_pct
FROM customers;

-- 17. Open order aging: For open and in-transit purchase orders, calculate how many days overdue they are. 
-- Bucket them into 0–7, 8–15 and 15+ days using CASE.
SELECT
    po.po_id,
    s.supplier_name,
    w.warehouse_name,
    po.status,
    po.order_date,
    po.expected_date,
    DATEDIFF('2025-12-31', po.expected_date)              AS days_overdue,
    CASE
        WHEN DATEDIFF('2025-12-31', po.expected_date) <= 0  THEN 'Not yet due'
        WHEN DATEDIFF('2025-12-31', po.expected_date) <= 7  THEN '1-7 days'
        WHEN DATEDIFF('2025-12-31', po.expected_date) <= 15 THEN '8-15 days'
        ELSE '16+ days'
    END                                                   AS aging_bucket,
    ROUND(v.order_value, 2)                               AS order_value
FROM purchase_orders po
JOIN suppliers  s ON s.supplier_id  = po.supplier_id
JOIN warehouses w ON w.warehouse_id = po.warehouse_id
JOIN (SELECT po_id, SUM(quantity_ordered * unit_cost) AS order_value
      FROM po_items
      GROUP BY po_id) v ON v.po_id = po.po_id
WHERE po.status IN ('Open', 'In Transit')
ORDER BY days_overdue DESC;

WITH aged AS (
    SELECT
        po.po_id,
        DATEDIFF('2025-12-31', po.expected_date) AS days_overdue,
        v.order_value,
        CASE
            WHEN DATEDIFF('2025-12-31', po.expected_date) <= 0  THEN 'Not yet due'
            WHEN DATEDIFF('2025-12-31', po.expected_date) <= 7  THEN '1-7 days'
            WHEN DATEDIFF('2025-12-31', po.expected_date) <= 15 THEN '8-15 days'
            ELSE '16+ days'
        END AS aging_bucket
    FROM purchase_orders po
    JOIN (SELECT po_id, SUM(quantity_ordered * unit_cost) AS order_value
          FROM po_items
          GROUP BY po_id) v ON v.po_id = po.po_id
    WHERE po.status IN ('Open', 'In Transit')
)
SELECT
    aging_bucket,
    COUNT(*)                     AS open_pos,
    ROUND(AVG(days_overdue), 1)  AS avg_days_overdue,
    ROUND(SUM(order_value), 0)   AS value_at_stake
FROM aged
GROUP BY aging_bucket
ORDER BY MIN(days_overdue) DESC;

-- 18. Returns deep dive: Calculate return rate % by product, category and supplier. 
-- Pivot return reasons into columns (one column per reason) using conditional aggregation. 
-- Find products that are among both the top 10 sellers and the top 10 most returned (INTERSECT), 
-- and products that sell well but are never returned (EXCEPT).
WITH item_returns AS (            -- one row per order line that was returned
    SELECT order_item_id, SUM(quantity) AS returned_qty
    FROM returns
    GROUP BY order_item_id
),
sales AS (                        -- every sold line, with its returned qty (0 if none)
    SELECT
        p.product_id, p.product_name, p.category, p.supplier_id,
        oi.quantity                       AS sold_qty,
        COALESCE(r.returned_qty, 0)       AS returned_qty
    FROM order_items  oi
    JOIN sales_orders so ON so.order_id   = oi.order_id
    JOIN products     p  ON p.product_id  = oi.product_id
    LEFT JOIN item_returns r ON r.order_item_id = oi.order_item_id
    WHERE so.status <> 'Cancelled'
)
SELECT
    product_name,
    category,
    SUM(sold_qty)                                         AS units_sold,
    SUM(returned_qty)                                     AS units_returned,
    ROUND(100.0 * SUM(returned_qty) / SUM(sold_qty), 2)   AS return_rate_pct
FROM sales
GROUP BY product_id, product_name, category
ORDER BY return_rate_pct DESC;

SELECT
    category,
    SUM(sold_qty)                                         AS units_sold,
    SUM(returned_qty)                                     AS units_returned,
    ROUND(100.0 * SUM(returned_qty) / SUM(sold_qty), 2)   AS return_rate_pct
FROM sales
GROUP BY category
ORDER BY return_rate_pct DESC;

SELECT
    p.category,
    SUM(CASE WHEN r.reason = 'Damaged'               THEN r.quantity ELSE 0 END) AS damaged,
    SUM(CASE WHEN r.reason = 'Wrong Item'            THEN r.quantity ELSE 0 END) AS wrong_item,
    SUM(CASE WHEN r.reason = 'Late Delivery'         THEN r.quantity ELSE 0 END) AS late_delivery,
    SUM(CASE WHEN r.reason = 'Quality Issue'         THEN r.quantity ELSE 0 END) AS quality_issue,
    SUM(CASE WHEN r.reason = 'Customer Changed Mind' THEN r.quantity ELSE 0 END) AS changed_mind,
    SUM(r.quantity)                                                              AS total_returned
FROM returns r
JOIN order_items oi ON oi.order_item_id = r.order_item_id
JOIN products    p  ON p.product_id     = oi.product_id
GROUP BY p.category
ORDER BY total_returned DESC;

SELECT product_id, product_name
FROM (SELECT product_id, product_name FROM product_stats
      ORDER BY units_sold DESC, product_id LIMIT 10) top_sold
WHERE product_id IN (
    SELECT product_id
    FROM (SELECT product_id FROM product_stats
          ORDER BY units_returned DESC, product_id LIMIT 10) top_returned
);

SELECT product_id, product_name
FROM (SELECT product_id, product_name FROM product_stats
      ORDER BY units_sold DESC, product_id LIMIT 10) top_sold
EXCEPT
SELECT product_id, product_name
FROM (SELECT product_id, product_name FROM product_stats
      ORDER BY units_returned DESC, product_id LIMIT 10) top_returned;
      
-- 19. Warehouse capacity and flow: Build a view showing, per warehouse, stock units, percent of capacity used, units sold 
-- and units received per month.
 -- Then recommend which warehouse should receive the next purchase order. 
 -- Also use a recursive CTE to produce a full management chain from the CEO down to each employee.
CREATE OR REPLACE VIEW v_warehouse_monthly_flow AS
WITH flow AS (
    SELECT                                           -- units leaving (sales)
        so.warehouse_id,
        DATE_FORMAT(so.order_date, '%Y-%m') AS month,
        SUM(oi.quantity)                    AS units_sold,
        0                                   AS units_received
    FROM sales_orders so
    JOIN order_items  oi ON oi.order_id = so.order_id
    WHERE so.status <> 'Cancelled'
    GROUP BY so.warehouse_id, DATE_FORMAT(so.order_date, '%Y-%m')

    UNION ALL

    SELECT                                           -- units arriving (purchases)
        po.warehouse_id,
        DATE_FORMAT(po.received_date, '%Y-%m'),
        0,
        SUM(pi.quantity_received)
    FROM purchase_orders po
    JOIN po_items        pi ON pi.po_id = po.po_id
    WHERE po.status = 'Received'
    GROUP BY po.warehouse_id, DATE_FORMAT(po.received_date, '%Y-%m')
),
monthly AS (
    SELECT warehouse_id, month,
           SUM(units_sold)     AS units_sold,
           SUM(units_received) AS units_received
    FROM flow
    GROUP BY warehouse_id, month
),
stock AS (
    SELECT warehouse_id, SUM(quantity_on_hand) AS stock_units
    FROM inventory
    GROUP BY warehouse_id
)
SELECT
    w.warehouse_id,
    w.warehouse_name,
    m.month,
    m.units_sold,
    m.units_received,
    st.stock_units,
    w.capacity_units,
    ROUND(100.0 * st.stock_units / w.capacity_units, 1) AS pct_capacity_used
FROM monthly    m
JOIN warehouses w  ON w.warehouse_id  = m.warehouse_id
JOIN stock      st ON st.warehouse_id = m.warehouse_id;

SELECT * FROM v_warehouse_monthly_flow
ORDER BY warehouse_name, month;

SELECT warehouse_name, month, units_sold, units_received
FROM v_warehouse_monthly_flow
WHERE month >= '2025-10';

WITH recent_sales AS (
    SELECT so.warehouse_id, SUM(oi.quantity) AS units_sold_90d
    FROM sales_orders so
    JOIN order_items  oi ON oi.order_id = so.order_id
    WHERE so.status <> 'Cancelled'
      AND so.order_date > DATE_SUB((SELECT MAX(order_date) FROM sales_orders),
                                   INTERVAL 90 DAY)
    GROUP BY so.warehouse_id
),
stock AS (
    SELECT warehouse_id, SUM(quantity_on_hand) AS stock_units
    FROM inventory
    GROUP BY warehouse_id
),
inbound AS (
    SELECT po.warehouse_id, SUM(pi.quantity_ordered) AS inbound_units
    FROM purchase_orders po
    JOIN po_items        pi ON pi.po_id = po.po_id
    WHERE po.status IN ('Open', 'In Transit')
    GROUP BY po.warehouse_id
),
calc AS (
    SELECT
        w.warehouse_name,
        w.capacity_units,
        s.stock_units,
        COALESCE(ib.inbound_units, 0)                              AS inbound_units,
        w.capacity_units - s.stock_units - COALESCE(ib.inbound_units, 0) AS free_after_inbound,
        rs.units_sold_90d / 90.0                                   AS daily_demand,
        (s.stock_units + COALESCE(ib.inbound_units, 0))
            / (rs.units_sold_90d / 90.0)                           AS projected_days_cover
    FROM warehouses w
    JOIN stock        s  ON s.warehouse_id  = w.warehouse_id
    JOIN recent_sales rs ON rs.warehouse_id = w.warehouse_id
    LEFT JOIN inbound ib ON ib.warehouse_id = w.warehouse_id
)
SELECT
    RANK() OVER (ORDER BY projected_days_cover) AS priority_rank,
    warehouse_name,
    stock_units,
    inbound_units,
    free_after_inbound,
    ROUND(daily_demand, 1)                      AS daily_demand_units,
    ROUND(projected_days_cover, 0)              AS projected_days_cover
FROM calc
ORDER BY priority_rank;

WITH RECURSIVE org AS (
    -- anchor: the top of the hierarchy (no manager)
    SELECT
        employee_id,
        full_name,
        job_role,
        manager_id,
        1                              AS level,
        CAST(full_name AS CHAR(500))   AS management_chain
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- recursive step: find everyone who reports to someone already in org
    SELECT
        e.employee_id,
        e.full_name,
        e.job_role,
        e.manager_id,
        o.level + 1,
        CONCAT(o.management_chain, ' > ', e.full_name)
    FROM employees e
    JOIN org       o ON e.manager_id = o.employee_id
)
SELECT level, full_name, job_role, management_chain
FROM org
ORDER BY management_chain;

--  20. Operational tasks (DML and performance). Do the following:

CREATE TABLE suppliers_backup AS SELECT * FROM suppliers;
CREATE TABLE inventory_backup AS SELECT * FROM inventory;

-- (A) Create a reorder-suggestion table with INSERT … SELECT.
CREATE TABLE reorder_suggestions (
    suggestion_id  INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id   INT,
    product_id     INT,
    supplier_id    INT,
    current_stock  INT,
    reorder_level  INT,
    suggested_qty  INT,
    est_cost       DECIMAL(12,2),
    status         VARCHAR(20),
    created_date   DATE
);

INSERT INTO reorder_suggestions
    (warehouse_id, product_id, supplier_id, current_stock, reorder_level,
     suggested_qty, est_cost, status, created_date)
SELECT
    i.warehouse_id,
    i.product_id,
    p.supplier_id,
    i.quantity_on_hand,
    p.reorder_level,
    2 * p.reorder_level - i.quantity_on_hand,                       -- order up to 2x reorder level
    (2 * p.reorder_level - i.quantity_on_hand) * p.unit_cost,
    'Suggested',
    CURDATE()
FROM inventory i
JOIN products  p ON p.product_id = i.product_id
WHERE i.quantity_on_hand <= p.reorder_level;

-- (B)UPDATE supplier ratings based on on-time performance.
UPDATE suppliers s
JOIN (
    SELECT supplier_id,
           SUM(CASE WHEN received_date <= expected_date THEN 1 ELSE 0 END) / COUNT(*) AS on_time_ratio
    FROM purchase_orders
    WHERE status = 'Received'
    GROUP BY supplier_id
) t ON t.supplier_id = s.supplier_id
SET s.rating = ROUND(1 + 4 * t.on_time_ratio, 1);
SELECT s.supplier_name, b.rating AS old_rating, s.rating AS new_rating
FROM suppliers s JOIN suppliers_backup b ON b.supplier_id = s.supplier_id;

-- (C) Wrap a stock transfer between two warehouses in a transaction.
START TRANSACTION;

-- Step 1: lock the source row so nobody else changes it mid-transfer
SELECT quantity_on_hand FROM inventory
WHERE warehouse_id = 1 AND product_id = 1
FOR UPDATE;

-- Step 2: take stock out, but only if enough exists
UPDATE inventory
SET quantity_on_hand = quantity_on_hand - 100,
    last_updated     = CURDATE()
WHERE warehouse_id = 1 AND product_id = 1
  AND quantity_on_hand >= 100;

SELECT ROW_COUNT() AS source_rows_updated;   -- must be 1; if 0, run ROLLBACK instead of continuing

-- Step 3: add stock to the destination (creates the row if the product wasn't stocked there)
INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand, last_updated)
VALUES (2, 1, 100, CURDATE())
ON DUPLICATE KEY UPDATE
    quantity_on_hand = quantity_on_hand + 100,
    last_updated     = CURDATE();

-- Step 4:  verify before making it permanent
SELECT warehouse_id, quantity_on_hand FROM inventory
WHERE product_id = 1 AND warehouse_id IN (1, 2);

COMMIT;      -- or ROLLBACK; to undo everything above

-- (D) DELETE outdated cancelled records.
START TRANSACTION;

DELETE FROM order_items
WHERE order_id IN (SELECT order_id FROM sales_orders
                   WHERE status = 'Cancelled' AND order_date < '2025-01-01');

DELETE FROM sales_orders
WHERE status = 'Cancelled' AND order_date < '2025-01-01';

-- same idea for purchase orders
DELETE FROM po_items
WHERE po_id IN (SELECT po_id FROM purchase_orders
                WHERE status = 'Cancelled' AND order_date < '2025-01-01');

DELETE FROM purchase_orders
WHERE status = 'Cancelled' AND order_date < '2025-01-01';

COMMIT;

-- (E) Add indexes on the heaviest join columns and compare query plans with EXPLAIN before and after.
EXPLAIN
SELECT c.region,
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS net_revenue
FROM order_items  oi
JOIN sales_orders so ON so.order_id   = oi.order_id
JOIN customers    c  ON c.customer_id = so.customer_id
WHERE so.order_date BETWEEN '2025-10-01' AND '2025-12-31'
GROUP BY c.region;
CREATE INDEX idx_oi_order      ON order_items (order_id);
CREATE INDEX idx_oi_product    ON order_items (product_id);
CREATE INDEX idx_so_customer   ON sales_orders (customer_id);
CREATE INDEX idx_so_date       ON sales_orders (order_date);
CREATE INDEX idx_ship_order    ON shipments (order_id);
CREATE INDEX idx_poi_po        ON po_items (po_id);
CREATE INDEX idx_po_supplier   ON purchase_orders (supplier_id);
CREATE INDEX idx_ret_item      ON returns (order_item_id);