select
    payment_id,
    customer_id,
    staff_id,
    rental_id,
    payment_amount as amount,
    payment_date,
    db_source
from {{ ref('int_rental_facts') }}
where payment_id is not null -- Берем только те записи, где реально был платеж