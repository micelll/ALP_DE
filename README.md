# Data Engineering Final Project — Online Retail Sales Analytics Medallion Pipeline

## Table of Contents

- [Final Dataset](#final-dataset)
- [Architecture Diagram](#architecture-diagram)
- [Domain](#domain)
- [Project Description](#project-description)
- [Problem Statement](#problem-statement)
- [Project Objectives](#project-objectives)
- [Technology Stack](#technology-stack)
- [Pipeline Architecture](#pipeline-architecture)
- [Planned Data Transformation Layers](#planned-data-transformation-layers)
- [Planned Business Insights](#planned-business-insights)
- [How to Run](#how-to-run)
- [Metabase Dashboard](#metabase-dashboard)
- [Findings & Conclusion](#findings--conclusion)
- [Known Limitations](#known-limitations)
- [Contributors](#contributors)

---

## Final Dataset

This project uses the following final dataset:

**Online Retail II (UCI Machine Learning Repository)**  
Source: University of California, Irvine (UCI)

Dataset file: `online_retail_II.xlsx` (inside the `ingestion/` folder)

Dataset Link: https://archive.ics.uci.edu/dataset/502/online+retail+ii

### Dataset Validation Result

The transaction dataset was audited and validated prior to ingestion. The metrics below establish the production baseline verified during the engineering phase:

| Validation Metric | Target Baseline | Actual Result | Verification Status |
|---|---|---|---|
| Dataset File Size | Minimum 10 MB | ~45.00 MB | ✅ Passed |
| Total Row Count | Minimum 500,000 rows | 1,067,371 rows | ✅ Passed |
| Non-Null Customer IDs | Traceable identities | 824,374 records | ✅ Filtered in Silver |
| Duplicate Records | Zero redundant inputs | Identified & Cleaned | ✅ Fixed via dbt |
| Temporal Range | Minimum 12 Months | 24 Months (2009-2011) | ✅ Verified |

### Dataset Columns

| Column | Description |
|---|---|
| Invoice | 6-digit nominal number uniquely assigned to each transaction (Pre StockCode) |
| StockCode | 5-digit nominal number uniquely assigned to each distinct product |
| Description | Product nominal name |
| Quantity | The quantities of each product per transaction (Incorporates negative quantities for returns) |
| InvoiceDate | The day and time when a transaction was generated |
| Price | Product price per unit in sterling (£) |
| Customer ID | 5-digit nominal number uniquely assigned to each customer |
| Country | The name of the country where each customer resides |

---

## Architecture Diagram

```
                    Apache Airflow
                (Orchestration Layer)
                         |
          _______________|________________
         |                               |
         ↓                               ↓
    Ingestion Script              dbt Pipeline
    (load_raw.py)          Staging (Silver) → Marts (Gold)
         |                               |
         └_______________________________┘
                         |
                         ↓
            PostgreSQL OLAP Warehouse
         ┌──────────────┬──────────────┬─────────────┐
         |   Bronze     |    Silver    |    Gold     |
         | (row layer)  |  (staging)   |(dimensional)|
         └──────────────┴──────────────┴─────────────┘
                         |
                         ↓
                    Metabase
              (Visualization Layer)
```

---

## Domain

**E-Commerce / Retail Transactional Data Engineering**

---

## Project Description

This project implements an end-to-end batch data engineering pipeline designed to handle over 1 million retail transactions spanning from 2009 to 2011. Utilizing a structured Medallion Architecture (Bronze → Silver → Gold), the pipeline ingests raw transaction data, applies comprehensive data quality validation, performs business-driven transformations, and delivers analytical insights through a visual BI layer.

---

## Problem Statement

Online retail businesses generate massive volumes of transactional data daily, but extracting actionable intelligence remains difficult due to duplicate entries, null records, and unoptimized database structures. Processing millions of rows without data governance leads to severe pipeline bottlenecks, version dependency collisions, and sluggish, unreliable business visualization layers.

To resolve these bottlenecks, this project leverages a multi-layered Medallion Architecture orchestrated by Apache Airflow and dbt. The pipeline cleans raw operational inputs as they move from Bronze to Silver layers, ultimately materializing a fully tested dimensional Star Schema in the Gold layer of a PostgreSQL data warehouse to power interactive Metabase dashboards.

---

## Project Objectives

1. Build a containerized batch analytics environment utilizing Docker Compose to deploy Apache Airflow, dbt core, PostgreSQL, and Metabase concurrently within an isolated local network.
2. Automate raw file ingestion to load historical Excel transactions exactly as received into a baseline PostgreSQL layer (Bronze Layer) without applying transformations, using optimized psycopg2 cursor abstractions.
3. Establish an analytical transformation framework using dbt to transform unstructured inputs into standardized staging tables (Silver Layer) by executing deduplication window rules, explicit type casting, and text parsing.
4. Construct a high-performance Star Schema model (Gold Layer) by generating optimized dimension structures (`dim_customers`, `dim_products`, `dim_date`) coupled to a centralized metrics transactional ledger (`fact_sales`).
5. Enforce strict data validation protocols by embedding data testing mechanisms inside dbt to verify key unique identities and `not_null` constraints across data components.
6. Build a comprehensive business visualization layout by connecting Metabase to the Gold layer to present real-time enterprise key performance indicators, regional sales balances, and macro revenue trajectories.
---

## Technology Stack

- **Docker Compose**: Complete infrastructure containment and isolated service routing.
- **Apache Airflow**: Pipeline execution management and upstream task orchestration.
- **dbt (Data Build Tool)**: Modular SQL transformation modeling, quality testing, and metadata generation.
- **PostgreSQL**:  Specialized central data warehouse processing Bronze, Silver, and Gold structures.
- **Metabase**:  Analytical workspace engine generating dynamic relational charts and graphs.
- **Python**: Ingestion driver layer utilizing psycopg2 streaming mechanisms.

---

## Pipeline Architecture

The pipeline follows the **Medallion Architecture** pattern with three distinct layers:

### Layer 1: Bronze (Raw Layer)
- Stores unmodified source data
- Row-level ingestion from CSV/Excel files
- Preserves original data structure

### Layer 2: Silver (Staging Layer)
- Data quality enforcement
- Deduplication and null handling
- Business rule application
- Prepared for analytics

### Layer 3: Gold (Dimensional Model)
- Dimensional tables (Customers, Products, Dates)
- Fact tables (Transactions)
- Optimized for BI tools and analytics

---

## Planned Data Transformation Layers

1. **Bronze Layer (Raw Archive)**: Captures raw tabular transactions into the target `raw_online_retail table`. Schema fields reflect the data source exactly, maintaining formatting errors or invalid records for audit tracing.

2. **Silver Layer (Staging Platform)**: Compiled as modular SQL Views (`stg_online_retail`). Cleans data by casting data types (e.g., converting text to timestamps), remapping names, extracting cancellation indicators, and filtering out null identifier variables.

3. **Gold Layer (Dimensional Marts)** : Persisted as physical database tables. Materializes an optimized Star Schema:

   - `fact_sales`: Contains metrics such as `quantity`, `unit_price`, and  `line_total` along with foreign keys.
   - `dim_customers`: Captures customer-specific aggregations like total invoices, country data, and lifecycle ranges.
   - `dim_products`: Stores master records of stock details, text flags, and running pricing baselines.
   - `dim_date`: Deconstructs dates into attributes such as year, quarter, month, week, and weekend flags.

---

## Planned Business Insights

The analytical engine generates several high-value business insights:

- Evaluating cumulative sales across fiscal operational months to identify seasonal spikes, annual compound expansions, and historical demand shifts.

- Ranking stock codes against integrated revenue models to discover high-margin retail assets and inventory trends.

- Aggregating transactional sales totals by country boundaries to isolate critical regional concentrations outside the domestic UK marketplace.

- Evaluating customer segments by linking total interactions and lifecycle ranges to uncover baseline retention health.

---

## How to Run

Follow these operational instructions sequentially to initialize and run the entire data pipeline cluster locally.

### 1. Clone the Repository

```bash
git clone https://github.com/micell1/ALP_DE.git
cd ALP_DE
```

### 2. Environment Setup & Dependency Installation

⚠️ **IMPORTANT FOR WINDOWS USERS (CRLF to LF Line Endings):**  
Before initializing the containers, you must ensure that the shell initialization script `init-db.sh` uses LF line endings instead of Windows' default CRLF. If left as CRLF, Linux environments will fail to execute the database engine, throwing parsing errors.

**How to resolve inside VS Code:**
- Open `init-db.sh`
- Look at the bottom right corner of the status bar
- Click on CRLF and change it to LF
- Then save the file
- Keep `docker-compose.yml` configured as CRLF for correct Windows daemon communication

### 3. Initialize the Core Database and Orchestrator

Ensure your Docker Desktop application is fully opened and running in the background. Then execute the environment bootstrapper:

```bash
docker-compose up airflow-init
```

Wait until the console outputs the verification sequence: `User "admin" created with role "Admin"`.

### 4. Start All Pipeline Services

Launch the complete container cluster in detached mode:

```bash
docker-compose up -d
```

This command builds and deploys the following services within an isolated network loop:

- **Airflow Scheduler & Webserver**: Manages the pipeline workflow
- **PostgreSQL OLAP Warehouse**: Stores the operational data layers
- **Metabase BI Console**: Powers the presentation layer

### 5. Execute and Monitor the Airflow DAG

1. Open your web browser and navigate to the management interface: `http://localhost:8088`
2. Authenticate using the default workspace credentials:
   - **Username**: `admin`
   - **Password**: `admin`

3. Locate the `online_retail_pipeline` DAG and trigger it manually
4. Monitor task execution through the Airflow UI
5. Verify successful completion of all tasks, the task graphs will execute sequentially, tracking progress in real time across three stages:

```
ingest_to_bronze (Python Ingestion) ──▶ dbt_run (Silver/Gold Build) ──▶ dbt_test (Data Audit)

```

### 6. Access the Metabase Dashboard

1. Navigate to `http://localhost:3001`
2. Set up your Metabase workspace (first-time setup)
3. Connect to the PostgreSQL warehouse using:
   - **Database Type**: `postgres`
   - **Host**: `postgres-warehouse`
   - **Port**: `5432`
   - **Database**: `online_retail`
   - **Username**: `warehouse`
   - **Password**: `warehouse`

4. Browse and create dashboards from the Gold layer tables

---

## Metabase Dashboard


---

## Findings & Conclusion

The data pipeline successfully transformed raw transaction data into structured insights stored within the data warehouse. Key findings include:



---

## Known Limitations

- **Batch Ingestion Constraints**: The pipeline operates on fixed batch cycles using local file storage rather than continuously streaming live API inputs.

- **Host Resource Overhead**: Processing over 1 million records through an uncompressed local Excel parsing driver can cause short memory spikes on the host machine before the data lands in the Bronze database layer.

- **Single-Node Warehouse Environment**: The PostgreSQL OLAP cluster is configured as a single-node setup for development and testing, rather than a multi-node distributed database.

- **Local Visualization Syncing (Metabase Sandbox Constraints)**: Because Metabase dashboards and connection states are stored in local Docker database volumes rather than Git files, they do not automatically sync between contributors' branches. Each team member must manually recreate and configure their dashboard panels locally, creating collaborative hurdles for interface development.

- **Strict Package and Tool Version Coupling**: The orchestration and SQL translation engines are exceptionally sensitive to technical version alignment. Even minor discrepancies between python packages, PostgreSQL driver interfaces, SQLAlchemy, and Apache Airflow (strictly locked to version 2.10.2 in airflow.Dockerfile) will cause execution and deployment failures.

---

## Contributors

| Name | NIM |
|------|-----|
| Ruby Arthalia Golden | 0706022310035 |
| Amanda Renata Go | 0706022310010 |
| Catherine Eline Santoso | 0706022310009 |
| Deborah Michelle Kwandinata | 0706022310014 |
| Feylin Christelia | 0706022310012 |