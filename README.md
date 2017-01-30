# parse-backup - quick and dirty big parse db downloader
```bash
apt-get install perl curl jq
# fix hardcoded tokens and @classes list in parse-backup.pl first
./parse-backup.pl >>log 2>&1
./upload-to-mongo.sh >>upload.log 2>&1
```
