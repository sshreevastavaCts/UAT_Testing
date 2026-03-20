# Salesforce Trigger Framework & Flow Coexistence Strategy

## Executive Summary

This document presents a lightweight, scalable trigger framework designed to bring consistency and predictability to business logic execution in Salesforce, enabling Apex triggers and Record-Triggered Flows to coexist safely without conflicts.

---

## Part 1: Trigger Framework Architecture

### Design Philosophy

**Goal:** Create a thin, extensible framework that:
- Eliminates duplicate trigger logic
- Provides predictable execution order
- Allows selective bypass for data loads
- Scales easily to multiple objects
- Makes testing straightforward

### Core Components

#### 1. **TriggerFramework.cls** — Central Dispatcher
The main orchestrator that:
- Manages a handler registry to prevent duplicate handler execution
- Encapsulates trigger context (before/after, insert/update/delete, old/new data)
- Respects bypass logic
- Routes trigger events to appropriate handlers

**Key Features:**
```apex
// Single entry point for all triggers
TriggerFramework.execute(new CaseTriggerHandler());

// Handlers are registered and can only execute once per transaction
// Context is captured and passed to handlers
// Bypass logic is checked before execution
```

#### 2. **TriggerHandler.cls** — Abstract Base Class
Provides a standardized interface for object-specific handlers:
- `beforeInsert()`, `afterInsert()`
- `beforeUpdate()`, `afterUpdate()`
- `beforeDelete()`, `afterDelete()`
- `afterUndelete()`

Each handler extends this class and overrides only the methods it needs.

#### 3. **CaseTriggerHandler.cls** — Example Implementation
Demonstrates the framework with practical business logic:
- Auto-resolves Flight Disruption Cancellation cases with "Refund" status
- Shows how to add new rules without touching the trigger
- Validates status transitions
- Logs case creation events

**Example Business Rule:**
```
IF Case.Reason = "Flight Disruption" AND Case.Type = "Cancellation"
THEN Set Case.Status = "Resolved" AND Case.Resolution__c = "Refund"
```

#### 4. **TriggerBypassUtil.cls** — Bypass Management
Allows selective disabling of trigger logic for specific scenarios:
- Data loads (bulk imports)
- System backfills
- Integration scripts
- Admin-initiated updates

**Usage:**
```apex
// During data load
TriggerBypassUtil.bypass('CaseTriggerHandler');
// ... insert/update 10k records ...
TriggerBypassUtil.clearBypass('CaseTriggerHandler');
```

#### 5. **CaseTrigger.trigger** — Thin Trigger
The trigger itself becomes one line of delegation:
```apex
trigger CaseTrigger on Case (before insert, before update, ...) {
    TriggerFramework.execute(new CaseTriggerHandler());
}
```

### Execution Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│ Trigger Event (Case beforeInsert)                   │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│ TriggerFramework.execute(handler)                   │
├─────────────────────────────────────────────────────┤
│ 1. Check handler registry (prevent duplicates)      │
│ 2. Register handler in map                          │
│ 3. Capture trigger context                          │
│ 4. Check bypass utility                             │
│ 5. Route to appropriate handler method              │
└────────────────────┬────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │ (if not bypassed)       │
        ▼                         ▼
    Handler executes    Trigger is skipped
    business logic      (no exception)
```

### Supported Objects & Extensibility

**Current Implementation:**
- Case (with example business rules)

**Adding a New Object (e.g., Opportunity):**

1. Create `OpportunityTriggerHandler.cls`:
```apex
public class OpportunityTriggerHandler extends TriggerHandler {
    @Override
    public String getHandlerKey() {
        return 'OpportunityTriggerHandler';
    }
    
    @Override
    public void beforeInsert(TriggerFramework.TriggerContext context) {
        // Business logic here
    }
}
```

2. Create the trigger:
```apex
trigger OpportunityTrigger on Opportunity (before insert, after insert, ...) {
    TriggerFramework.execute(new OpportunityTriggerHandler());
}
```

3. Add business rules to the handler — **no trigger modification needed**.

---

## Part 2: Flow Coexistence Strategy

### The Problem

In existing Salesforce systems, business logic gets fragmented:
- **Triggers handle:** Field validations, before-save logic, after-insert notifications
- **Flows handle:** Complex multi-step processes, notifications, record updates
- **Result:** Duplicate notifications, conflicting updates, unpredictable execution order

### Solution: Clear Boundaries & Communication Pattern

#### **Principle 1: Logic Segregation**

| Logic Type | Apex Trigger | Record-Triggered Flow |
|------------|-------------|----------------------|
| **Field validation** | ✓ (beforeInsert/beforeUpdate) | ✗ |
| **Calculate/auto-populate** | ✓ (beforeInsert/beforeUpdate) | ✗ |
| **Prevent invalid states** | ✓ (beforeInsert/beforeUpdate) | ✗ |
| **Send notifications** | ✗ (use platform events) | ✓ |
| **Complex workflows** | ✗ (use async/batch jobs) | ✓ |
| **Multi-record updates** | ✗ (use async/batch jobs) | ✓ |
| **External integrations** | (Queueable jobs) | (Flow actions) |

**Rule:** Flows should **NOT** perform field validations or before-save calculations. Apex triggers own the before-save layer.

#### **Principle 2: Naming Conventions**

Establish clear naming patterns to indicate logic ownership:

```
Case Record-Triggered Flow naming:
- Case_BeforeInsert → Reserved for framework registration/triggers
- Case_OnCreation → Business flow triggered AFTER insert
- Case_StatusChanged → Business flow triggered AFTER update
- Case_NotifyTeamOnEscalation → Specific notification flow

