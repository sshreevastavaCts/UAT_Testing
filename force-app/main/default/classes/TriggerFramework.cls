/**
 * @description Core trigger dispatcher framework that manages trigger execution,
 * bypass logic, and maintains a registry of trigger handlers for different objects.
 * This lightweight framework prevents duplicate logic, ensures execution order,
 * and allows selective logic bypass for data loads/backfills.
 * 
 * Usage in Trigger:
 * trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
 *     TriggerFramework.execute(new CaseTriggerHandler());
 * }
 */
public class TriggerFramework {
    
    // Static registry of active handlers - prevents duplicate handler execution
    private static Map<String, TriggerHandler> handlerRegistry = new Map<String, TriggerHandler>();
    
    // Execution context tracking
    private static Map<String, TriggerContext> executionContexts = new Map<String, TriggerContext>();
    
    /**
     * @description Main entry point for all triggers. Routes the trigger event
     * to the appropriate handler and manages context/bypass logic.
     * 
     * @param handler The TriggerHandler instance for the object
     */
    public static void execute(TriggerHandler handler) {
        String handlerKey = handler.getHandlerKey();
        
        // Guard against duplicate handler execution in the same transaction
        if (handlerRegistry.containsKey(handlerKey)) {
            System.debug('Handler already registered: ' + handlerKey);
            return;
        }
        
        handlerRegistry.put(handlerKey, handler);
        
        // Initialize execution context for this handler
        TriggerContext context = new TriggerContext(
            Trigger.operationType.name(),
            Trigger.isExecuting,
            Trigger.isBefore,
            Trigger.isAfter,
            Trigger.isInsert,
            Trigger.isUpdate,
            Trigger.isDelete,
            Trigger.isUndelete,
            Trigger.new,
            Trigger.newMap,
            Trigger.old,
            Trigger.oldMap,
            Trigger.size
        );
        
        executionContexts.put(handlerKey, context);
        
        // Check if logic is bypassed for this handler
        if (TriggerBypassUtil.isBypassed(handler.getHandlerKey())) {
            System.debug('Trigger logic bypassed for: ' + handlerKey);
            return;
        }
        
        // Execute handler based on trigger event
        if (context.isBefore) {
            if (context.isInsert) {
                handler.beforeInsert(context);
            } else if (context.isUpdate) {
                handler.beforeUpdate(context);
            } else if (context.isDelete) {
                handler.beforeDelete(context);
            }
        }
        
        if (context.isAfter) {
            if (context.isInsert) {
                handler.afterInsert(context);
            } else if (context.isUpdate) {
                handler.afterUpdate(context);
            } else if (context.isDelete) {
                handler.afterDelete(context);
            } else if (context.isUndelete) {
                handler.afterUndelete(context);
            }
        }
    }
    
    /**
     * @description Retrieves the execution context for a handler.
     * Useful for handlers that need access to context information.
     * 
     * @param handlerKey The unique key identifying the handler
     * @return TriggerContext object containing trigger metadata
     */
    public static TriggerContext getContext(String handlerKey) {
        return executionContexts.get(handlerKey);
    }
    
    /**
     * @description Clears the handler registry and execution contexts.
     * Useful for testing to avoid handler conflicts across tests.
     */
    public static void clearRegistry() {
        handlerRegistry.clear();
        executionContexts.clear();
    }
    
    /**
     * @description Inner class that encapsulates the trigger context
     * information and provides helper methods.
     */
    public class TriggerContext {
        public String operationType { get; private set; }
        public Boolean isExecuting { get; private set; }
        public Boolean isBefore { get; private set; }
        public Boolean isAfter { get; private set; }
        public Boolean isInsert { get; private set; }
        public Boolean isUpdate { get; private set; }
        public Boolean isDelete { get; private set; }
        public Boolean isUndelete { get; private set; }
        public List<SObject> newList { get; private set; }
        public Map<Id, SObject> newMap { get; private set; }
        public List<SObject> oldList { get; private set; }
        public Map<Id, SObject> oldMap { get; private set; }
        public Integer size { get; private set; }
        
        public TriggerContext(
            String operationType,
            Boolean isExecuting,
            Boolean isBefore,
            Boolean isAfter,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            Boolean isUndelete,
            List<SObject> newList,
            Map<Id, SObject> newMap,
            List<SObject> oldList,
            Map<Id, SObject> oldMap,
            Integer size
        ) {
            this.operationType = operationType;
            this.isExecuting = isExecuting;
            this.isBefore = isBefore;
            this.isAfter = isAfter;
            this.isInsert = isInsert;
            this.isUpdate = isUpdate;
            this.isDelete = isDelete;
            this.isUndelete = isUndelete;
            this.newList = newList;
            this.newMap = newMap;
            this.oldList = oldList;
            this.oldMap = oldMap;
            this.size = size;
        }
    }
}