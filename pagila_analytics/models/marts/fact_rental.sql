select
    rental_surrogate_key as rental_key,
    rental_id,
    customer_surrogate_key as customer_key,
    inventory_surrogate_key as inventory_key,
    staff_id,
    rental_date,
    return_date,
    rental_hours,
    rental_duration_days,
    db_source
from {{ ref('int_rental_facts') }}