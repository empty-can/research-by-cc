---
name: 5-Whys Root Cause Analysis
description: This skill should be used when the user asks to "find the root cause", "根本原因", "为什么会发生这件事", "why did this happen", "debug this issue", "分析原因", "analyze this bug", "分析这个bug", "what's causing this", "问题在哪", "dig deeper", "深挖原因", or needs to systematically trace a problem back to its fundamental cause rather than just addressing symptoms.
version: 0.1.0
---

# 5-Whys Root Cause Analysis

A systematic technique for drilling down through symptoms to uncover the true root cause of a problem by repeatedly asking "Why?" until the fundamental issue is revealed.

## When to Use This Skill

- Bug investigation where the obvious fix didn't work
- Production incidents requiring post-mortem analysis
- Performance problems with unclear origins
- Recurring issues that keep coming back after "fixes"
- System failures requiring prevention, not just recovery
- Any situation where treating symptoms isn't enough

## Core Process

### Phase 1: Define the Problem Clearly

State the problem as a specific, observable fact:

**Good problem statements:**
- "The API response time increased from 50ms to 500ms"
- "Users are seeing 500 errors on the checkout page"
- "The nightly job failed at 3:00 AM"

**Poor problem statements:**
- "The system is slow" (too vague)
- "Something is broken" (not specific)
- "Users are unhappy" (symptom, not problem)

**Problem Statement Template:**
```
What: [Specific observable behavior]
When: [Time/conditions when it occurs]
Where: [Component/system affected]
Impact: [Measurable consequence]
```

### Phase 2: Ask "Why?" Iteratively

For each answer, ask "Why does that happen?" until reaching an actionable root cause:

**The 5-Whys Chain:**
```
Problem: [Statement]
    ↓
Why 1: [First-level cause]
    ↓
Why 2: [Deeper cause]
    ↓
Why 3: [Even deeper]
    ↓
Why 4: [Approaching root]
    ↓
Why 5: [Root cause - actionable]
```

**Quality Checks for Each "Why":**
- Is this answer factual and verifiable?
- Does this explain the previous level?
- Is there evidence supporting this?
- Could there be multiple causes at this level?

### Phase 3: Identify the Root Cause

A true root cause has these characteristics:

| Characteristic | Test |
|----------------|------|
| **Actionable** | Can we do something about it? |
| **Preventable** | Would fixing this prevent recurrence? |
| **Fundamental** | Asking "why" again yields nothing actionable |
| **Verifiable** | Can we prove this is the cause? |

**Stop Conditions:**
- Reached a process/policy that can be changed
- Found a missing control or check
- Identified a knowledge/training gap
- Discovered a design flaw
- Hit a resource constraint decision

### Phase 4: Validate the Chain

Work backwards through the chain:

```
If [Root Cause] is fixed
↓ Then [Why 4] wouldn't happen
↓ Then [Why 3] wouldn't happen
↓ Then [Why 2] wouldn't happen
↓ Then [Why 1] wouldn't happen
↓ Then [Problem] wouldn't occur
```

If the chain breaks at any point, revisit that level.

### Phase 5: Define Countermeasures

For the root cause, define:

1. **Immediate fix** - Stop the bleeding
2. **Preventive measure** - Ensure it never happens again
3. **Detection mechanism** - Catch it early if prevention fails

## Output Format

```markdown
## 5-Whys Analysis: [Problem Title]

### Problem Statement
**What:** [Specific behavior]
**When:** [Time/conditions]
**Where:** [Component]
**Impact:** [Consequence]

### Why Chain

| Level | Question | Answer | Evidence |
|-------|----------|--------|----------|
| Why 1 | Why did [problem] occur? | [Answer] | [Evidence] |
| Why 2 | Why did [Why 1 answer]? | [Answer] | [Evidence] |
| Why 3 | Why did [Why 2 answer]? | [Answer] | [Evidence] |
| Why 4 | Why did [Why 3 answer]? | [Answer] | [Evidence] |
| Why 5 | Why did [Why 4 answer]? | [Answer] | [Evidence] |

### Root Cause
**Identified cause:** [Statement]
**Type:** [Process/Design/Knowledge/Resource]
**Confidence:** [High/Medium/Low]

### Validation
- [Root cause fixed] → [Why 4 prevented] ✓
- [Why 4 prevented] → [Why 3 prevented] ✓
- ... chain validates ...

### Countermeasures
| Type | Action | Owner | Timeline |
|------|--------|-------|----------|
| Immediate | [Action] | [Who] | [When] |
| Preventive | [Action] | [Who] | [When] |
| Detection | [Action] | [Who] | [When] |
```

## Common Pitfalls

### Pitfall 1: Stopping Too Early

**Symptom:** Root cause is still a symptom
```
Problem: Server crashed
Why 1: Out of memory
→ "Fix: Add more memory" ✗ (Treating symptom)

Continue:
Why 2: Memory leak in service X
Why 3: Connection pool not releasing connections
Why 4: Exception handler not closing connections
Why 5: No finally block in database code
→ Fix: Add proper resource cleanup ✓
```

### Pitfall 2: Blame Instead of Cause

**Wrong:** "Why? → Developer made a mistake"
**Right:** "Why? → No code review caught the issue"
**Even better:** "Why? → No automated test for this case"

**Rule:** Focus on process and systems, not individuals.

### Pitfall 3: Single Thread When Multiple Causes Exist

Sometimes problems have multiple contributing factors:

```
Problem: Deployment failed
    ↓
Why 1: Database migration timed out
    ├─→ Branch A: Why did migration take so long?
    │       └─→ Table lock held too long
    │               └─→ Long-running query
    │                       └─→ Missing index
    │
    └─→ Branch B: Why is timeout so short?
            └─→ Default timeout used
                    └─→ No deployment-specific config
```

### Pitfall 4: Unverified Assumptions

Each "why" should be supported by evidence:

| Level | Answer | Evidence Required |
|-------|--------|------------------|
| Why 1 | "Service crashed" | Logs showing crash |
| Why 2 | "OOM killed" | dmesg/system logs |
| Why 3 | "Memory leak" | Heap dump analysis |
| Why 4 | "Unclosed streams" | Code inspection |
| Why 5 | "Missing finally" | Git blame |

## Integration with Other Tools

| Tool | When to Combine |
|------|----------------|
| **First Principles** | When questioning if the problem definition itself is right |
| **Hypothesis Testing** | When evidence for a "why" is uncertain |
| **Pre-mortem** | After fixing, to prevent similar issues |
| **Trade-off Analysis** | When choosing between countermeasures |

## Boundaries

**Will:**
- Systematically trace problems to root causes
- Ensure each level is evidence-based
- Identify actionable countermeasures
- Handle multi-branch cause trees

**Will Not:**
- Stop at blame ("human error")
- Accept vague answers without evidence
- Guarantee exactly 5 levels (might be 3, might be 7)
- Replace detailed debugging when code inspection is needed

## Quick Reference

**The 5-Whys Checklist:**
- [ ] Problem stated specifically and measurably
- [ ] Each "why" is factual, not assumed
- [ ] Evidence supports each level
- [ ] Root cause is actionable and preventable
- [ ] Chain validates when traced backwards
- [ ] Countermeasures address root cause, not symptoms
- [ ] Process/system focus, not blame

## Additional Resources

### Reference Files
- **`references/toyota-origins.md`** - History and principles from Toyota Production System
- **`references/software-patterns.md`** - Common root cause patterns in software

### Example Files
- **`examples/production-incident.md`** - Complete analysis of a production outage
- **`examples/performance-regression.md`** - Tracing a performance degradation
