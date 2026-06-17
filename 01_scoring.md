# 01_scoring.md – KAP Spesifikasjon: Scoringmotoren

> **Dokumentserie (forslag til konvensjon, én spec per delsteg):**
> `01_scoring` (dette) · `02_datamodell` · `03_data_pipeline` · `04_curator` · `05_api` · `06_frontend_gameloop` · `07_kartoteket` · `08_realtime`
> Hver spec skal være implementerbar alene: formler, parametre, edge cases, grensesnitt mot nabo-specs, og talleksempler som blir enhetstest-fixtures.

---

## 1. Designprinsipper

1. **Score det du vil lære bort.** Spillere optimaliserer poengfunksjonen, ikke intensjonen bak den (Goodhart). Hver komponent i scoren må svare på: «hvilken atferd belønner dette på marginen?»
2. **Ingen poeng uten pedagogisk setning.** Scoren skal være dekomponerbar slik at hvert tall på resultatskjermen kan forklares i én setning. Scoring er feedback-arkitektur, ikke bare rangering.
3. **Utfall ≠ prosess.** Ex-post-score måler utfall på én realisert bane (flaks finnes). Prosesskvalitet (diversifisering, korrelasjon, risiko) vises ex-ante og diagnostisk – vi later aldri som det ene er det andre.
4. **Begrensede avbildninger.** Finansavkastning er tunghalede; rå alpha som poeng lar ett lottokort dominere en hel sesjon. Alle poengavbildninger squashes (tanh) slik at rangering bevares, men halene temmes.
5. **Buffett-kompatibilitet.** Konsentrasjon er tillatt og skal kunne vinne – men den må *betale for seg* risikojustert. Vi belønner aldri diversifisering mekanisk (det ville motsagt appens egen tese); vi lar konsentrert risiko koste via realisert aktiv risiko.

---

## 2. Notasjon og felles definisjoner

| Symbol | Definisjon |
|---|---|
| `t0` | Beslutningsdato = første handelsdag **etter** siste `filing_date` i kortets datapakke (look-ahead-regelen, jf. Instructions §4) |
| `H` | Horisont i år (typisk 3–5) , `t1 = t0 + H` |
| `R_i` | Kumulativ **totalavkastning** for aksje *i* over `[t0, t1]`, fra justerte kurser (splitt + utbytte reinvestert) |
| `R_m` | Kumulativ totalavkastning for benchmark (S&P 500 **Total Return** i MVP) |
| `R_f` | Kumulativ risikofri avkastning: geometrisk sammensatt 3M T-bill over perioden (FRED, f.eks. TB3MS) |
| `r` | Annualisert avkastning: `r = (1+R)^(1/H) − 1` |
| `α_i` | Annualisert alpha per aksje: `α_i = r_i − r_m` |

**Valg om annualisering:** Alle poeng beregnes på *annualiserte* størrelser. Hvorfor: (a) sammenliknbart på tvers av batcher med ulik horisont, (b) leselig for brukeren («du slo indeksen med 13 % i året»), (c) kumulative tall over 5 år blir uhåndterlig store (±200 %-poeng). Vi bruker aritmetisk differanse av geometrisk annualiserte avkastninger; forskjellen mot geometrisk meravkastning `(1+R_i)/(1+R_m)` er andreordens og ikke verdt kompleksiteten.

**Poengavbildningen (felles byggekloss):**

```
P(x) = 100 · tanh(x / τ)        τ = 0.15 (annualisert, config)
```

Egenskaper: monoton (bevarer rangering), lineær nær null (`P(x) ≈ 667·x` for små x, dvs. 1 %-poeng alpha ≈ 6,7 poeng), begrenset til ±100 (ett ekstremkort kan aldri dominere mer enn ett «perfekt» kort). τ er skalaen der poeng begynner å mette: ved `x = τ` får man ~76 poeng… *(korreksjon: tanh(1) = 0.762, ja ~76)*. Kalibrering av τ: se §9.

---

## 3. Junior Mode – per-kort-scoring

### 3.1 Regler

Valg per kort `d_i ∈ {Long, Short, Cash}`. Poengbærende størrelse («ditt alpha-bidrag»):

```
Long:   a_i = α_i              = r_i − r_m
Short:  a_i = −α_i             = −(r_i − r_m)
Cash:   a_i = α_cash           = r_f − r_m      (samme for alle kort i batchen)
```

Poeng per kort: `p_i = P(a_i)`. Rundescore:

```
Score_J = Σ p_i  +  Bonus
Bonus   = +25 hvis a_i > 0 for alle 5 kort («perfekt runde», config)
```

