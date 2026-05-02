/* Заполняем линк-таблицу l_admins. */
INSERT INTO VT25110761DD38__DWH.l_admins (
	hk_l_admin_id,
	hk_group_id,
	hk_user_id,
	load_dt,
	load_src
)
SELECT
	HASH(hg.hk_group_id, hu.hk_user_id),
	hg.hk_group_id,
	hu.hk_user_id,
	NOW() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__STAGING.groups AS g
LEFT JOIN VT25110761DD38__DWH.h_users AS hu ON g.admin_id = hu.user_id
LEFT JOIN VT25110761DD38__DWH.h_groups AS hg ON g.id = hg.group_id
WHERE HASH(hg.hk_group_id, hu.hk_user_id) NOT IN (
	SELECT
		hk_l_admin_id
	FROM VT25110761DD38__DWH.l_admins
);