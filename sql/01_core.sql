
--ИСТКА СТРУКТУРЫ (Запускать при пересоздании модели)

DROP TABLE IF EXISTS fact_bookings;
DROP TABLE IF EXISTS dim_salesperson;
DROP TABLE IF EXISTS dim_channel;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_hotel;

-- 1. Справочник отелей
CREATE TABLE dim_hotel (
    hotel_id SERIAL PRIMARY KEY,
    hotel_name VARCHAR(255) UNIQUE NOT NULL,
    hotel_type VARCHAR(100) NOT NULL,
    reg VARCHAR(100),
    state VARCHAR(100)
);

-- 2. Справочник клиентов
CREATE TABLE dim_customer (
    customer_id SERIAL PRIMARY KEY,
    emel VARCHAR(255) UNIQUE NOT NULL,
    membership VARCHAR(50) NOT NULL
);

-- 3. Справочник каналов продаж
CREATE TABLE dim_channel (
    channel_id SERIAL PRIMARY KEY,
    dis_channel VARCHAR(100) UNIQUE NOT NULL
);

-- 4. Справочник менеджеров по продажам
CREATE TABLE dim_salesperson (
    salesperson_id SERIAL PRIMARY KEY,
    sales_person VARCHAR(255) UNIQUE NOT NULL
);

-- 5. Центральная таблица фактов бронирования
CREATE TABLE fact_bookings (
    booking_id SERIAL PRIMARY KEY,
    
    -- Ключи связи со справочниками
    hotel_id INT REFERENCES dim_hotel(hotel_id),
    customer_id INT REFERENCES dim_customer(customer_id),
    channel_id INT REFERENCES dim_channel(channel_id),
    salesperson_id INT REFERENCES dim_salesperson(salesperson_id),
    
    -- Даты
    arrival_date DATE NOT NULL,
    depature_date DATE NOT NULL,
    arrival_cohort VARCHAR(50), -- Текстовая когорта (например, '2026-Q1')
    
    -- Данные клиента на момент бронирования
    cus_name VARCHAR(255),
    phone_no VARCHAR(50),
    card_no VARCHAR(50),
    cus_seg VARCHAR(100) NOT NULL,
    
    -- Операционные характеристики брони
    payment_method VARCHAR(50),
    resv_status VARCHAR(50),
    meal VARCHAR(50),
    room_type VARCHAR(50),
    assgn_room VARCHAR(50),
    pos VARCHAR(100),
    dep VARCHAR(100),
    d_s VARCHAR(100),
    customer_review TEXT,
    
    -- Числовые показатели и метрики
    nights INT,
    adult INT,
    child INT,
    rep_guest INT,
    prev_cancel INT,
    customer_rating INT,
    
    -- Финансовые показатели
    price NUMERIC(10, 2),
    gross NUMERIC(10, 2),
    disc VARCHAR(50), -- Процент или тип скидки
    disc_amt NUMERIC(10, 2),
    sales NUMERIC(10, 2),
    package NUMERIC(10, 2),
    adr NUMERIC(10, 2),
    calculated_adr NUMERIC(10, 2),
    comm_pay NUMERIC(10, 2),
    comm_amt NUMERIC(10, 2)
);

-- Наполнение справочника отелей
INSERT INTO dim_hotel (hotel_name, hotel_type, reg, state)
SELECT hotel_name, MAX(types), MAX(reg), MAX(state)
FROM raw_booking_data 
WHERE hotel_name IS NOT NULL 
GROUP BY hotel_name;

-- Наполнение справочника клиентов
INSERT INTO dim_customer (emel, membership)
SELECT emel, MAX(COALESCE(membership, 'None'))
FROM raw_booking_data 
WHERE emel IS NOT NULL 
GROUP BY emel;

-- Наполнение справочника каналов продаж
INSERT INTO dim_channel (dis_channel)
SELECT DISTINCT dis_channel 
FROM raw_booking_data 
WHERE dis_channel IS NOT NULL;

-- Наполнение справочника менеджеров
INSERT INTO dim_salesperson (sales_person)
SELECT DISTINCT sales_person 
FROM raw_booking_data 
WHERE sales_person IS NOT NULL;

-- Наполнение таблицы фактов
INSERT INTO fact_bookings (
    hotel_id, customer_id, channel_id, salesperson_id, 
    arrival_date, depature_date, arrival_cohort,
    cus_name, phone_no, card_no, cus_seg,
    payment_method, resv_status, meal, room_type, assgn_room, 
    pos, dep, d_s, customer_review,
    nights, adult, child, rep_guest, prev_cancel, customer_rating,
    price, gross, disc, disc_amt, sales, package, adr, calculated_adr, comm_pay, comm_amt
)
SELECT 
    h.hotel_id,
    c.customer_id,
    ch.channel_id,
    s.salesperson_id,
    r.arrival_date::DATE,
    r.depature_date::DATE,
    r.arrival_cohort,
    r.cus_name,
    r.phone_no,
    r.card_no,
    r.cus_seg, 
    r.payment_method,
    r.resv_status,
    r.meal,
    r.room_type,
    r.assgn_room,
    r.pos,
    r.dep,
    r.d_s,
    r.customer_review,
    r.nights::INT,
    r.adult::INT,
    r.child::INT,
    r.rep_guest::INT,
    r.prev_cancel::INT,
    r.customer_rating::INT,
    r.price::NUMERIC(10,2),
    r.gross::NUMERIC(10,2),
    r.disc,
    r.disc_amt::NUMERIC(10,2),
    r.sales::NUMERIC(10,2),
    r.package::NUMERIC(10,2),
    r.adr::NUMERIC(10,2),
    r.calculated_adr::NUMERIC(10,2),
    r.comm_pay::NUMERIC(10,2),
    r.comm_amt::NUMERIC(10,2)
FROM raw_booking_data r
LEFT JOIN dim_hotel h ON r.hotel_name = h.hotel_name
LEFT JOIN dim_customer c ON r.emel = c.email -- связка по уникальному email/emel
LEFT JOIN dim_channel ch ON r.dis_channel = ch.dis_channel
LEFT JOIN dim_salesperson s ON r.sales_person = s.sales_person;



