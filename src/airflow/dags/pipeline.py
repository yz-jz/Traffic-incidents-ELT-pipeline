import os

from airflow.decorators import dag, task
from pendulum import datetime
from airflow.contrib.operators.gcs_to_bq import GCSToBigQueryOperator
from airflow.providers.google.cloud.transfers.local_to_gcs import LocalFilesystemToGCSOperator

from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.profiles import PostgresUserPasswordProfileMapping

from concurrent.futures import ThreadPoolExecutor
from functools import partial
import polars as pl

from extract_tasks import *

DBT_PROJECT_PATH = f"{os.environ['AIRFLOW_HOME']}/dags/dbt/traffic_incidents"
# The path where Cosmos will find the dbt executable
# in the virtual environment created in the Dockerfile
DBT_EXECUTABLE_PATH = f"{os.environ['AIRFLOW_HOME']}/dbt_venv/bin/dbt"

profile_config = ProfileConfig(
    profile_name="traffic_incidents",
    target_name="dev",
    profiles_yml_filepath=f"{DBT_PROJECT_PATH}/profiles.yml",
)

execution_config = ExecutionConfig(
    dbt_executable_path=DBT_EXECUTABLE_PATH,
)

# Define functions that can't be used with task decorator 
# Define file transfer function from local fs to gcs
def upload_to_datalake(filename : str, task_id : str) -> LocalFilesystemToGCSOperator:
    """ Uploads parquet file to google cloud storage before ingestion """
    return LocalFilesystemToGCSOperator(
        task_id=task_id,
        src=filename,
        dst=filename,
        bucket=bucket_name,
    )

# Define file transfer function from gcs to bigquery
def load_to_warehouse(file_path : str, table_name : str, task_id : str) -> GCSToBigQueryOperator:
    return GCSToBigQueryOperator(
            task_id=task_id,
            bucket=bucket_name,
            source_objects=[file_path],
            source_format="parquet",
            destination_project_dataset_table=f"{dataset_name}.{table_name}",
            write_disposition="WRITE_TRUNCATE",
            external_table=False,
            autodetect=True
        )

