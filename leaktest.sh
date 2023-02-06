#!/bin/sh
# Busybox-compatible, lightweight, and POSIX-compatible DNS Leak Test script

# Env vars
set -eu
if (set -o pipefail 2> /dev/null); then
  set -o pipefail
fi
if (set -E 2> /dev/null); then
  set -E
fi

# Error handler
err() {
  if command -v date > /dev/null 2>&1; then
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
  else
    echo "[leaktest.sh]: $*" >&2
  fi
  exit 1
}

# Function to check for command line tools
available() {
  for pkg in "$@"; do
    if ! command -v "$pkg" > /dev/null 2>&1; then
      err "Error, missing a vital package to run: $pkg"
    fi
  done
}

# Check for all mandatory tools
available \
  "cut" \
  "echo" \
  "grep" \
  "head" \
  "mktemp" \
  "ping" \
  "tr"

# Leaktest site
transport="https://"
domain="bash.ws"

# Start test
echo "Checking for network connection..."

# Prep for download and get a header
results=$(mktemp || err "Error, unable to create temp file with mktemp")
link="${transport}${domain}"
# Check internet connection
if command -v curl > /dev/null 2>&1; then
  # If curl exists, use it
  curl --silent --head "$link" -o "$results" || \
    err "Error, timeout while testing internet connection with curl"
elif command -v wget > /dev/null 2>&1; then
  # Use wget as a backup, test for header tools
  if wget --help 2>&1 | grep -qF "save-header"; then
    # If full-blown wget available, save the header and check
    wget -q --save-header "$link" -O "$results" || \
      err "Error, timeout while testing internet connection with wget"
  else
    # If basic wget only, don't get header, just get site
    wget -q "$link" -O "$results" || \
      err "Error, timeout while reading ${transport}${domain} with wget"
  fi
else
  err "Error, curl or wget required"
fi

# Test header
if grep -qF "200 OK" "$results" || grep -qF "DNS leak test" "$results"; then
  echo "Connected to internet, getting DNS results...
  "
else
  err "Error, failed to connect to testing domain: ${transport}${domain}"
fi

# Generate random id between 1000000-9999999
id=0
if command -v openssl > /dev/null 2>&1; then
  # If openssl present, generate number with it
  while [ 1000000 -gt "$id" ]; do
    id=$(openssl rand -hex 50 | tr -cd '0-9' | head -c 7)
  done
elif command -v shuf > /dev/null 2>&1; then
  # If no openssl, but shuf exists
  id=$(shuf -n 1 -i 1000000-9999999)
else
  # If no standard programs, use proc uuid to generate random
  while [ 1000000 -gt "$id" ]; do
    id=$(tr -cd '0-9' < /proc/sys/kernel/random/uuid | head -c 7)
  done
fi

# Send 10 pings with your id
for i in $(seq 1 10); do
  ping -c 1 "${i}.${id}.${domain}" > /dev/null 2>&1 || true
done

# Save results to a file
[ -f "$results" ] && rm -f "$results"
link="${transport}${domain}/dnsleak/test/${id}?txt"
if command -v curl > /dev/null 2>&1; then
  # If curl exists, use it
  curl --silent "$link" -o "$results"
elif command -v wget > /dev/null 2>&1; then
  # Use wget as a backup
  wget -q "$link" -O "$results"
fi
if [ ! -s "$results" ]; then
  err "Error, failed to download results of DNS Leak test"
fi

# Help print a server line based on what info is present, pass a line (arg $1)
print_ip() {
  [ -n "$1" ] || err "Error, no line passed to print_ip()"
  ip=$(echo "$1" | cut -d "|" -f 1)
  country=$(echo "$1" | cut -d "|" -f 3)
  asn=$(echo "$1" | cut -d "|" -f 4)
  if [ -z "$ip" ]; then
    echo "NO IP"
  elif [ -z "$country" ] && [ -z "$asn" ]; then
    echo "$ip"
  elif [ -z "$country" ] || [ -z "$asn" ]; then
    echo "$ip | ${country}${asn}"
  else
    echo "$ip | ${country} | ${asn}"
  fi
}

# Unpack the text file and print the servers
while IFS= read -r line; do
  # Check for line type
  type=$(echo "$line" | cut -d "|" -f 5)
  if echo "$type" | grep -qxF "ip"; then
    echo "Your IP: "
    print_ip "$line"
    echo "
Your DNS Server(s):"
  elif echo "$type" | grep -qxF "conclusion"; then
    echo "
Conclusion: $(echo "$line" | cut -d "|" -f 1)"
  elif echo "$type" | grep -qxF "dns"; then
    print_ip "$line"
  else
    echo "Error encountered for line: $line"
  fi
done < "$results"

# Delete temp file
rm -f "$results"
