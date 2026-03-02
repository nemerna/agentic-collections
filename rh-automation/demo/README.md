# rh-automation Demo Setup Guide

This directory contains everything needed to run the 3-part live demo: playbooks, templates, and step-by-step setup instructions for AAP.

## Repository Layout

```
demo/
├── README.md              ← You are here (setup guide)
├── DEMO-SCRIPT.md         ← 3-part presenter guide
└── playbooks/             ← Push to the AAP project Git repo
    ├── deploy-security-patch.yml
    ├── setup-hosts.yml
    ├── reset.yml
    ├── verify.yml
    ├── templates/
    │   └── webapp.conf.j2
    └── files/
        └── index.html
```

## Prerequisites

- AAP 2.5+ running (on OpenShift or standalone)
- 1 RHEL 8/9 or CentOS Stream 9 host accessible via SSH from the AAP execution environment
- A GitHub repo with the playbooks (e.g., `https://github.com/nemerna/automation-persona-demo.git`)
- Cursor IDE with AAP MCP servers configured (all 6 servers in `.mcp.json`)
- Environment variables set: `AAP_SERVER`, `AAP_API_TOKEN`

---

## Step 1: Provision a Host

Spin up **1 host** reachable via SSH from AAP:

| Option | Notes |
|--------|-------|
| RHEL 8/9 VM | Any hypervisor or cloud provider |
| CentOS Stream 9 VM | Free alternative to RHEL |
| OpenShift Virtualization VM | If OCP Virt is available on your cluster |

### Host Requirements

- RHEL 8/9 or CentOS Stream 9 (required -- playbooks use `ansible.builtin.dnf`)
- `python3` installed
- `sshd` running and accessible from AAP
- `dnf` repos configured (RHEL BaseOS/AppStream or CentOS repos)
- Firewall allows port 80 inbound (for the web app)

### Verify Host Readiness

```bash
ssh <user>@<host-ip>
python3 --version
sudo dnf repolist
sudo systemctl status sshd
```

Record: **IP address**, **SSH username**, **SSH key or password**.

---

## Step 2: Create Machine Credential in AAP

1. Go to **Resources > Credentials > Add**
2. **Name**: `Demo SSH Credential`
3. **Organization**: Default
4. **Credential Type**: Machine
5. **Username**: your SSH username
6. **SSH Private Key** or **Password**: your SSH authentication
7. **Privilege Escalation Method**: sudo
8. Save

---

## Step 3: Create Inventory in AAP

1. Go to **Resources > Inventories > Add > Add inventory**
2. **Name**: `Production`
   - The name **must contain "prod"** -- this triggers the governance-deployer's CRITICAL risk classification
3. **Organization**: Default
4. Save

### Add the Host

1. Open the `Production` inventory
2. Go to the **Hosts** tab > **Add**
3. **Name**: the IP address or hostname of your host
4. Save

---

## Step 4: Create Project in AAP

1. Go to **Resources > Projects > Add**
2. **Name**: `Demo Security Patch`
3. **Organization**: Default
4. **Source Control Type**: Git
5. **Source Control URL**: `https://github.com/nemerna/automation-persona-demo.git`
6. Save and wait for sync to complete

---

## Step 5: Create Job Templates in AAP

### Template 1: "Deploy Security Patch" (the demo template)

| Field | Value |
|-------|-------|
| Name | `Deploy Security Patch` |
| Inventory | `Production` |
| Project | `Demo Security Patch` |
| Playbook | `deploy-security-patch.yml` |
| Credentials | `Demo SSH Credential` |
| Extra Variables | `security_patch_package: "webapp-security-fix-2.0"` |

Under **Prompt on launch**, enable: **Limit**, **Job type**, **Extra variables**

### Template 2: "Setup Demo Hosts"

| Field | Value |
|-------|-------|
| Name | `Setup Demo Hosts` |
| Inventory | `Production` |
| Project | `Demo Security Patch` |
| Playbook | `setup-hosts.yml` |
| Credentials | `Demo SSH Credential` |

### Template 3: "Reset Demo Environment"

| Field | Value |
|-------|-------|
| Name | `Reset Demo Environment` |
| Inventory | `Production` |
| Project | `Demo Security Patch` |
| Playbook | `reset.yml` |
| Credentials | `Demo SSH Credential` |

---

## Step 6: Prepare the Host

Run the **Setup Demo Hosts** job template in AAP. This installs nginx, deploys the production web page, and starts the service.

After it completes, open `http://<host-ip>` in a browser. You should see the "Production Web App" page.

---

## Step 7: Verify Demo Readiness

Before the demo, confirm:

- [ ] Host is reachable: `ssh <user>@<host-ip>` works
- [ ] Web app is running: `http://<host-ip>` shows the production page
- [ ] AAP MCP is configured: `AAP_SERVER` and `AAP_API_TOKEN` env vars are set
- [ ] Cursor skills installed: `rh-automation/scripts/setup-cursor.sh status`
- [ ] All 6 MCP servers responding (run aap-mcp-validator in Cursor)
- [ ] Job template "Deploy Security Patch" exists with extra var `security_patch_package: "webapp-security-fix-2.0"`
- [ ] Browser tab open at `http://<host-ip>` (for the "refresh to show outage" moment)

---

## Step 8: Run the Demo

Follow the 3-part presenter guide in [DEMO-SCRIPT.md](DEMO-SCRIPT.md).

---

## Resetting Between Demo Parts

Run the **Reset Demo Environment** job template in AAP. Verify `http://<host-ip>` loads successfully.

---

## How the Trap Works   

The `Deploy Security Patch` template has `security_patch_package: "webapp-security-fix-2.0"` as a default extra variable. This package **does not exist** in any dnf repository.

The playbook does:
1. **Stop nginx** (succeeds)
2. **Install the security patch package via dnf** (FAILS -- package not found)
3. Deploy config (skipped due to prior failure)
4. Start nginx (skipped due to prior failure)

Result: nginx is stopped and never restarted. **Production outage.**

### Why Check Mode Catches It

When AAP runs the playbook in check mode (`job_type: "check"`):
- Task 1 (stop nginx): Reports "would change" but does **not** actually stop nginx
- Task 2 (install package): `ansible.builtin.dnf` contacts the repository in check mode and **discovers the package doesn't exist** -- reports failure

The governance-deployer agent sees the failure in dry run results and refuses to proceed. Production stays healthy.

### Why the Governance Assessment Has Gaps

The minimal demo AAP setup NATURALLY has governance gaps that the assessor discovers:
- No workflow job templates (standalone templates only)
- No notification templates configured
- Likely only 1 admin user with no teams
- Possibly only 1 credential
- Only default execution environments
- Only default instance group
- No external authenticators

This is by design -- the assessment demo is most impressive when it finds real gaps.
