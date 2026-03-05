# Architecture

## Layers

1. **LWC UI**
   - Runs in Lightning Experience
   - Requests analysis + renders findings and plan
   - Exports: JSON and CSV

2. **Apex Services**
   - `DDC_AnalyzerService` (entry point)
   - `DDC_ToolingApiClient` (Tooling API query abstraction)
   - `DDC_Heuristics` (scoring, clustering, sequencing)

3. **Configuration (optional)**
   - Custom Metadata Type: `DDC_Settings__mdt`
   - Thresholds and callout mode toggles

## Data flow

UI → `DDC_AnalyzerService.runAnalysis()` → Tooling queries → heuristics → response DTO → UI.

## Security
- `with sharing` where applicable
- No data is persisted
- Only metadata is read; no metadata is modified
