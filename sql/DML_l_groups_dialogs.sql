/* Заполняем линк-таблицу l_groups_dialogs. */
INSERT INTO VT25110761DD38__DWH.l_groups_dialogs (
	hk_l_groups_dialogs,
	hk_message_id,
	hk_group_id,
	load_dt,
	load_src
)
SELECT
	HASH(hg.hk_group_id, hd.hk_message_id),
	hd.hk_message_id,
	hg.hk_group_id,
	NOW() AS load_dt,
	'S3' AS load_src
FROM VT25110761DD38__STAGING.dialogs AS d
LEFT JOIN VT25110761DD38__DWH.h_dialogs AS hd ON d.message_id = hd.message_id
INNER JOIN VT25110761DD38__DWH.h_groups AS hg ON d.message_group = hg.group_id
WHERE HASH(hg.hk_group_id, hd.hk_message_id) NOT IN (
	SELECT
		hk_l_groups_dialogs
	FROM VT25110761DD38__DWH.l_groups_dialogs
);