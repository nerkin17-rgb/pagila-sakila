with customer as (
    select * from {{ ref('stg_customer') }}
),
address as (
    select * from {{ ref('stg_address') }}
),
city as (
    select * from {{ ref('stg_city') }}
)
select
    c.customer_surrogate_key,
    c.customer_id,
    c.store_id,
    c.first_name,
    c.last_name,
    concat(c.first_name, ' ', c.last_name) as full_name,
    c.email,
    c.is_active,
    a.address,
    a.district,
    a.postal_code,
    a.phone,
    ci.city,
    c.db_source
from customer c
left join address a 
    on c.address_id = a.address_id and c.db_source = a.db_source
left join city ci 
    on a.city_id = ci.city_id and a.db_source = ci.db_source