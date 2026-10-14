from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from pathlib import Path
from datetime import UTC, date, datetime, timedelta

app = FastAPI(title="Billing & Tasks POC")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory mock store (no database)
users = {
    "tpg@example.com": {
        "id": 1,
        "name": "TPG",
        "email": "tpg@example.com",
        "password": "password",
        "plan": "Standard",
        "price": "$20/month",
        "renew_at": "Oct 30, 2026",
    }
}

billing_data = {
    "tpg@example.com": {
        "plan_name": "Standard",
        "price": "$20/month",
        "renew_at": "Oct 30, 2026",
        "usages": [
            {
                "id": "video-quality",
                "label": "Video quality",
                "type": "feature",
                "value": "Full HD (1080p)",
                "help": "The best video resolution available on the Standard plan.",
            },
            {
                "id": "screens",
                "label": "Watch at the same time",
                "type": "feature",
                "value": "Can watch on 2 devices at once",
                "help": "Number of supported devices that can stream on your account simultaneously.",
            },
            {
                "id": "downloads",
                "label": "Download on devices",
                "type": "feature",
                "value": "Can download on 2 devices",
                "help": "Number of supported devices you can download titles to for offline viewing.",
            },
        ],
        "included_usage": {
            "title": "Plan perks",
            "items": [
                {"id": "ad-free", "label": "Ad-free streaming", "used_percent": 100},
                {"id": "spatial-audio", "label": "Spatial audio (select titles)", "used_percent": 100},
            ],
            "help": "Perks included in your Standard plan.",
        },
    }
}

class LoginRequest(BaseModel):
    email: str
    password: str


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str


class TokenRequest(BaseModel):
    token: str


class UpgradeRequest(BaseModel):
    email: str


STANDARD_PRICE = 20
PREMIUM_PRICE = 40
CYCLE_DAYS = 30
RENEW_AT_FORMAT = "%b %d, %Y"


def _today() -> date:
    return datetime.now().astimezone().date()


def calculate_days_remaining(renew_at: str, today: date | None = None) -> int:
    """Days left in the cycle, clamped to 0..CYCLE_DAYS; an unparseable date counts as 0."""
    try:
        renew_date = datetime.strptime(renew_at, RENEW_AT_FORMAT).replace(tzinfo=UTC).date()
    except (TypeError, ValueError):
        return 0
    remaining = (renew_date - (today or _today())).days
    return min(max(remaining, 0), CYCLE_DAYS)


def prorate(days_remaining: int) -> float:
    """Prorated Standard to Premium charge for the days left in the cycle."""
    days = min(max(days_remaining, 0), CYCLE_DAYS)
    return round((PREMIUM_PRICE - STANDARD_PRICE) * (days / CYCLE_DAYS), 2)


def premium_billing_profile(renew_at: str) -> dict:
    """A fresh Premium billing profile; every call returns its own copy so accounts never share state."""
    return {
        "plan_name": "Premium",
        "price": f"${PREMIUM_PRICE}/month",
        "renew_at": renew_at,
        "usages": [
            {
                "id": "video-quality",
                "label": "Video quality",
                "type": "feature",
                "value": "4K Ultra HD",
                "help": "The best video resolution available on the Premium plan.",
            },
            {
                "id": "screens",
                "label": "Watch at the same time",
                "type": "feature",
                "value": "Can watch on 4 devices at once",
                "help": "Number of supported devices that can stream simultaneously.",
            },
            {
                "id": "downloads",
                "label": "Download on devices",
                "type": "feature",
                "value": "Can download on 6 devices",
                "help": "Number of devices for offline viewing.",
            },
        ],
        "included_usage": {
            "title": "Plan perks",
            "items": [
                {"id": "ad-free", "label": "Ad-free streaming", "used_percent": 100},
                {"id": "spatial-audio", "label": "Spatial audio (select titles)", "used_percent": 100},
                {"id": "dolby-vision", "label": "Dolby Vision (select titles)", "used_percent": 100},
            ],
            "help": "Perks included in your Premium plan.",
        },
    }


@app.post("/api/auth/login")
def login(payload: LoginRequest):
    user = users.get(payload.email)
    if not user or user["password"] != payload.password:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return {"access_token": payload.email, "user": {k: v for k, v in user.items() if k != "password"}}


@app.post("/api/auth/register")
def register(payload: RegisterRequest):
    if payload.email in users:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Account already exists")
    users[payload.email] = {
        "id": len(users) + 1,
        "name": payload.name,
        "email": payload.email,
        "password": payload.password,
        "plan": "Standard",
        "price": "$20/month",
        "renew_at": (datetime.today() + timedelta(days=30)).strftime("%b %d, %Y"),
    }
    billing_data[payload.email] = {
        "plan_name": "Standard",
        "price": "$20/month",
        "renew_at": (datetime.today() + timedelta(days=30)).strftime("%b %d, %Y"),
        "usages": [
            {
                "id": "video-quality",
                "label": "Video quality",
                "type": "feature",
                "value": "Full HD (1080p)",
                "help": "The best video resolution available on the Standard plan.",
            },
            {
                "id": "screens",
                "label": "Watch at the same time",
                "type": "feature",
                "value": "Can watch on 2 devices at once",
                "help": "Number of supported devices that can stream on your account simultaneously.",
            },
            {
                "id": "downloads",
                "label": "Download on devices",
                "type": "feature",
                "value": "Can download on 2 devices",
                "help": "Number of supported devices you can download titles to for offline viewing.",
            },
        ],
        "included_usage": {
            "title": "Plan perks",
            "items": [
                {"id": "ad-free", "label": "Ad-free streaming", "used_percent": 100},
                {"id": "spatial-audio", "label": "Spatial audio (select titles)", "used_percent": 100},
            ],
            "help": "Perks included in your Standard plan.",
        },
    }
    return {"access_token": payload.email, "user": {k: v for k, v in users[payload.email].items() if k != "password"}}


@app.get("/api/users/me")
def me(email: str):
    user = users.get(email)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    return {k: v for k, v in user.items() if k != "password"}


@app.get("/api/billing")
def billing(email: str):
    if email not in users:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    return billing_data.get(email, billing_data["tpg@example.com"])


@app.post("/api/billing/upgrade")
def upgrade_plan(payload: UpgradeRequest):
    user = users.get(payload.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    if user["plan"] == "Premium":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already on Premium plan")

    renew_at = str(user["renew_at"])
    prorated_charge = prorate(calculate_days_remaining(renew_at))
    profile = premium_billing_profile(renew_at)

    user["plan"] = "Premium"
    user["price"] = profile["price"]
    billing_data[payload.email] = profile
    return {**profile, "prorated_charge": prorated_charge}


# Serve the built frontend if it exists (production build)
dist_dir = Path(__file__).resolve().parent.parent / "frontend" / "dist"
if dist_dir.is_dir():
    app.mount("/", StaticFiles(directory=dist_dir, html=True), name="static")
