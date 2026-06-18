# 04_curator.md – KAP Spesifikasjon: The Curator (utvalg & seal)

> **Dokumentserie:** `01_scoring` ✓ · `02_datamodell` ✓ · `03_data_pipeline` ✓ · **`04_curator` (dette)** · `05_api` · `06_frontend_gameloop` · `07_kartoteket` · `08_realtime`
> Curator er der alt møtes: den trekker batchens periode og fem kort fra det point-in-time-korrekte universet, beregner de pris-avhengige feltene og fasiten ved *seal*, fryser benchmark/risikofri, og forsegler resultatet som en uforanderlig batch. Dette dokumentet dekker **Junior Mode + Dagens Runde fullt**; Manager rammes inn som v1.2 (§12); Real-Time er 08.

---

## 0. Periodemodell (besluttet)

Hver Junior-batch får én `decision_date` + horisont `H`, trukket fra et stort sett mulige kvartaler, og **alle fem kort i batchen deler den perioden** — slik makro-boksen og introkortet krever (Instructions §3). *Batchens* periode flyter over historien (§2); kortene innad spriker ikke.

Bekymringen «recognize epoken → exploit» (f.eks. «2020–2025, long alt» eller «1998–2003, short tech») håndteres på tre andre akser enn å splitte perioden per kort — fordi per-kort-perioder hverken hadde lukket exploiten (hvert korts makro røper fortsatt *sin* epoke) og dessuten ville brutt Manager-porteføljeteorien (ingen felles tidslinje → ingen korrelasjon/kovarians):
1. **Alpha-scoring** (01 §2) dreper «long alt»: i et oksemarked gir det ~0 alpha, ikke gevinst.
2. **Variert periode på tvers av batcher** (§2): spilleren kan ikke forutsi neste batchs epoke.
3. **Epoke-anonymitet på den delte makro-boksen** (§5.7): grovkornet makro (bånd, ingen tall, ingen årstall) + epoke-lekkasjesjekk gir nok til regime-resonnement, men ikke nok til å tidfeste året og anvende sektor-fasit.

Beskyttet: selskapsidentitet **og** kalenderepoke. *Ikke* beskyttet: regimet selv – å lese «høye, økende renter» og resonnere om det er kjerneferdigheten spillet trener.

---

## 1. Designprinsipper

1. **Determinisme via seed.** En batch er en ren funksjon av `(seed, datatilstand ved generering)`. Samme seed + samme data ⇒ samme batch. Det gir reproduserbarhet, og det er det som lar Dagens Runde gi alle samme bunke.
2. **Generér én gang, frys for alltid.** Determinisme og uforanderlighet er *ikke* det samme. Seed styrer *førstegangs*-trekningen; deretter snapshotes batchen (02 §8, frosset `public_payload` + truth) og regenereres aldri – selv om data endres eller seed kjøres på nytt. Spiller du seed-en mot endret data i ettertid, kan trekningen bli en annen; nettopp derfor snapshoter vi i stedet for å regenerere ved lesing.
3. **Pris-avhengige felt beregnes her, ved seal.** P/E, P/S og cap-kategori krever `price(t0)` på en vilkårlig dato Curator først velger nå (03-prinsipp 3). Pipelinen leverte byggeklossene; Curator regner multiplene.
4. **Løsbarhet uten å være gjettbar.** Hver batch har et *gulv* (≥1 vinner, ≥1 taper) så «long alt» aldri er dominant – men gulvet er et minimum, ikke et eksakt antall, og de øvrige kortene varierer fritt, så spilleren kan ikke telle seg til fasiten.
5. **Ærlig variasjon framfor konstruert.** At cash av og til er riktig valg oppnås ved å inkludere *ekte* dårlige/flate markedsperioder der det historisk *var* riktig å sitte i statsobligasjoner – ikke ved å fabrikkere kunstige kort (§4).
6. **Seal er en port, ikke en formalitet.** En batch blir `live` bare hvis dekningssjekk (03 §8), leak-sjekk (03 §7) og constraints er oppfylt – og, for Dagens Runde, etter menneskelig godkjenning i utviklingsfasen (§9).

