---
title: AAP Deployment Governance Patterns
category: aap
sources:
  - title: "Ansible Automation Controller Best Practices"
    url: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/assembly-controller-best-practices
    sections: "Best practices for inventories, credentials, job templates"
    date_accessed: 2026-02-22
  - title: "Red Hat AAP Controller User Guide - Inventories"
    url: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-inventories
    sections: "Inventory management, groups, host patterns"
    date_accessed: 2026-02-22
tags: [governance, deployment, safety, inventory, production, risk-assessment]
applies_to: [aap2.5, aap2.6]
semantic_keywords:
  - deployment governance
  - production safety
  - inventory risk classification
  - change control
  - deployment approval
  - phased rollout
  - blast radius control
  - canary deployment
use_cases:
  - governance_deployment
  - inventory_risk_classification
  - phased_rollout
  - production_safety
related_docs:
  - aap/job-launching-best-practices.md
  - references/error-classification.md
last_updated: 2026-02-22
---

# AAP Deployment Governance Patterns

## Overview

Deployment governance ensures that automation jobs are executed safely, with appropriate controls for target scope, execution mode, and approval. This document defines the governance patterns that differentiate an intelligent automation agent from a blind execution engine.

## When to Use This

- When processing any deployment request targeting production or sensitive environments
- When establishing governance workflows for AAP job launches
- When classifying inventory risk levels
- When determining phased rollout strategies

## Inventory Risk Classification

### Risk Level Determination

Classify inventory risk based on naming conventions and metadata:

| Risk Level | Inventory Name Patterns | Governance Requirements |
|-----------|------------------------|------------------------|
| **CRITICAL** | `prod`, `production`, `pci`, `hipaa`, `financial`, `secure` | Check mode mandatory, limit required, approval chain |
| **HIGH** | `staging`, `pre-prod`, `uat`, `qa-prod` | Check mode recommended, limit suggested |
| **MEDIUM** | `qa`, `test`, `integration`, `perf` | Check mode optional |
| **LOW** | `dev`, `development`, `sandbox`, `lab`, `demo` | No governance required |

### Detection Logic

```python
HIGH_RISK_PATTERNS = [
    "prod", "production", "pci", "hipaa", "financial",
    "secure", "compliance", "regulated", "critical"
]

MEDIUM_RISK_PATTERNS = [
    "staging", "pre-prod", "preprod", "uat", "qa-prod"
]

def classify_inventory_risk(inventory_name):
    name_lower = inventory_name.lower()
    for pattern in HIGH_RISK_PATTERNS:
        if pattern in name_lower:
            return "CRITICAL"
    for pattern in MEDIUM_RISK_PATTERNS:
        if pattern in name_lower:
            return "HIGH"
    if any(p in name_lower for p in ["qa", "test", "integration"]):
        return "MEDIUM"
    return "LOW"
```

### Risk-Based Governance Response

**CRITICAL Risk**:
```
⚠️ HIGH-RISK DEPLOYMENT DETECTED

Target inventory: "Production-US-East" (Risk: CRITICAL)

Required governance steps:
1. ✅ Check Mode execution first (mandatory)
2. ✅ Limit to subset of hosts (mandatory)
3. ✅ Extra variables sanitization (mandatory)
4. ✅ Explicit user approval (mandatory)

Recommended:
- Start with limit: "us-east[0:1]" (first 2 hosts)
- Schedule maintenance window
- Notify change management

Shall I proceed with Check Mode on a limited subset first?
```

**HIGH Risk**:
```
⚠️ Sensitive environment detected

Target inventory: "Staging-Global" (Risk: HIGH)

Recommended governance steps:
1. ✅ Check Mode execution first (recommended)
2. ✅ Limit to subset of hosts (recommended)
3. ✅ Extra variables sanitization (mandatory)

Shall I run in Check Mode first?
```

**MEDIUM/LOW Risk**:
```
Target inventory: "Dev-Lab" (Risk: LOW)

Proceeding with standard execution.
No additional governance required.
```

## Governance Workflow

### Phase 1: Pre-Flight Validation

Before any job launch:

