with customers as (
    select distinct
        customer_id,
        country,
        count(distinct invoice_id) over (partition by customer_id) as total_invoices,
        min(invoice_date) over (partition by customer_id)          as first_purchase_date,
        max(invoice_date) over (partition by customer_id)          as last_purchase_date
    from {{ ref('stg_online_retail') }}
    where customer_id is not null
)

select
    md5(customer_id) as customer_key,
    customer_id,
    country,
    total_invoices,
    first_purchase_date,
    last_purchase_date
from customers