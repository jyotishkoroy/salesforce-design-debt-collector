/**
 * Findings + plan builder.
 *
 * This is intentionally conservative and produces sequenced steps.
 */
public with sharing class DDC_Heuristics {
    private final DDC_Settings cfg;

    public DDC_Heuristics(DDC_Settings cfg) {
        this.cfg = cfg;
    }

    public List<DDC_Types.Finding> analyzeFlows(List<DDC_FlowModel.FlowInfo> flows) {
        List<DDC_Types.Finding> out = new List<DDC_Types.Finding>();
        Map<String, List<String>> decisionHashToFlows = new Map<String, List<String>>();

        for (DDC_FlowModel.FlowInfo f : flows) {
            if (f.elementCount != null && f.elementCount > cfg.maxFlowElements) {
                out.add(newFinding(
                    'flow-mega-' + f.apiName,
                    'Mega flow: ' + f.label,
                    'This flow appears large (' + f.elementCount + ' elements). Large flows are harder to test and refactor safely. Consider splitting into subflows and extracting shared logic.',
                    'FLOW',
                    'MEDIUM',
                    f.apiName,
                    new List<DDC_Types.Evidence>{
                        ev('Elements', String.valueOf(f.elementCount), null),
                        ev('Tooling link', 'Open flow', f.toolingUrl)
                    },
                    new List<String>{'split', 'subflow'}
                ));
            }

            if (f.decisionRuleHashes != null) {
                for (String h : f.decisionRuleHashes.keySet()) {
                    if (!decisionHashToFlows.containsKey(h)) decisionHashToFlows.put(h, new List<String>());
                    decisionHashToFlows.get(h).add(f.apiName);
                }
            }
        }

        for (String h : decisionHashToFlows.keySet()) {
            List<String> owners = decisionHashToFlows.get(h);
            if (owners != null && owners.size() >= 3) {
                out.add(newFinding(
                    'flow-dupdec-' + h.substring(0, 10),
                    'Duplicated decision logic across flows',
                    'Identical decision logic appears in multiple flows: ' + String.join(owners, ', ') + '. Consider extracting this into a shared invocable action or a rule service.',
                    'FLOW',
                    'LOW',
                    'Decision logic hash ' + h.substring(0, 12),
                    new List<DDC_Types.Evidence>{ ev('Flows', String.valueOf(owners.size()), null) },
                    new List<String>{'dedupe', 'rule-service'}
                ));
            }
        }

        return out;
    }

    public List<DDC_Types.Finding> analyzeApex(List<DDC_ApexModel.ApexInfo> apex) {
        List<DDC_Types.Finding> out = new List<DDC_Types.Finding>();
        for (DDC_ApexModel.ApexInfo a : apex) {
            if (String.isBlank(a.body)) continue;

            // Heuristic flags (regex-based).
            Boolean hasCallout = a.body.contains('HttpRequest') || a.body.contains('Http(') || a.body.contains('callout:');
            Boolean hasLoop = a.body.contains('for (') || a.body.contains('while (');
            Boolean hasDml = a.body.contains('insert ') || a.body.contains('update ') || a.body.contains('delete ') || a.body.contains('upsert ');
            Boolean calloutInLoop = hasCallout && hasLoop && a.body.matches('(?s).*for\s*\(.*\).*HttpRequest.*');

            if (calloutInLoop) {
                out.add(newFinding(
                    'apex-callout-loop-' + a.name,
                    'Callout inside loop: ' + a.name,
                    'Potential governor-limit and reliability issue. Consider moving callouts to a Queueable job and batching inputs.',
                    'APEX',
                    'HIGH',
                    a.name,
                    new List<DDC_Types.Evidence>{ ev('Tooling link', 'Open class', a.toolingUrl) },
                    new List<String>{'async', 'queueable', 'callout'}
                ));
            } else if (hasCallout && hasDml) {
                out.add(newFinding(
                    'apex-callout-dml-' + a.name,
                    'Mixed callout + DML: ' + a.name,
                    'Mixing callouts and DML often leads to retry complexity and partial failures. Consider establishing an async boundary.',
                    'APEX',
                    'MEDIUM',
                    a.name,
                    new List<DDC_Types.Evidence>{ ev('Tooling link', 'Open class', a.toolingUrl) },
                    new List<String>{'async-boundary'}
                ));
            }
        }
        return out;
    }

    public List<DDC_Types.Finding> analyzePermissions(DDC_PermissionModel.PermSnapshot perms) {
        List<DDC_Types.Finding> out = new List<DDC_Types.Finding>();
        List<DDC_PermissionModel.PermissionSetInfo> ps = perms.permissionSets;

        // Pairwise overlap (O(n^2) but orgs typically manageable; cap to 200).
        Integer cap = Math.min(ps.size(), 200);
        for (Integer i = 0; i < cap; i++) {
            for (Integer j = i+1; j < cap; j++) {
                String aId = ps[i].id, bId = ps[j].id;
                Set<String> aKeys = perms.permKeysByPermSetId.get(aId);
                Set<String> bKeys = perms.permKeysByPermSetId.get(bId);
                Decimal overlap = jaccard(aKeys, bKeys);
                if (overlap >= cfg.permissionOverlapThreshold && overlap > 0) {
                    out.add(newFinding(
                        'perm-overlap-' + ps[i].name + '-' + ps[j].name,
                        'High permission overlap: ' + ps[i].label + ' ↔ ' + ps[j].label,
                        'These permission sets overlap heavily (Jaccard ~ ' + overlap.setScale(2) + '). Consider consolidating via a Permission Set Group or factoring common access into a shared permset.',
                        'PERMISSIONS',
                        'LOW',
                        ps[i].name + ' / ' + ps[j].name,
                        new List<DDC_Types.Evidence>{ ev('Jaccard', String.valueOf(overlap.setScale(4)), null) },
                        new List<String>{'permset-group', 'cleanup'}
                    ));
                }
            }
        }
        return out;
    }

    public List<DDC_Types.PlanStep> buildPlan(
        List<DDC_Types.Finding> findings,
        List<DDC_FlowModel.FlowInfo> flows,
        List<DDC_ApexModel.ApexInfo> apex,
        DDC_PermissionModel.PermSnapshot perms
    ) {
        List<DDC_Types.PlanStep> plan = new List<DDC_Types.PlanStep>();

        Integer order = 1;

        // 1) Baseline: export and document
        plan.add(step(order++,
            'Baseline exports + inventory',
            'Create a snapshot (JSON/CSV) and confirm ownership of key automations before any change.',
            'LOW',
            new List<String>(),
            new List<String>{'Run DDC export and store in your backlog repo.'}
        ));

        // 2) Permission consolidation
        if (hasCategory(findings, 'PERMISSIONS')) {
            plan.add(step(order++,
                'Consolidate overlapping permission sets',
                'Permission Set Groups reduce long-term admin overhead without changing business logic.',
                'LOW',
                new List<String>{ String.valueOf(order-2) },
                new List<String>{'Create Permission Set Groups for overlap clusters.', 'Move shared access into base permsets.'}
            ));
        }

        // 3) Extract duplicated flow decision logic
        if (hasTag(findings, 'rule-service')) {
            plan.add(step(order++,
                'Extract duplicated decision logic into a rule service',
                'Shared rules reduce drift and make flow refactors safer.',
                'MEDIUM',
                new List<String>{},
                new List<String>{'Create an invocable Apex action or subflow for shared decisions.', 'Replace duplicated decisions incrementally.'}
            ));
        }

        // 4) Split mega flows into subflows
        if (hasTag(findings, 'split')) {
            plan.add(step(order++,
                'Split mega flows into subflows',
                'Smaller flows are easier to test, deploy, and troubleshoot.',
                'MEDIUM',
                new List<String>{},
                new List<String>{'Identify stable sub-processes and extract into subflows.', 'Keep entry flow as orchestrator.'}
            ));
        }

        // 5) Async boundaries for Apex
        if (hasTag(findings, 'async')) {
            plan.add(step(order++,
                'Introduce async boundaries for risky Apex paths',
                'Queueable boundaries reduce governor pressure and isolate retries.',
                'HIGH',
                new List<String>{},
                new List<String>{'Wrap callouts in Queueable.', 'Batch inputs and add idempotency guards.'}
            ));
        }

        // Final: verification
        plan.add(step(order++,
            'Verification + rollback readiness',
            'Re-run analysis, confirm metric improvements, and ensure rollback plan exists (versions, backups, deployments).',
            'LOW',
            new List<String>{},
            new List<String>{'Re-run DDC and compare exports.', 'Run tests and validate critical business flows.'}
        ));

        return plan;
    }

    private static Boolean hasCategory(List<DDC_Types.Finding> findings, String cat) {
        for (DDC_Types.Finding f : findings) if (f != null && f.category == cat) return true;
        return false;
    }
    private static Boolean hasTag(List<DDC_Types.Finding> findings, String tag) {
        for (DDC_Types.Finding f : findings) {
            if (f != null && f.tags != null && f.tags.contains(tag)) return true;
        }
        return false;
    }

    private static DDC_Types.PlanStep step(Integer order, String title, String rationale, String risk, List<String> dependsOn, List<String> actions) {
        DDC_Types.PlanStep s = new DDC_Types.PlanStep();
        s.order = order;
        s.title = title;
        s.rationale = rationale;
        s.risk = risk;
        s.dependsOn = dependsOn;
        s.actions = actions;
        s.evidence = new List<DDC_Types.Evidence>();
        return s;
    }

    private static DDC_Types.Evidence ev(String label, String value, String url) {
        DDC_Types.Evidence e = new DDC_Types.Evidence();
        e.label = label; e.value = value; e.url = url;
        return e;
    }

    private static DDC_Types.Finding newFinding(String id, String title, String detail, String category, String severity, String target,
                                                List<DDC_Types.Evidence> evidence, List<String> tags) {
        DDC_Types.Finding f = new DDC_Types.Finding();
        f.id = id;
        f.title = title;
        f.detail = detail;
        f.category = category;
        f.severity = severity;
        f.target = target;
        f.evidence = evidence == null ? new List<DDC_Types.Evidence>() : evidence;
        f.tags = tags == null ? new List<String>() : tags;
        return f;
    }

    private static Decimal jaccard(Set<String> a, Set<String> b) {
        if (a == null || b == null) return 0;
        if (a.isEmpty() && b.isEmpty()) return 0;
        Integer inter = 0;
        // iterate smaller
        Set<String> small = a.size() <= b.size() ? a : b;
        Set<String> large = a.size() > b.size() ? a : b;
        for (String k : small) if (large.contains(k)) inter++;
        Integer union = a.size() + b.size() - inter;
        if (union <= 0) return 0;
        return Decimal.valueOf(inter) / Decimal.valueOf(union);
    }
}
