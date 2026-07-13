"""
SM Trading Discipline Pro — Backend (Phase 2)

Handles broker OAuth flows and live P&L fetching on behalf of the
Flutter app. Broker client secrets live here (as environment variables),
never inside the mobile app.

Run locally:
    pip install -r requirements.txt
    uvicorn main:app --reload

Deploy: see README.md for Render/Railway instructions.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import broker_fyers

app = FastAPI(
    title="SM Trading Discipline Pro API",
    description="Broker integration + live P&L backend",
    version="0.1.0",
)

# Locked down to the Flutter app's needs. If you add a web dashboard
# later, add its origin here instead of using "*".
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(broker_fyers.router, prefix="/broker/fyers", tags=["Fyers"])


@app.get("/")
def health_check():
    return {"status": "ok", "service": "sm-trading-discipline-pro-backend"}
