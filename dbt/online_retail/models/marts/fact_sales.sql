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
    md5(t.invoice_id || t.stock_code || t.invoice_date::text) as fact_key,
    
    -- foreign keys
    c.customer_key,
    p.product_key,
    d.date_key,

    t.invoice_id,
    t.country,
    t.is_return,
    
    t.quantity,
    t.unit_price,
    t.line_total,
    t.invoice_date

from transactions t
left join dim_customers c on t.customer_id = c.customer_id
left join dim_products p  on t.stock_code  = p.stock_code
left join dim_date d      on t.invoice_date_day = d.date_day