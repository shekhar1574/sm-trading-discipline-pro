"""
Endpoints the Flutter app calls for Fyers integration.

  GET  /broker/fyers/login       -> redirects browser to Fyers login
  GET  /broker/fyers/callback    -> Fyers redirects here after login;
                                     we render a simple success page.
  POST /broker/fyers/callback    -> app calls this with the auth_code
                                     to complete the exchange (kept as
                                     a POST too so the Flutter client
                                     can drive it if you choose a
                                     webview flow instead of external
                                     browser).
  GET  /broker/fyers/positions   -> live open positions + P&L
"""
from fastapi import APIRouter, HTTPException, Header, Query
from fastapi.responses import RedirectResponse, HTMLResponse
from pydantic import BaseModel

from app.services import fyers_service

router = APIRouter()


class CallbackBody(BaseModel):
    auth_code: str


@router.get("/login")
def login():
    """Redirects the user's browser to Fyers' actual login page."""
    return RedirectResponse(fyers_service.build_login_url())


@router.get("/callback")
async def callback_redirect(auth_code: str = Query(default=None, alias="auth_code")):
    """
    Fyers redirects here after the user logs in, with ?auth_code=...
    in the query string. We complete the token exchange immediately and
    show a simple "you can return to the app" page — the Flutter app
    re-checks connection status via GET /broker/fyers/positions on next
    open (see BrokerConnectScreen's pull-to-refresh).
    """
    if not auth_code:
        return HTMLResponse("<h3>Login failed — no auth code received.</h3>", status_code=400)

    try:
        session_token = await fyers_service.exchange_auth_code_for_token(auth_code)
    except Exception as e:
        return HTMLResponse(f"<h3>Login failed: {e}</h3>", status_code=400)

    # In this Phase 1 scaffold we surface the session_token in the page
    # so it's visible during testing. For production, instead persist
    # it against the logged-in app user (once you add app auth) and
    # just show a plain success message here.
    return HTMLResponse(f"""
        <html><body style="font-family: sans-serif; text-align: center; padding-top: 60px;">
            <h2>✅ Fyers connected</h2>
            <p>You can close this window and return to SM Trading Discipline Pro.</p>
            <p style="color: #888; font-size: 12px;">session_token: {session_token}</p>
        </body></html>
    """)


@router.post("/callback")
async def callback_post(body: CallbackBody):
    """Alternative POST flow for a webview-driven callback instead of
    the redirect page above — returns JSON with the session_token."""
    try:
        session_token = await fyers_service.exchange_auth_code_for_token(body.auth_code)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    return {"session_token": session_token}


@router.get("/positions")
async def positions(authorization: str = Header(...)):
    """
    Expects: Authorization: Bearer <session_token>
    (the session_token the app received from /callback)
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer session token")

    session_token = authorization.removeprefix("Bearer ").strip()

    try:
        return await fyers_service.get_live_positions(session_token)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Fyers API error: {e}")
