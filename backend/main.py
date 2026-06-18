"""KAP backend — FastAPI application.

CP 0.3: the thinnest possible server. A single health endpoint so the Flutter
client can confirm it reaches the API end-to-end (CP 0.4) before any game
logic, auth, or database exists. The real endpoints (`/v1/daily`, submit, etc.)
are specced in 05_api.md and arrive in later phases.
"""

from fastapi import FastAPI

app = FastAPI(title="KAP API", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    """Liveness probe — returns 200 with a small JSON body."""
    return {"status": "ok"}
