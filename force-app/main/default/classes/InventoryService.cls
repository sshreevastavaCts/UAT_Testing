/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class InventoryService {
    public class InventoryRequest {
        @AuraEnabled public Id productId;
        @AuraEnabled public Id locationId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String status;
        @AuraEnabled public String externalRef;
        @AuraEnabled public String batchNumber;
        @AuraEnabled public Date expiryDate;
        @AuraEnabled public Decimal unitCost;
    }

    public class InventoryResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id inventoryId;
        @AuraEnabled public String externalRef;

        public InventoryResult(Boolean success, String message, Id inventoryId, String externalRef) {
            this.success = success;
            this.message = message;
            this.inventoryId = inventoryId;
            this.externalRef = externalRef;
        }
    }

    // Default assumptions for Medical Pharmacy application:
    // - Inventory object: Inventory__c
    // - Lookups: Product__c (to Product2 or Medicine__c), Location__c (to a custom Location object)
    // - Quantity__c (Number), Status__c (Picklist), ExternalRef__c (Text)
    // - Optional: BatchNumber__c (Text), ExpiryDate__c (Date), UnitCost__c (Currency)
    // Adjust field API names in one place if your org differs.
    private static final String F_PRODUCT = 'Product__c';
    private static final String F_LOCATION = 'Location__c';
    private static final String F_QUANTITY = 'Quantity__c';
    private static final String F_STATUS = 'Status__c';
    private static final String F_EXTERNAL_REF = 'ExternalRef__c';
    private static final String F_BATCH = 'BatchNumber__c';
    private static final String F_EXPIRY = 'ExpiryDate__c';
    private static final String F_UNITCOST = 'UnitCost__c';

    @TestVisible private static void validate(InventoryRequest req) {
        if (req == null) {
            throw new InventoryException('Request is required');
        }
        if (req.productId == null) {
            throw new InventoryException('productId is required');
        }
        if (req.locationId == null) {
            throw new InventoryException('locationId is required');
        }
        if (req.quantity == null) {
            throw new InventoryException('quantity is required');
        }
        if (req.quantity < 0) {
            throw new InventoryException('quantity must be non-negative');
        }
    }

    public class InventoryException extends Exception {}

    /**
     * Creates a single Inventory__c record based on defaults.
     * Returns result with success flag and created record Id.
     */
    public static InventoryResult createInventory(InventoryRequest req) {
        try {
            validate(req);

            Inventory__c inv = new Inventory__c();
            SObject sobj = inv;

            // Required fields
            sobj.put(F_PRODUCT, req.productId);
            sobj.put(F_LOCATION, req.locationId);
            sobj.put(F_QUANTITY, req.quantity);

            // Optional fields
            if (String.isNotBlank(req.status)) sobj.put(F_STATUS, req.status);
            if (String.isNotBlank(req.externalRef)) sobj.put(F_EXTERNAL_REF, req.externalRef);
            if (String.isNotBlank(req.batchNumber)) sobj.put(F_BATCH, req.batchNumber);
            if (req.expiryDate != null) sobj.put(F_EXPIRY, req.expiryDate);
            if (req.unitCost != null) sobj.put(F_UNITCOST, req.unitCost);

            insert sobj;

            return new InventoryResult(true, 'Inventory created', (Id)sobj.get('Id'), (String)sobj.get(F_EXTERNAL_REF));
        } catch (Exception e) {
            return new InventoryResult(false, 'Failed to create inventory: ' + e.getMessage(), null, req != null ? req.externalRef : null);
        }
    }

    /**
     * Bulk variant. Attempts to insert all, returns per-item results.
     */
    public static List<InventoryResult> createInventories(List<InventoryRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<InventoryResult>{ new InventoryResult(false, 'Requests list is empty', null, null) };
        }
        List<SObject> toInsert = new List<SObject>();
        List<Integer> indexMap = new List<Integer>();
        List<InventoryResult> results = new List<InventoryResult>();
        results.addAll(new List<InventoryResult>(new InventoryResult[requests.size()]));

        // Build SObjects or capture validation errors
        for (Integer i = 0; i < requests.size(); i++) {
            InventoryRequest req = requests[i];
            try {
                validate(req);
                Inventory__c inv = new Inventory__c();
                SObject sobj = inv;
                sobj.put(F_PRODUCT, req.productId);
                sobj.put(F_LOCATION, req.locationId);
                sobj.put(F_QUANTITY, req.quantity);
                if (String.isNotBlank(req.status)) sobj.put(F_STATUS, req.status);
                if (String.isNotBlank(req.externalRef)) sobj.put(F_EXTERNAL_REF, req.externalRef);
                if (String.isNotBlank(req.batchNumber)) sobj.put(F_BATCH, req.batchNumber);
                if (req.expiryDate != null) sobj.put(F_EXPIRY, req.expiryDate);
                if (req.unitCost != null) sobj.put(F_UNITCOST, req.unitCost);
                toInsert.add(sobj);
                indexMap.add(i);
            } catch (Exception v) {
                results[i] = new InventoryResult(false, 'Validation failed: ' + v.getMessage(), null, req != null ? req.externalRef : null);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] srs = Database.insert(toInsert, false);
            for (Integer j = 0; j < srs.size(); j++) {
                Integer originalIndex = indexMap[j];
                Database.SaveResult sr = srs[j];
                InventoryRequest req = requests[originalIndex];
                if (sr.isSuccess()) {
                    results[originalIndex] = new InventoryResult(true, 'Inventory created', sr.getId(), req != null ? req.externalRef : null);
                } else {
                    results[originalIndex] = new InventoryResult(false, buildErrorMessage(sr.getErrors()), null, req != null ? req.externalRef : null);
                }
            }
        }

        // Fill any remaining nulls (should not happen) with a generic failure
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i] == null) {
                results[i] = new InventoryResult(false, 'Unknown error', null, null);
            }
        }
        return results;
    }

    @TestVisible private static String buildErrorMessage(Database.Error[] errors) {
        if (errors == null || errors.isEmpty()) return 'Unknown DML error';
        List<String> msgs = new List<String>();
        for (Database.Error e : errors) {
            msgs.add(e.getMessage());
        }
        return String.join(msgs, '; ');
    }
}
