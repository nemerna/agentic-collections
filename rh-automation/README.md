# Red Hat Automation Agentic Collection

Intelligent automation governance for Ansible Automation Platform. This collection transforms AAP from an execution engine into an automation architect that audits platform configuration against Red Hat best practices, enforces governed deployments, and performs forensic failure analysis -- all backed by official Red Hat documentation.

**Persona**: Red Hat Automation Governance Architect
**Marketplaces**: Claude Code, Cursor

## Why Use This Instead of Raw MCP Tools?

A vanilla AI agent with AAP MCP access can list templates, launch jobs, and read events. But it lacks three things this collection provides:

1. **Knowledge** -- 4 documents distilling Red Hat's official recommendations (8+ sources) that the agent reads and cites in every output
2. **Judgment** -- 8 skills that interpret MCP data through Red Hat best practices (risk classification, error taxonomy, governance assessment)
3. **Workflow** -- 3 agents that orchestrate skills in governed sequences with human-in-the-loop controls

**Every recommendation is traceable to official Red Hat documentation.** The agent doesn't invent rules -- it embeds Red Hat's enterprise knowledge and cites chapter and section for every finding.

## Three Use Cases

### Use Case 1: Governance Assessment (The "Automation Architect")

> "Assess my AAP platform's governance readiness for production deployments."

The agent audits 7 governance domains across all 6 AAP MCP servers, producing a PASS/GAP/WARN report with Red Hat citations per finding. Domains: Workflow Governance, Notification Coverage, RBAC, Credential Security, Execution Environments, Workload Isolation, Audit Trail.

**Agent**: `governance-assessor` | **Key Skill**: `governance-readiness-assessor` | **Doc**: `governance-readiness.md`

### Use Case 2: Governed Deployment (The "Gatekeeper")

> "Deploy the security patch to production urgently."

The agent classifies inventory risk, scans extra_vars for secrets, runs check mode before execution, and requires approval for production targets. Catches failures in dry run before they cause outages.

**Agent**: `governance-deployer` | **Key Skills**: `deployment-risk-analyzer`, `governed-job-launcher` | **Doc**: `deployment-governance.md`

### Use Case 3: Forensic Troubleshooting (The "Analyst")

> "Job #4451 failed. What happened?"

The agent extracts failure events, classifies errors (Platform/Code/Configuration), correlates with host system facts, and provides Red Hat documentation-backed resolution recommendations.

**Agent**: `forensic-troubleshooter` | **Key Skills**: `job-failure-analyzer`, `host-fact-inspector`, `resolution-advisor` | **Docs**: `job-troubleshooting.md`, `error-classification.md`

## Quick Start

### Prerequisites

- Red Hat Ansible Automation Platform 2.5+
- Cursor IDE (or Claude Code)
- AAP API token

### Environment Setup

```bash
export AAP_SERVER="your-aap-server.example.com"
export AAP_API_TOKEN="your-personal-access-token"
```

### Installation (Cursor IDE)

```bash
rh-automation/scripts/setup-cursor.sh install
```

Opens lightweight skill wrappers in `~/.cursor/skills/`. Open a new Cursor chat to start using the skills.

```bash
rh-automation/scripts/setup-cursor.sh status     # check installed skills
rh-automation/scripts/setup-cursor.sh uninstall   # remove skills
```

## Skills (8)

| Skill | Purpose | MCP Servers |
|-------|---------|-------------|
| `aap-mcp-validator` | Validate AAP MCP server connectivity | All 6 |
| `governance-readiness-assessor` | 7-domain platform governance audit | All 6 |
| `deployment-risk-analyzer` | Inventory risk classification + secret scanning | job-management, inventory-management |
| `governed-job-launcher` | Check mode + approval + phased rollout + rollback | job-management |
| `job-failure-analyzer` | Event extraction + error classification | job-management |
| `host-fact-inspector` | Host fact correlation with failures | inventory-management |
| `resolution-advisor` | Red Hat doc-backed resolution recommendations | None (advisory) |
| `execution-summary` | Audit trail with doc consultation tracking | None (reporting) |

