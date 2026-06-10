with film_data as (
    select 
        category_name,
        film_id
    from {{ ref('dim_film') }}
)

select
    category_name as category,
    count(film_id) as movie_count
from film_data
group by category_name
order by movie_count desc