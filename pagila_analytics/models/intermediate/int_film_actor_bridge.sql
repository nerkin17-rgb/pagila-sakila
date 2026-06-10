with film as (
    select film_id, db_source from {{ ref('stg_films') }}
),

actor as (
    select actor_id, db_source from {{ ref('stg_actor') }}
),

raw_bridge as (
    select cast(FILM_ID as integer) as film_id, cast(ACTOR_ID as integer) as actor_id, 'pagila' as db_source 
    from {{ source('pagila_source', 'FILM_ACTOR') }}
    union all
    select cast(FILM_ID as integer) as film_id, cast(ACTOR_ID as integer) as actor_id, 'sakila' as db_source 
    from {{ source('sakila_source', 'FILM_ACTOR') }}
)

select
    concat(b.film_id, '-', b.actor_id, '-', b.db_source) as film_actor_id,
    f.film_id,
    a.actor_id,
    b.db_source
from raw_bridge b
inner join film f 
    on b.film_id = f.film_id and b.db_source = f.db_source
inner join actor a 
    on b.actor_id = a.actor_id and b.db_source = a.db_source