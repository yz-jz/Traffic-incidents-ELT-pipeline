-- Aggregate incidents per country (daily basis)
-- Pivoting over incident causes


with incidents as (
select
		*
from `central-catcher-448814-j1`.`traffic_incidents_253`.`int_incidents_data__incidents`
 -- aggregate data with validate location only
where country is not null
), 
incidents_by_cause as (
	-- Group by date and incident cause for incident count 
select 
			country,
			incident_cause,
			occurence_date,
			count(1) as cause_count
from incidents
group by occurence_date, incident_cause, country
),
pivoted_by_cause as (
select 
		*
from incidents_by_cause
-- Pivot on incident_cause column widening the table for furthur analysis
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
),
total_per_day as (
---- aggregate over daily basis
select 
		country,
	  occurence_date,
		count(1) as total_incidents
from incidents
group by country, occurence_date
)
select 
			t.total_incidents,
			p.*
from total_per_day t
join pivoted_by_cause p
	on t.occurence_date = p.occurence_date and t.country = p.country