---

## 2. Periodemodellen (flytende)

### 2.1 Mulighetsrommet

En batchperiode er et par `(decision_date, H)`:
* `decision_date`: starten av et kvartal. Over tilgjengelig historikk (~1993→) gir det ~130+ mulige kvartaler.
* `H ∈ {1, 3, 5}` år (Instructions; favoriser 3/5 i vekting for det langsiktige etosen – config).

⇒ ~130 kvartaler × 3 horisonter ≈ **~400 periode-definisjoner** (matcher ditt estimat). Et par er *kvalifisert* hvis:
* **Ferdig historie:** `t1 = decision_date + H ≤ i_dag − 30 handelsdager` (02 §13(d)).
* **Dekning finnes:** nok av universet har hullfrie serier over `[t0−2år, t1]` (03 §8).
* **Regimebredde:** poolen skal med vilje spenne oppgang *og* nedgang/flatt (se §4 – det er slik cash blir meningsfullt).
* **MVP – FY-forankring via eligibility (Q4-felle, 03 S3):** i stedet for å binde *batchens* `decision_date` til ett FY-vindu (umulig når fem selskaper har ulike regnskapsår og filing-lag), flyttes forankringen til en **per-selskap eligibility-test (§3.1)**: et selskap kvalifiserer kun hvis dets ferskeste point-in-time-filing ved `decision_date` *er* et årsregnskap – ingen interim rapportert siden FY. Da bruker hvert valgt kort **FY-rapporten direkte** uten TTM-summering, og 02 §6.2 forblir ærlig: vi skjuler aldri et nyere offentlig kvartal, vi *velger* bare ikke selskaper som har ett. FY = TTM trivielt. **Konsekvens:** kvalifisert pool ved en dato = selskaper i sitt post-FY/pre-neste-interim-vindu; siden mesteparten av S&P 500 har desember-regnskapsår, klynger `decision_date`-ene seg rundt feb–april. Rikelig for MVP, og nedgangsvinduer nås fortsatt (post-FY-2008 ≈ tidlig 2009). Den robuste YTD-delta-TTM-en (03 S3) trengs først i en senere fase som slakker dato-/univers-restriksjonen.

### 2.2 Narrativ-økonomi (oppdaterer 03 §7.3)

To kostnadsklasser, bevisst adskilt:
* **Periode-/makrokontekst** (introkort + makro-setning): per `decision_date` (~130) eller `(decision_date, H)` (~400). Pre-genereres – billig, avgrenset, *dette er ~400-tallet ditt*.
* **Per-selskap kortnarrativ** (anonymisert situasjon + clue + resultatforklaring): genereres **lazy og caches** kun for selskaper som faktisk trekkes inn i en sealet batch. Du betaler aldri for det teoretiske maksimum (~130 × universet); kostnaden skalerer med faktisk spilte kort, ikke med mulighetsrommet. For Dagens Runde skjer genereringen under den 7-dagers ledetiden (§9), aldri ved brukerforespørsel.

Dette erstatter 03s «liten fast mål-dato-liste» med «flytende `decision_date` + lazy, cachet per-selskap-generering». 03 §7.3/§8-#4 oppdateres tilsvarende.

### 2.3 Alpha-/cap-precompute (ytelse)

For å stratifisere universet (§3) trenger Curator per-selskap alpha *og* market cap for hele det kvalifiserte universet ved en `decision_date`. Begge er billig aritmetikk fra `prices` (allerede i DB). Materialisér per `(company_id, decision_date, H)`:

```
alpha_table(company_id, decision_date, H, ret_cum, ret_ann, alpha_ann, mktcap_t0, event)
```

Beregnes første gang en `decision_date` brukes, caches. `alpha_ann` driver vinner/taper-stratifiseringen; `mktcap_t0 = price(t0)·shares_out(known@t0)` driver relativ cap-bucket (§5.3).

---

## 3. Kvalifisert univers & kortutvalg

