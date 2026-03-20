# Trigger Framework Architecture - Presentation Slides

## Slide 1: The Problem & Motivation

### Current State (Fragmented)
```
┌──────────────────────────────────────────────────────────────┐
│                    SALESFORCE ORG                             │
│                                                                │
│  ┌─────────────────────┐      ┌──────────────────────┐      │
│  │  Apex Triggers      │      │  Record-Triggered    │      │
│  │  - Field validation │      │  Flows               │      │
│  │  - Auto-populate    │      │  - Multi-step process│      │
│  │  - Status updates   │      │  - Notifications     │      │
│  │                     │      │  - Child updates     │      │
│  └──────────┬──────────┘      └──────────┬───────────┘      │
│             │                            │                   │
│             └────────────┬───────────────┘                   │
│                          ▼                                    │
│              ❌ DUPLICATE LOGIC                              │
│              ❌ UNPREDICTABLE ORDER                          │
│              ❌ DUPLICATE NOTIFICATIONS                      │
│              ❌ HARD TO MAINTAIN                             │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## Slide 2: Solution Architecture

### Framework Design
```
┌──────────────────────────────────────────────────────────────┐
│                    TRIGGER FRAMEWORK                          │
│                                                                │
│  ┌────────────────────────────────────────────────────┐      │
│  │ Trigger (thin dispatcher)                          │      │
│  │ → TriggerFramework.execute(new CaseTriggerHandler) │      │
│  └────────────────────┬───────────────────────────────┘      │
│                       │                                       │
│  ┌────────────────────▼───────────────────────────────┐      │
│  │      TriggerFramework                              │      │
│  │  ┌──────────────────────────────────────┐         │      │
│  │  │ 1. Check Handler Registry            │         │      │
│  │  │    (prevent duplicates)              │         │      │
│  │  └──────────────────────────────────────┘         │      │
│  │  ┌──────────────────────────────────────┐         │      │
│  │  │ 2. Capture Trigger Context           │         │      │
│  │  │    (before/after, old/new, size)     │         │      │
│  │  └──────────────────────────────────────┘         │      │
│  │  ┌──────────────────────────────────────┐         │      │
│  │  │ 3. Check Bypass Utility              │         │      │
│  │  │    (for data loads)                  │         │      │
│  │  └──────────────────────────────────────┘         │      │
│  │  ┌──────────────────────────────────────┐         │      │
│  │  │ 4. Route to Handler Method           │         │      │
│  │  │    beforeInsert? afterUpdate? etc.   │         │      │
│  │  └──────────────────────────────────────┘         │      │
│  └────────────────────┬───────────────────────────────┘      │
│                       │                                       │
│  ┌────────────────────▼───────────────────────────────┐      │
│  │ TriggerHandler Base Class (abstract)               │      │
│  │ ├─ CaseTriggerHandler                             │      │
│  │ │  └─ beforeInsert()  { business logic }          │      │
│  │ │     afterInsert()   { business logic }          │      │
│  │ │     beforeUpdate()  { business logic }          │      │
│  │ ├─ OpportunityTriggerHandler (future)             │      │
│  │ │  └─ beforeInsert()  { business logic }          │      │
│  │ └─ AccountTriggerHandler (future)                 │      │
│  │    └─ beforeInsert()  { business logic }          │      │
│  └────────────────────┬───────────────────────────────┘      │
│                       │                                       │
│              ✓ EXTENSIBLE:                                    │
│              Add new handler without touching trigger         │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## Slide 3: How It Works (Step by Step)

### Execution Flow Example: Case Insert

