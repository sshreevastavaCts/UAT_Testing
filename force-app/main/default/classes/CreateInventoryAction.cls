/**
 * @description       : Flow-invocable action to create Inventory__c records using InventoryService
 * @author            : Agentforce
**/
public with sharing class CreateInventoryAction {
    public class Input {
        @InvocableVariable(required=true) public Id productId;
        @InvocableVariable(required=true) public Id locationId;
        @InvocableVariable(required=true) public Decimal quantity;
        @InvocableVariable public String status;
        @InvocableVariable public String externalRef;
        @InvocableVariable public String batchNumber;
        @InvocableVariable public Date expiryDate;
        @InvocableVariable public Decimal unitCost;
    }

    public class Output {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public Id inventoryId;
        @InvocableVariable public String externalRef;
    }

    @InvocableMethod(label='Create Inventory' description='Creates Inventory__c records in bulk for Medical Pharmacy defaults')
    public static List<Output> createInventory(List<Input> inputs) {
        List<InventoryService.InventoryRequest> reqs = new List<InventoryService.InventoryRequest>();
        if (inputs != null) {
            for (Input inRec : inputs) {
                InventoryService.InventoryRequest r = new InventoryService.InventoryRequest();
                r.productId = inRec.productId;
                r.locationId = inRec.locationId;
                r.quantity = inRec.quantity;
                r.status = inRec.status;
                r.externalRef = inRec.externalRef;
                r.batchNumber = inRec.batchNumber;
                r.expiryDate = inRec.expiryDate;
                r.unitCost = inRec.unitCost;
                reqs.add(r);
            }
        }
        List<InventoryService.InventoryResult> svcResults = InventoryService.createInventories(reqs);
        List<Output> outs = new List<Output>();
        for (InventoryService.InventoryResult r : svcResults) {
            Output o = new Output();
            o.success = r.success;
            o.message = r.message;
            o.inventoryId = r.inventoryId;
            o.externalRef = r.externalRef;
            outs.add(o);
        }
        return outs;
    }
}
