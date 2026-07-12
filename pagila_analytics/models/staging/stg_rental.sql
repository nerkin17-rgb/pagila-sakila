with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'RENTAL') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'RENTAL') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['RENTAL_ID', 'db_source']) }} as rental_surrogate_key,
    cast(RENTAL_ID as integer) as rental_id,
    cast(RENTAL_DATE as timestamp) as rental_date,
    cast(INVENTORY_ID as integer) as inventory_id,
    cast(CUSTOMER_ID as integer) as customer_id,
    cast(RETURN_DATE as timestamp) as return_date,
    cast(STAFF_ID as integer) as staff_id,
    db_source
from combined