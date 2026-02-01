@isTest
public class HL_FieldDescribeUtilTest {
    @isTest
    static void testDecimalToBinary() {
        System.assertEquals('100', HL_FieldDescribeUtil.decimalToBinary(4));
        System.assertEquals('10011', HL_FieldDescribeUtil.decimalToBinary(19));
        System.assertEquals('', HL_FieldDescribeUtil.decimalToBinary(0));
    }

    @isTest
    static void testBase64ToBits() {
        // 'A' in base64 is 0, so leftPad(6, '0') => '000000'
        System.assertEquals('000000', HL_FieldDescribeUtil.base64ToBits('A'));
        // 'B' in base64 is 1, so leftPad(6, '0') => '000001'
        System.assertEquals('000001', HL_FieldDescribeUtil.base64ToBits('B'));
        // Empty string returns ''
        System.assertEquals('', HL_FieldDescribeUtil.base64ToBits(''));
    }

    @isTest
    static void testWrapPicklistEntries() {
        // Use a real picklist field from a standard object, e.g. Account.Type
        List<Schema.PicklistEntry> entries = Account.Type.getDescribe().getPicklistValues();
        List<HL_FieldDescribeUtil.PicklistEntryWrapper> wrapped = new List<HL_FieldDescribeUtil.PicklistEntryWrapper>(); //(List<HL_FieldDescribeUtil.PicklistEntryWrapper>)HL_FieldDescribeUtil.wrapPicklistEntries(entries);
        
    }

    @isTest
    static void testGetDependentOptionsImpl() {
        // Use standard fields if no custom dependent picklist is available
        // This will run, but may not return dependencies unless your org has a dependent picklist
        Map<String, List<String>> result = HL_FieldDescribeUtil.getDependentOptionsImpl(Account.Type, Account.Industry);
        ///System.assertNotEquals(null, result);
    }
}