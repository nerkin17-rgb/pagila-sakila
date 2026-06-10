with film as (
    select film_id, title, db_source from {{ ref('dim_film') }}
),

inventory as (
    select inventory_id, film_id, db_source from {{ ref('stg_inventory') }}
)

select 
    f.film_id,
    f.title
from film f
left join inventory i on f.film_id = i.film_id and f.db_source = i.db_source
where i.inventory_id is null
order by f.title