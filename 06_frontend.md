# 06_frontend_gameloop.md – KAP Spesifikasjon: Frontend & Game Loop (Flutter)

> **Dokumentserie:** `01_scoring` ✓ · `02_datamodell` ✓ · `03_data_pipeline` ✓ · `04_curator` ✓ · `05_api` ✓ · **`06_frontend_gameloop` (dette)** · `07_kartoteket` · `08_realtime`
> Dekker Flutter-appen for **MVP: Dagens Runde + vanlig Junior**. Manager, Kartoteket og Real-Time rammes inn lett (§16) og spec'es i egne revisjoner. Modellene/flyten speiler API-kontrakten i 05 §4 og reveal-kontrakten i 01 §7.

---

## 1. Designprinsipper

1. **Engasjerende spill, men ikke en spilleautomat.** Det bærende skillet er smalt og hardt: **ingen utfallsfeedback under blind seleksjon.** En tikkende P&L mens du velger ville latt deg jage utfallet – nettopp biaset den blinde runden fjerner (Instructions §1, Buffett-skolen). Alt *rundt* seleksjonen skal derimot være tilfredsstillende og belønnende: vektige swipe-tilbakemeldinger, reveal-flippen, en score som teller opp, streak-feiring, delingskortet. Linjen går ikke mellom «rolig» og «spennende», men mellom *å belønne innsikt* og *å fabrikkere hastverk eller falske live-innsatser*. Målgruppen er både bankfolk og ungdom – det skal føles polert og morsomt, ikke sterilt og ikke kasino. Reward-animasjoner (dopamin med smak) hører hjemme i reveal/streak; den blinde runden forblir utfallsfri.
2. **Swipe-muskelminne deles på tvers av moduser.** Høyre/venstre/opp betyr det samme i Junior, Manager og (senere) Kartoteket. Lær det én gang.
3. **Anonymitet håndheves også i klienten.** Klienten *kan ikke* vise det den ikke har: `GET`-svar inneholder ingen ticker/navn/epoke (05 §5). Reveal-data finnes først etter submit. Frontend skal aldri logge eller cache reveal-felt på en måte som lekker før tid.
4. **Progressiv avsløring av kompleksitet.** Fagbegrep er tap-for-å-utvide, og definisjonsdybden styres av `knowledge_level` (Instructions §3, §6). Nybegynneren drukner ikke; eksperten slipper noobfakta.
5. **Offline-tålig og tilstandsærlig.** Dagens Runde-kortene caches lokalt (de er uforanderlige, 05 §5). Hver skjerm har eksplisitt loading-, tom- og feiltilstand (shimmer, ikke blank skjerm).
6. **Tilgjengelig som standard.** `Semantics` på swipe-handlinger og kort, kontrast som holder i både lys og mørk modus, skjermleser-vennlige etiketter.

## 2. Stack & konvensjoner

* **Flutter 3.x / Dart**, **Riverpod** (state), **GoRouter** (navigasjon), **Dio** (HTTP), **flutter_card_swiper** (swipe), **fl_chart** (grafer), **cached_network_image** + **shimmer** (bilder/lasting), **freezed** + **json_serializable** (modeller).
* **Design-konvensjonskilde – `flutter-ai-ui-skill`:** brukes når frontend bygges med Claude Code. Installasjon (fra repoets README): `curl -sSL <repo>/…/ai_flutter_skill_ui_3.4.zip | sh -s -- --ai claude`, deretter legg `.claude/skills/flutter-ai-ui-skill/SKILL.md` til `CLAUDE.md`. Den bidrar med: Material 3 + `ColorScheme` + dark mode, `const`-konstruktører / `ListView.builder` / uttrukne widgets, `Semantics`-tilgjengelighet, `CachedNetworkImage`/shimmer/feiltilstander, GoRouter + Riverpod, animasjons- og komponent-blueprints, og en prosjekt-analysator (`analyse_flutter_project.py`) som flagger anti-mønstre (hardkodede farger, `setState` i `build`, `StatefulWidget`-andel > 30 %).
  * *Forbehold:* tredjeparts-community-skill med lav adopsjon; installasjonen piper et fjernarkiv til `sh`. **Gjennomgå innholdet før du installerer.** Vi bruker den for *ingeniørkonvensjonene* (som er standard god praksis), ikke som autoritativ sannhet, og vi **avviker bevisst fra de dopamin-tunge stilene** (Dark Neon, glødende effekter) – se §1 og §14.

## 3. Prosjektstruktur

