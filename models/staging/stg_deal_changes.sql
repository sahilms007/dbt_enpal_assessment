{{ config(materialized='view') }}

select
    deal_id,
    changed_field_key as changed_field,
    new_value,
    change_time::timestamp as changed_at
from {{ source('postgres_public', 'deal_changes') }}
