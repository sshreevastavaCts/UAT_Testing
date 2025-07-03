/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AccountApi {
    public static List<Contact> getContactsByAccId(Id accId) {
        List<contact> conLists = [Select Id, FirstName, LastName From Contact where AccountId =:accId];
        return conLists;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        List<Account> accLists = [Select Id, Name From Account limit 100];
        return accLists;
    }
    
    // get account country state city data and display in LWC pages

   	@AuraEnabled(cacheable=true)
    public static List<String> getTaskSubjectsByRecordId() {
        Id recordTypeId = '012Qy000006ipY1IAI'; // example
        RecordType rt = [SELECT DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1];
        String recordTypeDevName = rt.DeveloperName;
        system.debug('get rec type name: '+recordTypeDevName);
        List<String> subjectValues = new List<String>();
       
        // get custom meta data for filter
        List<String> subjects = new List<String>();

        for (Task_Subject_Per_Record_Type_Id__mdt mapping : [SELECT Subject_Value__c FROM Task_Subject_Per_Record_Type_Id__mdt WHERE Record_Type_Developer_Name__c = :recordTypeDevName AND Active__c = true order by Order__c]) {
            subjects.add(mapping.Subject_Value__c);
        }
        
        Schema.DescribeFieldResult fieldResult = Task.Subject.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
		system.debug('get picklistEntries: '+picklistEntries);
        List<String> finalSubjects = new List<String>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive() && subjects.contains(entry.getLabel())) {
                finalSubjects.add(entry.getLabel());
            }
        }
        system.debug('get subjectValues: '+subjectValues);
        system.debug('get subjects from custome: '+subjects);
        system.debug('get finalSubjects: '+finalSubjects);
        return finalSubjects;
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<String> getTaskSubjects(Id recordTypeId) {
        List<String> subjectValues = new List<String>();
        // Get the Task.Subject field describe
        Schema.DescribeFieldResult fieldResult = Task.Subject.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            // Only include values valid for the given Record Type
            if (entry.isActive() && (entry.isDefaultValue())) {
                subjectValues.add(entry.getLabel());
            }
        }
        return subjectValues;
    }



    @AuraEnabled(cacheable=true)
    public static List<String> getTaskPriorities() {  
        return [SELECT Id, Answer_Option_1__c, Answer_Option_2__c, Answer_Option_3__c, Correct_Answer__c, Ques_Set__c , Question__c, Name FROM Quiz__c where Active__c = true]
            .stream()
            .map(q -> q.Answer_Option_1__c + ', ' + q.Answer_Option_2__c + ', ' + q.Answer_Option_3__c)
            .collect(Collectors.toList());
    }
}