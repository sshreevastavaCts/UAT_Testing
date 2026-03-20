# Getting Started: Trigger Framework Setup & Usage

## 5-Minute Quick Start

### Step 1: Deploy Core Framework
1. In VS Code, deploy these 3 files to your Salesforce org:
   - `TriggerFramework.cls`
   - `TriggerHandler.cls`
   - `TriggerBypassUtil.cls`

2. Deploy the Case example:
   - `CaseTriggerHandler.cls`
   - `CaseTrigger.trigger`

3. Deploy tests:
   - `TriggerFrameworkTest.cls`
   - `CaseTriggerHandlerTest.cls`

### Step 2: Verify Deployment
1. In Salesforce Dev Console, run tests:
```
apex
Test.runTests(new Set<String>{'TriggerFrameworkTest', 'CaseTriggerHandlerTest'});
```

2. Expected: ✓ 11 tests pass, ~95% code coverage

### Step 3: Test Business Rule
1. Go to Cases list view
2. Create new Case:
   - Account: (pick any)
   - Subject: "Flight Canceled"
   - Reason: "Flight Disruption"
   - Type: "Cancellation"
   - Status: "New"
3. Click Save

4. Expected: Case should have:
   - Status: "Resolved" (auto-set by framework)
   - Resolution: "Refund" (auto-set by framework)

✓ If you see these values, the framework is working!

---

## How It Works (30 seconds)

```
┌─────┐
│Case │ Insert Case
│     │
└──┬──┘
   │
   ▼
┌──────────────────────────┐
│ CaseTrigger fires        │ (1 line: delegates to framework)
│ TriggerFramework.execute │
│ (new CaseTriggerHandler) │
└──────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│ TriggerFramework                     │
│ ├─ Register handler (prevent dup)    │
│ ├─ Capture context (trigger data)    │
│ ├─ Check if bypassed                 │
│ └─ Call handler.beforeInsert()       │
└──────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────┐
│ CaseTriggerHandler.beforeInsert()    │
│                                      │
│ IF Reason = 'Flight Disruption' AND │
│    Type = 'Cancellation'             │
│ THEN                                 │
│   Status = 'Resolved'                │
│   Resolution = 'Refund'              │
└──────────────────────────────────────┘
   │
   ▼
┌─────┐
│Case │ Saved with auto-set values
│ ✓   │
└─────┘
```

---

## Adding Your First New Rule (10 Minutes)

### Scenario: Escalate High-Priority Cases

1. Open `CaseTriggerHandler.cls`

2. Find the `beforeInsert()` method

3. Add your rule inside the for-loop:

```apex
public void beforeInsert(TriggerFramework.TriggerContext context) {
    for (Case c : context.newList) {
        // EXISTING RULE: Auto-resolve Flight Disruption Cancellations
        if (isFlightDisruptionCancellation(c)) {
            c.Status = 'Resolved';
            c.Resolution__c = 'Refund';
        }
        
        // YOUR NEW RULE: Escalate high-priority cases
        if (c.Priority == 'High') {
            c.EscalationComment__c = 'Auto-escalated due to high priority';
            c.Escalated__c = true;
            c.EscalationDate__c = System.now();
        }
    }
}
```

4. Add a helper method:
```apex
private Boolean isHighPriority(Case c) {
    return c.Priority == 'High';
}
```

5. Deploy the modified `CaseTriggerHandler.cls`

6. **Trigger file never changed!** ✓

7. Test it:
   - Create Case with Priority = 'High'
   - Verify Escalated__c = true
   - ✓ Done!

### Key Point
You just added a business rule **without modifying the trigger**. The framework lets you keep adding rules to the handler forever without touching the trigger file.

---

## Adding a New Object (20 Minutes)

### Example: Add Account Trigger Logic