Custom Field naming:
- Bypass__c fields → For programmatic bypass (e.g., BypassFlows__c)
- ProcessingFlag__c → Indicates whether logic has already run

Platform Event naming:
- CaseCreated__e → "A Case was created successfully"
- CaseStatusChanged__e → "A Case status changed"
```

#### **Principle 3: Avoid Duplicate Updates**

**Problem Scenario:**
```
Apex Trigger sets Case.Status = "Resolved"
Flow detects status change and updates Case.Priority
→ Double database update, potential conflicts
```

**Solution Pattern:**

**Option A - "Apex First" (Recommended for validations):**
```apex
// CaseTriggerHandler.beforeInsert()
if (shouldAutoResolve(c)) {
    c.Status = 'Resolved';
    c.Resolution__c = 'Refund';
    // Flow will NOT re-run because we're in beforeInsert
}
```

**Option B - "Platform Event Communication" (For complex workflows):**
```apex
// CaseTriggerHandler.afterInsert()
// Publish event when important business event occurs
EventBus.publish(new CaseCreated__e(
    CaseId__c = c.Id,
    Reason__c = c.Reason,
    Type__c = c.Type
));

// Flow subscribes to CaseCreated__e event
// Flow controls what happens next (notifications, workflow)
```

**Option C - "Bypass Flag" (For mutual exclusion):**
```apex
// Apex checks if flow should run
if (!c.BypassAutoResolve__c) {
    c.Status = 'Resolved';
}

// Flow checks if apex already handled it
IF $Record.BypassAutoResolve = true THEN skip flow actions
```

#### **Principle 4: Entry/Exit Checks**

**Entry Check - "Did something already process this record?"**
```apex
// In Apex Handler
if (record.AlreadyProcessed__c) return;

// In Flow
If $Record.AlreadyProcessed == true
  Then exit flow
```

**Exit Check - "I just made a change, is another system watching?"**
```apex
// After making changes in Apex
// Log what was changed for Flow to detect
Case c = new Case(Id = caseId, LastModifiedReason__c = 'AutoResolved');
update c;
// Flow watches for this field and responds accordingly

// In Flow: Trigger on field change of LastModifiedReason__c
```

#### **Principle 5: Execution Order Guarantee**

Since Record-Triggered Flows run AFTER triggers, establish this contract:

```
Timeline:
1. Before-Insert Trigger → Apex validates, sets fields
2. Record saved to database
3. Before-Update Trigger → Apex validates changes
4. Record saved to database
5. After-Insert/Update Trigger → Apex publishes events, queues async work
6. Record-Triggered Flow → Flow responds to events/changes
```

**In Practice:**
- Apex owns the synchronous logic (validation, field calculation)
- Flows own the downstream orchestration (notifications, workflow)
- Events bridge the gap (async, decoupled)

---

## Part 3: Implementation Guide

### Adding a New Business Rule (No Trigger Modification!)

**Step 1: Add to Handler**
```apex
// CaseTriggerHandler.beforeInsert()
if (isFlightDisruptionCancellation(c)) {
    c.Resolution__c = REFUND_RESOLUTION;
    c.Status = 'Resolved';
}

// NEW RULE: If case has multiple complaints, escalate
if (hasMultipleComplaints(c)) {
    c.Priority = 'High';
    c.EscalationComment__c = 'Auto-escalated due to multiple complaints';
}
```

**Step 2: Add Matching Flow (if needed)**
- Create Flow: `Case_OnHighPriorityCreation`
- Trigger: Record-Triggered, when Priority = 'High'
- Actions: Notify supervisor, assign to escalation queue, etc.

**Step 3: Test**
```apex
@isTest
static void testMultipleComplaintsEscalation() {
    Case c = new Case(
        Reason = 'Flight Disruption',
        Type = 'Cancellation',
        ComplaintCount__c = 3
    );
    insert c;
    
    Case result = [SELECT Priority FROM Case WHERE Id = :c.Id];
    Assert.areEqual('High', result.Priority);
}
```

**That's it!** The trigger itself never changes.

---

## Part 4: Avoiding Common Pitfalls

### ❌ Don't Do This:

```apex
// BAD: Putting field updates in afterInsert that should be in beforeInsert
public void afterInsert(TriggerContext ctx) {
    List<Case> toUpdate = new List<Case>();
    for (Case c : ctx.newList) {
        if (shouldAutoResolve(c)) {
            c.Status = 'Resolved';
            toUpdate.add(c);
        }
    }
    update toUpdate;  // ❌ Causes extra database transaction
}
```

### ✓ Do This Instead:

```apex
// GOOD: Do it beforeInsert (no extra DML)
public void beforeInsert(TriggerContext ctx) {
    for (Case c : ctx.newList) {
        if (shouldAutoResolve(c)) {
            c.Status = 'Resolved';  // ✓ Happens before first insert
        }
    }
}
```

### ❌ Don't:

```apex
// BAD: Flow and Apex both sending notifications
// CaseTriggerHandler.afterInsert publishes CaseCreated event
// Flow also sends email to same people
// → Duplicate notifications
```

### ✓ Do:

```apex
// GOOD: Let Apex publish the event, Flow handles notification
// CaseTriggerHandler.afterInsert
EventBus.publish(new CaseCreated__e(...));

