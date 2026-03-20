# Quick Reference: Trigger Framework & Flow Coexistence

## Framework At-A-Glance

### How It Works (3 Steps)

```
1. Trigger delegates to Framework
   trigger CaseTrigger on Case (before insert, after insert, ...) {
       TriggerFramework.execute(new CaseTriggerHandler());
   }

2. Framework routes to Handler
   public void beforeInsert(TriggerFramework.TriggerContext context) {
       // Business logic here
   }

3. Add new rules without modifying trigger
   if (isFlightDisruptionCancellation(c)) {
       c.Status = 'Resolved';
   }
```

### Class Structure

```
TriggerFramework.cls
├── execute(handler) → Main entry point
├── getContext(key) → Access trigger context
└── clearRegistry() → For testing

TriggerHandler.cls (abstract base)
├── getHandlerKey() → "CaseTriggerHandler"
├── beforeInsert()
├── afterInsert()
├── beforeUpdate()
├── afterUpdate()
├── beforeDelete()
├── afterDelete()
└── afterUndelete()

CaseTriggerHandler.cls (example)
└── Implements business rules

TriggerBypassUtil.cls
├── bypass(key)
├── clearBypass(key)
├── isBypassed(key)
└── clearAllBypasses()
```

---

## Adding a New Rule (No Trigger Change!)

**Before:**
```apex
// Modify trigger to add new logic ❌
trigger CaseTrigger on Case (before insert) {
    for (Case c : Trigger.new) {
        if (c.Reason == 'Flight Disruption' && c.Type == 'Cancellation') {
            c.Status = 'Resolved';
        }
        // How to add new rule? Modify trigger again...
    }
}
```

**After (with Framework):**
```apex
// Add rule to handler, trigger stays thin ✓
public void beforeInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    
    for (Case c : newCases) {
        // Rule 1: Auto-resolve Flight Disruption Cancellations
        if (isFlightDisruptionCancellation(c)) {
            c.Status = 'Resolved';
        }
        
        // Rule 2: High-priority cases get escalated
        if (shouldEscalate(c)) {
            c.Priority = 'High';
        }
        
        // Rule 3: VIP customers get premium SLA
        if (isVIPCustomer(c.AccountId)) {
            c.SLA__c = 'Premium';
        }
    }
}
```

---

## Flow Coexistence Patterns

### Pattern 1: Apex Validates, Flow Notifies

```
┌─────────────────────┐
│ Apex beforeInsert   │
│ - Validate fields   │
│ - Calculate values  │
│ - Set Status        │
└──────────┬──────────┘
           │ Publish Event
           ▼
┌─────────────────────┐
│ Record-Triggered    │
│ Flow                │
│ - Send notification │
│ - Create related    │
│   records           │
│ - Update child recs │
└─────────────────────┘
```

### Pattern 2: Bypass Flag for Mutual Exclusion

```
Apex: Check bypass flag
IF NOT bypassed THEN
  - Set fields
  - Save record

Flow: Watch bypass flag
IF bypassed = true THEN
  - Skip flow actions
ELSE
  - Do notifications
```

### Pattern 3: Platform Event Decoupling

```
┌─────────────────────┐
│ Apex afterInsert    │
│ Publish event:      │
│ CaseCreated__e      │
└──────────┬──────────┘
           │
           ▼ (async, no wait)
┌─────────────────────┐
│ Flow (Event-based)  │
│ Responds to:        │
│ CaseCreated event   │
└─────────────────────┘
```

---

## Bypass Logic (Data Loads)

```apex
// Suppress triggers during bulk import
TriggerBypassUtil.bypass('CaseTriggerHandler');

// Import 50k cases without trigger overhead
insert largeCaseList;

// Re-enable
TriggerBypassUtil.clearBypass('CaseTriggerHandler');

// Or bypass multiple handlers
TriggerBypassUtil.bypassMultiple(new Set<String>{
    'CaseTriggerHandler',
    'AccountTriggerHandler'
});
```

---

## Testing

