
  
    

    create or replace table `central-catcher-448814-j1`.`traffic_incidents_253`.`int_incidents_data__incidents`
      
    partition by datetime_trunc(start_time, day)
    cluster by incident_cause, magnitude_of_delay, country, city

    OPTIONS()
    as (
      -- Intermediary table 
-- Enrich incidents with zones data

-- Partitionning and clustering


with incidents as (
select 
		*
from `central-catcher-448814-j1`.`traffic_incidents_253`.`stg_incidents_data__incidents`
),
incidents_zones as (
select 
		*
from `central-catcher-448814-j1`.`traffic_incidents_253`.`fct_incidents_data__coordinates`
), 
incidents_table as (
select 
			i.id,
			i.start_time,
			i.end_time,
			i.last_report_time,
			i.length,
			i.delay,
			i.probability_of_occurence,
			i.incident_cause,
			i.magnitude_of_delay,
			i.number_of_reports,
			i.code,
			i.description,
			z.lon,
			z.lat,
			z.country_code,
			z.country,
			z.county,
			z.state_district,
			z.state,
			z.municipality,
			z.city,
			z.town,
			z.village,
			z.postcode

from incidents i
join incidents_zones z 
	on i.id = z.id
)

select
			start_time,
			end_time,
-- extract date part from datetime
			-- needed for daily aggregation
			extract(date from start_time) as occurence_date,
			-- year & month needed for monthly aggregation
			extract(year from start_time) as occurence_year,
			extract(month from start_time) as occurence_month,
			-- needed for incidents peak hour analysis
			extract(hour from start_time) as occurence_hour,
			length,
			delay,
			incident_cause,
			magnitude_of_delay,
			probability_of_occurence,
			city,
			country
from incidents_table
    );
  