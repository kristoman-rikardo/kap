"""FMP (`stable`) API client (CP 3.1, 03 §4.1).

One responsibility: fetch robustly and within quota. All network and time are
injectable seams (`session`, `sleep`, `monotonic`) so the retry/backoff and
rate limiter are tested hermetically. 402 is a loud error, never a silent skip
— a silent skip would reintroduce survivorship bias unnoticed (03 §4.1).
"""

from __future__ import annotations

import logging
import time
from typing import Protocol

logger = logging.getLogger("kap.fmp")

_STABLE = "/stable"


class FMPError(Exception):
    """Base for all FMP client failures."""


class AuthError(FMPError):
    """401/403 — wrong key or plan."""


class PremiumGatedError(FMPError):
    """402 — endpoint requires a higher tier. Carries the path for the log."""

    def __init__(self, path: str) -> None:
        super().__init__(f"FMP-endepunkt krever høyere tier: {path}")
        self.path = path


class RateLimitError(FMPError):
    """429 persisted past max_retries."""


class FMPServerError(FMPError):
    """5xx persisted past max_retries."""


class _Session(Protocol):
    def get(self, url, params=None, headers=None, timeout=None): ...


class _TokenBucket:
    """Classic token bucket: refills continuously at `refill_per_sec`, caps at
    `capacity`. acquire() blocks (via the injected sleep) until a token is
    free. monotonic/sleep are injected so tests drive time deterministically."""

    def __init__(self, capacity: float, refill_per_sec: float, monotonic, sleep):
        self._capacity = capacity
        self._rate = refill_per_sec
        self._monotonic = monotonic
        self._sleep = sleep
        self._tokens = float(capacity)
        self._last = monotonic()

    def _refill(self) -> None:
        now = self._monotonic()
        self._tokens = min(
            self._capacity, self._tokens + (now - self._last) * self._rate
        )
        self._last = now

    def acquire(self) -> None:
        self._refill()
        if self._tokens < 1.0:
            self._sleep((1.0 - self._tokens) / self._rate)
            self._refill()
        self._tokens -= 1.0


class FMPClient:
    def __init__(
        self,
        key: str,
        base: str = "https://financialmodelingprep.com",
        calls_per_min: int = 700,  # 700 < 750-taket = margin (03 §4.1)
        max_retries: int = 5,
        backoff_base: float = 0.5,
        timeout: float = 30.0,
        session: _Session | None = None,
        sleep=time.sleep,
        monotonic=time.monotonic,
    ) -> None:
        if session is None:
            import requests

            session = requests.Session()
        self._key = key
        self._base = base.rstrip("/")
        self._session = session
        self._max_retries = max_retries
        self._backoff_base = backoff_base
        self._timeout = timeout
        self._sleep = sleep
        self._monotonic = monotonic
        self._bucket = _TokenBucket(
            capacity=calls_per_min,
            refill_per_sec=calls_per_min / 60.0,
            monotonic=monotonic,
            sleep=sleep,
        )

    def get(self, path: str, **params) -> list | dict:
        """GET `{base}/stable/{path}` with header auth, retrying transient
        failures. Returns parsed JSON; raises a typed FMPError otherwise."""
        url = f"{self._base}{_STABLE}/{path}"
        headers = {"apikey": self._key}
        for attempt in range(self._max_retries):
            self._bucket.acquire()  # each HTTP attempt spends one quota token
            started = self._monotonic()
            response = self._session.get(
                url, params=params, headers=headers, timeout=self._timeout
            )
            status = response.status_code
            logger.debug(
                "FMP %s -> %s (%.0f ms)",
                path,
                status,
                (self._monotonic() - started) * 1000,
            )
            if status == 200:
                return response.json()
            if status == 402:
                raise PremiumGatedError(path)
            if status in (401, 403):
                raise AuthError(f"FMP avviste nøkkelen ({status}) for {path}")
            if status == 429 or 500 <= status < 600:
                if attempt < self._max_retries - 1:
                    self._sleep(self._backoff_base * (2**attempt))
                    continue
                if status == 429:
                    raise RateLimitError(f"429 vedvarte for {path}")
                raise FMPServerError(f"{status} vedvarte for {path}")
            raise FMPError(f"Uventet status {status} for {path}")
        # Unreachable: the loop either returns or raises on the last attempt.
        raise FMPError(f"Ga opp {path} etter {self._max_retries} forsøk")
