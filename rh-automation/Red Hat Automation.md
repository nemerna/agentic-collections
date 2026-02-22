# Red Hat Automation Specification Lead

## Description

This builds on the core Ansible value proposition but adds an intelligent layer for enforcing best practices. An agent could act as a proactive guide, validating that playbooks are using efficient, built-in Ansible modules instead of fragile shell commands. It could also handle sensitive, repetitive common tasks like rotating credentials on RHEL servers, ensuring these critical operations are done securely and consistently without manual intervention. This elevates Ansible from an execution engine to an intelligent automation partner.

## Target Marketplaces

- Claude Code
- Cursor

## Connected MCPs

- [Red Hat AAP MCP Server](https://docs.google.com/document/d/1Rw_4LcawxxmZG4MQ6WS42AEcSSaYPk4U9SHEstnepcg/edit?tab=t.5xk0lc8690vn#heading=h.3nm84e2fkdab)
  - `aap-mcp-job-management` - Job templates, launches, events, status
  - `aap-mcp-inventory-management` - Inventories, hosts, groups, facts

## Example Prompts

**Governance & Safety (The "Gatekeeper")**

* *"I need to push the latest 'Web-App-v2' release to the Production inventory immediately."*
  * *(Triggers: Production warnings, Check Mode suggestion, Limit enforcement)*

**Forensic Troubleshooting (The "Analyst")**

* *"Job #4451 failed halfway through. Analyze the logs and tell me if it was a script error or if the host was just unreachable."*
  * *(Triggers: Log parsing, Event filtering, Host fact checking)*

**Best Practices & Development (The "Curator")** *(Use Case 4 - Future)*

* *"Write a playbook task to install Nginx and start the service using `shell` commands."*
  * *(Triggers: Anti-pattern detection, Recommendation of `redhat.rhel_system_roles`)*

## Implemented Use Cases

### Use Case 1: The "Governance-First" Deployment

**Short Description:** Instead of blindly launching a job when asked, the agent acts as a Change Control gatekeeper. It verifies the target inventory, enforces "Check Mode" (Dry Run) first, and validates that the user isn't overriding critical variables insecurely.

**Agent**: `governance-deployer` (agents/governance-deployer.md)

**Workflow:**

* **Intent Analysis:** User asks, "Deploy the new Web App version to Production."
* **Safety Checks** (deployment-safety-checker skill):
  * **Inventory Validation:** Agent confirms `production` inventory is used but asks user to confirm the `limit` (e.g., "Do you want to limit this to the `us-east` group first?").
  * **Variable Sanitization:** Agent scans `extra_vars` for plain-text passwords. If found, it aborts and demands the use of an **AAP Credential**.
* **Dry Run** (governance-launcher skill):
  * Agent offers: "I recommend running this in **Check Mode** first to see what will change. Shall I proceed with the dry run?"
* **Execution** (governance-launcher skill):
  * Only after confirmation, the agent launches the job.
* **Post-Validation** (governance-launcher skill):
  * Agent checks the job status and summarizes *only* the "Changed" tasks, ignoring the "OK" ones (reducing noise).

**Skills:**

| Skill | Purpose |
|-------|---------|
| `mcp-aap-validator` | Validate AAP MCP server connectivity |
| `deployment-safety-checker` | Inventory risk classification, secret scanning, scope assessment |
| `governance-launcher` | Check mode execution, dry-run analysis, governed execution, changed-only summary |

**Skill Abilities:**

* Differentiate between `Check Mode` and `Run Mode`.
* Identify "High Risk" keywords in inventories (e.g., `prod`, `pci`, `secure`).
* Enforce the "No Plain-Text Secrets" rule proactively.

**AAP MCP Tools:**

* `job_templates_list` (from aap-mcp-job-management)
* `job_templates_retrieve` (from aap-mcp-job-management)
* `job_templates_launch_retrieve` (from aap-mcp-job-management)
* `jobs_retrieve` (from aap-mcp-job-management)
* `jobs_job_events_list` (from aap-mcp-job-management)
* `inventories_retrieve` (from aap-mcp-inventory-management)
* `hosts_list` (from aap-mcp-inventory-management)

**Docs:**

* [Red Hat AAP Controller User Guide - Launching Jobs](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-job-templates#launching-job-templates)
* [Ansible Playbook Best Practices (Check Mode)](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/assembly-controller-best-practices)

**Embedded Documentation:**
* `docs/aap/job-launching-best-practices.md` - Check mode, limit, extra_vars, post-execution analysis
* `docs/aap/deployment-governance.md` - Inventory risk classification, phased rollout, approval patterns

### Use Case 2: Context-Aware "Forensic" Troubleshooting

**Short Description:** In demos, agents usually just read the error message. In an Enterprise context, the agent must correlate the failure with **System Facts** and **Documentation** to distinguish between a "Coding Error" (Developer's fault) and "Platform Drift" (Admin's fault).

**Agent**: `forensic-troubleshooter` (agents/forensic-troubleshooter.md)

**Workflow:**

* **Trigger:** User says, "Job #502 failed."
* **Deep Dive** (job-failure-analyzer skill):
  * **Log Analysis:** Agent extracts the specific task error (e.g., "Service failed to start").
  * **Error Classification:** Classifies as Platform Issue, Code Issue, or Mixed.
  * **Failure Sequence:** Reconstructs timeline showing cascade effects.
* **Fact Correlation** (host-fact-inspector skill):
  * Agent fetches `ansible_facts` for the failure host. *Is the disk full? Is the OS version supported?*
  * Produces health assessment with platform drift detection.
* **Knowledge Retrieval** (troubleshooting-advisor skill):
  * Agent consults the [**Red Hat Troubleshooting Guide**](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs) to see if the error matches a known platform issue.
* **Resolution Path:**
  * If it's a **Platform Issue**: "This looks like a `sudo` timeout. Per the docs, we should increase the timeout in the Job Template."
  * If it's a **Code Issue**: "The module failed because the required library `python3-lxml` is missing on the target host."

**Skills:**

| Skill | Purpose |
|-------|---------|
| `mcp-aap-validator` | Validate AAP MCP server connectivity |
| `job-failure-analyzer` | Job event extraction, error classification, failure sequence |
| `host-fact-inspector` | Host fact retrieval, health assessment, platform drift detection |
| `troubleshooting-advisor` | Documentation-backed resolution recommendations |

**Skill Abilities:**

* Correlate `job_events` with `host_facts` (connecting the "What" with the "Where").
* Distinguish between "Unreachable" (Network) and "Failed" (Logic).
* Cite official Red Hat documentation for the fix.

**AAP MCP Tools:**

* `jobs_retrieve` (from aap-mcp-job-management)
* `jobs_job_events_list` (from aap-mcp-job-management)
* `hosts_list` (from aap-mcp-inventory-management)
* `hosts_ansible_facts_retrieve` (from aap-mcp-inventory-management)

**Docs:**

* [Red Hat AAP 2.6 Troubleshooting Guide (Jobs)](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs)

**Embedded Documentation:**
* `docs/aap/troubleshooting-jobs.md` - 6 failure patterns with resolution steps
* `docs/references/error-classification.md` - Platform vs code error taxonomy

## Future Use Cases

### Use Case 3: "Golden State" Inventory Auditing

**Short Description:** The agent uses MCP to query the inventory and proactively flag hosts that deviate from the "Golden Image" standard (e.g., outdated RHEL version or missing groups).

**Status**: Not yet implemented

### Use Case 4: Certified Content Guardrails (The "Curator")

**Short Description:** The agent proactively prevents technical debt by scanning user intent for "Anti-Patterns" (like using `shell` or `command` modules) and enforces the use of Red Hat Certified Collections from the Automation Hub.

**Status**: Not yet implemented

## Architecture

```
rh-automation/
├── README.md
├── .claude-plugin/plugin.json
├── .mcp.json
├── Red Hat Automation.md (this file)
├── agents/
│   ├── governance-deployer.md        # UC1: Governance-first deployment
│   └── forensic-troubleshooter.md    # UC2: Forensic troubleshooting
├── skills/
│   ├── mcp-aap-validator/SKILL.md
│   ├── deployment-safety-checker/SKILL.md
│   ├── governance-launcher/SKILL.md
│   ├── job-failure-analyzer/SKILL.md
│   ├── host-fact-inspector/SKILL.md
│   ├── troubleshooting-advisor/SKILL.md
│   └── execution-summary/SKILL.md
└── docs/
    ├── INDEX.md
    ├── SOURCES.md
    ├── .ai-index/
    │   ├── semantic-index.json
    │   ├── task-to-docs-mapping.json
    │   └── cross-reference-graph.json
    ├── aap/
    │   ├── README.md
    │   ├── job-launching-best-practices.md
    │   ├── deployment-governance.md
    │   └── troubleshooting-jobs.md
    └── references/
        ├── README.md
        └── error-classification.md
```

## Reference Docs

* [Ansible Content Collections](https://www.redhat.com/en/technologies/management/ansible/content-collections)
* [5 Use-cases with MCP server for Red Hat Ansible Automation Platform](https://www.youtube.com/watch?v=h6VboweM8Ww)

## Reference SMEs

[Andrew Potozniak](mailto:apotozni@redhat.com) - He's been working with the Ansible Lightspeed team around MCP and could connect us to the right folks if required.
