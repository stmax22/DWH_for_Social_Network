/* Заполняем хаб-таблицу h_dialogs. */
INSERT INTO VT25110761DD38__DWH.h_dialogs (
	hk_message_id,
	message_id,
	message_ts,
	load_dt,
	load_src
)
SELECT
       HASH(message_id) AS hk_group_id,
       message_id,
       message_ts,
       NOW() AS load_dt,
       'S3' AS load_src
FROM VT25110761DD38__STAGING.dialogs
WHERE HASH(message_id) NOT IN (
	SELECT
		hk_message_id
	FROM VT25110761DD38__DWH.h_dialogs
);