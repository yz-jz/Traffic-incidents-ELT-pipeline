
  
    

    create or replace table `central-catcher-448814-j1`.`ti_tst25319`.`agg_incidents_data__per_country_daily`
      
    partition by occurence_date
    cluster by country

    OPTIONS()
    as (
      -- Aggregate incidents per country (daily basis)


with incidents as (
select
			start_time,
			end_time,
			probability_of_occurence,
			length,
			delay,
			incident_cause,
			magnitude_of_delay,
			country
from `central-catcher-448814-j1`.`ti_tst25319`.`int_incidents_data__incidents`
 -- aggregate data with validate location only
where country is not null
), 
incidents_by_cause as (
	-- Group by date and incident cause for incident count 
select 
			country,
			incident_cause,
			extract(date from start_time) as occurence_date,
			count(1) as cause_count
from incidents
group by occurence_date, incident_cause, country
),
pivoted_by_cause as (
select 
		*
from incidents_by_cause--(select country, incident_cause, occurence_date, cause_count from incidents_by_cause)
pivot(sum(cause_count) for incident_cause in (
			'unknown',
			'accident',
			'fog',
			'dangerousconditions',
			'rain',
			'ice',
			'jam',
			'lane_closed',
			'road_closed',
			'road_works',
			'wind',
			'flooding',
			'broken_down_vehicle'
		)
	)
)
--otals_per_day as (
---- extract date part from datetime
---- aggregate over daily basis
--elect 
	--	country,
	--	count(1) as total_incidents,
--rom incidents
--roup by country, occurence_date
--rder by 3, 2 desc
--)
select * from pivoted_by_cause
    );
  