---
name: cluster-report
description: |
  Generate a consolidated health report across multiple OpenShift clusters.
  Collects node resources (CPU, memory, GPUs), namespace counts, and pod
  status from all kubeconfig contexts into a single comparison view.
  Use when:
  - "Show me a report across all clusters"
  - "Compare cluster health"
  - "Multi-cluster status overview"
  - "How are my clusters doing?"
  NOT for single-cluster deep-dives or troubleshooting specific pods.
model: inherit
color: cyan
metadata:
  user_invocable: "true"
---

# Multi-Cluster Report Skill

Generate a unified health and resource report across multiple OpenShift/Kubernetes clusters using the OpenShift MCP server's multi-cluster capabilities.

## Prerequisites

**Required MCP Servers**: `openshift` (configured in [.mcp.json](../../.mcp.json))

**Required MCP Tools** (all from `openshift` server):
- `configuration_contexts_list`
- `nodes_top`
- `resources_list`
- `namespaces_list`
- `projects_list`
- `pods_list`

**Required Environment Variables**: `KUBECONFIG` — must contain at least one cluster context. Two or more recommended for comparison.

**Helper Scripts** (Python 3, stdlib only — treat as black boxes):
- [`assemble.py`](../../scripts/cluster-report/assemble.py) — resolves `$file` references into complete raw data JSON
- [`aggregate.py`](../../scripts/cluster-report/aggregate.py) — aggregates raw data into structured report JSON

**CRITICAL Script Rules**:
- **NEVER** read the source code of `aggregate.py` or `assemble.py`
- **NEVER** write ad-hoc Python to parse or transform MCP output
- **NEVER** manually reconstruct data already available in MCP output

## When to Use This Skill

**Use when**:
- Comparing resource utilization across clusters
- Getting a fleet-wide health overview
- Preparing capacity planning reports

**Do NOT use when**:
- Debugging a specific pod or workload (use `/debug-pod`)

## Workflow

### Step 0: Validate Environment

Check that `KUBECONFIG` is set. **Never expose the path or contents** — only confirm it is set. If not set, stop and instruct the user to `export KUBECONFIG=/path/to/kubeconfig`.

### Step 1: Discover Available Clusters

**MCP Tool**: `configuration_contexts_list`

Present the discovered clusters (name and server URL) to the user and ask which to include.

**WAIT**: Do not proceed until user confirms cluster selection.

### Step 2: Collect Cluster Data

For each selected cluster, pass `context=<context-name>` to every tool call. Collect data using:

| Manifest Key | MCP Tool | Extra Parameters | Fallback |
|---|---|---|---|
| `nodes_top` | `nodes_top` | — | Set null if Metrics Server unavailable |
| `nodes_list` | `resources_list` | `apiVersion=v1`, `kind=Node` | — |
| `projects` | `projects_list` | — | Use `namespaces_list` if fails |
| `pods` | `pods_list` | — | — |

**Error policy**: Skip unreachable clusters. Set failed fields to `null` and append the error to the cluster's `errors` array. Never abort the entire report.

#### Persist MCP Output to Files

For each MCP tool call, **immediately save the output to a file** under `/tmp/cluster-report/`.
This ensures data is available for the assembly pipeline regardless of output size.

**Naming convention**: `/tmp/cluster-report/<context-short>-<field>.txt`

Use a sanitized short name for the context (e.g., `prod-us`, `dev-eu`). Create the directory first:

```bash
mkdir -p /tmp/cluster-report
```

**How to save**: After each MCP tool call, use Bash to write the output to disk. `$file` references
accept **both plain text and JSON files** — no special formatting is required.

If Claude Code auto-persisted the output to a file (shown as `persisted-output` in the tool result),
reference that file path directly.

#### Assemble Manifest

Write the manifest to `/tmp/cluster-report-manifest.json` with `$file` references to the saved files:

```json
{
  "generated_at": "2026-03-03T14:30:00Z",
  "clusters": {
    "<context-name>": {
      "context": "<context-name>",
      "server": "<server-url>",
      "nodes_top": {"$file": "/tmp/cluster-report/<ctx>-nodes_top.txt"} or null,
      "nodes_list": {"$file": "/tmp/cluster-report/<ctx>-nodes_list.txt"} or null,
      "projects": {"$file": "/tmp/cluster-report/<ctx>-projects.txt"} or null,
      "namespaces": {"$file": "/tmp/cluster-report/<ctx>-namespaces.txt"} or null,
      "pods": {"$file": "/tmp/cluster-report/<ctx>-pods.txt"} or null,
      "errors": ["<error messages for failed tools>"]
    }
  }
}
```

