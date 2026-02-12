-- Grain: first time a deal enters a stage

{{ config(materialized='table') }}

with stage_changes as (
    select
        deal_id,
        cast(nullif(new_value,'') as int) as stage_id,
        changed_at
    from {{ ref('stg_deal_changes') }}
    where changed_field = 'stage_id'
      and new_value is not null
),

--- to remove duplication on deal stages and show only the progressiob
deduplicated as (
    select
        deal_id,
        stage_id,
        changed_at,
        row_number() over (
            partition by deal_id, stage_id
            order by changed_at asc
        ) as rn
    from stage_changes 
),

stage_lookup as (

    select
        stage_id,
        stage_name
    from {{ ref('stg_stages') }}
)

select
    d.deal_id,
    d.stage_id,
    s.stage_name,
    d.changed_at as stage_entered_at
from deduplicated d
left join stage_lookup s
    on d.stage_id = s.stage_id
where d.rn = 1 -- selecting the first instance of stage when there are multiple same stage transition for a deal
