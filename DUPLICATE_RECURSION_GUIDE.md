# Duplicate & Recursion Handling in Trigger Framework

## Overview

Your trigger framework has **multiple layers of protection** against duplicate execution and infinite recursion. Let me explain each mechanism.

---

## 1. Handler Registry (Primary Duplicate Prevention)

### How It Works

**File:** `TriggerFramework.cls` lines 9-10

```apex
// Static registry of active handlers - prevents duplicate handler execution
private static Map<String, TriggerHandler> handlerRegistry = new Map<String, TriggerHandler>();
```

**The Guard Clause:** Lines 28-32

```apex
public static void execute(TriggerHandler handler) {
    String handlerKey = handler.getHandlerKey();
    
    // Guard against duplicate handler execution in the same transaction
    if (handlerRegistry.containsKey(handlerKey)) {
        System.debug('Handler already registered: ' + handlerKey);
        return;  // ← EXIT EARLY, skip execution
    }
    
    handlerRegistry.put(handlerKey, handler);
    // ... rest of execution
}
```

### What This Prevents

```
Scenario: Case beforeInsert fires, then accidentally calls trigger again

FIRST EXECUTION:
├─ TriggerFramework.execute(new CaseTriggerHandler())
├─ Check: Is 'CaseTriggerHandler' in registry? NO
├─ Add to registry: YES
├─ Execute handler.beforeInsert()
└─ ✓ Handler runs once

SECOND EXECUTION (Same transaction):
├─ TriggerFramework.execute(new CaseTriggerHandler())
├─ Check: Is 'CaseTriggerHandler' in registry? YES ← Found it!
├─ System.debug('Handler already registered...')
└─ return; ← EXIT EARLY, DON'T RUN AGAIN

Net Result: Handler executes ONCE per transaction, never twice
```

### Code Example: Prevented Duplicate

**Scenario:** Someone writes a trigger that calls the handler twice by mistake

```apex
// BAD TRIGGER (Would cause duplicate without registry)
trigger CaseTrigger on Case (before insert) {
    TriggerFramework.execute(new CaseTriggerHandler());
    TriggerFramework.execute(new CaseTriggerHandler());  // Same handler!
}
```

**Without Registry:**
- ❌ Handler runs twice
- ❌ Business logic executed twice
- ❌ Potential data corruption

**With Registry:**
```
First execute():  Handler runs ✓
Second execute(): Caught by registry, skipped ✓
Result: Handler runs only ONCE
```

---

## 2. Static Map Scope (Transaction-Level Isolation)

### How It Works

The registry is **static** but scoped to a single transaction:

```apex
private static Map<String, TriggerHandler> handlerRegistry = new Map<String, TriggerHandler>();
```

### Transaction Boundaries

```
TRANSACTION 1: User creates Case
├─ Trigger fires
├─ handlerRegistry = {CaseTriggerHandler → instance}
├─ Handler executes
└─ Transaction ends → handlerRegistry reset

TRANSACTION 2: User creates another Case
├─ Trigger fires
├─ handlerRegistry = {} (EMPTY, new transaction!)
├─ No handler in registry yet
├─ Add CaseTriggerHandler
└─ Handler executes

Net Result: Each transaction has its own clean registry
```

### Code Evidence

**In TriggerFramework.cls:**

```apex
public static void clearRegistry() {
    handlerRegistry.clear();
    executionContexts.clear();
}
```

This is called in tests to ensure clean state between tests:

```apex
// In CaseTriggerHandlerTest.cls
@isTest
static void testFlightDisruptionCancellationAutoResolve() {
    TriggerFramework.clearRegistry();  // ← Clean slate for this test
    TriggerBypassUtil.clearAllBypasses();
    
    // Test code...
}
```

---

## 3. Recursion Prevention Mechanisms

### Mechanism A: Handler Registry (Primary)

Since a handler can only execute once per transaction, true recursion is impossible:

```
Recursion Scenario (Attempted):
┌─────────────────────────────────────────────────┐
│ CaseTrigger fires (beforeInsert)                │
├─────────────────────────────────────────────────┤
│ 1. TriggerFramework.execute(CaseTriggerHandler) │
│    └─ Handler runs, sets Status='Resolved'     │
│                                                 │
│ 2. Handler updates case: update case;          │
│    └─ Trigger fires AGAIN (afterUpdate)        │
│                                                 │
│ 3. TriggerFramework.execute(CaseTriggerHandler)│
│    └─ Check registry...                        │
│    └─ 'CaseTriggerHandler' already there!      │
│    └─ return; (skip execution)                 │
│                                                 │
│ Result: Handler doesn't run twice ✓            │
└─────────────────────────────────────────────────┘
```

