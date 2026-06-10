with combined as (
    select *, 'pagila' as db_source from {{ source('pagila_source', 'PAYMENT') }}
    union all
    select *, 'sakila' as db_source from {{ source('sakila_source', 'PAYMENT') }}
)
select
    cast(PAYMENT_ID as integer) as payment_id,
    cast(CUSTOMER_ID as integer) as customer_id,
    cast(STAFF_ID as integer) as staff_id,
    cast(RENTAL_ID as integer) as rental_id,
    cast(AMOUNT as numeric(5,2)) as amount,
    cast(PAYMENT_DATE as timestamp) as payment_date,
    db_source
from combined