```
lib/
  main.dart
  app.dart                 # MaterialApp.router + tema + GoRouter
  theme/                   # ColorScheme (lys/mørk), TextTheme, tokens — ingen hardkodede hex i widgets
  models/                  # GameCard, DailyBatch, Reveal, CompanyProfile (freezed)
  services/                # ApiClient (Dio), AuthService (Supabase), shareService, hapticsService
  providers/               # Riverpod: auth, daily, gameSession, submit, streak, knowledgeLevel
  screens/                 # daily, game, reveal, company, onboarding, stats
  widgets/                 # GameCardView, MacroBox, FundamentalsTable, SwipeOverlay,
                           # ResultChart, RevealCardTile, ShareCard, TermChip
  routing/                 # go_router-konfig
```

## 4. Datamodeller (Dart, speiler 05 §4)

```dart
enum Choice { long, short, cash }          // swipe: høyre/venstre/opp

@freezed class MacroBox with _$MacroBox {
  const factory MacroBox({
    required String rateLevel,             // 'lav'|'nøytral'|'høy'
    required String rateDirection,         // 'stigende'|'flat'|'fallende'
    required String inflationBand,         // bånd, ikke tall (04 §5.7)
    required String gdpBand,
    required String sectorSentiment,
  }) = _MacroBox;
  factory MacroBox.fromJson(...) ...;
}

@freezed class Fundamentals with _$Fundamentals {
  const factory Fundamentals({
    double? pe,                            // null/'neg.' håndteres i UI (04 §5.2)
    required double ps, required double debtToEquity,
    required double grossMargin, required double operatingMargin,
    required double netMargin, required double roic,
  }) = _Fundamentals;
}

@freezed class GameCard with _$GameCard {
  const factory GameCard({
    required int cardNo,
    required MacroBox macro,
    required Fundamentals fundamentals,
    required double revCagr3y, required double epsCagr3y,
    required String cap,                   // 'small'|'mid'|'large' (bånd, 04 §5.2)
    required String sectorCoarse,
    required String narrative,             // anonymisert (ingen navn/ticker)
    required String sectorSentiment,
  }) = _GameCard;                          // MERK: ingen ticker/navn/decision_date
}

@freezed class DailyBatch with _$DailyBatch {
  const factory DailyBatch({
    required int batchId, required String mode, required bool isDaily,
    String? dailyDate, required int horizonYears,
    required Intro intro,                  // markedssentiment + rentebilde (batch-nivå)
    required List<GameCard> cards,
    @Default(false) bool alreadyPlayed,
    Reveal? reveal,                        // satt hvis alreadyPlayed
  }) = _DailyBatch;
}

@freezed class Decision with _$Decision {
  const factory Decision({ required int cardNo, required Choice choice,
                           double? weight, int? responseMs }) = _Decision;   // weight: Manager-only
}

// Reveal (kun fra POST submit; 01 §7)
@freezed class RevealCard with _$RevealCard {
  const factory RevealCard({
    required int cardNo, required String ticker, required String name,
    required Choice choice, required double r, required double alpha,
    required double a, required double points, required String clue,
    String? event, required int companyId,
  }) = _RevealCard;
}
@freezed class Reveal with _$Reveal {
  const factory Reveal({
    required int sessionId, required double score, required double bonus,
    required double hitRate, required Benchmark benchmark,
    required String decisionDate, required int horizonYears,
    required List<RevealCard> cards, required Ideal ideal,
    ManagerExtra? managerExtra,
  }) = _Reveal;
}
```

## 5. API-klient & auth

* **AuthService (Supabase):** start anonym sesjon (device-basert) → JWT (05 §3). Persistér sesjonen; tilby «oppgrader til konto» senere uten å miste `user_id`/streak.
* **ApiClient (Dio):** base `…/v1`. Interceptor legger `Authorization: Bearer <jwt>` på hver request og frisker token ved utløp. Feil-mapping → typede exceptions:
  * `401` → re-auth; `409 DAILY_ALREADY_PLAYED` → vis eksisterende reveal (ikke feil); `429` → «prøv igjen om litt»; `5xx`/nett → retry-knapp.
* **Kontrakt:** `GET /v1/daily` og `/v1/practice` gir kort *uten* truth; `POST /v1/batches/{id}/submit` returnerer reveal. Klienten har ingen annen vei til navn/fasit (05 §5).

## 6. State (Riverpod)

```dart
authProvider            // AuthState (anonym/konto), JWT
knowledgeLevelProvider  // beginner|intermediate|expert -> definisjonsdybde
dailyProvider           // FutureProvider<DailyBatch>  (GET /daily; cache-aware)
gameSessionProvider     // StateNotifier<GameLoopState>  (in-progress valg)
submitProvider          // sender valg -> Reveal
streakProvider          // streak + neste-runde-nedtelling
```

