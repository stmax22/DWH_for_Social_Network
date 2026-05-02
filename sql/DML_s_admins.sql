/* Заполняем сателит-таблицу s_admins. */
INSERT INTO VT25110761DD38__DWH.s_admins (
	hk_admin_id,
	is_admin,
	admin_from,
	load_dt,
	load_src
)
SELECT
	la.hk_l_admin_id,
	TRUE AS is_admin,
	hg.registration_dt,
	NOW() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__DWH.l_admins AS la
LEFT JOIN VT25110761DD38__DWH.h_groups AS hg ON la.hk_group_id = hg.hk_group_id;