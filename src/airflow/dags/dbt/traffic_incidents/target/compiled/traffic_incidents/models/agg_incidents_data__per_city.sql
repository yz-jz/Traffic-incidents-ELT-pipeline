-- Aggregate AVG, MAX, MIN per city

with totals_per_day as (
select
			*
from `central-catcher-448814-j1`.`traffic_incidents_253`.`int_incidents_data__per_city_daily`

), aggregates_per_city as (
select 
			city,
			sum(total_incidents) as total_incidents,
			round(avg(total_incidents),2) as avg_incidents_per_day,
			max(total_incidents) as max_incidents_per_day,
			min(total_incidents) as min_incidents_per_day,
			sum(unknown) as unknown,
			sum(accident) as accident,
			sum(fog) as fog,
			sum(dangerousconditions) as dangerousconditions,
			sum(rain) as rain,
			sum(ice) as ice,
			sum(jam) as jam,
			sum(lane_closed) as lane_closed,
			sum(road_closed) as road_closed,
			sum(road_works) as road_works,
			sum(wind) as wind,
			sum(flooding) as flooding,
			sum(broken_down_vehicle) as broken_down_vehicle

from totals_per_day
group by city
)
select * from aggregates_per_city