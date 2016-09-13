# teamcity-backup
Bash script for TeamCity backup

### Requirements
* bash

### Installation
Adjust for your needs variables in **teamcity-backup.sh**:
```bash
TC_INSTALL_DIR
TC_BACKUP_DIR
TC_BACKUP_FILE_NAME
```
Modify cron for needed user (for example _www_):
```bash
crontab -u www -e
```
For every day backup in 01.00 add line:
```bash
0	1	*	*	*	/full_path_to/teamcity-backup.sh -d >>/var/log/teamcity-backup.log 2>&1
```
