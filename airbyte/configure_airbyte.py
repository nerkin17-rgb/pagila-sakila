from __future__ import annotations

import os
import sys

import requests

BASE_URL = os.environ["AIRBYTE_SERVER_URL"].rstrip("/")
WORKSPACE_ID = os.environ["AIRBYTE_WORKSPACE_ID"]


def _token() -> str:
    resp = requests.post(
        f"{BASE_URL}/applications/token",
        json={
            "client_id": os.environ["AIRBYTE_CLIENT_ID"],
            "client_secret": os.environ["AIRBYTE_CLIENT_SECRET"],
            "grant-type": "client_credentials",
        },
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


class Airbyte:
    def __init__(self):
        self.headers = {"Authorization": f"Bearer {_token()}"}

    def _find_by_name(self, kind: str, name: str) -> str | None:
        resp = requests.get(
            f"{BASE_URL}/{kind}", headers=self.headers,
            params={"workspaceIds": WORKSPACE_ID}, timeout=30,
        )
        resp.raise_for_status()
        for item in resp.json().get("data", []):
            if item["name"] == name:
                return item[f"{kind[:-1]}Id"]
        return None

    def upsert_source(self, name: str, configuration: dict) -> str:
        existing = self._find_by_name("sources", name)
        if existing:
            print(f"source '{name}' already exists -> {existing}")
            return existing
        resp = requests.post(
            f"{BASE_URL}/sources", headers=self.headers,
            json={"name": name, "workspaceId": WORKSPACE_ID, "configuration": configuration},
            timeout=30,
        )
        resp.raise_for_status()
        source_id = resp.json()["sourceId"]
        print(f"created source '{name}' -> {source_id}")
        return source_id

    def upsert_destination(self, name: str, configuration: dict) -> str:
        existing = self._find_by_name("destinations", name)
        if existing:
            print(f"destination '{name}' already exists -> {existing}")
            return existing
        resp = requests.post(
            f"{BASE_URL}/destinations", headers=self.headers,
            json={"name": name, "workspaceId": WORKSPACE_ID, "configuration": configuration},
            timeout=30,
        )
        resp.raise_for_status()
        destination_id = resp.json()["destinationId"]
        print(f"created destination '{name}' -> {destination_id}")
        return destination_id

    def upsert_connection(self, name: str, source_id: str, destination_id: str, namespace: str) -> str:
        existing = self._find_by_name("connections", name)
        if existing:
            print(f"connection '{name}' already exists -> {existing}")
            return existing
        resp = requests.post(
            f"{BASE_URL}/connections", headers=self.headers,
            json={
                "name": name,
                "sourceId": source_id,
                "destinationId": destination_id,
                "namespaceDefinition": "custom_format",
                "namespaceFormat": namespace,
                "schedule": {"scheduleType": "cron", "cronExpression": "0 * * * * ?"},
            },
            timeout=30,
        )
        resp.raise_for_status()
        connection_id = resp.json()["connectionId"]
        print(f"created connection '{name}' -> {connection_id}")
        return connection_id


def postgres_source_config(database: str) -> dict:
    return {
        "sourceType": "postgres",
        "host": os.environ["AIRBYTE_SRC_DB_HOST"],
        "port": 5432,
        "database": database,
        "username": os.environ["SRC_DB_USER"],
        "password": os.environ["SRC_DB_PASS"],
        "schemas": ["public"],
        "replicationMethod": {"method": "Standard"},
    }


def snowflake_destination_config() -> dict:
    key_path = os.environ["AIRBYTE_SF_LOADER_PRIVATE_KEY_PATH"]
    with open(key_path) as f:
        private_key = f.read()
    return {
        "destinationType": "snowflake",
        "host": os.environ["AIRBYTE_SF_ACCOUNT_URL"],
        "role": "LOADER_ROLE",
        "warehouse": "LOADING_WH",
        "database": "RAW",
        "username": "AIRBYTE_SVC",
        "credentials": {"authType": "Key Pair Authentication", "privateKey": private_key},
    }


def main() -> None:
    ab = Airbyte()

    pagila_source = ab.upsert_source("pagila-postgres", postgres_source_config("pagila"))
    sakila_source = ab.upsert_source("sakila-postgres", postgres_source_config("sakila"))
    snowflake_dest = ab.upsert_destination("snowflake-raw", snowflake_destination_config())

    pagila_conn = ab.upsert_connection("pagila-to-snowflake", pagila_source, snowflake_dest, "PAGILA_RAW")
    sakila_conn = ab.upsert_connection("sakila-to-snowflake", sakila_source, snowflake_dest, "SAKILA_RAW")

    print("\nAdd these to .env:")
    print(f"AIRBYTE_PAGILA_CONNECTION_ID={pagila_conn}")
    print(f"AIRBYTE_SAKILA_CONNECTION_ID={sakila_conn}")


if __name__ == "__main__":
    try:
        main()
    except requests.HTTPError as e:
        print(f"Airbyte API error: {e.response.status_code} {e.response.text}", file=sys.stderr)
        sys.exit(1)
