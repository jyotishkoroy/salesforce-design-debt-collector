/**
 * DTOs shared by services and UI.
 */
public class DDC_Types {
    public enum Severity { INFO, LOW, MEDIUM, HIGH, CRITICAL }
    public enum Category { FLOW, APEX, PERMISSIONS, GENERAL }

    public class Evidence {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String url;
    }

    public class Finding {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String detail;
        @AuraEnabled public String category;
        @AuraEnabled public String severity;
        @AuraEnabled public String target;
        @AuraEnabled public List<Evidence> evidence;
        @AuraEnabled public List<String> tags;
    }

    public class PlanStep {
        @AuraEnabled public Integer order;
        @AuraEnabled public String title;
        @AuraEnabled public String rationale;
        @AuraEnabled public String risk;
        @AuraEnabled public List<String> dependsOn;
        @AuraEnabled public List<Evidence> evidence;
        @AuraEnabled public List<String> actions;
    }
}