## 7. Game loop (statemaskin)

`GameLoopState` styres av en `StateNotifier` (04/05-flyten):

```
loading ─► ready ─► playing(n/5) ─► submitting ─► reveal
   │                    │
   │ (GET /daily)       │ swipe registrerer Decision(cardNo, choice, responseMs)
   │                    │ ved n==5: POST submit
   └─ alreadyPlayed ───────────────────────────────► reveal (kortslutter)
```

* Hvert kort timer `responseMs` (analytics, 02 §9) fra det vises til swipe.
* «Angre siste swipe» tillates frem til innsending (flutter_card_swiper støtter undo).
* Submit er idempotent (05 §4.3): re-forsøk på samme daily gir samme reveal.

## 8. Kortanatomi (GameCardView)

Tre lag (Instructions §3), fargekodet og rolig:

* **Makro-boks (øverst):** rentenivå/-retning, inflasjons-/BNP-**bånd** (ikke tall, 04 §5.7), sektorsentiment. Fargekode etter regime (f.eks. dempet blå = lavrente, dempet rav = høy/stigende) – *aldri* alarmrødt. Introkortet (batch-nivå) vises før kort 1.
* **Fundamentale tall:** P/E (vis «neg.» ved negativ EPS), P/S, gjeld/EK, marginer, ROIC, 3-års CAGR, cap-kategori. Tydelig tabell-typografi.
* **Narrativ:** 2 setninger, anonymisert. Ingen ticker/navn (modellen har dem ikke).
* **Fagbegrep (`TermChip`):** tap utvider definisjon; dybde fra `knowledgeLevelProvider`.
* **Tilgjengelighet:** `Semantics(label: "Kort 3 av 5. Sveip høyre for long, venstre for short, opp for cash.")`.

## 9. Swipe-mekanikk

* `flutter_card_swiper`: **høyre = Long, venstre = Short** via sveip. **Cash velges med knapp**, ikke opp-sveip: den vertikale aksen er reservert for å *scrolle* det tallrike kortet (som kan være høyere enn skjermen på mindre enheter). Overlay-etikett under draget («LONG»/«SHORT»).
* **Nøytral knapperad (Short / Cash / Long, Cash mest fremtredende):** lett tilgjengelig betjening ved siden av sveipene. Knappene går gjennom samme `onSwipe`-håndtering; Cash-knappen setter en `_pendingChoice` som `onSwipe` leser, så kortet animeres ut horisontalt men registreres som Cash. Fargenøytral under blind spilling – ingen rød/grønn (§1/§14).
* Haptisk feedback + lyd ved valg (whoosh) – tilfredsstillende, men ikke kasino. Reward-lydene kan være tydeligere i reveal/streak enn under selve seleksjonen (jf. §1).
* Teller «n/5» synlig. Manager-vekting skjer *ikke* per swipe (det er en egen bekreftelses-skjerm, 04 §12 / 01 §2B) – Junior er ren sveiping.

## 10. Resultat & reveal

* **Score = alpha mot indeks** (01 §3), aldri presentert som «du tjente X kr». Tekstfeedback skaleres etter alpha (oppmuntring/gratulasjon/terging, 01-stil) – men i tråd med §1: feire innsikt, ikke flaks.
* **Graf (fl_chart):** «Din portefølje» vs «Indeks» over horisonten; Manager legger til likevekts-varianten (01 §4.4).
* **Reveal per kort (`RevealCardTile`):** flip-animasjon → «Det var Tesla! Du valgte Short. −180 %-poeng alpha.» + clue-setning + `event`-merke + **«Utforsk selskapet»** → company-skjerm (frø til Kartoteket, 05 §4.4). Dette er eneste sted truth vises.
  * **Cash-treffmerke (01 §6.6):** valgte du cash på et kort med negativ absoluttavkastning, vis et eget ✓-«unngått tap»-merke ved siden av (de negative) alpha-poengene – en psykologisk bekreftelse adskilt fra scoren. Cash på en stiger merkes «mistet oppgang».
  * **Event-framing:** `event:"acquired"` på en *short* rammes inn som short-squeeze («Shorten din ble squeezet – selskapet ble kjøpt opp med premie»); på en *long* som gevinst. `event:"delisted"` → konkurs.
* **Idealportefølje** vises eksplisitt som etterpåklokskap (01 §8), inkl. cash-nyansen begge veier («cash kostet X %/år i et stigende marked» / «cash bevarte kapital da aksjen falt»).

## 11. Delingskort (ShareCard) – Wordle-mekanikken

