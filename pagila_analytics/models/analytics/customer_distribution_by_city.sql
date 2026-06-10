with customer_enriched as (
    select city, is_active from {{ ref('dim_customer') }}
)

select 
    city,
    count(case when is_active = 1 then 1 end) as active_customers,
    count(case when is_active = 0 then 1 end) as inactive_customers
from customer_enriched
group by city
order by inactive_customers desc