-- Business Question: What is the most common film category rented by each customer?
------------------------------------------------------------------------------------

-- Creates a new table that shows all rentals by customer id, etc.
DROP TABLE IF EXISTS customer_rental_categories;
CREATE TABLE customer_rental_categories AS 
	SELECT c.customer_id, c.first_name, c.last_name, c.email, cat.name, c.active
		FROM 
			customer c 
		JOIN rental r 
			ON c.customer_id = r.customer_id 
		JOIN inventory i
			ON r.inventory_id = i.inventory_id
		JOIN film f
			ON i.film_id = f.film_id
		JOIN film_category fc
			ON f.film_id = fc.film_id
		JOIN category cat
			ON fc.category_id = cat.category_id
		ORDER BY cat.name;

-- TO VIEW CUSTOMER RENTAL CATEGORIES TABLE
-- SELECT * FROM customer_rental_categories;

-- Creates a table with each customer's id and their most commonly rented movie category.
DROP TABLE IF EXISTS preferred_category;
CREATE TABLE preferred_category AS
	SELECT customer_id, mode() WITHIN GROUP (ORDER BY "name") -- Calculates the mode for film category
		FROM 
			customer_rental_categories
		GROUP BY 
			customer_id;
		
-- TO VIEW PREFERRED CATEGORIES TABLE
-- SELECT * FROM preferred_category;

-------------------------------------------------------
-- B. Creates a new empty table for the summary report.
-------------------------------------------------------

-- Summary Report: 
DROP TABLE IF EXISTS summary_report;
CREATE TABLE summary_report(
	customer_id integer,
	first_name varchar(45),
	last_name varchar(45),
	email varchar(50),
	preferred_category varchar(45),
	active varchar(5)
);

-- TO VIEW EMPTY SUMMARY REPORT TABLE
-- SELECT * FROM summary_report;

---------------------------------------------------------------------------------------------------
-- C & D. Creates a table for the detailed report, extracts the necessary data and transforms the data.
---------------------------------------------------------------------------------------------------

-- Detailed Report: 
DROP TABLE IF EXISTS detailed_report;
CREATE TABLE detailed_report AS 
	SELECT 
		c.customer_id,
		c.first_name,
		c.last_name,
		c.email,
		c.active,
		COUNT(c.name) FILTER(WHERE name = 'Action') as "action",
		COUNT(c.name) FILTER(WHERE name = 'Animation') as animation,
		COUNT(c.name) FILTER(WHERE name = 'Children') as children,
		COUNT(c.name) FILTER(WHERE name = 'Classics') as classics,
		COUNT(c.name) FILTER(WHERE name = 'Comedy') as comedy,
		COUNT(c.name) FILTER(WHERE name = 'Documentary') as documentary,
		COUNT(c.name) FILTER(WHERE name = 'Drama') as drama,
		COUNT(c.name) FILTER(WHERE name = 'Family') as "family",
		COUNT(c.name) FILTER(WHERE name = 'Foreign') as "foreign",
		COUNT(c.name) FILTER(WHERE name = 'Games') as games,
		COUNT(c.name) FILTER(WHERE name = 'Horror') as horror,
		COUNT(c.name) FILTER(WHERE name = 'Music') as music,
		COUNT(c.name) FILTER(WHERE name = 'New') as "new",
		COUNT(c.name) FILTER(WHERE name = 'Sci-Fi') as sci_fi,
		COUNT(c.name) FILTER(WHERE name = 'Sports') as sports,
		COUNT(c.name) FILTER(WHERE name = 'Travel') as travel,
		COUNT(c.name) AS total_rentals,
		p.mode AS preferred_film_category
	FROM 
		customer_rental_categories AS c
	INNER JOIN preferred_category AS p
		ON c.customer_id = p.customer_id
	GROUP BY
		c.customer_id,
		p.mode,
		c.first_name,
		c.last_name,
		c.email,
		c.active
	ORDER BY
		c.customer_id;

-- TO VIEW DETAILED REPORT TABLE
-- SELECT * FROM detailed_report;

-- Data Verification: 																					<-FIX
SELECT COALESCE("action",0) + COALESCE("animation",0) + COALESCE("children",0)
+ COALESCE("classics",0) + COALESCE("comedy",0) + COALESCE("documentary",0) 
+ COALESCE("drama",0)+ COALESCE("family",0) + COALESCE("foreign",0)
+ COALESCE("games",0)+ COALESCE("horror",0) + COALESCE("music",0)
+ COALESCE("new",0) + COALESCE("sci_fi",0) + COALESCE("sports",0)
+ COALESCE("travel",0) AS total_rentals_check, total_rentals 
	FROM detailed_report;
	
