with date_spine as (
    select generate_series(
        '2009-12-01'::date,
        '2011-12-31'::date,
        interval '1 day'
    )::date as date_day
)

select
    to_char(date_day, 'YYYYMMDD')::integer  as date_key,
    date_day,
    extract(year from date_day)::integer    as year,
    extract(quarter from date_day)::integer as quarter,
    extract(month from date_day)::integer   as month,
    to_char(date_day, 'Month')              as month_name,
    extract(week from date_day)::integer    as week_of_year,
    extract(dow from date_day)::integer     as day_of_week,
    to_char(date_day, 'Day')                as day_name,
    case when extract(dow from date_day) in (0,6) then true else false end as is_weekend
from date_spine