from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import sys

sys.path.insert(0, '/opt/airflow/ingestion')

default_args = {
    'owner': 'data-engineering',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='online_retail_pipeline',
    default_args=default_args,
    description='End-to-end pipeline: Bronze → Silver → Gold',
    schedule_interval='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['online-retail', 'dbt'],
) as dag:

    def run_ingestion():
        from load_raw import load_raw_data
        load_raw_data()

    task_ingest = PythonOperator(
        task_id='ingest_to_bronze',
        python_callable=run_ingestion,
    )

    task_dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command='cd /opt/airflow/dbt/online_retail && dbt run --profiles-dir .',
    )

    task_dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command='cd /opt/airflow/dbt/online_retail && dbt test --profiles-dir .',
    )

    task_ingest >> task_dbt_run >> task_dbt_test