**Hvorfor symmetrisk short i Junior:** Enkelhet og fokus på *retningsferdighet*. Den realistiske asymmetrien (lånekost, begrenset oppside, utslettelsesrisiko) modelleres i Manager (§4.2) og forklares i reveal-teksten allerede i Junior.

**Hvorfor cash scorer negativt i bullmarked:** `r_f − r_m < 0` når markedet stiger. Det er korrekt lærdom – trygghet har alternativkostnad. Reveal-teksten skal eksplisitt si at cash kan være *ex-ante rasjonelt* selv når det ble *ex-post dyrt* (se §8 om fasit-portefølje).

### 3.2 Diagnostikk (vises, scorer ikke)

* **Treffprosent:** andel Long/Short-valg der `sign(valg) = sign(α_i)`. Cash inngår ikke; rapporteres som «unngått tap» (kortets α < 0) eller «mistet oppgang» (α > 0).
* **Rå alpha per kort** vises ved siden av poeng – poeng er spill-laget, alpha er sannhetslaget. Alltid begge.

### 3.3 Talleksempel (enhetstest-fixture, H = 5, R_m = +60 % ⇒ r_m = 9,9 %, R_f = +8 % ⇒ r_f = 1,6 %)

| Kort | R_i (kum.) | r_i (ann.) | α_i | Valg | a_i | Poeng |
|---|---|---|---|---|---|---|
| 1 | +180 % | 22,9 % | +13,0 % | Long | +13,0 % | **+70** |
| 2 | −45 % | −11,3 % | −21,2 % | Short | +21,2 % | **+89** |
| 3 | +75 % | 11,8 % | +1,9 % | Cash | −8,3 % | **−50** |
| 4 | +10 % | 1,9 % | −8,0 % | Long | −8,0 % | **−49** |
| 5 | +320 % | 33,2 % | +23,3 % | Short | −23,3 % | **−91** |

`Score_J ≈ −32`. Treffprosent 2/4 = 50 %. Merk poenget med tanh: kort 5 (å shorte en femdobler!) koster −91, ikke −155 som lineær skala ville gitt – ett katastrofekort skal svi, men ikke definere hele runden. *(Tall avrundet; eksakte fixtures genereres av referanseimplementasjonen.)*

---

## 4. Manager Mode – porteføljescoring

Her kommer porteføljeteorien inn. Brukerens innlevering er en vektvektor, ikke en valgsekvens, og scoren må dekke tre ferdigheter: **seleksjon** (hva du valgte), **vekting** (hvor mye av hver) og **risikostyring** (hvor mye aktiv risiko du tok for alphaen, inkl. korrelasjonseffekter).

### 4.1 Porteføljemodellen («sleeves», buy-and-hold)

Innlevering: longs med vekter `w_i ≥ 0`, shorts med vekter `w_j ≥ 0` (kapitalandel satt av til shorten), cash `w_c`. Budsjett: `Σw_long + Σw_short + w_c = 1`. Ingen rebalansering i horisonten (buy-and-hold – konsistent med langsiktighets-etosen, og enklest ærlige modell). Sanity-caps i UI: maks 40 % per posisjon, maks 30 % brutto short (config).

Daglig verdiserie med `V(t0) = 1`, `G_i(t) = P̃_i(t)/P̃_i(t0)` (justert bruttoavkastning):

```
Long-sleeve:   V_i(t) = w_i · G_i(t)
Short-sleeve:  V_j(t) = max( 0 ,  w_j · (2 − G_j(t) − b·Δt) )      b = lånekost, 1 %/år (config)
Cash-sleeve:   V_c(t) = w_c · (1 + R_f(t0→t))
Portefølje:    V_p(t) = Σ V_i + Σ V_j + V_c
```

**Short-sleevens pedagogikk:** Verdien `w(2 − G)` gir +100 % på sleeven hvis aksjen går til null (`G→0 ⇒ V→2w`), og **utslettelse** (margin call) hvis aksjen dobles (`G ≥ 2 ⇒ V = 0`, gulvet hindrer negativ NAV). Begrenset oppside, total nedside – nøyaktig den asymmetrien Junior abstraherer bort. Reveal-teksten navngir det: «Shorten din ble utslettet da aksjen doblet seg.»

### 4.2 Realiserte nøkkeltall (fra dagsserien `r_p,t = V_p(t)/V_p(t−1) − 1`)