### Mechanism B: Bypass Utility (Manual Recursion Control)

For complex scenarios where you need explicit recursion control:

```apex
// In CaseTriggerHandler.afterInsert()
public void afterInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    
    // If we need to update related records, prevent trigger re-fire
    TriggerBypassUtil.bypass('CaseTriggerHandler');
    
    // Safe to update now - trigger won't re-execute our logic
    update relatedRecords;
    
    TriggerBypassUtil.clearBypass('CaseTriggerHandler');
}
```

### Mechanism C: Async Processing (Best Practice for Complex Logic)

For truly complex operations, use async to avoid trigger stack limit:

```apex
// In CaseTriggerHandler.afterInsert()
public void afterInsert(TriggerFramework.TriggerContext context) {
    List<Case> newCases = context.newList;
    
    // Queue async job instead of direct update
    System.enqueueJob(new UpdateRelatedRecordsJob(newCases));
}
```

**Benefit:** Job executes outside trigger context, no recursion risk

---

## 4. Real-World Recursion Scenarios & How Framework Handles Them

### Scenario 1: Simple Recursion (Handler Updates Same Object)

```apex
public void beforeInsert(TriggerContext context) {
    for (Case c : context.newList) {
        if (c.Reason == 'Flight Disruption') {
            c.Status = 'Resolved';  // ← Update in SAME transaction
        }
    }
}
```

**How Framework Prevents Recursion:**
- beforeInsert runs
- Sets Status = 'Resolved'
- Record saved
- afterInsert runs
- If any code in afterInsert tries to call TriggerFramework.execute() again
  - ✓ Registry check: Handler already executed
  - ✓ Return early, no recursion

### Scenario 2: Related Record Update (Potential Recursion)

```apex
public void afterInsert(TriggerContext context) {
    List<Case> newCases = context.newList;
    
    // Need to update parent Account
    for (Case c : newCases) {
        Account acc = new Account(Id = c.AccountId);
        acc.LastCaseDate__c = System.now();
    }
    update accountsToUpdate;  // ← Could trigger AccountTrigger
}
```

**Recursion Risk:**
- Case trigger fires
- Updates Account
- Account trigger fires (separate handler)
- If Account name changes Case
- Case trigger fires AGAIN

**Framework Protection:**
```
Case Trigger fires
├─ CaseTriggerHandler registered
├─ Handler.afterInsert() runs
├─ Updates Account
├─ Account Trigger fires
├─ AccountTriggerHandler registered (DIFFERENT handler)
├─ Handler.afterInsert() runs
├─ Updates Case back
├─ Case Trigger fires AGAIN
├─ CaseTriggerHandler called again
├─ Registry check: Already registered! 
├─ return; (skip execution)
└─ ✓ No infinite loop

Result: Each handler runs once, no recursion
```

### Scenario 3: Batch DML (Multiple Records, Potential Recursion)

```apex
public void beforeInsert(TriggerContext context) {
    List<Case> newCases = context.newList;  // Could be 100 records
    
    for (Case c : newCases) {
        if (c.Type == 'Escalation') {
            c.Priority = 'High';
        }
    }
    // All 100 Records processed in ONE beforeInsert call
    // No recursion because beforeInsert fires ONCE per DML
}
```

**Framework Behavior:**
```
insert largeCaseList;  // 100 records
├─ beforeInsert fires (ONCE for all 100)
├─ TriggerFramework.execute() called (ONCE)
├─ Handler processes all 100 in loop
└─ Handler never called twice = No recursion ✓
```

---

## 5. Duplicate Prevention Test Evidence

### Test: testHandlerRegistryPreventsDuplicates()

**File:** `TriggerFrameworkTest.cls` lines 28-36

```apex
@isTest
static void testHandlerRegistryPreventsDuplicates() {
    TriggerFramework.clearRegistry();
    mockHandlerExecutionCount = 0;
    
    TriggerFramework.execute(new MockTriggerHandler());
    TriggerFramework.execute(new MockTriggerHandler());  // Same handler again
    
    // Should only execute once due to registry check
    System.assertEquals(1, mockHandlerExecutionCount, 'Handler should only execute once');
}
```

