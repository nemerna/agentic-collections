# Red Hat Automation Agentic Collection

Intelligent automation governance and forensic troubleshooting for Ansible Automation Platform. This pack transforms AAP from an execution engine into an intelligent automation partner that enforces best practices, prevents unsafe deployments, and performs context-aware failure analysis.

**Persona**: Red Hat Automation Specification Lead
**Marketplaces**: Claude Code, Cursor

## Overview

The rh-automation collection provides:
- **7 specialized skills** for governance, troubleshooting, and operational tasks
- **2 orchestration agents** for complex multi-step workflows
- **AI-optimized documentation** with semantic indexing based on official Red Hat docs
- **2 MCP server integrations** (AAP Job Management, AAP Inventory Management)

## Why Use This Agentic Collection Instead of Raw MCP Tools?

While you could use the underlying AAP MCP servers directly, this collection provides critical advantages that transform how automation engineers interact with AAP:

### Governance & Safety

**Proactive Risk Detection**
- Skills detect high-risk targets (inventories named `prod`, `pci`, `secure`) and raise safety flags before execution
- Automatic scanning of `extra_vars` for plain-text secrets, blocking insecure deployments
- Limit enforcement ensures deployments are scoped appropriately
- Example: "Deploy to Production" triggers inventory validation, secret scanning, and check mode recommendation before any job runs

**Check Mode Enforcement**
- Skills automatically recommend dry-run execution for production targets
- Dry-run results are analyzed and summarized before requesting execution confirmation
- Changed-only output filtering reduces noise in post-execution summaries
- Example: Instead of 200 "OK" events, the skill highlights only the 5 tasks that would change

**Human-in-the-Loop for Critical Operations**
- Explicit confirmation required before production deployments
- Pre-execution preview showing target systems, risk level, and scope
- Post-dry-run analysis before full execution approval

### Forensic Troubleshooting

**Root Cause Correlation**
- Skills correlate job failure events with host system facts automatically
- Distinguishes "Unreachable" (network/platform) from "Failed" (code/logic) errors
- Maps failures to specific hosts and tasks, not just generic error messages
- Example: "Job failed" → Skill determines disk was full on target host, not a playbook bug

**Documentation-Backed Resolution**
- Skills consult Red Hat AAP Troubleshooting Guide and best practices documentation
- Error messages are matched against known issue patterns
- Resolution recommendations cite official Red Hat documentation
- Different resolution paths for platform issues vs code issues

### Productivity & Consistency

**Natural Language Workflows**
- "Deploy the new web app to production" → Triggers full governance workflow
- "Job #502 failed" → Triggers forensic analysis with host fact correlation
- No need to remember MCP tool names, parameters, or execution order

**Opinionated Best Practices**
- Every deployment follows Red Hat-validated governance patterns
- Every troubleshooting session follows a systematic correlation methodology
- Consistent behavior across users and sessions

**Progressive Documentation Loading**
- Skills load Red Hat documentation on-demand based on task requirements
- Semantic indexing reduces token overhead
- Only relevant docs enter context

### Error Handling

**Actionable Error Messages**
- Context-aware guidance based on failure mode
- Specific troubleshooting steps when operations fail
- Clear distinction between configuration issues and runtime errors

**Dependency Declaration**
- Skills explicitly document required MCP servers, tools, environment variables
- Clear prerequisites prevent runtime failures
- Setup instructions included inline when dependencies are missing

---

**Bottom Line**: This collection transforms AAP MCP tools into a governed, intelligent automation platform. The governance-deployer agent prevents unsafe deployments that vanilla agents would execute blindly. The forensic-troubleshooter agent performs systematic root cause analysis that vanilla agents would miss entirely.

## Quick Start

### Prerequisites

- Claude Code CLI or Cursor IDE
- Red Hat Ansible Automation Platform 2.5+ instance
- AAP MCP server endpoints enabled

### Environment Setup

Configure AAP credentials:

```bash
export AAP_SERVER="https://your-aap-server.example.com"
export AAP_API_TOKEN="your-personal-access-token"
```

To generate an API token:
1. Log in to AAP Web UI
2. Navigate to Users → [Your User] → Tokens
3. Create a new Personal Access Token
4. Copy the token value

### Installation (Claude Code)

```bash
claude plugin marketplace add https://github.com/RHEcosystemAppEng/agentic-collections
claude plugin install rh-automation
```

## Skills

### 1. **mcp-aap-validator** - AAP MCP Server Validation
Validate AAP MCP server configuration and connectivity.

**Use when:**
- "Validate AAP MCP"
- "Check if AAP is configured"
- "Verify AAP connection"
- Other skills need to verify AAP MCP server availability

