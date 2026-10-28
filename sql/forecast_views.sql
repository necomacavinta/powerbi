-- SQL Server views for a Power BI forecast model using ConnectWise project data
-- Adjust database/schema names if your ConnectWise environment is not under [cwwebapp_iventure].[dbo].

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[vw_Project_Fact]
AS
SELECT
    p.PM_Project_RecID AS Project_RecID,
    p.Project_ID AS Project_Name,
    p.Company_RecID,
    pt.Description AS Project_Type,
    ps.Description AS Project_Status_Description,
    m.First_Name + ' ' + m.Last_Name AS Project_Manager,
    p.AGR_Header_RecID AS Agreement_RecID,
    a.AGR_Name AS Agreement_Name,
    bm.Description AS Billing_Model,

    CAST(p.Date_Entered_UTC AS DATE) AS Signed_Date,
    CAST(p.Date_Start AS DATE) AS Date_Start,
    CAST(p.Date_Closed_UTC AS DATE) AS Closed_Date,
    CAST(p.Date_Req AS DATE) AS Requested_Date,

    TRY_CAST(p.Est_Hours AS DECIMAL(18,4)) AS Budget_Hours,
    TRY_CAST(p.Est_Revenue AS DECIMAL(18,2)) AS Estimated_Labor_Revenue,
    TRY_CAST(p.Project_Amount AS DECIMAL(18,2)) AS Project_Amount,
    TRY_CAST(p.Est_Time_Cost AS DECIMAL(18,2)) AS Est_Time_Cost,
    TRY_CAST(p.Est_Product_Cost AS DECIMAL(18,2)) AS Est_Product_Cost,
    TRY_CAST(p.Est_Expense_Cost AS DECIMAL(18,2)) AS Est_Expense_Cost,
    TRY_CAST(p.Est_Product_Revenue AS DECIMAL(18,2)) AS Est_Product_Revenue,
    TRY_CAST(p.Est_Expense_Revenue AS DECIMAL(18,2)) AS Est_Expense_Revenue,

    ISNULL(te_agg.Hours_Actual, 0) AS Actual_Hours,
    ISNULL(te_agg.Actual_Labor_Revenue, 0) AS Actual_Labor_Revenue,

    ISNULL(prod_agg.Total_Product_Qty, 0) AS Total_Product_Quantity,
    ISNULL(prod_agg.Total_Product_Revenue, 0) AS Total_Product_Revenue,
    ISNULL(prod_agg.Total_Product_Cost, 0) AS Total_Product_Cost,

    CASE
        WHEN p.Date_Closed_UTC IS NOT NULL AND CAST(p.Date_Closed_UTC AS DATE) < CAST(GETDATE() AS DATE)
            THEN 'Closed'
        WHEN p.Date_Start IS NOT NULL AND CAST(p.Date_Start AS DATE) <= CAST(GETDATE() AS DATE)
            THEN 'Open'
        WHEN p.Date_Entered_UTC IS NOT NULL AND CAST(p.Date_Entered_UTC AS DATE) <= CAST(GETDATE() AS DATE)
            THEN 'Signed / Not Started'
        ELSE 'Unclassified'
    END AS Project_Status,

    CASE
        WHEN LOWER(COALESCE(bm.Description,'')) LIKE '%time%' OR LOWER(COALESCE(bm.Description,'')) LIKE '%material%'
            THEN 'Time & Material'
        WHEN LOWER(COALESCE(bm.Description,'')) LIKE '%fixed%' OR LOWER(COALESCE(bm.Description,'')) LIKE '%full%' OR LOWER(COALESCE(bm.Description,'')) LIKE '%complete%'
            THEN 'Full Complete'
        ELSE 'Other'
    END AS Project_Segment,

    CASE
        WHEN TRY_CAST(p.Est_Hours AS DECIMAL(18,4)) > 0
            THEN TRY_CAST(p.Est_Hours AS DECIMAL(18,4)) - ISNULL(te_agg.Hours_Actual, 0)
        ELSE 0
    END AS Remaining_Hours,

    CASE
        WHEN ISNULL(te_agg.Hours_Actual, 0) > 0
            THEN ISNULL(te_agg.Actual_Labor_Revenue, 0) / te_agg.Hours_Actual
        WHEN TRY_CAST(p.Est_Hours AS DECIMAL(18,4)) > 0 AND TRY_CAST(p.Est_Revenue AS DECIMAL(18,2)) > 0
            THEN TRY_CAST(p.Est_Revenue AS DECIMAL(18,2)) / TRY_CAST(p.Est_Hours AS DECIMAL(18,4))
        ELSE 0
    END AS Avg_Hourly_Rate

