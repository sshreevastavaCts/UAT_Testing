@RestResource (Urlmapping = '/AccountContactApi')
global class RestAPIs {
	@httpPost
    global static void saveAccountContact() {
        
        // initialize the response and request
		restRequest req = RestContext.Request;
        restResponse res = RestContext.Response;
        
        // create JSOn to understandable way
        String reqBody = req.requestBody.toString(); // get JSON in string format
        JSONClass myobj = (JSONClass) JSON.deserialize(reqBody, JSONClass.class);
        
        system.debug('get response customerName ==>'+myobj.customerName +'isActive ==>'+myobj.isActive);
         
        // apply your logic
        if (myobj.isActive == true) {
            // create account
        } else {
            // create contact
        }
    }
}