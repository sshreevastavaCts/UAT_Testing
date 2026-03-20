/**
 * @description Test class for TriggerFramework core functionality.
 * Tests registry management, execution context, and bypass logic.
 */
@isTest
private class TriggerFrameworkTest {
    
    // Static counter for mock handler execution tracking
    static Integer mockHandlerExecutionCount = 0;
    
    @isTest
    static void testFrameworkInitialization() {
        TriggerFramework.clearRegistry();
        mockHandlerExecutionCount = 0;
        
        TriggerFramework.execute(new MockTriggerHandler());
        
        MockTriggerHandler handler = new MockTriggerHandler();
        String handlerKey = handler.getHandlerKey();
        
        TriggerFramework.TriggerContext context = TriggerFramework.getContext(handlerKey);
        System.assertNotEquals(null, context, 'Context should be populated after execute');
    }
    
    @isTest
    static void testHandlerRegistryPreventsDuplicates() {
        TriggerFramework.clearRegistry();
        mockHandlerExecutionCount = 0;
        
        TriggerFramework.execute(new MockTriggerHandler());
        TriggerFramework.execute(new MockTriggerHandler());
        
        // Should only execute once due to registry check
        System.assertEquals(1, mockHandlerExecutionCount, 'Handler should only execute once');
    }
    
    @isTest
    static void testContextDataPopulation() {
        TriggerFramework.clearRegistry();
        mockHandlerExecutionCount = 0;
        
        TriggerFramework.execute(new MockTriggerHandler());
        
        TriggerFramework.TriggerContext ctx = TriggerFramework.getContext('MockTriggerHandler');
        System.assertNotEquals(null, ctx.newList, 'newList should be available');
        System.assertNotEquals(null, ctx.oldMap, 'oldMap should be available');
    }
    
    @isTest
    static void testBypassLogic() {
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        mockHandlerExecutionCount = 0;
        
        TriggerBypassUtil.bypass('MockTriggerHandler');
        TriggerFramework.execute(new MockTriggerHandler());
        
        System.assertEquals(0, mockHandlerExecutionCount, 'Bypassed handler should not execute');
    }
    
    @isTest
    static void testClearRegistry() {
        TriggerFramework.clearRegistry();
        TriggerBypassUtil.clearAllBypasses();
        mockHandlerExecutionCount = 0;
        
        TriggerFramework.execute(new MockTriggerHandler());
        TriggerFramework.clearRegistry();
        
        // Can execute again after clear
        TriggerFramework.execute(new MockTriggerHandler());
        System.assertEquals(2, mockHandlerExecutionCount, 'Should execute twice after clear');
    }
    
    // Mock handler for testing framework
    private class MockTriggerHandler extends TriggerHandler {
        
        public override String getHandlerKey() {
            return 'MockTriggerHandler';
        }
        
        public override void beforeInsert(TriggerFramework.TriggerContext context) {
            mockHandlerExecutionCount++;
        }
    }
}