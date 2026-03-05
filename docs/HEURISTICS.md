# Heuristics

Heuristics are intentionally conservative; output is designed to be *actionable* and *sequenced*.

## Flow heuristics
- Mega-flow: element count exceeds threshold
- Duplicated decision logic: identical normalized decision rule hashes appear across flows
- Split recommendation: isolate sub-process boundaries around duplicated rules or high fan-out decisions

## Apex heuristics
- Async boundary candidate:
  - callout inside loop
  - large DML batches without chunking
  - mixed DML + callout paths
- Suggest Queueable boundary with clear inputs and retry semantics

## Permission set heuristics
- Similarity clustering by overlap of:
  - object permissions
  - field permissions
- Recommend Permission Set Group consolidation when overlap exceeds threshold

## Sequencing (risk-aware)
1. Low-risk hygiene: naming, documentation, exports
2. Consolidations without behavior change (perm group)
3. Extraction (rule service / invocable actions)
4. Splits and async boundaries (behavioral risk)
