/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-20-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class VoiceAIController {
    @AuraEnabled
    public static String getAnswer(String question) {
        // 1. Prepare Gemini API endpoint and key
        String apiKey = 'AIzaSyD5x-O57IZlioT7SyUiKAjdmG1l32asH88';
        String endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

        // 2. Build request body
        Map<String, Object> body = new Map<String, Object>{
            'contents' => new List<Object>{
                new Map<String, Object>{
                    'parts' => new List<Object>{
                        new Map<String, Object>{
                            'text' => question
                        }
                    }
                }
            }
        };
        system.debug('Request Body: ' + JSON.serialize(body));
        //String body = '{"contents": [{ "parts": [ {"text": "' + question + '"}] } ]}';
        // 3. Make HTTP callout
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('x-goog-api-key', apiKey);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));

        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                // Parse Gemini response
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (result.containsKey('candidates')) {
                    List<Object> candidates = (List<Object>) result.get('candidates');
                    if (!candidates.isEmpty()) {
                        Map<String, Object> candidate = (Map<String, Object>) candidates[0];
                        if (candidate.containsKey('content')) {
                            Map<String, Object> content = (Map<String, Object>) candidate.get('content');
                            if (content.containsKey('parts')) {
                                List<Object> parts = (List<Object>) content.get('parts');
                                if (!parts.isEmpty()) {
                                    Map<String, Object> part = (Map<String, Object>) parts[0];
                                    String answer = (String) part.get('text');
                                    // Return in OpenAI-compatible JSON structure
                                    Map<String, Object> response = new Map<String, Object>{
                                        'choices' => new List<Object>{
                                            new Map<String, Object>{
                                                'message' => new Map<String, Object>{
                                                    'content' => answer
                                                }
                                            }
                                        }
                                    };
                                    return JSON.serialize(response);
                                }
                            }
                        }
                    }
                }
                // If no answer found
                return '{"choices":[{"message":{"content":"No answer returned from Gemini."}}]}';
            } else {
                return '{"choices":[{"message":{"content":"Gemini API error: ' + res.getStatus() + '"}}]}';
            }
        } catch (Exception e) {
            return '{"choices":[{"message":{"content":"Gemini callout failed: ' + e.getMessage() + '"}}]}';
        }
    }
}