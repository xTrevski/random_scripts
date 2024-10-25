#!/usr/bin/env bash

# Define the IP range
start_ip=1
end_ip=25
base_ip="123.123.1123"
port="443"

# Pretty Colours
red='\033[4;91m'
green='\033[4;92m'
nocol='\033[0m'

# Function to check SSL certificate
check_certificate() {
    local ip="$1"
    echo "Checking IP: $ip:$port"
    
    # Fetch the certificate details using openssl with a timeout of 10 seconds
    cert_details=$(timeout 10s openssl s_client -connect "$ip:$port" -servername "$ip" 2>/dev/null | openssl x509 -noout -issuer -subject -dates 2>/dev/null)

    if [ -z "$cert_details" ]; then
        echo -e "No certificate found or unable to connect within the timeout period. \n"
        return
    fi
    
    # Extract the certificate expiration date
    expiry_date=$(echo "$cert_details" | grep 'notAfter=' | sed 's/notAfter=//')
    
    # Convert expiration date to timestamp
    expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
    
    if [ -z "$expiry_timestamp" ]; then
        echo "Unable to parse certificate expiration date."
        echo "$cert_details"
        return
    fi

    # Get the current date as a timestamp
    current_timestamp=$(date +%s)

    # Compare the expiration timestamp with the current timestamp
    if [ "$expiry_timestamp" -lt "$current_timestamp" ]; then
        echo -e "Certificate has ${red}EXPIRED${nocol}."
    else
        echo -e "Certificate is ${green}VALID${nocol}."
    fi
    
    # Print certificate details
    echo "Certificate details:"
    echo "$cert_details"
    echo
}

# Iterate over the IP range
for ip_suffix in $(seq "$start_ip" "$end_ip"); do
    ip="$base_ip.$ip_suffix"
    check_certificate "$ip"
done
