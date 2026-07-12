with film as (
    select * from {{ ref('stg_films') }}
),
category as (
    select * from {{ ref('stg_category') }}
),
film_category as (
    select * from {{ ref('stg_film_category') }}
)
select
    f.film_surrogate_key as film_key,
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    f.language_id,
    f.rental_duration,
    f.rental_rate,
    f.length,
    f.replacement_cost,
    f.rating,
    coalesce(c.name, 'Unknown') as category_name,
    f.db_source
from film f
left join film_category fc 
    on f.film_id = fc.film_id and f.db_source = fc.db_source
left join category c 
    on fc.category_id = c.category_id and fc.db_source = c.db_source