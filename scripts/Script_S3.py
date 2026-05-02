import boto3
import logging
import pandas as pd
import vertica_python

from contextlib import contextmanager
from airflow.hooks.base import BaseHook
from airflow.models import Variable


# Задаем формат лог-сообщений.
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

table_names = ('dialogs', 'groups', 'group_log', 'users')


@contextmanager
def connection_vertica():
    """Метод автоматически открывает и закрывает соединение."""

    vertica_id = BaseHook.get_connection('conn_vertica')
    conn_info = {
        'host': vertica_id.host,
        'port': vertica_id.port,
        'user': vertica_id.login,
        'password': vertica_id.password,
        'database': vertica_id.schema,
        'autocommit': True
    }
    conn = vertica_python.connect(**conn_info)
    curs = conn.cursor()

    try:
        logging.info('Подключение к Vertica прошло успешно!')
        yield curs
    except Exception as e:
        conn.rollback()
        logging.error(f'Ошибка при миграции данных: {e}')
        raise
    finally:
        conn.close()
        curs.close()


def connection_s3():
    """Метод подключается к хранилищу S3."""

    try:
        aws_access_key_id = Variable.get('AWS_ACCESS_KEY_ID')
        aws_secret_access_key = Variable.get('AWS_SECRET_ACCESS_KEY')

        conn_id = 'endpoint_url'
        http_conn_id = BaseHook.get_connection(conn_id)
        api_endpoint = http_conn_id.host

        session = boto3.session.Session()
        s3_client = session.client(
            service_name='s3',
            endpoint_url=api_endpoint,
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
        )
        logging.info('Подключение к хранилищу S3 прошло успешно!')

    except Exception as e:
        logging.error(f'Ошибка при подключении к хранилищу S3: {e}')
        raise

    return s3_client


def copy_data(table_name, file_name):
    """Метод загружает данные в DWH."""

    local_path = f'/data/{file_name}'

    with connection_vertica() as (curs):
        script = f"""
            COPY VT25110761DD38__STAGING.{table_name}
            FROM LOCAL '{local_path}'
            DELIMITER ',';
        """
        curs.execute(script)

    logging.info('Данные успешно загружены в Vertica!')


def download_file(file_name):
    """Метод выгружает файлы из S3 и сохраняет локально."""

    try:
        bucket = Variable.get('bucket')
        local_path = f'/data/{file_name}'

        s3_client = connection_s3()
        s3_client.download_file(
            Bucket=bucket,
            Key=file_name,
            Filename=local_path
        )

        logging.info(f'Файл "{file_name}" успешно скачен!')

        if file_name == 'group_log.csv':

            logging.info(f'Начинаем обработку файла "{file_name}".')

            df = pd.read_csv(local_path)

            # Преобразуем колонку 'user_id_from' в тип 'Int64' с поддержкой пропусков.
            df['user_id_from'] = pd.array(df['user_id_from'], dtype='Int64')

            # Cохраняем обработанный файл.
            df.to_csv(local_path, index=False)

            logging.info(f'Файл "{file_name}" обработан!')

    except Exception as e:
        logging.error(f'Ошибка при выгрузке файла "{file_name}" из S3: {e}')
        raise


def migration_data(table_name, file_name):
    """Метод производит миграцию данных из источника в DWH."""

    download_file(file_name)
    copy_data(table_name, file_name)
