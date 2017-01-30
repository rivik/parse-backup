#!/bin/bash
db=$1
if [ -z "$db" ]; then
    echo "Usage: cd parse-backup-jsons; $0 <db>"
fi

for i in *.json.*; do
    coll=${i%%.json*}
    jq -c -M '.results' $i | sed 's/"createdAt"/"_created_at"/g; s/"updatedAt"/"_updated_at"/g; s/"objectId"/"_id"/g' | mongoimport --db $db --collection $coll --type json --jsonArray --stopOnError -vvvv
done
