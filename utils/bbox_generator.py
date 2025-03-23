import json
from math import ceil, sqrt

# Angles to convert lon/lat to km (approximate)
lon_angle = 111
lat_angle = 85


def get_bbox(country: str, min_lon: float, min_lat: float, max_lon: float, max_lat: float) -> list[dict]:
    """Subdivide a given country's bounding box into adjacent sub bounding boxes of 10K km² area limit"""

    # Convert lon/lat coordonates of a country's bbox to width and height in kilometers
    # Max - min to get the distance * angle to get the distance in km
    width = (max_lon - min_lon) * lon_angle
    height = (max_lat - min_lat) * lat_angle

    # Give number of horizontal and vertical splits of the area dividing it into sub bounding boxes of MAX area = 10K km²
    # adhering to tomtom api requirements
    # dimension / 10 000 km²
    # max (1, x) is used to output one bounding box if the input bbox is 10k or less km²
    x_split = max(1, ceil(width / sqrt(10000)))
    y_split = max(1, ceil(height / sqrt(10000)))

    # Calculate how many units a single sub bounding box has, lon/lat
    lon_step = (max_lon - min_lon) / x_split
    lat_step = (max_lat - min_lat) / y_split

    # Store sub bbox
    boxes = []

    # Generate bounds for each sub bbox
    # Take each min coordinate * n steps to constitute min longitude/latitude
    # Take sub bbox min longitude + 1 step for it's corresponding max longitude/latitude
    for i in range(x_split):
        for j in range(y_split):
            sub_min_step_lon = min_lon + (i * lon_step)
            sub_max_step_lon = sub_min_step_lon + lon_step
            sub_min_step_lat = min_lat + (j * lat_step)
            sub_max_step_lat = sub_min_step_lat + lat_step

            boxes.append(
                {
                    "country": country,
                    "bbox": [
                        sub_min_step_lon,
                        sub_min_step_lat,
                        sub_max_step_lon,
                        sub_max_step_lat,
                    ],
                }
            )
            # boxes.append({"country":country,"coordinates": [ sub_min_step_lon,sub_min_step_lat,sub_max_step_lon,sub_max_step_lat ] })
            # box = shapely.geometry.box(min_lon,min_lat,max_lon,max_lat)
            # boxes.append({"country" : country, "box" : box, "coords" : [ sub_min_step_lon,sub_min_step_lat,sub_max_step_lon,sub_max_step_lat ] })
    return boxes

# List of country_codes for countries covered by traffic API
country_codes = ["EG","KE","LS","MA","MZ","NG","RE","ZA","AR","BR",
                "CA","CL","CO","GP","MQ","MX","PE","US","UY","BH",
                "BN","HK","IN","ID","IL","KZ","KW","MO","MY","OM",
                "PH","QA","SA","SG","KR","TW","TH","AE","VN","AU",
                "NZ","AD","AT","BY","BE","BA","BG","HR","CY","CZ",
                "DK","EE","FI","FR","DE","GI","GR","HU","IS","IE",
                "IT","LV","LI","LT","LU","MT","MC","NL","NO","PL",
                "PT","RO","RU","SM","RS","SK","SI","ES","SE","CH",
                "TR","UA","GB"
]

# Open provided countries bounding-boxes
with open("countries_bounding-boxes.json", "r") as file:
    bbox = json.load(file)

# Store all sub bounding boxes
grids = []

# iterate over each country's bounding_box and pass it to get_bbox function if the country is supported by tomtom api
for country, bounding_box in bbox.items():
    if country in country_codes:
        box = bounding_box[1]
        grids += get_bbox(country, box[0], box[1], box[2], box[3])


def map_bbox(filename: str, bounding_boxes: list[dict]) -> None:
    """Generate an interactive map displaying the area of the provided bounding boxes"""
    import folium
    import shapely

    m = folium.Map()
    for bbox in bounding_boxes:
        print(bbox)
        # Make bbox a box object so folium can process it
        box = shapely.geometry.box(
            bbox["bbox"][0], bbox["bbox"][1], bbox["bbox"][2], bbox["bbox"][3]
        )
        # Add bounding box rectangle to map
        folium.Rectangle(
            # [[SW], [NE]]
            bounds=[
                [box.bounds[1], box.bounds[0]],
                [box.bounds[3], box.bounds[2]],
            ],  
            color="red",
            fill=True,
            fill_opacity=0.3,
        ).add_to(m)
    # Save map to HTML file
    m.save(filename)
