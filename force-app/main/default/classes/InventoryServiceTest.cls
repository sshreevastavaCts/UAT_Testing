/**
 * @description       : Unit tests for InventoryService and CreateInventoryAction
 * Covers single and bulk creation, validations, and Flow-invocable mapping.
**/
@IsTest
private class InventoryServiceTest {
    // Helper to create minimal related records. Adjust object/field names if your org differs.
    private static Id ensureProduct() {
        // Try to use standard Product2; if not available in the org metadata, tests may be adjusted.
        Product2 p = new Product2(Name = 'Test Medicine', IsActive = true);
        insert p;
        return p.Id;
    }
    private static SObject createLocationStub() {
        // Assumes a custom Location object exists. If standard Location is enabled, replace with Location.
        // Using a generic SObject for Location__c to avoid compile-time dependency in case of different API name.
        SObject loc = (SObject) Type.forName('Location__c').newInstance();
        loc.put('Name', 'Main Pharmacy');
        insert loc;
        return loc;
    }

    @IsTest
    static void test_create_single_success() {
        Id productId = ensureProduct();
        SObject loc = createLocationStub();

        InventoryService.InventoryRequest req = new InventoryService.InventoryRequest();
        req.productId = productId;
        req.locationId = (Id) loc.get('Id');
        req.quantity = 10;
        req.status = 'Available';
        req.externalRef = 'EXT-1';
        req.batchNumber = 'B-001';
        req.expiryDate = Date.today().addDays(365);
        req.unitCost = 12.5;

        Test.startTest();
        InventoryService.InventoryResult res = InventoryService.createInventory(req);
        Test.stopTest();

        System.assertEquals(true, res.success, 'Expected success');
        System.assertNotEquals(null, res.inventoryId, 'Inventory Id should be populated');
    }

    @IsTest
    static void test_create_single_validation_missing_fields() {
        InventoryService.InventoryRequest bad = new InventoryService.InventoryRequest();
        // Missing productId, locationId, quantity
        Test.startTest();
        InventoryService.InventoryResult res = InventoryService.createInventory(bad);
        Test.stopTest();
        System.assertEquals(false, res.success, 'Expected failure on validation');
        System.assert(res.message.contains('required') || res.message.contains('Failed to create'), 'Error message should indicate missing required fields');
    }

    @IsTest
    static void test_create_bulk_mixed_results() {
        Id productId = ensureProduct();
        SObject loc = createLocationStub();

        List<InventoryService.InventoryRequest> reqs = new List<InventoryService.InventoryRequest>();

        // Valid
        InventoryService.InventoryRequest r1 = new InventoryService.InventoryRequest();
        r1.productId = productId;
        r1.locationId = (Id) loc.get('Id');
        r1.quantity = 5;
        reqs.add(r1);

        // Invalid - missing productId
        InventoryService.InventoryRequest r2 = new InventoryService.InventoryRequest();
        r2.locationId = (Id) loc.get('Id');
        r2.quantity = 3;
        reqs.add(r2);

        // Invalid - negative qty
        InventoryService.InventoryRequest r3 = new InventoryService.InventoryRequest();
        r3.productId = productId;
        r3.locationId = (Id) loc.get('Id');
        r3.quantity = -2;
        reqs.add(r3);

        Test.startTest();
        List<InventoryService.InventoryResult> results = InventoryService.createInventories(reqs);
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Expect 3 results');
        System.assertEquals(true, results[0].success, 'First should succeed');
        System.assertEquals(false, results[1].success, 'Second should fail validation');
        System.assertEquals(false, results[2].success, 'Third should fail validation');
    }

    @IsTest
    static void test_invocable_flow_bridge() {
        Id productId = ensureProduct();
        SObject loc = createLocationStub();

        CreateInventoryAction.Input in1 = new CreateInventoryAction.Input();
        in1.productId = productId;
        in1.locationId = (Id) loc.get('Id');
        in1.quantity = 7;
        in1.status = 'Available';
        in1.externalRef = 'EXT-FLOW-1';

        List<CreateInventoryAction.Input> inputs = new List<CreateInventoryAction.Input>{ in1 };

        Test.startTest();
        List<CreateInventoryAction.Output> outs = CreateInventoryAction.createInventory(inputs);
        Test.stopTest();

        System.assertEquals(1, outs.size(), 'One output expected');
        System.assertEquals(true, outs[0].success, 'Should succeed');
        System.assertNotEquals(null, outs[0].inventoryId, 'Inventory Id expected');
        System.assertEquals('EXT-FLOW-1', outs[0].externalRef, 'ExternalRef mapping should pass through');
    }
}
