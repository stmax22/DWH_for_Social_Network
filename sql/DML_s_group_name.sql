/* Заполняем сателит-таблицу s_group_name. */
INSERT INTO VT25110761DD38__DWH.s_group_name (
	hk_group_id,
	group_name,
	load_dt,
	load_src
)
SELECT
	hg.hk_group_id,
	g.group_name,
	NOW() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__DWH.h_groups AS hg
LEFT JOIN VT25110761DD38__STAGING.groups AS g ON hg.group_id = g.id;