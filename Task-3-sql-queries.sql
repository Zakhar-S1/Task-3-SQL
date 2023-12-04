-- 1. Вывести количество фильмов в каждой категории, отсортировать по убыванию.
SELECT c.category_id, c.name, Count(f.film_id) AS Count_of_films_in_category
FROM category c
LEFT JOIN film_category f ON f.category_id = c.category_id
GROUP BY c.category_id
ORDER BY Count_of_films_in_category DESC;

-- 2. Вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.
SELECT a.actor_id, a.first_name, a.last_name, COUNT(r.rental_id) As Quantity
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY a.actor_id
ORDER BY Quantity DESC
LIMIT 10;

-- 3. Вывести категорию фильмов, на которую потратили больше всего денег.
SELECT c.category_id, c.name, SUM(p.amount) AS Money_spending
FROM category c
LEFT JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.category_id
ORDER BY Money_spending DESC
LIMIT 1;

-- 4. Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.
SELECT f.film_id, f.title
FROM film f
WHERE NOT EXISTS (
    SELECT *
    FROM inventory i
    WHERE i.film_id = f.film_id
);

-- 5. Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”. Если у нескольких актеров одинаковое кол-во фильмов, вывести всех.
WITH ActorFilmCounts AS (
    SELECT a.actor_id, a.first_name, a.last_name,
           COUNT(fa.film_id) AS Quantity,
           DENSE_RANK() OVER (ORDER BY COUNT(fa.film_id) DESC) AS d_rank_of_actors
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) = 'CHILDREN' OR LOWER(c.name) = 'children'
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT actor_id, first_name, last_name, Quantity
FROM ActorFilmCounts
WHERE d_rank_of_actors <= 3;

-- 6. Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). Отсортировать по количеству неактивных клиентов по убыванию.
SELECT c.city_id, c.city,
       COUNT(CASE WHEN cu.active = 1 THEN 1 END) AS active_customers,
       COUNT(CASE WHEN cu.active = 0 THEN 1 END) AS inactive_customers
FROM customer cu
JOIN address a ON cu.address_id = a.address_id
JOIN city c ON a.city_id = c.city_id
GROUP BY c.city_id
ORDER BY inactive_customers DESC;

-- 7. Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах (customer.address_id в этом city), и которые начинаются на букву “a”. 
--То же самое сделать для городов в которых есть символ “-”. Написать все в одном запросе.
SELECT 'City with a' AS city_with_a, category_name, total_rental_time
FROM(
    SELECT ca.name AS category_name, SUM(r.return_date - r.rental_date) AS total_rental_time
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN customer cu ON r.customer_id = cu.customer_id
    JOIN address a ON cu.address_id = a.address_id
    JOIN city c ON a.city_id = c.city_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category ca ON fc.category_id = ca.category_id
    WHERE ca.name LIKE 'A%' AND c.city ILIKE 'a%'
    GROUP BY ca.name
    ORDER BY total_rental_time DESC
    LIMIT 1
) AS city_with_a

UNION ALL

SELECT 'City with -' AS city_with_dash, category_name, total_rental_time
FROM(
    SELECT ca.name AS category_name, SUM(r.return_date - r.rental_date) AS total_rental_time
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN customer cu ON r.customer_id = cu.customer_id
    JOIN address a ON cu.address_id = a.address_id
    JOIN city c ON a.city_id = c.city_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category ca ON fc.category_id = ca.category_id
    WHERE ca.name LIKE 'A%' AND c.city ILIKE '%-%'
    GROUP BY ca.name
    ORDER BY total_rental_time DESC
    LIMIT 1
) AS city_with_dash