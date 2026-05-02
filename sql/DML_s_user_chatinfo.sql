/* Заполняем сателит-таблицу s_user_chatinfo. */
INSERT INTO VT25110761DD38__DWH.s_user_chatinfo (
	hk_user_id,
	chat_name,
	load_dt,
	load_src
)
SELECT
	hu.hk_user_id,
	u.chat_name,
	NOW() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__DWH.h_users AS hu
LEFT JOIN VT25110761DD38__STAGING.users AS u ON hu.user_id  = u.id;