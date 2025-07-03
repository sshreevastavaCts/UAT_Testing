/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-28-2025
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
    public static List<Quiz__c> getQuestions() {  
        return [SELECT Id, Answer_Option_1__c, Answer_Option_2__c, Answer_Option_3__c, Correct_Answer__c, Ques_Set__c , Question__c, Name FROM Quiz__c where isActive__c = true limit 5];
    }

    // save quiz answers
    @AuraEnabled
    public static void saveQuizAnswers(List<user_attempt_result__c> quizAnswers, List<Quiz_Result__c> QR_Answers) {
        if (quizAnswers == null || quizAnswers.isEmpty()) {
            throw new AuraHandledException('Quiz answers cannot be null or empty.');
        }
        
        // Insert the records
        try {
            insert quizAnswers;


            // Convert QR_Answers to List<Quiz_Result__c>
            List<Quiz_Result__c> qrList = new List<Quiz_Result__c>();
            for (Object o : QR_Answers) {
                // Cast the generic Object to a Map
                Map<String, Object> m = (Map<String, Object>)o;
                Quiz_Result__c qr = new Quiz_Result__c();
                if (m.containsKey('Exam_Date_Time__c')) qr.Exam_Date_Time__c = (String)m.get('Exam_Date_Time__c');
                if (m.containsKey('Exam_Name__c')) qr.Exam_Name__c = (String)m.get('Exam_Name__c');
                if (m.containsKey('Exam_Status__c')) qr.Exam_Status__c = (String)m.get('Exam_Status__c');
                if (m.containsKey('Exam_Taken_Time__c')) qr.Exam_Taken_Time__c = (String)m.get('Exam_Taken_Time__c');
                if (m.containsKey('Percentage__c')) qr.Percentage__c = (Decimal)m.get('Percentage__c');
                if (m.containsKey('Score__c')) qr.Score__c = (Decimal)m.get('Score__c');
                if (m.containsKey('Set_No__c')) qr.Set_No__c = (Integer)m.get('Set_No__c');
                if (m.containsKey('Student_Attempts__c')) qr.Student_Attempts__c = (Integer)m.get('Student_Attempts__c');
                if (m.containsKey('Student_Name__c')) qr.Student_Name__c = (String)m.get('Student_Name__c');
                if (m.containsKey('Total_Questions__c')) qr.Total_Questions__c = (Integer)m.get('Total_Questions__c');
                if (m.containsKey('Total_Time_Duration__c')) qr.Total_Time_Duration__c = (String)m.get('Total_Time_Duration__c');
                if (m.containsKey('UAR_UUID__c')) qr.UAR_UUID__c = (String)m.get('UAR_UUID__c');
                qrList.add(qr);
            }

            if (!qrList.isEmpty()) {
                insert qrList;
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error inserting quiz answers: ' + e.getMessage());
        }
    }


}