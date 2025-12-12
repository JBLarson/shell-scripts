#!/bin/sh
# Whois domain lookup with formatted output for key registration details

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

# Perform the whois query
WHOIS_OUTPUT=$(whois "$DOMAIN")

# Extract the needed information using grep and sed
DOMAIN_NAME=$(echo "$WHOIS_OUTPUT" | grep -i "Domain Name:" | sed 's/Domain Name: //I')
REGISTRAR=$(echo "$WHOIS_OUTPUT" | grep -i "Registrar:" | sed 's/Registrar: //I')
CREATION_DATE=$(echo "$WHOIS_OUTPUT" | grep -i "Creation Date:" | sed 's/Creation Date: //I')
EXPIRY_DATE=$(echo "$WHOIS_OUTPUT" | grep -i "Registry Expiry Date:" | sed 's/Registry Expiry Date: //I')
NAME_SERVERS=$(echo "$WHOIS_OUTPUT" | grep -i "Name Server:" | sed 's/Name Server: //I')

# Output the extracted data
echo "Domain Name: $DOMAIN_NAME"
echo "Registrar: $REGISTRAR"
echo "Creation Date: $CREATION_DATE"
echo "Expiry Date: $EXPIRY_DATE"
echo "Name Servers:"
echo "$NAME_SERVERS" | while read -r line; do
    echo "  - $line"
done