## Agents (3)

| Agent | Use Case | Skills Orchestrated |
|-------|----------|-------------------|
| `governance-assessor` | Platform governance audit | validator → readiness-assessor → summary |
| `governance-deployer` | Governed deployment | validator → risk-analyzer → job-launcher → summary |
| `forensic-troubleshooter` | Failure root cause analysis | validator → failure-analyzer → fact-inspector → resolution-advisor → summary |

## MCP Server Integrations (6)

| Server | Purpose |
|--------|---------|
| `aap-mcp-job-management` | Job templates, launches, events, workflows |
| `aap-mcp-inventory-management` | Inventories, hosts, groups, host facts |
| `aap-mcp-configuration` | Notifications, execution environments, settings |
| `aap-mcp-security-compliance` | Credentials, credential types |
| `aap-mcp-system-monitoring` | Instance groups, activity stream, status |
| `aap-mcp-user-management` | Users, teams, roles, authenticators |

## Documentation

4 AI-optimized documents backed by 8+ official Red Hat sources:

| Document | Content | Red Hat Sources |
|----------|---------|----------------|
| `governance-readiness.md` | 7-domain assessment framework | Security Best Practices, Workflows, Notifications, RBAC, EE, Instance Groups, Activity Stream, Hardening Guide |
| `deployment-governance.md` | Risk classification, check mode, rollback, phased rollout | Job Templates, Security Best Practices, Controller Best Practices, Check Mode |
| `job-troubleshooting.md` | Event parsing, host correlation, failure patterns | AAP 2.6 Troubleshooting Guide, Job Events |
| `error-classification.md` | Error taxonomy, classification trees, resolution paths | AAP 2.6 Troubleshooting Guide, Ansible Module docs |

See [docs/INDEX.md](docs/INDEX.md) for the complete documentation map and [docs/SOURCES.md](docs/SOURCES.md) for all source attributions.

## Demo

A 3-part live demo against a real AAP instance:

1. **Vanilla Deployment** -- AI breaks production (visual impact)
2. **Skilled Deployment** -- AI catches failure via check mode (safety net)
3. **Governance Assessment** -- AI audits platform against Red Hat best practices (crown jewel)

See [demo/README.md](demo/README.md) for setup and [demo/DEMO-SCRIPT.md](demo/DEMO-SCRIPT.md) for the presenter guide.

## Architecture

```
rh-automation/
├── .mcp.json                        # 6 AAP MCP servers
├── agents/
│   ├── governance-assessor.md       # UC1: Platform governance audit
│   ├── governance-deployer.md       # UC2: Governed deployment
│   └── forensic-troubleshooter.md   # UC3: Forensic troubleshooting
├── skills/
│   ├── aap-mcp-validator/           # Shared: MCP connectivity
│   ├── governance-readiness-assessor/ # UC1: 7-domain assessment
│   ├── deployment-risk-analyzer/    # UC2: Risk + secret scanning
│   ├── governed-job-launcher/       # UC2: Check mode + launch
│   ├── job-failure-analyzer/        # UC3: Event extraction
│   ├── host-fact-inspector/         # UC3: Host correlation
│   ├── resolution-advisor/          # UC3: Resolution guidance
│   └── execution-summary/          # Shared: Audit trail
├── docs/
│   ├── aap/
│   │   ├── governance-readiness.md  # 7-domain assessment reference
│   │   ├── deployment-governance.md # Deployment execution reference
│   │   └── job-troubleshooting.md   # Failure analysis reference
│   └── references/
│       └── error-classification.md  # Error taxonomy reference
├── demo/                            # 3-part live demo
└── scripts/
    └── setup-cursor.sh              # Install/uninstall/status
```

## References

- [Red Hat Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible)
- [AAP 2.5 Security Best Practices](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html/automation_controller_administration_guide/assembly-controller-security-best-practices)
- [AAP 2.6 Troubleshooting Guide](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs)
- [AAP 2.6 Execution Environments](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/creating_and_consuming_execution_environments)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
