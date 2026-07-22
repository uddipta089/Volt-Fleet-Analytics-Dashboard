import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# Set random seed for reproducibility
np.random.seed(42)

# --- 1. Generate Dim_Stations ---
cities = ['Bengaluru', 'Delhi', 'Pune']
stations_data = []
for i in range(1, 51):
    city = random.choice(cities)
    stations_data.append({
        'StationID': f'STN-{i:03}',
        'City': city,
        'Total_Ports': random.choice([10, 20, 30]),
        'Peak_Grid_Cost_Per_kWh': round(random.uniform(8.0, 10.0), 2),
        'OffPeak_Grid_Cost_Per_kWh': round(random.uniform(3.5, 5.0), 2)
    })
df_stations = pd.DataFrame(stations_data)
df_stations.to_csv('stations.csv', index=False)

# --- 2. Generate Dim_Customers ---
customers_data = []
models = ['Tata Punch EV', 'MG Windsor EV', 'Maruti e Vitara']
plans = ['Pay-Per-KM', 'Fixed-Monthly']
statuses = ['Active', 'Active', 'Active', 'Defaulted', 'Suspended'] # Weighted to active

for i in range(1, 5001):
    plan = random.choice(plans)
    rate_km = round(random.uniform(2.6, 4.5), 2) if plan == 'Pay-Per-KM' else None
    monthly_fee = random.choice([1500, 2000, 2500, 3000]) if plan == 'Fixed-Monthly' else None
    
    customers_data.append({
        'CustomerID': f'CUST-{i:04}',
        'City': random.choice(cities),
        'Vehicle_Model': random.choice(models),
        'Subscription_Plan': plan,
        'Rate_Per_KM': rate_km,
        'Monthly_Fee': monthly_fee,
        'Account_Status': random.choice(statuses)
    })
df_customers = pd.DataFrame(customers_data)
df_customers.to_csv('customers.csv', index=False)

# --- 3. Generate Dim_Batteries ---
batteries_data = []
manufacturers = ['Exide', 'Amara Raja', 'LG Chem']
for i in range(1, 2001):
    batteries_data.append({
        'BatteryID': f'BAT-{i:04}',
        'Capacity_kWh': random.choice([30, 40, 50]),
        'Manufacturer': random.choice(manufacturers),
        'Manufacture_Date': datetime(2023, 1, 1) + timedelta(days=random.randint(0, 365)),
        'Current_SoH_Pct': round(random.uniform(75.0, 100.0), 2)
    })
df_batteries = pd.DataFrame(batteries_data)
df_batteries.to_csv('batteries.csv', index=False)

# --- 4. Generate Fact_Swap_Transactions & Fact_Charging_Logs ---
swaps = []
charges = []
start_date = datetime(2025, 1, 1)

# Generate 80,000 transactions over 6 months
for i in range(1, 80001):
    txn_date = start_date + timedelta(days=random.randint(0, 180))
    station = random.choice(stations_data)
    
    bat_ret = f'BAT-{random.randint(1, 2000):04}'
    bat_iss = f'BAT-{random.randint(1, 2000):04}'
    while bat_ret == bat_iss: # ensure different batteries
        bat_iss = f'BAT-{random.randint(1, 2000):04}'
        
    swaps.append({
        'TransactionID': f'TXN-{i:06}',
        'Date': txn_date.strftime('%Y-%m-%d'),
        'CustomerID': f'CUST-{random.randint(1, 5000):04}',
        'StationID': station['StationID'],
        'Battery_Returned_ID': bat_ret,
        'Battery_Issued_ID': bat_iss,
        'Odometer_Reading': random.randint(100, 50000),
        'Wait_Time_Minutes': random.randint(0, 45)
    })
    
    # Simulate the subsequent charging of the returned battery
    start_hour = random.randint(0, 23)
    is_peak = 1 if (8 <= start_hour <= 11) or (17 <= start_hour <= 21) else 0
    energy_used = round(random.uniform(10.0, 40.0), 2)
    cost = energy_used * station['Peak_Grid_Cost_Per_kWh'] if is_peak else energy_used * station['OffPeak_Grid_Cost_Per_kWh']
    
    charges.append({
        'LogID': f'CHG-{i:06}',
        'Date': txn_date.strftime('%Y-%m-%d'),
        'StationID': station['StationID'],
        'BatteryID': bat_ret,
        'Start_Hour': start_hour,
        'Energy_Consumed_kWh': energy_used,
        'Is_Peak_Hour': is_peak,
        'Total_Cost_INR': round(cost, 2)
    })

df_swaps = pd.DataFrame(swaps)
df_swaps.to_csv('swap_transactions.csv', index=False)

df_charges = pd.DataFrame(charges)
df_charges.to_csv('charging_logs.csv', index=False)

print("Success! 5 CSV files generated totaling over 160,000 rows.")