-- Test Insert: Shows 																					<-FIX
-- INSERT INTO rental(rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
-- 	VALUES (current_timestamp, 4020, 1, current_timestamp, 2, current_timestamp)

--------------------------------
-- D. TRANSFORMATION FUNCTION --
--------------------------------																		<-FIX

-- CHANGE 1 or 0 to "Active" or "Not Active"
CREATE OR REPLACE FUNCTION transform_active()
	RETURNS VARCHAR
	LANGUAGE PLPGSQL
	AS
$$
DECLARE
BEGIN
END;
$$;

--------------------------
-- E. TRIGGER FUNCTIONS --
--------------------------

-- REFRESHES SUMMARY_REPORT TABLE
CREATE OR REPLACE FUNCTION summary_trigger()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS 
$$
BEGIN
	DELETE FROM summary_report;
	INSERT INTO summary_report (
		SELECT customer_id, first_name, last_name, email, preferred_film_category, active
		FROM
			detailed_report
		ORDER BY
			customer_id
	);
	
	RETURN NEW;
	
END; 
$$;

-- REFRESHES CUSTOMER_RENTAL_CATEGORIES TABLE
CREATE OR REPLACE FUNCTION customer_rental_categories_trigger()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS 
$$
BEGIN
	DELETE FROM customer_rental_categories;
	INSERT INTO customer_rental_categories (
		SELECT c.customer_id, c.first_name, c.last_name, c.email, cat.name, c.active
			FROM 
				customer c 
		JOIN rental r 
			ON c.customer_id = r.customer_id 
		JOIN inventory i
			ON r.inventory_id = i.inventory_id
		JOIN film f
			ON i.film_id = f.film_id
		JOIN film_category fc
			ON f.film_id = fc.film_id
		JOIN category cat
			ON fc.category_id = cat.category_id
		ORDER BY cat.name
	);
	
	RETURN NEW;
	
END;
$$;

-- REFRESHES PREFERRED_CATEGORY TABLE
CREATE OR REPLACE FUNCTION preferred_category_trigger()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
	AS 
$$
BEGIN
	DELETE FROM preferred_category;
	INSERT INTO preferred_category (
		SELECT customer_id, mode() WITHIN GROUP (ORDER BY "name")
			FROM 
				customer_rental_categories
		GROUP BY 
			customer_id
	);
	
	RETURN NEW;
	
END; 
$$;

-------------------------
-- E. TRIGGER CREATION --
-------------------------

-- CREATES CUSTOMER RENTAL CATEGORIES TRIGGER
DROP TRIGGER IF EXISTS crc_table_trigger ON rental;

CREATE TRIGGER crc_table_trigger
AFTER INSERT
ON rental
FOR EACH STATEMENT
EXECUTE PROCEDURE customer_rental_categories_trigger();

-- CREATES PREFERRED CATEGORY TRIGGER CREATION
DROP TRIGGER IF EXISTS pc_table_trigger ON rental;

CREATE TRIGGER pc_table_trigger
AFTER INSERT
ON rental
FOR EACH STATEMENT
EXECUTE PROCEDURE preferred_category_trigger();

-- CREATES SUMMARY TRIGGER CREATION
DROP TRIGGER IF EXISTS summary_report_refresh ON detailed_report;

CREATE TRIGGER summary_report_refresh
AFTER INSERT
ON detailed_report
FOR EACH STATEMENT
EXECUTE PROCEDURE summary_trigger();

-------------------------
-- F. STORED PROCEDURE --
-------------------------

-- 																								<- FIX
CREATE OR REPLACE PROCEDURE refresh_reports()
LANGUAGE PLPGSQL
AS $$
BEGIN
	DELETE FROM detailed_report;
	INSERT INTO detailed_report (
		customer_id,
		first_name,
		last_name,
		email,
		active,
		"action",
		animation,
		children,
		classics,
		comedy,
		documentary,
		drama,
		"family",
		"foreign",
		games,
		horror,
		music,
		"new",
		sci_fi,
		sports,
		travel,
		total_rentals,
		preferred_film_category
	)
	SELECT 
		c.customer_id,
		c.first_name,
		c.last_name,
		c.email,
		c.active,
		COUNT(c.name) FILTER(WHERE name = 'Action') as "action",
		COUNT(c.name) FILTER(WHERE name = 'Animation') as animation,
		COUNT(c.name) FILTER(WHERE name = 'Children') as children,
		COUNT(c.name) FILTER(WHERE name = 'Classics') as classics,
		COUNT(c.name) FILTER(WHERE name = 'Comedy') as comedy,
		COUNT(c.name) FILTER(WHERE name = 'Documentary') as documentary,
		COUNT(c.name) FILTER(WHERE name = 'Drama') as drama,
		COUNT(c.name) FILTER(WHERE name = 'Family') as "family",
		COUNT(c.name) FILTER(WHERE name = 'Foreign') as "foreign",
		COUNT(c.name) FILTER(WHERE name = 'Games') as games,
		COUNT(c.name) FILTER(WHERE name = 'Horror') as horror,
		COUNT(c.name) FILTER(WHERE name = 'Music') as music,
		COUNT(c.name) FILTER(WHERE name = 'New') as "new",
		COUNT(c.name) FILTER(WHERE name = 'Sci-Fi') as sci_fi,
		COUNT(c.name) FILTER(WHERE name = 'Sports') as sports,
		COUNT(c.name) FILTER(WHERE name = 'Travel') as travel,
		COUNT(c.name) AS total_rentals,
		p.mode AS preferred_film_category
	FROM 
		customer_rental_categories AS c
	INNER JOIN preferred_category AS p
		ON c.customer_id = p.customer_id
	GROUP BY
		c.customer_id,
		p.mode,
		c.first_name,
		c.last_name,
		c.email,
		c.active
	ORDER BY
		c.customer_id;
END; 
$$;

-- 
-- CALL refresh_reports();


SELECT * FROM detailed_report;
-- SELECT * FROM summary_report;