# Power BI Forecast Model for ConnectWise

This repository contains the SQL and Power BI planning artifacts for a ConnectWise-based project forecast dashboard.

The model supports:
- Time & Material vs Full Complete project segmentation
- Signed, Open, and Closed project status tracking
- Actual vs budgeted hours
- Labor revenue and product revenue/cost analysis
- Monthly and weekly forecast views
- Trend reporting for next-month and next-quarter planning

## Repository structure

- `sql/forecast_views.sql` — SQL Server views for project fact, time entries, product data, and forecast-ready outputs
- `powerbi/data_model.md` — data model diagram and relationship guidance
- `powerbi/dax_measures.md` — Power BI DAX measures for forecast reporting
- `powerbi/report_layout.md` — recommended dashboard layout and KPIs

## Core idea

The model is built as a star schema with:
- `vw_Project_Fact` — one row per project
- `vw_Time_Entry_Fact` — one row per time entry
- `vw_Product_Fact` — one row per product line item
- `vw_Project_Forecast_Ready` — one row per project with forecast metrics
- Date dimension in Power BI

## Recommended Power BI flow

1. Import the SQL views into Power BI Desktop.
2. Create a Date table in Power BI.
3. Build relationships:
   - Project_RecID between project and time/product fact tables
   - Date table joined to the relevant date columns with active/inactive relationships
4. Add the DAX measures from `powerbi/dax_measures.md`.
5. Use the visuals described in `powerbi/report_layout.md`.

## Notes

- This project is intended to support financial planning and staffing decisions.
- Forecast revenue is based on remaining hours multiplied by realized average hourly rate, plus product revenue.
- Use conservative, expected, and aggressive scenarios if finance needs a range forecast.

## Next steps

Open Power BI Desktop and import the SQL views from the SQL Server database. Then create the Date table and apply the DAX measures.
