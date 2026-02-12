-- Grain: 1 row per deal_id + activity_type_code 

{{ config(materialized='table') }}

with activity_joined as (

    select
        a.deal_id,
        a.activity_type_code,
        t.activity_name,
        a.activity_due_at 
    from {{ ref('stg_activity') }} a
    join {{ ref('stg_activity_types') }} t
        on a.activity_type_code = t.activity_type_code
    where a.is_completed = true  -- Assumption that reporting is needed only for activities that are done, supported by observation of having repeating activity_ids with one of them being true.

),

first_calls as (

    select
        deal_id,
        activity_type_code,
        activity_name,
        min(activity_due_at) as first_completed_at
    from activity_joined
    group by deal_id, activity_type_code, activity_name

)

select *
from first_calls order by deal_id,activity_name
