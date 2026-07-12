with film as (
    select film_id, film_surrogate_key, db_source from {{ ref('stg_films') }}
),
actor as (
    select actor_id, actor_surrogate_key, db_source from {{ ref('stg_actor') }}
),
raw_bridge as (
    select cast(FILM_ID as integer) as film_id, cast(ACTOR_ID as integer) as actor_id, 'pagila' as db_source 
    from {{ source('pagila_source', 'FILM_ACTOR') }}
    union all
    select cast(FILM_ID as integer) as film_id, cast(ACTOR_ID as integer) as actor_id, 'sakila' as db_source 
    from {{ source('sakila_source', 'FILM_ACTOR') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['b.film_id', 'b.actor_id', 'b.db_source']) }} as film_actor_surrogate_key,
    f.film_surrogate_key,
    a.actor_surrogate_key,
    b.db_source
from raw_bridge b
inner join film f 
    on b.film_id = f.film_id and b.db_source = f.db_source
inner join actor a 
    on b.actor_id = a.actor_id and b.db_source = a.db_source