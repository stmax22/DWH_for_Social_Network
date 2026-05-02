/* Заполняем хаб-таблицу h_users. */
INSERT INTO VT25110761DD38__DWH.h_users (
	hk_user_id,
	user_id,
	registration_dt,
	load_dt,
	load_src
)
SELECT
       HASH(id) AS hk_user_id,
       id AS user_id,
       registration_dt,
       NOW() AS load_dt,
       'S3' AS load_src
FROM VT25110761DD38__STAGING.users
WHERE HASH(id) NOT IN (
	SELECT
		hk_user_id
	FROM VT25110761DD38__DWH.h_users
);