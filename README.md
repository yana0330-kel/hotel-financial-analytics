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

# DWH Architecture (Core Layer) & Data Marts (DM Layer)

At this stage, the flat Staging table (`raw_booking_data`) was successfully normalized and transformed into a fully-fledged analytical Data Warehouse (DWH) powered by PostgreSQL. The architecture follows a classic **Star Schema** design.

---

## 1. Core Layer Architecture (`01_core.sql`)
To eliminate redundant text duplicates, the data was decomposed into a central fact table and 4 independent dimension tables (lookups):

* **`dim_hotel`** – Hotel reference table. It contains unique hotel names and types (*City Hotel* / *Resort Hotel*). The aggregation was handled directly within the SQL query, keeping the schema clean and avoiding unnecessary intermediary tables.
* **`dim_customer`** – A lookup of unique clients (**6,037 records**). To account for dynamic updates in guest loyalty statuses, the architecture uses a `GROUP BY email` combined with the `MAX()` function. This locks in the most up-to-date loyalty status from the guest's latest booking.
* **`dim_channel`** – Sales channels reference table.
* **`dim_salesperson`** – Sales managers reference table.
* **`fact_bookings`** – The central fact table. It consolidates numerical metrics, financial KPIs (including calculated ADR), and technical columns. Textual descriptions of hotels, customers, and channels were replaced with efficient integer Foreign Keys (`FOREIGN KEY`) with strict referential integrity (`REFERENCES`).

### Engineering Spotlight: Fixing the Data Encoding Issue
During the initial migration, a critical anomaly popped up: when grouping data in SQL, the customer segment column (`cus_seg`) only displayed a single value (*Individual*), while the rest vanished into "visual emptiness."

* **Root Cause:** Hidden carriage returns (`\r`, `\n`) and non-breaking spaces imported from Excel.
* **Solution:** Fix it at the root. The issue was automatically resolved in Pandas before pushing the data to the database using regular expressions: 
  ```python
  df_clean['cus_seg'] = df_clean['cus_seg'].str.replace(r'[^a-zA-Z]', '', regex=True)
  ```
  Thanks to this, all three clean segments successfully landed in the DB: *Corporate* (2,672), *Individual* (1,828), and *Family* (1,550).

---

## 2. Data Quality Assurance (`02_qa.sql`)
To verify the integrity of the Core layer, a complete data reconciliation was performed using automated SQL tests:

* **Volume Test:** Checked data completeness. Exactly **6,050 rows** were loaded into the fact table (**0% data loss**).
* **Referential Integrity Test:** Verified dimension joins. The test returned **0 orphaned records (NULLs)**, confirming seamless key mapping.
* **Financial Reconciliation:** The final revenue checksum (`SUM(sales)`) in PostgreSQL matched the Jupyter Notebook calculations down to the penny.

---

## 3. Data Marts Layer (`03_dm_marts.sql`)
To keep the BI tool (Metabase) snappy and prevent it from running heavy, on-the-fly `JOIN` queries across millions of rows, the DM layer was built using lightweight Views (`VIEW`). These views come pre-loaded with answers to 5 core business questions:

*  **`dm_question_1`** – Revenue and booking trends by hotel on a monthly breakdown (to uncover seasonality).
*  **`dm_question_2`** – Sales channel efficiency and unit economics. SQL metrics backed up our EDA insights, proving that the *Direct* channel is the most profitable (**6,195.23 in net profit** per booking in January) due to zero middleman commissions.
*  **`dm_question_3`** – Hotel operational benchmarks (Average ADR and length of stay in nights).
*  **`dm_question_4`** – Revenue analysis by customer segments paired with loyalty packages (*Corporate*, *Individual*, *Family*).
*  **`dm_question_5`** – Impact of discounts on the average and median guest satisfaction scores.

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
