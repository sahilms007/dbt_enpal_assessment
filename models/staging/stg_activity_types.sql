{{ config(materialized='view') }}

select
    id as activity_type_id,
    name as activity_name,
    active as is_active,
    type as activity_type_code
from {{ source('postgres_public', 'activity_types') }}