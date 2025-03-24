import os
import json
import time
import requests
import logging
from datetime import date, timedelta

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] :: %(message)s',
)

# Set logger
logger = logging.getLogger(__name__)

# File names
incidents_data_file = f"outputs/incidents_data_{date.today() - timedelta(days = 1)}.parquet"
incidents_intermediary_file = f"outputs/incidents_intermediary_{date.today() - timedelta(days = 1)}.parquet"
incidents_coordinates_file = f"outputs/incidents_coordinates_{date.today() - timedelta(days = 1)}.parquet"
zones_file = "outputs/zones.parquet"

bucket_name = os.getenv("BUCKET_NAME")
dataset_name = os.getenv("DATASET_NAME")
# Api keys
tomtom_key = os.getenv("TOMTOM_KEY")

locationIQ_key = os.getenv("LOCATIONIQ_KEY")

# Load json file to bbox variable
with open("sub_bounding_boxes.json", "r") as file:
    bboxes = json.load(file)

def fetch_incidents_data(coordinates: dict, key: str) -> None:
    """Requests incidents data from traffic api (tomtom traffic api) for the given bbox"""
    # Tomtom api url
    # url is kept as is since formatting is odd (url taken from api website)
    url = f"https://api.tomtom.com/traffic/services/5/incidentDetails?bbox={coordinates["bbox"]}&fields=%7Bincidents%7Btype%2Cgeometry%7Btype%2Ccoordinates%7D%2Cproperties%7Bid%2CiconCategory%2CmagnitudeOfDelay%2Cevents%7Bdescription%2Ccode%2CiconCategory%7D%2CstartTime%2CendTime%2Cfrom%2Cto%2Clength%2Cdelay%2CroadNumbers%2CtimeValidity%2CprobabilityOfOccurrence%2CnumberOfReports%2ClastReportTime%2Ctmc%7BcountryCode%2CtableNumber%2CtableVersion%2Cdirection%7D%7D%7D%7D&language=en-GB&categoryFilter=0%2C1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9%2C10%2C11%2C14&timeValidityFilter=present&key={key}"
    headers = {"accept": "application/json"}

    # Retry counter, Max retries at 5 then abort
    retry = 0
    while retry < 5:
        try:
            response = requests.get(url, headers=headers, timeout=15)

            # On success add records
            if response.status_code == 200:
                response = response.json()["incidents"]

                # Iterate over incidents per requested bbox
                for i in response:
                    point_coordinates = i["geometry"]["coordinates"]
                    # Ensure type consistency even if coordinates contains a single element
                    if not isinstance(point_coordinates[0], list):
                        point_coordinates = [ point_coordinates ]
                        
                    incidents_data.append(
                        {
                            "properties": i["properties"],
                            "coordinates": point_coordinates,
                            "server" : coordinates["server"]
                        }
                    )
                logger.info(f"INCIDENTS API - Successfull request at : {coordinates["bbox"]}")
                break

            # Sleep when reached rate limit
            elif response.status_code == 429:
                logger.warning(f"INCIDENTS API - Reached request limit, sleeping ...")
                # Lock ressource when accessed by thread
                retry += 1
                time.sleep(5)

            # Break on failure mainly due to server error
            else:
                logger.error(
                    f"INCIDENTS API - Couldn't request {coordinates} failed with code : {response.status_code}"
                )
                break
        # Retry on connection error & increment counter
        except requests.exceptions.ConnectionError:
            logger.warning(
                f"INCIDENTS API - Connection error for bbox : {coordinates}, retry : {retry}"
            )
            retry += 1
            time.sleep(5)


def fetch_zone(coordinates: dict, key: str) -> None:
    """Requests geolocation data in batch from reverse geocoding api (LocationIQ) for given points"""

    # Request the right url depending on the server
    if coordinates["server"] == "US":
        url = "https://us1.locationiq.com/v1/reverse"
    else:
        url = "https://eu1.locationiq.com/v1/reverse"

    headers = {"accept": "application/json"}
    # Request parameters
    params = {
        "lon": coordinates["lon"],
        "lat": coordinates["lat"],
        "format": "json",
        "zoom": 10,
        "key": key,
    }

    # Retry counter, Max retries at 5 then abort
    retry = 0
    while retry < 5:
        try:
            response = requests.get(url, headers=headers, params=params, timeout=15)

            # On success add records
            if response.status_code == 200:
                response = response.json()

                logger.info(
                    f"REVERSE GEOCODING API - Successfull request at : {coordinates}"
                )
                # Append data keeping lon/lat as is for lookup tables
                zones_data.append(
                    {
                        "lon": coordinates["lon"],
                        "lat": coordinates["lat"],
                        "address": response["address"],
                    }
                )
                # Reverse geocoding api has tight request per minute 
                time.sleep(0.7)
                break

            # Sleep when reached rate limit
            elif response.status_code == 429:
                logger.warning(f"REVERSE GEOCODING LOOKUP API - Reached request limit, sleeping ...")
                retry += 1
                time.sleep(2)

            # Break on failure mainly due to server error
            else:
                logger.error(
                    f"REVERSE GEOCODING LOOKUP API - Couldn't request {coordinates} failed with code : {response.status_code}"
                )
                break
        # Retry on connection error & increment counter
        except requests.exceptions.ConnectionError:
            logger.warning(
                f"REVERSE GEOCODING LOOKUP API - Connection error for coordinates : {coordinates}, retry : {retry}"
            )
            retry += 1
            time.sleep(4)


incidents_data = []
zones_data = []
