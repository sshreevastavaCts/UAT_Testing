// not more then 10 records per account
// steps: 1. get account id
// 2. get the counts of contacts where account is this
// 3. chk if counts is more then 10 then throw error
trigger Contact_Trigger on Contact (before insert) {
   ContactAccountTriggerHandler.ContactTriggerHandler(trigger.new);
    
    
}