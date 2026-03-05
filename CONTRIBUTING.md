# Contributing

Thanks for contributing.

## Development setup
1. Install Salesforce CLI (`sf`)
2. Authenticate to a scratch org or dev org
3. Deploy:
   ```bash
   sf project deploy start
   ```
4. Run tests:
   ```bash
   sf apex run test --tests DDC_AnalyzerServiceTest
   ```

## Pull requests
- Keep PRs focused and small
- Include tests for new logic
- Avoid org-specific assumptions (no hardcoded domain, IDs, etc.)

## Style
- Apex: readable, defensive coding, explicit null handling
- LWC: minimal dependencies, accessible UI

## Licensing
By contributing, you agree your contributions are licensed under Apache-2.0 and attributed in the NOTICE file where appropriate.

Public credit remains:
- Jyotishko Roy (https://orcid.org/0009-0000-2837-4731)
