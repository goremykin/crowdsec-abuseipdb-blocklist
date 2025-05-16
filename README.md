### About
This script downloads the AbuseIPDB database and imports it into CrowdSec

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

| Field Name                | Required / Optional                               | Description                                                                                |
|---------------------------|---------------------------------------------------|--------------------------------------------------------------------------------------------|
| `apiKey`                  | Required if you use import_abuseipdb_blocklist.sh | AbuseIPDB api key                                                                          |
| `confidenceMinimum`       | Optional, 75 by default                           | [What is the "Confidence of Abuse" rating?](https://www.abuseipdb.com/faq.html#confidence) |
| `banDuration`             | Optional, 24h by default                          | Ban duration                                                                               |
| `borestadBlocklistPeriod` | Optional, 7d by default                           | Read more in [borestad repo](https://github.com/borestad/blocklist-abuseipdb)              |
| `crowdsecContainerName`   | Required if you use CrowdSec in docker            | The name of the docker container in which CrowdSec is running                              |

Open the root user's crontab for editing:
```bash
sudo crontab -e
```

Add this to the end and save if you want to import AbuseIPDB block list:
```
0 2 * * * /bin/bash <PATH_TO_REPO>/import_abuseipdb_blocklist.sh
```

Or this if you want to import [borestad/blocklist-abuseipdb](https://github.com/borestad/blocklist-abuseipdb) block list:
```
0 2 * * * /bin/bash <PATH_TO_REPO>/import_borestad_blocklist.sh
```