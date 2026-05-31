# Online Retail Sales Analytics Pipeline

> Final Project — Data Engineering Course
> Universitas Ciputra Surabaya

---

## 👥 Contributors

| Name | NIM |
|------|-----|
| Amanda Renata Go | 0706022310010 |
| Catherine Eline Santoso | 0706022310009 |
| Deborah Michelle Kwandinata | 0706022310014 |
| Feylin Christelia | 0706022310012 |
| Ruby Arthalia Golden | 0706022310035 |

---

## 📐 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Apache Airflow                           │
│                    (Orchestration Layer)                         │
└───────────────┬─────────────────────┬───────────────────────────┘
                │                     │
                ▼                     ▼
┌──────────────────────┐   ┌─────────────────────────────────────┐
│   Ingestion Script   │   │            dbt Pipeline              │
│    (load_raw.py)     │   │  Staging (Silver) → Marts (Gold)    │
└──────────┬───────────┘   └──────────────────┬──────────────────┘
           │                                   │
           ▼                                   ▼
┌──────────────────────────────────────────────────────────────── ┐
│                     PostgreSQL Warehouse                         │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────────────┐  │
│  │   Bronze    │   │    Silver    │   │        Gold         │  │
│  │ (raw layer) │──▶│  (staging)   │──▶│  (dimensional model)│  │
│  └─────────────┘   └──────────────┘   └─────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
                                     ┌─────────────────────────┐
                                     │        Metabase          │
                                     │  (Visualization Layer)   │
                                     └─────────────────────────┘
```

---

## 📝 Project Description

This project implements an end-to-end batch data pipeline for the **Online Retail II** dataset, a real-world e-commerce transaction dataset from a UK-based online retailer spanning 2009–2011.

The pipeline follows the **Bronze → Silver → Gold** medallion architecture:
- **Bronze**: Raw data loaded as-is from Excel into PostgreSQL
- **Silver**: Cleaned, deduplicated, and type-casted data via dbt staging models
- **Gold**: Dimensional star schema (fact + dimension tables) via dbt mart models

The entire pipeline is orchestrated by **Apache Airflow** and containerized with **Docker**.

---

## 📦 Dataset Description

| Attribute | Detail |
|-----------|--------|
| Source | [UCI Machine Learning Repository — Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) |
| Format | Excel (.xlsx), 2 sheets |
| Period | December 2009 – December 2011 |
| Total Rows | ~1,067,371 transactions |
| Columns | Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country |

---

## 🗂️ Data Model Diagram

### Star Schema (Gold Layer)

```
                    ┌─────────────────┐
                    │   dim_date      │
                    │─────────────────│
                    │ date_key (PK)   │
                    │ date_day        │
                    │ year            │
                    │ quarter         │
                    │ month           │
                    │ month_name      │
                    │ week_of_year    │
                    │ day_of_week     │
                    │ is_weekend      │
                    └────────┬────────┘
                             │
┌─────────────────┐          │          ┌─────────────────┐
│  dim_customers  │          │          │  dim_products   │
│─────────────────│          │          │─────────────────│
│ customer_key(PK)│          │          │ product_key (PK)│
│ customer_id     │          │          │ stock_code      │
│ country         │          │          │ description     │
│ total_invoices  │          │          │ avg_price       │
│ first_purchase  │◀─────────┼─────────▶│                 │
│ last_purchase   │          │          └─────────────────┘
└─────────────────┘          │
                    ┌────────▼────────┐
                    │   fact_sales    │
                    │─────────────────│
                    │ fact_key (PK)   │
                    │ customer_key(FK)│
                    │ product_key (FK)│
                    │ date_key (FK)   │
                    │ invoice_id      │
                    │ country         │
                    │ is_return       │
                    │ quantity        │
                    │ unit_price      │
                    │ line_total      │
                    │ invoice_date    │
                    └─────────────────┘
```

---

## 🚀 How to Run

### Prerequisites
- Docker Desktop (running)
- Git

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/<your-username>/final-project-data-engineering.git
cd final-project-data-engineering
```

**2. Add the dataset**

Place `online_retail_II.xlsx` inside the `ingestion/` folder.

**3. Initialize the database and Airflow**
```bash
docker-compose up airflow-init
```
Wait until you see: `User "admin" created with role "Admin"`

**4. Start all services**
```bash
docker-compose up -d
```

Wait ~60 seconds for all services to be healthy.

**5. Access the services**

| Service | URL | Credentials |
|---------|-----|-------------|
| Airflow | http://localhost:8088 | admin / admin |
| Metabase | http://localhost:3001 | setup on first visit |

**6. Trigger the pipeline**

In Airflow UI:
- Go to DAGs → `online_retail_pipeline`
- Click the ▶️ (Trigger DAG) button
- Monitor the task progress

**7. Connect Metabase to the warehouse**

In Metabase setup:
- Database type: **PostgreSQL**
- Host: `postgres-warehouse`
- Port: `5432`
- Database: `online_retail`
- Username: `warehouse`
- Password: `warehouse`

---

## 📊 Expected Output

### Airflow DAG Graph View
> *(Screenshot to be added after successful run)*

```
ingest_to_bronze  ──▶  dbt_run  ──▶  dbt_test
```

### Metabase Dashboard Charts
> *(Screenshots to be added after dashboard is built)*

1. Monthly Revenue Trend
2. Top 10 Products by Revenue
3. Revenue by Country

---

## 🔍 Findings & Conclusion

> *(To be filled after pipeline runs and dashboard is built)*

Key business questions this pipeline answers:
- Which months generate the highest revenue?
- Which products are the top sellers?
- Which countries contribute the most to total sales?

---

## ⚠️ Known Limitations

- The dataset file (`online_retail_II.xlsx`) must be manually placed in the `ingestion/` folder before running — it is not included in the repository due to file size.
- The ingestion script uses `if_exists='replace'` which reloads all data on every run. For production use, incremental loading should be implemented.
- Metabase uses a PostgreSQL backend; the `metabase` database is auto-created by `init-db.sh` on first run only. If the volume already exists, re-run with `docker-compose down -v`.

---

## 📁 Project Structure

```
final-project/
├── README.md                        # This file
├── docker-compose.yml               # All services wired together
├── airflow.Dockerfile               # Custom Airflow image with dbt installed
├── init-db.sh                       # Auto-create metabase database on postgres startup
├── .gitignore
├── container/
│   ├── dags/
│   │   └── pipeline_dag.py         # Airflow DAG definition
│   ├── config/
│   └── logs/
├── dbt/
│   └── online_retail/
│       ├── dbt_project.yml
│       ├── profiles.yml
│       └── models/
│           ├── staging/
│           │   ├── sources.yml
│           │   ├── staging.yml
│           │   └── stg_online_retail.sql
│           └── marts/
│               ├── marts.yml
│               ├── dim_customers.sql
│               ├── dim_products.sql
│               ├── dim_date.sql
│               └── fact_sales.sql
└── ingestion/
    └── load_raw.py                  # Extract & load raw data to Bronze
```