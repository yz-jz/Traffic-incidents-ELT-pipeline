with pivoted as (
select
			*
from `central-catcher-448814-j1`.`traffic_incidents_253`.`int_incidents_data__per_country_daily`
)
-- Unpivot for looker studio chart
select 
    country,
    occurence_date,
    cause,
    incident_count
from pivoted
unpivot (
    incident_count for cause in (
        unknown, 
        accident, 
        fog, 
        dangerousconditions, 
        rain, 
        ice, 
        jam, 
        lane_closed, 
        road_closed, 
        road_works, 
        wind, 
        flooding, 
        broken_down_vehicle
    )
)