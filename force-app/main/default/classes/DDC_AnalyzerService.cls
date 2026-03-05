/**
 * Design Debt Collector
 * Public credit: Jyotishko Roy (https://orcid.org/0009-0000-2837-4731)
 * License: Apache-2.0 (see repository root)
 */
public with sharing class DDC_AnalyzerService {
    public class AnalysisResponse {
        @AuraEnabled public String orgId;
        @AuraEnabled public String orgDomain;
        @AuraEnabled public String generatedAtIso;
        @AuraEnabled public List<DDC_Types.Finding> findings;
        @AuraEnabled public List<DDC_Types.PlanStep> plan;
        @AuraEnabled public Map<String, Object> summary;
    }

    @AuraEnabled(cacheable=false)
    public static AnalysisResponse runAnalysis() {
        AnalysisResponse res = new AnalysisResponse();
        res.orgId = UserInfo.getOrganizationId();
        res.orgDomain = URL.getSalesforceBaseUrl().toExternalForm();
        res.generatedAtIso = Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        DDC_Settings cfg = DDC_Settings.load();

        DDC_ToolingApiClient client = new DDC_ToolingApiClient(cfg);
        DDC_Analyzer analyzer = new DDC_Analyzer(client, cfg);

        DDC_Analyzer.Result r = analyzer.analyze();

        res.findings = r.findings;
        res.plan = r.plan;

        res.summary = new Map<String, Object>{
            'flowsScanned' => r.flowsScanned,
            'apexClassesScanned' => r.apexScanned,
            'permissionSetsScanned' => r.permSetsScanned,
            'settings' => cfg.toPublicMap()
        };
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBuildInfo() {
        return new Map<String, Object>{
            'name' => 'Design Debt Collector',
            'version' => '1.0.0',
            'author' => 'Jyotishko Roy',
            'orcid' => 'https://orcid.org/0009-0000-2837-4731',
            'license' => 'Apache-2.0'
        };
    }
}
