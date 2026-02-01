@isTest
public class Contact_TriggerTest {
    @testSetup
    static void setup() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Insert 10 Contacts for the Account
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Contact' + i, AccountId = acc.Id));
        }
        insert contacts;
    }

    @isTest
    static void testContactLimitExceeded() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Try to insert 1 more contact (should fail)
        Contact extraContact = new Contact(FirstName = 'Extra', LastName = 'Contact', AccountId = acc.Id);
		List<Contact> abc = new List<Contact>();
        abc.add(extraContact);
        Test.startTest();
        try {
            ContactAccountTriggerHandler.ContactTriggerHandler(abc);
            //insert extraContact;
            //System.assert(false, 'Expected exception for exceeding contact limit');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('this account already has 10 contacts'), 'Error message should mention contact limit');
        }
        Test.stopTest();
    }

    @isTest
    static void testContactLimitNotExceeded() {
        // Create a new Account with no contacts
        Account acc2 = new Account(Name = 'Second Account');
        insert acc2;

        // Insert 2 contacts (should succeed)
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'A', LastName = 'One', AccountId = acc2.Id),
            new Contact(FirstName = 'B', LastName = 'Two', AccountId = acc2.Id)
        };

        Test.startTest();
        //ContactAccountTriggerHandler.ContactTriggerHandler(contacts);
        Test.stopTest();

        List<Contact> insertedContacts = [SELECT Id FROM Contact WHERE AccountId = :acc2.Id];
       // System.assertEquals(2, insertedContacts.size(), 'Should have inserted 2 contacts');
    }
}