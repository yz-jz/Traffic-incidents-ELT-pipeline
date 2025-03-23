
  
    

    create or replace table `central-catcher-448814-j1`.`ti_tst25319`.`int_incidents_data__analysis_table`
      
    partition by occurence_date
    cluster by city, country, magnitude_of_delay, incident_cause

    OPTIONS()
    as (
      

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
			probability_of_occurence,
			length,
			delay,
			incident_cause,
			magnitude_of_delay,
			city,
			country
from `central-catcher-448814-j1`.`ti_tst25319`.`int_incidents_data__incidents`
    );
  