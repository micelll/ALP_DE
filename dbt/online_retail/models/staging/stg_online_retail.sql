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
        quantity > 0               
        and price > 0              
        and stockcode not in ('POST', 'D', 'M', 'BANK CHARGES', 'PADS', 'DOT')  -- hilangkan non-product
),

deduped as (
    select *
    from cleaned
    qualify row_number() over (
        partition by invoice_id, stock_code, quantity, unit_price
        order by invoice_date
    ) = 1
)

select * from deduped