```apex
@isTest
static void testFlightCancellationAutoResolve() {
    Case c = new Case(
        Reason = 'Flight Disruption',
        Type = 'Cancellation'
    );
    
    insert c;
    
    Case result = [SELECT Status, Resolution__c 
                   FROM Case WHERE Id = :c.Id];
    Assert.areEqual('Resolved', result.Status);
    Assert.areEqual('Refund', result.Resolution__c);
}

@isTest
static void testBypass() {
    TriggerBypassUtil.bypass('CaseTriggerHandler');
    
    Case c = new Case(Reason = 'Flight Disruption', Type = 'Cancellation');
    insert c;
    
    Case result = [SELECT Status FROM Case WHERE Id = :c.Id];
    Assert.areEqual('New', result.Status); // NOT auto-resolved
}
```

---

## Decision Tree: Which Layer?

```
┌─────────────────────────────────────┐
│ Where should logic go?              │
└────────────┬────────────────────────┘
             │
             ├─→ Validate fields?
             │   → Apex beforeInsert/beforeUpdate
             │
             ├─→ Calculate/auto-populate?
             │   → Apex beforeInsert/beforeUpdate
             │
             ├─→ Prevent invalid state?
             │   → Apex beforeInsert/beforeUpdate
             │
             ├─→ Send notification?
             │   → Flow (after record saved)
             │   → Or: Apex publishes event, Flow listens
             │
             ├─→ Complex workflow?
             │   → Flow
             │   → Or: Queueable Apex job
             │
             └─→ External integration?
                 → Queueable/Batch Apex
                 → Or: Flow callout action
```

---

## Naming Conventions

| Entity | Format | Example |
|--------|--------|---------|
| Handler | `{Object}TriggerHandler` | `CaseTriggerHandler` |
| Trigger | `{Object}Trigger` | `CaseTrigger` |
| Flow | `{Object}_OnEvent` | `Case_OnCreation` |
| Event | `{Object}Created__e` | `CaseCreated__e` |
| Field (bypass) | `Bypass{Action}__c` | `BypassAutoResolve__c` |

---

## Checklist: Adding New Object

- [ ] Create `{Object}TriggerHandler.cls` extending `TriggerHandler`
- [ ] Implement `getHandlerKey()` returning `"{Object}TriggerHandler"`
- [ ] Override event methods (beforeInsert, afterUpdate, etc.)
- [ ] Create `{Object}Trigger` with single line: `TriggerFramework.execute(new {Object}TriggerHandler())`
- [ ] Create unit tests in `{Object}TriggerHandlerTest.cls`
- [ ] Design matching Flows if needed (naming: `{Object}_OnEvent`)
- [ ] Add to documentation
- [ ] Deploy and test end-to-end

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Handler runs twice | Not using framework registry | Ensure single `TriggerFramework.execute()` in trigger |
| Bypass not working | Clearing bypass at wrong time | Clear bypass AFTER all DML, not before |
| Flow doesn't fire | Flow conditions not met | Check trigger timing, add Flow debug logs |
| Recursive updates | BeforeInsert logic doing DML | Move DML to afterInsert/afterUpdate |
| Too many SOQL queries | Handler not bulk-aware | Use maps to avoid N+1 queries |

---

## Key Principles

1. **Keep triggers thin** — One line of delegation
2. **Put logic in handlers** — Organized, testable, reusable
3. **Apex validates, flows orchestrate** — Clear boundary
4. **Use bypass for data loads** — TriggerBypassUtil
5. **Test independently** — Unit test handlers, integration test flows
6. **Document future additions** — Naming conventions matter
7. **Use platform events** — For decoupling Apex from Flows

---

## Presentation Talking Points

### Slide 1: The Problem
- Fragmented logic (triggers + flows)
- Duplicate notifications
- Unpredictable execution
- Hard to maintain

### Slide 2: The Solution
- Lightweight framework (4 core classes)
- Handler registry prevents duplicates
- Clear execution order
- Extensible without code changes

### Slide 3: How It Works
- Trigger delegates to Framework
- Framework routes to Handler
- Handler implements business logic
- New rules added to handler, not trigger

### Slide 4: Flow Coexistence
- Apex owns before-save validation
- Flows own downstream orchestration
- Platform events bridge the gap
- Three patterns shown

### Slide 5: Demo
- Show CaseTriggerHandler
- Add new rule (no trigger change)
- Run test (passes)
- Explain bypass for bulk loads

### Slide 6: Q&A
- Scalability: Handles 100+ objects
- Testing: Each handler independently testable
- Performance: Minimal overhead, registry prevents duplicates
- Migration: Add new objects iteratively
