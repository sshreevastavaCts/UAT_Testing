/**
 * @description Test class for CaseTriggerHandler.
 * Tests business logic implementation and demonstrates handler extensibility.
 */
@isTest
private class CaseTriggerHandlerTest {
    
    @isTest
    static void testFlightDisruptionCancellationAutoResolve() {
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        
        // Create a Flight Disruption Cancellation case
        Case testCase = new Case(
            Subject = 'Flight Cancelled - Refund',
            Reason = 'Flight Disruption',
            Type = 'Cancellation',
            Status = 'New'
        );
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        // Verify the case was auto-resolved with Refund
        Case insertedCase = [SELECT Id, Status, Resolution__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Resolved', insertedCase.Status, 'Status should be set to Resolved');
        System.assertEquals('Refund', insertedCase.Resolution__c, 'Resolution should be set to Refund');
    }
    
    @isTest
    static void testNonCancellationCaseNotAutoResolved() {
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        
        // Create a Flight Disruption case that is NOT a Cancellation
        Case testCase = new Case(
            Subject = 'Flight Delayed',
            Reason = 'Flight Disruption',
            Type = 'Delay',
            Status = 'New'
        );
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        // Verify the case was NOT auto-resolved
        Case insertedCase = [SELECT Id, Status, Resolution__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('New', insertedCase.Status, 'Status should remain New');
        System.assertEquals(null, insertedCase.Resolution__c, 'Resolution should not be set');
    }
    
    @isTest
    static void testNonFlightDisruptionCaseNotAutoResolved() {
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        
        // Create a Cancellation case that is NOT a Flight Disruption
        Case testCase = new Case(
            Subject = 'Booking Cancellation',
            Reason = 'Customer Request',
            Type = 'Cancellation',
            Status = 'New'
        );
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        // Verify the case was NOT auto-resolved
        Case insertedCase = [SELECT Id, Status, Resolution__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('New', insertedCase.Status, 'Status should remain New');
        System.assertEquals(null, insertedCase.Resolution__c, 'Resolution should not be set');
    }
    
    @isTest
    static void testMultipleCasesProcessedCorrectly() {
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        
        // Create multiple cases with different scenarios
        List<Case> testCases = new List<Case>{
            new Case(
                Subject = 'Flight Cancelled',
                Reason = 'Flight Disruption',
                Type = 'Cancellation',
                Status = 'New'
            ),
            new Case(
                Subject = 'Refund Request',
                Reason = 'Flight Disruption',
                Type = 'Refund',
                Status = 'New'
            ),
            new Case(
                Subject = 'Other Cancellation',
                Reason = 'Other',
                Type = 'Cancellation',
                Status = 'New'
            )
        };
        
        Test.startTest();
        insert testCases;
        Test.stopTest();
        
        // Verify only the Flight Disruption Cancellation was auto-resolved
        Case case1 = [SELECT Id, Status, Resolution__c FROM Case WHERE Subject = 'Flight Cancelled'];
        System.assertEquals('Resolved', case1.Status);
        System.assertEquals('Refund', case1.Resolution__c);
        
        Case case2 = [SELECT Id, Status, Resolution__c FROM Case WHERE Subject = 'Refund Request'];
        System.assertEquals('New', case2.Status);
        System.assertEquals(null, case2.Resolution__c);
        
        Case case3 = [SELECT Id, Status, Resolution__c FROM Case WHERE Subject = 'Other Cancellation'];
        System.assertEquals('New', case3.Status);
        System.assertEquals(null, case3.Resolution__c);
    }
    
    @isTest
    static void testHandlerBypass() {
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        
        // Bypass the handler
        TriggerBypassUtil.bypass('CaseTriggerHandler');
        
        Case testCase = new Case(
            Subject = 'Flight Cancelled - No Auto-Resolve',
            Reason = 'Flight Disruption',
            Type = 'Cancellation',
            Status = 'New'
        );
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        // Verify the case was NOT auto-resolved because handler was bypassed
        Case insertedCase = [SELECT Id, Status, Resolution__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('New', insertedCase.Status, 'Status should remain New when bypassed');
        System.assertEquals(null, insertedCase.Resolution__c, 'Resolution should not be set when bypassed');
    }
    
    @isTest
    static void testHandlerKeyIdentification() {
        CaseTriggerHandler handler = new CaseTriggerHandler();
        System.assertEquals('CaseTriggerHandler', handler.getHandlerKey(), 'Handler key should be correctly identified');
    }
    
    @isTest
    static void testFlowCoexistence_AutoResolveTriggersFlowCondition() {
        // This test verifies that Apex sets fields correctly,
        // allowing Record-Triggered Flows to respond to those field changes.
        // 
        // In production: Flow watches for Status='Resolved' and acts accordingly
        // This test ensures Apex does its part correctly.
        
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        
        // Create Flight Disruption Cancellation case
        Case testCase = new Case(
            Subject = 'Flight Cancelled - Flow Coexistence Test',
            Reason = 'Flight Disruption',
            Type = 'Cancellation',
            Status = 'New'
        );
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        // Verify Apex set fields that Flow will watch for
        Case result = [SELECT Id, Status, Reason FROM Case WHERE Id = :testCase.Id];
        
        // These assertions prove Apex did its job
        System.assertEquals('Resolved', result.Status, 
            'Apex should auto-set Status to Resolved (Flow will watch for this)');
        System.assertEquals('Refund', result.Reason, 
            'Apex should auto-set Reason to Refund (Flow will reference this)');
        
        // In real execution:
        // 1. Apex beforeInsert sets Status='Resolved' and Reason='Refund'
        // 2. Record is saved to database
        // 3. Record-Triggered Flow detects Status='Resolved'
        // 4. Flow sends email notification, creates task, etc.
        // 5. No duplicate updates occur because Flow only watches (doesn't modify fields Apex set)
    }
}