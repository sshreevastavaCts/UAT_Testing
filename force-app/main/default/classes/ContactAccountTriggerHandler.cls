/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ContactAccountTriggerHandler {
    public static void updateAccountAmounts(List<Contact> contactList) {
        Set<Id> accountIds = new Set<Id>();

        // Collect Account IDs from the Contacts
        for (Contact con : contactList) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            } 
        }

        if (accountIds.isEmpty()) return;

        // Aggregate Contact.Amount__c per AccountId
        Map<Id, Decimal> accountIdToTotal = new Map<Id, Decimal>();

        for (AggregateResult ar : [
            SELECT AccountId, SUM(Amount__c) total
            FROM Contact
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ]) {
            accountIdToTotal.put((Id)ar.get('AccountId'), (Decimal)ar.get('total'));
        }

        // Fetch accounts to update
        List<Account> accountsToUpdate = new List<Account>();

        for (Id accId : accountIdToTotal.keySet()) {
            accountsToUpdate.add(new Account(
                Id = accId,
                Amount__c = accountIdToTotal.get(accId)
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    } 
    // This method retrieves all Quiz_Result__c records
    @AuraEnabled(cacheable=true)
    public static List<Quiz_Result__c> getQuizResults() {
        return [SELECT Id, Name FROM Quiz_Result__c];
    }

    // test updated for trigger
    
    public static void ContactTriggerHandler(List<Contact> newConList) {
        set<Id> accIds = new set<Id>();
        for (Contact con: newConList){
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
        for (contact con: newConList) {
            if (con.AccountId != null) {
                Integer conCount = currentContactCountmap.get(con.AccountId);
                currentContactCountmap.put(con.AccountId, conCount == null ? 1 : conCount + 1);
            }
        }
        
        // inforce the 10 contact limit 
        for (contact con: newConList) {
            if (con.AccountId != null) {
                integer existingCon = existingContactCountmap.get(con.AccountId);
                integer newCon = currentContactCountmap.get(con.AccountId);
                if (existingCon + newCon > 10) {
                    con.addError('Cannot add contact: this account already has 10 contacts.');
                }
            }
        }
    }    
}