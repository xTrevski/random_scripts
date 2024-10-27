#!/usr/binenv sh

# File containing the list of domains
domain_file="domains.txt"

# Lists to store failed domains
failed_spf=()
failed_dmarc=()

# Function to set color
set_color() {
  case $1 in
    red) tput setaf 1 ; tput bold ;;
    green) tput setaf 2 ; tput bold ;;
    reset) tput sgr0 ;;
  esac
}

# Function to check SPF record
check_spf() {
  domain=$1
  spf_record=$(dig +short TXT "$domain" | grep 'v=spf1')
  if [ -n "$spf_record" ]; then
    spf_status="PASS"
    spf_color="green"
  else
    spf_status="FAIL"
    spf_color="red"
    failed_spf+=("$domain")
  fi
}

# Function to check DMARC record
check_dmarc() {
  domain=$1
  dmarc_record=$(dig +short TXT "_dmarc.$domain" | grep 'v=DMARC1')
  if [[ "$dmarc_record" == *"v=DMARC1"* ]]; then
    dmarc_status="PASS"
    dmarc_color="green"
  else
    dmarc_status="FAIL"
    dmarc_color="red"
    failed_dmarc+=("$domain")
  fi
}

# Read the domain file line by line
while IFS= read -r domain; do
  check_spf "$domain"
  check_dmarc "$domain"
  printf "%-40s" "$domain"
  printf "SPF:"
  set_color $spf_color
  printf "[$spf_status]"
  set_color reset
  printf "  DMARC:"
  set_color $dmarc_color
  printf "%-10s\n" "[$dmarc_status]"
  set_color reset
done < "$domain_file"

# Print summary of failed domains
if [ ${#failed_spf[@]} -ne 0 ]; then
  echo -e "\nSummary of domains that failed SPF check:"
  for domain in "${failed_spf[@]}"; do
    echo "$domain"
  done
else
  echo -e "\nAll domains passed the SPF check."
fi

if [ ${#failed_dmarc[@]} -ne 0 ]; then
  echo -e "\nSummary of domains that failed DMARC check:"
  for domain in "${failed_dmarc[@]}"; do
    echo "$domain"
  done
else
  echo -e "\nAll domains passed the DMARC check."
fi

# Uncomment to Send email if there are any failed results
#if [ ${#failed_spf[@]} -ne 0 ] || [ ${#failed_dmarc[@]} -ne 0 ]; then
#  email_body="The following domains failed email security check\n\nMissing SPF:\n$(printf "%s\n" "${failed_spf[@]}")\n\nMissing DMARC:\n$(printf "%s\n" "${failed_dmarc[@]}")"
#  swaks --to someone@example.com --from someone@example.com --server smtp.example.com:587 --auth LOGIN --auth-user someuser --auth-password somepasswd --header "Subject: Domain Email Security Check Failures" --body "$email_body" -tls > /dev/null 2>&1
#fi
