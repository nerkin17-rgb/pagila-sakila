with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'CATEGORY') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'CATEGORY') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['CATEGORY_ID', 'db_source']) }} as category_surrogate_key,
    cast(CATEGORY_ID as integer) as category_id,
    cast(NAME as varchar) as name,
    db_source
from combined