* Generér et delbart kort: emoji-grid **🟩 (riktig retning) / 🟥 (feil) / ⬜ (cash)** + alpha mot indeks + streak – **uten** å avsløre selskapene (Instructions §2E, 04 §7).
* Render som bilde (for Instagram/Snap) og som tekst (for meldinger). Sosialt objekt, organisk distribusjon.

## 12. Dagens Runde-flyt & streak

* Ett forsøk per dag (05 §4.1). Har brukeren spilt → `alreadyPlayed` kortslutter til reveal + nedtelling til neste runde.
* **Streak-teller** + lokal notifikasjon «Dagens Runde er klar» (ikke mas; én rolig påminnelse). Streak feires nøkternt.
* Vanlig Junior (øving) tilgjengelig ved siden av (05 §4.2) for de som vil spille mer.

## 13. Onboarding

* Førstegangs-overlay forklarer: makro-boksen, **alpha-scoringen** (hvorfor «long alt» ikke vinner), og cash-regelen. Kort, vis-ikke-fortell.
* **Kunnskapsnivå-velger** (beginner/intermediate/expert) → `knowledgeLevelProvider`, styrer definisjonsdybde overalt.

## 14. Estetisk retning

* **Polert fintech med smakfull juice, ikke kasino.** Fra `flutter-ai-ui-skill`: bruk en fintech-palett og *Minimal Flat*/*Enterprise Dark*-sjangrene; **unngå** Dark Neon / glødende effekter som signaliserer hype. Material 3 (`ThemeData(useMaterial3: true)`, `ColorScheme.fromSeed`) med innebygd dark mode. **Reward-motion er tillatt og ønsket** i reveal og streak (flip, opptelling, nøktern feiring); den blinde seleksjonen holdes bevisst utfallsfri og rolig (§1).
* **Farge med omhu:** rød/grønn brukes kun i *reveal* (utfall), aldri som angst-skapende live-signal. Under blind spilling finnes ingen utfallsfarge – det er en feature (§1).
* **Typografi:** ett tydelig, seriøst fontpar (skillets `flutter_typography.csv` har ferdige par); rikelig med pust/spacing.

## 15. Ytelse & tilgjengelighet (skill-retningslinjer)

* `const`-konstruktører, `ListView.builder`, uttrukne widgets; hold `StatefulWidget`-andel < 30 % (skillets analysator flagger dette).
* `CachedNetworkImage` for evt. bilder; **shimmer** som lastetilstand; eksplisitte feil-/tom-tilstander.
* `Semantics` på interaktive elementer; kontrast i lys/mørk; respekter systemets tekststørrelse.
* Kjør `analyse_flutter_project.py` før hver milepæl for å fange anti-mønstre.

## 16. Senere moduser (innramming)

* **Manager:** samme kort + swipe, men en **«Bekreft portefølje»-skjerm** med vekting (slider per long/short, rest i cash) før innsending (01 §2B, 04 §12). Resultatet viser IR/Sharpe + attribusjon (01 §4).
* **Kartoteket (07):** gjenbruker `GameCardView`/swipe, men ikke-anonymisert; samlingsmekanikk, dekningsmetere, gjettemodus.
* **Real-Time (08):** løpende portefølje, earnings-varsler.

## 17. Grensesnitt mot nabo-specs

* **← 05_api:** alle kall mot `/v1`; modellene speiler §4-skjemaene; reveal = 01 §7-kontrakten.
* **← 04_curator:** UI viser kun det Curator la i `public_payload` (bånd-makro, anonymisert); truth/`decision_date` først i reveal.
* **← 01_scoring:** score = alpha; graf og feedback bygger på reveal-feltene.
* **→ 07_kartoteket:** «Utforsk selskapet»-CTA + company-skjerm er frøet.

## 18. Åpne beslutninger

1. **Flutter vs React Native** (Instructions Backlog): fortsatt åpen prinsipielt, men hele denne spec'en + skillet forutsetter Flutter. Bekreft endelig før Fase 4.
2. **Design-sjanger:** Minimal Flat (lys) vs Enterprise Dark som standard? Forslag: dark-først, rolig palett.
3. **Lyd/haptikk-nivå:** hvor diskré? Forslag: haptikk på, lyd av som standard (toggle).
4. **Bruke skillets scaffolder** (`create_flutter_project.py --template material3`) som startpunkt, eller `flutter create` rent? Forslag: scaffolder for fart, men gjennomgå generert kode.
5. **GoRouter-struktur:** shell-route med bunnnavigasjon (Daily / Øving / Kartotek / Profil), eller enklere stack i MVP? Forslag: enkel stack i MVP, shell når Kartoteket kommer.