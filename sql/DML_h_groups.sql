/* Заполняем хаб-таблицу h_groups. */
INSERT INTO VT25110761DD38__DWH.h_groups (
	hk_group_id,
	group_id,
	registration_dt,
	load_dt,
	load_src
)
SELECT
       HASH(id) AS hk_group_id,
       id AS group_id,
       registration_dt,
       NOW() AS load_dt,
       'S3' AS load_src
FROM VT25110761DD38__STAGING.groups
WHERE HASH(id) NOT IN (
	SELECT
		hk_group_id
	FROM VT25110761DD38__DWH.h_groups
);