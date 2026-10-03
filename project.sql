-- ============================================================================
-- CASE STUDY 123: Newspaper Vendor Delivery and Subscription Database
-- Course  : Database Management Systems (Semester III)
-- B.Tech CSE 2025-29
-- ============================================================================

-- ============================================================================
-- PART 1: SCHEMA CREATION
-- Four normalised tables (3NF): households, publications, daily_deliveries,
-- monthly_bills.
-- ============================================================================

DROP SCHEMA IF EXISTS newspaper_vendor CASCADE;
CREATE SCHEMA newspaper_vendor;
SET search_path TO newspaper_vendor;

-- ----- households -----
-- Master list of every subscriber the vendor serves.
CREATE TABLE households (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    city            VARCHAR(50)  NOT NULL,
    monthly_bill_rs DECIMAL(10,2) NOT NULL DEFAULT 0
);

-- ----- publications -----
-- Catalogue of newspapers/magazines the vendor supplies.
CREATE TABLE publications (
    id                SERIAL PRIMARY KEY,
    publication_name  VARCHAR(100) NOT NULL,
    price_per_copy_rs DECIMAL(8,2) NOT NULL,
    frequency         VARCHAR(10)  NOT NULL CHECK (frequency IN ('daily','weekly'))
);

-- ----- daily_deliveries -----
-- Activity log: one row per actual delivery event.
CREATE TABLE daily_deliveries (
    id               SERIAL PRIMARY KEY,
    household_id     INT      NOT NULL,
    publication_id   INT      NOT NULL,
    papers_delivered  INT      NOT NULL DEFAULT 1,
    delivery_date    DATE     NOT NULL,
    FOREIGN KEY (household_id)   REFERENCES households(id),
    FOREIGN KEY (publication_id) REFERENCES publications(id)
);

-- ----- monthly_bills -----
-- Billing summary: one row per household per month.
CREATE TABLE monthly_bills (
    id               SERIAL PRIMARY KEY,
    household_id     INT          NOT NULL,
    billing_month    VARCHAR(7)   NOT NULL,       -- format: 'YYYY-MM'
    papers_delivered  INT          NOT NULL DEFAULT 0,
    amount_rs        DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (household_id) REFERENCES households(id)
);


-- ============================================================================
-- INDEXES
-- delivery_date  -> range scans in Query 1
-- household_id on daily_deliveries -> correlated subqueries (Q5, Q10)
-- household_id on monthly_bills    -> JOINs (Q3, Q6, Q8, Q9)
-- ============================================================================

CREATE INDEX idx_dd_delivery_date  ON daily_deliveries (delivery_date);
CREATE INDEX idx_dd_household_id   ON daily_deliveries (household_id);
CREATE INDEX idx_mb_household_id   ON monthly_bills (household_id);


-- ============================================================================
-- PART 2: SEED DATA
-- ============================================================================

-- ----- 10 households -----
INSERT INTO households (id, name, city, monthly_bill_rs) VALUES
(1,  'Household - Kharadi Society',  'Guwahati',  770),
(2,  'Household - Wagholi Colony',   'Mumbai',    470),
(3,  'Household - Viman Nagar',      'Pune',      370),
(4,  'Household - Kalyani Nagar',    'Pune',      870),
(5,  'Household - Hadapsar',         'Delhi',     870),
(6,  'Household - Magarpatta',       'Mumbai',    170),
(7,  'Household - Baner Road',       'Pune',      550),
(8,  'Household - Andheri West',     'Mumbai',    620),
(9,  'Household - Salt Lake',        'Kolkata',   430),
(10, 'Household - Indiranagar',      'Bangalore', 710);

-- ----- 5 publications -----
INSERT INTO publications (id, publication_name, price_per_copy_rs, frequency) VALUES
(1, 'Times of India',      6,  'daily'),
(2, 'Malayala Manorama',   5,  'daily'),
(3, 'India Today',         50, 'weekly'),
(4, 'Hindustan Times',     6,  'daily'),
(5, 'The Hindu',           7,  'daily');