### 3.1 Kvalifisert univers ved `decision_date`

```
U(decision_date) =
    index_constituents @ decision_date            -- point-in-time medlemskap (02 §4.2)
  − iconic = true                                 -- for gjenkjennelige (03 S2)
  − selskaper uten leak-passert narrativ-mulighet -- (genereres lazy; men må kunne genereres)
  − selskaper med datakvalitets-/dekningsflagg    -- (03 §8)
  − selskaper uten shares_out@t0                   -- (kan ikke regne P/E/P/S/cap; 03 edge case 4)
  − selskaper hvis ferskeste filing@decision_date IKKE er FY  -- FY-eligibility (§2.1): kun selskaper uten interim siden årsregnskapet, så kortet bruker FY direkte
```

### 3.2 Stratifisert-med-gulv trekning (deterministisk)

Partisjonér `U` på annualisert alpha (`θ = 10 %`-poeng, config):

```
W = { c ∈ U : alpha_ann(c) ≥ +θ }     # vinnere
L = { c ∈ U : alpha_ann(c) ≤ −θ }     # tapere
R = U \ (W ∪ L)                        # resten (inkl. ekte myntkast nær 0)
```

Trekk med seedet PRNG:
1. 1 kort fra `W` (garantert vinner).
2. 1 kort fra `L` (garantert taper ⇒ «long alt» kan ikke vinne; punkt 4).
3. 3 kort fra `U \ {trukne}` – fri spredning (kan bli flere vinnere/tapere *eller* myntkast).

Beskrankninger håndheves *under* trekningen (re-trekk seedet ved brudd, begrenset antall forsøk):
* maks 2 kort per ekte GICS-sektor (11-nivå),
* sikt på ≥2 distinkte cap-kategorier,
* ingen `iconic`.

Feiler trekningen (for liten `U`, constraints uoppnåelige) ⇒ seedet re-pick av `decision_date`, begrenset antall forsøk, ellers logg og hopp (aldri en halv batch).

**Hvorfor stratifisert framfor reject-sampling av 5 tilfeldige:** garanterer gulvet i ett pass uten løkke-risiko, og er deterministisk. Gulvet (1+1) er et *minimum*; de tre frie kortene gjør at spilleren ikke kan anta «nøyaktig én vinner og én taper».

### 3.3 Talleksempel (fixture-skjelett)

`U` har 220 kvalifiserte selskaper ved `2014-06-01`, H=5. `θ=10 %`. `|W|=31, |L|=18, |R|=171`. Seed=20140601:
trekk W→[idx 7], L→[idx 12], så 3 fra resten → 2 myntkast (alpha +1,2 %, −3,4 %) + 1 ekstra vinner (alpha +14 %). Sektorsjekk: 2×Tech tillatt, 3. Tech-kort re-trekkes til Industrials. Cap: 2 Large, 2 Mid, 1 Small ✓. Resultat: 5 kort, deterministisk, gulv oppfylt, «long alt» gir negativ score pga. taperen.

---

## 4. Løsbarhet & tre-valgs-variasjon

Ditt krav (punkt 3): korrekt utvalg, men bland inn selskaper så «long hele veien» ikke vinner; og alle tre valg (Long/Short/Cash) skal være fasit i *noen* runder, ikke nødvendigvis alle.

