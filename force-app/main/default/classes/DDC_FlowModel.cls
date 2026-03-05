/**
 * Flow metadata fetch + parsing helpers.
 */
public class DDC_FlowModel {
    public class FlowInfo {
        public String id;
        public String apiName;
        public String label;
        public String status;
        public Integer versionNumber;
        public Integer elementCount;
        public Map<String, Integer> decisionRuleHashes; // hash -> count
        public String toolingUrl;
    }

    public static List<FlowInfo> fetchFlows(DDC_ToolingApiClient client) {
        List<FlowInfo> out = new List<FlowInfo>();

        // Pull active and latest flow versions for org (limited fields).
        // FlowDefinitionView provides a convenient view; fall back to Flow if needed.
        List<Object> defs = client.query(
            'SELECT DurableId, ApiName, MasterLabel, ActiveVersionId, LatestVersionId ' +
            'FROM FlowDefinitionView WHERE ApiName != null'
        );

        for (Object o : defs) {
            Map<String, Object> d = (Map<String, Object>) o;
            String latestId = (String) d.get('LatestVersionId');
            if (String.isBlank(latestId)) continue;

            Map<String, Object> f = client.querySingle(
                'SELECT Id, Status, VersionNumber, ApiVersion, Metadata ' +
                'FROM Flow WHERE Id = \''
                + latestId.replace('\'', '') + '\''
            );
            if (f == null) continue;

            FlowInfo info = new FlowInfo();
            info.id = (String) f.get('Id');
            info.apiName = (String) d.get('ApiName');
            info.label = (String) d.get('MasterLabel');
            info.status = (String) f.get('Status');
            info.versionNumber = f.get('VersionNumber') == null ? null : Integer.valueOf(String.valueOf(f.get('VersionNumber')));
            info.toolingUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/setup/Flows/page?address=%2F' + info.id;

            // Parse flow metadata (XML-ish payload inside JSON).
            info.elementCount = 0;
            info.decisionRuleHashes = new Map<String, Integer>();

            try {
                Map<String, Object> metadata = (Map<String, Object>) f.get('Metadata');
                if (metadata != null) {
                    String xml = (String) metadata.get('xml');
                    if (String.isNotBlank(xml)) {
                        parseFlowXml(xml, info);
                    }
                }
            } catch (Exception e) {
                // Keep partial info.
            }

            out.add(info);
        }
        return out;
    }

    private static void parseFlowXml(String xml, FlowInfo info) {
        Dom.Document doc = new Dom.Document();
        doc.load(xml);
        Dom.XmlNode root = doc.getRootElement();
        if (root == null) return;

        // Element count heuristic: count common node types.
        Integer count = 0;
        List<String> nodesToCount = new List<String>{
            'actionCalls', 'assignments', 'decisions', 'loops', 'recordCreates',
            'recordDeletes', 'recordLookups', 'recordUpdates', 'screens', 'subflows', 'waits'
        };
        for (String n : nodesToCount) {
            List<Dom.XmlNode> children = root.getChildElements();
            for (Dom.XmlNode c : children) {
                if (c.getName() == n) count += c.getChildElements().size() > 0 ? c.getChildElements().size() : 1;
            }
        }
        info.elementCount = count;

        // Decision rule hash: normalize decision labels + conditions
        for (Dom.XmlNode c : root.getChildElements()) {
            if (c.getName() != 'decisions') continue;
            String normalized = normalizeDecisionNode(c);
            String hash = sha256(normalized);
            Integer existing = info.decisionRuleHashes.containsKey(hash) ? info.decisionRuleHashes.get(hash) : 0;
            info.decisionRuleHashes.put(hash, existing + 1);
        }
    }

    private static String normalizeDecisionNode(Dom.XmlNode decisionNode) {
        // Keep it stable: name + rule conditions (without whitespace).
        String raw = decisionNode.toXmlString();
        raw = raw.replaceAll('\\s+', '');
        // Remove org-specific ids if any appear.
        raw = raw.replaceAll('[a-zA-Z0-9]{15,18}', 'ID');
        return raw;
    }

    private static String sha256(String input) {
        Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(input == null ? '' : input));
        return EncodingUtil.convertToHex(b);
    }
}