```
Step 1: DML Operation Triggered
┌─────────────────────┐
│ insert new Case     │
│ (Flight Disruption  │
│  Type = Cancellation)
└──────────┬──────────┘
           │
Step 2: Trigger Fires
┌──────────▼──────────────────────────────┐
│ trigger CaseTrigger on Case before insert│
│ {                                        │
│   TriggerFramework.execute(              │
│     new CaseTriggerHandler()             │
│   );                                     │
│ }                                        │
└──────────┬───────────────────────────────┘
           │
Step 3: Framework Processes
┌──────────▼─────────────────────────────────────┐
│ TriggerFramework.execute()                     │
│                                                 │
│ ✓ Register handler in map (prevent duplic)    │
│ ✓ Capture context (isBefore=true, etc)       │
│ ✓ Check bypass (is this bypassed? no)         │
│ ✓ Route to beforeInsert()                     │
└──────────┬─────────────────────────────────────┘
           │
Step 4: Handler Logic Executes
┌──────────▼──────────────────────────────────────┐
│ CaseTriggerHandler.beforeInsert()               │
│                                                  │
│ for (Case c : context.newList) {                │
│   if (c.Reason == 'Flight Disruption' &&       │
│       c.Type == 'Cancellation') {               │
│     c.Status = 'Resolved';        ◄─ SET FIELD │
│     c.Resolution__c = 'Refund';   ◄─ SET FIELD │
│   }                                             │
│ }                                               │
└──────────┬──────────────────────────────────────┘
           │
Step 5: Record Persisted
┌──────────▼──────────────────────────────────────┐
│ Case saved with:                                │
│ ✓ Status = 'Resolved'                          │
│ ✓ Resolution__c = 'Refund'                     │
│ ✓ All other required fields populated          │
└──────────┬──────────────────────────────────────┘
           │
Step 6: After Triggers & Flows
┌──────────▼──────────────────────────────────────┐
│ CaseTrigger after insert fires                  │
│ │                                                │
│ └─→ CaseTriggerHandler.afterInsert()            │
│     (e.g., publish event, queue jobs)           │
│                                                  │
│ Record-Triggered Flows fire                     │
│ (e.g., send notifications, update parent)      │
└───────────────────────────────────────────────────┘

RESULT: Record created with all validations,
        calculations, and downstream processes
        executed in predictable order ✓
```

---

## Slide 4: Adding New Business Rules (No Trigger Change!)

### Example: Add High-Priority Escalation Rule

**BEFORE (Traditional Approach):**
```apex
// Modify the trigger
trigger CaseTrigger on Case (before insert) {
    for (Case c : Trigger.new) {
        if (c.Reason == 'Flight Disruption' && c.Type == 'Cancellation') {
            c.Status = 'Resolved';
        }
        // NEW RULE: Need to modify trigger ❌
        if (c.Priority == 'High') {
            c.Escalated__c = true;
            c.EscalationDate__c = System.now();
        }
    }
}
```

**AFTER (Framework Approach):**
```apex
// Handler stays modular, trigger never changes ✓
public void beforeInsert(TriggerFramework.TriggerContext context) {
    for (Case c : context.newList) {
        // RULE 1: Auto-resolve Flight Disruption Cancellations
        if (isFlightDisruptionCancellation(c)) {
            c.Status = 'Resolved';
            c.Resolution__c = 'Refund';
        }
        
        // RULE 2: High-priority cases get escalated (NEW - just added!)
        if (shouldEscalate(c)) {
            c.Escalated__c = true;
            c.EscalationDate__c = System.now();
        }
        
        // RULE 3: VIP customers get premium SLA (easy to add later)
        if (isVIPCustomer(c.AccountId)) {
            c.SLA__c = 'Premium';
            c.ReplyWithin__c = 2; // hours
        }
    }
}
// Trigger file: NEVER MODIFIED ✓
// Framework file: NEVER MODIFIED ✓
// Just add to handler method
```

**The Difference:**
| Traditional | Framework |
|-------------|-----------|
| Modify trigger each time | Add to handler |
| Risk trigger logic complexity | Handler stays clean |
| Hard to test new rules | Easy to unit test |
| Potential for duplicates | Registry prevents duplicates |

---

## Slide 5: Flow Coexistence Strategy

### Clear Boundaries

