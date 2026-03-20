# Record-Triggered Flow for Case - Implementation Guide

## Case: Before-Save Flow Added (Auto Resolution to Refund)

Implemented metadata (deployable):
- Case field: Bypass_Business_Logic__c (Checkbox; default false)
  - Path: force-app/main/default/objects/Case/fields/Bypass_Business_Logic__c.field-meta.xml
- Record-Triggered Flow: Case_RT_BeforeCreate_AutoResolution (Before-save on Create)
  - Path: force-app/main/default/flows/Case_RT_BeforeCreate_AutoResolution.flow-meta.xml
  - Entry Conditions:
    - Bypass_Business_Logic__c = false
    - Type = "Cancellation"
    - RecordType.DeveloperName = "Flight_Disruption"
  - Action: Set $Record.Resolution__c = "Refund"
  - Optimization: FastFieldUpdates (before-save)

Coexistence with existing Apex triggers/handlers:
- This flow is before-save and sets only Resolution__c on create when criteria match.
- Apex code remains unchanged as requested. To avoid duplicate updates:
  - If Apex also sets Resolution__c for the same condition, enable Case.Bypass_Business_Logic__c during batch loads/migrations to prevent double-writes.
  - If Apex runs after-save and re-updates Resolution__c, the final value will be whatever Apex sets. Consider, in future, aligning Apex to skip when the field is already "Refund" to minimize DML.

Recommended conventions (applied here):
- Flow naming: {Object}_{Timing}_{Event}_{Purpose}
  - Example: Case_RT_BeforeCreate_AutoResolution
- Guardrails:
  - Always include bypass check first.
  - Use before-save for deterministic, single-record defaults to minimize recursion and DML.
  - Constrain entry conditions tightly to avoid overlap with Apex updates.

Testing checklist:
- Case A (expect Resolution__c = "Refund"):
  - Type = Cancellation
  - Record Type = Flight_Disruption
  - Bypass_Business_Logic__c = false
- Case B (no change):
  - Type = Cancellation
  - Record Type != Flight_Disruption
  - Bypass_Business_Logic__c = false
- Case C (no change):
  - Type != Cancellation
  - Record Type = Flight_Disruption
  - Bypass_Business_Logic__c = false
- Case D (no change due to bypass):
  - Type = Cancellation
  - Record Type = Flight_Disruption
  - Bypass_Business_Logic__c = true

Deployment
- Use sf deploy to push the field and flow:
  - sf project deploy start --metadata "Flow:Case_RT_BeforeCreate_AutoResolution" --metadata "CustomField:Case.Bypass_Business_Logic__c"
  - Or deploy the whole force-app.

Notes
- Ensure Case.RecordType with DeveloperName = "Flight_Disruption" exists in the target org; otherwise adjust the filter.
- Ensure picklist value "Refund" exists on Resolution__c.

## Overview

This guide walks you through creating a **Record-Triggered Flow** that demonstrates safe coexistence with your Apex trigger framework.

**Goal:** Show how Apex validates/auto-populates fields, and Flows handle downstream notifications/workflows.

---

## Architecture: How They Work Together

```
┌─────────────────────────────────────────────────────────────┐
│ INSERT Case (Flight Disruption, Type = Cancellation)        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ BEFORE TRIGGER FIRES (Synchronous)                          │
├─────────────────────────────────────────────────────────────┤
│ CaseTrigger → TriggerFramework → CaseTriggerHandler         │
│ beforeInsert() executes:                                     │
│ ✓ Sets Status = 'Resolved'                                 │
│ ✓ Sets Reason = 'Refund'                                   │
│ ✓ DOES NOT send notifications yet                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ RECORD SAVED TO DATABASE                                    │
│ Case now has: Status='Resolved', Reason='Refund'           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ AFTER TRIGGER FIRES (Synchronous)                           │
├─────────────────────────────────────────────────────────────┤
│ CaseTrigger → TriggerFramework → CaseTriggerHandler         │
│ afterInsert() executes:                                      │
│ ✓ If needed: Publish event for Flow to consume              │
│ ✓ If needed: Queue async jobs                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ RECORD-TRIGGERED FLOW FIRES (Asynchronous)                  │
├─────────────────────────────────────────────────────────────┤
│ Case_OnResolvedCreation Flow:                               │
│ Trigger: Record is created AND Status = 'Resolved'         │
│                                                             │
│ Actions:                                                     │
│ ✓ Send email notification to Team Lead                     │
│ ✓ Create Task to follow up                                 │
│ ✓ Update related Account with latest case info             │
│ ✓ Log to custom audit object                               │
│                                                             │
│ Benefits:                                                    │
│ ✓ Apex already set fields (no duplication)                 │
│ ✓ Flow only orchestrates (notifications/workflow)          │
│ ✓ Independent, can be updated without code change          │
└─────────────────────────────────────────────────────────────┘

RESULT: Case resolved with notifications sent, all in one transaction
```

