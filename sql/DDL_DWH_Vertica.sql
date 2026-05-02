/* Создаем STG слой. */
/* Создаем таблицу users. */
DROP TABLE IF EXISTS VT25110761DD38__STAGING.users;

CREATE TABLE IF NOT EXISTS VT25110761DD38__STAGING.users (
	id INTEGER NOT NULL,
	chat_name VARCHAR(200),
	registration_dt TIMESTAMP,
	country VARCHAR(200),
	age INTEGER
)
ORDER BY id
SEGMENTED BY HASH(id) ALL NODES;

/* Создаем таблицу dialogs. */
DROP TABLE IF EXISTS VT25110761DD38__STAGING.dialogs;

CREATE TABLE IF NOT EXISTS VT25110761DD38__STAGING.dialogs (
	message_id INTEGER NOT NULL,
	message_ts TIMESTAMP,
	message_from INTEGER,
	message_to INTEGER,
	message VARCHAR(1000),
	message_group INTEGER
)
ORDER BY message_id
SEGMENTED BY HASH(message_id) ALL NODES
PARTITION BY message_ts::DATE
GROUP BY calendar_hierarchy_day(message_ts::DATE, 3, 2);

/* Создаем таблицу groups. */
DROP TABLE IF EXISTS VT25110761DD38__STAGING.groups;

CREATE TABLE IF NOT EXISTS VT25110761DD38__STAGING.groups (
	id INTEGER NOT NULL,
	admin_id INTEGER,
	group_name VARCHAR(100),
	registration_dt TIMESTAMP,
	is_private BOOLEAN
)
ORDER BY id, admin_id
SEGMENTED BY HASH(id) ALL NODES
PARTITION BY registration_dt::DATE
GROUP BY calendar_hierarchy_day(registration_dt::DATE, 3, 2);

/* Создаем таблицу group_log. */
DROP TABLE IF EXISTS VT25110761DD38__STAGING.group_log;

CREATE TABLE IF NOT EXISTS VT25110761DD38__STAGING.group_log (
	group_id INTEGER NOT NULL,
	user_id INTEGER,
	user_id_from INTEGER,
	event VARCHAR(100),
	datetime TIMESTAMP
)
ORDER BY group_id, user_id
SEGMENTED BY HASH(group_id) ALL NODES
PARTITION BY datetime::DATE
GROUP BY calendar_hierarchy_day(datetime::DATE, 3, 2);