```
R_p = V_p(t1) − 1            r_p = (1+R_p)^(1/H) − 1         α_p = r_p − r_m
TE  = std(r_p,t − r_m,t) · √252                              (tracking error, annualisert)
IR  = α_p / TE               (med guard: hvis TE < TE_min = 2 %, settes IR-leddet i scoren til 0)
σ_p = std(r_p,t) · √252      Sharpe = (r_p − r_f)/σ_p        (vises, scorer ikke – se 4.4)
```

### 4.3 Scoren: to ledd

```
Score_M = w1 · P(α_p)  +  w2 · 100·tanh(IR / IR_τ)
w1 = 0.7   w2 = 0.3   IR_τ = 1.0   (config)
```

* **Ledd 1 (magnitude):** Hvor mye slo du indeksen, risikojustert *implisitt* gjennom tanh-metningen.
* **Ledd 2 (effisiens):** Alpha per enhet aktiv risiko. **Information ratio er aktiv forvaltnings Sharpe** – og det riktige målet her, ikke Sharpe: Sharpe måler totalrisiko mot risikofritt; IR måler nettopp det spillet skal lære, seleksjonsferdighet relativt til benchmark. Grinold & Kahns fundamentallov, `IR ≈ IC·√BR` (information coefficient × bredde), knytter den direkte til treffsikkerhet × antall uavhengige veddemål – som er spillets to dimensjoner. Bonus: brukerens empiriske IC (korrelasjonen mellom valgene og realisert alpha-fortegn over historikken) er målbar og hører hjemme i «Din investorprofil».

**Insentivanalyse (sjekk mot prinsipp 1):**
* *Lottokupong* (alt i ett volatilt navn): stor mulig α_p, men ledd 1 metter på ±70 og høy TE demper ledd 2 → begrenset oppside, symmetrisk begrenset nedside. Variansjakt lønner seg ikke.
* *Skapindeksering* (12 megacaps ≈ indeksen): α_p ≈ 0 ⇒ ledd 1 ≈ 0; TE < TE_min ⇒ ledd 2 = 0. Null aktiv risiko = null evidens for ferdighet = null poeng. (TE_min-guarden finnes fordi IR = liten α / bitteliten TE ellers er ren støy som kan eksplodere.)
* *Konsentrert overbevisning à la Buffett*: fullt mulig å vinne – høy α med høy TE gir sterkt ledd 1 og moderat ledd 2. Konsentrasjon er lov; den må bare levere mer alpha enn en diversifisert bok for samme score. Det er riktig lekse.

**Hvorfor negativt fortegn håndteres riktig:** Begge ledd er odde funksjoner av prestasjon (negativ α ⇒ negativ IR ⇒ begge ledd negative). En multiplikativ form `P(α)·m(IR)` ble forkastet: med α < 0 ville lav IR *redusert* straffen – belønning for slurv når man taper. Additivt unngår fortegnspatologien. (Generaliserbart: sjekk alltid insentiver i alle fire kvadranter av (utfall, risiko).)

### 4.4 Attribusjon i reveal (Brinson-lite): seleksjon vs vekting

Beregn en hypotetisk **likevektsportefølje** av brukerens egne valg (samme retninger, like vekter, samme cash-andel):

```
α_EW            = likevektsporteføljens annualiserte alpha     → «seleksjonsbidraget ditt»
Δ_w = α_p − α_EW                                               → «vektingsbidraget ditt»
```

Vises som to setninger: «Valgene dine var verdt +2,5 %/år mot indeks. Vektingen din la til +1,5 %-poeng.» Dette er forenklet Brinson-attribusjon og er **feedback, ikke score** (vektingseffekten ligger allerede inne i α_p; å score den separat ville dobbelttelle).

### 4.5 Korrelasjon og diversifisering: hvor de faktisk virker

Porteføljeteorien dekkes gjennom **to kanaler**, ingen av dem en mekanisk «diversifiseringsbonus»:

1. **Realisert, i scoren:** En konsentrert bok av høyt korrelerte navn får mekanisk høyere TE (av `Var(w) = wᵀΣw` – korrelasjon er ikke et sidetema, den *er* porteføljevariansen). Høyere TE ⇒ lavere IR-ledd for samme alpha. Korrelasjonsslurv koster altså poeng via utfallet, uten at vi dikterer stil.
2. **Ex-ante, i UI («pre-flight risikopanel» på Bekreft portefølje-skjermen):** Før innsending estimeres fra trailing 2 års dagsavkastninger *før* `t0` (ingen look-ahead):
   * `Σ̂` via **Ledoit–Wolf-shrinkage** (8–12 aktiva × ~500 obs gir støyete sample-kovarians; shrinkage er én linje i sklearn og standardkuren)
   * Estimert porteføljevolatilitet `σ̂_p = √(wᵀΣ̂w)·√252` og estimert TE mot indeks
   * **N_eff = 1/Σw²** (effektivt antall posisjoner, invers Herfindahl): «8 navn, men diversifisering som ~5,6»
   * Gjennomsnittlig parvis korrelasjon `ρ̄` og **diversifiseringsratio** `DR = Σ|w_i|σ̂_i / σ̂_p` (DR ≈ 1 ⇒ du kjøpte kloner)
   * Sektor-HHI
   
   Panelet gir setninger, ikke poeng: «To av valgene dine er 0,85-korrelert – porteføljen din er mer konsentrert enn den ser ut.» Brukeren kan ignorere det – og bære konsekvensen i kanal 1.