* **Long og Short matters i hver batch:** gulvet ≥1 vinner / ≥1 taper (§3.2) garanterer at både en long og en short finnes i fasiten hver gang.
* **Når er Cash faktisk fasit?** Per kort er scorene `long=α, short=−α, cash=c` med `c = r_f − r_m`. Cash er optimalt *kun* når `c ≥ |α|`, dvs. `r_f ≥ r_m` (markedet slo *ikke* risikofritt over horisonten) **og** kortet har lav |alpha|. I et stigende marked (`c<0`) er cash aldri optimalt – det er korrekt (01 §3.1, §8). Cash blir altså meningsfullt nettopp i **ekte dårlige/flate perioder**.
* **Mekanisme (ærlig, ikke konstruert):** la det kvalifiserte periode-poolen (§2.1) inkludere nedgangs-/flate vinduer (f.eks. starter rundt 2000, 2007, eller flate strekk). I slike batcher vil et lav-|alpha|-kort (en markedsfølger i et fallende marked) ha cash som lavest-anger-valg. Spillet lærer da en sann Buffett-lekse: i noen regimer *var* statsobligasjoner det rette. Vi fabrikkerer ingenting – vi lar historien levere cash-optimaliteten.
* **Populasjonsdekning (myk):** Curator teller, over nylige sealede batcher, hvor ofte fasiten inneholder et long-/short-/cash-optimalt kort. Er cash-dekningen lav, bias neste trekning mot et nedgangs-/flatt vindu (for Dagens Runde: poolen er forhåndsbalansert for regimebredde, så seedet sampling gir variasjonen uten å bryte determinisme).

---

## 5. Seal: fra trekning til frosset batch

Når de 5 kortene er trukket, beregner Curator alt og forsegler. Rekkefølge:

### 5.1 Point-in-time-tall
Per kort: kjør 02 §6.2-spørringen (siste tall med `filing_date ≤ decision_date`, riktig restatement-versjon). Henter regnskapslinjer + `shares_out`.

### 5.2 Pris-avhengige felt (her, ikke i pipeline)
* **Fundamentale tall (MVP): FY direkte.** For MVP forankres `decision_date` rett etter FY-`filingDate` (§2.1), så P/E-nevneren er **FY-EPS direkte** – ingen TTM-summering, og Q4-revisjonsfellen (03 S3) unngås. (Skalert drift bruker YTD-delta-TTM, 03 S3.)
* `P/E = price(t0) / ttm_eps`. Negativ EPS ⇒ P/E vises som «neg.»/utelates (selv et signal). `P/S = price(t0) / (ttm_revenue / shares_out)`.
* **Cap-kategori (inflasjonsjusterte absolutte terskler):** klassifisér `mktcap_t0` mot reelle terskler deflatert til `t0`. Velg 2026-ankre (default: Large ≥ $10 mrd, Mid $2–10 mrd, Small < $2 mrd; config) og skalér nominelt: `terskel(t0) = ankre_2026 · CPI(t0)/CPI(2026)` (CPI fra FMP `economic-indicators`, allerede ingestet – 03 S6). Kilde for `mktcap_t0`: `price(t0)·weightedAverageShsOutDil` (virker også for delistede; FMP `historical-market-capitalization` gir 0 rader for delistede – Q29, så price·shares er den robuste veien). **Kun bånd-etiketten («Large/Mid/Small») vises – aldri beløpet** – så absolutt størrelse og epoke lekker ikke, mens etiketten beholder en stabil, allmenn betydning på tvers av batcher (en «Large» i 1995 og i 2020 betyr samme *reelle* størrelse). Erstatter den tidligere batch-relative persentil-bucketen.
* **CAGR** (3 år, revenue/EPS): prisuavhengig, kan også komme fra pipeline.

### 5.3 Fasit (truth-laget)
Per kort fra `alpha_table`: `ret_cum, ret_ann, alpha_ann, event`.
* **Event-deteksjon** (delisting innen `[t0,t1]`): siden `delisting_reason` er null (03 S1), klassifisér ved seal fra `historical-sp500-constituent.reason`-teksten («acquisition»/«merger» → `acquired`, proveny reinvestert i indeks, 01 §6-2) + sluttkurs-nær-null → `bankruptcy` (`ret=−100 %`, 01 §6-1), ellers `other`. **M&A-endepunktet er verifisert ubrukbart** for dette (kun navnesøk, manglende data – Q37). Clue-setningen nevner hendelsen. (Åpen post §15.)

### 5.4 Frys benchmark/risikofri (determinisme, 01 §2/§6.6)
Over `[t0, t1]`, fra `index_prices('SP500TR_SPY')` og `risk_free`:
`R_m, r_m` (SPY-TR-proxy), `R_f, r_f` (geometrisk 3M T-bill), `alpha_cash = r_f − r_m`. Lagres på `game_batches`.

