# Design Debt Collector (Salesforce)

A lightweight **Salesforce DX** app that scans your org’s automation and security metadata and produces a **sequenced refactor plan** — not just findings.

It focuses on:
- **Flows**: identify oversized flows, detect repeated decision logic, and propose split/extract steps
- **Apex**: flag async boundary candidates (callouts + heavy DML patterns) and suggest queueable boundaries
- **Permission Sets**: detect overlap clusters and recommend **Permission Set Group** consolidation

> Public credit: **Jyotishko Roy** — https://orcid.org/0009-0000-2837-4731

---

## Why this exists

Most “health check” tools stop after listing problems. Design Debt Collector goes further:
- builds a **dependency-aware** change list
- outputs **stepwise remediation** (safe first, risky last)
- provides **exports** for backlog/tools (CSV/JSON)

---

## Quick start

### Prerequisites
- Salesforce CLI (sf)
- A Salesforce org (Developer, Sandbox, Scratch, Production with deployment access)
- API enabled (standard)

### Install / Deploy (any org)
1. Clone:
   ```bash
   git clone https://github.com/<you>/design-debt-collector.git
   cd design-debt-collector
   ```

2. Authorize:
   ```bash
   sf org login web --set-default --alias ddc
   ```

3. Deploy metadata:
   ```bash
   sf project deploy start
   ```

4. Assign permissions:
   ```bash
   sf org assign permset --name Design_Debt_Collector
   ```

5. Open the app:
   ```bash
   sf org open --path /lightning/n/DDC_Design_Debt_Collector
   ```

---

## How it works (high level)

The UI calls Apex which queries the **Tooling API** for:
- Flow definitions + latest versions (with metadata payload where available)
- Apex class bodies for static pattern checks
- Permission sets and their object/field permissions for similarity clustering

The analyzer produces:
- `findings[]` (severity, category, evidence)
- `plan[]` (ordered steps with rationale + estimated risk)

No custom objects are required. One **Custom Metadata Type** is included for thresholds (optional).

---

## Compatibility notes

This app is designed to run in *any* Salesforce org with API access.

Callout strategy:
- Prefer an org’s own session to call the Tooling API endpoint for the same org.
- Uses the org base URL at runtime; see `ToolingApiClient`.

If your org enforces stricter callout policies, follow `docs/SETUP.md` for the alternate Named Credential approach.

---

## Documentation
- **Setup guide:** `docs/SETUP.md`
- **Architecture:** `docs/ARCHITECTURE.md`
- **Heuristics:** `docs/HEURISTICS.md`
- **Release checklist:** `docs/RELEASE.md`

---

## License & attribution

- Code: **Apache-2.0**
- Copyright © 2026 Jyotishko Roy
- See `LICENSE`, `NOTICE`, `CITATION.cff`

---

## Support / security

Please see **SECURITY.md** for reporting vulnerabilities responsibly.
