"""
Thin wrapper around Fyers API v3.

Reference (verify against Fyers' current docs before going live, as
broker APIs do change): https://myapi.fyers.in/docsv3

Auth flow:
  1. User is sent to Fyers' login URL (built in the router).
  2. Fyers redirects back to our /broker/fyers/callback with ?auth_code=...
  3. We exchange auth_code -> access_token via /validate-authcode,
     authenticating that exchange with sha256(app_id:secret_key).
  4. access_token is used as "APP_ID:access_token" in the Authorization
     header for subsequent Fyers API calls (positions, funds, etc).

Phase 1 scaffolding note: access tokens are held in-memory here
(SESSION_STORE) keyed by a random session_token we hand back to the
app. For production, replace SESSION_STORE with a real database
(Postgres) and encrypt tokens at rest — Fyers access tokens are
bearer credentials for the user's real trading account.
"""
import hashlib
import secrets
import httpx

from app.config import settings

FYERS_AUTH_BASE = "https://api-t1.fyers.in/api/v3"
FYERS_API_BASE = "https://api-t1.fyers.in/api/v3"

# TEMPORARY in-memory store: session_token -> fyers_access_token.
# Swap for a real DB before shipping to real users.
SESSION_STORE: dict[str, str] = {}


def build_login_url(state: str = "sm_trading_discipline_pro") -> str:
    return (
        f"{FYERS_AUTH_BASE}/generate-authcode"
        f"?client_id={settings.fyers_app_id}"
        f"&redirect_uri={settings.fyers_redirect_uri}"
        f"&response_type=code"
        f"&state={state}"
    )


async def exchange_auth_code_for_token(auth_code: str) -> str:
    """Exchanges a Fyers auth_code for an access_token, stores it under
    a fresh session_token, and returns that session_token to the app."""
    app_id_hash = hashlib.sha256(
        f"{settings.fyers_app_id}:{settings.fyers_secret_key}".encode()
    ).hexdigest()

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{FYERS_AUTH_BASE}/validate-authcode",
            json={
                "grant_type": "authorization_code",
                "appIdHash": app_id_hash,
                "code": auth_code,
            },
        )
        resp.raise_for_status()
        data = resp.json()

    access_token = data["access_token"]

    session_token = secrets.token_urlsafe(24)
    SESSION_STORE[session_token] = access_token
    return session_token


def _auth_header(access_token: str) -> dict:
    return {"Authorization": f"{settings.fyers_app_id}:{access_token}"}


async def get_live_positions(session_token: str) -> list[dict]:
    access_token = SESSION_STORE.get(session_token)
    if not access_token:
        raise ValueError("Session expired or invalid. Please reconnect Fyers.")

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{FYERS_API_BASE}/positions",
            headers=_auth_header(access_token),
        )
        resp.raise_for_status()
        data = resp.json()

    # Normalize Fyers' response shape into the flat structure the
    # Flutter app's BrokerPosition.fromJson expects.
    positions = []
    for p in data.get("netPositions", []):
        positions.append({
            "symbol": p.get("symbol", "UNKNOWN"),
            "quantity": p.get("netQty", 0),
            "avgPrice": p.get("avgPrice", 0.0),
            "lastTradedPrice": p.get("ltp", 0.0),
            "pnl": p.get("pl", 0.0),
            "segment": _segment_from_symbol(p.get("symbol", "")),
        })
    return positions


def _segment_from_symbol(symbol: str) -> str:
    upper = symbol.upper()
    if "FUT" in upper or "CE" in upper or "PE" in upper:
        return "F&O"
    if any(c in upper for c in ["USD", "EUR", "GBP", "JPY"]):
        return "Forex"
    if any(c in upper for c in ["BTC", "ETH", "USDT"]):
        return "Crypto"
    return "Equity"