-- ----- 32 daily_deliveries rows spanning Jan-Mar 2026 -----
INSERT INTO daily_deliveries (id, household_id, publication_id, papers_delivered, delivery_date) VALUES
-- Household 1
( 1, 1, 1, 4, '2026-01-08'),
( 2, 1, 1, 1, '2026-01-19'),
( 3, 1, 2, 3, '2026-01-25'),
( 4, 1, 1, 2, '2026-02-05'),
( 5, 1, 4, 3, '2026-02-15'),
( 6, 1, 1, 1, '2026-03-01'),
-- Household 2
( 7, 2, 3, 4, '2026-02-02'),
( 8, 2, 2, 2, '2026-02-10'),
( 9, 2, 5, 1, '2026-03-12'),
-- Household 3
(10, 3, 1, 2, '2026-02-14'),
(11, 3, 4, 3, '2026-02-27'),
(12, 3, 2, 1, '2026-03-05'),
-- Household 4
(13, 4, 5, 1, '2026-01-03'),
(14, 4, 1, 2, '2026-01-17'),
(15, 4, 3, 1, '2026-02-08'),
(16, 4, 4, 4, '2026-03-20'),
-- Household 5
(17, 5, 2, 3, '2026-03-16'),
(18, 5, 1, 1, '2026-03-28'),
(19, 5, 5, 2, '2026-01-12'),
-- Household 6
(20, 6, 4, 1, '2026-03-05'),
(21, 6, 1, 2, '2026-01-22'),
-- Household 7
(22, 7, 2, 2, '2026-01-30'),
(23, 7, 5, 3, '2026-02-18'),
(24, 7, 1, 1, '2026-03-10'),
-- Household 8
(25, 8, 3, 2, '2026-02-01'),
(26, 8, 4, 3, '2026-02-20'),
(27, 8, 1, 1, '2026-03-15'),
-- Household 9
(28, 9, 2, 4, '2026-01-09'),
(29, 9, 5, 2, '2026-03-22'),
-- Household 10
(30, 10, 1, 3, '2026-01-14'),
(31, 10, 4, 2, '2026-02-25'),
(32, 10, 3, 1, '2026-03-30');

-- ----- monthly_bills -----
INSERT INTO monthly_bills (id, household_id, billing_month, papers_delivered, amount_rs) VALUES
-- Household 1
(1,  1, '2026-01', 8,  45),
(2,  1, '2026-02', 5,  30),
(3,  1, '2026-03', 1,  6),
-- Household 2
(4,  2, '2026-02', 6,  210),
(5,  2, '2026-03', 1,  7),
-- Household 3
(6,  3, '2026-02', 5,  30),
(7,  3, '2026-03', 1,  5),
-- Household 4
(8,  4, '2026-01', 3,  19),
(9,  4, '2026-02', 1,  50),
(10, 4, '2026-03', 4,  24),
-- Household 5
(11, 5, '2026-01', 2,  14),
(12, 5, '2026-03', 4,  21),
-- Household 6
(13, 6, '2026-01', 2,  12),
(14, 6, '2026-03', 1,  6),
-- Household 7
(15, 7, '2026-01', 2,  10),
(16, 7, '2026-02', 3,  21),
(17, 7, '2026-03', 1,  6),
-- Household 8
(18, 8, '2026-02', 5,  118),
(19, 8, '2026-03', 1,  6),
-- Household 9
(20, 9, '2026-01', 4,  20),
(21, 9, '2026-03', 2,  14),
-- Household 10
(22, 10, '2026-01', 3,  18),
(23, 10, '2026-02', 2,  12),
(24, 10, '2026-03', 1,  50);

-- Reset SERIAL sequences after explicit id inserts (PostgreSQL requirement).
SELECT setval('households_id_seq',        (SELECT MAX(id) FROM households));
SELECT setval('publications_id_seq',      (SELECT MAX(id) FROM publications));
SELECT setval('daily_deliveries_id_seq',  (SELECT MAX(id) FROM daily_deliveries));
SELECT setval('monthly_bills_id_seq',     (SELECT MAX(id) FROM monthly_bills));


-- ============================================================================
-- PART 3: QUERIES
-- ============================================================================


-- --------------------------------------------------------------------------
-- QUERY 1 -- FILTERING
-- Purpose : Find all deliveries made in February 2026.
-- --------------------------------------------------------------------------
SELECT dd.id, h.name AS household, p.publication_name,
       dd.papers_delivered, dd.delivery_date
FROM   daily_deliveries dd
JOIN   households h   ON dd.household_id   = h.id
JOIN   publications p ON dd.publication_id = p.id
WHERE  dd.delivery_date BETWEEN '2026-02-01' AND '2026-02-28'
ORDER BY dd.delivery_date;


-- --------------------------------------------------------------------------
-- QUERY 2 -- JOIN (three-table join)
-- Purpose : For every delivery, show household name, publication name,
--           number of papers, and the monetary value of that delivery.
-- --------------------------------------------------------------------------
SELECT h.name            AS household,
       p.publication_name,
       dd.delivery_date,
       dd.papers_delivered,
       (dd.papers_delivered * p.price_per_copy_rs) AS delivery_value_rs
FROM   daily_deliveries dd
JOIN   households h   ON dd.household_id   = h.id
JOIN   publications p ON dd.publication_id = p.id
ORDER BY h.name, dd.delivery_date;


