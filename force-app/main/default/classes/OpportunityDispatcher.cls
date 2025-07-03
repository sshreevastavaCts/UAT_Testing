public class OpportunityDispatcher {
	private static Boolean isFirstRun = true;
    
    public static void TriggerDispatch(Boolean isExecuting, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, 
     								   Boolean isDelete, list<opportunity> oldList, list<opportunity> newList, 
                                       map<Id, opportunity> oldMap, map<Id, opportunity> newMap
                                      ){
                                          try{
                                              Map<Id, Task> insertTasks = new Map<Id, Task>();
                                              for (opportunity opp: newlist) {
                                                  Opportunity oOptyOld = oldMap.get(opp.Id);
                                                  if (isExecuting && isAfter && (isInsert || isUpdate) ) { // execute if called by trigger
                                                      if (opp.stageName != null && oldMap.get(opp.Id).stageName != opp.stageName) {
                                                          insertTasks.put(opp.id, new Task(subject = 'testing recordId '+opp.Id, whatId = opp.Id, ownerid = opp.ownerid));
                                                      }
                                                  }
                                                  
                                              }
                                              if (insertTasks.size() > 0) { 
                                                  insert insertTasks.values();
                                              }
                                              if (isFirstRun) {
                                                  isFirstRun(false);
                                              }
                                          } catch(Exception ex) {
                                              throw(ex);
                                          }
    }
    
    // set the boolean variavle : isFirstRun
    public static void isFirstRun (boolean isRun) {
        // you can call this function for finer control!
        OpportunityDispatcher.isFirstRun = false;
    }
}