3. **I reveal:** ex-ante-estimatene vises ved siden av realiserte verdier (σ̂_p vs σ_p, estimert vs realisert TE). Det lærer en meta-lekse ingen finansapp lærer bort: **risikomodeller er estimater med feil.**

### 4.6 Talleksempel (fixture-skjelett)

Anta innlevert portefølje: 8 longs (vekter 0.30/0.20/0.15/0.10/0.10/0.05/0.05/0.05 ⇒ N_eff = 5,6), ingen shorts, 0 % cash. Anta realisert: `α_p = +4,0 %/år`, `TE = 8 %` ⇒ `IR = 0,50`; likevektsvarianten ga `α_EW = +2,5 %` ⇒ `Δ_w = +1,5 %-poeng`.

```
Ledd 1: 0.7 · 100·tanh(0.040/0.15) = 0.7 · 26.0 = 18.2
Ledd 2: 0.3 · 100·tanh(0.50/1.00)  = 0.3 · 46.2 = 13.9
Score_M ≈ 32      Feedback: seleksjon +2.5, vekting +1.5, N_eff 5.6, IR 0.50
```

---

## 5. Real-Time Mode – skisse (låses i `08_realtime.md`)

* Løpende NAV-serie (ingen eksterne kontantstrømmer ⇒ tidsvektet avkastning er bare daglig lenking av NAV).
* Score = rullerende IR over 90d- og 365d-vinduer mot indeks, samme tanh-avbildning. Kort vindu vises med «lav signifikans»-merke (90 dager IR er mest støy – si det høyt).
* Earnings-events: faste små poeng (+10 korrekt / −5 feil, config) med obligatorisk begrunnelses-tag. Senere: sannsynlighetsprediksjon og **Brier-score** for kalibreringstrening.
* 30-dagers karantenen (Instructions §2C) håndheves utenfor scoringmotoren.

---

## 6. Edge cases (normative regler)

1. **Konkurs/delisting til null:** `R_i = −100 %` fra delist-dato. Long-sleeve → 0. Short-sleeve → `2w` (+100 %, maks gevinst realisert). Junior: `a_i` beregnes som vanlig (short på konkurskandidat er maksgevinst – tanh holder det på ≤ +100 poeng).
2. **Oppkjøp/fusjon:** Totalavkastning frem til delist-dato, deretter reinvesteres provenyet i **indeksen** for resthorisonten (standard backtest-konvensjon; alternativet risikofritt er strengere – config-flagg, default indeks). Clue-setningen skal nevne oppkjøpet.
3. **Manglende kursdata > 10 handelsdager i horisonten:** kortet skulle vært stoppet i datavasken (`03_data_pipeline`-grensesnitt); scoringmotoren kaster valideringsfeil, gjetter aldri.
4. **Short-sleeve truffet gulvet:** sleeve forblir 0 resten av horisonten (ingen gjenoppstandelse) – margin call er endelig.
5. **Valuta:** MVP er USD-only (univers, indeks, r_f). Flervaluta (Manager global) krever egen regel – lokal TR-indeks per marked eller alt målt i USD; beslutning utsatt til universet utvides.
6. **r_f-kilde:** 3M T-bill (FRED), geometrisk sammensatt over `[t0, t1]`. Lagres per batch slik at `α_cash` er deterministisk og revisjonsbar.
7. **Batch med horisont som ender < 30 handelsdager fra i dag:** ikke tillatt (Curator-constraint) – fasit må være «ferdig historie».

---

## 7. Grensesnitt (kontrakter mot nabo-specs)

**Inn (fra `04_curator` + `03_data_pipeline`):** per kort `{ticker, t0, H}` + garantert komplette serier `{P̃_i(t)}`, `{P̃_m(t)}`, `{r_f}` for `[t0−2år, t1]` (de to ekstra årene er til ex-ante-kovariansen).

**Ut (responsen fra `POST /batch/{id}/submit`, definerer `05_api`):**

