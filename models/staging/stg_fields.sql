{{ config(materialized='view') }}

select
    id as field_id,
    field_key,
    name as field_name,
    field_value_options
from {{ source('postgres_public', 'fields') }}
