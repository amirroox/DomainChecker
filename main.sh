#!/bin/bash

if [ $# -ne 3 ] || [ "$2" != "-o" ]; then
    echo "Usage: $0 input_file -o output_file"
    exit 1
fi

input_file="$1"
output_file="$3"

# Check Input File
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found!"
    exit 1
fi

# Delete Output File (Last)
> "$output_file"

# Main Function For Check Domain
check_domain() {
    local domain="$1"
    local whois_result
    
    echo -n "Checking domain: $domain"
    
    whois_result=$(whois "$domain" 2>&1)
    
    # Check Domain
    if echo "$whois_result" | grep -iE "No match|NOT FOUND|No entries found|Domain not found|Status: AVAILABLE|Status: free" > /dev/null; then
        echo "Available: $domain" >> "$output_file"
        echo -e " \e[32m[Available ✓]\e[0m"
    else
        echo "Taken: $domain" >> "$output_file"
        echo -e " \e[31m[Taken ✗]\e[0m"
    fi
    
    # Time Out
    sleep 5
}

# Read Domain With File
while IFS= read -r domain || [[ -n "$domain" ]]; do
    # Delete Space
    domain=$(echo "$domain" | tr -d '[:space:]')
    if [ ! -z "$domain" ]; then
        check_domain "$domain"
    fi
done < "$input_file"

echo "Done! Results saved in $output_file"

# Summary Result
echo -e "\nSummary:"
echo "Available domains: $(grep -c "Available:" "$output_file")"
echo "Taken domains: $(grep -c "Taken:" "$output_file")"
