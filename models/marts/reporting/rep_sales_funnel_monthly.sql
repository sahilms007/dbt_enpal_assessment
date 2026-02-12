{{ config(materialized='table') }}

with enriched as (

    select
        date_trunc('month', f.event_timestamp) as month,
        f.deal_id,
        d.funnel_step,
        d.kpi_name
    from {{ ref('fct_deal_funnel_events') }} f
    join {{ ref('dim_funnel_step') }} d
         on f.funnel_step = d.funnel_step
)

select
    month,
    kpi_name,
    funnel_step,
    count(distinct deal_id) as deals_count
from enriched
group by 1,2,3
order by 1,3
