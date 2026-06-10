with source_pagila as (
    select * from {{ source('pagila_source', 'FILM') }}
),

source_sakila as (
    select * from {{ source('sakila_source', 'FILM') }}
),

combined as (
    select *, 'pagila' as db_source from source_pagila
    union all
    select *, 'sakila' as db_source from source_sakila
)

select
    cast(FILM_ID as integer) as film_id,
    cast(TITLE as varchar) as title,
    cast(DESCRIPTION as varchar) as description,
    cast(RELEASE_YEAR as integer) as release_year,
    cast(LANGUAGE_ID as integer) as language_id,
    cast(RENTAL_DURATION as integer) as rental_duration,
    cast(RENTAL_RATE as numeric(4,2)) as rental_rate,
    cast(LENGTH as integer) as length,
    cast(REPLACEMENT_COST as numeric(4,2)) as replacement_cost,
    cast(RATING as varchar) as rating,
    db_source
from combined