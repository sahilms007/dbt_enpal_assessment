{{ config(materialized='view') }}

select
    id as user_id,
    name as user_name,
    email,
    modified::timestamp  as modified_at
from {{ source('postgres_public', 'users') }}
