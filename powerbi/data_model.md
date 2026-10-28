# Data model and relationship guidance

```mermaid
erDiagram
    DATE_DIM {
        date_key int
        date date
        year int
        quarter int
        month int
        month_name varchar
        week int
    }

    PROJECT_FACT {
        project_recid bigint
        project_name varchar
        signed_date date
        date_start date
        closed_date date
        budget_hours decimal
        actual_hours decimal
        remaining_hours decimal
        avg_hourly_rate decimal
        actual_labor_revenue decimal
        total_product_revenue decimal
        total_product_cost decimal
        project_status varchar
        project_segment varchar
        billing_model varchar
    }

    TIME_ENTRY_FACT {
        project_recid bigint
        entry_date date
        member_id bigint
        hours_actual decimal
        hours_bill decimal
        hourly_rate decimal
        labor_revenue decimal
    }

    PRODUCT_FACT {
        project_recid bigint
        product_date date
        quantity decimal
        unit_price decimal
        unit_cost decimal
        product_revenue decimal
        product_cost decimal
    }

    PROJECT_FACT ||--o{ TIME_ENTRY_FACT : contains
    PROJECT_FACT ||--o{ PRODUCT_FACT : contains

    DATE_DIM ||--o{ PROJECT_FACT : starts_on
    DATE_DIM ||--o{ PROJECT_FACT : signed_on
    DATE_DIM ||--o{ PROJECT_FACT : closes_on
    DATE_DIM ||--o{ TIME_ENTRY_FACT : entry_date
    DATE_DIM ||--o{ PRODUCT_FACT : product_date
```

## Relationship rules

1. Use one active date relationship per Date table in Power BI.
2. Keep the other date relationships inactive.
3. Use `USERELATIONSHIP()` in DAX when you intentionally need a non-active relationship.
4. Keep `Project_RecID` as the join key between project, time entry, and product facts.
5. Build a standard date table in Power BI to support weekly and monthly reporting.

## Keys to use

- `Project_RecID` for project-to-time-entry and project-to-product relationships
- `Date` for month/week/quarter slicing
- `Project_Status` and `Project_Segment` for portal reporting

## Recommended Power BI measures

The most critical business measures are:
- Actual Revenue
- Forecast Revenue
- Open Pipeline Value
- Closed Revenue
- Product Revenue / Product Cost
- Budget Hours vs Actual Hours
- Forecast Gross Margin
