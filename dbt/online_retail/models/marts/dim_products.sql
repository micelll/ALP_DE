with products as (
    select distinct on (stock_code)
        stock_code,
        description,
        avg(unit_price) over (partition by stock_code) as avg_price
    from {{ ref('stg_online_retail') }}
    where stock_code is not null and description is not null
    order by stock_code, invoice_date desc
)

select
    md5(stock_code)  as product_key,
    stock_code,
    description,
    round(avg_price::numeric, 2) as avg_price
from products