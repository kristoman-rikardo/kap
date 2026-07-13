# TODO: Estetisk løft (UI pass 2)

> Status: **backlog, bevisst utsatt.** Loopen og informasjonsarkitekturen først;
> theming er billigst å gjøre når skjermflatene er stabile. Rammen er låst av
> 06 §1/§14: polert fintech med smakfull juice — reward-motion i reveal/streak,
> aldri kasino, ingen utfallsfarge under blind spilling, unngå neon/glow.

## 1. Typografi

Ett tydelig fontpar (display + tekst) i stedet for system-default.

* **Alternativ A – `google_fonts`-pakken:** raskest å prøve ut; kandidater med
  riktig fintech-karakter: **Manrope** (display) + **Inter** (tekst),
  eller **Space Grotesk** (display, mer attitude) + Inter. Tabular figures for
  nøkkeltall er kravet som siler kandidatene.
* **Alternativ B – bundlede fontassets:** samme fonter, men lastes fra assets
  (offline-sikkert, ingen runtime-fetch). Riktig valg før release; A er riktig
  for utforskning.
* Sett alt via `TextTheme` i ett `theme/`-bibliotek — ingen fontnavn i widgets.

## 2. Farger & tema

* Etabler `lib/theme/` (06 §3) med `ColorScheme` for lys/mørk — **dark-først**
  (06 §18 forslag). Ingen hardkodede hex i widgets (skill-regelen); flytt
  reveal-grønnfargen (`_outcomeColor` i `reveal_screen.dart`) hit som token.
* **Alternativ A – `ColorScheme.fromSeed`** med en distinkt seed (dyp grønn/
  «market screen»-grønn? mørk petrol?) — minst arbeid, M3-konsistent.
* **Alternativ B – `flex_color_scheme`-pakken:** ferdige, gjennomarbeidede
  fintech-paletter med surface-blending; mer kontroll uten å håndrulle.
* Vurder én aksentfarge for «truth-laget» (alpha) adskilt fra brand-fargen.

## 3. Motion & juice (kun der utfall allerede er kjent)

* **`flutter_animate`:** deklarative kjeder (fade/slide/shimmer) — sannsynlig
  beste verktøy/effort-ratio for reveal-innslag og streak-feiring.
* Score-opptelling (count-up) i reveal; grafen tegnes inn venstre→høyre
  (fl_chart støtter implicit animation via data-swap).
* Haptikk ved valg (`HapticFeedback.selectionClick`) + tydeligere ved reveal;
  lyd av som default (06 §18).
* Swipe-overlay («LONG»/«SHORT» under draget, 06 §9) — mangler fortsatt.
* **Reveal-grafen er for døll i dag** (brukerfeedback 2026-07-06): gradient-
  fyll under din-linjen, draw-in-animasjon venstre→høyre, endepunkt-markører
  med verdi, sterkere fargekontrast mot indekslinjen.
* Streak/konfetti: nøktern feiring (f.eks. `confetti`-pakken, lav tetthet)
  først når streak finnes (CP 4.3).

## 3b. Full tekst-rework (all copy) — HØY prioritet før lansering

> Brukerønske 2026-07-13: «alle tekster suger nå» — trenger en full
> gjennomgang. Kristoffer vil ha **siste hånd på verket selv**, men
> `stop-slop`-skillen kan gjøre grovarbeidet først.

Gjelder ALL synlig copy, ikke bare én skjerm:
* Intro/framing-noter (batch-nivå), narrativer og clue-setninger (nå
  hardkodet i `fake_data._TRUTH` / `_CARDS` — erstattes av AI-generert i
  Fase 3, så koordiner: reworken bør treffe *malene/prompten*, ikke bare
  fixture-teksten).
* Hjemskjerm: stats-etiketter, dagens-runde-kortets tre tilstander,
  «Siste runder».
* Reveal: score-header, fasit-tags, cash-nyanser, footer-noten.
* Kort: seksjonsetiketter, cap-labels, term-forklaringer (når TermChip kommer).
* Feil-/tomtilstander og knappetekster overalt.
* Onboarding (CP 4.3) — skrives fra scratch, bruk anledningen.
* **Prosess:** kjør `stop-slop` som førstepass på en samlet copy-liste,
  deretter Kristoffers redigering. Norsk + engelsk (lokalisering, Instr §8).

## 4. Komponent-polish

* Kort-fronten: sterkere typografisk hierarki på nøkkeltall (tabular, større
  verdier, tydeligere gruppering), evt. subtil gradient/elevation på Card.
* `TermChip` (06 §8): tap-for-definisjon med kunnskapsnivå — pedagogikk-kravet
  som også løfter opplevd kvalitet.
* App-ikon + splash (flutter_native_splash) før soft launch.
* Referanse-gjennomgang: `flutter-ai-ui-skill`-sjangrene «Minimal Flat» /
  «Enterprise Dark» (06 §2) — bruk som moodboard, ikke fasit.

## Beslutninger som må tas (når passet starter)

1. Fontpar (A/B over) — prøv 2–3 par på ekte kort-skjerm, velg én.
2. Dark-først eller begge fra start?
3. `flutter_animate` inn som dependency, eller håndrullet motion?
4. Seed-farge / palett — trenger en smaksrunde på simulator.
