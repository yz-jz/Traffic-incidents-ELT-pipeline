-- Coordinates table

with coordinates as (
	select * from `central-catcher-448814-j1`.`traffic_incidents_253`.`incidents_coordinates`
), -- Zones lookup table
zones as (
	select * from `central-catcher-448814-j1`.`traffic_incidents_253`.`zones`
) select c.id,
				 c.lon,
				 c.lat,
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
	from coordinates c 
	left join zones z
		on z.lon = c.lon and z.lat = c.lat