/**
 * Minimal Tooling API client for same-org metadata reads.
 *
 * Strategy:
 * - Default: use session-based bearer token against org base URL
 * - Optional: Named Credential (Salesforce type) for strict orgs
 */
public with sharing class DDC_ToolingApiClient {
    private final DDC_Settings cfg;
    private final String apiVersion = '60.0';

    public DDC_ToolingApiClient(DDC_Settings cfg) {
        this.cfg = cfg;
    }

    public List<Object> query(String soql) {
        String endpoint = buildEndpoint('/services/data/v' + apiVersion + '/tooling/query/?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
        Map<String, Object> res = (Map<String, Object>) doGet(endpoint);
        if (res == null || !res.containsKey('records')) return new List<Object>();
        return (List<Object>) res.get('records');
    }

    public Map<String, Object> querySingle(String soql) {
        List<Object> records = query(soql);
        if (records.isEmpty()) return null;
        return (Map<String, Object>) records[0];
    }

    private Object doGet(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');

        if (cfg.useNamedCredential) {
            // callout:NamedCredentialName/services/data/...
            String nc = String.isBlank(cfg.namedCredentialName) ? 'DDC_Self' : cfg.namedCredentialName;
            if (!endpoint.startsWith('callout:')) {
                // endpoint already in callout: form in buildEndpoint when using NC
            }
            req.setEndpoint(endpoint.replace(URL.getSalesforceBaseUrl().toExternalForm(), 'callout:' + nc));
        } else {
            req.setEndpoint(endpoint);
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        }

        req.setHeader('Accept', 'application/json');
        req.setTimeout(120000);

        Http h = new Http();
        HttpResponse resp = h.send(req);

        Integer sc = resp.getStatusCode();
        if (sc >= 200 && sc < 300) {
            return JSON.deserializeUntyped(resp.getBody());
        }
        // Surface readable error
        throw new CalloutException('Tooling API call failed (' + sc + '): ' + safeTrim(resp.getBody(), 1000));
    }

    private String buildEndpoint(String pathAndQuery) {
        String base = URL.getSalesforceBaseUrl().toExternalForm();
        return base + pathAndQuery;
    }

    private static String safeTrim(String s, Integer maxLen) {
        if (s == null) return null;
        if (s.length() <= maxLen) return s;
        return s.substring(0, maxLen) + '…';
    }
}
