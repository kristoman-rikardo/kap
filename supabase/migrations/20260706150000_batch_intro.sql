-- Batch-level intro (CP 2.3). Spec gap: API-kontrakten (05 §4.1) serverer et
-- batch-nivå introkort (markedssentiment, rentebilde, note), men 02-skjemaet
-- har ingen kolonne for det. Fryses som jsonb ved seal, samme prinsipp som
-- batch_cards.public_payload (uforanderlig kvittering, 02 §8).
alter table game_batches add column intro jsonb;
