# 00_fremgangsmate.md – KAP: Fremgangsmåte (sjekkpunkt-drevet utvikling)

> Hvordan vi beveger oss framover. Dette er ikke en *hva-skal-bygges*-liste (det er Instructions §7 + specene 01–08), men en **rekkefølge** der hvert ledd er en tilstand du kan **kjøre og se**. Målet i hele dokumentet er MVP: **Dagens Runde** (Junior, daglig).

---

## Prinsippet: vertikalt skjelett først

I stedet for å bygge hele backenden, så hele API-et, så appen – og oppdage integrasjonsproblemene helt til slutt – reiser vi den **tynneste mulige ende-til-ende-tråden** først (appen åpner → API-et svarer → appen viser noe fra API-et), og **tykner så ett lag om gangen**. Hvert sjekkpunkt nedenfor er demobart: du kan kjøre det og bekrefte med øynene at det virker, før du går videre.

Den ene rekkefølge-beslutningen som gjør dette mulig: **bevis spill-loopen på *falske* data før datapipelinen er ekte.** Den tunge backenden (survivorship, point-in-time, leak-sjekk) er det største og mest risikofylte arbeidet. Ved å mate hardkodede kort inn i en ekte app + ekte scoringmotor allerede i Fase 1, ser du hele opplevelsen virke tidlig – og bytter så ut *kun datakilden* i Fase 3 uten å røre loopen.

**Arbeidsregel:** ett lag «i lufta» om gangen. Hvert sjekkpunkt = en commit du kan vende tilbake til. Kommer du deg ikke til neste sjekkpunkt, er feilen isolert til det laget du nettopp rørte.

---

## Fase 0 – Skjeletter som kjører

**CP 0.1 — Verktøy & repo**
Bygg: GitHub-repo, `.gitignore` (Python + Flutter), Python `venv`, kjør `flutter doctor`.
✓ **Sjekkpunkt:** `flutter doctor` uten røde kryss; repoet er pushet.

**CP 0.2 — Appen åpner seg** *(første ekte sjekkpunkt)*
Bygg: `flutter create kap`, kjør på simulator/enhet, rydd boilerplate til én blank skjerm med apptittelen.
✓ **Sjekkpunkt:** appen starter på telefonen/simulatoren og du ser KAP-skjermen. Ingen data, ingen logikk – bare at app-arkitekturen reiser seg.

**CP 0.3 — API-serveren åpner seg**
Bygg: FastAPI + `uvicorn`, ett `GET /health` → `{"status":"ok"}`.
✓ **Sjekkpunkt:** `curl localhost:8000/health` (eller nettleser) gir 200 + JSON.

**CP 0.4 — Appen snakker med API-et** *(første vertikale skive)*
Bygg: Dio-klient i Flutter som kaller `/health` og viser svaret på skjermen.
✓ **Sjekkpunkt:** endre teksten i API-svaret → se den endre seg i appen. Nå går én tråd hele veien fra skjerm til server.

---

## Fase 1 – Spill-loopen på falske data

**CP 1.1 — Falsk Dagens Runde**
Bygg: `GET /v1/daily` returnerer en **hardkodet** batch med 5 anonymiserte kort (JSON som matcher 05 §4.1). Flutter-modeller (`GameCard`, `DailyBatch`, freezed, 06 §4) + `GameCardView` rendrer dem.
✓ **Sjekkpunkt:** du swiper deg gjennom 5 (falske) kort i appen.

**CP 1.2 — Hele loopen, ende-til-ende (falsk)**
Bygg: swipe samler valg → `POST /v1/batches/{id}/submit` returnerer en **hardkodet** reveal (navn, alpha, ideal). Reveal-skjerm med flip + graf-stubb.
✓ **Sjekkpunkt:** swipe 5 → submit → se reveal-skjermen. Loopen funker visuelt før noe er ekte.

**CP 1.3 — Ekte scoringmotor på falske kort**
Bygg: implementer **01** som en ren funksjon; enhetstest mot golden fixtures (01 §3.3). Koble den inn i submit, slik at de falske kort-alphaene gir en *korrekt beregnet* score.
✓ **Sjekkpunkt:** `pytest` grønn på fixturene; submit returnerer riktig score for fixture-batchen. (Nå er loopen + scoringen ekte; kun *dataene* er falske.)

---

## Fase 2 – Database & auth

**CP 2.1 — Database reist**
Bygg: Supabase-prosjekt + første migrasjon (hele 02-skjemaet; Alembic eller Supabase migrations).
✓ **Sjekkpunkt:** tabellene finnes; du kan `insert` en rad og lese den tilbake.

**CP 2.2 — Anonym auth + JWT**
Bygg: Supabase anonym sesjon i appen → JWT; FastAPI verifiserer signaturen mot JWKS (05 §3).
✓ **Sjekkpunkt:** appen får et token; API-et gir `401` på ugyldig token og `200` på gyldig.

**CP 2.3 — Loopen kjører mot DB (seed-univers)**
Bygg: seed fixture-universet (02 §15: 5–10 selskaper inkl. ett delistet og ett oppkjøpt, samme tall som golden fixtures) inn i DB. Submit leser nå `batch_cards` fra DB i stedet for hardkodet JSON, og logger `game_sessions`/`decisions`.
✓ **Sjekkpunkt:** loopen går mot databasen; du kan spørre opp dine egne valg etterpå. RLS testet (du ser kun dine egne rader).

---

