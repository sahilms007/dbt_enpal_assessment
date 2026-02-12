{{ config(materialized='view') }}

select
    activity_id,
    type as activity_type_code,
    assigned_to_user as assigned_user_id,
    deal_id,
    done as is_completed,
    due_to::timestamp as activity_due_at 
from {{ source('postgres_public', 'activity') }}
