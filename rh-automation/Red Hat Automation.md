# Red Hat Automation Governance Architect

## Description

This collection transforms Ansible Automation Platform from an execution engine into an intelligent automation governance partner. The agent embeds official Red Hat documentation (8+ sources) to provide three capabilities that raw MCP tools cannot: governance assessment against Red Hat best practices, risk-aware deployment with check mode and rollback, and forensic failure analysis with error classification and resolution advisory.

Every recommendation is traceable to official Red Hat documentation with chapter and section citations. The agent doesn't invent rules -- it implements Red Hat's published enterprise knowledge.

## Target Marketplaces

- Cursor
- Claude Code

## Connected MCPs (6 servers)

All 6 AAP MCP servers are required for full governance assessment. Deployment and troubleshooting workflows require a subset.

| Server | URL Pattern | Purpose |
|--------|-------------|---------|
| `aap-mcp-job-management` | `https://${AAP_SERVER}/job_management/mcp` | Job templates, launches, events, workflows, approvals |
| `aap-mcp-inventory-management` | `https://${AAP_SERVER}/inventory_management/mcp` | Inventories, hosts, groups, host facts |
| `aap-mcp-configuration` | `https://${AAP_SERVER}/configuration/mcp` | Notifications, execution environments, settings |
| `aap-mcp-security-compliance` | `https://${AAP_SERVER}/security_compliance/mcp` | Credentials, credential types |
| `aap-mcp-system-monitoring` | `https://${AAP_SERVER}/system_monitoring/mcp` | Instance groups, activity stream, status |
| `aap-mcp-user-management` | `https://${AAP_SERVER}/user_management/mcp` | Users, teams, roles, authenticators |

## Example Prompts

**Governance Assessment (The "Automation Architect")**

* *"Assess my AAP platform's governance readiness for production deployments."*
  * Triggers: 7-domain audit across all 6 MCP servers with Red Hat citations per finding

**Governed Deployment (The "Gatekeeper")**

* *"Deploy the security patch to production urgently."*
  * Triggers: Risk classification, secret scanning, check mode, approval gate, phased rollout

**Forensic Troubleshooting (The "Analyst")**

* *"Job #4451 failed halfway through. What happened?"*
  * Triggers: Event extraction, error classification, host fact correlation, resolution advisory

## Implemented Use Cases

### Use Case 1: Governance Readiness Assessment

**Agent**: `governance-assessor`

**Workflow**: validator → governance-readiness-assessor → offer remediation → execution-summary

**7 Domains Assessed**:
1. Workflow Governance (Red Hat AAP 2.5, Ch. 9)
2. Notification Coverage (Red Hat AAP 2.5, Ch. 25)
3. Access Control / RBAC (Red Hat AAP 2.5, Ch. 15, Sec. 15.2.1)
4. Credential Security (Red Hat AAP 2.5, Ch. 15, Sec. 15.1.4-5)
5. Execution Environments (Red Hat AAP 2.6 EE Guide)
6. Workload Isolation (Red Hat AAP 2.5, Ch. 17)
7. Audit Trail (Red Hat AAP 2.5, Activity Stream)
8. External Authentication (Bonus -- Red Hat AAP 2.5, Ch. 15, Sec. 15.2.2)

**MCP Tools Used**: `workflow_job_templates_list`, `job_templates_list`, `notification_templates_list`, `users_list`, `teams_list`, `role_user_assignments_list`, `role_team_assignments_list`, `credentials_list`, `credential_types_list`, `execution_environments_list`, `instance_groups_list`, `activity_stream_list`, `authenticators_list`

**Documentation**: [governance-readiness.md](docs/aap/governance-readiness.md)

### Use Case 2: Governed Deployment

**Agent**: `governance-deployer`

**Workflow**: validator → deployment-risk-analyzer → governed-job-launcher → execution-summary

**Governance Controls**:
- Inventory risk classification (CRITICAL / HIGH / MEDIUM / LOW)
- Extra_vars secret scanning
- Check mode with diff_mode for CRITICAL/HIGH targets
- Approval gate before full execution
- Phased rollout (canary → 25% → full) for CRITICAL targets
- Rollback via `jobs_relaunch_create` on failure

**MCP Tools Used**: `job_templates_list`, `job_templates_retrieve`, `job_templates_launch_retrieve`, `job_templates_launch_create`, `jobs_retrieve`, `jobs_job_events_list`, `jobs_job_host_summaries_list`, `jobs_relaunch_create`, `inventories_list`, `hosts_list`

**Documentation**: [deployment-governance.md](docs/aap/deployment-governance.md)

### Use Case 3: Forensic Troubleshooting

**Agent**: `forensic-troubleshooter`

**Workflow**: validator → job-failure-analyzer → host-fact-inspector → resolution-advisor → execution-summary

**Analysis Capabilities**:
- Event extraction and failure timeline reconstruction
- Error classification: Platform / Code / Configuration
- Host fact correlation (disk, memory, OS version, service manager)
- Red Hat documentation-backed resolution paths

**MCP Tools Used**: `jobs_retrieve`, `jobs_job_events_list`, `jobs_job_host_summaries_list`, `jobs_stdout_retrieve`, `hosts_list`, `hosts_variable_data_retrieve`

**Documentation**: [job-troubleshooting.md](docs/aap/job-troubleshooting.md), [error-classification.md](docs/references/error-classification.md)

## Skills

| Skill | Use Case | Purpose |
|-------|----------|---------|
| `aap-mcp-validator` | Shared | Validate AAP MCP server connectivity (all 6 servers) |
| `governance-readiness-assessor` | UC1 | 7-domain governance assessment with Red Hat citations |
| `deployment-risk-analyzer` | UC2 | Inventory risk classification + secret scanning |
| `governed-job-launcher` | UC2 | Check mode + approval + phased rollout + rollback |
| `job-failure-analyzer` | UC3 | Event extraction + error classification |
| `host-fact-inspector` | UC3 | Host fact correlation with failures |
| `resolution-advisor` | UC3 | Red Hat doc-backed resolution recommendations |
| `execution-summary` | Shared | Audit trail with doc consultation tracking |

## Architecture

```
rh-automation/
├── .mcp.json                        # 6 AAP MCP servers
├── agents/
│   ├── governance-assessor.md       # UC1
│   ├── governance-deployer.md       # UC2
│   └── forensic-troubleshooter.md   # UC3
├── skills/
│   ├── aap-mcp-validator/
│   ├── governance-readiness-assessor/
│   ├── deployment-risk-analyzer/
│   ├── governed-job-launcher/
│   ├── job-failure-analyzer/
│   ├── host-fact-inspector/
│   ├── resolution-advisor/
│   └── execution-summary/
├── docs/
│   ├── aap/
│   │   ├── governance-readiness.md
│   │   ├── deployment-governance.md
│   │   └── job-troubleshooting.md
│   └── references/
│       └── error-classification.md
├── demo/
│   ├── README.md
│   ├── DEMO-SCRIPT.md
│   └── playbooks/
└── scripts/
    └── setup-cursor.sh
```

## Reference SMEs

[Andrew Potozniak](mailto:apotozni@redhat.com) - Ansible Lightspeed team, MCP server integration
