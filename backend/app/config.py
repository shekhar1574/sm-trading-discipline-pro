"""
Configuration loaded from environment variables. Never commit real
credentials — set these in your hosting provider's dashboard
(Render/Railway/etc. all have an "Environment Variables" section).
"""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # From https://myapi.fyers.in/dashboard after registering an app.
    fyers_app_id: str = "YOUR_FYERS_APP_ID"          # e.g. "ABCD1234-100"
    fyers_secret_key: str = "YOUR_FYERS_SECRET_KEY"
    fyers_redirect_uri: str = "https://YOUR-BACKEND-URL.example.com/broker/fyers/callback"

    class Config:
        env_file = ".env"


settings = Settings()
