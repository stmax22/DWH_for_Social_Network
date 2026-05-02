/* Создаем аналитический запрос. */
WITH
user_group_messages AS (
	SELECT
		lgd.hk_group_id,
		COUNT(DISTINCT sdi.message_from) AS cnt_users_in_group_with_messages
	FROM VT25110761DD38__DWH.l_user_group_activity AS luga
	LEFT JOIN VT25110761DD38__DWH.l_groups_dialogs AS lgd ON luga.hk_group_id = lgd.hk_group_id
	LEFT JOIN  VT25110761DD38__DWH.s_dialog_info AS sdi ON lgd.hk_message_id = sdi.hk_message_id
	GROUP BY lgd.hk_group_id
),
user_group_log AS (
	SELECT
		hg.hk_group_id,
		COUNT(DISTINCT hu.user_id) AS cnt_added_users
	FROM VT25110761DD38__DWH.h_groups AS hg
	LEFT JOIN VT25110761DD38__DWH.l_user_group_activity AS luga ON hg.hk_group_id = luga.hk_group_id 
	LEFT JOIN VT25110761DD38__DWH.h_users AS hu ON luga.hk_user_id = hu.hk_user_id
	LEFT JOIN VT25110761DD38__DWH.s_auth_history AS sah ON luga.hk_l_user_group_activity = sah.hk_l_user_group_activity 
	WHERE sah.event = 'add' AND hg.hk_group_id IN (
		SELECT
			hk_group_id
		FROM VT25110761DD38__DWH.h_groups
		ORDER BY registration_dt
		LIMIT 10
	)
	GROUP BY hg.hk_group_id
	
)

SELECT
	ugl.hk_group_id,
	ugl.cnt_added_users,
	ugm.cnt_users_in_group_with_messages,
	ugm.cnt_users_in_group_with_messages / ugl.cnt_added_users AS group_conversion
FROM user_group_log AS ugl
INNER JOIN user_group_messages AS ugm ON ugl.hk_group_id = ugm.hk_group_id
ORDER BY ugm.cnt_users_in_group_with_messages / ugl.cnt_added_users DESC;