# Dag basic parameters
@dag(
    start_date=datetime(2025, 1, 1),
    schedule="@daily",
    catchup=False, # Disable reruns of all DAG that were scheduled before today's date
    default_args={"retries": 3},
)
def traffic_incidents_pipeline():
    """ Orchestrates the daily execution of traffic incidents pipeline
    The DAG leverages Airflow's TaskFlow API, using the @dag and @task decorators 
    
    Tasks:
      - extract_data: Executes the data extraction logic and saves output to disk for incidents data
      - extract_zones: Executes the data extraction logic and saves output to disk for zones and coordinates
      
    Note:
      - This DAG relies on side effects (e.g., file I/O) rather than XCom-based data passing.
      - Ensure that required dependencies are installed and that keys are properly defined and accessible.
    """
    # Define tasks
    @task
    def extract_data() -> None:
        """Wrapper function fetches incidents data concurrently using multithreadding"""

        with ThreadPoolExecutor(max_workers=5) as executor:
            function = partial(fetch_incidents_data, key=tomtom_key)
            list(executor.map(function,bboxes))

        df_data = pl.DataFrame(incidents_data).unnest("properties")
        df_coordinates = df_data.select(["id", "coordinates","server"])

        # save files
        # as airflow is not intended to pass dataframes between tasks
        # next functions will read from disk

        df_data.drop("coordinates").write_parquet(incidents_data_file)
        df_coordinates.write_parquet(incidents_intermediary_file)

    @task
    def extract_zones(incidents_intermediary_file : str) -> None:
        """Wrapper function fetches zones data concurrently using multithreadding"""

        # Read from raw coordinates file
        df = pl.read_parquet(incidents_intermediary_file)
        # Get the mid point of the incident LineString >> mean longitute and mean latitude
        # Coordinates is a list[ list[ float  ]  ]
        # Map longitude elements of index 0 into list[ float  ] column
        # Map latitude elements of index 1 into list[ float  ] column
        # Coordinates are rounded to 2 decimal places giving an approximate precision of 1km (Precision had to be traded in order to optimize query per api call due to rate limits)
        df_lon_lat = df.with_columns(
            pl.col("coordinates")
            .map_elements(lambda x: [i[0] if len(i) > 0 else None for i in x], return_dtype=pl.List(pl.Float64))
            .alias("lon")
            .list.mean()
            .round(2),
            pl.col("coordinates")
            .map_elements(lambda x: [i[1] if len(i) > 1 else None for i in x], return_dtype=pl.List(pl.Float64))
            .alias("lat")
            .list.mean()
            .round(2),
        ).drop("coordinates")

        # Save incidents coordinates file
        df_lon_lat.write_parquet(incidents_coordinates_file)

        # Select distinct coordinates for zones lookup table server needed for knowing which server to choose in the api url
        distinct_lon_lat = df_lon_lat.select(["server","lon", "lat"]).unique()
        
        # Load zones lookup file if exists to filter known locations (optimize reverse lookup incrementally) NB : data caching complies to LocationIQ TOS
        try:
            zones = pl.read_parquet(zones_file)
            # Filter on lon/lat, keeping only unkown locations
            distinct_lon_lat = distinct_lon_lat.filter((~pl.col("lon").is_in(zones["lon"])) & (~pl.col("lat").is_in(zones["lat"])))
        except FileNotFoundError:
            pass

        # Get list[ dict ] from distinct coordinates dataframe to query zones api
        coordinates_list = distinct_lon_lat.to_dicts()

    #    # Split coordinates_list into list[ list[ dict ] ] nested list are of max_size 1000 as stated in api docs
    #    max_size = 2
    #    split_number = len(coordinates_list) // max_size # Size of chunked coordinates list
    #    # Split coordinates list
    #    coordinates_list = [coordinates_list[i * max_size : (i + 1) * max_size]  for i in range(split_number + 1)]

        with ThreadPoolExecutor(max_workers=2) as executor:
            function = partial(fetch_zone, key=locationIQ_key)
            #function = partial(fetch_zone, key=locationIQ_key)
            list(executor.map(function, coordinates_list))

        try:
            zones_df = pl.DataFrame(zones_data).unnest("address")
        except pl.exceptions.ColumnNotFoundError:
            zones_df = pl.DataFrame()

        # Concat fetched zones dataframe with zones lookup df
        try:
            # Diagonal to allow schema mismatch as data might be inconcisten
            zones_df = pl.concat([zones, zones_df], how="diagonal")
        except NameError:
            pass
        # Save zones file
        zones_df.write_parquet(zones_file)

    transform_data = DbtTaskGroup(
        group_id="transform_data",
        project_config=ProjectConfig(DBT_PROJECT_PATH),
        profile_config=profile_config,
        execution_config=execution_config
    )

    # Upload tasks
    upload_incidents_data_to_datalake = upload_to_datalake(incidents_data_file, "upload_incidents")
    upload_incidents_coordinates_to_datalake = upload_to_datalake(incidents_coordinates_file, "upload_coordinates")
    upload_zones_to_datalake = upload_to_datalake(zones_file, "upload_zones")

    # Load tasks
    load_incidents_data_to_bigquery = load_to_warehouse(incidents_data_file, "incidents_data","load_incidents")
    load_incidents_coordinates_to_bigquery = load_to_warehouse(incidents_coordinates_file, "incidents_coordinates","load_coordinates")
    load_zones_to_big_query = load_to_warehouse(zones_file, "zones","load_zones")

    # Execution order
    (
        extract_data()
        >> upload_incidents_data_to_datalake
        >> extract_zones(incidents_intermediary_file)
        >> [upload_incidents_coordinates_to_datalake, upload_zones_to_datalake]
        >> load_incidents_data_to_bigquery
        >> [load_incidents_coordinates_to_bigquery, load_zones_to_big_query]
        >> transform_data
    )

# Instantiate DAG
traffic_incidents_pipeline()