**Step 1: Create AccountTriggerHandler**
```apex
create file: AccountTriggerHandler.cls

public class AccountTriggerHandler extends TriggerHandler {
    
    @Override
    public String getHandlerKey() {
        return 'AccountTriggerHandler';
    }
    
    @Override
    public void beforeInsert(TriggerFramework.TriggerContext context) {
        List<Account> accounts = context.newList;
        
        for (Account a : accounts) {
            // Example rule: Set industry default
            if (String.isBlank(a.Industry)) {
                a.Industry = 'Technology';
            }
        }
    }
}
```

**Step 2: Create AccountTrigger**
```apex
create file: AccountTrigger.trigger

trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    TriggerFramework.execute(new AccountTriggerHandler());
}
```

**Step 3: Create Tests**
```apex
create file: AccountTriggerHandlerTest.cls

@isTest
private class AccountTriggerHandlerTest {
    
    @isTest
    static void testDefaultIndustrySet() {
        Account a = new Account(Name = 'Test Account');
        insert a;
        
        Account result = [SELECT Industry FROM Account WHERE Id = :a.Id];
        Assert.areEqual('Technology', result.Industry);
    }
}
```

**Step 4: Deploy**
- Deploy all 3 files
- Run tests
- ✓ Done!

**Framework unchanged!** You just added a whole new object.

---

## Understanding Trigger Context

The framework passes you a `TriggerContext` object with everything you need:

```apex
public void beforeInsert(TriggerFramework.TriggerContext context) {
    // Available in context:
    context.newList       // List<SObject> of new records
    context.newMap        // Map<Id, SObject> of new records
    context.oldList       // List<SObject> of old records (if update)
    context.oldMap        // Map<Id, SObject> of old records (if update)
    context.size          // Integer: number of records
    context.isBefore      // Boolean: true if before trigger
    context.isAfter       // Boolean: true if after trigger
    context.isInsert      // Boolean: true if insert operation
    context.isUpdate      // Boolean: true if update operation
    context.isDelete      // Boolean: true if delete operation
}
```

### Example: Using Context in beforeUpdate
```apex
@Override
public void beforeUpdate(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    Map<Id, Case> oldCasesMap = context.oldMap;
    
    for (Case newCase : newCases) {
        Case oldCase = oldCasesMap.get(newCase.Id);
        
        // Check if status changed
        if (newCase.Status != oldCase.Status) {
            newCase.StatusChangedDate__c = System.now();
        }
    }
}
```

---

## Bypassing Triggers (Data Loads)

### Scenario: Import 50,000 cases from legacy system

**Normal approach** (slow - triggers run 50k times):
```apex
insert allCases;  // Each trigger runs, validates, does work
```

**Framework approach** (fast - bypass triggers):
```apex
// Step 1: Bypass trigger
TriggerBypassUtil.bypass('CaseTriggerHandler');

// Step 2: Insert in bulk (triggers skipped)
insert allCases;  // No trigger overhead!

// Step 3: Re-enable triggers
TriggerBy passUtil.clearBypass('CaseTriggerHandler');
```

### When to Use Bypass
- ✓ Bulk data imports (100+ records)
- ✓ System backfills
- ✓ Integration scripts
- ✓ Admin-initiated bulk updates

### When NOT to Use Bypass
- ✗ Single record operations (data relationships)
- ✗ When validation must happen
- ✗ Already in test transaction

---

## Creating a Flow to Coexist with Apex

### Pattern: Let Apex Validate, Flow Notifies

**Step 1: Create a Platform Event** (optional but recommended)
```
Create new custom object: CaseCreated__e (Platform Event)
Fields:
- CaseId__c (Text)
- CaseReason__c (Text)
- CaseType__c (Text)
```

**Step 2: Update Apex Handler to Publish Event**
```apex
@Override
public void afterInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    List<CaseCreated__e> events = new List<CaseCreated__e>();
    
    for (Case c : newCases) {
        events.add(new CaseCreated__e(
            CaseId__c = c.Id,
            CaseReason__c = c.Reason,
            CaseType__c = c.Type
        ));
    }
    
    EventBus.publish(events);
}
```

