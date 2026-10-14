"""API & contract tests for POST /api/billing/upgrade against the real endpoint."""
import pytest

import main

SEED = "tpg@example.com"
RESPONSE_KEYS = {"plan_name", "price", "renew_at", "prorated_charge", "usages", "included_usage"}


def test_functional_happy_path_and_response_schema(client, set_today):
    from datetime import date

    set_today(date(2026, 10, 15))
    response = client.post("/api/billing/upgrade", json={"email": SEED})
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    body = response.json()
    assert set(body) == RESPONSE_KEYS
    assert isinstance(body["plan_name"], str) and isinstance(body["price"], str)
    assert isinstance(body["renew_at"], str) and isinstance(body["prorated_charge"], float)
    assert isinstance(body["usages"], list) and len(body["usages"]) == 3
    for usage in body["usages"]:
        assert set(usage) == {"id", "label", "type", "value", "help"}
    perks = body["included_usage"]
    assert set(perks) == {"title", "items", "help"}
    for item in perks["items"]:
        assert set(item) == {"id", "label", "used_percent"}


@pytest.mark.parametrize(
    "payload, expected_status",
    [
        ({"email": "ghost@example.com"}, 401),
        ({"email": SEED}, 200),
    ],
)
def test_response_codes(client, payload, expected_status):
    assert client.post("/api/billing/upgrade", json=payload).status_code == expected_status


def test_error_response_shape_for_unknown_user(client):
    body = client.post("/api/billing/upgrade", json={"email": "ghost@example.com"}).json()
    assert body == {"detail": "Not authenticated"}


def test_error_response_shape_when_already_premium(client):
    client.post("/api/billing/upgrade", json={"email": SEED})
    response = client.post("/api/billing/upgrade", json={"email": SEED})
    assert response.status_code == 400
    assert response.json() == {"detail": "Already on Premium plan"}


@pytest.mark.parametrize("payload", [{}, {"email": None}, {"email": 123}, {"email": ["a"]}])
def test_request_validation_rejects_bad_bodies(client, payload):
    assert client.post("/api/billing/upgrade", json=payload).status_code == 422
    assert main.users[SEED]["plan"] == "Standard"


def test_request_validation_rejects_non_json_body(client):
    response = client.post("/api/billing/upgrade", content="not json", headers={"content-type": "application/json"})
    assert response.status_code == 422


def test_wrong_method_is_not_allowed(client):
    assert client.get("/api/billing/upgrade").status_code == 405