// Case_OnCreation Flow
Receives: CaseCreated event
Actions: Send email (single source of truth)
```

### ❌ Don't:

```apex
// BAD: Hardcoded configuration in handler
public void beforeInsert(TriggerContext ctx) {
    if (c.Reason == 'Flight Disruption' && c.Type == 'Cancellation') {
        c.Resolution__c = 'Refund';
    }
    // If business rules change, code change required
}
```

### ✓ Do:

```apex
// GOOD: Externalized configuration (Custom Metadata or Settings)
private static final String FLIGHT_DISRUPTION = 'Flight Disruption';
private static final String CANCELLATION = 'Cancellation';
private static final String REFUND = 'Refund';
// Or query from Custom Metadata

if (c.Reason == FLIGHT_DISRUPTION && c.Type == CANCELLATION) {
    c.Resolution__c = REFUND;
}
// Business analyst can change values without code
```

---

## Part 5: Testing & Quality Assurance

### Unit Tests

```apex
@isTest
private class CaseTriggerHandlerTest {
    
    @isTest
    static void testFlightDisruptionCancellationAutoResolve() {
        Case c = new Case(
            Reason = 'Flight Disruption',
            Type = 'Cancellation'
        );
        insert c;
        
        Case result = [SELECT Status, Resolution__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual('Resolved', result.Status);
        Assert.areEqual('Refund', result.Resolution__c);
    }
}
```

### Integration Tests

```apex
@isTest
static void testApexTriggersAndFlowsCoexist() {
    // Create record
    Case c = new Case(Reason = 'Flight Disruption', Type = 'Cancellation');
    insert c;
    
    // Verify Apex trigger set fields
    Case afterApex = [SELECT Status, Resolution__c FROM Case WHERE Id = :c.Id];
    Assert.areEqual('Resolved', afterApex.Status);
    
    // (Flow would run here and do its thing)
    // (Manually verify Flow execution in Flow Manager)
}
```

---

## Part 6: Deployment Checklist

- [ ] Deploy TriggerFramework.cls
- [ ] Deploy TriggerHandler.cls
- [ ] Deploy TriggerBypassUtil.cls
- [ ] Deploy CaseTriggerHandler.cls
- [ ] Deploy CaseTrigger.trigger
- [ ] Run all tests (minimum 80% coverage)
- [ ] Document existing flows and their responsibilities
- [ ] Update/create Flow coexistence documentation
- [ ] Train team on framework usage
- [ ] Refactor existing single-object triggers to use framework (optional, iterative)

---

## Part 7: Assumptions & Trade-offs

### Assumptions
1. **Salesforce Standard/Professional Edition or higher** (supports before-triggers and platform events)
2. **Development/QA environments available** for testing framework changes
3. **Team is familiar with Apex and Flows** (not an intro course)
4. **Custom objects and metadata can be created** as needed for configuration

### Trade-offs

| Decision | Benefit | Cost |
|----------|---------|------|
| **Lightweight framework (single class)** | Easy to understand, minimal overhead | Less feature-rich than some third-party frameworks |
| **Static bypass map (in-transaction)** | Simple implementation | Only works within single transaction; doesn't survive batch jobs |
| **Flows handle downstream logic** | Clear separation, easier testing | Requires Flow expertise, Flow limits |
| **Platform Events for decoupling** | Prevents tight coupling | Eventual consistency (not instant) |

### Future Enhancements

1. **Custom Metadata for Configuration** — Move business rules to CMT for no-code updates
2. **Queueable Async Jobs** — For heavy processing (integrate with Apex jobs framework)
3. **Event-Driven Architecture** — Publish/subscribe pattern for true microservices feel
4. **Batch Bypass Persistence** — Use Custom Metadata instead of static map for batch jobs
5. **Dependency Injection** — Add handler factory for testing and flexibility

---

## Conclusion

This framework provides a **scalable, testable, and maintainable** approach to trigger management while enabling safe coexistence with Flows. The key lies in:

1. **Clear separation of concerns** (Apex validates, Flows orchestrate)
2. **Predictable execution order** (framework-managed)
3. **Extensibility without trigger changes** (add handlers, not trigger code)
4. **Safe bypass for data loads** (TriggerBypassUtil)

The framework grows with you — add new objects, create new handlers, and define new flows without ever touching the framework code again.
