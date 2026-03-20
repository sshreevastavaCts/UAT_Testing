/**
 * @description Trigger for Case object events.
 * Delegates all logic to CaseTriggerHandler following the TriggerFramework pattern.
 * 
 * The trigger stays thin and focused on routing events, with all business logic
 * in the handler class, making the system maintainable and testable.
 */
trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerFramework.execute(new CaseTriggerHandler());
}