# SM Trading Discipline Pro — Backend

Handles the Fyers OAuth handshake and live position fetching. This
**must** run on a real server with a public HTTPS URL — Fyers needs
somewhere real to redirect the user back to after login, and your
Fyers app secret needs to live somewhere other than the phone app.

## 1. Register a Fyers API app (you'll need a Fyers trading account)

1. Go to https://myapi.fyers.in/dashboard
2. Create a new app. You'll get:
   - **App ID** (looks like `ABCD1234-100`)
   - **Secret Key**
3. Set the **Redirect URL** to (fill in your deployed backend URL once you have it — step 2):
   ```
   https://YOUR-BACKEND-URL.example.com/broker/fyers/callback
   ```

## 2. Deploy this backend (Render — free tier works for testing)

1. Push this `backend/` folder to its own GitHub repo (or a subfolder of your existing one — Render lets you set a root directory).
2. Go to https://render.com → **New** → **Web Service** → connect your repo.
3. Settings:
   - **Root Directory**: `backend` (if it's a subfolder)
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
4. Add environment variables (Render → your service → **Environment**):
   ```
   FYERS_APP_ID=ABCD1234-100
   FYERS_SECRET_KEY=your_secret_key_here
   FYERS_REDIRECT_URI=https://your-actual-render-url.onrender.com/broker/fyers/callback
   ```
5. Deploy. Render gives you a URL like `https://sm-trading-backend.onrender.com`.
6. Go back to the Fyers dashboard (step 1) and update the Redirect URL to match your real Render URL exactly.

(Railway, Fly.io, or a plain VPS work the same way — any host that runs a Python web process with a public HTTPS URL is fine.)

## 3. Point the Flutter app at your backend

Edit `lib/core/constants/backend_config.dart`:
```dart
static const String baseUrl = 'https://sm-trading-backend.onrender.com';
```
Rebuild the APK (push to GitHub, let the Actions workflow build it again).

## 4. Test it

```bash
curl https://your-backend-url.onrender.com/
# should return {"status":"ok","service":"sm-trading-discipline-pro-backend"}
```

Then in the app: Dashboard → **Connect Broker** → **Connect** next to Fyers. It opens Fyers' login page in your browser; after logging in, Fyers redirects back to your backend, which completes the token exchange.

## Local development

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env   # fill in your real Fyers credentials
uvicorn main:app --reload
```
Interactive API docs at `http://localhost:8000/docs`.

## Security notes (read before connecting a real trading account)

- **`SESSION_STORE` in `fyers_service.py` is in-memory** — it resets on every server restart/redeploy, and holds real Fyers access tokens as plain strings. Before connecting a real account with real money, replace it with a proper database (Postgres) with tokens encrypted at rest.
- There's no app-level user authentication yet (single-user scaffold, matching Phase 1 of the Flutter app). If you add multi-user support, tie `SESSION_STORE` entries to authenticated app users, not just a random token.
- Fyers access tokens are typically valid for one trading day — you'll need to re-login each morning until a token-refresh flow is added.
- Verify the exact Fyers API v3 endpoint paths/response shapes against https://myapi.fyers.in/docsv3 before going live — broker APIs change, and `fyers_service.py` was written from general API v3 patterns, not tested against a live Fyers account.
