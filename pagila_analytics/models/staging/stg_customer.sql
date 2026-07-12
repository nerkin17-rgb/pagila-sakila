with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'CUSTOMER') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'CUSTOMER') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['CUSTOMER_ID', 'db_source']) }} as customer_surrogate_key,
    cast(CUSTOMER_ID as integer) as customer_id,
    cast(STORE_ID as integer) as store_id,
    cast(FIRST_NAME as varchar) as first_name,
    cast(LAST_NAME as varchar) as last_name,
    cast(EMAIL as varchar) as email,
    cast(ADDRESS_ID as integer) as address_id,
    cast(ACTIVE as integer) as is_active,
    db_source
from combined