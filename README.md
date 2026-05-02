## Описание проекта
Необходимо построить хранилище данных, которое:
- **Собирает данные as is** из S3-хранилища:
  - `users.csv` — пользователи социальной сети
  - `groups.csv` — группы пользователей
  - `dialogs.csv` — сообщения между пользователями
  - `group_log.csv` — лог активности пользователей в группах
- **Реализует гибкую модель данных** (Data Vault) для быстрого запуска без предварительного проектирования витрин
- **Обеспечивает масштабируемость** — легкое добавление новых источников и изменение структуры БД
- **Формирует аналитические CTE** для ответов на бизнес-вопросы

## Архитектура решения
Проект построен по методологии **Data Vault** с двумя слоями данных:
- **STG** — Staging-слой для хранения сырых данных
- **DDS** — Detail Data Store, основной слой хранилища

## Структура проекта
```
.
├── dags/
│   ├── DAG_Vertica.py                      # Загрузка сырых данных из S3 в Staging-слой
│   └── DAG_DDS.py                          # Заполнение DDS-слоя
├── scripts/
│   └── Script_S3.py                        # Скрипт для миграции данных из S3 в Vertica
├── sql/
│   ├── DDL_DWH_Vertica.sql                 # Создание таблиц (STG + DDS)
│   ├── DML_h_users.sql                     # Заполнение хаба «Пользователи»
│   ├── DML_h_groups.sql                    # Заполнение хаба «Группы»
│   ├── DML_h_dialogs.sql                   # Заполнение хаба «Диалоги»
│   ├── DML_l_admins.sql                    # Заполнение линка «Администраторы групп»
│   ├── DML_l_user_message.sql              # Заполнение линка «Пользователь — Сообщение»
│   ├── DML_l_groups_dialogs.sql            # Заполнение линка «Группа — Диалог»
│   ├── DML_l_user_group_activity.sql       # Заполнение линка «Пользователь — Группа (активность)»
│   ├── DML_s_admins.sql                    # Заполнение сателлита «Администраторы»
│   ├── DML_s_auth_history.sql              # Заполнение сателлита «История авторизации/активности»
│   ├── DML_s_group_name.sql                # Заполнение сателлита «Название группы»
│   ├── DML_s_group_private_status.sql      # Заполнение сателлита «Приватность группы»
│   ├── DML_s_dialog_info.sql               # Заполнение сателлита «Информация о сообщении»
│   ├── DML_s_user_chatinfo.sql             # Заполнение сателлита «Чат-информация пользователя»
│   ├── DML_s_user_socdem.sql               # Заполнение сателлита «Социально-демографические данные»
│   ├── Guery_1.sql                         # Аналитический запрос: возрастное распределение пользователей топ-10 групп
│   └── Guery_2.sql                         # Аналитический запрос: конверсия в первое сообщение для топ-10 групп
└── Diagram_DDS.png                         # ER-диаграмма DDS-слоя
```

## Источники данных
Данные поступают из S3-хранилища в виде CSV-файлов:
| Файл | Описание | Поля |
|------|----------|------|
| `users.csv` | Пользователи соцсети | `id`, `chat_name`, `registration_dt`, `country`, `age` |
| `groups.csv` | Группы пользователей | `id`, `admin_id`, `group_name`, `registration_dt`, `is_private` |
| `dialogs.csv` | Диалоги между пользователями | `message_id`, `message_ts`, `message_from`, `message_to`, `message`, `message_group` |
| `group_log.csv` | Лог работы групп | `group_id`, `user_id`, `user_id_from`, `event`, `datetime` |

## Слои данных

### STG-слой
Слой для хранения сырых данных из S3.
| Таблица | Ключевые особенности |
|---------|---------------------|
| `users` | Сегментация по HASH(id) |
| `groups` | Сегментация по HASH(id), партиционирование по дате регистрации |
| `dialogs` | Сегментация по HASH(message_id), партиционирование по дате сообщения |
| `group_log` | Сегментация по HASH(group_id), партиционирование по дате события |

### DDS-слой
Основной слой хранилища, спроектированный по методологии Data Vault.