Fields may also be inlined as raw text strings or set to `null` for failed/unavailable data.

### Step 3: Aggregate Data

Run the assembly and aggregation pipeline:

```bash
python3 ocp-admin/scripts/cluster-report/assemble.py --aggregate < /tmp/cluster-report-manifest.json
```

If the pipeline exits with code 1, display the error JSON to the user and stop.

### Step 4: Render Report

Render the structured JSON output as markdown using this template:

```markdown
# Multi-Cluster Report

**Generated**: YYYY-MM-DDTHH:MM:SSZ
**Clusters**: <clusters_reported> clusters reporting

---

## Cluster Overview

| Cluster | Nodes | CPU (used/total) | Memory (used/total) | GPUs | Projects | Pods (Running/Total) |
|---------|-------|-------------------|---------------------|------|----------|---------------------|
| prod-us | 12    | 48/96 cores (50%) | 192/384 GiB (50%)   | 8    | 45       | 312/320             |
| dev-eu  | 4     | 8/32 cores (25%)  | 32/128 GiB (25%)    | 0    | 12       | 87/92               |
| **Total** | **16** | **56/128 cores (44%)** | **224/512 GiB (44%)** | **8** | **57** | **399/412** |

---

## Per-Cluster Details

### <cluster> (<server>)

#### Node Resources

| Node | Role | CPU Used | CPU Total | Memory Used | Memory Total | GPUs |
|------|------|----------|-----------|-------------|--------------|------|
| node-1 | worker | 4 cores | 8 cores | 16 GiB | 32 GiB | 2 |

#### Pod Status

| Status | Count |
|--------|-------|
| Running | 312 |
| Pending | 5 |
| Succeeded | 0 |
| Failed | 3 |
| Unknown | 0 |

#### Top Namespaces (by pod count)

| Namespace | Pods | Running | Pending | Failed |
|-----------|------|---------|---------|--------|
| openshift-monitoring | 24 | 24 | 0 | 0 |

[Repeat for each cluster]

---

## Attention Required

[Render each item from the `attention` array]
```

### Step 5: Offer Next Steps

```markdown
## Next Steps

Would you like to:
1. **Drill down** into a specific cluster or namespace
2. **Check alerts** — query Prometheus/Alertmanager for active alerts
3. **Refresh** — re-run the report with updated data
```

## Dependencies

### Required MCP Servers
- `openshift` — with multi-cluster support enabled

### Required MCP Tools
- `configuration_contexts_list`, `nodes_top`, `resources_list`, `namespaces_list`, `projects_list`, `pods_list`

### Helper Scripts
- [`ocp-admin/scripts/cluster-report/assemble.py`](../../scripts/cluster-report/assemble.py)
- [`ocp-admin/scripts/cluster-report/aggregate.py`](../../scripts/cluster-report/aggregate.py)

### Related Skills
- None currently

### Reference Documentation
- [OpenShift MCP Server](https://github.com/openshift/openshift-mcp-server)
- [Kubernetes MCP Server Tools](https://github.com/containers/kubernetes-mcp-server#tools)

## Error Handling

| Error | Behavior |
|---|---|
| Cluster unreachable | Skip, continue with remaining clusters |
| Metrics Server missing | Set `nodes_top` to null, show N/A for CPU/memory usage |
| Auth expired (401) | Skip cluster, suggest `oc login <server-url>` |
| No GPUs found | Display 0 (not an error) |
| Empty cluster | Report with all zeros (valid data) |

## Examples

### Multi-Cluster Report

**User**: "Show me a report across all clusters"

**Execution**:
1. Validate KUBECONFIG — OK
2. `configuration_contexts_list()` discovers: prod-us, dev-eu
3. User confirms all clusters
4. Collect `nodes_top`, `resources_list` (Nodes), `projects_list`, `pods_list` for each context
5. Write manifest to `/tmp/cluster-report-manifest.json`
6. Run `assemble.py --aggregate` pipeline
7. Render structured JSON as markdown report
8. Flag attention items (e.g., "prod-us: 3 pods in Failed state")
