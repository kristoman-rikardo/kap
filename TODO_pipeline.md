# TODO: Datapipeline-gjeld (backlog)

> Tekniske avveininger tatt bevisst under Fase 3, som skal revurderes senere.
> Ikke blokkerende for MVP.

## Delistet kursdekning ~76% (notert 2026-07-19, CP 3.3)

**Målt:** av 50 samplede delistede i 2016-universet har 38 (76%)
utbyttejusterte kurser i FMP; 24% mangler (YHOO, GMCR, TWC, CA, DNB, LLL,
ADT, NBL, …) — typisk eldre oppkjøp der FMP ikke beholdt serien.
2023-delistinger (SIVB/FRC/BBBY) har kurser; enkelte 2016-oppkjøp
(SNDK/MON/EMC/PCP) mangler helt.

**Håndtering i MVP:** `coverage_ok` ekskluderer selskaper uten hullfri serie
(ikke stille skip — 03 prinsipp 5), og dekningsraten rapporteres per ingest.
Survivorship-signalet er stort sett bevart (~121 av 159 delistede i 2016 er
fortsatt spillbare), men Curatoren har litt mindre å velge blant blant de
delistede.

**Fallback-kilde (backlog):** vurder en sekundær kursleverandør (eller manuell
backfill) for de manglende ~24%. Verifiser dekning/kvalitet før integrasjon.
Først aktuelt hvis Curator-constraintene (≥1 taper) blir vanskelige å møte for
enkelte perioder pga. for få prisede delistede.
