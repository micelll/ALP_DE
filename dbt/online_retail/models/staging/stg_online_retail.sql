with source as (
    select * from {{ source('bronze', 'raw_online_retail') }}
),

cleaned as (
    select
        invoice::varchar                                as invoice_id,
        stockcode::varchar                              as stock_code,
        trim(description)::varchar                      as description,
        quantity::integer                               as quantity,
        invoicedate::timestamp                          as invoice_date,
        price::numeric(10,2)                            as unit_price,
        customer_id::varchar                            as customer_id,
        trim(country)::varchar                          as country,
        
        (quantity * price)::numeric(10,2)               as line_total,
        date(invoicedate)                               as invoice_date_day,
        
        case when invoice like 'C%' then true else false end as is_return

    from source
    where
        -- Catatan Bisnis: Jangan filter 'quantity > 0' di sini jika ingin mempertahankan data retur (C%).
        -- Di dataset Online Retail II, barang yang diretur ditandai dengan invoice diawali huruf 'C' DAN quantity bernilai negatif.
        (quantity > 0 or invoice like 'C%')
        and price > 0               
        and stockcode not in ('POST', 'D', 'M', 'BANK CHARGES', 'PADS', 'DOT')  -- hilangkan non-product
),

deduped as (
    select 
        *,
        -- Kita buat row_number di dalam CTE ini menggantikan QUALIFY
        row_number() over (
            partition by invoice_id, stock_code, quantity, unit_price
            order by invoice_date
        ) as rn
    from cleaned
)

-- Di seleksi akhir, baru kita saring yang bernilai 1 dan drop kolom rn-nya
select 
    invoice_id,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    line_total,
    invoice_date_day,
    is_return
from deduped
where rn = 1