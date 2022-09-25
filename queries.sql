-- Business Question: What is the most common film category rented by each customer?

---------------------------------------------------------
-- Creates rental categories table for all customers --
-- EXPLAIN MORE
---------------------------------------------------------

DROP TABLE IF EXISTS customer_rental_categories;
CREATE TABLE customer_rental_categories AS 
	SELECT c.customer_id, c.first_name, c.last_name, c.email, cat.name
		FROM customer c 
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
	
-----------------------------------------------------------------------------------
-- Determine the most common rental category for each customer (aggregate function)
-----------------------------------------------------------------------------------

DROP TABLE IF EXISTS preferred_category;
CREATE TABLE preferred_category AS
	SELECT customer_id, mode() WITHIN GROUP (ORDER BY name)
		FROM customer_rental_categories
		GROUP BY customer_id;

----------------------
-- SUMMARY REPORT --
----------------------

DROP TABLE IF EXISTS summary_report;
CREATE TABLE summary_report AS
	SELECT c.customer_id, c.first_name, c.last_name, c.email, cpc.mode AS preferred_category
		FROM customer AS c
		JOIN preferred_category AS cpc
			ON c.customer_id = cpc.customer_id;

SELECT * FROM summary_report;
SELECT * FROM preferred_category;

		
----------------------
-- DETAILED REPORT --
----------------------

DROP TABLE IF EXISTS detailed_report;
CREATE TABLE detailed_report AS 
	SELECT 
		c.customer_id,
		COUNT(c.name) FILTER(WHERE name = 'Action') as action,
		COUNT(c.name) FILTER(WHERE name = 'Animation') as animation,
		COUNT(c.name) FILTER(WHERE name = 'Children') as children,
		COUNT(c.name) FILTER(WHERE name = 'Classics') as classics,
		COUNT(c.name) FILTER(WHERE name = 'Comedy') as comedy,
		COUNT(c.name) FILTER(WHERE name = 'Documentary') as documentary,
		COUNT(c.name) FILTER(WHERE name = 'Drama') as drama,
		COUNT(c.name) FILTER(WHERE name = 'Family') as family,
		COUNT(c.name) FILTER(WHERE name = 'Foreign') as foreign,
		COUNT(c.name) FILTER(WHERE name = 'Games') as games,
		COUNT(c.name) FILTER(WHERE name = 'Horror') as horror,
		COUNT(c.name) FILTER(WHERE name = 'Music') as music,
		COUNT(c.name) FILTER(WHERE name = 'New') as new,
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
		p.mode
	ORDER BY
		c.customer_id;

SELECT * FROM detailed_report;

---------------
-- Data Verification 
-- add up all rental counts and compare against total_rentals column in detailed report 
---------------


-------------
-- TRIGGER --
-------------

----------------------
-- STORED PROCEDURE --
----------------------

















-- SAVED CODE FROM DETAILED REPORT -> SAVED JUST IN CASE AN INSERT IS REQUIRED
-- DROP TABLE IF EXISTS detailed_report;
-- CREATE TABLE detailed_report (
-- 	customer_id SMALLINT,
-- 	category_mode VARCHAR,
-- 	action_rentals SMALLINT,
-- 	animation_rentals SMALLINT,
-- 	children_rentals SMALLINT,
-- 	classics_rentals SMALLINT,
-- 	comedy_rentals SMALLINT,
-- 	documentary_rentals SMALLINT,
-- 	drama_rentals SMALLINT,
-- 	family_rentals SMALLINT,
-- 	foreign_rentals SMALLINT,
-- 	games_rentals SMALLINT,
-- 	horror_rentals SMALLINT,
-- 	music_rentals SMALLINT,
-- 	new_rentals SMALLINT,
-- 	scifi_rentals SMALLINT,
-- 	sports_rentals SMALLINT,
-- 	travel_rentals SMALLINT
-- )

-- INSERT INTO detailed_report (
-- 	customer_id,
-- 	category_mode,
-- 	animation_rentals,
-- 	children_rentals,
-- 	classics_rentals,
-- 	comedy_rentals,
-- 	documentary_rentals,
-- 	drama_rentals,
-- 	family_rentals,
-- 	foreign_rentals,
-- 	games_rentals,
-- 	horror_rentals,
-- 	music_rentals,
-- 	new_rentals,
-- 	scifi_rentals,
-- 	sports_rentals,
-- 	travel_rentals 
-- ) 	