-- --------------------------------------------------------------------------
-- QUERY 3 -- GROUP BY / HAVING
-- Purpose : Show households whose total bill across all months exceeds Rs 50.
-- --------------------------------------------------------------------------
SELECT h.name             AS household,
       COUNT(mb.id)        AS billing_months,
       SUM(mb.amount_rs)   AS total_billed_rs
FROM   monthly_bills mb
JOIN   households h ON mb.household_id = h.id
GROUP BY h.id, h.name
HAVING SUM(mb.amount_rs) > 50
ORDER BY total_billed_rs DESC;


-- --------------------------------------------------------------------------
-- QUERY 4 -- NESTED SUBQUERY (non-correlated)
-- Purpose : Find households that received at least one delivery of a weekly
--           publication (e.g., India Today).
-- --------------------------------------------------------------------------
SELECT DISTINCT h.id, h.name, h.city
FROM   households h
JOIN   daily_deliveries dd ON h.id = dd.household_id
WHERE  dd.publication_id IN (
           SELECT p.id
           FROM   publications p
           WHERE  p.frequency = 'weekly'
       )
ORDER BY h.id;


-- --------------------------------------------------------------------------
-- QUERY 5 -- CORRELATED SUBQUERY
-- Purpose : For each household, show its name and the date of its most
--           recent delivery.
-- --------------------------------------------------------------------------
SELECT h.name AS household,
       (SELECT MAX(dd.delivery_date)
        FROM   daily_deliveries dd
        WHERE  dd.household_id = h.id
       ) AS last_delivery_date
FROM   households h
ORDER BY last_delivery_date DESC;


-- --------------------------------------------------------------------------
-- QUERY 6 -- Households with above-average monthly billing
-- Purpose : List every household whose average monthly bill is greater than
--           the overall average monthly bill across all households.
-- --------------------------------------------------------------------------
SELECT h.name              AS household,
       AVG(mb.amount_rs)    AS avg_monthly_bill_rs
FROM   monthly_bills mb
JOIN   households h ON mb.household_id = h.id
GROUP BY h.id, h.name
HAVING AVG(mb.amount_rs) > (
           SELECT AVG(amount_rs) FROM monthly_bills
       )
ORDER BY avg_monthly_bill_rs DESC;


-- --------------------------------------------------------------------------
-- QUERY 7 -- Total papers delivered per publication (aggregate report)
-- Purpose : Show each publication and the total number of copies delivered
--           across all households and all dates.
-- --------------------------------------------------------------------------
SELECT p.publication_name,
       p.frequency,
       SUM(dd.papers_delivered) AS total_copies_delivered,
       SUM(dd.papers_delivered * p.price_per_copy_rs) AS total_revenue_rs
FROM   daily_deliveries dd
JOIN   publications p ON dd.publication_id = p.id
GROUP BY p.id, p.publication_name, p.frequency
ORDER BY total_revenue_rs DESC;


-- --------------------------------------------------------------------------
-- QUERY 8 -- City-wise billing summary
-- Purpose : Aggregate billing by city to compare revenue across regions.
-- --------------------------------------------------------------------------
SELECT h.city,
       COUNT(DISTINCT h.id)       AS households,
       SUM(mb.papers_delivered)    AS total_papers,
       SUM(mb.amount_rs)           AS total_revenue_rs
FROM   monthly_bills mb
JOIN   households h ON mb.household_id = h.id
GROUP BY h.city
ORDER BY total_revenue_rs DESC; 


-- --------------------------------------------------------------------------
-- QUERY 9 -- Months where a specific household (id=1) was billed > Rs 10
-- Purpose : Demonstrates filtering on both a specific row and an aggregate
--           condition.
-- --------------------------------------------------------------------------
SELECT mb.billing_month,
       mb.papers_delivered,
       mb.amount_rs
FROM   monthly_bills mb
WHERE  mb.household_id = 1
  AND  mb.amount_rs > 10
ORDER BY mb.billing_month;


-- --------------------------------------------------------------------------
-- QUERY 10 -- Households that have NEVER received a weekly publication
-- Purpose : Uses NOT EXISTS with a correlated subquery to identify households
--           with no weekly-publication deliveries (upsell opportunities).
-- --------------------------------------------------------------------------
SELECT h.id, h.name, h.city
FROM   households h
WHERE  NOT EXISTS (
           SELECT 1
           FROM   daily_deliveries dd
           JOIN   publications p ON dd.publication_id = p.id
           WHERE  dd.household_id = h.id
             AND  p.frequency = 'weekly'
       )
ORDER BY h.id;


-- ============================================================================
-- END OF project.sql
-- ============================================================================