FROM [cwwebapp_iventure].[dbo].[PM_Project] p
LEFT JOIN [cwwebapp_iventure].[dbo].[PM_Type] pt
    ON p.PM_Type_RecID = pt.PM_Type_RecID
LEFT JOIN [cwwebapp_iventure].[dbo].[PM_Status] ps
    ON p.PM_Status_RecID = ps.PM_Status_RecID
LEFT JOIN [cwwebapp_iventure].[dbo].[Member] m
    ON p.Member_ID = m.Member_ID
LEFT JOIN [cwwebapp_iventure].[dbo].[PM_Billing_Method] bm
    ON p.PM_Billing_Method_ID = bm.PM_Billing_Method_ID
   AND p.Override_Flag = bm.Override_Flag
LEFT JOIN [cwwebapp_iventure].[dbo].[AGR_Header] a
    ON p.AGR_Header_RecID = a.AGR_Header_RecID

OUTER APPLY (
    SELECT
        SUM(TRY_CAST(TE.Hours_Actual AS DECIMAL(18,4))) AS Hours_Actual,
        SUM(
            TRY_CAST(TE.Hours_Actual AS DECIMAL(18,4)) *
            TRY_CAST(TE.Hourly_Rate AS DECIMAL(18,4))
        ) AS Actual_Labor_Revenue
    FROM [cwwebapp_iventure].[dbo].[Time_Entry] TE
    WHERE TE.PM_Project_RecID = p.PM_Project_RecID
) te_agg

OUTER APPLY (
    SELECT
        SUM(TRY_CAST(ip.Quantity AS DECIMAL(18,4))) AS Total_Product_Qty,
        SUM(
            TRY_CAST(ip.Quantity AS DECIMAL(18,4)) *
            TRY_CAST(ip.Unit_Price AS DECIMAL(18,4))
        ) AS Total_Product_Revenue,
        SUM(
            TRY_CAST(ip.Quantity AS DECIMAL(18,4)) *
            TRY_CAST(ip.Unit_Cost AS DECIMAL(18,4))
        ) AS Total_Product_Cost
    FROM [cwwebapp_iventure].[dbo].[IV_Product] ip
    WHERE ip.PM_Project_RecID = p.PM_Project_RecID
) prod_agg

WHERE
    ISNULL(pt.Description, '') NOT LIKE '%Onboarding%'
    AND ISNULL(pt.Description, '') NOT LIKE '%On Boarding%'
    AND ISNULL(p.Project_ID, '') NOT LIKE '%onboarding%'
    AND ISNULL(p.Project_ID, '') NOT LIKE '%on boarding%'
GO

CREATE OR ALTER VIEW [dbo].[vw_Time_Entry_Fact]
AS
SELECT
    TE.PM_Project_RecID AS Project_RecID,
    p.Project_ID AS Project_Name,
    CAST(COALESCE(TE.Date_Entered_UTC, TE.Date_Start_UTC, TE.Date_End_UTC) AS DATE) AS Entry_Date,
    TE.Member_ID,
    TRY_CAST(TE.Hours_Actual AS DECIMAL(18,4)) AS Hours_Actual,
    TRY_CAST(TE.Hours_Bill AS DECIMAL(18,4)) AS Hours_Bill,
    TRY_CAST(TE.Hourly_Rate AS DECIMAL(18,4)) AS Hourly_Rate,
    TRY_CAST(TE.Hours_Actual AS DECIMAL(18,4)) * TRY_CAST(TE.Hourly_Rate AS DECIMAL(18,4)) AS Labor_Revenue,
    CASE
        WHEN LOWER(COALESCE(bm.Description,'')) LIKE '%time%' OR LOWER(COALESCE(bm.Description,'')) LIKE '%material%'
            THEN 'Time & Material'
        WHEN LOWER(COALESCE(bm.Description,'')) LIKE '%fixed%' OR LOWER(COALESCE(bm.Description,'')) LIKE '%full%' OR LOWER(COALESCE(bm.Description,'')) LIKE '%complete%'
            THEN 'Full Complete'
        ELSE 'Other'
    END AS Project_Segment
FROM [cwwebapp_iventure].[dbo].[Time_Entry] TE
LEFT JOIN [cwwebapp_iventure].[dbo].[PM_Project] p
    ON TE.PM_Project_RecID = p.PM_Project_RecID
