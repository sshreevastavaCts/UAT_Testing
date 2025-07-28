/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-29-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class AccountApiTest {
    @testSetup
    static void setup() {
        // Create Account and Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        // Create RecordType for Task
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
            Ques_Set__c = 'Set 1',
            Exam_Name__c = 'Agentforce Specialist',
            Question__c = 'What is the answer?'
        );
        insert quiz;
	
        

        // Create a test User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Student',
            LastName = 'User',
            Email = 'studentuser@test.com',
            Username = 'studentuser' + DateTime.now().getTime() + '@test.com',
            Alias = 'studusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
		Quiz_Result__c qr = new Quiz_Result__c();
        qr.Exam_Date_Time__c = system.now();
        qr.Exam_Name__c = 'AI';
        qr.Exam_Status__c = 'Pass';
        qr.Exam_Taken_Time__c = '08:13';
        qr.Percentage__c = 80.0;
        qr.Score__c = '37/40';
        qr.Set_No__c = 2;
        qr.Student_Attempts__c = 1;
        qr.Student_Name__c = testUser.Id;
        qr.Total_Questions__c = 5;
        qr.Total_Time_Duration__c = '01:01:47';
        qr.UAR_UUID__c = '123456';
        insert qr;
        // Create user_attempt_result__c
        user_attempt_result__c uar = new user_attempt_result__c(
            Selected_Question__c = quiz.Question__c,
            Selected_Answer__c = 'C',
            Correct_Answer__c = 'C',
            Quiz_Question_Number__c = quiz.Id,
            Attended_By__c = UserInfo.getUserId(),
            UUID__c = '123456',
            IsCorrect_Answer__c = true,
            Quiz_Result__c = qr.Id
        );
        insert uar;
        // Create Quiz_Result__c
        
		
    }

    @isTest
    static void testGetContactsByAccId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> contacts = AccountApi.getContactsByAccId(acc.Id);
        System.assertEquals(1, contacts.size());
    }

    @isTest
    static void testGetAccounts() {
        List<Account> accounts = AccountApi.getAccounts();
        System.assert(accounts.size() > 0);
    }

    @isTest
    static void testGetQuestions() {
        List<Quiz__c> quizzes = AccountApi.getQuestions();
        System.assertEquals(1, quizzes.size());
    }

    @isTest
    static void testSaveQuizAnswers() {
        Quiz__c quiz = [SELECT Id, Question__c FROM Quiz__c LIMIT 1];
        
        
        Quiz_Result__c qr = new Quiz_Result__c();
        qr.Exam_Date_Time__c = system.now();
        qr.Exam_Name__c = 'AI';
        qr.Exam_Status__c = 'Pass';
        qr.Exam_Taken_Time__c = '08:13';
        qr.Percentage__c = 80.0;
        qr.Score__c = '37/40';
        qr.Set_No__c = 2;
        qr.Student_Attempts__c = 1;
        qr.Student_Name__c = UserInfo.getUserId();
        qr.Total_Questions__c = 5;
        qr.Total_Time_Duration__c = '01:01:47';
        qr.UAR_UUID__c = '123456';
        user_attempt_result__c uar = new user_attempt_result__c(
            Selected_Question__c = quiz.Question__c,
            Selected_Answer__c = 'C',
            Correct_Answer__c = 'C',
            Quiz_Question_Number__c = quiz.Id,
            Attended_By__c = UserInfo.getUserId(),
            UUID__c = '123456',
            IsCorrect_Answer__c = true,
            Quiz_Result__c = qr.Id
        );
        List<user_attempt_result__c> uarList = new List<user_attempt_result__c>{uar};
        List<Quiz_Result__c> qrList = new List<Quiz_Result__c>{qr};
        Test.startTest();
        String resultId = AccountApi.saveQuizAnswers(uarList, qrList);
        Test.stopTest();
        System.assertNotEquals(null, resultId);
    }

    @isTest
    static void testGetQuizResults() {
        List<Quiz_Result__c> results = AccountApi.getQuizResults();
        System.assert(results.size() > 0);
    }
}