```json
{
  "score": -32, "bonus": 0, "hit_rate": 0.5,
  "benchmark": {"R_m": 0.60, "r_m": 0.099, "r_f": 0.016, "alpha_cash": -0.083},
  "cards": [
    {"card_no": 1, "ticker": "…", "name": "…", "choice": "long",
     "R": 1.80, "r": 0.229, "alpha": 0.130, "a": 0.130, "points": 70,
     "clue": "…", "event": null | "acquired" | "delisted"}
  ],
  "manager_extra": {                      // kun Manager Mode
    "alpha_p": 0.040, "alpha_ew": 0.025, "weighting_contrib": 0.015,
    "te": 0.08, "ir": 0.50, "sharpe": 0.61, "sigma": 0.18,
    "n_eff": 5.6, "avg_pairwise_corr": 0.42, "sector_hhi": 0.21, "div_ratio": 1.6,
    "ex_ante": {"sigma_hat": 0.16, "te_hat": 0.07}
  }
}
```

Alle felter brukerrettet – hvert tall har en setningsmal i frontend (prinsipp 2).

---

## 8. Fasit-portefølje og reveal-semantikk

* **«Fasit (etterpåklokskap)»** – eksplisitt merket som hindsight: Junior = Long alle α>0, Short alle α<0; Manager = beste oppnåelige score gitt constraints (vises som tall, ikke som «du burde»).
* Cash i fasiten: aldri optimal ex post (|α| > 0 nesten sikkert). Derfor MÅ reveal-teksten bære nyansen: «Cash kostet deg 8 %/år mot indeks denne runden. Det betyr ikke at det var dumt – det betyr at trygghet koster i stigende marked.» Uten denne setningen lærer spillet bort at cash alltid er feil, hvilket er usant ex ante.
* Referanselinjer i grafen: din portefølje, (Manager: likevektsvarianten din), indeksen.

---

## 9. Parametertabell og kalibrering

| Parameter | Default | Kalibreringsoppgave |
|---|---|---|
| `τ` (alpha-squash) | 0.15 | Simuler ~10 000 tilfeldige strategier på det historiske universet; sett τ slik at ±1 SD av tilfeldig-score ≈ ±35 poeng og «åpenbart god» runde ≈ +60–80. Poengskalaen skal *føles* riktig før den låses. |
| `Bonus` perfekt runde | +25 | A/B mot streak-retention senere |
| `w1 / w2` | 0.70 / 0.30 | Sjekk at rangering av testporteføljer matcher ekspertintuisjon (du + 2–3 finansvenner rangerer blindt) |
| `IR_τ` | 1.0 | IR = 1 er eksepsjonelt i virkeligheten – gir ~46 av 100 mulige i ledd 2, bevisst strengt |
| `TE_min` | 2 % ann. | Under dette: ingen evidens for aktiv forvaltning |
| `b` (lånekost short) | 1 %/år | Hardcodet i v1; per-aksje borrow senere |
| Posisjonscap / brutto short | 40 % / 30 % | UI-constraints, ikke scoring |

---

## 10. Testplan

* **Egenskapstester:** (1) Symmetri Junior: bytt Long↔Short på et kort ⇒ `p_i ↔ −p_i`. (2) Cash-bidrag uavhengig av kortet. (3) `|p_i| ≤ 100`, `|Score_M-ledd| ≤ w·100`. (4) Short-sleeve aldri negativ. (5) Score invariant under kortrekkefølge. (6) Manager med likevekter ⇒ `Δ_w = 0` eksakt.
* **Golden fixtures:** tabellene i §3.3 og §4.6 regenereres av referanseimplementasjonen og fryses som testdata.
* **Insentivtester (viktigst):** kjør de degenererte strategiene fra §4.3 på 100 historiske batcher og verifiser at ingen av dem ligger i topp-kvartilen av score-fordelingen. Dette er enhetstesten for prinsipp 1.

---

## 11. Åpne beslutninger

1. Skal Manager-shorts ha per-aksje lånekost (krever borrow-data, neppe i FMP) eller flat `b`? → flat i v1.
2. Skal `Δ_w` (vektingsbidraget) inn i scoren med liten vekt, eller forbli ren feedback? → feedback i v1; revurder når data viser om brukere ignorerer vekting.
3. Persentil/rating på tvers av dager (Dagens Runde-leaderboard) → egen spec (`rating` hører ikke hjemme her; scoringens ansvar slutter ved sesjonsscore + dagspersentil).
4. τ-kalibreringen (§9) er første konkrete numeriske oppgave når pipelinen har data – god kandidat til et notebook-eksperiment.