#### Хабы (Hubs)
Неизменяемые таблицы с информацией по одной бизнес-сущности.
| Таблица | Бизнес-сущность | Поля |
|---------|----------------|------|
| `h_users` | Пользователи | `hk_user_id`, `user_id`, `registration_dt`, `load_dt`, `load_src` |
| `h_groups` | Группы | `hk_group_id`, `group_id`, `registration_dt`, `load_dt`, `load_src` |
| `h_dialogs` | Сообщения | `hk_message_id`, `message_id`, `message_ts`, `load_dt`, `load_src` |

#### Линки (Links)
Таблицы связей между хабами.
| Таблица | Связь | Поля |
|---------|-------|------|
| `l_admins` | Администратор — Группа | `hk_l_admin_id`, `hk_user_id`, `hk_group_id`, `load_dt`, `load_src` |
| `l_user_message` | Пользователь — Сообщение | `hk_l_user_message`, `hk_user_id`, `hk_message_id`, `load_dt`, `load_src` |
| `l_groups_dialogs` | Группа — Диалог | `hk_l_groups_dialogs`, `hk_message_id`, `hk_group_id`, `load_dt`, `load_src` |
| `l_user_group_activity` | Пользователь — Группа (активность) | `hk_l_user_group_activity`, `hk_user_id`, `hk_group_id`, `load_dt`, `load_src` |

#### Сателлиты (Satellites)
Таблицы изменяемых свойств бизнес-сущностей.
| Таблица | Родитель | Поля |
|---------|----------|------|
| `s_group_name` | `h_groups` | `hk_group_id`, `group_name`, `load_dt`, `load_src` |
| `s_group_private_status` | `h_groups` | `hk_group_id`, `is_private`, `load_dt`, `load_src` |
| `s_dialog_info` | `h_dialogs` | `hk_message_id`, `message_from`, `message_to`, `message`, `load_dt`, `load_src` |
| `s_user_chatinfo` | `h_users` | `hk_user_id`, `chat_name`, `load_dt`, `load_src` |
| `s_user_socdem` | `h_users` | `hk_user_id`, `country`, `age`, `load_dt`, `load_src` |
| `s_admins` | `l_admins` | `hk_admin_id`, `is_admin`, `admin_from`, `load_dt`, `load_src` |
| `s_auth_history` | `l_user_group_activity` | `hk_l_user_group_activity`, `user_id_from`, `event`, `event_dt`, `load_dt`, `load_src` |

### ER-диаграмма DDS-слоя
![](https://github.com/stmax22/DWH_for_Social_Network/blob/d1c3b4c47f1fecf8d63e24a3aa4cc29cffdfa13b/Diagram_DDS.png)

## Аналитические запросы

### Query 1 — Возрастное распределение пользователей топ-10 групп
**Бизнес-вопрос:** Как распределен возраст пользователей в 10 самых старых группах?

**CTE-структура:**
- `request_1` — 10 самых старых групп
- `request_2` — сообщения в этих группах
- `request_3` — пользователи, отправившие эти сообщения

**Результат:**

| Поле | Описание |
|------|----------|
| `age` | Возраст пользователя |
| `COUNT(DISTINCT hk_user_id)` | Количество уникальных пользователей данного возраста |

### Query 2 — Конверсия в первое сообщение
**Бизнес-вопрос:** Какие группы лучше всего вовлекают участников в общение?

**CTE-структура:**
- `user_group_messages` — количество уникальных пользователей, написавших хотя бы одно сообщение в группе
- `user_group_log` — количество пользователей, вступивших в группу

**Результат:**

| Поле | Описание |
|------|----------|
| `hk_group_id` | Хэш-ключ группы |
| `cnt_added_users` | Количество вступивших пользователей |
| `cnt_users_in_group_with_messages` | Количество пользователей, написавших сообщение |
| `group_conversion` | Доля активных пользователей |

## Особенности реализации

### Инкрементальная загрузка
- Все DML-скрипты используют `WHERE hash_key NOT IN (SELECT hash_key FROM target_table)` — загружаются только новые записи
- Хабы неизменяемы — дубли исключаются на уровне SQL

### Партиционирование и сегментация
- Все DDS-таблицы партиционированы по `load_dt::DATE` с иерархией `calendar_hierarchy_day`
- Хабы сегментированы по суррогатному ключу для равномерного распределения
- STG-таблицы сегментированы по бизнес-ключам для оптимизации JOIN
