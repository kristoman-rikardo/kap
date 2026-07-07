# Hjemskjerm: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A home screen that makes state visible: played/not-played today, streak, and session history read from the database.

**Architecture:** Pure streak function + `get_user_sessions` on the Repo protocol feed a new `GET /v1/me/stats`; Flutter gets a `HomeScreen` as app root with a state-aware daily card and history list, navigating to the existing DailyScreen.

**Tech Stack:** unchanged (FastAPI/psycopg, Flutter/freezed/Dio).

## Global Constraints

- Same as CP 2.3 (uv, mise exec, envelope, .env). Commit per task; push at the end.
- "Played today" = ≥1 session on today's live daily batch (free replay stays; enforcement is CP 4.2).

---

### Task 1: Backend — streak + sessions + `/v1/me/stats` (TDD)

**Files:** Create `backend/stats.py`, `backend/tests/test_stats.py`; Modify `backend/repo.py` (SessionRow + get_user_sessions on Repo/PgRepo), `backend/schemas.py` (MeStats, SessionSummary), `backend/main.py` (endpoint), `backend/tests/conftest.py` (FakeRepo.get_user_sessions from recorded sessions), `backend/tests/test_api.py` (stats endpoint tests).

**Interfaces produced:**
- `compute_streak(played: set[date], today: date) -> int`
- `SessionRow(session_id, batch_id, daily_date: date|None, submitted_at: datetime|None, score, bonus, hit_rate)`
- `Repo.get_user_sessions(user_id: str, limit: int = 20) -> list[SessionRow]`
- `GET /v1/me/stats` → `{"streak": int, "rounds_played": int, "daily_played_today": bool, "today_score": float|null, "recent": [{"session_id", "daily_date", "submitted_at", "score", "hit_rate"}]}`

Steps: failing streak tests (empty→0; {today}→1; {today,-1,-2}→3; gap {today,-2}→1; {-1,-2}→2 ends-yesterday; {-2,-3}→0) → implement → failing endpoint tests (401 without token; empty stats; after a golden submit: rounds_played 1, daily_played_today true, today_score ≈ −31.58, recent has 1 entry) → implement repo+endpoint → suite green → commit.

PgRepo SQL:
```sql
select s.id, s.batch_id, b.daily_date, s.submitted_at, s.score, s.bonus, s.hit_rate
from game_sessions s join game_batches b on b.id = s.batch_id
where s.user_id = %s order by s.submitted_at desc nulls last limit %s
```

### Task 2: Flutter — MeStats model + ApiClient.getStats

**Files:** Create `app/lib/models/me_stats.dart`; Modify `app/lib/services/api_client.dart`; test in `app/test/widget_test.dart` (fromJson mapping incl. null today_score).

`MeStats(streak, roundsPlayed, dailyPlayedToday, todayScore?, recent: List<SessionSummary>)`; `SessionSummary(sessionId, dailyDate?, submittedAt?, score?, hitRate?)`. `getStats()` → `GET /v1/me/stats`. Codegen via build_runner. Commit.

### Task 3: Flutter — HomeScreen as root

**Files:** Create `app/lib/screens/home_screen.dart`; Modify `app/lib/main.dart` (home: HomeScreen), `app/lib/screens/daily_screen.dart` (no changes needed beyond being pushable); widget tests.

HomeScreen: FutureBuilder on getStats; RefreshIndicator; sections: `_StatsStrip` (streak/rounds/today), `_DailyCard` (3 states; CTA pushes DailyScreen and reloads stats on return), `_RecentSessions` (up to 10 rows: date · score · hit%). Error view with retry (reuse pattern). Widget tests: not-played state shows CTA; played state shows score and "allerede spilt"; recent list renders rows. Commit.

### Task 4: E2E + push

Backend running → relaunch app → home shows current state (screenshot) → play a round on the simulator is manual; programmatic proof: submit via API as the simulator's user? No — use integration path: verify stats endpoint against hosted DB with a temp anon user (submit → stats reflect it). Screenshot home. Update memory. Push.
