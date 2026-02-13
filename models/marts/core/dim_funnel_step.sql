{{ config(materialized='table') }}

with stage_steps as (
    select
        stage_id as funnel_id,
        cast(stage_id as varchar) as funnel_step,
        stage_name as kpi_name,
        'stage' as step_type
    from {{ ref('stg_stages') }}
),

activity_steps as (

    select
        activity_type_id as funnel_id,
        case 
            when activity_type_code='meeting' then '2.1' 
            when activity_type_code='sc_2' then '3.1' end as funnel_step,
        activity_name as kpi_name,
        'activity' as step_type
    from {{ ref('stg_activity_types') }}
    where activity_type_code in ('meeting','sc_2')   -- filter only relevant KPI activities
)

select * from stage_steps
union all
select * from activity_steps
