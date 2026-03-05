/**
 * Apex metadata fetch + static analysis heuristics.
 */
public class DDC_ApexModel {
    public class ApexInfo {
        public String id;
        public String name;
        public String body;
        public String toolingUrl;
    }

    public static List<ApexInfo> fetchApexClasses(DDC_ToolingApiClient client) {
        List<ApexInfo> out = new List<ApexInfo>();
        // Exclude managed package classes for signal quality.
        List<Object> classes = client.query(
            'SELECT Id, Name, Body, NamespacePrefix FROM ApexClass WHERE NamespacePrefix = null'
        );
        for (Object o : classes) {
            Map<String, Object> c = (Map<String, Object>) o;
            ApexInfo a = new ApexInfo();
            a.id = (String) c.get('Id');
            a.name = (String) c.get('Name');
            a.body = (String) c.get('Body');
            a.toolingUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/setup/ApexClasses/page?address=%2F' + a.id;
            out.add(a);
        }
        return out;
    }
}
