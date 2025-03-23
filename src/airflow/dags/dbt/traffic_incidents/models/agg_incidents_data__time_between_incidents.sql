-- Aggregate average time difference between incidents 

with incidents as (
select
-- End time is skewed as it contains invalid dates
			country,
			city,
			start_time,
			occurence_year,
			occurence_month

from {{ ref('int_incidents_data__incidents') }}
 -- aggregate data with validate location only
where city is not null
), 
lead_incidents as (
	-- Get lead incident to compute time difference between the end of an incident and the start of the following one
	-- partitionned by country
select 
	country,
	city,
	start_time,
	occurence_year,
	occurence_month,
	lead(start_time) over(partition by country order by start_time) as following_incident
from incidents
),
time_difference as (
select 
		country,
		city,
		start_time,
		occurence_year,
		occurence_month,
		datetime_diff(following_incident, start_time, second) as time_between_incidents
from lead_incidents
)
select 
		country,
		occurence_year,
		occurence_month,
		date(occurence_year, occurence_month, 1) as day,
		avg(time_between_incidents) || ' s' as avg_time_between_incidents
from time_difference
where country is not null and occurence_year >= 2025
group by country, occurence_year, occurence_month