### 5.5 Narrativer (lazy)
Per kort: hent narrativ for `(company, decision_date)` + clue/resultatforklaring for `(company, decision_date, H)`. Mangler de ⇒ generér via 03 §7 (LLM + to-trinns leak-sjekk) og cache. Seal krever `leak_check_passed=true` for alle kort. For brukerrettede forespørsler skjer generering *aldri* synkront (pool/ledetid dekker det).

### 5.6 Sett sammen & forsegl
* **`public_payload`** (anonymisert, 02 §8): makro (fra `macro_context @ decision_date`, *delt* av alle 5 kort), fundamentals (P/E, P/S, gjeld/EK, marginer, ROIC), growth (CAGR), cap (bånd, §5.2), `sector_coarse`, narrativ, sektorsentiment. **Aldri navn/ticker/beløp.**
* **Introkort/periodekontekst** (batch-nivå, delt): markedssentiment + rentebilde for `decision_date` (Instructions §3, pkt 4).
* **`f_*`-analytics** (02 §8): `f_pe, f_debt_to_equity, f_rev_cagr, f_sector, f_cap`.
* **truth**: `name, alpha, ret_cum, ret_ann, event, clue, result_explanation`.
* **Difficulty** (lagres, ubrukt til matchmaking): alpha-spredning i bunken, f.eks. `std(alpha_ann over de 5)` eller `max−min` (config). Lav spredning = vanskelig (vinner/taper utydelig).
* **Dekningsport:** kall `coverage_ok(company_id, t0, H)` for alle kort (03 §8). Én feil ⇒ ikke seal.
* Sett `status='sealed'` (→ `'live'` etter §9 for daily).

### 5.7 Epoke-anonymitet (lukker rest-exploiten fra §0)
Makro-boksen er *delt* av de fem kortene (batch-nivå), så den er den ene flaten som kan røpe kalenderepoken. To regler ved assemblering:
1. **Bånd-vis numerisk makro.** `macro_context` lagrer numerisk inflasjon/BNP (Curator trenger tallene til regime-logikken, §4 cash-optimalitet), men payloaden viser *kvalitative bånd*: inflasjon ∈ {lav, moderat, forhøyet, høy}, BNP ∈ {kontraksjon, svak, sunn, sterk} (config-terskler); rente er allerede kvalitativ. Samme mønster som `f_*`/payload-splitten: numerisk internt, bånd vist. Et presist inflasjonstall (9,1 %) ville ropt «2022».
2. **Epoke-lekkasjesjekk på AI-teksten** (makro-setning + sektorsentiment + introkort), parallelt til selskaps-leak-sjekken (03 §7.2): regex mot epokedefinerende termer (pandemi, finanskrise, dot-com, Lehman, 9/11, Covid, krig) + LLM-dommer «kan du tidfeste til ±2 år?» → regenerér ved treff. **Oppdaterer 03 S6/S7:** epoke-lekkasje er en *andre* leak-dimensjon på makro-/sentiment-tekst, ved siden av selskaps-leak.

Prinsipp: nok makro til å lese regimet, ikke nok til å pinne året. Selskapsidentitet **og** kalenderepoke beskyttes; regimet gjør det ikke.

---

## 6. Determinisme & reproduserbarhet (samlet)

```
seed ─► PRNG ─► (H) ─► (decision_date ∈ kvalifiserte) ─► stratifisert trekk av 5 ─► seal-beregning ─► SNAPSHOT
```
Alt fra én seedet PRNG. Snapshot fryser resultatet (prinsipp 2). `seed`, `curator_version`, `curator_params` lagres på `game_batches` for full sporbarhet. En batch kan rekonstrueres bit-eksakt fra snapshotet; den *regenereres* aldri fra seed mot live data.

---

## 7. Dagens Runde (growth-motoren)

