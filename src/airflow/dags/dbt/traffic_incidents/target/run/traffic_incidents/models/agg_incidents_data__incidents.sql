
  
    

    create or replace table `central-catcher-448814-j1`.`traffic_incidents_253`.`agg_incidents_data__incidents`
      
    
    

    OPTIONS()
    as (
      -- Aggregations on monthly basis 

with incidents as (
    select 
        *
    from `central-catcher-448814-j1`.`traffic_incidents_253`.`int_incidents_data__incidents`
),
incidents_per_country as (
select 
    country,
    occurence_date,
    count(1) as total_incidents
from incidents
-- filter out invalid entries and keep current year data
where country is not null and occurence_year >= 2025
group by country, occurence_date
) select 
    occurence_date,
    sum(total_incidents) as total_incidents
from incidents_per_country
group by occurence_date
    );
  