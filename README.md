# Volt-Fleet Analytics Dashboard

### Dashboard Link : https://app.powerbi.com/groups/5252c73d-27bc-43a1-9117-0485b25ceef1/reports/3ecb1796-8777-44b0-8ee3-c34b811a8065/b6dcac2f37a0d9ed9a5d?experience=power-bi

# Problem Statement

This dashboard helps organizations analyze Battery-as-a-Service (BaaS) fleet performance, station operations, and financial efficiency by providing interactive visualizations of swap and telemetry data. It enables users to monitor wait time trends, evaluate customer churn risk, analyze grid charging costs across different cities, and identify key operational bottlenecks.

The dashboard provides comprehensive insights into total swaps, cumulative grid costs, operational wait times, customer retention segmentation, and daily volume trends. These insights help fleet operators make data-driven decisions, assess station efficiency, and improve overall network management.

Interactive filters allow users to explore swap data based on specific cities and dynamic date ranges.

---
## Technologies Used

- Python (Pandas, Matplotlib, Seaborn for EDA & Data Generation)
- AWS S3
- Snowflake
- Power BI Desktop
- Power Query Editor
- DAX
- Power BI Service
---

## Architecture

```text
Python Script (01_eda_and_health.py)
    │
    ▼
CSV Dataset
    │
    ▼
AWS S3
    │
    ▼
Snowflake
    │
    ▼
Power BI Desktop
    │
    ▼
Power Query Editor
    │
    ▼
DAX Measures (Iterators & Cumulative Totals)
    │
    ▼
Interactive Dashboard (Custom Dark UI)
    │
    ▼
Power BI Service
```
---

## Steps Followed

- Step 1 : Utilized Python (Pandas) to generate over 160,000 rows of synthetic transactional and telemetry data for a BaaS network.

- Step 2 : Executed Exploratory Data Analysis (EDA) using Matplotlib and Seaborn for outlier detection and feature engineering.

- Step 3 : Uploaded the generated fleet dataset to an AWS S3 bucket.

- Step 4 : Connected Snowflake with AWS S3 using a Storage Integration and External Stage.

- Step 5 : Loaded the dataset from AWS S3 into Snowflake tables using the COPY INTO command.

- Step 6 : Connected Snowflake to Power BI Desktop using the Snowflake connector.

- Step 7 : Opened Power Query Editor and performed data type formatting and final transformations.

- Step 8 : Built the data model by creating the required relationships.

- Step 9 : Created DAX measures including:
  
  (a) Total Swaps
  
  (b) Total Grid Cost

  (c) Cumulative Swaps (Using variables and context iterators)

  (d) Average Wait Time

- Step 10 : Designed a custom dark-themed UI with consistent #161A23 backgrounds and #00E396 (Mint Green) accents.

- Step 11 : Designed the Executive Overview dashboard to analyze grid cost breakdowns, subscription splits, and top-level KPIs.
  
- Step 12 : Developed the Station Operations dashboard to analyze wait times, battery fleet health, and hourly grid cost heatmaps.
  
- Step 13 : Built the Financials & Retention dashboard to monitor unit economics, customer churn risk segmentation, and cumulative daily volume.
  
- Step 14 : Added interactive filtering (City & Date Slicers) and Bookmark-driven "Reset" buttons to enable dynamic analysis.
  
- Step 15 : Published the report to Power BI Service.
  
---

# Snapshot of Dashboard (Power BI Service)

<img width="1918" height="853" alt="Screenshot 2026-07-22 200609" src="https://github.com/user-attachments/assets/79365ef1-b8f2-4f4b-81bf-d5be5d2a47b1" />



---

# Report Snapshot (Power BI Desktop)

## Executive Overview

<img width="1912" height="792" alt="Screenshot 2026-07-22 200720" src="https://github.com/user-attachments/assets/54e68696-4427-4c20-a79b-2af09b698cf9" />



---

## Operational Health

<img width="1918" height="795" alt="Screenshot 2026-07-22 200658" src="https://github.com/user-attachments/assets/ab8b0fa9-fa97-4a01-a50e-ffc44f7fc2b8" />



---

## Financials & Retention

<img width="1918" height="792" alt="Screenshot 2026-07-22 200645" src="https://github.com/user-attachments/assets/487d71b7-1379-419b-8286-6b56ced99f99" />



---

# Report PDF

If you do not have Power BI Desktop installed, you can view the complete dashboard report in PDF format.

📄 **Volt-Fleet Analytics Dashboard Report**

