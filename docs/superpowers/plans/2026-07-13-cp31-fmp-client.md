# CP 3.1 — FMP-klient: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A robust, quota-aware FMP client: real AAPL income-statement works; a gated request raises PremiumGatedError.

**Architecture:** One `backend/fmp.py` module — error hierarchy + `FMPClient.get` with a token-bucket limiter and exponential backoff, all network/time behind injectable seams for hermetic tests.

**Tech Stack:** requests (already a dep), pytest.

## Global Constraints

- `uv add`; tests `uv run pytest backend/tests/ -q`. Commit per task; push at end.
- Header auth `apikey:`; key from `FMP_API_KEY` (.env, gitignored).
- Rate limit 700/min (< 750 cap); backoff on 429/5xx max 5; 402→PremiumGatedError; 401/403→AuthError.

---

### Task 1: Error hierarchy + get() happy/gated/auth paths (TDD)

**Files:** Create `backend/fmp.py`, `backend/tests/test_fmp.py`.

**Interfaces produced:**
- `FMPError(Exception)`; `AuthError(FMPError)`; `PremiumGatedError(FMPError)` with `.path`; `RateLimitError(FMPError)`; `FMPServerError(FMPError)`.
- `FMPClient(key, base="https://financialmodelingprep.com", calls_per_min=700, max_retries=5, session=None, sleep=time.sleep, monotonic=time.monotonic)`
- `FMPClient.get(path, **params) -> list | dict` — GETs `{base}/stable/{path}`, header `apikey`, params passed through, returns parsed JSON.

**Test doubles:**
```python
class FakeResponse:
    def __init__(self, status_code, json_data): self.status_code=status_code; self._j=json_data
    def json(self): return self._j

class FakeSession:
    """Returns queued responses in order; records requests."""
    def __init__(self, responses): self._responses=list(responses); self.calls=[]
    def get(self, url, params=None, headers=None, timeout=None):
        self.calls.append({"url":url,"params":params,"headers":headers})
        return self._responses.pop(0)
```

- [ ] Step 1: Write failing tests — `_client(responses)` helper builds `FMPClient(key="k", session=FakeSession(responses), sleep=lambda _:None, monotonic=<fake>)`.
  - `test_get_returns_json_on_200`: 200 `[{"symbol":"AAPL"}]` → returns that list; asserts url endswith `/stable/income-statement`, header `apikey`=="k", params include symbol.
  - `test_402_raises_premium_gated`: 402 → `PremiumGatedError`, `exc.path=="earning-call-transcript"`.
  - `test_401_raises_auth`: 401 → `AuthError`.
  - `test_403_raises_auth`: 403 → `AuthError`.
- [ ] Step 2: Run → fail (module missing).
- [ ] Step 3: Implement error classes + `get` (no retry/limiter yet — just status dispatch + header + url build). Use an internal `_perform` that does one request.
- [ ] Step 4: Run → pass.
- [ ] Step 5: Commit `CP 3.1 (part 1): FMP client core — status dispatch, gated/auth errors`.

### Task 2: Retry with exponential backoff (429/5xx)

**Files:** Modify `backend/fmp.py`, `backend/tests/test_fmp.py`.

- [ ] Step 1: Failing tests (inject `sleep` recorder):
  - `test_retries_on_429_then_succeeds`: [429, 429, 200-data] → returns data; sleep called twice; backoff doubles (assert recorded sleeps == [base, base*2]).
  - `test_429_exhausted_raises_rate_limit`: max_retries=3 → [429,429,429] → `RateLimitError`.
  - `test_500_retried_then_raises_server_error`: [500,500,500] (max_retries=3) → `FMPServerError`; and `[503,200]`→data.
- [ ] Step 2: Run → fail.
- [ ] Step 3: Wrap `_perform` in a retry loop: on 429/5xx sleep `backoff_base * 2**attempt` (backoff_base config, default e.g. 0.5) then retry; after max_retries raise RateLimitError (429) / FMPServerError (5xx). 402/401/403/200 return/raise immediately (no retry).
- [ ] Step 4: Run → pass.
- [ ] Step 5: Commit `CP 3.1 (part 2): exponential backoff on 429/5xx`.

### Task 3: Token-bucket rate limiter

**Files:** Modify `backend/fmp.py`, `backend/tests/test_fmp.py`.

- [ ] Step 1: Failing tests using a fake clock (mutable `[t]`) and sleep that advances it:
  - `test_bucket_allows_burst_up_to_capacity`: calls_per_min=60 (1/sec, capacity 60); 60 immediate calls consume no sleep; the 61st with empty bucket sleeps until a token refills.
  - `test_sleep_advances_and_refills`: after sleeping, a token is available and the call proceeds; total sleep ≈ expected refill interval.
  - Keep it deterministic: sleep(dt) does `clock[0]+=dt`.
- [ ] Step 2: Run → fail.
- [ ] Step 3: Implement `_TokenBucket(capacity, refill_per_sec, monotonic, sleep)`: on `acquire()`, refill by elapsed*rate (cap at capacity), if <1 token sleep for the deficit time then refill; consume 1. Call `acquire()` at the start of each `get`.
- [ ] Step 4: Run → pass.
- [ ] Step 5: Commit `CP 3.1 (part 3): token-bucket rate limiter (700/min)`.

### Task 4: Integration checkpoint (env-gated) + push

**Files:** Create `backend/tests/test_fmp_integration.py`.

- [ ] Step 1: Env-gated (skip unless FMP_API_KEY; dotenv):
  - `test_income_statement_real`: `FMPClient(key).get("income-statement", symbol="AAPL", period="annual", limit=1)` → non-empty list, row has `filingDate` and `revenue`.
  - `test_gated_endpoint_raises`: `.get("earning-call-transcript", symbol="AAPL", year=2023, quarter=1)` → `PremiumGatedError`.
- [ ] Step 2: Run against real FMP → pass (this is the checkpoint).
- [ ] Step 3: Full suite green; commit `CP 3.1 (part 4): live FMP checkpoint — income-statement works, gated raises`; `git push`.
- [ ] Step 4: Update memory (Fase 3 started, FMP key in .env, client at backend/fmp.py).
