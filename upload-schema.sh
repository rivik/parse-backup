for class in $(jq '.results[].className' < schema ); do
    class=$(echo $class | sed 's/"//g')
    jq ".results[] | select(.className == "'"'"$class"'"'") | del(.fields.password) | del(.fields.username) | del(.fields.roles) | del(.fields.users) | del(.fields.user) | del(.fields.ACL) | del(.fields.sessionToken) | del(.fields.appName) | del(.fileds.user) | del(.fields.appVersion) | del(.fileds.badge) | del(.fields.restricted) | del(.fields.emailVerified) | del(.fields.installationId) | del(.fields.appIdentifier) | del(.fields.email) | del(.fields.name) | del(.fields.createdWith) | del(.fields.objectId) | del(.fields.createdAt) | del(.fields.updatedAt) | del(.fields.expiresAt) | del(.fields.GCMSenderId) | del(.fields.authData)" < schema > schema.$class

    curl -X POST \
    -H "X-Parse-Application-Id: "   -H "X-Parse-Master-Key: "  \
    -H "Content-Type: application/json" \
    -d "@schema.$class" \
    https://myparse/schemas/$class
    echo "done $class"
done
