with film as (
    select film_id, category_name, db_source from {{ ref('dim_film') }}
    where category_name = 'Children'
),

bridge as (
    select film_id, actor_id, db_source from {{ ref('int_film_actor_bridge') }}
),

actor as (
    select actor_id, first_name, last_name, db_source from {{ ref('dim_actor') }}
),

actor_children_films as (
    select 
        a.actor_id,
        a.first_name,
        a.last_name,
        count(distinct f.film_id) as film_count,
        a.db_source
    from actor a
    inner join bridge fa on a.actor_id = fa.actor_id and a.db_source = fa.db_source
    inner join film f on fa.film_id = f.film_id and fa.db_source = f.db_source
    group by a.actor_id, a.first_name, a.last_name, a.db_source
),

ranked_actors as (
    select 
        *,
        dense_rank() over (order by film_count desc) as rank
    from actor_children_films
)

select 
    actor_id,
    first_name,
    last_name,
    film_count
from ranked_actors
where rank <= 3
order by rank, last_name, first_name