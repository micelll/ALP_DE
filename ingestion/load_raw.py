import pandas as pd
from sqlalchemy import create_engine, text
import os
from datetime import datetime

# Koneksi ke warehouse
DB_URL = os.getenv(
    "WAREHOUSE_DB_URL",
    "postgresql://warehouse:warehouse@postgres-warehouse:5432/online_retail"
)

def load_raw_data():
    engine = create_engine(DB_URL)
    
    # Path file Excel
    excel_path = "/opt/airflow/ingestion/online_retail_II.xlsx"
    
    print(f"[{datetime.now()}] Reading Excel file...")
    
    # Baca kedua sheet
    df_2009 = pd.read_excel(excel_path, sheet_name="Year 2009-2010", dtype={"Customer ID": str})
    df_2010 = pd.read_excel(excel_path, sheet_name="Year 2010-2011", dtype={"Customer ID": str})
    
    # Gabungkan
    df = pd.concat([df_2009, df_2010], ignore_index=True)
    
    # Rename kolom supaya PostgreSQL-friendly (lowercase, no spaces)
    df.columns = [c.lower().replace(" ", "_") for c in df.columns]
    # Sekarang kolom: invoice, stockcode, description, quantity, invoicedate, price, customer_id, country
    
    print(f"[{datetime.now()}] Total rows: {len(df)}")
    
    # Buat schema 'bronze' kalau belum ada
    with engine.connect() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS bronze"))
        conn.commit()
    
    # Load ke tabel bronze.raw_online_retail
    # if_exists='replace' supaya idempotent (aman dijalankan ulang)
    df.to_sql(
        name="raw_online_retail",
        schema="bronze",
        con=engine,
        if_exists="replace",
        index=False,
        chunksize=10000
    )
    
    print(f"[{datetime.now()}] Done! Loaded {len(df)} rows to bronze.raw_online_retail")

if __name__ == "__main__":
    load_raw_data()