select
    rental_id,
    customer_id,
    inventory_id,
    staff_id,
    rental_date,
    return_date,
    rental_hours,
    rental_duration_days,
    db_source
from {{ ref('int_rental_facts') }}