[Download Report PDF](https://github.com/user-attachments/files/30273724/Volt_Fleet_Analytics.pdf)


---

# Exploratory Data Analysis (Python)

Prior to cloud ingestion and Power BI deployment, exploratory data analysis (EDA) was performed in Python to validate telemetry data integrity, evaluate battery degradation trends, and identify operational bottlenecks.

### 1. Battery Fleet Health by Manufacturer
<img width="2565" height="1695" alt="soh_by_manufacturer" src="https://github.com/user-attachments/assets/13a9f431-66eb-4e55-aa43-5a4840a59768" />
<i>Figure 1: Boxplot analysis of the Fleet State of Health (SoH) Distribution Profile comparing cell manufacturers (Amara Raja, LG Chem, Exide). This visual helps identify if specific suppliers exhibit faster capacity degradation.</i>

### 2. Operational Grid Cost Variance
<img width="3158" height="1695" alt="charging_cost_by_city" src="https://github.com/user-attachments/assets/f056534e-1006-46f5-b241-355ccb588b15" />
<i>Figure 2: Total Operational Grid Cost grouped by Metro Territory and Tariff Window. This highlights the financial impact of Peak vs. Off-Peak charging strategies across Bengaluru, Delhi, and Pune.</i>

### 3. Feature Correlation Matrix
<img width="2473" height="2155" alt="correlation_heatmap" src="https://github.com/user-attachments/assets/27dc82d1-55a8-4f3e-ba7e-7de071cf39ef" />
<i>Figure 3: Correlation Matrix analyzing interactions between Energy Telemetry (Total Energy Drawn, Capacity) and Asset Degradation (Current SoH, Cumulative Charge Cycles).</i>

---

# Insights

A three-page interactive report was created in Power BI Desktop and published to Power BI Service.

Following inferences can be drawn from the dashboard;

## [1] Executive Overview

### Top-Level Network KPIs
The dashboard tracks high-level operational and financial metrics including:
- Total Swaps (80K)
- Total Grid Cost (₹ 12.00M)
- Average Wait Time (22.52 Mins)
- Peak Cost Percentage (56.35%)
This provides operators with an immediate pulse on fleet utilization and expenses.

### Grid Cost Breakdown by City & Station
A decomposition tree visualizes the hierarchy of the ₹ 12.00M total grid cost, allowing users to drill down from the overall network to specific cities (Pune, Bengaluru, Delhi) and individual station nodes to identify the highest cost centers.

### Subscription Split
Revenue streams are analyzed between:
- Fixed-Monthly (49.38%)
- Pay-Per-KM (50.62%)
This breakdown helps business strategy teams understand customer preference in pricing models.

### Average Wait Time by City
Average customer wait times are compared across Delhi, Bengaluru, and Pune to evaluate regional operational efficiency and identify underperforming territories.

---

## [2] Station Operations

### Station Efficiency Matrix
A scatter plot evaluates Total Grid Cost against Total Swaps across all stations. This visual helps operators quickly identify outlier stations that are highly inefficient (high cost, low volume) or highly profitable (low cost, high volume).

### Top 5 Stations by Wait Time
The dashboard flags the most congested hubs (e.g., STN-017, STN-028) by highlighting the top 5 stations with the highest average wait times. This allows regional managers to prioritize battery supply rebalancing.

### Battery Fleet Health
Asset health is segmented into three categories:
- Healthy (38.55%)
- Warning - Monitor (40.2%)
- Degraded - Replace Soon (21.25%)
This enables predictive maintenance and helps forecast capital expenditure for battery replacements.

### Hourly Grid Cost Heatmap
A matrix tracks charging costs across a 24-hour cycle (0.00 to 23.00), segmented by city. This temporal mapping allows operators to optimize charging schedules to take advantage of off-peak energy tariffs.

---

## [3] Financials & Retention

### Customer Churn Risk Segmentation
User retention is categorized based on wait time tolerance and swap frequency:
- Standard Retained
- Highly Loyal
- At Risk (Tolerating Delay)
This enables marketing and operations teams to target "At Risk" segments with retention campaigns or service improvements.

### Unit Economics: Grid Cost Per Swap
A time-series analysis (Jan 2025 - Jun 2025) tracking the daily fluctuation of grid costs per swap to monitor ongoing profitability and energy price volatility.

### Operational Bottlenecks: Excess Wait Time
A daily trend line visualizing the total excess wait time (in minutes) across the network, helping to pinpoint specific days or weeks where operational capacity failed to meet customer demand.

### Daily Volume vs. Cumulative Swaps
A combo chart maps the daily transactional volume (Total Swaps) against a continuously growing tracking metric (Cumulative Swaps). This visualizes the overall growth trajectory and scaling speed of the BaaS network over the six-month period.

## [4] Interactive Analysis

The report enables dynamic exploration using interactive Power BI visuals.

Users can analyze fleet performance by applying different filters (such as specific Date ranges and Metro Cities) and exploring relationships between station efficiency, grid charging costs, battery asset health, and customer wait times. The inclusion of bookmark-driven reset controls ensures seamless navigation during deep-dive data discovery.

---

## [5] Business Insights

The dashboard helps Battery-as-a-Service (BaaS) and EV fleet organizations to:

- Monitor overall network utilization and station-level operational performance.
- Track grid cost fluctuations and wait time trends over multiple months.
- Analyze customer retention and segment users based on churn risk.
- Evaluate charging expenses based on peak vs. off-peak tariff windows across different territories.
- Compare operational efficiency and profitability across individual swapping stations.
- Identify asset health risks and forecast battery fleet replacement needs.
- Support data-driven energy procurement and operational management decisions.

The dashboard provides a comprehensive overview of fleet operations, unit economics, and asset health, enabling better strategic decision-making for EV fleet operators.

---

# Dashboard Features

The dashboard includes the following interactive features:

- Custom enterprise-grade Dark UI with custom SVG iconography.
- Dynamic filtering across multiple station and temporal attributes.
- Cross-filtering and cross-highlighting between visuals.
- Interactive KPI cards for operational performance analysis.
- Bookmark-driven Global Filter Reset controls.
- Multi-page report navigation.

---

# Business Value

This dashboard helps Battery-as-a-Service (BaaS) and EV fleet organizations to:

- Monitor overall fleet performance.
- Identify operational bottlenecks and wait time trends.
- Evaluate churn risk across different customer segments.
- Understand user behavior based on subscription types and locations.
- Improve decision-making using cloud-scaled data pipelines and insights.


---

# Files Included

This repository contains:

- Volt_Fleet_Analytics.pbix (Power BI Dashboard)
- 01_eda_and_health.py (Python Data Generation & EDA Script)
- Snowflake_SQL_Scripts.sql (Cloud data warehouse scripts)
- /images/ (Exported Matplotlib/Seaborn statistical charts)
- Dataset
- README.md

---



# How to Use

1. Clone this repository.

```
git clone https://github.com/uddipta089/Volt-Fleet-Analytics-Dashboard
```

2. Run the 01_eda_and_health.py script to generate the synthetic dataset and EDA charts.

3. Upload the generated dataset to an AWS S3 bucket.

4. Create the required Snowflake objects (Database, Schema, Table, Storage Integration, Stage, and File Format) using the provided SQL scripts.

5. Load the dataset from AWS S3 into Snowflake using the COPY INTO command.

6. Open the Power BI (.pbix) file.

7. Update the Snowflake connection parameters if required.

8. Refresh the dataset.
   
9. Explore the interactive dashboards.

---

# Dashboard Link

Power BI Service

[Volt-Fleet Analytics Dashboard](https://app.powerbi.com/groups/5252c73d-27bc-43a1-9117-0485b25ceef1/reports/3ecb1796-8777-44b0-8ee3-c34b811a8065/b6dcac2f37a0d9ed9a5d?experience=power-bi)

---

# Project Report

📄 **Download Dashboard Report**

[Volt-Fleet Analytics Report](https://github.com/user-attachments/files/30276755/Volt_Fleet_Analytics.pdf)


---

# GitHub Repository

[Volt-Fleet Analytics Dashboard](https://github.com/uddipta089/Volt-Fleet-Analytics-Dashboard)

---

# Dataset

[swap_transactions.csv](https://github.com/user-attachments/files/30276809/swap_transactions.csv)

[stations.csv](https://github.com/user-attachments/files/30276808/stations.csv)

[customers.csv](https://github.com/user-attachments/files/30276806/customers.csv)

[charging_logs.csv](https://github.com/user-attachments/files/30276803/charging_logs.csv)

[batteries.csv](https://github.com/user-attachments/files/30276801/batteries.csv)




---

# Author

**Uddipta Pathak**

LinkedIn:
[Uddipta Pathak](https://www.linkedin.com/in/uddipta-pathak-144272335/?lipi=urn%3Ali%3Apage%3Ad_flagship3_profile_view_base_contact_details%3BxGYUjRMARu6n%2BFP6WvNvHA%3D%3D)

GitHub:
[uddipta089](https://github.com/uddipta089)

Email:
<uddiptapathak0831@gmail.com>

---

# Acknowledgements

This project demonstrates practical implementation of:

- AWS S3
- Snowflake Data Warehousing
- Python (Pandas/Seaborn)
- Power BI & Power Query Editor
- DAX & Data Modeling
- UI/UX Design for Analytics

---

# Future Improvements

- Real-time data ingestion using Snowpipe.
- Automated dashboard refresh.
- Predictive wait-time analysis using Machine Learning.
- Integration with live telemetry API endpoints.

---
