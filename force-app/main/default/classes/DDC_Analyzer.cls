/**
 * Primary analyzer. Pulls metadata via Tooling API and produces findings + plan.
 */
public with sharing class DDC_Analyzer {
    public class Result {
        public List<DDC_Types.Finding> findings = new List<DDC_Types.Finding>();
        public List<DDC_Types.PlanStep> plan = new List<DDC_Types.PlanStep>();
        public Integer flowsScanned = 0;
        public Integer apexScanned = 0;
        public Integer permSetsScanned = 0;
    }

    private final DDC_ToolingApiClient client;
    private final DDC_Settings cfg;

    public DDC_Analyzer(DDC_ToolingApiClient client, DDC_Settings cfg) {
        this.client = client;
        this.cfg = cfg;
    }

    public Result analyze() {
        Result r = new Result();

        List<DDC_FlowModel.FlowInfo> flows = DDC_FlowModel.fetchFlows(client);
        r.flowsScanned = flows.size();

        List<DDC_ApexModel.ApexInfo> apex = DDC_ApexModel.fetchApexClasses(client);
        r.apexScanned = apex.size();

        DDC_PermissionModel.PermSnapshot perms = DDC_PermissionModel.fetchPermissions(client);
        r.permSetsScanned = perms.permissionSets.size();

        DDC_Heuristics h = new DDC_Heuristics(cfg);

        r.findings.addAll(h.analyzeFlows(flows));
        r.findings.addAll(h.analyzeApex(apex));
        r.findings.addAll(h.analyzePermissions(perms));

        r.plan = h.buildPlan(r.findings, flows, apex, perms);

        return r;
    }
}
