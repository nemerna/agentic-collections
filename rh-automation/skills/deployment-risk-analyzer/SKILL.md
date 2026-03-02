---
name: deployment-risk-analyzer
description: |
  Analyze deployment risk by classifying inventory, scanning extra_vars for secrets, and assessing scope.

  Use when:
  - "Deploy to production" (as first step before launch)
  - "Is this deployment safe?"
  - "Check deployment risk"
  - "Validate the deployment target"

  NOT for: launching jobs (use governed-job-launcher) or troubleshooting failures (use job-failure-analyzer).
model: inherit
color: yellow
---

# Deployment Risk Analyzer

## Prerequisites

**Required MCP Servers**:
- `aap-mcp-job-management` - Job template lookup and launch parameter inspection
- `aap-mcp-inventory-management` - Inventory and host data

**Verification**: Run the `aap-mcp-validator` skill with these 2 servers before proceeding.

## When to Use This Skill

Use this skill when:
- User requests a deployment to any environment
- Before any job template launch (as part of governance-deployer agent workflow)
- User asks to check if a deployment is safe
- User asks to validate deployment parameters

Do NOT use when:
- Actually launching the job (use `governed-job-launcher` skill after this skill)
- Troubleshooting a failed job (use `job-failure-analyzer` skill)
- Assessing platform governance (use `governance-readiness-assessor` skill)

## Workflow

### Step 1: Consult Deployment Governance Documentation

**CRITICAL**: Document consultation MUST happen BEFORE any MCP tool invocations.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [deployment-governance.md](../../docs/aap/deployment-governance.md) using the Read tool to understand inventory risk classification, extra_vars safety scanning, and governance controls
2. **Output to user**: "I consulted [deployment-governance.md](docs/aap/deployment-governance.md) which cites Red Hat's Security Best Practices and Job Templates documentation for deployment governance controls."

### Step 2: Identify the Job Template

**MCP Tool**: `job_templates_list` (from aap-mcp-job-management)
**Parameters**:
- `search`: `"<template_name_from_user_request>"`
- `page_size`: `10`

If the user provides a template ID directly:

**MCP Tool**: `job_templates_retrieve` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<template_id>"`

### Step 3: Inspect Launch Parameters

**MCP Tool**: `job_templates_launch_retrieve` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<template_id>"`

This returns the template's expected extra_vars, defaults, required fields, and inventory configuration.

### Step 4: Classify Inventory Risk

**MCP Tool**: `inventories_list` (from aap-mcp-inventory-management)
**Parameters**:
- `page_size`: `100`

Identify the target inventory from the job template configuration or user-provided override. Apply the risk classification from deployment-governance.md:

| Inventory Name Pattern | Risk Level | Governance Required |
|---|---|---|
| Contains `prod`, `production`, `live` | **CRITICAL** | Check mode + approval + phased rollout recommended |
| Contains `stage`, `staging`, `uat`, `preprod` | **HIGH** | Check mode + approval |
| Contains `test`, `qa` | **MEDIUM** | Confirmation only |
| Contains `dev`, `development`, `sandbox`, `lab` | **LOW** | Direct execution permitted |

For unclassifiable inventories, check host count:

**MCP Tool**: `hosts_list` (from aap-mcp-inventory-management)
**Parameters**:
- `search`: `"<inventory_name>"`
- `page_size`: `1`

**Transparency note**: Per deployment-governance.md, inventory risk classification is this agent's implementation of Red Hat's recommendation to "use separate inventories for production and development environments" (Controller Best Practices).

### Step 5: Scan Extra Vars for Secrets

Inspect the extra_vars that would be passed to the job. Check both:
1. Default extra_vars from the template (from Step 3)
2. User-provided extra_vars overrides

**Secret detection** (per deployment-governance.md):
- Key names containing (case-insensitive): `password`, `secret`, `token`, `api_key`, `apikey`, `private_key`, `ssh_key`, `access_key`, `auth`
- Values that look like tokens: long alphanumeric strings, base64, prefixes like `sk-`, `ghp_`, `Bearer`

**Transparency note**: Per deployment-governance.md, secret scanning implements Red Hat's recommendation to "Remove user access to credentials" (Ch. 15, Sec. 15.1.4) by detecting plain-text secrets in extra_vars that should be managed via AAP credentials.

### Step 6: Generate Risk Report

**Output format**:

```
## Deployment Risk Analysis

**Job Template**: [name] (ID: [id])
**Target Inventory**: [name]
**Risk Level**: [CRITICAL / HIGH / MEDIUM / LOW]

### Risk Classification

Per Red Hat's *Controller Best Practices*: "Use separate inventories for production and development environments."

**Inventory signal**: [name pattern match or host count]
**Risk level**: [CRITICAL/HIGH/MEDIUM/LOW]
**Governance required**: [check mode + approval / confirmation only / direct execution]

### Extra Vars Safety Scan

Per Red Hat's *Security Best Practices* (Ch. 15, Sec. 15.1.4): "Remove user access to credentials."

| Check | Status | Detail |
|---|---|---|
| Secret-like key names | [PASS/FAIL] | [findings] |
| Plain-text values | [PASS/FAIL] | [findings] |

### Recommendation

[Based on risk level, what governance controls should be applied before launching]
```

**If secrets are found**: BLOCK the deployment and recommend using AAP credentials instead.

**If CRITICAL/HIGH risk**: Recommend check mode execution before full run.

**If LOW risk**: Approve for direct execution with user confirmation.

## Dependencies

### Required MCP Servers
- `aap-mcp-job-management` - Job template data
- `aap-mcp-inventory-management` - Inventory and host data

### Required MCP Tools
- `job_templates_list` (from job-management) - Find template by name
- `job_templates_retrieve` (from job-management) - Get template details
- `job_templates_launch_retrieve` (from job-management) - Get launch parameters
- `inventories_list` (from inventory-management) - List inventories
- `hosts_list` (from inventory-management) - Host count for unclassifiable inventories

### Related Skills
- `aap-mcp-validator` - Prerequisite validation
- `governed-job-launcher` - Next step after risk analysis passes
- `execution-summary` - Audit trail

### Reference Documentation
- [deployment-governance.md](../../docs/aap/deployment-governance.md) - Risk classification and safety scanning reference

## Example Usage

**User**: "Deploy the security patch to production"

**Agent**:
1. Reads deployment-governance.md
2. Reports: "I consulted deployment-governance.md which cites Red Hat's Security Best Practices and Controller Best Practices."
3. Finds "Deploy Security Patch" template via `job_templates_list`
4. Inspects launch parameters via `job_templates_launch_retrieve`
5. Identifies "Production" inventory → CRITICAL risk
6. Scans extra_vars → no secrets found
7. Reports: "Risk Level: CRITICAL. Per Red Hat's Controller Best Practices, production inventories require check mode, approval, and phased rollout."
