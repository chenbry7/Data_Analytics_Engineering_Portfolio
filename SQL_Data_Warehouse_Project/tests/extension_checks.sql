/* Focused SQL regression checks. No warehouse objects or data are changed.
Run in SSMS/sqlcmd on SQL Server 2017+. THROW indicates a failed check.
*/
SET NOCOUNT ON;
DECLARE @dates TABLE (source_date int NULL, expected_date date NULL);
INSERT INTO @dates VALUES
    (20240229, CONVERT(date, '20240229', 112)),
    (20260228, CONVERT(date, '20260228', 112)),
    (20260230, NULL), (20230229, NULL), (20261301, NULL),
    (0, NULL), (2026011, NULL), (-20260101, NULL), (NULL, NULL),
    (54890101, NULL), (18991231, NULL), (20500102, NULL),
    (19000101, CONVERT(date, '19000101',112)),
    (20500101, CONVERT(date, '20500101',112));
IF EXISTS (
    SELECT 1 FROM @dates
    CROSS APPLY (SELECT CASE WHEN source_date BETWEEN 19000101 AND 20500101
                        THEN TRY_CONVERT(date, CONVERT(varchar(10), source_date), 112) END) v(actual_date)
    WHERE actual_date <> expected_date
       OR (actual_date IS NULL AND expected_date IS NOT NULL)
       OR (actual_date IS NOT NULL AND expected_date IS NULL)
)
    THROW 51001, 'Date conversion regression failed.', 1;

-- Two lines in one order must not make a customer a repeat buyer.
DECLARE @sales TABLE (customer_key int, order_number varchar(10), sales_amount int, quantity int);
INSERT INTO @sales VALUES (1, 'A', 10, 1), (1, 'A', 20, 2),
                         (2, 'B', 10, 1), (2, 'C', 20, 2);
DECLARE @buyers int, @repeat int;
;WITH orders AS (
    SELECT customer_key, COUNT(DISTINCT order_number) AS order_count
    FROM @sales GROUP BY customer_key
)
SELECT @buyers = COUNT(*),
       @repeat = SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END)
FROM orders;
IF @buyers <> 2 OR @repeat <> 1
    THROW 51002, 'Distinct-order repeat purchasing regression failed.', 1;
IF (SELECT CAST(1.0 * SUM(sales_amount) / NULLIF(COUNT(DISTINCT order_number), 0)
                AS decimal(18,2)) FROM @sales) <> 20.00
    THROW 51003, 'Average order value regression failed.', 1;
PRINT 'PASS: calendar date conversion, repeat purchasing, and average order value.';
