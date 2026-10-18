# Sales Analytics Guide

The warehouse supports exploration and aggregation over Gold views. [Script 14](../scripts/14_sales_analysis.sql) is the executed reporting deliverable; this guide also provides optional read-only query patterns. Run the quality scorecard first and resolve FAIL results before interpreting output. Queries assume the `DataWarehouse` database context.

## Fields, Dimensions, and Measures

Dimensions describe customers/products/time; measures quantify sales. Numeric identifiers remain dimensions. Unit price is numeric but requires an explicit averaging policy. Revenue and quantity are additive only across compatible fact records; order counts can overlap across categories.

## Exploration

### Dimension Exploration

Use DISTINCT to inspect available labels and reveal null or unexpected categories before grouping.

```sql
SELECT DISTINCT country FROM gold.dim_customers ORDER BY country;
SELECT DISTINCT category, subcategory FROM gold.dim_products
ORDER BY category, subcategory;
```

### Date Exploration

MIN/MAX establish coverage; DATEDIFF describes the span, not proof that every day is complete.

```sql
SELECT MIN(order_date) AS first_order_date,
       MAX(order_date) AS last_order_date,
       DATEDIFF(day, MIN(order_date), MAX(order_date)) AS elapsed_days,
       COUNT_BIG(*) - COUNT_BIG(order_date) AS undated_rows
FROM gold.fact_sales;
```

Customer birthdate and creation-date ranges can be explored separately. Do not interpret the earliest customer date as the beginning of sales coverage.

### Measure Exploration

```sql
SELECT SUM(CONVERT(bigint, sales_amount)) AS revenue,
       SUM(CONVERT(bigint, quantity)) AS units_sold,
       COUNT(DISTINCT order_number) AS orders,
       COUNT_BIG(*) AS sales_rows,
       CAST(1.0 * SUM(CONVERT(bigint, sales_amount))
            / NULLIF(SUM(CONVERT(bigint, quantity)), 0)
            AS decimal(18,2)) AS weighted_unit_price
FROM gold.fact_sales;
```

COUNT of fact rows differs from distinct orders. NULL measures are ignored by SUM, so missing values must be examined through quality checks rather than hidden by aggregates.

## Magnitude: Measures by a Dimension

Compare revenue by country, quantity by category, or orders by customer. The following country example retains unresolved geography under an explicit label:

```sql
SELECT COALESCE(c.country, 'Unknown') AS country,
       SUM(CONVERT(bigint, f.sales_amount)) AS revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY COALESCE(c.country, 'Unknown')
ORDER BY revenue DESC;
```

Script 14 applies this pattern to current product categories and adds rankings and weighted unit prices.

## Change Over Time

Group by the intended date role and period. Script 14 groups by order month and compares each period to the previous observed month using LAG. Shipping month would answer a different operational question.

Missing months are not automatically zero months. The first and last observed months may have partial coverage. Revenue changes do not establish their cause; compare units, prices, and coverage before explaining demand.

## Cumulative Analysis

Running totals show accumulated revenue; moving averages smooth observed period values. Aggregate to month first, then apply window functions so individual sales lines do not determine the window size.

```sql
WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS sales_month,
           SUM(CONVERT(bigint, sales_amount)) AS revenue
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT sales_month, revenue,
       SUM(revenue) OVER (
           ORDER BY sales_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_revenue,
       AVG(CONVERT(decimal(20,2), revenue)) OVER (
           ORDER BY sales_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS average_last_three_observed_months
FROM monthly
ORDER BY sales_month;
```

The moving window includes up to three observed months, not necessarily three consecutive calendar months. Early windows contain fewer observations. The running total spans the dataset and does not reset annually.

## Performance Comparisons

Compare a current measure with an explicitly labeled baseline: a previous observed period, an average, or a supplied business target. The example compares each month's revenue with the average observed month; the average is not a sales target.

```sql
WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS sales_month,
           SUM(CONVERT(bigint, sales_amount)) AS revenue
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT sales_month, revenue,
       AVG(CONVERT(decimal(20,2), revenue)) OVER () AS average_observed_revenue,
       revenue - AVG(CONVERT(decimal(20,2), revenue)) OVER () AS difference_from_average,
       LAG(revenue) OVER (ORDER BY sales_month) AS previous_observed_revenue
FROM monthly
ORDER BY sales_month;
```

A previous-year comparison requires matching calendar years or months rather than assuming a previous row represents exactly one year. No budget/target dataset is supplied, so target achievement is not claimed.

## Part-to-Whole Analysis

Percentage contribution is a group's measure divided by the total over the same selected scope. Script 14 computes category revenue share with `SUM(revenue) OVER ()` and guards zero denominators with NULLIF. Rounded shares may not sum to exactly 100%.

An order with products from two categories appears in each category's distinct-order count. Summing those counts does not reproduce the global number of orders.

## Segmentation

Aggregate before assigning behavior groups. The example groups observed buyers into one-order and repeat-order segments, then counts buyers per segment:

```sql
WITH customer_orders AS (
    SELECT customer_key, COUNT(DISTINCT order_number) AS order_count
    FROM gold.fact_sales
    WHERE customer_key IS NOT NULL AND order_number IS NOT NULL
    GROUP BY customer_key
), segments AS (
    SELECT customer_key,
           CASE WHEN order_count >= 2 THEN 'Repeat buyer'
                ELSE 'One-order buyer' END AS purchase_segment
    FROM customer_orders
)
SELECT purchase_segment, COUNT_BIG(*) AS buyers
FROM segments
GROUP BY purchase_segment;
```

Other valid patterns include product sales bands or customer age bands. Sales-band thresholds must be explicitly defined; age requires a fixed as-of date and birthday-aware calculation. Such thresholds and ages are not supplied by this model and should not be invented as business policy.

## Reading and Publishing Results

State the grain, period, date role, exclusions, denominator, and units. Revenue is not profit; currency is unspecified. Gold product attributes are current-state values. Repeat purchasing in the observed dataset is not lifetime retention. [Analysis Findings](analysis_findings.md) provides executed results with these boundaries, while [Project Capabilities](project_extensions.md) specifies the report definitions.
