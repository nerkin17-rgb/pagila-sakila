with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'CITY') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'CITY') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['CITY_ID', 'db_source']) }} as city_surrogate_key,
    cast(CITY_ID as integer) as city_id,
    cast(CITY as varchar) as city,
    cast(COUNTRY_ID as integer) as country_id,
    db_source
from combined