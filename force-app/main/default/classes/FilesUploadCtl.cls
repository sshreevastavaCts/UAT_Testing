/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class FilesUploadCtl {
    // Start upload (first chunk or small file)
    @AuraEnabled
    public static Id startFileUpload(String fileName, Id parentId, String base64Data) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName; // 👈 Determines file type automatically
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        insert cv;

        // Link file to parent record if provided
        if (parentId != null) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [
                SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1
            ].ContentDocumentId;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'V';
            insert cdl;
        }

        return cv.Id;
    }

    // Upload additional chunks
    @AuraEnabled
    public static Id uploadFileChunk(String fileName, Id parentId, String base64Data) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        insert cv;

        if (parentId != null) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [
                SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1
            ].ContentDocumentId;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'V';
            insert cdl;
        }

        return cv.Id;
    }

    // Delete uploaded file
    @AuraEnabled
    public static void deleteFile(Id contentDocumentId) {
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
        if (!docs.isEmpty()) {
            delete docs;
        }
    }
}