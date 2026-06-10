with rentals as (
    select inventory_id, db_source from {{ ref('fact_rental') }}
),

inventory as (
    select inventory_id, film_id, db_source from {{ ref('stg_inventory') }}
),

bridge as (
    select film_id, actor_id, db_source from {{ ref('int_film_actor_bridge') }}
),

actor as (
    select actor_id, first_name, last_name, db_source from {{ ref('dim_actor') }}
)

select
    a.actor_id,
    a.first_name,
    a.last_name,
    count(r.inventory_id) as total_rentals
from actor a
inner join bridge b on a.actor_id = b.actor_id and a.db_source = b.db_source
inner join inventory i on b.film_id = i.film_id and b.db_source = i.db_source
inner join rentals r on i.inventory_id = r.inventory_id and i.db_source = r.db_source
group by a.actor_id, a.first_name, a.last_name
order by total_rentals desc
limit 10