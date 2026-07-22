"""
Volt-Fleet Analytics: BaaS Infrastructure & Asset Health
Step 8: Exploratory Data Analysis (EDA) & Outlier Detection
Author: Senior Data Analyst
"""
# ---------------------------------------------------------
# 1. SETUP & ROBUST FILE PATHS
# ---------------------------------------------------------
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Set visual themes for professional stakeholder presentations
sns.set_theme(style="whitegrid")
plt.rcParams['figure.figsize'] = (12, 7)
plt.rcParams['font.size'] = 11

# Check current working directory to adjust paths dynamically
cwd = os.getcwd()
if cwd.endswith('Python'):
    data_dir = os.path.join(cwd, '../Data') # <-- Removed /raw
    img_dir = os.path.join(cwd, '../Images')
else:
    data_dir = os.path.join(cwd, 'Data')    # <-- Removed /raw
    img_dir = os.path.join(cwd, 'Images')

# Ensure the Images directory exists for saving plots
os.makedirs(img_dir, exist_ok=True)

# Ingestion: Read local copies of our Star Schema tables
try:
    df_batteries = pd.read_csv(os.path.join(data_dir, 'batteries.csv'))
    df_charging = pd.read_csv(os.path.join(data_dir, 'charging_logs.csv'))
    df_stations = pd.read_csv(os.path.join(data_dir, 'stations.csv'))
    df_customers = pd.read_csv(os.path.join(data_dir, 'customers.csv'))
    print("✅ Ingestion Successful!")
    print(f"Loaded {df_charging.shape[0]:,} charging logs and {df_batteries.shape[0]:,} battery profiles.")
except FileNotFoundError as e:
    print(f"❌ Ingestion Failed: Check your relative file paths. Error: {e}")
    exit()
# ---------------------------------------------------------
# 2. DATA QUALITY ASSURANCE & FEATURE ENGINEERING
# ---------------------------------------------------------
print("\n--- Missing Value Review ---")
print("Nulls in Batteries Table:\n", df_batteries.isnull().sum())

# Outlier Detection: Identify impossible telemetry metrics
outliers_soh = df_batteries[(df_batteries['Current_SoH_Pct'] > 100) | (df_batteries['Current_SoH_Pct'] < 0)]
if not outliers_soh.empty:
    print(f"⚠️ Warning: {len(outliers_soh)} records detected with structurally impossible SoH values. Capping at 100%.")
    df_batteries.loc[df_batteries['Current_SoH_Pct'] > 100, 'Current_SoH_Pct'] = 100.0
else:
    print("📊 Data Integrity Check Passed: Battery State of Health contains no anomalies.")

# Feature Engineering: Bin batteries into categorical operational tiers
df_batteries['Health_Category'] = pd.cut(
    df_batteries['Current_SoH_Pct'], 
    bins=[0, 80, 90, 100], 
    labels=['Critical (<80%)', 'Warning (80-90%)', 'Healthy (>90%)']
)

# ---------------------------------------------------------
# 3. STATISTICAL SUMMARIES & DYNAMIC VISUALIZATIONS
# ---------------------------------------------------------
print("\n--- Generating Visualization A: Manufacturer Degradation ---")
plt.figure(figsize=(10, 6))
sns.boxplot(x='Manufacturer', y='Current_SoH_Pct', data=df_batteries, palette='Blues_r', width=0.5)
plt.title('Fleet State of Health (SoH) Distribution Profile by Manufacturer', fontsize=14, fontweight='bold', pad=15)
plt.xlabel('Cell Manufacturer', fontsize=12)
plt.ylabel('Current State of Health (%)', fontsize=12)
plt.savefig(os.path.join(img_dir, 'soh_by_manufacturer.png'), dpi=300, bbox_inches='tight')
plt.close()
print("💾 Visualization A saved successfully to 'Images/soh_by_manufacturer.png'")

print("\n--- Generating Visualization B: Tariff Performance Over Grid ---")
# Join charging logs with station locations to analyze geography
df_grid_merged = pd.merge(df_charging, df_stations, on='StationID', how='inner')
city_financials = df_grid_merged.groupby(['City', 'Is_Peak_Hour'])['Total_Cost_INR'].sum().reset_index()
city_financials['Tariff_Window'] = city_financials['Is_Peak_Hour'].map({1: 'Peak Tariff Hours', 0: 'Off-Peak Hours'})

plt.figure(figsize=(12, 6))
sns.barplot(x='City', y='Total_Cost_INR', hue='Tariff_Window', data=city_financials, palette='Set2')
plt.title('Total Operational Grid Cost by Metro and Tariff Window', fontsize=14, fontweight='bold', pad=15)
plt.xlabel('Metro Territory', fontsize=12)
plt.ylabel('Total Expenses (INR)', fontsize=12)
# Format the large currency units with proper commas on the Y-Axis
plt.gca().yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: format(int(x), ',')))
plt.savefig(os.path.join(img_dir, 'charging_cost_by_city.png'), dpi=300, bbox_inches='tight')
plt.close()
print("💾 Visualization B saved successfully to 'Images/charging_cost_by_city.png'")

# ---------------------------------------------------------
# 4. MULTIVARIATE CORRELATION MATRIX
# ---------------------------------------------------------
print("\n--- Processing Fleet Usage Stress Metrics ---")
# Aggregate continuous transaction history for cumulative operational stress
battery_stress = df_charging.groupby('BatteryID').agg(
    Total_Energy_Drawn=('Energy_Consumed_kWh', 'sum'),
    Cumulative_Charge_Cycles=('LogID', 'count')
).reset_index()

# Blend cumulative stress into asset master profile
df_analytical_profile = pd.merge(df_batteries, battery_stress, on='BatteryID', how='inner')
features_to_correlate = df_analytical_profile[['Current_SoH_Pct', 'Capacity_kWh', 'Total_Energy_Drawn', 'Cumulative_Charge_Cycles']]
matrix_correlation = features_to_correlate.corr()

plt.figure(figsize=(8, 6))
sns.heatmap(matrix_correlation, annot=True, cmap='coolwarm', fmt=".2f", vmin=-1, vmax=1, linewidths=.5)
plt.title('Correlation Matrix: Energy Telemetry vs. Asset Degradation', fontsize=13, fontweight='bold', pad=15)
plt.savefig(os.path.join(img_dir, 'correlation_heatmap.png'), dpi=300, bbox_inches='tight')
plt.close()
print("💾 Heatmap visualization saved successfully to 'Images/correlation_heatmap.png'")
print("\n🎉 Step 8 Python execution completed flawlessly. Ready for reporting layers.")