with customers_metrics as (
    select
        customer_id,
        -- Menggunakan max(country) untuk memastikan satu baris unik per customer_id
        max(country) as country,
        count(distinct invoice_id) as total_invoices,
        min(invoice_date) as first_purchase_date,
        max(invoice_date) as last_purchase_date
    from {{ ref('stg_online_retail') }}
    where customer_id is not null
    group by customer_id
)

select
    md5(customer_id) as customer_key,
    customer_id,
    country,
    total_invoices,
    first_purchase_date,
    last_purchase_date
from customers_metrics