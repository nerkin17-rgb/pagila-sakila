with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'ADDRESS') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'ADDRESS') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['ADDRESS_ID', 'db_source']) }} as address_surrogate_key,
    cast(ADDRESS_ID as integer) as address_id,
    cast(ADDRESS as varchar) as address,
    cast(DISTRICT as varchar) as district,
    cast(CITY_ID as integer) as city_id,
    cast(POSTAL_CODE as varchar) as postal_code,
    cast(PHONE as varchar) as phone,
    db_source
from combined