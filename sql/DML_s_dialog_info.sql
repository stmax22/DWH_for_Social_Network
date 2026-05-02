/* Заполняем сателит-таблицу s_dialog_info. */
INSERT INTO VT25110761DD38__DWH.s_dialog_info (
	hk_message_id,
	message_from,
	message_to,
	message,
	load_dt,
	load_src
)
SELECT
	hd.hk_message_id,
	d.message_from,
	d.message_to,
	d.message,
	NOW() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__DWH.h_dialogs AS hd
LEFT JOIN VT25110761DD38__STAGING.dialogs AS d ON hd.message_id = d.message_id;