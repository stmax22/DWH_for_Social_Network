from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator

from scripts.Script_S3 import (
    migration_data,
    table_names
)


with DAG(
    'Uploading_data_to_Vertica',
    start_date=datetime(2023, 10, 22),
    schedule_interval='0 0 * * *',
    catchup=False,
    tags=['S3', 'Vertica', 'staging']
) as dag:

    for name in table_names:
        uploading_data = PythonOperator(
                task_id=f'load_{name}',
                python_callable=migration_data,
                op_kwargs={
                    'file_name': f'{name}.csv',
                    'table_name': name
                    }
            )

    uploading_data
