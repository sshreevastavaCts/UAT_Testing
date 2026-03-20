/**
 * @description Handler for Case trigger events.
 * Demonstrates the trigger framework by implementing business logic without
 * modifying the trigger itself.
 * 
 * Business Rules:
 * 1. Flight Disruption Cases with Type = 'Cancellation' get auto-resolved with "Refund"
 * 2. New rules can be added to handler methods without touching the trigger
 */
public class CaseTriggerHandler extends TriggerHandler {
    
    // Configuration - can be moved to custom metadata for flexibility
    private static final String FLIGHT_DISRUPTION_REASON = 'Flight Disruption';
    private static final String CANCELLATION_TYPE = 'Cancellation';
    private static final String REFUND_RESOLUTION = 'Refund';
    
    public override String getHandlerKey() {
        return 'CaseTriggerHandler';
    }
    
    /**
     * @description Handles logic before a Case is inserted.
     * Example: Auto-populate fields based on case type/reason
     */
    public override void beforeInsert(TriggerFramework.TriggerContext context) {
        List<Case> newCases = context.newList;
        
        // Rule 1: Auto-resolve Flight Disruption Cancellations
        for (Case c : newCases) {
            if (isFlightDisruptionCancellation(c)) {
                c.Resolution__c = REFUND_RESOLUTION;
                c.Status = 'Resolved';
            }
        }
    }
    
    /**
     * @description Handles logic after Cases are inserted.
     * Example: Create related records, send notifications
     */
    public override void afterInsert(TriggerFramework.TriggerContext context) {
        List<Case> newCases = context.newList;
        
        // Rule: Log case creation for audit trail (example only)
        logCaseCreations(newCases);
    }
    
    /**
     * @description Handles logic before a Case is updated.
     * Example: Validate field transitions, auto-calculate values
     */
    public override void beforeUpdate(TriggerFramework.TriggerContext context) {
        List<Case> newCases = context.newList;
        Map<Id, Case> oldCasesMap = (Map<Id, Case>) context.oldMap;
        
        for (Case newCase : newCases) {
            Case oldCase = oldCasesMap.get(newCase.Id);
            
            // Example rule: Prevent status change if case is resolved
            if (oldCase.Status == 'Resolved' && newCase.Status != 'Resolved') {
                newCase.addError('Cannot change status of resolved cases');
            }
        }
    }
    
    /**
     * @description Handles logic after Cases are updated.
     * Example: Trigger downstream processes, update related records
     */
    public override void afterUpdate(TriggerFramework.TriggerContext context) {
        List<Case> newCases = context.newList;
        Map<Id, Case> oldCasesMap = (Map<Id, Case>) context.oldMap;
        
        // Example: Track status changes for analytics
        List<Case> statusChangedCases = new List<Case>();
        for (Case newCase : newCases) {
            Case oldCase = oldCasesMap.get(newCase.Id);
            if (newCase.Status != oldCase.Status) {
                statusChangedCases.add(newCase);
            }
        }
    }
    
    /**
     * @description Helper method to determine if a case is a Flight Disruption Cancellation.
     * This logic can be extended without modifying the trigger.
     * 
     * @param c The Case record
     * @return Boolean true if matches the pattern
     */
    private Boolean isFlightDisruptionCancellation(Case c) {
        return c.Reason == FLIGHT_DISRUPTION_REASON && 
               c.Type == CANCELLATION_TYPE;
    }
    
    /**
     * @description Example logging method - in production this might queue
     * a job, send event, or write to audit trail
     * 
     * @param cases List of cases to log
     */
    private void logCaseCreations(List<Case> cases) {
        // Example implementation - in production, could:
        // - Queue async work
        // - Log to custom object
        // - Send platform event
        for (Case c : cases) {
            System.debug('Case created: ' + c.Id + ', Reason: ' + c.Reason + ', Type: ' + c.Type);
        }
    }
}