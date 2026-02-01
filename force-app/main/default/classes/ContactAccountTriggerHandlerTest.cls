@isTest
public class ContactAccountTriggerHandlerTest {
    @testSetup
    static void setup() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contacts with Amount__c
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'A', LastName = 'One', AccountId = acc.Id, Amount__c = 100),
            new Contact(FirstName = 'B', LastName = 'Two', AccountId = acc.Id, Amount__c = 200)
        };
        insert contacts;
        
        
    }

    @isTest
    static void testUpdateAccountAmounts() {
        // Fetch contacts
        List<Contact> contacts = [SELECT Id, AccountId, Amount__c FROM Contact WHERE Amount__c != null];
        // Call handler
        Test.startTest();
        ContactAccountTriggerHandler.updateAccountAmounts(contacts);
        Test.stopTest();

        // Assert Account Amount__c is updated
        Account acc = [SELECT Id, Amount__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        System.assertEquals(300, acc.Amount__c, 'Account Amount__c should be sum of related contacts');
    }
    
    
    
}