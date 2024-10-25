#!/usr/bin/env bash

# File containing the list of domains
domain_file="domains.txt"

# List to store failed domains
failed_domains=()

# Function to check SPF record
check_spf() {
  domain=$1
  spf_record=$(dig +short TXT "$domain" | grep 'v=spf1')
  if [ -n "$spf_record" ]; then
    echo -e "$domain: \033[32m[Pass]\033[0m"
  else
    echo -e "$domain: \033[31m[Fail]\033[0m"
    failed_domains+=("$domain")
  fi
}

# Read the domain file line by line
while IFS= read -r domain; do
  check_spf "$domain"
done < "$domain_file"

# Print summary of failed domains
if [ ${#failed_domains[@]} -ne 0 ]; then
  echo -e "\nSummary of failed domains:"
  for failed_domain in "${failed_domains[@]}"; do
    echo "$failed_domain"
  done
else
  echo -e "\nAll domains passed the SPF check."
fi

