-- with transactions as (
--     select * from {{ ref('stg_online_retail') }}
-- ),

{{ config(
    materialized='incremental',
    unique_key='fact_key',
    on_schema_change='fail'
) }}

with transactions as (
    select * from {{ ref('stg_online_retail') }}
    {%- if is_incremental() -%}
        -- Hanya ambil data baru yang tanggalnya lebih besar dari data maksimal yang sudah masuk data warehouse
        where invoice_date > (select max(invoice_date) from {{ this }})
    {%- endif -%}
),

dim_customers as (
    -- Memastikan hanya ada 1 customer_key per customer_id
    select customer_id, max(customer_key) as customer_key 
    from {{ ref('dim_customers') }}
    group by customer_id
),

dim_products as (
    -- Memastikan hanya ada 1 product_key per stock_code (Mencegah Fan-out)
    select stock_code, max(product_key) as product_key 
    from {{ ref('dim_products') }}
    group by stock_code
),

dim_date as (
    select date_key, date_day from {{ ref('dim_date') }}
)

select
    md5(t.invoice_id || t.stock_code || t.invoice_date::text) as fact_key,
    
    c.customer_key,
    p.product_key,
    d.date_key,

    t.invoice_id,
    t.country,
    t.is_return,
    t.invoice_date,
    
    sum(t.quantity) as quantity,
    max(t.unit_price) as unit_price,
    sum(t.line_total) as line_total

from transactions t
left join dim_customers c on t.customer_id = c.customer_id
left join dim_products p  on t.stock_code  = p.stock_code
left join dim_date d      on t.invoice_date_day = d.date_day
group by 
    t.invoice_id, t.stock_code, t.invoice_date, 
    c.customer_key, p.product_key, d.date_key, 
    t.country, t.is_return