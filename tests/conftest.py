import copy
from datetime import date

import pytest
from fastapi.testclient import TestClient

import main


@pytest.fixture(autouse=True)
def reset_state():
    """Every test starts from, and restores, the seed in-memory data."""
    users = copy.deepcopy(main.users)
    billing = copy.deepcopy(main.billing_data)
    yield
    main.users.clear()
    main.users.update(users)
    main.billing_data.clear()
    main.billing_data.update(billing)


@pytest.fixture
def client():
    return TestClient(main.app)


@pytest.fixture
def set_today(monkeypatch):
    def _set(value: date) -> None:
        monkeypatch.setattr(main, "_today", lambda: value)

    return _set
