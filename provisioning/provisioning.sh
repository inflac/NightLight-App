#!/bin/bash

# Function to generate a random IV (16 bytes base64 encoded)
generate_random_iv() {
  openssl rand -base64 16
}

# Function to hash a string with sha256
hash_sha256() {
  echo -n "$1" | sha256sum | awk '{print $1}'
}

# Function to encrypt the API-Key with AES-256 CBC (requires OpenSSL)
encrypt_api_key() {
  local key=$1
  local iv=$(echo "$2" | base64 -d | xxd -p | tr -d '\n')
  local api_key=$3

  # Apply PKCS#7 padding (OpenSSL's enc command does this automatically for block ciphers)
  # Encrypt the API-Key with AES-256-CBC mode
  echo -n "$api_key" | openssl enc -aes-256-cbc -a -K "$key" -iv "$iv"
}

# Main function
main() {
  gen_api_key=false

  # Get the application password
  read -p "Enter the preferred APP Password: " app_pw

  if [[ -z "$app_pw" ]]; then
    echo "Password length can't be 0. You need to set a password"
    exit 1
  elif [[ ${#app_pw} -le 8 ]]; then
    echo "WARNING: The entered password is weak"
  fi

  # Hash the password using SHA256
  app_pw_hash=$(hash_sha256 "$app_pw")

  # Get the API-Key from the user or generate a random one
  read -p "Enter your API-Key (leave blank for a random one): " api_key
  if [[ -z "$api_key" ]]; then
    api_key="nl-$(openssl rand -base64 2045)"
    gen_api_key=true
  elif [[ ${#api_key} -le 32 ]]; then
    echo "WARNING: The entered API-Key is weak"
  fi

  # Get or generate the IV (Initialization Vector)
  read -p "Enter your IV (base64 encoded) (leave blank for random): " iv
  if [[ -z "$iv" ]]; then
    iv=$(generate_random_iv)
  elif [[ ${#iv} -lt 24 ]]; then
    echo "The IV needs to be a 16-Byte value, encoded as base64"
    exit 1
  fi

  # Encrypt the API-Key
  encrypted_api_key=$(encrypt_api_key "$app_pw_hash" "$iv" "$api_key")

  # Print the results
  echo -e "\n\n#### Provisioning Data ####\n"
  if $gen_api_key; then
    echo "Generated API-Key: $api_key"
  fi
  echo "ENC_API_KEY: $encrypted_api_key"
  echo "AES_IV: $iv"
}

# Call the main function
main
