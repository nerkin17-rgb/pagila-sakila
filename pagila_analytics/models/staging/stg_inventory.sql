with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'INVENTORY') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'INVENTORY') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['INVENTORY_ID', 'db_source']) }} as inventory_surrogate_key,
    cast(INVENTORY_ID as integer) as inventory_id,
    cast(FILM_ID as integer) as film_id,
    cast(STORE_ID as integer) as store_id,
    db_source
from combined