with source_pagila as (
    select * from {{ source('pagila_source', 'ACTOR') }}
),

source_sakila as (
    select * from {{ source('sakila_source', 'ACTOR') }}
),

combined as (
    select *, 'pagila' as db_source from source_pagila
    union all
    select *, 'sakila' as db_source from source_sakila
)

select
    cast(ACTOR_ID as integer) as actor_id,
    cast(FIRST_NAME as varchar) as first_name,
    cast(LAST_NAME as varchar) as last_name,
    db_source
from combined