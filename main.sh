#!/bin/bash

# Set Default Value
input_file="input.txt"
output_file="output.txt"
available_file="available.txt"
domain_suffix=""
non_domain=false
sleep_time=5

# Function Helper
show_help() {
    echo -e "\e[32m\nUsage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -i, --input FILE     Input file (default: input.txt)"
    echo "  -o, --output FILE    Output file (default: output.txt)"
    echo "  -a, --available FILE    Available file (default: available.txt)"
    echo "  -s, --sleep TIME    Sleep time between checks in seconds (default: 5)"
    echo "  -N, --non-domain SUFFIX  Add suffix to domains (e.g., .com, .net)"
    echo "  -h, --help          Show this help message"
    echo
    echo "Example:"
    echo "  $0 -i domains.txt -o results.txt -s 0.5"
    echo "  $0 --non-domain .com -i names.txt -o output.txt"
    echo -e "\n\e[0m"
}

# Process Arguments Main
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            input_file="$2"
            shift 2
            ;;
        -o|--output)
            output_file="$2"
            shift 2
            ;;
        -a|--available)
            available_file="$2"
            shift 2
            ;;
        -s|--sleep)
            if ! [[ "$2" =~ ^[0-9]*\.?[0-9]+$ ]]; then
                echo "Error: Sleep time must be a number"
                exit 1
            fi
            sleep_time="$2"
            shift 2
            ;;
        -N|--non-domain)
            non_domain=true
            domain_suffix="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validation Input File
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found!"
    exit 1
fi

# Delete Output File / Available file
> "$output_file"
> "$available_file"

# Validation Domain Checker (Main Function)
check_domain() {
    local domain="$1"
    local whois_result
    
    # Add Prefix Domain
    if [ "$non_domain" = true ]; then
        domain="${domain}${domain_suffix}"
    fi
    
    echo -n "Checking domain: $domain "
    
    whois_result=$(whois "$domain" 2>&1)
    
    if echo "$whois_result" | grep -iE "No match|NOT FOUND|No entries found|Domain not found|Status: AVAILABLE|Status: free" > /dev/null; then
        echo "Available: $domain" >> "$output_file"
        echo "$domain" >> "$available_file"
        echo -e " \e[32m[Available ✓]\e[0m"
    else
        echo "Taken: $domain" >> "$output_file"
        echo -e " \e[31m[Taken ✗]\e[0m"
    fi
    
    sleep "$sleep_time"
}

# Display Start
echo "Starting domain check..."
echo "Input file: $input_file"
echo "Output file: $output_file"
echo "Available file: $available_file"
if [ "$non_domain" = true ]; then
    echo "Adding suffix: $domain_suffix to all domains"
fi
echo "----------------------------------------"

# Calculate Total Domain And Time Reminde
total_domains=$(wc -l < "$input_file")
estimated_time=$(echo "$total_domains * $sleep_time" | bc)
echo "Total domains to check: $total_domains"
echo "Estimated time: ${estimated_time} seconds"
echo "----------------------------------------"

current_domain=0

# Processes Main
while IFS= read -r domain || [[ -n "$domain" ]]; do
    domain=$(echo "$domain" | tr -d '[:space:]')
    if [ ! -z "$domain" ]; then
        ((current_domain++))
        echo -n "[$current_domain/$total_domains] "
        check_domain "$domain"
    fi
done < "$input_file"

# Resluts
echo -e "\nResults:"
echo "----------------------------------------"
echo "Total domains checked: $(wc -l < "$input_file")"
echo "Available domains: $(grep -c "Available:" "$output_file")"
echo "Taken domains: $(grep -c "Taken:" "$output_file")"
echo "Results All saved in: $output_file"
echo "Available saved in: $available_file"