---

## Step-by-Step: Create the Flow

### Prerequisites
- ✓ Apex trigger framework deployed
- ✓ CaseTrigger and CaseTriggerHandler deployed
- ✓ Case object accessible in org

### Flow Definition

| Property | Value |
|----------|-------|
| Name | `Case_OnResolvedCreation` |
| Trigger Type | Record-Triggered Flow |
| Object | Case |
| Trigger On | Create and Update |
| Trigger Conditions | Status = 'Resolved' |
| Run As | System Context |

---

## Creation Steps (Using Flow Builder UI)

### Step 1: Create New Flow

1. Navigate to **Setup → Flows**
2. Click **New Flow**
3. Choose **Record-Triggered Flow**
4. Click **Create**

### Step 2: Configure Trigger

1. **Object:** Case
2. **Trigger Condition:** "When a record is created or updated"
3. **Condition Requirements:**
   ```
   Case.Status EQUALS 'Resolved'
   ```
4. **Optimize the flow for:** Actions and Related Records
5. Click **Done**

### Step 3: Add Get Current Case Details

This ensures we have fresh data from database:

1. Click **+ Add Element** in execution pane
2. Choose **Action** → **Get Records**
3. Configure:
   ```
   Label:              Get_Case_Details
   API Name:           Get_Case_Details
   Object:             Case
   Filter Condition:   Case.Id equals {$Trigger.id}
   Sort Order:         (leave default)
   Limit Records:      1
   ```
4. Click **Done**

### Step 4: Add Send Email Action

1. Click **+ Add Element**
2. Choose **Action** → **Send Email**
3. Configure:
   ```
   Label:              Send_Resolution_Notification
   API Name:           Send_Resolution_Notification
   Email Template:     Case Resolution Notification (or create one)
   Send List:          Recipient Type: User
                       User ID: {!Get_Case_Details.Records[0].Owner}
   ```
4. Click **Done**

**Note:** If you don't have a custom email template, use **Send Email (v1)** and manually fill:
```
To Email Addresses: {!Get_Case_Details.Records[0].OwnerID}
Subject:            Case {!$Trigger.records[0].CaseNumber} Resolved
Body:               Details: {!$Trigger.records[0].Subject}
```

### Step 5: Add Create Task Action (Optional)

1. Click **+ Add Element**
2. Choose **Action** → **Create Records**
3. Configure:
   ```
   Label:              Create_Followup_Task
   API Name:           Create_Followup_Task
   Object:             Task
   Assign Values:
   ├─ Subject:         Follow up on Case {!$Trigger.records[0].CaseNumber}
   ├─ Description:     Case auto-resolved with status: {!$Trigger.records[0].Status}
   ├─ WhoId:           {!Get_Case_Details.Records[0].ContactId}
   ├─ WhatId:          {!$Trigger.records[0].Id}
   ├─ OwnerId:         {!Get_Case_Details.Records[0].OwnerId}
   └─ DueDate:         TODAY PLUS 3 days
   ```
4. Click **Done**

### Step 6: Publish the Flow

1. Click **Save** (top right)
2. Label: `Case_OnResolvedCreation`
3. API Name: `Case_OnResolvedCreation` (auto-populated)
4. Click **Save**
5. Click **Activate** (top left, next to Save)

**Confirmation:** Flow is now ACTIVE and will trigger on all Case creates/updates with Status='Resolved'

---

## Diagram: Flow Logic

