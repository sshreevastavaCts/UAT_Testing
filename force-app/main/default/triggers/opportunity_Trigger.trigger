/*trigger opportunity_Trigger on Opportunity (after insert, after update) {
    if ((trigger.isInsert || trigger.isUpdate) && trigger.isAfter) {
        map<Id, Task> insertTask = new map<Id, Task>();
        for (opportunity opp: trigger.new){
            if (trigger.oldMap.get(opp.Id).StageName != opp.StageName) {
                if (!insertTask.containsKey(opp.Id)) {
                    insertTask.put(opp.Id, new task(subject = 'new task for opportunity '+opp.Id, whatId = opp.Id, OwnerId = opp.OwnerId));
                }
            }
        }
        List<task> tkList = new List<Task>();
        Task tk;
        if (insertTask.size() > 0) {
            insert insertTask.values();
        }
    }
}
*/
// for handling the recursion we are using the boolean var, but this one only can be handle 200 records after 
// that it may be create the duplicate records so for we need to use trigger classes for this


Trigger opportunity_Trigger on Opportunity (before insert, before update, after insert, after update) {
    OpportunityDispatcher.TriggerDispatch(
    	Trigger.isExecuting, Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, 
        Trigger.isUpdate, Trigger.isDelete, trigger.old, trigger.new, 
        trigger.oldMap, Trigger.newMap
    );
}