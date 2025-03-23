-- Coordinates table

with coordinates as (
	select * from {{ source('incidents','incidents_coordinates') }}
), -- Zones lookup table
zones as (
	select * from {{ source('incidents','zones') }}
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





