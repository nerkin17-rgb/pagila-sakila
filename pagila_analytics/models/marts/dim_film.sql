with film as (
    select * from {{ ref('stg_films') }}
),

category as (
    select * from {{ ref('stg_category') }}
),

-- Читаем связь фильм-категория напрямую из источников
film_category as (
    select cast(FILM_ID as integer) as film_id, cast(CATEGORY_ID as integer) as category_id, 'pagila' as db_source 
    from {{ source('pagila_source', 'FILM_CATEGORY') }}
    union all
    select cast(FILM_ID as integer) as film_id, cast(CATEGORY_ID as integer) as category_id, 'sakila' as db_source 
    from {{ source('sakila_source', 'FILM_CATEGORY') }}
)

select
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