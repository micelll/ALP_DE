with transactions as (
    select * from {{ ref('stg_online_retail') }}
),

dim_customers as (
    select customer_key, customer_id from {{ ref('dim_customers') }}
),

dim_products as (
    select product_key, stock_code from {{ ref('dim_products') }}
),

dim_date as (
    select date_key, date_day from {{ ref('dim_date') }}
)

select
    -- Kunci di-generate setelah datanya dipastikan unik per invoice & item
    md5(t.invoice_id || t.stock_code || t.invoice_date::text) as fact_key,
    
    c.customer_key,
    p.product_key,
    d.date_key,

    t.invoice_id,
    t.country,
    t.is_return,
    t.invoice_date,
    
    -- Lakukan agregasi untuk mengeliminasi duplikat item di invoice yang sama
    sum(t.quantity) as quantity,
    max(t.unit_price) as unit_price, -- ambil harga tertinggi atau rata-rata jika variatif
    sum(t.line_total) as line_total

from transactions t
left join dim_customers c on t.customer_id = c.customer_id
left join dim_products p  on t.stock_code  = p.stock_code
left join dim_date d      on t.invoice_date_day = d.date_day
group by 
    t.invoice_id, t.stock_code, t.invoice_date, 
    c.customer_key, p.product_key, d.date_key, 
    t.country, t.is_return