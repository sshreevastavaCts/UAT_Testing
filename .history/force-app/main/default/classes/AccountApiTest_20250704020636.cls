/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class AccountApiTest {
    @testSetup
    static void setup() {
        // Create Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Create Contact
        Contact con = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert con;

        // Create RecordType
        // RecordType rt = new RecordType(
        //     Name = 'TestRT',
        //     SObjectType = 'Task',
        //     DeveloperName = 'TestRTDev'
        // );
        // insert rt;

        // Create Quiz__c
        Quiz__c quiz = new Quiz__c(
            isActive__c = true,
            Answer_Option_1__c = 'A',
            Answer_Option_2__c = 'B',
            Answer_Option_3__c = 'C',
            Correct_Answer__c = 'C',
            Ques_Set__c = 'Set1',
            Question__c = 'What is the answer?'
        );
        insert quiz;

        // Create user_attempt_result__c and Quiz_Result__c for saveQuizAnswers
        user_attempt_result__c uar = new user_attempt_result__c(
            Selected_Question__c = 'What is the answer?',
            Selected_Answer__c = 'C',
            Correct_Answer__c = 'C',
            Quiz_Question_Number__c = quiz.Id,
            Attended_By__c = UserInfo.getUserId(),
            IsCorrect_Answer__c = true
        );
        insert uar;

        Quiz_Result__c qr = new Quiz_Result__c(
            Exam_Name__c = 'Sample Exam',
            Exam_Status__c = 'Pass',
            Percentage__c = 100,
            Score__c = '1/1',
            Set_No__c = 1,
            Student_Attempts__c = 1,
            Student_Name__c = UserInfo.getUserId(),
            Total_Questions__c = 1,
            Total_Time_Duration__c = '00:01:00',
            UAR_UUID__c = 'ABC123'
        );
        insert qr;
    }

    @isTest
    static void testGetContactsByAccId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> contacts = AccountApi.getContactsByAccId(acc.Id);
        System.assert(!contacts.isEmpty(), 'Should return contacts for the account');
    }

    @isTest
    static void testGetAccounts() {
        List<Account> accounts = AccountApi.getAccounts();
        System.assert(!accounts.isEmpty(), 'Should return accounts');
    }

    @isTest
    static void testGetTaskSubjectsByRecordId() {
        // This method depends on metadata and picklist values, so just check it runs
        Test.startTest();
        List<String> subjects = AccountApi.getTaskSubjectsByRecordId();
        Test.stopTest();
        System.assert(subjects != null);
    }

    @isTest
    static void testGetTaskSubjects() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Task' LIMIT 1];
        List<String> subjects = AccountApi.getTaskSubjects(rt.Id);
        System.assert(subjects != null);
    }

    @isTest
    static void testGetQuestions() {
        List<Quiz__c> questions = AccountApi.getQuestions();
        System.assert(!questions.isEmpty(), 'Should return quiz questions');
    }

    @isTest
    static void testSaveQuizAnswers() {
        user_attempt_result__c uar = [SELECT Id, Selected_Question__c, Selected_Answer__c, Correct_Answer__c, Quiz_Question_Number__c, Attended_By__c, IsCorrect_Answer__c FROM user_attempt_result__c LIMIT 1];
        Quiz_Result__c qr = [SELECT Id, Exam_Name__c, Exam_Status__c, Percentage__c, Score__c, Set_No__c, Student_Attempts__c, Student_Name__c, Total_Questions__c, Total_Time_Duration__c, UAR_UUID__c FROM Quiz_Result__c LIMIT 1];
        List<user_attempt_result__c> uarList = new List<user_attempt_result__c>{ uar };
        List<Quiz_Result__c> qrList = new List<Quiz_Result__c>{ qr };

        Test.startTest();
        String resultId = AccountApi.saveQuizAnswers(uarList, qrList);
        Test.stopTest();
        System.assertNotEquals(null, resultId, 'Should return an Id');
    }
}