```
┌──────────────────────────────────────────────────────────────┐
│                      EXECUTION TIMELINE                       │
│                                                                │
│  PHASE 1: BEFORE TRIGGERS (Synchronous, Same Transaction)   │
│  ┌─────────────────────────────────────────────┐             │
│  │ ✓ Apex beforeInsert/beforeUpdate            │             │
│  │   ├─ Validate fields                        │             │
│  │   ├─ Auto-calculate values                  │             │
│  │   └─ Prevent invalid states                 │             │
│  │                                             │             │
│  │ ❌ Flow (cannot run in before phase)        │             │
│  │ ❌ Notifications (data not persisted yet)  │             │
│  └──────────────────────┬──────────────────────┘             │
│                         │                                     │
│                    ▼ DML Executes ▼                           │
│                  Record saved to DB                           │
│                         │                                     │
│  PHASE 2: AFTER TRIGGERS (Synchronous, Same Transaction)    │
│  ┌──────────────────────┬────────────────────────┐           │
│  │ ✓ Apex afterInsert/  │  ✓ Publish Events      │           │
│  │   afterUpdate        │    (async-friendly)    │           │
│  │   ├─ Queue jobs      │  ✓ Send notifications  │           │
│  │   ├─ Publish events  │    (from events)       │           │
│  │   └─ Update related  │──────────────┬─────────│           │
│  │                      │              │         │           │
│  └──────────────────────┴───────────────┼─────────┘           │
│                                         │                     │
│  PHASE 3: RECORD-TRIGGERED FLOWS       │                    │
│  ┌────────────────────────────────────▼────────┐             │
│  │ ✓ Record-Triggered Flow                     │             │
│  │   ├─ Responds to record change              │             │
│  │   ├─ Can update same record (careful!)      │             │
│  │   ├─ Send notifications                     │             │
│  │   ├─ Call APIs                              │             │
│  │   └─ Update related records (safe)          │             │
│  └──────────────────────────────────────────────┘             │
│                                                                │
│  PHASE 4: ASYNCHRONOUS JOBS (After Everything)               │
│  ┌──────────────────────────────────────────────┐             │
│  │ ✓ Queueable/Batch Jobs                      │             │
│  │   ├─ Heavy processing                      │             │
│  │   ├─ External integrations                 │             │
│  │   └─ Complex multi-record updates          │             │
│  └──────────────────────────────────────────────┘             │
│                                                                │
└──────────────────────────────────────────────────────────────┘

KEY PRINCIPLE:
Apex owns BEFORE (validation/calculation)
Flows own AFTER (orchestration/notification)
→ No duplicate logic, predictable order
```

### Three Coexistence Patterns

```
PATTERN 1: APEX FIRST (Recommended)
├─ Apex beforeInsert calculates fields
├─ Record saved with computed values
└─ Flow detects changes and acts on them

PATTERN 2: EVENT DECOUPLING (Best Practice)
├─ Apex afterInsert publishes event
├─ Flow listens to event
└─ Flow acts independently (notifications, etc)

PATTERN 3: BYPASS FLAG (Mutual Exclusion)
├─ Apex checks: if NOT bypassed then process
├─ Flow checks: if bypassed then skip
└─ Only one layer processes (avoid duplication)
```

---

## Slide 6: Demo Code

### Live Demo: Case Flight Disruption

**Handler Code:**
```apex
public class CaseTriggerHandler extends TriggerHandler {
    @Override
    public String getHandlerKey() {
        return 'CaseTriggerHandler';
    }
    
    @Override
    public void beforeInsert(TriggerFramework.TriggerContext context) {
        for (Case c : context.newList) {
            // RULE: Flight Disruption Cancellations auto-resolve
            if (c.Reason == 'Flight Disruption' && c.Type == 'Cancellation') {
                c.Status = 'Resolved';
                c.Resolution__c = 'Refund';
            }
        }
    }
}
```

**Test Code:**
```apex
@isTest
static void testFlightDisruptionCancellationAutoResolve() {
    Case c = new Case(
        Subject = 'Flight Cancelled',
        Reason = 'Flight Disruption',
        Type = 'Cancellation',
        Status = 'New'
    );
    
    insert c;
    
    Case result = [SELECT Status, Resolution__c FROM Case WHERE Id = :c.Id];
    Assert.areEqual('Resolved', result.Status);
    Assert.areEqual('Refund', result.Resolution__c);
}
```

