select 
    customer_surrogate_key as customer_key,
    customer_id,
    store_id,
    first_name,
    last_name,
    full_name,
    email,
    is_active,
    address,
    district,
    postal_code,
    phone,
    city,
    db_source
from {{ ref('int_customer_enriched') }}