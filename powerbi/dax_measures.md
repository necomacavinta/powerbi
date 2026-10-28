# Power BI DAX measures for the ConnectWise forecast model

## Required date table

Create a standard Date table in Power BI with at least:
- Date
- Year
- Quarter
- Month Number
- Month Name
- Week Number
- Day Name

Use a calendar from min(project date) to max(project date) plus a small buffer.

## Base measures

```DAX
Actual Labor Revenue =
SUM('vw_Time_Entry_Fact'[Labor_Revenue])
```

```DAX
Actual Product Revenue =
SUM('vw_Product_Fact'[Product_Revenue])
```

```DAX
Actual Revenue =
[Actual Labor Revenue] + [Actual Product Revenue]
```

```DAX
Actual Product Cost =
SUM('vw_Product_Fact'[Product_Cost])
```

```DAX
Actual Hours =
SUM('vw_Time_Entry_Fact'[Hours_Actual])
```

```DAX
Budget Hours =
SUM('vw_Project_Fact'[Budget_Hours])
```

```DAX
Remaining Hours =
SUM('vw_Project_Fact'[Remaining_Hours])
```

## Forecast measures

```DAX
Forecast Labor Revenue =
SUM('vw_Project_Fact'[Remaining_Hours] * 'vw_Project_Fact'[Avg_Hourly_Rate])
```

```DAX
Forecast Product Revenue =
SUM('vw_Product_Fact'[Product_Revenue])
```

```DAX
Forecast Total Revenue =
SUM('vw_Project_Fact'[Remaining_Hours] * 'vw_Project_Fact'[Avg_Hourly_Rate])
+ SUM('vw_Product_Fact'[Product_Revenue])
```

```DAX
Forecast Product Cost =
SUM('vw_Product_Fact'[Product_Cost])
```

```DAX
Forecast Gross Margin =
[Forecast Total Revenue] - [Forecast Product Cost]
```

## Scenario measures

```DAX
Forecast Conservative =
[Forecast Total Revenue] * 0.8
```

```DAX
Forecast Expected =
[Forecast Total Revenue]
```

```DAX
Forecast Aggressive =
[Forecast Total Revenue] * 1.1
```

## Portfolio status measures

```DAX
Open Pipeline Revenue =
CALCULATE(
    [Forecast Total Revenue],
    'vw_Project_Fact'[Project_Status] IN {"Open", "Signed / Not Started"}
)
```

```DAX
Closed Revenue =
CALCULATE(
    [Actual Revenue],
    'vw_Project_Fact'[Project_Status] = "Closed"
)
```

```DAX
TimeMaterial Revenue =
CALCULATE(
    [Actual Revenue] + [Forecast Total Revenue],
    'vw_Project_Fact'[Project_Segment] = "Time & Material"
)
```

```DAX
FullComplete Revenue =
CALCULATE(
    [Actual Revenue] + [Forecast Total Revenue],
    'vw_Project_Fact'[Project_Segment] = "Full Complete"
)
```

## Monthly trend measures

```DAX
Actual Revenue by Month =
TOTALMTD([Actual Revenue], 'Date'[Date])
```

```DAX
Forecast Revenue by Month =
TOTALMTD([Forecast Total Revenue], 'Date'[Date])
```

```DAX
Budget vs Actual =
[Budget Hours] - [Actual Hours]
```

## Recommended relationship setup

- Active relationship: Date[Date] -> vw_Project_Fact[Date_Start]
- Inactive relationships:
  - Date[Date] -> vw_Project_Fact[Signed_Date]
  - Date[Date] -> vw_Project_Fact[Closed_Date]
  - Date[Date] -> vw_Time_Entry_Fact[Entry_Date]
  - Date[Date] -> vw_Product_Fact[Product_Date]

Use USERELATIONSHIP when you need a non-active date relationship in a calculation.
