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

    public static List<Quiz_Result__c> getQuizResults() {
        return [SELECT Id, Name FROM Quiz_Result__c];
    }
        
}