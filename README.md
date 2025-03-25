### About
This script downloads the AbuseIPDB database and imports it into CrowdSec

### Requirements
1. CrowdSec must be installed natively on the system, not in Docker
2. [Node.js](https://nodejs.org/en) must be installed


### How to use
Clone the repo and go into:
```bash
git clone https://github.com/goremykin/crowdsec-abuseipdb-blocklist.git
cd crowdsec-abuseipdb-blocklist
```

Copy the config template:
```bash
cp config.template.json config.json
```

Edit the config with your favorite text editor:
```bash
nano config.json
```

Open the root user's crontab for editing:
```bash
sudo crontab -e
```

Add this to the end and save:
```
0 2 * * * /bin/node <PATH_TO_REPO>/index.mjs
```