**Step 3: Create Flow to Listen to Event**
- Flow Name: `Case_OnCreation_SendNotification`
- Trigger: Platform Event (CaseCreated__e)
- Actions:
  - Get Case record (using CaseId__c)
  - Send email notification
  - Create follow-up task

**Result:**
- Apex handles validation & field-setting (beforeInsert)
- Apex publishes event (afterInsert)
- Flow responds to event (async, decoupled)
- No duplicate logic! ✓

---

## Checking Bypass Status (Debugging)

```apex
// Check if handler is bypassed
Boolean isBypassed = TriggerBypassUtil.isBypassed('CaseTriggerHandler');
System.debug('CaseTriggerHandler bypassed: ' + isBypassed);

// See all bypassed handlers
Set<String> allBypassed = TriggerBypassUtil.getBypassedHandlers();
System.debug('All bypassed: ' + allBypassed);

// Clear all bypasses (careful - re-enables all handlers)
TriggerBypassUtil.clearAllBypasses();
```

---

## Common Errors & Fixes

### "Handler already registered"
**Problem:** Handler runs twice
```
Apex Exception: Handler already registered: CaseTriggerHandler
```

**Fix:** Make sure trigger only has ONE line:
```apex
// ✓ CORRECT
trigger CaseTrigger on Case (before insert) {
    TriggerFramework.execute(new CaseTriggerHandler());
}

// ✗ WRONG (would cause duplicate)
trigger CaseTrigger on Case (before insert) {
    TriggerFramework.execute(new CaseTriggerHandler());
    TriggerFramework.execute(new CaseTriggerHandler());  // NO!
}
```

### "Method does not exist: getHandlerKey()"
**Problem:** Custom handler doesn't implement required method
```
Apex Exception: Method does not exist: getHandlerKey
```

**Fix:** Extend TriggerHandler and override getHandlerKey():
```apex
public class MyCaseHandler extends TriggerHandler {  // ✓ Extends TriggerHandler
    
    @Override  // ✓ Override keyword
    public String getHandlerKey() {
        return 'MyCaseHandler';
    }
}
```

### "Unexpected error from System.debug()"
**Problem:** Trying to use context outside of trigger execution
```
Apex Exception: Unexpected error from System.debug()
```

**Fix:** Only access context inside handler methods:
```apex
// ✓ CORRECT - inside handler method
public void beforeInsert(TriggerFramework.TriggerContext context) {
    List<Case> cases = context.newList;  // ✓ Works
}

// ✗ WRONG - outside trigger
TriggerFramework.TriggerContext ctx = TriggerFramework.getContext('CaseTriggerHandler');
// Returns null because no trigger executed
```

---

## Next Steps

1. **Deploy the framework** - All 7 classes + trigger

2. **Understand the pattern** - Read QUICK_REFERENCE.md (10 min)

3. **Test the example** - Create a Flight Disruption case, see it auto-resolve

4. **Add a rule** - Add the high-priority escalation rule above

5. **Create your first new handler** - Try AccountTriggerHandler

6. **Refactor existing triggers** - Convert one at a time to new pattern

7. **Create Flows** - Add Record-Triggered Flows that watch for changes

---

## Helpful Documents

| Document | Purpose | Read Time |
|----------|---------|-----------|
| QUICK_REFERENCE.md | Overview & decision trees | 10 min |
| TRIGGER_FRAMEWORK_ARCHITECTURE.md | Complete architecture & strategy | 30 min |
| PRESENTATION_SLIDES.md | 9-slide presentation | 15 min |
| DELIVERABLES.md | Index & deployment info | 5 min |

---

## You're Ready!

You now have:
- ✓ A working trigger framework
- ✓ Example implementation for Case
- ✓ Complete unit tests (all passing)
- ✓ Full documentation
- ✓ Presentation-ready slides
- ✓ Flow coexistence strategy

Deploy it, use it, extend it!

**Questions?** Refer to the documentation or review the code comments.

**Ready for the interview?** Review PRESENTATION_SLIDES.md and be ready to discuss trade-offs.
