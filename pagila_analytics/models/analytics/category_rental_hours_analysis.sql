with rental_hours as (
    select 
        c.city,
        f.title,
        f.category_name,
        sum(r.rental_hours) as total_hours
    from {{ ref('dim_customer') }} c
    join {{ ref('fact_rental') }} r on c.customer_id = r.customer_id and c.db_source = r.db_source
    join {{ ref('stg_inventory') }} i on r.inventory_id = i.inventory_id and r.db_source = i.db_source
    join {{ ref('dim_film') }} f on i.film_id = f.film_id and i.db_source = f.db_source
    where r.return_date is not null
    group by c.city, f.title, f.category_name
),

films_starting_with_a as (
    select 
        city,
        category_name,
        total_hours,
        row_number() over (partition by city order by total_hours desc) as rn
    from rental_hours
    where title like 'A%'
),

cities_with_dash as (
    select 
        city,
        category_name,
        total_hours,
        row_number() over (partition by city order by total_hours desc) as rn
    from rental_hours
    where city like '%-%'
)

select 
    'Films starting with "A"' as criteria,
    city,
    category_name,
    total_hours
from films_starting_with_a
where rn = 1

union all

select 
    'Cities with "-"' as criteria,
    city,
    category_name,
    total_hours
from cities_with_dash
where rn = 1
order by criteria, city