FROM apache/airflow:2.10.2

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

RUN pip install --no-cache-dir \
    dbt-postgres==1.9.0 \
    pandas==2.2.0 \
    openpyxl==3.1.2 \
    psycopg2-binary==2.9.9