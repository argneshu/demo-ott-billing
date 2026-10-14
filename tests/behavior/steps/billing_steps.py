"""Step definitions for the billing behaviour contracts (spec/behavior/*.feature).

Bound to the application's public surface: the HTTP endpoints, plus the module-level
proration functions. Loaded as a pytest plugin (see pytest.ini) so every feature shares them.
"""
from datetime import datetime

import pytest
from pytest_bdd import given, parsers, then, when

SEED = "tpg@example.com"


class _LazyMain:
    """Import the app on first use, not when this plugin loads.

    The plugin is loaded before pytest-cov starts measuring; importing main at that point would
    execute its module-level code untraced and under-report coverage.
    """

    def __getattr__(self, name):
        import main as app_module

        return getattr(app_module, name)


main = _LazyMain()


@pytest.fixture
def ctx():
    return {}


def _parse_day(text):
    return datetime.strptime(text, main.RENEW_AT_FORMAT).date()


@given(parsers.parse('the demo account "{email}" exists on the "{plan}" plan at ${amount:d}/month'))
def demo_account_exists(email, plan, amount):
    assert main.users[email]["plan"] == plan
    assert main.users[email]["price"] == f"${amount}/month"


@given(parsers.parse('its renewal date is "{renew_at}"'))
def renewal_date(renew_at):
    main.users[SEED]["renew_at"] = renew_at
    main.billing_data[SEED]["renew_at"] = renew_at


@given(parsers.parse('today is "{day}"'))
def today_is(day, set_today):
    set_today(_parse_day(day))


@given(parsers.parse('the renewal date of "{email}" is "{renew_at}"'))
def renewal_date_of(email, renew_at):
    main.users[email]["renew_at"] = renew_at
    main.billing_data[email]["renew_at"] = renew_at


@given(parsers.parse('a second Standard account "{email}" exists'))
def second_account(client, ctx, email):
    response = client.post("/api/auth/register", json={"name": "Other", "email": email, "password": "pw"})
    assert response.status_code == 200
    ctx["snapshot_" + email] = [dict(u) for u in main.billing_data[email]["usages"]]


@when("the days remaining and prorated charge are calculated")
def calculate(ctx):
    ctx["days"] = main.calculate_days_remaining(main.users[SEED]["renew_at"])
    ctx["charge"] = main.prorate(ctx["days"])


@when(parsers.parse('"{email}" requests an upgrade'))
def request_upgrade(client, ctx, email):
    ctx["response"] = client.post("/api/billing/upgrade", json={"email": email})


@when(parsers.parse('the Premium usages of "{email}" are modified in memory'))
def modify_usages(email):
    main.billing_data[email]["usages"].append({"id": "extra"})
    main.billing_data[email]["usages"][0]["value"] = "changed"


@then(parsers.parse("the days remaining are {days:d}"))
def days_are(ctx, days):
    assert ctx["days"] == days


@then(parsers.parse("the prorated charge is {charge:f}"))
def charge_is(ctx, charge):
    assert ctx["charge"] == charge


@then(parsers.parse("the response is 200 with prorated_charge {charge:f}"))
def ok_with_charge(ctx, charge):
    assert ctx["response"].status_code == 200
    assert ctx["response"].json()["prorated_charge"] == charge


@then(parsers.parse('the response is 200 with plan_name "{plan}", price "{price}" and prorated_charge {charge:f}'))
def ok_with_plan(ctx, plan, price, charge):
    body = ctx["response"].json()
    assert ctx["response"].status_code == 200
    assert (body["plan_name"], body["price"], body["prorated_charge"]) == (plan, price, charge)


@then(parsers.parse('"{email}" is on the "{plan}" plan'))
def is_on_plan(email, plan):
    assert main.users[email]["plan"] == plan


@then(parsers.parse('the account\'s plan is "{plan}" and its price is "{price}"'))
def account_plan(plan, price):
    assert main.users[SEED]["plan"] == plan
    assert main.users[SEED]["price"] == price


@then(parsers.parse('the usages are "{first}", "{second}" and "{third}"'))
def usages_are(ctx, first, second, third):
    values = [u["value"] for u in ctx["response"].json()["usages"]]
    assert values == [first, second, third]


@then(parsers.parse('the plan perks are "{first}", "{second}" and "{third}" at {percent:d} percent'))
def perks_are(ctx, first, second, third, percent):
    items = ctx["response"].json()["included_usage"]["items"]
    assert [i["label"] for i in items] == [first, second, third]
    assert {i["used_percent"] for i in items} == {percent}


@then(parsers.parse('the perks help text is "{text}"'))
def perks_help(ctx, text):
    assert ctx["response"].json()["included_usage"]["help"] == text


@then(parsers.parse('the response renew_at is "{value}"'))
def response_renew(ctx, value):
    assert ctx["response"].json()["renew_at"] == value


@then(parsers.parse('the account renewal date is "{value}"'))
def account_renew(value):
    assert main.users[SEED]["renew_at"] == value


@then(parsers.parse('the billing renewal date is "{value}"'))
def billing_renew(value):
    assert main.billing_data[SEED]["renew_at"] == value


@then(parsers.parse('the billing usages of "{email}" are unchanged'))
def usages_unchanged(ctx, email):
    assert main.billing_data[email]["usages"] == ctx["snapshot_" + email]
