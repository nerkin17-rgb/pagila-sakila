"""
pagila_sakila_pipeline
-----------------------
Orchestrates the whole load+transform cycle:
  1. trigger Airbyte sync for the Pagila source -> RAW.PAGILA_RAW
  2. trigger Airbyte sync for the Sakila source -> RAW.SAKILA_RAW
  3. dbt deps / run / test against Snowflake using the TRANSFORM_ROLE
     service account (never ADMIN — see snowflake/setup.sql)

Airbyte is deployed separately via `abctl` (Docker Compose deployments of
Airbyte are deprecated), so this DAG only talks to its REST API — it does
not try to manage Airbyte containers itself.
"""
from __future__ import annotations

import os
import time
from datetime import datetime

import requests
from airflow.decorators import dag, task
from airflow.exceptions import AirflowException

AIRBYTE_SERVER_URL = os.environ["AIRBYTE_SERVER_URL"].rstrip("/")
AIRBYTE_CLIENT_ID = os.environ.get("AIRBYTE_CLIENT_ID", "")
AIRBYTE_CLIENT_SECRET = os.environ.get("AIRBYTE_CLIENT_SECRET", "")
DBT_PROJECT_DIR = "/opt/pagila_analytics"


def _airbyte_token() -> str:
    resp = requests.post(
        f"{AIRBYTE_SERVER_URL}/applications/token",
        json={
            "client_id": AIRBYTE_CLIENT_ID,
            "client_secret": AIRBYTE_CLIENT_SECRET,
            "grant-type": "client_credentials",
        },
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


def _trigger_and_wait(connection_id: str, poll_interval: int = 15, timeout: int = 1800) -> None:
    if not connection_id:
        raise AirflowException("Connection id not configured, check .env")

    headers = {"Authorization": f"Bearer {_airbyte_token()}"}
    job = requests.post(
        f"{AIRBYTE_SERVER_URL}/jobs",
        headers=headers,
        json={"connectionId": connection_id, "jobType": "sync"},
        timeout=30,
    )
    job.raise_for_status()
    job_id = job.json()["jobId"]

    elapsed = 0
    while elapsed < timeout:
        status_resp = requests.get(f"{AIRBYTE_SERVER_URL}/jobs/{job_id}", headers=headers, timeout=30)
        status_resp.raise_for_status()
        status = status_resp.json()["status"]
        if status == "succeeded":
            return
        if status in ("failed", "cancelled", "incomplete"):
            raise AirflowException(f"Airbyte job {job_id} ended with status={status}")
        time.sleep(poll_interval)
        elapsed += poll_interval

    raise AirflowException(f"Airbyte job {job_id} did not finish within {timeout}s")


@dag(
    dag_id="pagila_sakila_pipeline",
    schedule="0 * * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["pagila", "sakila", "airbyte", "dbt", "snowflake"],
)
def pagila_sakila_pipeline():

    @task
    def sync_pagila():
        _trigger_and_wait(os.environ["AIRBYTE_PAGILA_CONNECTION_ID"])

    @task
    def sync_sakila():
        _trigger_and_wait(os.environ["AIRBYTE_SAKILA_CONNECTION_ID"])

    from airflow.operators.bash import BashOperator

    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command=f"dbt deps --project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROJECT_DIR}",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"dbt run --project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROJECT_DIR}",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"dbt test --project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROJECT_DIR}",
    )

    [sync_pagila(), sync_sakila()] >> dbt_deps >> dbt_run >> dbt_test


pagila_sakila_pipeline()
