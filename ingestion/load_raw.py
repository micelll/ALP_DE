import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
import os
from datetime import datetime

# Mengambil parameter koneksi dari DB_URL murni
DB_URL = os.getenv(
    "WAREHOUSE_DB_URL",
    "postgresql://warehouse:warehouse@postgres-warehouse:5432/online_retail"
)

def load_raw_data():
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
    
    # Menangani nilai NaN/Null agar aman saat masuk ke Postgres (mengubah NaN menjadi None)
    df = df.where(pd.notnull(df), None)
    
    print(f"[{datetime.now()}] Total rows: {len(df)}")
    
    print(f"[{datetime.now()}] Connecting to PostgreSQL via psycopg2...")
    # Membuka koneksi murni menggunakan psycopg2
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        # 1. Buat schema bronze
        print(f"[{datetime.now()}] Creating schema 'bronze' if not exists...")
        cur.execute("CREATE SCHEMA IF NOT EXISTS bronze;")
        
        # 2. Drop tabel lama jika ada (meniru efek if_exists='replace')
        print(f"[{datetime.now()}] Preparing target table...")
        cur.execute("DROP TABLE IF EXISTS bronze.raw_online_retail;")
        
        # 3. Buat struktur tabel secara manual sesuai kolom dataset
        cur.execute("""
            CREATE TABLE bronze.raw_online_retail (
                invoice VARCHAR(50),
                stockcode VARCHAR(50),
                description TEXT,
                quantity INTEGER,
                invoicedate TIMESTAMP,
                price NUMERIC,
                customer_id VARCHAR(50),
                country VARCHAR(100)
            );
        """)
        
        # 4. Proses pemindahan data menggunakan execute_values (sangat cepat)
        print(f"[{datetime.now()}] Inserting data to bronze.raw_online_retail...")
        
        # Mengubah dataframe menjadi list of tuples
        data_tuples = [tuple(x) for x in df.to_numpy()]
        
        # Query insert
        insert_query = """
            INSERT INTO bronze.raw_online_retail 
            (invoice, stockcode, description, quantity, invoicedate, price, customer_id, country) 
            VALUES %s
        """
        
        # Eksekusi dengan batch size 10.000 baris sekaligus
        execute_values(cur, insert_query, data_tuples, page_size=10000)
        
        # Commit seluruh transaksi
        conn.commit()
        print(f"[{datetime.now()}] Done! Loaded {len(df)} rows to bronze.raw_online_retail")
        
    except Exception as e:
        conn.rollback()
        print(f"[{datetime.now()}] Error occurred: {e}")
        raise e
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    load_raw_data()