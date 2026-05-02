from datetime import datetime

from airflow import DAG
from airflow.providers.vertica.operators.vertica import VerticaOperator
from airflow.utils.task_group import TaskGroup


# Данные для подключения к БД.
vertica_conn_id = 'conn_vertica'


with DAG(
    'DML_DWH_Vertica',
    start_date=datetime(2023, 10, 22),
    schedule_interval='0 1 * * *',
    catchup=False,
    tags=['Vertica', 'dds']
) as dag:

    with TaskGroup(group_id='hubs') as hubs_group:
        DML_h_users = VerticaOperator(
            task_id='DML_h_users',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_h_users.sql'
        )

        DML_h_groups = VerticaOperator(
            task_id='DML_h_groups',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_h_groups.sql'
        )

        DML_h_dialogs = VerticaOperator(
            task_id='DML_h_dialogs',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_h_dialogs.sql'
        )

    with TaskGroup(group_id='links') as links_group:
        DML_l_admins = VerticaOperator(
            task_id='DML_l_admins',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_l_admins.sql'
        )

        DML_l_user_message = VerticaOperator(
            task_id='DML_l_user_message',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_l_user_message.sql'
        )

        DML_l_groups_dialogs = VerticaOperator(
            task_id='DML_l_groups_dialogs',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_l_groups_dialogs.sql'
        )

        DML_l_user_group_activity = VerticaOperator(
            task_id='DML_l_user_group_activity',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_l_user_group_activity.sql'
        )

    with TaskGroup(group_id='satellites_on_hubs') as sat_hubs_group:
        DML_s_group_name = VerticaOperator(
            task_id='DML_s_group_name',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_s_group_name.sql'
        )

        DML_s_group_private_status = VerticaOperator(
            task_id='DML_s_group_private_status',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_s_group_private_status.sql'
        )

        DML_s_dialog_info = VerticaOperator(
            task_id='DML_s_dialog_info',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_s_dialog_info.sql'
        )

        DML_s_user_chatinfo = VerticaOperator(
            task_id='DML_s_user_chatinfo',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_s_user_chatinfo.sql'
        )

        DML_s_user_socdem = VerticaOperator(
            task_id='DML_s_user_socdem',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_s_user_socdem.sql'
        )

    with TaskGroup(group_id='satellites_on_links') as sat_links_group:
        DML_s_admins = VerticaOperator(
            task_id='DML_s_admins',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_s_admins.sql'
        )

        DML_s_auth_history = VerticaOperator(
            task_id='DML_s_auth_history',
            vertica_conn_id=vertica_conn_id,
            sql='sql/DML_s_auth_history.sql'
        )

    hubs_group >> links_group >> sat_hubs_group >> sat_links_group
