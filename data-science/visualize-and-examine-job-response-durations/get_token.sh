#!/usr/bin/env sh
# Generate an access_token scoped to the libreBaas client

# Rhize Configuration
USERNAME=""
PASSWORD=""
CLIENT_ID=""
CLIENT_SECRET=""
URL=""



curl --location --request POST "$URL/realms/libre/protocol/openid-connect/token" \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=password' \
--data-urlencode "username=$USERNAME" \
--data-urlencode "password=$PASSWORD" \
--data-urlencode "client_id=$CLIENT_ID" \
--data-urlencode "client_secret=$CLIENT_SECRET" \
2>/dev/null
