#!/bin/bash

# Debug
#set -x
set -Eeo pipefail

################################################################################
TRANSPORT="https://"
DOMAIN="bash.ws"
################################################################################

# TODO: Make sure ping exists
# TODO: Check internet connection

ID=0
# Generate random ID between 1000000-9999999
if command -v openssl &> /dev/null; then
  # If openssl present, generate number with it
  while [ 1000000 -gt "$ID" ]; do
    ID=$(openssl rand -hex 50 | tr -cd "[:digit:]" | head -c 7)
  done
elif command -v shuf &> /dev/null; then
  # If no openssl, but shuf exists
  ID=$(shuf -n 1 -i 1000000-9999999)
elif [ -n "$RANDOM" ]; then
  ID=$(echo "$((1000000 + RANDOM * 1000 + RANDOM))" | head -c 7)
else
  # If no standard programs, use proc uuid to generate random
  while [ 1000000 -gt "$ID" ]; do
    ID=$(tr -cd "[:digit:]" < /proc/sys/kernel/random/uuid | head -c 7)
  done
fi

# Send 10 pings with your ID
for i in $(seq 1 10); do
  ping -c 1 "${i}.${ID}.${DOMAIN}" > /dev/null 2>&1 || true
done

# Save results to a file
RESULTS=$(mktemp || exit 1)
LINK="${TRANSPORT}${DOMAIN}/dnsleak/test/${ID}?txt"
if command -v curl &> /dev/null; then
#if command -v curl &> /dev/null; then
  # If curl exists, use it
  curl --silent "$LINK" -o "$RESULTS"
elif command -v wget &> /dev/null; then
  # Use wget as a backup
  wget -q "$LINK" -O "$RESULTS"
else
  echo "Error, curl or wget required to download the results!"
  exit 1
fi
# TODO: Check downloaded file validity

# Help print a server line based on what info is present, pass a LINE (arg $1)
print_ip() {
  local LINE="$1"
  [ -n "$LINE" ] || (echo "Error, no line passed to print_ip()"; exit 1)
  IP=$(echo "$LINE" | cut -d "|" -f 1)
  COUNTRY=$(echo "$LINE" | cut -d "|" -f 3)
  ASN=$(echo "$LINE" | cut -d "|" -f 4)
  if [ -z "$IP" ]; then
    echo "NO IP"
  elif [ -z "$COUNTRY" ] && [ -z "$ASN" ]; then
    echo "$IP"
  elif [ -z "$COUNTRY" ] || [ -z "$ASN" ]; then
    echo "$IP | ${COUNTRY}${ASN}"
  else
    echo "$IP | ${COUNTRY} | ${ASN}"
  fi
}

# Unpack the text file and print the servers
while IFS= read -r LINE; do
  # Check for line type
  TYPE=$(echo "$LINE" | cut -d "|" -f 5)
  if [[ "$TYPE" == "ip" ]]; then
    echo "Your IP: "
    print_ip "$LINE"
    echo -e "\nYour DNS Server(s):"
  elif [[ "$TYPE" == "conclusion" ]]; then
    echo -e "\nConclusion: $(echo "$LINE" | cut -d "|" -f 1)"
  elif [[ "$TYPE" == "dns" ]]; then
    print_ip "$LINE"
  else
    echo "Error encountered for line: $LINE"
  fi
done < "$RESULTS"

# Delete temp file
rm -f "$RESULTS"
