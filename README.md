# Enpal Assessment - Sales Funnel Analytics

## 1. Objective

Design and implement a scalable analytics engineering solution that
transforms raw Pipedrive CRM data into a reliable, analytics-ready
monthly sales funnel reporting model.

------------------------------------------------------------------------

## 2. Architecture Overview

    Source → Staging → Intermediate → Core Mart → Reporting Mart

The project follows a layered dbt architecture to ensure separation of
concerns, clarity of grain, and long-term maintainability.

------------------------------------------------------------------------

## 3. Data Layers

### Source Layer

Raw ingestion layer. No transformations applied.

Basic integrity tests ensure primary identifiers are present.

**Raw Postgres tables:** 
- `activity` 
- `activity_types`  
- `stages` 
- `users` 
- `fields`
- `deal_changes`

------------------------------------------------------------------------

### Staging Layer (`stg_*`)

No business logic is introduced at this stage.

**Purpose:** 
- Rename columns for clarity 
- Cast data types 
- Deduplicate records using window functions 
- Standardize structure

------------------------------------------------------------------------

### Intermediate Layer (`int_*`)

Contains reusable business logic and event construction. This layer builds a reusable event-level structure for funnel modelling.

**`int_deal_stage_progression`** 
- Grain: `(deal_id, stage_id)` 
- Captures the first time a deal enters a stage

**`int_sales_calls`** 
- Grain: `(deal_id, activity_type_code)` 
- Captures the first completed sales call event

------------------------------------------------------------------------

### Mart Layer
The mart layer is intentionally divided into two components to separate
reusable analytical logic from presentation-specific reporting models.

### Core Mart (`marts/core`)

The Core Mart contains reusable dimensional and fact models that serve
as the analytical foundation.

**`dim_funnel_step`** 
- Grain: one row per `funnel_step_id` and  `stage_event`
- Defines funnel ordering and KPI mapping

**`fct_deal_funnel_events`** 
- Grain: one row per deal per funnel step event 
- Combines: 
  - Stage transition events 
  - Sales call milestones

------------------------------------------------------------------------

### Reporting Mart (`marts/reporting`)

The Reporting Mart contains presentation-ready aggregated models
designed for BI consumption.

**`rep_sales_funnel_monthly`** 
- Grain: `(month, funnel_step)` 
- Aggregated funnel KPIs 
- Designed for dashboard consumption

------------------------------------------------------------------------

## 4. Final Output

The final model reports:

-   `month`
-   `funnel_step`
-   `kpi_name`
-   `deals_count`

Deals are counted at the first timestamp they enter a funnel step.

------------------------------------------------------------------------

## 5. Design Decisions & Trade-offs

### Event-Based Modeling vs Snapshot Modeling

Two approaches were considered:

**Option A - Snapshot / SCD Type 2** 
- Maintain versioned state history 
- Useful for attribute tracking

**Option B - Event-based modeling (Selected)**

**Rationale:** 
- CRM already provides full event history (`deal_changes`) 
- Funnel analytics requires entry timestamps rather than full dimensional reconstruction 
- Event modelling is simpler and aligned with KPI requirements

**Trade-off:** 
- If attribute history becomes required, dbt snapshots can be introduced.

------------------------------------------------------------------------

### Why a Fact Table?

A unified `fct_deal_funnel_events` centralizes funnel event logic to:

-   Simplify downstream aggregation
-   Avoid repeated logic in reporting models
-   Support future KPI expansion

------------------------------------------------------------------------

### Why a Dimension for Funnel Steps?

`dim_funnel_step` defines ordering and KPI labels instead of hardcoding logic.

Benefits: 
- Improved extensibility 
- Simplified BI integration 
- Centralized funnel logic

------------------------------------------------------------------------

### Deduplication Strategy

Raw source data may contain duplicates. Deduplication is handled in staging to ensure downstream layers operate on deterministic keys and avoid cascading inconsistencies.
Deduplication is handled in staging using:

``` sql
row_number() over (partition by id order by updated_at desc)
```

Only the latest version is retained to ensure:

-   Deterministic primary keys
-   Stable fact generation
-   Reliable testing

------------------------------------------------------------------------

## 6. Data Quality & Testing Strategy

Tests implemented across layers:

-   `not_null` on primary identifiers
-   `unique` on surrogate keys
-   `relationships` for referential integrity
-   Required timestamp validation

Testing is applied progressively:

-   Source → basic integrity
-   Staging → key enforcement
-   Mart → foreign key validation

------------------------------------------------------------------------

## 7. Assumptions

-   A deal is counted once per funnel step (first entry only)
-   Only completed activities are considered valid sales call milestones
-   Non-stage deal changes are excluded from funnel logic

------------------------------------------------------------------------

## 8. Scalability Considerations

-   Event modelling supports incremental builds
-   Intermediate models can be converted to incremental materialization
-   Architecture supports additional KPIs without structural redesign

------------------------------------------------------------------------

## 9. How to Run

``` bash
docker compose up --build
dbt run
dbt test
```

------------------------------------------------------------------------

## 10. Future Improvements

-   Introduce dbt snapshots for dimensional history if required
-   Convert large intermediate models to incremental builds

------------------------------------------------------------------------

## Closing Note

This solution prioritizes:

-   Clear grain definition
-   Separation of concerns
-   Reusable logic
-   Production-oriented modelling
-   Long-term maintainability