**Result:** ✓ PASSED - Record auto-resolved on insert

**Easy Extension:**
```apex
// Add new rule - no trigger modification!
private void addNewRule(Case c) {
    if (c.Priority == 'High') {
        c.EscalationComment__c = 'Auto-escalated due to high priority';
    }
}
```

---

## Slide 7: Scalability & Governance

### Multi-Object Support

```
Current Implementation:      Can Easily Extend To:
┌────────────────────────┐  ┌──────────────────────────────┐
│ CaseTrigger            │  │ AccountTrigger               │
│ CaseTriggerHandler     │  │ AccountTriggerHandler        │
│ (business rules)       │  │ (business rules)             │
└────────────────────────┘  │                              │
                            │ OpportunityTrigger           │
                            │ OpportunityTriggerHandler    │
                            │ (business rules)             │
                            │                              │
                            │ LeadTrigger                  │
                            │ LeadTriggerHandler           │
                            │ (business rules)             │
                            │                              │
                            │ ... n more objects           │
                            └──────────────────────────────┘

Framework Classes Reused:
├─ TriggerFramework.cls (same for all objects)
├─ TriggerHandler.cls (same for all objects)
├─ TriggerBypassUtil.cls (same for all objects)
└─ Each object gets 2 new files:
   ├─ {Object}TriggerHandler.cls
   └─ {Object}Trigger
```

### Governance & Cost

| Aspect | Benefit |
|--------|---------|
| **Code Organization** | Each handler owns its logic, easy to review |
| **Testing** | Unit test each handler independently |
| **Performance** | Registry prevents duplicate handler execution |
| **Maintenance** | Add rules without modifying trigger files |
| **Onboarding** | New devs understand pattern quickly |
| **Collaboration** | Multiple teams can add rules to same handler |

---

## Slide 8: Key Takeaways

### 1. **Lightweight Framework**
   - Just 4 core classes (~500 lines total)
   - Easy to understand, easy to extend
   - No external dependencies

### 2. **Prevents Duplicate Logic**
   - Registry ensures handler runs once per transaction
   - Bypass utility for data loads
   - No conflicting updates

### 3. **Extensible Without Changes**
   - Add new rules to handler
   - Add new objects (new handler + trigger, framework unchanged)
   - New rules don't break existing code

### 4. **Flow-Friendly**
   - Clear before/after boundary
   - Apex validates, Flows orchestrate
   - Event-driven communication

### 5. **Testable**
   - Unit test handlers independently
   - Mock trigger contexts
   - Clear assertions

### 6. **Scalable**
   - Works for 1 object, 100 objects, 1000 rules
   - Minimal overhead
   - Framework stays the same

---

## Slide 9: Q&A

### Common Questions

**Q: Won't this add overhead?**
A: Registry and bypass logic are negligible. Framework prevents duplicates, actually improves performance.

**Q: What if we need to modify trigger event order?**
A: TriggerFramework controls order. All handlers for before-insert run before persisting. Can add sequencing to framework if needed (future enhancement).

**Q: How do we handle batch jobs that bypass triggers?**
A: TriggerBypassUtil works in single transaction. For batch jobs, use Custom Metadata for persistent bypass.

**Q: Can Apex and Flows both update the same field?**
A: Avoid if possible. Use bypass flag pattern or let Apex set in beforeInsert (Flow respects that).

**Q: Is this enterprise-ready?**
A: Yes. Handles thousands of records, works with platform events, scales to many objects.

---

## Implementation Timeline

```
Phase 1: Framework Deployment (Week 1)
├─ Deploy core framework classes
├─ Set up Case example
└─ Run all tests (100% pass)

Phase 2: Documentation & Training (Week 1-2)
├─ Team training on framework
├─ Document existing Flows
└─ Create coexistence strategy for org

Phase 3: Migration (Ongoing)
├─ Refactor existing triggers (one at a time)
├─ Add new objects as needed
└─ Monitor performance

Phase 4: Optimization (Future)
├─ Custom Metadata for configuration
├─ Event-driven architecture
└─ Dependency injection
```
