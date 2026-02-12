{{ config(materialized='table') }}


-- Stage Entry Events
with stage_events as (
    select
        deal_id,
        stage_entered_at as event_timestamp,
        cast(stage_id as varchar) as funnel_step
    from {{ ref('int_deal_stage_progression') }}
    where stage_entered_at is not null
),

-- Activity entry events
activity_events as (
    select
        deal_id,
        first_completed_at as event_timestamp,
        case 
            when activity_type_code='meeting' then '2.1' 
            when activity_type_code='sc_2' then '3.1' end as funnel_step
    from {{ ref('int_sales_calls') }}
     where first_completed_at is not null
     and activity_type_code in ('meeting','sc_2')   -- filter only relevant KPI activities
)


    select * from stage_events
    union all
    select * from activity_events