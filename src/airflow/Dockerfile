FROM quay.io/astronomer/astro-runtime:12.1.1

COPY k.json /usr/local/airflow

RUN python -m venv dbt_venv && source dbt_venv/bin/activate && \
    pip install --no-cache-dir astronomer-cosmos[dbt.bigquery] dbt-postgres && deactivate \
    && pip install polars astronomer-cosmos
