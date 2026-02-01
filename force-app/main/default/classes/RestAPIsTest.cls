@isTest
public class RestAPIsTest {
    @isTest
    static void testSaveAccountContact_Account() {
        // Prepare mock JSON for Account creation
        String jsonBody = '{"customerName":"Test Account","isActive":true}';
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AccountContactApi';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        RestAPIs.saveAccountContact();
        Test.stopTest();

        // You can add asserts here if your logic creates an Account
        // Example:
        // Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        // System.assertNotEquals(null, acc);
    }

    @isTest
    static void testSaveAccountContact_Contact() {
        // Prepare mock JSON for Contact creation
        String jsonBody = '{"customerName":"Test Contact","isActive":false}';
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AccountContactApi';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        RestAPIs.saveAccountContact();
        Test.stopTest();

        // You can add asserts here if your logic creates a Contact
        // Example:
        // Contact con = [SELECT Id FROM Contact WHERE LastName = 'Test Contact' LIMIT 1];
        // System.assertNotEquals(null, con);
    }
}