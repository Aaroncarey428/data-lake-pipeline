-- 01_clean_and_reshape.sql
-- Cleans and reshapes the raw synthetic source data into curated,
-- analysis ready tables for reporting.
--
-- Assumes the raw CSV (sample_source_data.csv) has already been loaded
-- into raw_jobs_tasks by the pipeline script (scripts/run_pipeline.ps1).
-- All data is synthetic. No real or proprietary information is used.

-- 1. Define the raw landing table that the CSV is loaded into.
DROP TABLE IF EXISTS raw_jobs_tasks;
CREATE TABLE raw_jobs_tasks (
    job_id        INTEGER,
    task_id       INTEGER,
    customer      TEXT,
    city          TEXT,
    job_type      TEXT,
    is_recurring  BOOLEAN,
    status        TEXT,
    created_at    DATE,
    task_cost     NUMERIC,
    sales_price   NUMERIC
);

-- (The pipeline script loads sample_source_data.csv into raw_jobs_tasks here.)

-- 2. Build the curated table with cleaning and reshaping logic.
DROP TABLE IF EXISTS curated_jobs_tasks;
CREATE TABLE curated_jobs_tasks AS
WITH deduped AS (
    -- Remove accidental duplicate task rows, keeping the most recent.
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY task_id
               ORDER BY created_at DESC
           ) AS row_rank
    FROM raw_jobs_tasks
)
SELECT
    job_id,
    task_id,
    -- Standardize customer text and strip stray leading dashes or spaces.
    TRIM(LEADING '- ' FROM COALESCE(customer, 'Unknown')) AS customer,
    city,
    job_type,

    -- Classify every job as Proactive or Reactive.
    CASE
        WHEN job_type IN ('Preventive', 'Inspection', 'Planned')
        THEN 'Proactive'
        ELSE 'Reactive'
    END AS pro_reactive,

    -- Convert the recurring boolean into report friendly text.
    CASE WHEN is_recurring THEN 'YES' ELSE 'NO' END AS recurring_flag,

    -- Normalize status into a simple open or closed grouping.
    CASE WHEN status = 'Closed' THEN 'Closed' ELSE 'Open' END AS open_closed,

    status AS detailed_status,
    created_at,
    DATE_TRUNC('month', created_at)::DATE AS month_start,

    -- Guard against null or zero costs before calculations.
    COALESCE(NULLIF(task_cost, 0), 0) AS task_cost,
    sales_price,

    -- Margin between sales price and cost.
    ROUND(sales_price - COALESCE(task_cost, 0), 2) AS gross_margin
FROM deduped
WHERE row_rank = 1;

-- 3. Build a reporting summary: monthly spend by customer.
DROP TABLE IF EXISTS report_monthly_spend;
CREATE TABLE report_monthly_spend AS
SELECT
    customer,
    month_start,
    COUNT(DISTINCT job_id)     AS job_count,
    COUNT(DISTINCT task_id)    AS task_count,
    ROUND(SUM(sales_price), 2) AS total_sales_price
FROM curated_jobs_tasks
GROUP BY customer, month_start
ORDER BY customer, month_start;
