# Traffic Incidents ELT Data Pipeline

## Project Overview

Traffic incidents occur daily across various regions, impacting commuters, urban planning, and emergency response strategies. To gain better insights into these incidents, we need a robust data pipeline capable of efficiently collecting, processing, and analyzing incident data at scale.

However, raw incident data is fragmented and retrieved through an API that requires bounding box coordinates for querying. Additionally, the data lacks proper structuring for analytical workloads. This project addresses these challenges by developing a cloud native end-to-end ELT pipeline that automates data ingestion, transformation, and visualization, enabling efficient analysis of traffic incidents.

## Tech Stack & Tools

This project is designed as a cloud-native, scalable, and fully automated data pipeline:

1. Cloud Infrastructure

- Google Cloud Platform (GCP) : Fully cloud-based architecture

- Google Cloud Storage (GCS) : Data lake for parquet data storage and source code deployment

- Google Compute Engine (GCE) : Hosting Airflow for pipeline orchestration

- BigQuery : Cloud-based data warehouse optimized for analytical workloads

- Terraform : Infrastructure as Code (IaC) to provision and manage all cloud resources, including storage buckets, compute instances, cloud functions and firewall rules

2. Workflow Orchestration

Apache Airflow : End-to-end orchestration of the ELT process using DAGs

Cosmos : Bridging Airflow and dbt for seamless transformation execution

3. Data Processing & Ingestion

Python : Core programming language for data exctraction and processing

Polars : High-performance data manipulation library for fast transformations and data flattening 

Multithreading : Optimized API querying for parallelized data retrieval

Folium & Shapelt : Converting coordinates into plotted locations on an interactive map

Cosmos : Enabling interaction between Apache Airflow and dbt

4. Data Transformation 

dbt (Data Build Tool) : Automated SQL-based transformations in BigQuery, ensuring structured and optimized data models

5. Visualization

Looker : Cloud-native BI platform for interactive data visualization

## Pipeline Overview

The pipeline follows a structured ELT (Extract, Load, Transform) workflow, ensuring efficient data ingestion, transformation, and visualization:

1️⃣. Data Ingestion

- Geodata partitionning as a prerequisite, traffic incident data is retrieved using API calls that require predefined bounding boxes refer to doc

- BBox Optimization: Large country-wide bboxes are split into sub-bboxes of 10,000 km² to comply with API constraints.

- Parallel API Requests: Using multithreading, the system efficiently queries the API for incidents across multiple bboxes.

- Extracted data is split into incidents metadata and coordinates data both saved as parquet files.

- API Based Reverse Geocoding is applied to coordinates data constituting a zones lookup table for downstream optimizations

- Raw data is stored in Data lake

2. Data Loading

- Data is transferred from GCS to BigQuery, ensuring efficient storage for analytical queries.

4. Data Transformation with dbt

SQL-Based Transformations: dbt is used to process the data, including:

- Data enrichment
- Data cleaning
- Aggregations

5️⃣. Data Visualization

- Looker Dashboard: A dashboard is created in Looker with interactive visualizations

** Orchestration with Cosmos & Airflow: dbt runs within Airflow via Cosmos, ensuring automated execution within DAGs **


Get countries bboxes

generate bboxes

plot bboxes

mention overlap

#TODO explain no code
filter bboxes 

pubsub trigger cloud function

SELECT parse_datetime("%FT%H:%M:%SZ", startTime) FROM `central-catcher-448814-j1.ti_tst25319.incidents_data` LIMIT 1000

select (select direction from unnest([tmc])) as code FROM `central-catcher-448814-j1.ti_tst25319.incidents_data` LIMIT 1000

SELECT
  element.code,
  element.description,
  element.iconCategory
FROM `central-catcher-448814-j1.ti_tst25319.incidents_data`,
UNNEST(events.list) AS list,  -- First, unnest the list
UNNEST([list.element]) AS element  -- Then, unnest the nullable struct as an array
LIMIT 1000;

MEntion partitionning and clustering in doc and in dbt

#export env vars for dbt and airflow

curl -sSL install.astronomer.io | sudo bash -s

add to make dockerfile gen with env vars

https://lookerstudio.google.com/s/j7yhOMsJhHk
