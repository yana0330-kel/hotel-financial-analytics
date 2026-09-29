<<<<<<< HEAD
# Hotel Chain Financial Performance & Unit Economics Analysis, 2024

Dataset from Kaggle: [Hotel Sales 2024](https://www.kaggle.com/datasets/tianrongsim/hotel-sales-2024).
6,050 hotel bookings for 2024, one row per booking, 36 columns: hotel
info, customer data, booking details, financials, reviews, sales rep.

*(Версия на русском языке: [README.ru.md](README.ru.md))*

## Dataset overview

**Hotel**
- Hotel Name → `hotel_name` (str), 3 values
- Region → `reg` (str), 3 values
- State → `state` (str)
- Hotel Type → `types` (str)

**Customer**
- Customer Name → `cus_name` (str)
- Phone Number → `phone_no` (str)
- Email → `emel` (str) — key used to check for repeat customers
- Customer Segment → `cus_seg` (str) — Individual / Corporate / Family
- Membership → `membership` (str) — Platinum / Gold / None
- Repeated Guest → `rep_guest` (int64) — **constant (always 0)**
- Previous Cancellations → `prev_cancel` (int64) — **constant (always 0)**

**Booking**
- Reservation Status → `resv_status` (str) — **constant (always `Check-Out`)**
- Check-in / Check-out Date → `arrival_date`, `depature_date` (datetime64)
- Adults / Children → `adult`, `child` (int64)
- Room Type → `room_type` (str), 4 values
- Nights → `nights` (int64), 1–16
- Meal Plan → `meal` (str)
- Assigned Room → `assgn_room` (str)
- Distribution Channel → `dis_channel` (str) — Direct / Agoda / Booking.com

**Financials**
- Price Per Room → `price` (int64), 4 fixed rate tiers
- Gross Sales → `gross` (int64)
- Discount Rate / Amount → `disc` (float64), `disc_amt` (float64)
- Package Add-ons → `package` (int64)
- Net Sales → `sales` (float64) — `= gross − disc_amt + package`, verified across the whole dataset
- Payment Method → `payment_method` (str)
- Card Number → `card_no` (str) — masked at the source, only the last 4 digits are visible
- Deposit Amount → `dep` (int64) — **constant (always 300)**
- Deposit Status → `d_s` (str) — Refunded / Forfeited
- ADR → `adr` (float64) — **invalid in 2.4% of rows**, use `sales/nights` instead
- Commission → `comm_pay` (int64), 4 fixed rates: 15/20/25/30%

**Reviews**
- Customer Rating → `customer_rating` (int64), 2–5
- Customer Review → `customer_review` (str)

**Sales**
- Sales Person → `sales_person` (str)
- Position → `pos` (str)

## Project goal

Help the Finance department (FP&A) find profit growth opportunities and
optimize distribution channels.

## How the questions were shaped

The first draft of the questions was written before the exploratory
analysis — based on column names and general hotel-business logic.
After EDA (`notebooks/eda_research.ipynb`), two questions had to be
revised: `rep_guest` and `prev_cancel` turned out to be constant across
the whole dataset (always 0), so there was nothing to compare. Below is
the final, verified set of questions; results are added stage by stage
below (EDA → SQL → Excel → dashboard).

### Key business questions:
1. **Volume, revenue, and time-based cohorts:** which hotel generates the highest net revenue (`sales`), and how is it distributed by month? 
*(Classic customer-level cohort analysis isn't possible — 0.2% repeat customers, not enough for LTV/retention. Instead I analyze time-based cohorts — volume and average booking value trends by arrival month.)*
2. **Distribution unit economics:** how much is lost to commissions (`comm_pay`) and discounts (`disc_amt`) by distribution channel (`dis_channel`)? Which channel is the most profitable per booking?
3. **Factor analysis:** what drives the change in hotel revenue — the average nightly rate (ADR) or the number of nights sold? 
*(ADR is invalid in 2.4% of bookings at the source — I use `sales/nights` instead of the `adr` field directly.)*
4. **Customer unit economics:** which customer segment (`cus_seg`) and membership tier (`membership`) generates the highest profit per booking?
5. **Quality and economics:** how does customer rating (`customer_rating`) relate to the discount given and to the sales channel?
*(The original question about cancellations (`prev_cancel`) was dropped — that column was also a constant, there are no cancellations in the data at all.)*

## EDA results

Full analysis in `notebooks/eda_research.ipynb` (data cleaning, 7 data
quality hypotheses, 5 business questions). Summary below.

**Data quality:**
- The source is read directly from `.xlsx`, with no intermediate CSV
  export — an earlier CSV-based draft introduced spurious artifacts
  (commas instead of decimal points in ratings, hidden whitespace in
  amounts) that don't exist when reading the source directly.
- Four columns are constants across the whole dataset: `rep_guest`,
  `prev_cancel`, `dep`, `resv_status`. They carry no analytical value as
  dimensions.
- Repeat customers by email — 0.2% (13 of 6,050) — customer-level
  LTV/retention/churn isn't computable; all unit economics is built at
  the booking, channel, and segment level instead.
- The revenue formula `sales = gross − disc_amt + package` is confirmed
  across the entire dataset (0 mismatches).
- `ADR` is invalid in 2.4% of bookings (=0) — the money is real there
  (`sales`, `nights` check out), so I recompute it as `sales/nights`.
- `d_s` and `room_type` had stray whitespace (`'Forfeited '`,
  `'Royal Suite '`) — normalized.
- The only missing values are in `membership` (NaN = not a loyalty
  program member) — made into an explicit `'None'` category.

**By business question:**
1. March runs 28–37% above normal in sync across all three hotels
   (demand surge); April and October are two distinct dips (−17…−27%
   and −8…−17%). Lexis Suites' July is the exception: bookings grew
   just 4.4% versus March, while revenue grew 25.5% (average booking
   value +20.3%) — a value increase, not a volume increase.
2. Direct is the most profitable channel: 5,523 net profit per booking
   versus 5,411 (Agoda) and 5,357 (Booking.com) — 3–4% more efficient
   than intermediaries thanks to zero commission.
3. ADR (902–911) and average length of stay (8.51–8.56 nights) are
   practically identical across all three hotels. The revenue swings
   from question 1 are explained by shared market cycles, not by any
   one hotel's specifics.
4. Family + Gold is the leader in revenue per booking (10,374), Family
   + Platinum is second (9,896). Individual with no membership is the
   lowest (4,687). Gold consistently outperforms Platinum across every
   segment — a likely sign that the Platinum tier over-discounts.
5. Sales channel doesn't affect rating (median 4.0 across all three).
   Discount does, but not proportionally to its size: guests with no
   discount are noticeably happier (median 5.0, though that's only 83
   of 6,050 bookings), while 5% and 10% discounts produce nearly
   identical results (median 4.0 for both).

## SQL results

*(In progress — porting the EDA aggregations into the Core/DM layer, `sql/`.)*

## Excel results

*(In progress — unit economics and financial model, `excel/`.)*

## Final conclusions and dashboard

*(In progress — Metabase dashboard and consolidated business
recommendations, once every stage is done.)*

## Repository structure

```
data/
  hotel_bookings_raw.xlsx        source file
notebooks/
  eda_research.ipynb              exploratory analysis and 5 business questions — done
sql/                               Core/DM layer - done
excel/                             unit economics and financial model (in progress)
docker-compose.yml                 Postgres + Metabase for the dashboard (in progress)
README.md / README.ru.md
```

## Tools

Python (pandas, seaborn, matplotlib), SQL (PostgreSQL syntax: CTEs,
window functions), Excel (formula-driven model), BI (Metabase in Docker).
=======
### Анализ финансовой эффективности и юнит-экономики сети отелей за 2024 год
Датасет взят с Kaggle.com 'https://www.kaggle.com/datasets/tianrongsim/hotel-sales-2024'.
Этот набор данных содержит информацию о 6050 бронированиях отелей за 2024 год. 
Каждое наблюдение представляет собой отдельное бронирование отеля. Набор данных содержит 6050 транзакций с отелями и 36 столбцов, охватывающих различные аспекты бронирования отелей, данные о клиентах, показатели продаж и финансовые показатели.
### Основные характеристики датасета 

**Отель**
- Hotel Name - `hotel_name` (str), 3 значения
- Region - `reg` (str), 3 значения
- State - `state` (str)
- Hotel Type - `types` (str)

**Клиент**
- Customer Name - `cus_name` (str)
- Phone Number - `phone_no` (str)
- Email - `emel` (str) — ключ для проверки повторных клиентов
- Customer Segment - `cus_seg` (str) — Individual / Corporate / Family
- Membership - `membership` (str) — Platinum / Gold / None
- Repeated Guest - `rep_guest` (int64) — **константа (всегда 0)**
- Previous Cancellations - `prev_cancel` (int64) — **константа (всегда 0)**

**Бронирование**
- Reservation Status - `resv_status` (str) — **константа (всегда `Check-Out`)**
- Check-in / Check-out Date - `arrival_date`, `depature_date` (datetime64)
- Adults / Children - `adult`, `child` (int64)
- Room Type - `room_type` (str), 4 значения
- Nights - `nights` (int64), 1–16
- Meal Plan - `meal` (str)
- Assigned Room - `assgn_room` (str)
- Distribution Channel - `dis_channel` (str) — Direct / Agoda / Booking.com

**Финансы**
- Price Per Room - `price` (int64), 4 фиксированных тарифа
- Gross Sales - `gross` (int64)
- Discount Rate / Amount - `disc` (float64), `disc_amt` (float64)
- Package Add-ons - `package` (int64)
- Net Sales - `sales` (float64) — `= gross − disc_amt + package`, проверено на всём датасете
- Payment Method - `payment_method` (str)
- Card Number - `card_no` (str) — замаскировано в источнике, видны только последние 4 цифры
- Deposit Amount - `dep` (int64) — **константа (всегда 300)**
- Deposit Status - `d_s` (str) — Refunded / Forfeited
- ADR - `adr` (float64) — **некорректен в 2.4% строк**, использовать `sales/nights` вместо него
- Commission - `comm_pay` (int64), 4 фиксированные ставки: 15/20/25/30%

**Отзывы**
- Customer Rating - `customer_rating` (int64), 2–5
- Customer Review - `customer_review` (str)

**Продажи**
- Sales Person - `sales_person` (str)
- Position - `pos` (str)
### Цель проекта: 
Помочь финансовому департаменту FP&A найти точки роста прибыли и оптимизировать каналы продаж
### Как формировались вопросы
Первая версия вопросов была написана до разведочного анализа — на основе названий колонок и общей логики отельного бизнеса. После EDA (`notebooks/eda_research.ipynb`) два вопроса пришлось скорректировать:
данные не поддерживали исходную постановку — `rep_guest` и `prev_cancel` оказались константами на весь датасет (все значения равны 0), сравнивать было не с чем. Ниже — уже финальная, проверенная версия вопросов.
### Ключевые бизнес-вопросы для исследования:
1. **Объёмы, выручка и временные когорты:** какой отель генерирует наибольшую чистую выручку (`sales`) и как она распределена по месяцам? 
*(Классический когортный анализ по клиентам невозможен — 0.2% повторных клиентов, недостаточно для LTV/retention.Вместо этого анализирую временные когорты — динамику объёма и среднего чека по месяцу заезда.)
**Находка: мартовский пик и апрельский/октябрьский спад синхронны у всех трёх отелей и объясняются объёмом спроса — но июльский рекорд Lexis Suites (2.1 млн) исключение: брони выросли на 4.4% к марту, а выручка на 25.5%, то есть вырос средний чек, а не объём.**
2. **Юнит-экономика дистрибуции:** сколько теряем на комиссиях (`comm_pay`) и скидках (`disc_amt`) в разрезе каналов продаж (`dis_channel`)? Какой канал самый маржинальный на одно бронирование?
3. **Факторный анализ:** из-за чего меняется выручка отелей — из-за изменения средней стоимости номера за ночь (ADR) или из-за количества  проданных ночей? 
*(ADR в 2.4% броней некорректен в источнике — при расчёте использую `sales/nights` вместо поля `adr` напрямую.)*
4. **Юнит-экономика по клиентам:** какой сегмент (`cus_seg`) и уровень членства (`membership`) приносит наибольшую прибыль с одной брони?
5. **Качество и экономика:** как оценка клиента (`customer_rating`) связана с размером предоставленной скидки и с каналом продаж?
*(Первоначальный вопрос про отмены (`prev_cancel`) снят — колонка тоже оказалась константой, отмен в данных нет вообще.)*

### Результаты EDA-research:

Полный ход анализа — в notebooks/eda_research.ipynb (очистка данных, 7 гипотез о качестве, 5 бизнес-вопросов). Здесь — краткие находки.

Качество данных: Источник читается напрямую из .xlsx, без промежуточного экспорта в CSV — черновик через CSV давал ложные артефакты (запятая вместо точки в оценках, скрытые пробелы в суммах), которых при прямом чтении нет.
Четыре колонки — константы на весь датасет: rep_guest, prev_cancel, dep, resv_status. Не несут аналитической ценности как измерения.
Повторных клиентов по email — 0.2% (13 из 6050) — customer-level LTV/retention/churn не считается; вся юнит-экономика строится на уровне бронирования, канала и сегмента.
Формула выручки sales = gross − disc_amt + package подтверждена на всём датасете (0 несовпадений).
ADR некорректен в 2.4% броней (=0) — деньги там настоящие (sales, nights в порядке), пересчитываю как sales/nights- колонка названа `calculated_adr`.
В d_s и room_type встречались лишние пробелы ('Forfeited ', 'Royal Suite ') — нормализовано.
Пропуски есть только в membership (NaN = не участник программы лояльности) — сделаны явной категорией 'None'.

По бизнес-вопросам:

- Март на 28–37% выше нормы у всех трёх отелей (рост спроса), апрель и октябрь — два разных по силе спада (−17%:−27% и −8%:−17%). Июль у Lexis Suites — исключение: брони выросли всего на 4.4% к марту, а выручка — на 25.5% (средний чек +20.3%) — рост не объёма, а ценности брони.
- Direct — самый маржинальный канал: 5 523 чистой прибыли с брони против 5 411 (Agoda) и 5 357 (Booking.com) — на 3–4% эффективнее посредников за счёт отсутствия комиссии.
- ADR (902–911) и средняя длительность проживания (8.51–8.56 ночей) практически идентичны у всех трёх отелей. Колебания выручки (вопрос 1) объясняются общими рыночными циклами, а не спецификой конкретного отеля.
- Family + Gold — лидер по выручке на бронь (10 374), Family + Platinum — второе место (9 896). Individual без членства — минимум (4 687). Gold стабильно обгоняет Platinum во всех сегментах — вероятный признак избыточного дисконтирования в пакете Platinum.
- Канал продаж не влияет на рейтинг (медиана 4.0 у всех трёх). Скидка влияет не пропорционально размеру: гости без скидки заметно довольнее (медиана 5.0, но это лишь 83 брони из 6050), а 5% и 10% скидка дают почти одинаковый результат (медиана 4.0 у обеих).

### Результаты SQL

## Проектирование DWH (Core-слой) и создание витрин данных (DM-слой)

На этом этапе плоская Staging-таблица `raw_booking_data` была успешно нормализована и переведена в полноценное аналитическое хранилище данных (DWH) на базе **PostgreSQL**. Структура спроектирована по классической схеме «Звезда».

### 1. Архитектура Core-слоя (01_core.sql)
Вместо хранения избыточных текстовых дубликатов, данные были декомпозированы на центральную **таблицу фактов** и **4 независимых справочника измерений**:

*   `dim_hotel` — справочник отелей. Содержит уникальные названия и тип отеля (`City Hotel` / `Resort Hotel`). Агрегация проведена на уровне SQL-запроса, что исключило избыточные таблицы.
*   `dim_customer` — справочник уникальных клиентов (6 037 записей). При проектировании учтена динамика изменения статуса лояльности гостя: с помощью группировки `GROUP BY emel` и функции `MAX()` зафиксирован самый актуальный статус лояльности на момент последнего бронирования.
*   `dim_channel` — справочник уникальных каналов продаж.
*   `dim_salesperson` — справочник менеджеров по продажам.
*   `fact_bookings` — центральная таблица фактов. Аккумулирует числовые метрики, финансовые показатели (включая расчетный ADR) и технические столбцы. Текстовые описания отелей, клиентов и каналов заменены на эффективные целочисленные внешние ключи (`FOREIGN KEY`) со строгой ссылочной целостностью (`REFERENCES`).

#### 💡 Решение инженерной проблемы с кодировкой данных
В ходе первой миграции была обнаружена критическая аномалия: колонка сегментов `cus_seg` при группировке в SQL отображала только одно значение (`Individual`), скрывая остальные в «визуальную пустоту». 
* **Причина:** Наличие невидимых символов переноса строки (`\r`, `\n`) и неразрывных пробелов, пришедших из Excel.
* **Решение:** Проблема была устранена автоматически на корневом уровне в Pandas перед отправкой в базу с помощью регулярных выражений: `df_clean['cus_seg'].str.replace(r'[^a-zA-Z]', '', regex=True)`. После этого в базу успешно пролились все три чистых сегмента: **Corporate (2 672)**, **Individual ( 1828)** и **Family (1 550)**.

### 2. Проверка качества данных (02_qa.sql)
Для верификации Core-слоя была проведена полная реконсиляция данных с помощью автоматических SQL-тестов:
1.  **Тест объема:** Проверена полнота данных — в таблицу фактов перенесено ровно **6 050 строк** (0% потерь).
2.  **Тест ссылочной целостности:** Проверен статус соединений справочников. Тест вернул `0` пропущенных связей (`NULL`), подтвердив идеальную склейку ключей.
3.  **Финансовая сверка:** Итоговая контрольная сумма выручки (`SUM(sales)`) в PostgreSQL сошлась копейка в копейку с расчетами в Jupyter Notebook.

### 3. Слой витрин данных (03_dm_marts.sql)
Чтобы BI-инструмент (Metabase) работал быстро и не выполнял тяжелые JOIN-запросы к миллионам строк «на лету», в DM-слое были созданы легковесные представления (**VIEW**). Они содержат предосчитанные ответы на 5 главных бизнес-вопросов:

*   `dm_question_1` — Динамика выручки и бронирований по отелям в разрезе месяцев (выявление сезонности).
*   `dm_question_2` — Эффективность и юнит-экономика каналов продаж. *SQL-метрики подтвердили инсайт из EDA: канал **Direct** является самым маржинальным (6 195.23 чистой прибыли с одной брони за январь) из-за отсутствия комиссий посредникам.*
*   `dm_question_3` — Сравнение операционных показателей отелей (средний ADR и длительность проживания в ночах).
*   `dm_question_4` — Анализ доходности клиентских сегментов в связке с пакетами лояльности (`Corporate`, `Individual`, `Family`).
*   `dm_question_5` — Влияние факта наличия скидки на среднюю и медианную оценку удовлетворенности гостей.

### Результаты Excel

(В работе — юнит-экономика и финансовая модель, excel/.)

### Итоговые выводы и дашборд

(В работе — дашборд в Metabase и сводные рекомендации для бизнеса по итогам всех этапов.)

### Структура репозитория
data/
  hotel_bookings_raw.xlsx        исходный файл
notebooks/
  eda_research.ipynb              разведочный анализ и 5 бизнес-вопросов
sql/                               Core/DM-слой
excel/                             юнит-экономика и финансовая модель
docker-compose.yml                 Postgres + Metabase 
README.md

### Инструменты

Python (pandas, seaborn, matplotlib), SQL (PostgreSQL-синтаксис: CTE, оконные функции), Excel (формульная модель), BI (Metabase в Docker).
>>>>>>> origin/master
