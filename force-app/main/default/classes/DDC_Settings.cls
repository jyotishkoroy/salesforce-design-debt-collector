/**
 * Runtime settings loader (Custom Metadata).
 */
public class DDC_Settings {
    public Integer maxFlowElements;
    public Decimal permissionOverlapThreshold;
    public Boolean useNamedCredential;
    public String namedCredentialName;

    public static DDC_Settings load() {
        DDC_Settings s = new DDC_Settings();
        s.maxFlowElements = 250;
        s.permissionOverlapThreshold = 0.80;
        s.useNamedCredential = false;
        s.namedCredentialName = 'DDC_Self';

        try {
            DDC_Settings__mdt m = [SELECT Max_Flow_Elements__c, Permission_Overlap_Threshold__c, Use_Named_Credential__c, Named_Credential_Name__c
                                  FROM DDC_Settings__mdt WHERE DeveloperName = 'Default' LIMIT 1];
            if (m.Max_Flow_Elements__c != null) s.maxFlowElements = Integer.valueOf(m.Max_Flow_Elements__c);
            if (m.Permission_Overlap_Threshold__c != null) s.permissionOverlapThreshold = Decimal.valueOf(m.Permission_Overlap_Threshold__c);
            if (m.Use_Named_Credential__c != null) s.useNamedCredential = m.Use_Named_Credential__c;
            if (String.isNotBlank(m.Named_Credential_Name__c)) s.namedCredentialName = m.Named_Credential_Name__c;
        } catch (Exception e) {
            // If metadata isn't accessible, keep defaults.
        }
        return s;
    }

    public Map<String, Object> toPublicMap() {
        return new Map<String, Object>{
            'maxFlowElements' => maxFlowElements,
            'permissionOverlapThreshold' => permissionOverlapThreshold,
            'useNamedCredential' => useNamedCredential,
            'namedCredentialName' => namedCredentialName
        };
    }
}
