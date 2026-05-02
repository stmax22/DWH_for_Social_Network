/* Создаем аналитический запрос. */
WITH
request_1 AS (
	SELECT hk_group_id
	FROM VT25110761DD38__DWH.h_groups
	ORDER BY registration_dt
	LIMIT 10
),
request_2 AS (
	SELECT hk_message_id
	FROM VT25110761DD38__DWH.l_groups_dialogs
	WHERE hk_group_id IN (SELECT * FROM request_1)
),
request_3 AS (
	SELECT hk_user_id
	FROM VT25110761DD38__DWH.l_user_message
	WHERE hk_message_id IN (SELECT * FROM request_2)
)

SELECT
	age,
	COUNT(DISTINCT hk_user_id)
FROM VT25110761DD38__DWH.s_user_socdem
WHERE hk_user_id IN (SELECT * FROM request_3)
GROUP BY age
ORDER BY age;