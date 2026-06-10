with date_spine as (
    -- Генерируем массив дат от 2000 до 2030 года
    select dateadd(day, seq4(), '2000-01-01') as date_day
    from table(generator(rowcount => 12000))
)
select
    cast(date_day as date) as date_id,
    day(date_day) as day_of_month,
    month(date_day) as month_number,
    monthname(date_day) as month_name,
    year(date_day) as year_number,
    quarter(date_day) as quarter_number,
    dayofweek(date_day) as day_of_week
from date_spine
where date_day <= '2030-12-31'