LEFT JOIN [cwwebapp_iventure].[dbo].[PM_Billing_Method] bm
    ON p.PM_Billing_Method_ID = bm.PM_Billing_Method_ID
   AND p.Override_Flag = bm.Override_Flag
WHERE TE.PM_Project_RecID IS NOT NULL
GO

CREATE OR ALTER VIEW [dbo].[vw_Product_Fact]
AS
SELECT
    ip.PM_Project_RecID AS Project_RecID,
    p.Project_ID AS Project_Name,
    CAST(COALESCE(ip.Date_Entered_UTC, ip.Date_Entered, ip.Date_Added_UTC) AS DATE) AS Product_Date,
    TRY_CAST(ip.Quantity AS DECIMAL(18,4)) AS Quantity,
    TRY_CAST(ip.Unit_Price AS DECIMAL(18,4)) AS Unit_Price,
    TRY_CAST(ip.Unit_Cost AS DECIMAL(18,4)) AS Unit_Cost,
    TRY_CAST(ip.Quantity AS DECIMAL(18,4)) * TRY_CAST(ip.Unit_Price AS DECIMAL(18,4)) AS Product_Revenue,
    TRY_CAST(ip.Quantity AS DECIMAL(18,4)) * TRY_CAST(ip.Unit_Cost AS DECIMAL(18,4)) AS Product_Cost
FROM [cwwebapp_iventure].[dbo].[IV_Product] ip
LEFT JOIN [cwwebapp_iventure].[dbo].[PM_Project] p
    ON ip.PM_Project_RecID = p.PM_Project_RecID
WHERE ip.PM_Project_RecID IS NOT NULL
GO

CREATE OR ALTER VIEW [dbo].[vw_Project_Forecast_Ready]
AS
SELECT
    pf.Project_RecID,
    pf.Project_Name,
    pf.Project_Type,
    pf.Project_Status_Description,
    pf.Project_Manager,
    pf.Billing_Model,
    pf.Project_Segment,
    pf.Signed_Date,
    pf.Date_Start,
    pf.Closed_Date,
    pf.Budget_Hours,
    pf.Actual_Hours,
    pf.Remaining_Hours,
    pf.Avg_Hourly_Rate,

    pf.Actual_Labor_Revenue,
    pf.Total_Product_Revenue,
    pf.Total_Product_Cost,

    pf.Actual_Labor_Revenue + pf.Total_Product_Revenue AS Actual_Total_Revenue,

    CASE
        WHEN pf.Project_Segment = 'Time & Material'
            THEN pf.Remaining_Hours * pf.Avg_Hourly_Rate
        ELSE 0
    END AS Forecast_Labor_Revenue,

    CASE
        WHEN pf.Project_Segment = 'Time & Material'
            THEN (pf.Remaining_Hours * pf.Avg_Hourly_Rate) + pf.Total_Product_Revenue
        ELSE pf.Total_Product_Revenue
    END AS Forecast_Total_Revenue,

    pf.Total_Product_Cost AS Forecast_Product_Cost,

    CASE
        WHEN pf.Project_Segment = 'Time & Material'
            THEN (pf.Remaining_Hours * pf.Avg_Hourly_Rate) + pf.Total_Product_Revenue - pf.Total_Product_Cost
        ELSE pf.Total_Product_Revenue - pf.Total_Product_Cost
    END AS Forecast_Gross_Margin,

    pf.Project_Status
FROM [dbo].[vw_Project_Fact] pf
GO

CREATE OR ALTER VIEW [dbo].[vw_Project_Monthly_Rollup]
AS
SELECT
    pf.Project_RecID,
    pf.Project_Name,
    pf.Project_Segment,
    pf.Project_Status,
    DATEFROMPARTS(
        YEAR(COALESCE(pf.Date_Start, pf.Signed_Date, GETDATE())),
        MONTH(COALESCE(pf.Date_Start, pf.Signed_Date, GETDATE())),
        1
    ) AS Month_Start,
    pf.Budget_Hours,
    pf.Actual_Hours,
    pf.Remaining_Hours,
    pf.Actual_Labor_Revenue,
    pf.Total_Product_Revenue,
    pf.Total_Product_Cost,
    CASE
        WHEN pf.Project_Segment = 'Time & Material'
            THEN pf.Remaining_Hours * pf.Avg_Hourly_Rate
        ELSE 0
    END AS Monthly_Forecast_Labor_Revenue
FROM [dbo].[vw_Project_Fact] pf
WHERE pf.Project_Status IN ('Open', 'Signed / Not Started', 'Closed')
GO
