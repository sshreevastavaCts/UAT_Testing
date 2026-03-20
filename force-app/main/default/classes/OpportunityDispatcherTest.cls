@isTest
public class OpportunityDispatcherTest {
    @testSetup
    static void setup() {
        // Create test Account and User
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        User owner = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Create initial Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            OwnerId = owner.Id
        );
        insert opp;
        
    }

    @isTest
    static void testTriggerDispatchInsertAndUpdate() {
        Opportunity opp = [SELECT Id, StageName, OwnerId FROM Opportunity LIMIT 1];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => opp };

        // Simulate stage change
        Opportunity oppUpdate = opp.clone(false, true, false, false);
        opp.StageName = 'Closed Won';
		update opp;
        List<Opportunity> newList = new List<Opportunity>{ oppUpdate };
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ oppUpdate.Id => oppUpdate };

   

        // Assert that a Task was created for the Opportunity stage change
        List<Task> tasks = [SELECT Id, WhatId, Subject FROM Task WHERE WhatId = :opp.Id];
           }
}