**What It Proves:**
- ✓ First execute(): Handler runs (count = 1)
- ✓ Second execute(): Handler skipped (count stays 1)
- ✓ Registry prevents duplicate execution

### Test: testBypassLogic()

**File:** `TriggerFrameworkTest.cls` lines 48-56

```apex
@isTest
static void testBypassLogic() {
    TriggerFramework.clearRegistry();
    TriggerBypassUtil.clearAllBypasses();
    mockHandlerExecutionCount = 0;
    
    TriggerBypassUtil.bypass('MockTriggerHandler');
    TriggerFramework.execute(new MockTriggerHandler());
    
    System.assertEquals(0, mockHandlerExecutionCount, 'Bypassed handler should not execute');
}
```

**What It Proves:**
- ✓ Bypass prevents handler execution entirely
- ✓ Useful for data loads or intentional skipping
- ✓ Manual control over execution

---

## 6. Bypass Utility Detailed Explanation

### How Bypass Works

**File:** `TriggerBypassUtil.cls`

```apex
private static Set<String> bypassedHandlers = new Set<String>();

public static void bypass(String handlerKey) {
    bypassedHandlers.add(handlerKey);
    System.debug('Bypassing handler: ' + handlerKey);
}

public static Boolean isBypassed(String handlerKey) {
    return bypassedHandlers.contains(handlerKey);
}
```

### In TriggerFramework

**Lines 34-38:**

```apex
// Check if logic is bypassed for this handler
if (TriggerBypassUtil.isBypassed(handler.getHandlerKey())) {
    System.debug('Trigger logic bypassed for: ' + handlerKey);
    return;  // Exit before executing
}
```

### Real-World Bypass Scenario

```apex
// Bulk data import with 50k cases
public static void importCasesFromLegacySystem(List<Case> legacyCases) {
    // Bypass trigger validation (we already validated in legacy system)
    TriggerBypassUtil.bypass('CaseTriggerHandler');
    
    // Insert massive batch (no trigger overhead)
    insert legacyCases;  // 50,000 records inserted FAST
    
    // Re-enable triggers for normal operations
    TriggerBypassUtil.clearBypass('CaseTriggerHandler');
}
```

**Without Bypass:**
- ❌ Trigger fires 50,000 times
- ❌ Validation runs 50,000 times
- ❌ Governor limits exceeded
- ❌ Takes 10+ minutes

**With Bypass:**
- ✓ Trigger skipped entirely
- ✓ Insert completes in seconds
- ✓ Governor limits respected
- ✓ Clean, predictable

---

## 7. Stack Trace Protection

### Context Tracking

The framework tracks execution context:

```apex
// Static execution context tracking
private static Map<String, TriggerContext> executionContexts = 
    new Map<String, TriggerContext>();

// After execute(), context is stored
executionContexts.put(handlerKey, context);

// Handlers can check their context
public void beforeInsert(TriggerFramework.TriggerContext context) {
    if (context.isInsert && context.isBefore) {
        // Safe to do beforeInsert logic
    }
}
```

### Why This Matters

You can't accidentally do things in the wrong trigger event:

```apex
// SAFE: Checks trigger event
public void beforeInsert(TriggerContext context) {
    if (context.isBefore) {
        c.Status = 'Resolved';  // ✓ Safe in beforeInsert
    }
}

// PREVENTED: Wrong event
public void afterInsert(TriggerContext context) {
    if (context.isBefore) {
        c.Status = 'Resolved';  // ✗ Won't run, wrong event
    }
}
```

---

## 8. Visual Flow: How Duplicates Are Prevented

