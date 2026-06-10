with revenue as (
    select rental_id, amount, db_source from {{ ref('fact_revenue') }}
),

rental as (
    select rental_id, inventory_id, db_source from {{ ref('fact_rental') }}
),

inventory as (
    select inventory_id, film_id, db_source from {{ ref('stg_inventory') }}
),

film as (
    select film_id, category_name, db_source from {{ ref('dim_film') }}
)

select 
    f.category_name as category,
    sum(r.amount) as total_revenue
from film f
inner join inventory i on f.film_id = i.film_id and f.db_source = i.db_source
inner join rental ren on i.inventory_id = ren.inventory_id and i.db_source = ren.db_source
inner join revenue r on ren.rental_id = r.rental_id and ren.db_source = r.db_source
group by f.category_name
order by total_revenue desc
limit 1