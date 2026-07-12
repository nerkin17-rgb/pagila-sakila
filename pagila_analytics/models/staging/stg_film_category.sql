with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'FILM_CATEGORY') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'FILM_CATEGORY') }}
)
select
    cast(FILM_ID as integer) as film_id,
    cast(CATEGORY_ID as integer) as category_id,
    db_source
from combined