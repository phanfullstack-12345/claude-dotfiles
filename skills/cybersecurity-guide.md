# Reference: cybersecurity-guide
# Load this file when working on tasks matching this domain.

## 🛡️ Cybersecurity Engineering

### Methodology: Offensive → Defensive Thinking
- Think like an attacker to build defenses — every feature is a potential attack surface.
- Security = process, not a product. It's never "done".
- Defense in depth: multiple independent controls — if one fails, others hold.
- Assume breach: design systems that limit blast radius when (not if) something is compromised.

### Penetration Testing Methodology (PTES / OWASP)
```
1. Reconnaissance    → passive (OSINT, Shodan, Censys) + active (nmap, nessus)
2. Scanning          → ports, services, versions, OS fingerprinting
3. Enumeration       → users, shares, services, subdomains, directories
4. Exploitation      → use found vulns; never in prod without written authorization
5. Post-exploitation → persistence, lateral movement, privilege escalation
6. Reporting         → severity rating, PoC, remediation steps
```

**Authorization in writing** before any active testing — never assume.

### Web Application Security Testing

#### Recon & Discovery
```bash
# Subdomain enumeration
subfinder -d example.com -o subdomains.txt
amass enum -passive -d example.com

# Directory/endpoint discovery
ffuf -w /usr/share/wordlists/dirb/common.txt -u https://example.com/FUZZ
gobuster dir -u https://example.com -w wordlist.txt -x php,js,html

# JS analysis for hidden endpoints
cat app.js | grep -E "(api|endpoint|fetch|axios)" | sort -u

# Headers inspection
curl -sI https://example.com | grep -i "server\|x-powered\|x-frame"
```

#### Common Vulnerabilities (Testing)
```bash
# SQL Injection testing (authorized only)
sqlmap -u "https://example.com/users?id=1" --dbs --batch

# XSS payloads (test in isolated env)
# Reflected: "><script>alert(1)</script>
# DOM-based: #"><img src=x onerror=alert(1)>

# IDOR testing
# Enumerate IDs: /api/orders/1, /api/orders/2, /api/orders/3
# Try accessing other users' resources with your token

# JWT vulnerabilities
# Algorithm confusion: change alg to "none"
# Weak secret: crack with hashcat: hashcat -a 0 -m 16500 jwt.txt wordlist.txt

# SSRF
curl "https://example.com/fetch?url=http://169.254.169.254/latest/meta-data/"
```

#### OWASP ZAP (Automated DAST)
```bash
# Run full scan
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t https://staging.example.com \
  -r report.html \
  -I  # don't fail on warnings
```

### Network Security
```bash
# Port scanning
nmap -sV -sC -O -p- --min-rate 5000 target.com    # full version+script scan
nmap -sU --top-ports 100 target.com                 # UDP top ports
nmap --script vuln target.com                        # vulnerability scripts

# SSL/TLS analysis
testssl.sh target.com             # comprehensive TLS config check
sslyze target.com                 # fast TLS analysis

# Packet capture
tcpdump -i eth0 -w capture.pcap port 80 or port 443
wireshark capture.pcap            # GUI analysis

# Network monitoring (defensive)
zeek -i eth0                      # protocol analysis + logs
suricata -c suricata.yaml -i eth0 # IDS/IPS rules-based detection
```

### OSINT & Reconnaissance
```bash
# Google dorks
site:example.com filetype:pdf
site:example.com inurl:admin
"example.com" ext:env OR ext:config OR ext:yml

# Certificate transparency logs (find subdomains)
curl "https://crt.sh/?q=%.example.com&output=json" | jq '.[].name_value' | sort -u

# Shodan CLI
shodan search "hostname:example.com"
shodan host 1.2.3.4

# Email harvesting (OSINT)
theHarvester -d example.com -b google,linkedin,github
```

### Defensive Security Engineering

#### Security Information & Event Management (SIEM)
```yaml
# Detection rules pattern (Sigma format — portable across SIEM tools)
title: Brute Force Login Attempt
status: stable
logsource:
  category: authentication
detection:
  selection:
    EventID: 4625         # Windows failed login
  timeframe: 5m
  condition: selection | count() by SourceIP > 10
level: medium
```

#### Intrusion Detection
```bash
# Falco (runtime security for containers/K8s)
# Rule: alert on shell spawned in container
- rule: Shell Spawned in Container
  desc: A shell was spawned in a container
  condition: spawned_process and container and shell_procs
  output: "Shell spawned (user=%user.name container=%container.name)"
  priority: WARNING
```

#### Incident Response Toolkit
```bash
# Capture volatile data first (order of volatility)
1. Memory dump: avml memory.lime
2. Running processes: ps auxf > processes.txt
3. Network connections: ss -tupan > connections.txt
4. Logged-in users: w > users.txt
5. Open files: lsof > open_files.txt
6. Then disk image (non-volatile)

# Log analysis
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn
journalctl -u sshd --since "2024-01-01" | grep -i "failed\|invalid"
```

### Vulnerability Management
```bash
# CVE scanning
trivy image nginx:latest               # container CVEs
trivy fs .                             # filesystem/code CVEs
nuclei -u https://example.com         # template-based vuln scanning

# Dependency CVEs
grype .                                # any language
osv-scanner .                          # Google OSV database

# Infrastructure misconfiguration
checkov -d terraform/                  # IaC security
kube-bench                             # CIS K8s benchmark
aws-securityhub-findings               # AWS config compliance
```

### Security Hardening Baselines
- **CIS Benchmarks**: use for OS, K8s, cloud hardening checklists.
- **DISA STIGs**: DoD hardening guides — most comprehensive but complex.
- **NIST CSF**: Identify → Protect → Detect → Respond → Recover framework.
- Automate compliance checks in CI: `checkov`, `tfsec`, `kube-bench`, `lynis`.

---

