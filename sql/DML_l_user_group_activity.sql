/* Заполняем линк-таблицу l_user_group_activity. */
INSERT INTO VT25110761DD38__DWH.l_user_group_activity (
	hk_l_user_group_activity,
	hk_group_id,
	hk_user_id,
	load_dt,
	load_src
)
SELECT DISTINCT
	HASH(hg.hk_group_id, hu.hk_user_id),
	hg.hk_group_id,
	hu.hk_user_id,
	now() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__STAGING.group_log AS gl
LEFT JOIN VT25110761DD38__DWH.h_users AS hu ON gl.user_id = hu.user_id
LEFT JOIN VT25110761DD38__DWH.h_groups AS hg ON gl.group_id = hg.group_id
WHERE HASH(hg.hk_group_id, hu.hk_user_id) NOT IN (
	SELECT
		hk_l_user_group_activity
	FROM VT25110761DD38__DWH.l_user_group_activity
);