* **Seed = `daily_date`** (f.eks. heltall `YYYYMMDD`) ⇒ alle får samme `(H, decision_date, 5 kort)`.
* **Unik global batch:** `game_batches(is_daily=true, daily_date)` (02 §8 unik indeks). Ett forsøk per bruker (02 §9 partiell unik).
* **Regimebredde-pool:** seedet sampling trekker fra en pool forhåndsbalansert for oppgang/nedgang/flatt (§4) – variasjon uten å bryte determinisme.
* **Delingskort:** emoji-grid (🟩 riktig retning / 🟥 feil / ⬜ cash) + alpha mot indeks, uten å spoile selskapene (Instructions §2E; bygges i 06).

## 8. (slått sammen i 7)

## 9. Generering, ledetid & menneske-i-loop (punkt 4 låst)

* **Ledetid ~7 dager:** en jobb genererer de neste ~7 dagers daily-batcher på forskudd. Gir QA-buffer og robusthet hvis jobben feiler en natt.
* **Menneske-i-loop (utviklingsfasen):** du ser over hver kommende daily – de 5 kortene, makro/intro, og narrativene – og kan **redigere eller regenerere** før den går `live`. Det er denne godkjenningen som gjør at leak-sjekken *og* øyet ditt gater det mest synlige innholdet. Status: `sealed` → (din godkjenning) → `live`.
* **Frysing:** så lenge en daily ikke er `live`, kan den regenereres fritt (ennå ikke spilt). Når den er `live`, er den uforanderlig (prinsipp 2). En datafeil oppdaget *etter* live håndteres som en annullering/erstatning, ikke en stille endring.
* Automatiseres senere når pipelinen har vist seg pålitelig (godkjennings-flagget kan da defaultes til auto).

## 10. Vanlig Junior (øving)

Eksisterer i MVP ved siden av Dagens Runde.
* **Pool-generering:** Curator pre-genererer en pool av sealede øvings-batcher (flytende perioder, §2), så bruker aldri venter på seal/narrativ.
* **Per-bruker-variasjon:** server ikke samme `batch_id` to ganger til samme bruker (join mot `game_sessions`). *(Kartotek-utforskning nedvekter **ikke** kort – 07 §1.4: Kartoteket er nåtid/ekte, blindkortene historiske/anonyme, så gjenkjenning er ikke lekkasje. Dette punktet er bevisst fjernet.)*
* Samme utvalgsalgoritme som daily, minus den globale seed-bindingen (seed = `batch_id`).

## 11. Edge cases

1. **For lite kvalifisert univers** ved en `decision_date` (tidlig historikk, mange dekningshull) ⇒ seedet re-pick av dato; ellers logg.
2. **Ingen vinner eller ingen taper** i `U` (svært homogen periode) ⇒ senk `θ` midlertidig per config, eller re-pick dato. Aldri seal uten gulv.
3. **Negativ EPS:** P/E «neg.»/utelatt; P/S og øvrige tall står. Selve fraværet er et signal.
4. **Delisting midt i horisonten:** event-klassifisering (§5.3); short på konkurskandidat = maksgevinst (tanh-kappet, 01 §6-1).
5. **Oppkjøp:** proveny reinvesteres i indeks for resthorisonten (01 §6-2); clue nevner det.
6. **Constraints uoppnåelige** (f.eks. for få sektorer) ⇒ slakk cap-målet før sektor-målet (cap er «sikt på», sektor er hardt); ellers re-pick dato.
7. **Narrativ feiler leak-sjekk N ganger** ⇒ selskapet droppes fra `U` for den datoen; trekk erstatning (seedet).

## 12. Manager Mode (v1.2 – kun innramming)

Gjenbruker Curator med andre beskrankninger; spec'es fullt i egen revisjon. Forskjeller:
* **25–30 kort** (ikke 5), bredere univers, flere/lengre perioder (01 §2B).
* **Vekting** justeres på «Bekreft portefølje»-skjermen, ikke per swipe (01 §2B).
* **Risikojustering** i scoren (Sharpe/IR-ledd, 01 §4) – krever realisert dagsserie for porteføljen ved submit, fra `prices` for batchens tickere.
* **Short-asymmetri** modelleres (01 §4.1 short-sleeve).
* Curator-gulvet generaliseres (flere vinnere/tapere, bredere regime).