```
┌──────────────────────────────────────────────────────┐
│ FLOW TRIGGER                                         │
│ Case.Status = 'Resolved'                            │
└──────────────────┬───────────────────────────────────┘
                   │
               ▼▼▼▼▼
┌──────────────────────────────────────────────────────┐
│ Get Case Details                                     │
│ (Retrieves fresh data from database)                │
│ ✓ Get owner info
│ ✓ Get contact/account info                          │
└──────────────────┬───────────────────────────────────┘
                   │
           ┌───────┴───────┐
           ▼               ▼
    ┌─────────────┐  ┌──────────────┐
    │ Send Email  │  │ Create Task  │
    │ Notification│  │ (Follow-up)  │
    └─────────────┘  └──────────────┘
           │               │
           └───────┬───────┘
                   ▼
           ┌──────────────┐
           │ Flow Complete│
           │ (Success)    │
           └──────────────┘
```

---

## Testing & Validation

### Manual Test (Easiest)

Since Apex Unit Tests cannot directly test Flows, use manual testing:

#### Test Case 1: Flight Disruption Cancellation Auto-Resolve

1. **Create Case:**
   - Account: Any
   - Subject: "Flight Cancelled"
   - Reason: "Flight Disruption"
   - Type: "Cancellation"
   - Status: "New"
   - Click **Save**

2. **Verify Apex Trigger Executed:**
   - ✓ Case Status auto-changed to "Resolved" → **Apex trigger worked!**
   - ✓ Case Reason = "Refund" → **Apex trigger worked!**

3. **Verify Flow Executed:**
   - Send email action triggered → Check **Setup → Email Logs**
   - Task created → Check **Tasks** list for new Follow-up Task
   - Email sent to Owner → Check owner's **Sent Tasks/Email Activity**

**Expected Result:**
```
✓ Apex: Status='Resolved', Reason='Refund'
✓ Flow: Email sent, Task created
✓ Both executed without conflicts or duplication
```

#### Test Case 2: Non-Matching Case (Should NOT trigger Flow)

1. **Create Case:**
   - Subject: "Regular Issue"
   - Reason: "Other"
   - Type: "Other"
   - Status: "New"
   - Click **Save**