## Fase 3 – Ekte datapipeline (bytt seed med FMP-data)

Det tunge laget. Hvert steg er sitt eget sjekkpunkt så feil isoleres. (Du har allerede probet FMP – `fmp_api_questions.md` – så feltene er kjente.)

**CP 3.1 — FMP-klient**
Bygg: 03 §4.1 – token-bucket 700/min, backoff på 429/5xx, `402 → PremiumGatedError`, `401 → AuthError`.
✓ **Sjekkpunkt:** et kall henter AAPL income-statement; en bevisst gated forespørsel gir riktig `PremiumGatedError` (ikke stille skip).

**CP 3.2 — Universbygger (survivorship)**
Bygg: S1 – rekonstruér medlemskap fra `historical-sp500-constituent` (spol endringer bakover).
✓ **Sjekkpunkt:** `universe(2016-01-04)` inneholder **minst ett selskap som senere ble delistet** (survivorship-røyktesten, 03 §9). Uten dette lekker dagens-liste-bias inn.

**CP 3.3 — Finans + kurser (point-in-time)**
Bygg: S3/S4 for et lite univers – statements m/ `filingDate`, TR-justerte kurser (`dividend-adjusted`, `from/to`), trunkér delistede på `delisted_date` per `company_id`.
✓ **Sjekkpunkt:** 02 §6.2-spørringen returnerer **kun** rader med `filing_date ≤ decision_date`; `coverage_ok(...)` passerer for en valgt dato.

**CP 3.4 — Benchmark + risikofri**
Bygg: S5 – SPY `adjClose` (TR-proxy), `treasury-rates.month3` (husk: prosent → `/100`).
✓ **Sjekkpunkt:** SPY-serie lastet tilbake til 1993; `R_m/r_m/R_f/r_f/alpha_cash` fryses på en testbatch.

**CP 3.5 — Makro + narrativer + leak-sjekk**
Bygg: S6 (bånd-makro) + S7 (LLM-narrativ + **adversariell** leak-dommer, 03 §7.2).
✓ **Sjekkpunkt:** et generert narrativ består leak-dommeren; ett som navngir et produkt blir underkjent og regenerert.

**CP 3.6 — Curator seler en ekte batch**
Bygg: 04 – stratifisert-med-gulv-trekning, deterministisk seed, seal (pris-avhengige felt + fasit + frys).
✓ **Sjekkpunkt:** samme seed → **bit-identisk** batch (determinisme); batchen har ≥1 vinner og ≥1 taper; «long alt» gir negativ score.

---

## Fase 4 – Dagens Runde & MVP-finish

**CP 4.1 — Dagens Runde-jobb + menneske-i-loop**
Bygg: cron som seler én global batch/dag (`seed = dato`), 7-dagers ledetid, din godkjenning `sealed → live` (04 §9).
✓ **Sjekkpunkt:** morgendagens daily finnes som `sealed`; du godkjenner den; den blir `live`.

**CP 4.2 — Ekte Dagens Runde i appen**
Bygg: `/v1/daily` server den ekte daily; ett-forsøk-per-bruker (02 §9); `already_played` kortslutter til reveal.
✓ **Sjekkpunkt:** du spiller dagens runde, kan ikke spille på nytt, og ser ditt eget reveal.

**CP 4.3 — Sosialt + onboarding + Kartotek-frø**
Bygg: delingskort (emoji-grid 🟩🟥⬜ + alpha + streak), streak-teller, onboarding-overlay (makro-boks, alpha, cash-regel), kunnskapsnivå-velger, og «frøet» til Kartoteket (den enkle selskapssiden reveal lenker til, 06 §10 / 07).
✓ **Sjekkpunkt:** du genererer et delbart resultatkort; streaken øker; «Utforsk selskapet» åpner en selskapsside.

**CP 4.4 — Soft launch**
Bygg: E2E-gjennomgang, `.apk` + iOS-simulator, «ikke investeringsråd»-disclaimer.
✓ **Sjekkpunkt:** en venn spiller dagens runde på sin egen telefon.

---

## Etter MVP (gatet bak bevist retention)

Bygg disse først når kjerneloopen har vist at folk kommer tilbake. Hver har allerede sin spec:
* **Manager Mode** – porteføljevekting, IR/Sharpe-attribusjon (01 §4, 04 §12).
* **Kartoteket (fullt)** – decks, dekningsmetere, gjettemodus, deep-dive (07). *Kan utvides til OBX tidlig – verifiser FMP-dekning for `.OL` først (07 §13).*
* **Real-Time Mode** – løpende anonymisert portefølje på etterslept klokke, earnings-kalibrering (08). Egen app i praksis; sist.
* **Din investorprofil** – analyse av `decisions` mot kort-features (Instructions §8).

---

## Hvorfor denne rekkefølgen virker

* **Tidlig synlighet:** etter Fase 1 har du en app du kan vise fram – hele loopen, ekte scoring, kun falske data. Det er motiverende og avdekker UX-problemer før du har brukt uker på backend.
* **Isolerte feil:** ett lag om gangen betyr at når noe brekker, vet du hvilket lag det var.
* **De-risket tungt arbeid:** datapipelinen (det vanskeligste) bygges bak et grensesnitt loopen allerede bruker – du bytter datakilde, ikke arkitektur.
* **Alltid demobar:** hvert sjekkpunkt er en commit-bar, kjørbar tilstand. Du står aldri med et halvt system som ikke starter.