with rentals as (
    select inventory_key from {{ ref('fact_rental') }}
),
inventory as (
    select inventory_key, film_key from {{ ref('stg_inventory') }}
),
bridge as (
    select film_key, actor_key from {{ ref('int_film_actor_bridge') }}
),
actor as (
    select actor_key, actor_id, first_name, last_name from {{ ref('dim_actor') }}
)
select
    a.actor_id,
    a.first_name,
    a.last_name,
    count(r.inventory_key) as total_rentals
from actor a
inner join bridge b on a.actor_key = b.actor_key
inner join inventory i on b.film_key = i.film_key
inner join rentals r on i.inventory_key = r.inventory_key
group by a.actor_id, a.first_name, a.last_name
order by total_rentals desc
limit 10