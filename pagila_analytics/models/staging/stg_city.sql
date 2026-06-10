with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'CITY') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'CITY') }}
)
select
    cast(CITY_ID as integer) as city_id,
    cast(CITY as varchar) as city,
    cast(COUNTRY_ID as integer) as country_id,
    db_source
from combined