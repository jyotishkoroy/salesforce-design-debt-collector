# Setup (Design Debt Collector)

This project is built as a Salesforce DX (source format) package.

## Standard install path (recommended)

### 1) Deploy
```bash
sf project deploy start
```

### 2) Assign permission set
```bash
sf org assign permset --name Design_Debt_Collector
```

### 3) Open the UI
```bash
sf org open --path /lightning/n/DDC_Design_Debt_Collector
```

---

## Tooling API callouts (what you need to know)

Design Debt Collector queries Tooling API endpoints inside your own org. Most orgs allow this out of the box.

If your org blocks same-org callouts, use the **Named Credential** fallback:

### Named Credential fallback (strict orgs)

1. In Setup → **Named Credentials** → New
2. Type: **Salesforce**
3. Label/Name: `DDC_Self`
4. URL: leave default (or your My Domain base URL)
5. Identity Type: **Named Principal**
6. Authentication: **OAuth 2.0**
7. Scope: `full` or minimally `api` (plus what your org requires)

Then set the Custom Metadata value:
- `DDC_Settings__mdt.Default` → `Use_Named_Credential__c = true`
- and `Named_Credential_Name__c = DDC_Self`

> This keeps the app compatible with orgs that disallow session-based callouts.

---

## Uninstall
- Remove the permission set assignment
- Delete deployed metadata (or uninstall unlocked package if you created one)

---

## Troubleshooting
- “Insufficient access” → ensure the user has **API Enabled** and can read metadata
- “Callout blocked” → use Named Credential fallback above
