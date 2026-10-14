from datetime import date, timedelta

from hypothesis import given, settings
from hypothesis import strategies as st

import main

DATES = st.dates(min_value=date(1990, 1, 1), max_value=date(2100, 12, 31))


@settings(max_examples=200, derandomize=True)
@given(st.integers(min_value=-10_000, max_value=10_000))
def test_charge_is_bounded_and_has_two_decimals(days):
    charge = main.prorate(days)
    assert 0.0 <= charge <= 20.0
    assert charge == round(charge, 2)


@settings(max_examples=200, derandomize=True)
@given(st.integers(min_value=-1_000, max_value=1_000), st.integers(min_value=0, max_value=1_000))
def test_charge_never_decreases_with_more_days(days, extra):
    assert main.prorate(days) <= main.prorate(days + extra)


@settings(max_examples=100, derandomize=True)
@given(st.integers(min_value=-10_000, max_value=0))
def test_zero_or_fewer_days_cost_nothing(days):
    assert main.prorate(days) == 0.0


@settings(max_examples=100, derandomize=True)
@given(st.integers(min_value=30, max_value=10_000))
def test_thirty_or_more_days_cost_the_full_difference(days):
    assert main.prorate(days) == 20.0


@settings(max_examples=200, derandomize=True)
@given(st.text(max_size=40), DATES)
def test_days_remaining_is_always_within_the_cycle(text, today):
    assert 0 <= main.calculate_days_remaining(text, today) <= 30


@settings(max_examples=200, derandomize=True)
@given(DATES)
def test_renewal_date_format_round_trips(day):
    formatted = day.strftime(main.RENEW_AT_FORMAT)
    parsed = main.datetime.strptime(formatted, main.RENEW_AT_FORMAT).date()
    assert parsed == day


@settings(max_examples=200, derandomize=True)
@given(DATES, st.integers(min_value=-60, max_value=60))
def test_days_remaining_matches_calendar_distance(renew, offset):
    today = renew - timedelta(days=offset)
    expected = min(max(offset, 0), 30)
    assert main.calculate_days_remaining(renew.strftime(main.RENEW_AT_FORMAT), today) == expected


@settings(max_examples=100, derandomize=True)
@given(DATES)
def test_upgrade_never_changes_the_renewal_date(renew):
    email = "prop@example.com"
    renew_at = renew.strftime(main.RENEW_AT_FORMAT)
    main.users[email] = {"plan": "Standard", "price": "$20/month", "renew_at": renew_at}
    try:
        from fastapi.testclient import TestClient

        body = TestClient(main.app).post("/api/billing/upgrade", json={"email": email}).json()
        assert body["renew_at"] == renew_at
        assert main.users[email]["renew_at"] == renew_at
        assert main.billing_data[email]["renew_at"] == renew_at
    finally:
        main.users.pop(email, None)
        main.billing_data.pop(email, None)
