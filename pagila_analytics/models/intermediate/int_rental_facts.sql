with rental as (
    select * from {{ ref('stg_rental') }}
),

payment as (
    select * from {{ ref('stg_payment') }}
)

select
    r.rental_id,
    r.customer_id,
    r.inventory_id,
    r.staff_id,
    r.rental_date,
    r.return_date,
    datediff('hour', r.rental_date, r.return_date) as rental_hours,
    datediff('day', r.rental_date, r.return_date) as rental_duration_days,
    p.payment_id,
    p.amount as payment_amount,
    p.payment_date,
    r.db_source
from rental r
left join payment p 
    on r.rental_id = p.rental_id and r.db_source = p.db_source