### 2. **deployment-safety-checker** - Pre-Deployment Risk Analysis
Comprehensive safety analysis before job execution.

**Use when:**
- "Deploy X to production" (automatically invoked by governance-deployer)
- "Check if this deployment is safe"
- "Validate the deployment target"

**What it does:**
- Classifies inventory risk level (production/staging/development)
- Scans extra_vars for plain-text secrets
- Recommends scope limiting for high-risk targets
- Suggests check mode for production deployments

### 3. **governance-launcher** - Governed Job Execution
Launch AAP jobs with full governance controls.

**Use when:**
- "Launch this job template with governance checks"
- "Run this in check mode first"
- After safety checks pass (invoked by governance-deployer)

**What it does:**
- Executes in check mode (dry run) first
- Analyzes dry-run results
- Requests explicit confirmation for full execution
- Summarizes only Changed tasks (noise reduction)

### 4. **job-failure-analyzer** - Forensic Job Failure Analysis
Deep-dive analysis of failed AAP jobs.

**Use when:**
- "Job #502 failed"
- "Why did the deployment fail?"
- "Analyze the failed job"

**What it does:**
- Extracts job events and identifies failing tasks
- Classifies errors (Unreachable vs Failed vs Timeout)
- Maps failures to specific hosts
- Identifies error patterns (privilege escalation, module not found, etc.)

### 5. **host-fact-inspector** - Host Fact Correlation
Correlate job failures with system facts.

**Use when:**
- After job failure analysis identifies affected hosts
- "Check the system facts for the failed hosts"
- "Is the host healthy?"

**What it does:**
- Retrieves ansible_facts for failure hosts
- Checks disk space, memory, OS version
- Validates OS version against supported versions
- Detects platform drift

### 6. **troubleshooting-advisor** - Resolution Recommendations
Documentation-backed troubleshooting guidance.

**Use when:**
- After failure analysis and fact inspection
- "How do I fix this error?"
- "What does the Red Hat docs say about this?"

**What it does:**
- Consults Red Hat AAP Troubleshooting Guide
- Matches errors to known issue patterns
- Provides resolution paths (platform issue vs code issue)
- Cites official documentation

### 7. **execution-summary** - Workflow Execution Report
Generate concise execution reports.

**Use when:**
- "Generate execution summary"
- "Summarize what happened"
- After completing a governance deployment or troubleshooting session

## Agents

### **governance-deployer** - Governance-First Deployment (Use Case 1)

Orchestrates safe, governed deployments through AAP.

**Use when:**
- "Deploy the new Web App version to Production"
- "Push the latest release to the Production inventory"
- Any deployment request targeting production or sensitive environments

**Workflow:**
1. **Validate** AAP MCP connectivity (mcp-aap-validator)
2. **Safety Check** deployment parameters (deployment-safety-checker)
3. **Execute** with governance controls (governance-launcher)

### **forensic-troubleshooter** - Context-Aware Troubleshooting (Use Case 2)

Orchestrates systematic root cause analysis for failed jobs.

**Use when:**
- "Job #4451 failed halfway through"
- "Analyze the logs and tell me what went wrong"
- "Was it a script error or was the host unreachable?"

**Workflow:**
1. **Validate** AAP MCP connectivity (mcp-aap-validator)
2. **Analyze** job failure events (job-failure-analyzer)
3. **Inspect** host facts for affected systems (host-fact-inspector)
4. **Advise** resolution with documentation backing (troubleshooting-advisor)

## Skills vs Agent Decision Guide

| User Request | Tool to Use | Reason |
|--------------|-------------|--------|
| "Deploy X to production" | **governance-deployer agent** | Multi-step governance workflow |
| "Is this deployment safe?" | **deployment-safety-checker skill** | Standalone safety check |
| "Run this in check mode" | **governance-launcher skill** | Direct job launch with governance |
| "Job #502 failed" | **forensic-troubleshooter agent** | Multi-step troubleshooting |
| "Show me the job events" | **job-failure-analyzer skill** | Standalone event analysis |
| "Check host facts for server-01" | **host-fact-inspector skill** | Standalone fact inspection |
| "How to fix this AAP error?" | **troubleshooting-advisor skill** | Standalone doc lookup |
| "Validate AAP MCP" | **mcp-aap-validator skill** | MCP validation |
| "Summarize what happened" | **execution-summary skill** | Audit reporting |

**General Rule**: Agents for multi-step workflows, skills for specific tasks.

## Documentation

The rh-automation pack includes AI-optimized documentation in the `docs/` directory:

### Documentation Categories

- **AAP**: Job launching, deployment governance, troubleshooting
- **References**: Error classification, severity patterns

### Semantic Indexing System

