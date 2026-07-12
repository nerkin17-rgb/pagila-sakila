select
    payment_surrogate_key as payment_key,
    rental_surrogate_key as rental_key,
    customer_surrogate_key as customer_key,
    staff_id,
    payment_amount as amount,
    payment_date,
    db_source
from {{ ref('int_rental_facts') }}
where payment_surrogate_key is not null