## 13. Grensesnitt

**← 02_datamodell:** skriver `game_batches` (inkl. frosne `R_m/r_m/R_f/r_f/alpha_cash`, `seed`, `difficulty`, `curator_version/params`) og `batch_cards` (`public_payload`, `f_*`, truth). Service-only (02 §10).
**← 03_data_pipeline:** leser `index_constituents`, `financials` (point-in-time), `prices/index_prices/risk_free`, `narratives`; kaller `coverage_ok`; trigger lazy narrativ-generering. *Oppdaterer 03 §7.3:* flytende `decision_date` + lazy per-selskap-narrativ.
**→ 01_scoring:** leverer per-kort `alpha/ret` (truth) + batch-frosne benchmark/rf som scoringen anvender brukervalg på.
**→ 05_api:** API-et serverer kun `public_payload`+`card_no`; truth returneres først i submit-svaret (02 §10).

## 14. Test & fixtures

* **Determinisme:** samme seed + frosset datasnapshot ⇒ bit-identisk *utvalg + beregnede numeriske felt* (kjør to ganger). Narrativ-/makrotekst er LLM-generert og fryses ved første generering (snapshot, §5.5), så determinismetesten asserterer *ikke* bit-identisk tekst – kun seleksjon, pris-avhengige felt og fasit.
* **Frysing:** endre underliggende pris etter snapshot ⇒ batchen er uendret; ny seed-kjøring mot endret data brukes *ikke*.
* **Gulv:** generert batch har alltid ≥1 kort `alpha≥+θ` og ≥1 `alpha≤−θ`.
* **«Long alt» taper:** summen av long-på-alle-5 gir negativ score på en fixture-batch med taper.
* **Cash-optimalitet:** en batch fra et nedgangsvindu (`r_m<r_f`) har minst ett kort der `c≥|α|` ⇒ cash er fasit (verifiserer punkt 3).
* **Inflasjonsjustert cap:** et selskap med samme *reelle* market cap i en 1995- vs 2020-batch får **samme** cap-bånd (verifiserer at terskelen er inflasjonsjustert absolutt, ikke batch-relativ); et nominelt likt beløp kan derimot havne i ulikt bånd på tvers av epoker.
* **Sektor-cap:** ingen sealet batch har >2 kort i samme GICS-sektor.
* **Point-in-time:** ingen kort-payload bruker tall med `filing_date > decision_date` (binder mot 03 §9-testen).
* Binder mot **golden fixtures (01 §3.3/§4.6)** + seed-univers (02 §15): de samme fem kortene, samme alpha, samme score.

## 15. Åpne beslutninger

*Lukket:* per-kort vs per-batch periode → **batch-nivå** (delt periode innad, variert på tvers, epoke-anonymitet på makro-boksen; §0, §5.7).

1. **Event-klassifisering** (delisted vs acquired) ved seal: fra `historical-sp500-constituent.reason` + sluttkurs-nær-null-heuristikk (M&A-endepunktet er verifisert ubrukbart, Q37). Hvor aggressiv null-terskel? Revurder når vi ser ekte case.
2. **`θ`-adaptiv?** Fast 10 % vinner/taper-gulv, eller la `θ` flyte med periodens volatilitet (et regimejustert gulv)? Forslag: fast i MVP, adaptiv som difficulty-mekanikk senere.
3. **Horisont-vekting:** uniform `{1,3,5}`, eller favorisér 3/5 for langsiktighets-etosen? Forslag: favorisér 3/5.
4. **Bånd-terskler for makro** (§5.7): hvor settes grensene for inflasjon/BNP-bånd? Bør kalibreres så bånd-fordelingen er jevn nok til å ikke selv bli et fingeravtrykk.
5. **Øvings-pool-størrelse & refresh:** hvor mange forhåndsgenererte øvings-batcher, og hvor ofte påfyll? Avgjøres når retention-tall finnes.