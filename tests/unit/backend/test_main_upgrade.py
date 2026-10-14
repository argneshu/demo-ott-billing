from datetime import date

import pytest

import main

SEED = "tpg@example.com"


@pytest.mark.parametrize(
    "today, days, charge",
    [
        (date(2026, 10, 30), 0, 0.0),
        (date(2026, 11, 5), 0, 0.0),
        (date(2026, 10, 15), 15, 10.0),
        (date(2026, 10, 1), 29, 19.33),
        (date(2026, 9, 1), 30, 20.0),
    ],
)
def test_days_and_charge_for_seed_renewal_date(today, days, charge):
    assert main.calculate_days_remaining("Oct 30, 2026", today) == days
    assert main.prorate(days) == charge


def test_unparseable_renewal_date_counts_as_zero_days():
    assert main.calculate_days_remaining("not a date") == 0
    assert main.calculate_days_remaining(None) == 0  # type: ignore[arg-type]


def test_today_defaults_to_the_server_local_date():
    assert main.calculate_days_remaining("Jan 01, 2000") == 0


def test_prorate_clamps_out_of_range_days():
    assert main.prorate(-5) == 0.0
    assert main.prorate(99) == 20.0


def test_upgrade_applies_premium_and_returns_contract(client, set_today):
    set_today(date(2026, 10, 15))
    response = client.post("/api/billing/upgrade", json={"email": SEED})
    assert response.status_code == 200
    body = response.json()
    assert body["plan_name"] == "Premium"
    assert body["price"] == "$40/month"
    assert body["prorated_charge"] == 10.0
    assert set(body) == {"plan_name", "price", "renew_at", "prorated_charge", "usages", "included_usage"}
    assert main.users[SEED]["plan"] == "Premium"
    assert main.users[SEED]["price"] == "$40/month"
    assert main.billing_data[SEED]["plan_name"] == "Premium"
    assert "password" not in body


def test_upgrade_returns_exact_premium_feature_data(client):
    body = client.post("/api/billing/upgrade", json={"email": SEED}).json()
    assert [(u["id"], u["value"]) for u in body["usages"]] == [
        ("video-quality", "4K Ultra HD"),
        ("screens", "Can watch on 4 devices at once"),
        ("downloads", "Can download on 6 devices"),
    ]
    perks = body["included_usage"]
    assert perks["title"] == "Plan perks"
    assert perks["help"] == "Perks included in your Premium plan."
    assert [(i["id"], i["used_percent"]) for i in perks["items"]] == [
        ("ad-free", 100),
        ("spatial-audio", 100),
        ("dolby-vision", 100),
    ]


def test_renewal_date_is_unchanged(client):
    before = main.users[SEED]["renew_at"]
    body = client.post("/api/billing/upgrade", json={"email": SEED}).json()
    assert body["renew_at"] == before
    assert main.users[SEED]["renew_at"] == before
    assert main.billing_data[SEED]["renew_at"] == before


def test_unparseable_renewal_date_upgrades_with_zero_charge(client):
    main.users[SEED]["renew_at"] = "not a date"
    response = client.post("/api/billing/upgrade", json={"email": SEED})
    assert response.status_code == 200
    assert response.json()["prorated_charge"] == 0.0
    assert main.users[SEED]["plan"] == "Premium"


def test_premium_payload_is_not_shared_between_accounts(client):
    client.post("/api/auth/register", json={"name": "O", "email": "other@example.com", "password": "pw"})
    other_before = [dict(u) for u in main.billing_data["other@example.com"]["usages"]]
    client.post("/api/billing/upgrade", json={"email": SEED})
    main.billing_data[SEED]["usages"].append({"id": "extra"})
    main.billing_data[SEED]["usages"][0]["value"] = "changed"
    assert main.billing_data["other@example.com"]["usages"] == other_before
    second = client.post("/api/auth/register", json={"name": "P", "email": "p2@example.com", "password": "pw"})
    assert second.status_code == 200
    client.post("/api/billing/upgrade", json={"email": "p2@example.com"})
    assert main.billing_data["p2@example.com"]["usages"][0]["value"] == "4K Ultra HD"


def test_upgrade_guards_leave_state_untouched(client):
    client.post("/api/billing/upgrade", json={"email": SEED})
    snapshot = dict(main.users[SEED])
    again = client.post("/api/billing/upgrade", json={"email": SEED})
    assert again.status_code == 400
    assert again.json() == {"detail": "Already on Premium plan"}
    assert main.users[SEED] == snapshot
    ghost = client.post("/api/billing/upgrade", json={"email": "ghost@example.com"})
    assert ghost.status_code == 401
    assert "ghost@example.com" not in main.users