/* Создаем DDS слой. */
/* Создаем хаб-таблицу h_users. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.h_users;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.h_users (
    hk_user_id BIGINT PRIMARY KEY,
    user_id INTEGER,
    registration_dt TIMESTAMP,
    load_dt TIMESTAMP,
    load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_user_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);
;

/* Создаем хаб-таблицу h_groups. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.h_groups;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.h_groups (
    hk_group_id BIGINT PRIMARY KEY,
    group_id INTEGER,
    registration_dt TIMESTAMP,
    load_dt TIMESTAMP,
    load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_group_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);
;

/* Создаем хаб-таблицу h_dialogs. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.h_dialogs;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.h_dialogs (
    hk_message_id BIGINT PRIMARY KEY,
    message_id INTEGER,
    message_ts TIMESTAMP,
    load_dt TIMESTAMP,
    load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_message_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);
;

/* Создаем линк-таблицу l_user_message. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.l_user_message;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.l_user_message (
	hk_l_user_message BIGINT PRIMARY KEY,
	hk_user_id BIGINT NOT NULL CONSTRAINT fk_l_user_message_user REFERENCES VT25110761DD38__DWH.h_users (hk_user_id),
	hk_message_id BIGINT NOT NULL CONSTRAINT fk_l_user_message_message REFERENCES VT25110761DD38__DWH.h_dialogs (hk_message_id),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_user_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем линк-таблицу l_admins. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.l_admins;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.l_admins (
	hk_l_admin_id BIGINT PRIMARY KEY,
	hk_user_id BIGINT NOT NULL CONSTRAINT fk_l_admins_user REFERENCES VT25110761DD38__DWH.h_users (hk_user_id),
	hk_group_id BIGINT NOT NULL CONSTRAINT fk_l_admins_group REFERENCES VT25110761DD38__DWH.h_groups (hk_group_id),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_l_admin_id all NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем линк-таблицу l_groups_dialogs. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.l_groups_dialogs;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.l_groups_dialogs (
	hk_l_groups_dialogs BIGINT PRIMARY KEY,
	hk_message_id BIGINT NOT NULL CONSTRAINT fk_l_groups_dialogs_dialog REFERENCES VT25110761DD38__DWH.h_dialogs (hk_message_id),
	hk_group_id BIGINT NOT NULL CONSTRAINT fk_l_groups_dialogs_group REFERENCES VT25110761DD38__DWH.h_groups (hk_group_id),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_l_groups_dialogs ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем линк-таблицу l_user_group_activity. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.l_user_group_activity;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.l_user_group_activity (
	hk_l_user_group_activity BIGINT PRIMARY KEY,
	hk_user_id BIGINT NOT NULL CONSTRAINT fk_l_user_group_activity_user REFERENCES VT25110761DD38__DWH.h_users (hk_user_id),
	hk_group_id BIGINT NOT NULL CONSTRAINT fk_l_user_group_activity_group REFERENCES VT25110761DD38__DWH.h_groups (hk_group_id),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt, hk_user_id, hk_group_id
SEGMENTED BY HASH(hk_user_id, hk_group_id) ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем сателит-таблицу s_admins. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.s_admins;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.s_admins (
	hk_admin_id BIGINT NOT NULL CONSTRAINT fk_s_admins_l_admins REFERENCES VT25110761DD38__DWH.l_admins (hk_l_admin_id),
	is_admin BOOLEAN,
	admin_from TIMESTAMP,
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_admin_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем сателит-таблицу s_group_name. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.s_group_name;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.s_group_name (
	hk_group_id BIGINT NOT NULL CONSTRAINT fk_s_group_name_h_groups REFERENCES VT25110761DD38__DWH.h_groups (hk_group_id),
	group_name VARCHAR(100),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_group_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем сателит-таблицу s_group_private_status. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.s_group_private_status;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.s_group_private_status (
	hk_group_id BIGINT NOT NULL CONSTRAINT fk_s_group_private_status_h_groups REFERENCES VT25110761DD38__DWH.h_groups (hk_group_id),
	is_private VARCHAR(100),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_group_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем сателит-таблицу s_dialog_info. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.s_dialog_info;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.s_dialog_info (
	hk_message_id BIGINT NOT NULL CONSTRAINT fk_s_dialog_info_h_dialogs REFERENCES VT25110761DD38__DWH.h_dialogs (hk_message_id),
	message_from INTEGER,
	message_to INTEGER,
	message VARCHAR(1000),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_message_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем сателит-таблицу s_user_chatinfo. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.s_user_chatinfo;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.s_user_chatinfo (
	hk_user_id BIGINT NOT NULL CONSTRAINT fk_s_user_chatinfo_h_users REFERENCES VT25110761DD38__DWH.h_users (hk_user_id),
	chat_name VARCHAR(200),
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_user_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем сателит-таблицу s_user_socdem. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.s_user_socdem;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.s_user_socdem (
	hk_user_id BIGINT NOT NULL CONSTRAINT fk_s_user_socdem_h_users REFERENCES VT25110761DD38__DWH.h_users (hk_user_id),
	country VARCHAR(100),
	age INTEGER,
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_user_id ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);

/* Создаем сателит-таблицу s_auth_history. */
DROP TABLE IF EXISTS VT25110761DD38__DWH.s_auth_history;

CREATE TABLE IF NOT EXISTS VT25110761DD38__DWH.s_auth_history (
	hk_l_user_group_activity BIGINT NOT NULL CONSTRAINT fk_s_auth_history_l_user_group_activity REFERENCES VT25110761DD38__DWH.l_user_group_activity (hk_l_user_group_activity),
	user_id_from INTEGER,
	event VARCHAR(100),
	event_dt TIMESTAMP,
	load_dt TIMESTAMP,
	load_src VARCHAR(20)
)
ORDER BY load_dt
SEGMENTED BY hk_l_user_group_activity ALL NODES
PARTITION BY load_dt::DATE
GROUP BY calendar_hierarchy_day(load_dt::DATE, 3, 2);