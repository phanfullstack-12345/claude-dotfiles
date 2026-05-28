# Reference: linux-guide
# Load this file when working on tasks matching this domain.

## 💻 Terminal & Shell Skills

### Navigation & Files
```bash
# Find files
find . -name "*.ts" -not -path "*/node_modules/*"
fd "*.ts" --exclude node_modules          # fd is faster than find

# Search content
grep -r "TODO" src/ --include="*.ts"
rg "functionName" src/                    # ripgrep — fastest

# File operations
ls -la                                    # detailed listing
tree -L 2 --gitignore                     # directory tree
du -sh */ | sort -rh                      # disk usage by folder
stat filename                             # file metadata

# Permissions
chmod 755 script.sh                       # rwxr-xr-x
chmod 644 config.json                     # rw-r--r--
chown user:group file                     # change owner
```

### Process Management
```bash
ps aux | grep node                        # find processes
lsof -i :3000                            # what's using port 3000
kill -9 PID                              # force kill process
pkill -f "node server.js"               # kill by name
nohup ./script.sh &                      # run in background, survive logout
jobs                                     # list background jobs
fg %1                                    # bring job to foreground
```

### Networking
```bash
curl -X POST https://api.example.com/endpoint \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"key": "value"}' | jq .

wget -O output.file https://example.com/file

# Check connectivity
ping -c 4 google.com
traceroute google.com
nslookup domain.com
dig domain.com A

# Ports & connections
netstat -tlnp                            # listening ports
ss -tlnp                                 # modern netstat
```

### Text Processing
```bash
cat file | grep "error" | sort | uniq -c | sort -rn   # frequency count
awk '{print $1, $3}' file.txt            # print columns
sed -i 's/old/new/g' file.txt            # in-place replace
cut -d',' -f1,3 data.csv                 # CSV column extraction
jq '.users[] | .name' data.json          # JSON processing
wc -l file.txt                           # line count
head -20 / tail -20                      # first/last lines
less +F logfile.log                      # tail -f equivalent with scroll
```

### SSH
```bash
ssh user@host -p 22                      # connect
ssh -i ~/.ssh/key.pem user@host          # with key file
ssh -L 5432:localhost:5432 user@host     # local port forwarding (tunnel DB)
ssh -R 8080:localhost:3000 user@host     # remote port forwarding
scp -r ./dist user@host:/var/www/        # copy files to server
rsync -avz --exclude node_modules ./src user@host:/app/  # sync files

# SSH config (~/.ssh/config)
# Host myserver
#   HostName 192.168.1.100
#   User deploy
#   IdentityFile ~/.ssh/deploy_key
#   Port 22
```

### Environment & Variables
```bash
export VAR=value                         # set env var for session
echo $VAR                                # print var
printenv                                 # all env vars
source .env                              # load .env file
env VAR=value command                    # set var for single command
unset VAR                                # remove var
```

### Useful One-Liners
```bash
# Watch a command output every 2s
watch -n 2 "docker ps"

# Run command on file change
while inotifywait -e modify file.ts; do npm run build; done

# Generate a random secret
openssl rand -hex 32

# Base64 encode/decode
echo "hello" | base64
echo "aGVsbG8=" | base64 -d

# Timestamps
date +%Y-%m-%d_%H-%M-%S

# Disk space
df -h
ncdu /var/log                            # interactive disk usage
```

---

## 🐧 Ubuntu / Linux Server Skills

### System Setup & Updates
```bash
# Update system
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y && sudo apt clean

# Install essentials
sudo apt install -y \
  curl wget git vim htop tmux \
  build-essential software-properties-common \
  ufw fail2ban unattended-upgrades \
  net-tools dnsutils jq tree

# Check OS version
lsb_release -a
uname -r                                 # kernel version
```

### User Management
```bash
# Create deploy user (never run app as root)
sudo adduser deploy
sudo usermod -aG sudo deploy             # add to sudo group
sudo usermod -aG docker deploy           # add to docker group

# SSH key setup for user
sudo mkdir -p /home/deploy/.ssh
sudo cp ~/.ssh/authorized_keys /home/deploy/.ssh/
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

### Firewall (UFW)
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh                       # port 22
sudo ufw allow 80/tcp                    # HTTP
sudo ufw allow 443/tcp                   # HTTPS
sudo ufw allow from 10.0.0.0/8 to any port 5432  # PostgreSQL — private network only
sudo ufw enable
sudo ufw status verbose
```

### Nginx
```bash
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

# Config location
/etc/nginx/nginx.conf                    # main config
/etc/nginx/sites-available/             # site configs
/etc/nginx/sites-enabled/               # symlinked active configs

# Enable a site
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t                            # test config
sudo systemctl reload nginx             # reload without downtime
```

```nginx
# /etc/nginx/sites-available/myapp
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;  # force HTTPS
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### SSL — Let's Encrypt (Certbot)
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d example.com -d www.example.com
sudo certbot renew --dry-run             # test auto-renewal
# Auto-renewal via systemd timer is set up automatically
```

### Systemd Services (Run App as Service)
```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Node.js App
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/app
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=myapp
Environment=NODE_ENV=production
EnvironmentFile=/home/deploy/app/.env

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
sudo systemctl status myapp
journalctl -u myapp -f                  # follow logs
```

### Log Management
```bash
# View logs
journalctl -u nginx --since "1 hour ago"
journalctl -f                            # follow all system logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Log rotation — /etc/logrotate.d/myapp
/home/deploy/app/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        systemctl reload myapp
    endscript
}
```

### Performance & Monitoring
```bash
htop                                     # interactive process monitor
iotop                                    # disk I/O monitor
nethogs                                  # network usage by process
vmstat 1                                 # CPU/memory/IO stats every 1s
iostat -xz 1                            # disk stats
free -h                                  # memory usage
df -h                                    # disk space

# Check what's eating resources
top -b -n 1 | head -20
ps aux --sort=-%mem | head -10          # top memory consumers
ps aux --sort=-%cpu | head -10          # top CPU consumers
```

### Security Hardening
```bash
# Disable root SSH login and password auth
sudo vim /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes
sudo systemctl restart sshd

# Fail2ban for brute force protection
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status sshd

# Automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Audit open ports
sudo ss -tlnp
sudo nmap -sV localhost
```

### Node.js on Ubuntu
```bash
# Install Node via nvm (preferred — version manageable)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
nvm alias default 20

# Install pnpm
npm install -g pnpm

# PM2 for process management (alternative to systemd for Node)
npm install -g pm2
pm2 start dist/index.js --name myapp
pm2 startup                              # generate startup script
pm2 save                                 # save process list
pm2 logs myapp                          # view logs
pm2 monit                               # monitor dashboard
```

### Server Maintenance Checklist
- [ ] OS packages updated (`apt update && apt upgrade`)
- [ ] SSL certificates valid and auto-renewing
- [ ] Disk space > 20% free (`df -h`)
- [ ] Backups verified and restorable
- [ ] Firewall rules audited (`ufw status`)
- [ ] Failed login attempts reviewed (`fail2ban-client status`)
- [ ] Application logs checked for errors
- [ ] Memory/CPU baseline normal (`htop`)

---

