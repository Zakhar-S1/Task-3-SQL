-- 1. Вывести количество фильмов в каждой категории, отсортировать по убыванию.
SELECT category.name, Count(film_category.film_id) AS Count_of_films_in_category
FROM category 
LEFT JOIN film_category ON category.category_id = film_category.category_id
GROUP BY category.name
ORDER BY Count_of_films_in_category DESC;

-- 2. Вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.
SELECT actor.actor_id, actor.first_name, actor.last_name, COUNT(rental.rental_id) As Quantity
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film ON film_actor.film_id = film.film_id
JOIN inventory ON film.film_id = inventory.film_id
JOIN rental ON inventory.inventory_id = rental.inventory_id
GROUP BY actor.actor_id
ORDER BY Quantity DESC
LIMIT 10;

-- 3. Вывести категорию фильмов, на которую потратили больше всего денег.
SELECT category.category_id, category.name, SUM(payment.amount) AS Money_spending
FROM category 
LEFT JOIN film_category ON category.category_id = film_category.category_id
JOIN film ON film_category.film_id = film.film_id
JOIN inventory ON film.film_id = inventory.film_id
JOIN rental ON inventory.inventory_id = rental.inventory_id
JOIN payment ON rental.rental_id = payment.rental_id
GROUP BY category.category_id
ORDER BY Money_spending DESC
LIMIT 1;

-- 4. Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.
SELECT film.film_id, film.title
FROM film
WHERE NOT EXISTS (
    SELECT *
    FROM inventory
    WHERE inventory.film_id = film.film_id
)
GROUP BY film.film_id, film.title;

-- 5. Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”. Если у нескольких актеров одинаковое кол-во фильмов, вывести всех.
WITH ActorFilmCounts AS (
    SELECT actor.actor_id, actor.first_name, actor.last_name,
           COUNT(film_actor.film_id) AS Quantity,
           DENSE_RANK() OVER (ORDER BY COUNT(film_actor.film_id) DESC) AS d_rank_of_actors,
           RANK() OVER (ORDER BY COUNT(film_actor.film_id) DESC) AS rank_of_actors
    FROM actor
    JOIN film_actor ON actor.actor_id = film_actor.actor_id
    JOIN film ON film_actor.film_id = film.film_id
    JOIN film_category ON film.film_id = film_category.film_id
    JOIN category ON film_category.category_id = category.category_id
    WHERE category.name = 'Children'
    GROUP BY actor.actor_id, actor.first_name, actor.last_name
)
SELECT actor_id, first_name, last_name, Quantity
FROM ActorFilmCounts
WHERE d_rank_of_actors <= 3 AND rank_of_actors <= 3;

-- 6. Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). Отсортировать по количеству неактивных клиентов по убыванию.
SELECT city.city_id, city.city,
       COUNT(CASE WHEN customer.active = 1 THEN 1 END) AS active_customers,
       COUNT(CASE WHEN customer.active = 0 THEN 1 END) AS inactive_customers
FROM customer
JOIN address ON customer.address_id = address.address_id
JOIN city ON address.city_id = city.city_id
GROUP BY city.city_id
ORDER BY inactive_customers DESC;

-- 7. Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах (customer.address_id в этом city), и которые начинаются на букву “a”. 
--То же самое сделать для городов в которых есть символ “-”. Написать все в одном запросе.
SELECT category.name AS category_name, SUM(rental.return_date - rental.rental_date) AS total_rental_time
FROM film
JOIN inventory ON film.film_id = inventory.film_id
JOIN rental ON inventory.inventory_id = rental.inventory_id
JOIN customer ON rental.customer_id = customer.customer_id
JOIN address ON customer.address_id = address.address_id
JOIN city ON address.city_id = city.city_id
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
WHERE (category.name LIKE 'A%' AND city.city ILIKE 'a%') OR (category.name LIKE 'A%' AND city.city ILIKE '%-%')
GROUP BY category.name
ORDER BY total_rental_time DESC
LIMIT 1;