- **Progressive Disclosure**: Load only required docs based on task
- **Cross-Reference Graph**: Document relationship mapping
- **Task-to-Docs Mapping**: Pre-computed doc sets for common workflows

See [docs/INDEX.md](docs/INDEX.md) for the complete documentation map.

## MCP Server Integrations

### 1. **aap-mcp-job-management** - AAP Job Management
- Job template management (list, retrieve, launch)
- Job execution tracking and monitoring
- Job event inspection and analysis
- Requires: `AAP_SERVER`, `AAP_API_TOKEN`

**Type**: HTTP MCP server

### 2. **aap-mcp-inventory-management** - AAP Inventory Management
- Inventory and host management
- Host fact retrieval
- Group and variable management
- Requires: `AAP_SERVER`, `AAP_API_TOKEN`

**Type**: HTTP MCP server

## Sample Workflows

### Workflow 1: Governance-First Production Deployment

```
User: "Deploy the new Web App version to Production"
→ governance-deployer agent:
  1. Validates AAP MCP connectivity
  2. Resolves "Production" inventory → flags as HIGH RISK
  3. Scans extra_vars → blocks if plain-text secrets found
  4. Recommends: "Run in Check Mode first to see changes"
  5. Executes dry run → summarizes expected changes
  6. Asks: "Proceed with full deployment to us-east group first?"
  7. Executes with limit → summarizes only Changed tasks
```

### Workflow 2: Forensic Job Failure Analysis

```
User: "Job #4451 failed halfway through"
→ forensic-troubleshooter agent:
  1. Validates AAP MCP connectivity
  2. Reads job events → finds "Service failed to start" on host db-01
  3. Fetches host facts for db-01 → disk 98% full, RHEL 7 (EOL)
  4. Consults Red Hat docs → matches known issue pattern
  5. Reports: "Platform Issue: disk full on db-01. Per Red Hat docs,
     clear /var/log and consider RHEL 7→9 migration"
```

## Security Model

- **Credential Handling**: Environment variables only, never hardcoded or exposed in output
- **Secret Scanning**: Skills proactively detect plain-text secrets in extra_vars
- **Check Mode First**: Production deployments always recommend dry-run first
- **Limit Enforcement**: High-risk deployments suggest scope limiting
- **Human Confirmation**: Explicit approval required before production execution

## Configuration

MCP servers are configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "aap-mcp-job-management": {
      "type": "http",
      "url": "https://${AAP_SERVER}/job_management/mcp",
      "headers": {
        "Authorization": "Bearer ${AAP_API_TOKEN}"
      }
    },
    "aap-mcp-inventory-management": {
      "type": "http",
      "url": "https://${AAP_SERVER}/inventory_management/mcp",
      "headers": {
        "Authorization": "Bearer ${AAP_API_TOKEN}"
      }
    }
  }
}
```

## Troubleshooting

### AAP MCP Connection Issues

**Problem**: AAP MCP servers fail to connect

**Solutions**:
1. Verify AAP server is accessible: `curl -I ${AAP_SERVER}`
2. Check API token validity in AAP Web UI → Users → Tokens
3. Test authentication: `curl -H "Authorization: Bearer ${AAP_API_TOKEN}" ${AAP_SERVER}/api/controller/v2/ping/`
4. Verify MCP endpoints are enabled on AAP instance

### Skills Not Triggering

**Problem**: Skills don't activate on expected queries

**Solutions**:
1. Verify plugin installed: `claude plugin list`
2. Check skill descriptions in `skills/*/SKILL.md`
3. Use explicit phrasing matching skill examples

## Architecture Reference

```
rh-automation/
├── README.md
├── .claude-plugin/
│   └── plugin.json
├── .mcp.json
├── agents/
│   ├── governance-deployer.md
│   └── forensic-troubleshooter.md
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

## Key Patterns

- **Skills encapsulate tools** - Never call MCP tools directly
- **Agents orchestrate skills** - Complex workflows delegate to skills
- **Governance by default** - Production deployments always go through safety checks
- **Document consultation** - Skills read Red Hat docs and declare consultation to users
- **Progressive disclosure** - Load docs incrementally based on task needs
- **Environment-based secrets** - No hardcoded credentials

## Development

See main repository [CLAUDE.md](../CLAUDE.md) for:
- Adding new skills
- Creating agents
- Integrating MCP servers
- Documentation best practices

## License

[Apache 2.0](LICENSE)

## References

- [Red Hat Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible)
- [AAP Controller User Guide - Launching Jobs](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-job-templates#launching-job-templates)
- [AAP Best Practices](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/assembly-controller-best-practices)
- [AAP Troubleshooting Guide](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs)
- [AAP REST API Documentation](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Main Repository](https://github.com/RHEcosystemAppEng/agentic-collections)