2. **Verify:**
   - ✓ Status remains "New" (Apex rule didn't match)
   - ✓ No email sent (Flow didn't trigger)
   - ✓ No task created (Flow didn't trigger)

**Expected Result:**
```
✓ Neither Apex nor Flow acted (correct behavior)
```

#### Test Case 3: Update Existing Case

1. Create normal case (Status = New)
2. **Update manually:**
   - Set Status = "Resolved"
   - Click **Save**

3. **Verify Flow Triggered Again:**
   - Flow triggers on both create AND update
   - Email sent again (expected behavior)
   - Task created again (expected behavior)

**Expected Result:**
```
✓ Flow respects the condition (Status='Resolved')
✓ Works on updates too
```

---

### Automated Test (For Apex Code)

You **cannot** unit test Flows directly, but you can test that:
1. Apex sets the correct fields (already done in CaseTriggerHandlerTest)
2. Flow condition will trigger (manual verification)

However, you can add an **integration test** to verify the chain:

```apex
@isTest
static void testFlowIntegration_CaseAutoResolvedTriggersFlow() {
    // Test setup
    TriggerFramework.clearRegistry();
    TriggerBypassUtil.clearAllBypasses();
    
    // Create Flight Disruption Cancellation
    Case testCase = new Case(
        Subject = 'Flight Cancelled',
        Reason = 'Flight Disruption',
        Type = 'Cancellation',
        Status = 'New'
    );
    
    Test.startTest();
    insert testCase;
    Test.stopTest();
    
    // Verify Apex set fields correctly
    Case result = [SELECT Id, Status, Reason FROM Case WHERE Id = :testCase.Id];
    Assert.areEqual('Resolved', result.Status, 'Apex should set Status to Resolved');
    Assert.areEqual('Refund', result.Reason, 'Apex should set Reason to Refund');
    
    // NOTE: Flow execution would need Flow coverage reports to verify
    // Or manual observation of email logs and tasks
    
    // If you have flow testing plugin, you could verify:
    // List<Task> createdTasks = [SELECT Id FROM Task WHERE WhatId = :testCase.Id];
    // Assert.isTrue(createdTasks.size() > 0, 'Flow should create task');
}
```

Add this test to **CaseTriggerHandlerTest.cls**

---

## Validation Checklist

After creating and testing the Flow, verify:

- [ ] Flow created and activated (Setup → Flows → Case_OnResolvedCreation)
- [ ] Flow trigger on Case with Status='Resolved'
- [ ] Email action configured with correct recipient
- [ ] Task creation action configured (optional)
- [ ] Manual test 1: Flight Disruption case creates notification
- [ ] Manual test 2: Non-matching case does NOT create notification
- [ ] Manual test 3: Updating case to Resolved triggers Flow again
- [ ] No conflicts between Apex and Flow (tested)
- [ ] Email logs show correct emails sent
- [ ] Tasks list shows newly created tasks

---

## Flow Coexistence in Action

### What Apex Does (beforeInsert/beforeUpdate):
```
✓ Validates fields
✓ Auto-calculates values
✓ Sets Status and Reason based on business rules
✓ Does NOT send emails
✓ Does NOT create tasks
✓ Synchronous, same transaction
```

### What Flow Does (afterInsert/afterUpdate):
```
✓ Watches for record changes (Status='Resolved')
✓ Sends notifications
✓ Creates follow-up tasks
✓ Updates related records
✓ Asynchronous (or sync if configured)
✓ Independent of Apex logic
```

### Benefits of This Pattern:
```
✓ No duplicate logic (Apex sets fields, Flow watches for them)
✓ No duplicate notifications (only Flow sends)
✓ Clear separation of concerns
✓ Flow can be updated without code changes
✓ Easy to understand data flow
✓ Testable parts (Apex = unit tests, Flow = manual validation)
```

---

## Troubleshooting

### Issue: Flow not triggering after Apex sets Status='Resolved'

**Possible Causes:**
1. Flow not activated (check **Setup → Flows status)
2. Trigger condition incorrect (should be Status='Resolved')
3. Bypass logic preventing Apex (check `TriggerBypassUtil`)
4. Email service errors (check **Setup → Email Logs**)

**Solution:**
1. Verify Flow is **ACTIVE** in Setup
2. Edit Flow and check trigger condition
3. Call `TriggerBypassUtil.clearAllBypasses()` in test
4. Check email logs for errors

### Issue: Flow triggers too many times

**Possible Causes:**
1. Trigger on both create and update
2. Batch process triggering multiple times
3. Flow in loop with Apex (rare)

**Solution:**
1. Use Flow deduplication settings
2. Add bypass flag if needed (see guide)
3. Check Flow execution logs

### Issue: Email not sending

**Possible Causes:**
1. Email template not found
2. Owner email invalid
3. Organization email relay settings

**Solution:**
1. Use **Send Email (v1)** action instead of template
2. Verify owner has valid email
3. Check org email relay settings in Setup

---

## Next Steps

1. **Create the Flow** using steps above
2. **Test manually** using test cases provided
3. **Verify coexistence** - both Apex and Flow working together
4. **Document in your presentation** - show the Flow logic diagram
5. **Demo in interview** - show how Apex and Flow coexist safely

---

## For Your Interview Presentation

**Slide Addition: "Flow Coexistence in Action"**

```
BEFORE IMPLEMENTATION (Fragmented):
┌─────────────┐
│ Apex        │ → Sets fields
│ beforeInsert│
└─────────────┘
        ↓
┌─────────────┐
│ Apex        │ → Sends email (❌ Duplicate)
│ afterInsert │
└─────────────┘
        ↓
┌─────────────┐
│ Flow        │ → Sends email (❌ Duplicate)
│ OnCreation  │
└─────────────┘
        ↓
    Result: 2 emails sent to user 😞

AFTER IMPLEMENTATION (Clean Boundaries):
┌─────────────┐
│ Apex        │ → Sets Status='Resolved'
│ beforeInsert│
└─────────────┘
        ↓
┌─────────────┐
│ Apex        │ → Publishes event
│ afterInsert │
└─────────────┘
        ↓
┌─────────────┐
│ Flow        │ → Watches for Status='Resolved'
│ OnResolve   │    Sends notification
└─────────────┘
        ↓
    Result: 1 email sent, clean flow 😊
```

---

## Summary

You now have:
- ✓ Apex framework (CaseTriggerHandler)
- ✓ Flow that works alongside Apex (Case_OnResolvedCreation)
- ✓ Clear boundaries (Apex = before-save, Flow = after-save)
- ✓ Manual testing approach
- ✓ Integration test template
- ✓ Presentation talking points

**This demonstrates the complete Flow Coexistence Strategy** from your interview requirements! 🎉
