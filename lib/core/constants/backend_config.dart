/// Points the app at your deployed FastAPI backend (see /backend in the
/// project root). Broker OAuth flows (Fyers, and later Zerodha/Angel
/// One/etc.) must go through a real server because:
///   1. The broker needs a public HTTPS redirect URL to send the user
///      back to after login — a phone app alone can't receive that.
///   2. Client secrets must never live inside the mobile app itself.
///
/// Update [baseUrl] once you've deployed backend/ (see backend/README.md
/// for Render/Railway instructions). Until then, broker features will
/// show a "not configured" state instead of crashing.
class BackendConfig {
  BackendConfig._();

  static const String baseUrl = 'https://YOUR-BACKEND-URL.example.com';

  static bool get isConfigured => !baseUrl.contains('YOUR-BACKEND-URL');
}
