/* Заполняем линк-таблицу l_user_message. */
INSERT INTO VT25110761DD38__DWH.l_user_message (
	hk_l_user_message,
	hk_user_id,
	hk_message_id,
	load_dt,
	load_src
)
SELECT
	HASH(hd.hk_message_id, hu.hk_user_id),
	hu.hk_user_id,
	hd.hk_message_id,
	now() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__STAGING.dialogs AS d
LEFT JOIN VT25110761DD38__DWH.h_users AS hu ON d.message_from = hu.user_id
LEFT JOIN VT25110761DD38__DWH.h_dialogs AS hd ON d.message_id = hd.message_id
WHERE HASH(hd.hk_message_id, hu.hk_user_id) NOT IN (
	SELECT
		hk_l_user_message
	FROM VT25110761DD38__DWH.l_user_message
);