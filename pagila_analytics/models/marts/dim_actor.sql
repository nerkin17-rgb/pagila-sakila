select
    actor_id,
    first_name,
    last_name,
    concat(first_name, ' ', last_name) as full_name,
    db_source
from {{ ref('stg_actor') }}