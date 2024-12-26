#!/bin/bash

# Initialize variables
verbose=false
query=""
ip=""
port=""

# Function to print usage
usage() {
  echo "Usage: $0 --query '<query>' --ip <ip> --port <port> [-v]"
  echo "Options:"
  echo "  --query, -q    JSON file to send"
  echo "  --ip, -i       IP address of the server"
  echo "  --port, -p     Port of the server"
  echo "  -v             Enable verbose output"
  exit 1
}

# Parse named parameters
while [[ $# -gt 0 ]]; do
  case "$1" in
    --query|-q)
      query="$2"
      shift 2
      ;;
    --ip|-i)
      ip="$2"
      shift 2
      ;;
    --port|-p)
      port="$2"
      shift 2
      ;;
    -v)
      verbose=true
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      usage
      ;;
  esac
done

# Validate required parameters
if [[ -z "$query" || -z "$ip" || -z "$port" ]]; then
  if $verbose; then
    echo "Error: Missing required parameters."
  fi
  exit 1
fi

# Calculate the length of the query
query_length=$(cat $query | wc -c)

# Ensure the length fits into two bytes
if [[ "$query_length" -gt 65535 ]]; then
  if $verbose; then
    echo "Error: Query length exceeds 65535 bytes (two bytes max)."
  fi
  exit 2
fi

# Convert length to exactly 2 bytes in binary format
length_prefix=$(printf '\\x%02X\\x%02X' $((query_length >> 8)) $((query_length & 0xFF)))

# Create a temporary file for the packet
temp_file=$(mktemp)

# Write the 2-byte length prefix and the query into the temporary file
{
  echo -ne "$length_prefix"
  cat $query
} > "$temp_file"

# Optional verbose debugging output
if $verbose; then
  echo "Packet created:"
  hexdump -C "$temp_file"
  echo "Sending to $ip:$port..."
fi

# Send the packet using nc and capture the response
response=$(nc "$ip" "$port" < "$temp_file" 2>/dev/null)

# Check the success of the operation
if [[ $? -eq 0 ]]; then
  # Clean up and print the response
  rm -f "$temp_file"
  echo "$response"
  exit 0
else
  # Handle errors
  rm -f "$temp_file"
  if $verbose; then
    echo "Error: Failed to send packet or receive response."
  fi
  exit 3
fi