1. **Resolve Job Template**: Search and retrieve the target job template
2. **Resolve Inventory**: Identify target inventory, classify risk level
3. **Scan Variables**: Check extra_vars for plain-text secrets
4. **Assess Scope**: Count target hosts, evaluate blast radius

### Phase 2: Governance Decision

Based on risk assessment, determine execution strategy:

```
IF risk == CRITICAL:
    REQUIRE check_mode = true
    REQUIRE limit = subset
    REQUIRE user_approval = explicit
    RECOMMEND maintenance_window
ELIF risk == HIGH:
    RECOMMEND check_mode = true
    RECOMMEND limit = subset
    REQUIRE user_approval = explicit
ELIF risk == MEDIUM:
    SUGGEST check_mode = true
    SUGGEST limit = subset
ELSE:
    PROCEED with standard execution
```

### Phase 3: Check Mode Execution

Execute in check mode and analyze results:

1. **Launch**: `job_type: "check"`, `limit: "<subset>"`
2. **Monitor**: Poll job status until completion
3. **Analyze**: Extract changed/failed events
4. **Report**: Present dry-run summary to user
5. **Decide**: Ask user to approve, modify, or abort

### Phase 4: Full Execution

After check mode approval:

1. **Launch**: `job_type: "run"`, same parameters
2. **Monitor**: Poll job status, track progress
3. **Summarize**: Show only Changed tasks (noise reduction)
4. **Verify**: Confirm expected changes were applied

### Phase 5: Rollout Expansion (Optional)

For phased rollouts:

1. **Expand limit**: Next host group or percentage
2. **Repeat Phase 3-4**: Check mode → approval → execution
3. **Track progress**: Cumulative success/failure across phases
4. **Complete**: Remove limit for final full deployment

## Phased Rollout Strategies

### Strategy 1: Canary (Single Host First)

```
Phase 1: limit: "webservers[0]"    → 1 host (canary)
Phase 2: limit: "webservers[0:4]"  → 5 hosts (small batch)
Phase 3: limit: "webservers"       → All hosts (full rollout)
```

### Strategy 2: Geographic (Region by Region)

```
Phase 1: limit: "us-east"          → US East region
Phase 2: limit: "us-west"          → US West region
Phase 3: limit: "eu-west"          → EU West region
Phase 4: limit: "ap-southeast"     → Asia Pacific
```

### Strategy 3: Environment Ladder

```
Phase 1: Inventory: "Dev"          → Development
Phase 2: Inventory: "Staging"      → Staging
Phase 3: Inventory: "Production"   → Production
```

## Approval Patterns

### For Automated Agents

The agent MUST obtain explicit user confirmation at these points:

1. **Before Check Mode**: "I'll run this in Check Mode first on [subset]. Proceed?"
2. **After Check Mode**: "Dry run shows [N] changes on [M] hosts. See details above. Proceed with full execution?"
3. **Before Full Execution**: "Launching full execution against [inventory] with limit [scope]. Confirm?"
4. **Before Rollout Expansion**: "Phase 1 succeeded on [N] hosts. Expand to [next group]?"

### Approval Language

Accept only unambiguous approval:
- **Approved**: "yes", "proceed", "confirm", "go ahead", "approved", "execute"
- **Declined**: "no", "stop", "abort", "cancel", "wait", "hold"
- **Modify**: "change limit", "add hosts", "modify", "adjust"

## Related Documentation

- [Job Launching Best Practices](job-launching-best-practices.md) - Check mode, limit, extra_vars details
- [Error Classification](../references/error-classification.md) - Post-execution error analysis
- [Troubleshooting Jobs](troubleshooting-jobs.md) - When governance-launched jobs fail

## Quick Reference

| Governance Check | CRITICAL | HIGH | MEDIUM | LOW |
|-----------------|----------|------|--------|-----|
| Check Mode | Required | Recommended | Suggested | Optional |
| Limit Subset | Required | Recommended | Suggested | Optional |
| Secret Scan | Required | Required | Required | Optional |
| User Approval | Required | Required | Optional | None |
| Maintenance Window | Recommended | Optional | None | None |
| Phased Rollout | Recommended | Optional | None | None |
