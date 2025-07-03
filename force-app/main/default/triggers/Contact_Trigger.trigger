// not more then 10 records per account
// steps: 1. get account id
// 2. get the counts of contacts where account is this
// 3. chk if counts is more then 10 then throw error
trigger Contact_Trigger on Contact (before insert) {
   
    set<Id> accIds = new set<Id>();
    for (Contact con: Trigger.new){
        if (con.AccountId != null) {
            accIds.add(con.AccountId);
        }
    }
    // query for existing contact count on account
    Map<Id, Integer> existingContactCountmap = new Map<Id, Integer>();
    for (AggregateResult ar: [select AccountId, count(Id) contactCount from contact where AccountId IN: accIds Group By AccountId]) {
        existingContactCountmap.put((Id)ar.get('AccountId'), (Integer)ar.get('contactCount'));
    }
    
    // track how many new contacts per account in this trigger context
    map<Id, Integer> currentContactCountmap = new Map<Id, Integer>();
    for (contact con: trigger.new) {
        if (con.AccountId != null) {
            Integer conCount = currentContactCountmap.get(con.AccountId);
            currentContactCountmap.put(con.AccountId, conCount == null ? 1 : conCount + 1);
        }
    }
    
    // inforce the 10 contact limit 
    for (contact con: trigger.new) {
        if (con.AccountId != null) {
            integer existingCon = existingContactCountmap.get(con.AccountId);
            integer newCon = currentContactCountmap.get(con.AccountId);
            if (existingCon + newCon > 10) {
                con.addError('Cannot add contact: this account already has 10 contacts.');
            }
        }
    }
    
}