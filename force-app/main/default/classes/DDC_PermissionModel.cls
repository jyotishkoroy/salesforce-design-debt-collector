/**
 * Permission set snapshot for overlap analysis.
 */
public class DDC_PermissionModel {
    public class PermSnapshot {
        public List<PermissionSetInfo> permissionSets = new List<PermissionSetInfo>();
        // permSetId -> set of keys
        public Map<String, Set<String>> permKeysByPermSetId = new Map<String, Set<String>>();
    }

    public class PermissionSetInfo {
        public String id;
        public String name;
        public String label;
    }

    public static PermSnapshot fetchPermissions(DDC_ToolingApiClient client) {
        PermSnapshot s = new PermSnapshot();

        List<Object> ps = client.query('SELECT Id, Name, Label, IsOwnedByProfile, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND NamespacePrefix = null');
        for (Object o : ps) {
            Map<String, Object> m = (Map<String, Object>) o;
            PermissionSetInfo i = new PermissionSetInfo();
            i.id = (String) m.get('Id');
            i.name = (String) m.get('Name');
            i.label = (String) m.get('Label');
            s.permissionSets.add(i);
            s.permKeysByPermSetId.put(i.id, new Set<String>());
        }

        // Object permissions
        List<Object> objPerms = client.query('SELECT ParentId, SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions');
        for (Object o : objPerms) {
            Map<String, Object> m = (Map<String, Object>) o;
            String parentId = (String) m.get('ParentId');
            if (!s.permKeysByPermSetId.containsKey(parentId)) continue;

            String sobj = String.valueOf(m.get('SObjectType'));
            for (String key : new List<String>{'Read','Create','Edit','Delete','ViewAll','ModifyAll'}) {
                String field = 'Permissions' + (key=='ViewAll' ? 'ViewAllRecords' : (key=='ModifyAll' ? 'ModifyAllRecords' : key));
                Object val = m.get(field);
                if (val instanceof Boolean && ((Boolean)val)) {
                    s.permKeysByPermSetId.get(parentId).add('OBJ:' + sobj + ':' + key.toUpperCase());
                }
            }
        }

        // Field permissions
        List<Object> fieldPerms = client.query('SELECT ParentId, SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions');
        for (Object o : fieldPerms) {
            Map<String, Object> m = (Map<String, Object>) o;
            String parentId = (String) m.get('ParentId');
            if (!s.permKeysByPermSetId.containsKey(parentId)) continue;

            String sobj = String.valueOf(m.get('SObjectType'));
            String field = String.valueOf(m.get('Field'));
            if (m.get('PermissionsRead') instanceof Boolean && (Boolean)m.get('PermissionsRead')) {
                s.permKeysByPermSetId.get(parentId).add('FLD:' + sobj + '.' + field + ':READ');
            }
            if (m.get('PermissionsEdit') instanceof Boolean && (Boolean)m.get('PermissionsEdit')) {
                s.permKeysByPermSetId.get(parentId).add('FLD:' + sobj + '.' + field + ':EDIT');
            }
        }

        return s;
    }
}
