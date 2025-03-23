
  
    

    create or replace table `central-catcher-448814-j1`.`traffic_incidents_253`.`stg_incidents_data__incidents`
      
    
    

    OPTIONS()
    as (
      -- Cleaned_incidents dataset
-- incidents CTE with nested events column
with nested as (
select 
		id,
		-- Parse string data converting it to datetime
		parse_datetime("%FT%H:%M:%SZ",startTime) as start_time,
		parse_datetime("%FT%H:%M:%SZ",endTime) as end_time,
		parse_datetime("%FT%H:%M:%SZ",lastReportTime) as last_report_time,
		length,
		delay,
		probabilityOfOccurrence as probability_of_occurence,
		iconCategory as icon_category,
		-- Label incident_cause based on icon category 
		case 
			when iconCategory = 0 then 'unknown'
			when iconCategory = 1 then 'accident'
			when iconCategory = 2 then 'fog'
			when iconCategory = 3 then 'dangerousconditions'
			when iconCategory = 4 then 'rain'
			when iconCategory = 5 then 'ice'
			when iconCategory = 6 then 'jam'
			when iconCategory = 7 then 'lane_closed'
			when iconCategory = 8 then 'road_closed'
			when iconCategory = 9 then 'road_works'
			when iconCategory = 10 then 'wind'
			when iconCategory = 11 then 'flooding'
			when iconCategory = 12 then 'broken_down_vehicle'
		end as incident_cause,
		magnitudeOfDelay as delay_category,
		-- Label incident_delay based on delay category 
		case
			when magnitudeOfDelay = 0 then 'unknown'
			when magnitudeOfDelay = 1 then 'minor'
			when magnitudeOfDelay = 2 then 'moderate'
			when magnitudeOfDelay = 3 then 'major'
			when magnitudeOfDelay = 4 then 'undefined'
		end as magnitude_of_delay,
		numberOfReports as number_of_reports,
		events
from `central-catcher-448814-j1`.`traffic_incidents_253`.`incidents_data`

),
-- unnested events CTE
unnested as (

select
-- add id to join on correct record
		nested.id as id,
    element.code as code,
    element.description as description,
	-- Using row_number for deduplication as each array element would output a record
		row_number() over( partition by id  ) as num_row
from nested,
-- unnest array of structs
    unnest(nested.events.list) as list,
-- unnest eleemnt of type struct treating it as an array
    unnest([list.element]) as element
),
deduped_unnested as (
	-- Deduplicate unnested CTE by filtering records where num row is 1
	select * 
	from unnested
	where num_row = 1
)
-- select stg columns
select 
		nested.id,
		nested.start_time,
		nested.end_time,
		nested.last_report_time,
		nested.length,
		nested.delay,
		nested.probability_of_occurence,
		nested.icon_category,
		nested.incident_cause,
		nested.delay_category,
		nested.magnitude_of_delay,
		nested.number_of_reports,
		deduped.code,
		deduped.description

from nested 
-- Join both CTEs resulting in unnested output
left join deduped_unnested deduped
	on nested.id = deduped.id
    );
  