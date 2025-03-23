--  identifies the peak hours for traffic incidents in each country

with incidents as (
	select 
			occurence_hour,
			country,
			city
	from {{ ref('int_incidents_data__incidents') }}
	where country is not null

), ranked_peak_hour as (
-- Rank peak hours per country
select 
		country,
		occurence_hour,
		count(1) as total_incidents,
		dense_rank() over(partition by country order by count(1) desc) as hour_rank
from incidents
group by country, occurence_hour
) select * from ranked_peak_hour where hour_rank <= 10
