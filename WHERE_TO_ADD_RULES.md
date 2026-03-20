# Where to Add Rules in CaseTriggerHandler

## Overview
Your `CaseTriggerHandler` has **7 different methods** where you can add business rules. Each handles a different trigger event. Let me show you exactly where.

---

## 1. **beforeInsert() - Before Record Saved**

**Location:** [CaseTriggerHandler.cls](CaseTriggerHandler.cls#L23-L33)

**When it runs:** When new Case records are being inserted (before saved to DB)

**Best for:**
- ✅ Auto-populate fields
- ✅ Set default values
- ✅ Validate field values
- ✅ Prevent insertion with errors

**Example: Add a new rule**

```apex
public override void beforeInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    
    // EXISTING RULE 1: Auto-resolve Flight Disruption Cancellations
    for (Case c : newCases) {
        if (isFlightDisruptionCancellation(c)) {
            c.Resolution__c = REFUND_RESOLUTION;
            c.Status = 'Resolved';
        }
        
        // ✅ ADD NEW RULE 2 HERE: Auto-set priority for high-value accounts
        if (isHighValueAccount(c.AccountId)) {
            c.Priority = 'High';
        }
        
        // ✅ ADD NEW RULE 3 HERE: Assign to specific queue
        if (c.Type == 'Escalation') {
            c.OwnerId = getEscalationQueueId();
        }
    }
}

// Helper method for new rule
private Boolean isHighValueAccount(Id accountId) {
    // Query account to check if high-value
    Account acc = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :accountId LIMIT 1];
    return acc != null && acc.AnnualRevenue > 1000000;
}

private Id getEscalationQueueId() {
    Group queue = [SELECT Id FROM Group WHERE Name = 'Escalation Queue' LIMIT 1];
    return queue?.Id;
}
```

---

## 2. **afterInsert() - After Record Saved**

**Location:** [CaseTriggerHandler.cls](CaseTriggerHandler.cls#L35-L41)

**When it runs:** After new Case records are saved to database

**Best for:**
- ✅ Create related records (Tasks, Emails, Events)
- ✅ Update parent records
- ✅ Send notifications
- ✅ Queue async jobs

**Example: Add a new rule**

```apex
public override void afterInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    
    // EXISTING RULE: Log case creation
    logCaseCreations(newCases);
    
    // ✅ ADD NEW RULE 2 HERE: Create follow-up task
    createFollowUpTasks(newCases);
    
    // ✅ ADD NEW RULE 3 HERE: Send Slack notification
    sendSlackNotifications(newCases);
    
    // ✅ ADD NEW RULE 4 HERE: Queue email job
    queueEmailNotifications(newCases);
}

private void createFollowUpTasks(List<Case> cases) {
    List<Task> tasksToCreate = new List<Task>();
    
    for (Case c : cases) {
        if (c.Priority == 'High') {
            Task t = new Task(
                WhoId = c.ContactId,
                WhatId = c.Id,
                Subject = 'Follow up on High Priority Case',
                ActivityDate = System.today().addDays(1),
                Status = 'Not Started'
            );
            tasksToCreate.add(t);
        }
    }
    
    if (!tasksToCreate.isEmpty()) {
        insert tasksToCreate;
    }
}

private void sendSlackNotifications(List<Case> cases) {
    // Queue async job to send Slack messages
    System.enqueueJob(new SlackNotificationJob(cases));
}

private void queueEmailNotifications(List<Case> cases) {
    // Send emails asynchronously
    List<String> emails = new List<String>();
    for (Case c : cases) {
        if (isFlightDisruptionCancellation(c)) {
            emails.add('escalations@airline.com');
        }
    }
    
    if (!emails.isEmpty()) {
        // Queue email job here
    }
}
```

---

## 3. **beforeUpdate() - Before Record Updated**

**Location:** [CaseTriggerHandler.cls](CaseTriggerHandler.cls#L43-L55)

**When it runs:** When Case records are being updated (before saved)

**Best for:**
- ✅ Validate field changes
- ✅ Prevent invalid transitions
- ✅ Auto-populate based on changes
- ✅ Add error messages
- ✅ Compare old vs new values

**Example: Add a new rule**

```apex
public override void beforeUpdate(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    Map<Id, Case> oldCasesMap = (Map<Id, Case>) context.oldMap;
    
    for (Case newCase : newCases) {
        Case oldCase = oldCasesMap.get(newCase.Id);
        
        // EXISTING RULE: Prevent status change if resolved
        if (oldCase.Status == 'Resolved' && newCase.Status != 'Resolved') {
            newCase.addError('Cannot change status of resolved cases');
        }
        
        // ✅ ADD NEW RULE 2 HERE: Validate priority changes
        if (oldCase.Priority != newCase.Priority) {
            if (!isValidPriorityTransition(oldCase.Priority, newCase.Priority)) {
                newCase.addError('Invalid priority transition: ' + oldCase.Priority + 
                                ' → ' + newCase.Priority);
            }
        }
        
        // ✅ ADD NEW RULE 3 HERE: Auto-set resolution date
        if (oldCase.Status != 'Resolved' && newCase.Status == 'Resolved') {
            newCase.Resolution__c = 'Resolved by user';
            // Could also set custom resolution date field
        }
        
        // ✅ ADD NEW RULE 4 HERE: Validate ownership changes
        if (oldCase.OwnerId != newCase.OwnerId) {
            if (!isValidOwner(newCase.OwnerId)) {
                newCase.addError('Cannot assign to inactive users');
            }
        }
    }
}

private Boolean isValidPriorityTransition(String oldPriority, String newPriority) {
    // Define which priority transitions are allowed
    Set<String> validTransitions = new Set<String>{
        'Low-Medium', 'Low-High', 'Medium-High'  // Allow up-prioritization
    };
    return validTransitions.contains(oldPriority + '-' + newPriority);
}

private Boolean isValidOwner(Id ownerId) {
    User owner = [SELECT Id, IsActive FROM User WHERE Id = :ownerId LIMIT 1];
    return owner != null && owner.IsActive;
}
```

---

## 4. **afterUpdate() - After Record Updated**

**Location:** [CaseTriggerHandler.cls](CaseTriggerHandler.cls#L57-L72)

**When it runs:** After Case records are updated and saved to database

**Best for:**
- ✅ Trigger downstream processes
- ✅ Update related records
- ✅ Log audit trail
- ✅ Send notifications on status changes
- ✅ Create chatter posts

**Example: Add a new rule**

```apex
public override void afterUpdate(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    Map<Id, Case> oldCasesMap = (Map<Id, Case>) context.oldMap;
    
    // EXISTING: Track status changes
    List<Case> statusChangedCases = new List<Case>();
    for (Case newCase : newCases) {
        Case oldCase = oldCasesMap.get(newCase.Id);
        if (newCase.Status != oldCase.Status) {
            statusChangedCases.add(newCase);
        }
    }
    
    // ✅ ADD NEW RULE 2 HERE: Update parent account when critical case resolved
    updateParentAccountOnCaseResolution(newCases, oldCasesMap);
    
    // ✅ ADD NEW RULE 3 HERE: Send notification when escalated
    handleCaseEscalation(newCases, oldCasesMap);
    
    // ✅ ADD NEW RULE 4 HERE: Queue satisfaction survey
    queueSatisfactionSurvey(statusChangedCases);
}

private void updateParentAccountOnCaseResolution(List<Case> newCases, 
                                                  Map<Id, Case> oldCasesMap) {
    Set<Id> accountIds = new Set<Id>();
    
    for (Case newCase : newCases) {
        Case oldCase = oldCasesMap.get(newCase.Id);
        // If case just resolved, update account
        if (oldCase.Status != 'Resolved' && newCase.Status == 'Resolved') {
            accountIds.add(newCase.AccountId);
        }
    }
    
    if (!accountIds.isEmpty()) {
        List<Account> accountsToUpdate = [SELECT Id FROM Account 
                                         WHERE Id IN :accountIds];
        for (Account acc : accountsToUpdate) {
            acc.LastResolvedCaseDate__c = System.now();
        }
        update accountsToUpdate;
    }
}

private void handleCaseEscalation(List<Case> newCases, Map<Id, Case> oldCasesMap) {
    List<Case> escalatedCases = new List<Case>();
    
    for (Case newCase : newCases) {
        Case oldCase = oldCasesMap.get(newCase.Id);
        // Check if case was escalated
        if (oldCase.Priority != 'High' && newCase.Priority == 'High') {
            escalatedCases.add(newCase);
        }
    }
    
    if (!escalatedCases.isEmpty()) {
        // Send email to escalation team
        sendEscalationEmail(escalatedCases);
    }
}

private void queueSatisfactionSurvey(List<Case> resolvedCases) {
    if (!resolvedCases.isEmpty()) {
        System.enqueueJob(new SurveyNotificationJob(resolvedCases));
    }
}
```

---

## 5. **beforeDelete() - Before Record Deleted** (Currently Empty)

**Location:** [TriggerHandler.cls](TriggerHandler.cls) - Virtual method

**When it runs:** When Case records are being deleted (before deleted)

**Best for:**
- ✅ Prevent deletion with conditions
- ✅ Validate delete permissions
- ✅ Log deletion attempts

**Example: Add a rule**

```apex
public override void beforeDelete(TriggerFramework.TriggerContext context) {
    List<Case> casesToDelete = context.oldList;
    
    // ✅ RULE: Prevent deletion of resolved/closed cases
    for (Case c : casesToDelete) {
        if (c.Status == 'Resolved' || c.Status == 'Closed') {
            c.addError('Cannot delete resolved cases. Archive instead.');
        }
    }
    
    // ✅ RULE: Prevent deletion if open child records exist
    Set<Id> caseIds = new Map<Id, Case>(casesToDelete).keySet();
    Integer openTaskCount = [SELECT COUNT() FROM Task 
                            WHERE WhatId IN :caseIds AND IsClosed = false];
    
    if (openTaskCount > 0) {
        for (Case c : casesToDelete) {
            c.addError('Cannot delete case with open tasks. Close them first.');
        }
    }
}
```

---

## 6. **afterDelete() - After Record Deleted** (Currently Empty)

**Location:** [TriggerHandler.cls](TriggerHandler.cls) - Virtual method

**When it runs:** After Case records are deleted from database

**Best for:**
- ✅ Clean up related records
- ✅ Log audit trail
- ✅ Update summary fields
- ✅ Send notifications

**Example: Add a rule**

```apex
public override void afterDelete(TriggerFramework.TriggerContext context) {
    List<Case> deletedCases = context.oldList;
    
    // ✅ RULE: Close related tasks when case deleted
    Set<Id> caseIds = new Map<Id, Case>(deletedCases).keySet();
    List<Task> tasksToUpdate = [SELECT Id FROM Task 
                               WHERE WhatId IN :caseIds AND IsClosed = false];
    
    for (Task t : tasksToUpdate) {
        t.IsClosed = true;
        t.Status = 'Cancelled';
    }
    
    if (!tasksToUpdate.isEmpty()) {
        update tasksToUpdate;
    }
    
    // ✅ RULE: Archive deleted case metadata
    archiveDeletedCaseData(deletedCases);
}

private void archiveDeletedCaseData(List<Case> deletedCases) {
    // Create archive record or log deletion
    List<Case_Archive__c> archiveRecords = new List<Case_Archive__c>();
    
    for (Case c : deletedCases) {
        archiveRecords.add(new Case_Archive__c(
            Case_ID__c = c.Id,
            Subject__c = c.Subject,
            Reason__c = c.Reason,
            Deleted_Date__c = System.now()
        ));
    }
    
    insert archiveRecords;
}
```

---

## 7. **afterUndelete() - After Record Undeleted** (Currently Empty)

**Location:** [TriggerHandler.cls](TriggerHandler.cls) - Virtual method

**When it runs:** After deleted Case records are restored

**Best for:**
- ✅ Restore related records
- ✅ Log restoration
- ✅ Update audit trail

**Example: Add a rule**

```apex
public override void afterUndelete(TriggerFramework.TriggerContext context) {
    List<Case> restoredCases = context.newList;
    
    // ✅ RULE: Reopen related tasks when case restored
    Set<Id> caseIds = new Map<Id, Case>(restoredCases).keySet();
    List<Task> tasksToUpdate = [SELECT Id FROM Task 
                               WHERE WhatId IN :caseIds 
                               AND Status = 'Cancelled'];
    
    for (Task t : tasksToUpdate) {
        t.Status = 'Not Started';
    }
    
    if (!tasksToUpdate.isEmpty()) {
        update tasksToUpdate;
    }
    
    // ✅ RULE: Log restoration
    logCaseRestorations(restoredCases);
}

private void logCaseRestorations(List<Case> restoredCases) {
    for (Case c : restoredCases) {
        System.debug('Case restored: ' + c.Id + ', Subject: ' + c.Subject);
    }
}
```

---

## Quick Reference: Where to Add Rules

| Trigger Event | Method | When | Best For | Data Available |
|---------------|--------|------|----------|-----------------|
| **INSERT (BEFORE)** | `beforeInsert()` | Before saved | Auto-populate, validate | `newList` only |
| **INSERT (AFTER)** | `afterInsert()` | After saved | Create related, notify | `newList` + DB |
| **UPDATE (BEFORE)** | `beforeUpdate()` | Before saved | Validate changes, prevent | `newList`, `oldMap` |
| **UPDATE (AFTER)** | `afterUpdate()` | After saved | Update related, log | `newList`, `oldMap` + DB |
| **DELETE (BEFORE)** | `beforeDelete()` | Before deleted | Prevent deletion | `oldList` only |
| **DELETE (AFTER)** | `afterDelete()` | After deleted | Clean up, archive | `oldList` + DB |
| **UNDELETE (AFTER)** | `afterUndelete()` | After restored | Restore related | `newList` + DB |

---

## Rule Adding Checklist

When adding a new rule, follow these steps:

```apex
// 1. Pick the right trigger event method
public override void beforeInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    
    // 2. Loop through records
    for (Case c : newCases) {
        
        // 3. Check the condition
        if (someCondition(c)) {
            
            // 4. Perform action
            c.SomeField = 'value';  // Or add error, or queue job
        }
    }
    
    // 5. Or handle with helper method
    helpMethod(newCases);
}

// 6. Create helper method (optional)
private void helpMethod(List<Case> cases) {
    // Implementation
}

// 7. Add unit tests
@isTest
static void testNewRule() {
    // Create test case
    // Execute trigger
    // Assert results
}
```

---

## Real-World Example: Adding a Complete Rule

**Task:** "Create a task when a High Priority case is created"

```apex
// Step 1: Identify best trigger event → afterInsert ✓
public override void afterInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    
    // Step 2: Add the rule
    createTasksForHighPriorityCases(newCases);  // Call helper method
}

// Step 3: Implement helper method
private void createTasksForHighPriorityCases(List<Case> cases) {
    List<Task> tasksToCreate = new List<Task>();
    
    for (Case c : cases) {
        if (c.Priority == 'High') {
            tasksToCreate.add(
                new Task(
                    Subject = 'Follow up on high priority case',
                    WhatId = c.Id,
                    ActivityDate = System.today().addDays(1)
                )
            );
        }
    }
    
    if (!tasksToCreate.isEmpty()) {
        insert tasksToCreate;
    }
}

// Step 4: Add test
@isTest
static void testCreateTaskForHighPriority() {
    TriggerFramework.clearRegistry();
    
    Case testCase = new Case(
        Subject = 'High Priority Issue',
        Priority = 'High',
        Status = 'New'
    );
    
    Test.startTest();
    insert testCase;
    Test.stopTest();
    
    Task createdTask = [SELECT Id FROM Task WHERE WhatId = :testCase.Id LIMIT 1];
    System.assertNotEquals(null, createdTask, 'Task should be created');
}
```

---

## Common Mistakes to Avoid

| ❌ Mistake | ✅ Solution |
|-----------|------------|
| Adding DML (`insert`/`update`) in beforeInsert | Move to `afterInsert` |
| Querying old values in `beforeInsert` | Use `afterInsert` which has DB access |
| Not checking if value changed | Compare: `oldCase.Status != newCase.Status` |
| Adding logic directly in trigger | Move to handler method for testability |
| Not handling bulk operations | Loop through all records in context.newList |
| Forgetting to clear registry in tests | Add `TriggerFramework.clearRegistry();` at start |

---

## Key Takeaways

✅ **beforeInsert** → Populate fields before save  
✅ **afterInsert** → Create related records after save  
✅ **beforeUpdate** → Validate changes before save  
✅ **afterUpdate** → Handle post-save logic  
✅ **beforeDelete** → Prevent invalid deletions  
✅ **afterDelete** → Clean up after deletion  
✅ **afterUndelete** → Restore related data  

Pick the right method, add your logic, create helper methods, write tests! 🚀
