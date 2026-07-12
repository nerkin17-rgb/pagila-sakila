with revenue as (
    select inventory_key, amount from {{ ref('fact_revenue') }} r
    join {{ ref('fact_rental') }} ren on r.rental_key = ren.rental_key
),
inventory as (
    select inventory_key, film_key from {{ ref('stg_inventory') }}
),
film as (
    select film_key, category_name from {{ ref('dim_film') }}
)
select 
    f.category_name as category,
    sum(r.amount) as total_revenue
from film f
inner join inventory i on f.film_key = i.film_key
inner join revenue r on i.inventory_key = r.inventory_key
group by f.category_name
order by total_revenue desc
limit 1