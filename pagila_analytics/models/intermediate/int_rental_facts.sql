with rental as (
    select * from {{ ref('stg_rental') }}
),
payment as (
    select * from {{ ref('stg_payment') }}
),
customer as (
    select customer_id, customer_surrogate_key, db_source from {{ ref('stg_customer') }}
),
inventory as (
    select inventory_id, inventory_surrogate_key, db_source from {{ ref('stg_inventory') }}
)
select
    r.rental_surrogate_key,
    r.rental_id,
    c.customer_surrogate_key,
    i.inventory_surrogate_key,
    r.staff_id,
    r.rental_date,
    r.return_date,
    datediff('hour', r.rental_date, r.return_date) as rental_hours,
    datediff('day', r.rental_date, r.return_date) as rental_duration_days,
    p.payment_surrogate_key,
    p.amount as payment_amount,
    p.payment_date,
    r.db_source
from rental r
left join payment p 
    on r.rental_id = p.rental_id and r.db_source = p.db_source
left join customer c
    on r.customer_id = c.customer_id and r.db_source = c.db_source
left join inventory i
    on r.inventory_id = i.inventory_id and r.db_source = i.db_source