```
┌─────────────────────────────────────────────────────────────────┐
│ Case Insert with Auto-Resolve (Flight Disruption Cancellation) │
└─────────────────────────────────────────────────────────────────┘
                           │
                    ▼▼▼▼▼▼▼▼▼▼▼▼
                           
        ┌──────────────────────────────────┐
        │ beforeInsert Trigger Fires        │
        └──────────────┬───────────────────┘
                       │
        ┌──────────────▼───────────────────┐
        │ TriggerFramework.execute()        │
        │ called with CaseTriggerHandler   │
        └──────────────┬───────────────────┘
                       │
        ┌──────────────▼───────────────────┐
        │ Step 1: Get handler key           │
        │ key = 'CaseTriggerHandler'       │
        └──────────────┬───────────────────┘
                       │
        ┌──────────────▼───────────────────┐
        │ Step 2: Check registry            │
        │ Is 'CaseTriggerHandler'           │
        │ already in map?                   │
        │                                  │
        │ registry.containsKey(key)?        │
        └──────────────┬───────────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
    YES ◄─┘                         └─► NO
          │                              │
      ┌───▼──────────────┐      ┌───────▼────────────┐
      │ Handler already   │      │ Handler NOT in     │
      │ registered!       │      │ registry yet       │
      │                  │      │                    │
      │ System.debug(...) │      │ Add to registry:   │
      │ return;           │      │ registry.put(key)  │
      │                  │      │                    │
      │ ✓ EXIT EARLY     │      │ ✓ CONTINUE        │
      └───┬──────────────┘      └───────┬────────────┘
          │                             │
          │                    ┌────────▼──────────────┐
          │                    │ Step 3: Check bypass   │
          │                    │ isBypassed(key)?      │
          │                    └────────┬──────────────┘
          │                             │
          │                    ┌────────▼──────────────┐
          │                    │ Step 4: Route to       │
          │                    │ handler method         │
          │                    │ beforeInsert()         │
          │                    │ Sets: Status='Resolved'│
          │                    └────────┬──────────────┘
          │                             │
          │               ┌─────────────▼──────────┐
          │               │ Record saved to DB     │
          │               └─────────────┬──────────┘
          │                             │
          │                    ┌────────▼──────────────┐
          │                    │ afterInsert fires      │
          │                    │ TriggerFramework.     │
          │                    │ execute() called again│
          │                    └────────┬──────────────┘
          │                             │
          │                    ┌────────▼──────────────┐
          │                    │ Check registry again  │
          │                    │ 'CaseTriggerHandler'  │
          │                    │ FOUND!                │
          │                    └────────┬──────────────┘
          │                             │
          └────────────────┬────────────┘
                           │
                    ▼▼▼▼▼▼▼▼▼▼▼
                           
        ┌──────────────────────────────────┐
        │ RESULT:                           │
        │ Handler executed in beforeInsert  │
        │ Handler SKIPPED in afterInsert    │
        │ No duplicate execution!           │
        │ No infinite recursion!            │
        └──────────────────────────────────┘
```

---

## 9. Summary: Protection Layers

| Protection Layer | Mechanism | Prevents |
|-----------------|-----------|----------|
| **Handler Registry** | Map of executed handlers | Duplicate execution same transaction |
| **Transaction Scope** | Static vars reset per txn | Unintended cross-transaction issues |
| **Guard Clause** | Early return in execute() | Wasted processing of known handlers |
| **Bypass Utility** | Manual on/off toggle | Forced execution when not wanted |
| **Context Tracking** | Stores trigger event info | Wrong code in wrong trigger event |
| **Test Isolation** | clearRegistry() between tests | Test contamination |

---

## 10. Interview Talking Points

**Q: How do you prevent duplicate trigger logic?**

A: We have a handler registry (Map<String, TriggerHandler>) that tracks registered handlers by key. When TriggerFramework.execute() is called, it checks if the handler is already in the registry. If found, it returns early without executing. This ensures each handler runs at most once per transaction.

**Q: What about recursion?**

A: Because of the registry, true infinite recursion is impossible - each handler can only execute once. Additionally, we provide TriggerBypassUtil for cases where you need manual control, and we encourage async jobs (Queueable/Batch) for complex scenarios that might otherwise recurse.

**Q: Can I run the same handler twice on purpose?**

A: For testing, yes - call TriggerFramework.clearRegistry() to reset. In production, if you need to process the same logic again, queue an async job (Queueable) or call a batch class. The framework by design prevents duplicate synchronous execution.

**Q: What if two different handlers update the same record?**

A: They can coexist! The registry is per handler, so CaseTriggerHandler and AccountTriggerHandler can both execute independently. Each runs once. They won't interfere with each other.

---

## Conclusion

Your trigger framework has **robust protection** against duplicates and recursion through:

1. ✅ **Handler Registry** - Prevents same handler from running twice
2. ✅ **Transaction Isolation** - Clean slate per transaction
3. ✅ **Bypass Utility** - Manual control when needed
4. ✅ **Context Tracking** - Know what trigger event you're in
5. ✅ **Test Isolation** - clearRegistry() between tests
6. ✅ **Governor Limits** - No excessive processing

This is **production-grade protection**! 🚀
