#!/bin/bash

# Default values
timestamp=$(date +%F_%H-%M-%S)
input_file="input.txt"
output_file="output_$timestamp.txt"
available_file="available_$timestamp.txt"
taken_file="taken_$timestamp.txt"
json_file=""
sleep_time=5
domain_suffix=""
non_domain=false
fast_mode=false
debug_mode=false
no_save_mode=false
interactive_mode=false
prefix=""

# Colors
green='\e[32m'
red='\e[31m'
cyan='\e[36m'
yellow='\e[33m'
blue='\e[34m'
reset='\e[0m'

# Notification / sound
sound_file="ding.mp3"
turn_sound=false
turn_notification=false

# Create directories for organized output
create_directories() {
    mkdir -p logs
    mkdir -p results
    mkdir -p available
    mkdir -p taken

    # Update file paths to use organized directories
    output_file="results/$output_file"
    available_file="available/$available_file"
    taken_file="taken/$taken_file"
    [ -n "$json_file" ] && json_file="results/$json_file"
}

# Show Help
show_help() {
    echo -e "${green}\nDomain Checker Script"
    echo -e "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -i, --input FILE            Input file (default: input.txt)"
    echo "  -o, --output FILE           Output file (default: output_TIMESTAMP.txt)"
    echo "  -a, --available FILE        Available file (default: available_TIMESTAMP.txt)"
    echo "  -t, --taken FILE            Taken file (default: taken_TIMESTAMP.txt)"
    echo "  -j, --json FILE             JSON output file (optional)"
    echo "  -s, --sleep TIME            Sleep time in seconds (default: 5)"
    echo "  -N, --non-domain SUFFIX     Add suffix (e.g. .com, .net)"
    echo "  -p, --prefix VALUE          Add prefix (e.g. www.)"
    echo "  --fast                      Fast mode (no sleep)"
    echo "  --no-save                   Do not save any output files"
    echo "  --debug                     Save raw whois logs"
    echo "  --interactive               Ask before saving available domain"
    echo "  --sound                     Turn on the sound"
    echo "  --notify                    Turn on the notification"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Files will be organized in subdirectories:"
    echo "  - results/    : Main output files"
    echo "  - available/  : Available domains"
    echo "  - taken/      : Taken domains"
    echo "  - logs/       : Debug logs"
    echo -e "${yellow}"
    echo "Example:"
    echo " ./main.sh -i names.txt --non-domain .com --json result.json -s 10"
    echo -e "${reset}"
}

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input) input_file="$2"; shift 2;;
        -o|--output) output_file="$2"; shift 2;;
        -a|--available) available_file="$2"; shift 2;;
        -t|--taken) taken_file="$2"; shift 2;;
        -j|--json) json_file="$2"; shift 2;;
        -s|--sleep) sleep_time="$2"; shift 2;;
        -N|--non-domain) non_domain=true; domain_suffix="$2"; shift 2;;
        -p|--prefix) prefix="$2"; shift 2;;
        --fast) fast_mode=true; sleep_time=0; shift;;
        --debug) debug_mode=true; shift;;
        --no-save) no_save_mode=true; debug_mode=false; json_file="/dev/null"; available_file="/dev/null"; taken_file="/dev/null"; output_file="/dev/null"; shift;;
        --interactive) interactive_mode=true; shift;;
        --sound) turn_sound=true; shift;;
        --notify) turn_notification=true; shift;;
        -h|--help) show_help; exit 0;;
        *) echo -e "${red}Unknown option: $1${reset}"; show_help; exit 1;;
    esac
done

# Validate input file
if [ ! -f "$input_file" ]; then
    echo -e "${red}Error: Input file '$input_file' not found!${reset}"
    exit 1
fi

# Check required tools
check_dependencies() {
    if ! command -v whois &> /dev/null; then
        echo -e "${red}Error: whois command not found. Please install whois package.${reset}"
        exit 1
    fi

    if ! command -v bc &> /dev/null; then
        echo -e "${yellow}Warning: bc command not found. Time calculations may not work properly.${reset}"
    fi
}

# check save
if [ "$no_save_mode" = false ]; then
  # Create organized directory structure
  create_directories

  # Clear output files
  true > "$output_file"
  true > "$available_file"
  true > "$taken_file"
  if [ -n "$json_file" ]; then
      echo "[" > "$json_file"
  fi
fi

# Enhanced domain checker with better error handling
check_domain() {
    local domain="$1"
    local full_domain="${prefix}${domain}"
    [ "$non_domain" = true ] && full_domain="${full_domain}${domain_suffix}"

    echo -n "Checking: $full_domain "

    # Get whois result
    whois_result=$(whois "$full_domain" 2>&1)
#    whois_exit_code=$?

    # Save debug log if enabled
    if [ "$debug_mode" = true ]; then
      {
        echo "=== $full_domain ==="
        echo "$whois_result"
        echo ""
      } >> "logs/whois_debug_$timestamp.log"
    fi

    # TODO Fix
#    # Handle connection errors
#    if [ $whois_exit_code -ne 0 ]; then
#        echo -e "${yellow}[Error]${reset}"
#        echo "Error: $full_domain (connection error)" >> "$output_file"
#        return
#    fi

    # More comprehensive patterns for available domains
    if echo "$whois_result" | grep -iE "No match|NOT FOUND|No entries found|Domain not found|Status: AVAILABLE|Status: free|No matching record|Domain Status: No Object Found|Not found:|No Data Found|No Found|DOMAIN NOT FOUND|Domain not found|Not found|No match for domain" > /dev/null; then
        if [ "$interactive_mode" = true ]; then
            read -p -r ">> Found available: $full_domain — Accept? (y/n): " yn < /dev/tty
            [ "$yn" != "y" ] && return
        fi

        echo "Available: $full_domain" >> "$output_file"
        echo "$full_domain" >> "$available_file"
        echo -e "${green}[Available ✓]${reset}"

        if [ -n "$json_file" ]; then
            echo "{\"domain\": \"$full_domain\", \"status\": \"available\", \"timestamp\": \"$(date -Iseconds)\"}," >> "$json_file"
        fi

        # Send notification if available
        if [ "$turn_notification" = true ]; then
          if command -v notify-send >/dev/null 2>&1; then
              notify-send "✅ Available Domain" "$full_domain"
          fi
        fi

        # Play sound if available
        if [ "$turn_sound" = true ]; then
          if [ -f "$sound_file" ] && command -v ffplay >/dev/null 2>&1; then
              ffplay -nodisp -autoexit -loglevel quiet "$sound_file" >/dev/null 2>&1 &
          fi
        fi
    elif echo "$whois_result" | grep -iE "No whois server" > /dev/null; then
        echo "Error: $full_domain" >> "$output_file"
        echo "$full_domain" >> "$taken_file"
        echo -e "${red}[Error ✗]${reset}"

        if [ -n "$json_file" ]; then
            echo "{\"domain\": \"$full_domain\", \"status\": \"error\", \"timestamp\": \"$(date -Iseconds)\"}," >> "$json_file"
        fi
    else
        echo "Taken: $full_domain" >> "$output_file"
        echo "$full_domain" >> "$taken_file"
        echo -e "${red}[Taken ✗]${reset}"

        if [ -n "$json_file" ]; then
            echo "{\"domain\": \"$full_domain\", \"status\": \"taken\", \"timestamp\": \"$(date -Iseconds)\"}," >> "$json_file"
        fi
    fi

    # Sleep only if not in fast mode
    [ "$fast_mode" = false ] && sleep "$sleep_time"
}

# Check dependencies
check_dependencies

# Count actual domains (skip empty lines and comments)
total_domains=0
while IFS= read -r domain || [[ -n "$domain" ]]; do
    domain=$(echo "$domain" | tr -d '[:space:]' | tr -d '\r\n')
    [[ -z "$domain" || "$domain" =~ ^[[:space:]]*# ]] && continue
    ((total_domains++))
done < "$input_file"

avg_request_whois_seconds=3
estimated_time_1=$(echo "$total_domains * $sleep_time" | bc)  # Sleep Time
estimated_time_2=$(echo "$total_domains * $avg_request_whois_seconds" | bc)  # Average request whois
if command -v bc &> /dev/null; then
    estimated_time=$(echo "$estimated_time_1 + $estimated_time_2" | bc)
    estimated_minutes=$(echo "scale=1; $estimated_time / 60" | bc)
else
    estimated_time=$((estimated_time_1 + estimated_time_2))
    estimated_minutes=$((estimated_time / 60))
fi

echo -e "${cyan}╔══════════════════════════════════════════════════════════════╗"
echo -e "║                     Domain Checker Started                  "
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║ Total domains: ${yellow}$total_domains${cyan}                                      "
echo -e "║ Sleep time: ${yellow}${sleep_time}s${cyan}                                           "
echo -e "║ Estimated time: ${yellow}${estimated_time}s${cyan} (~${yellow}${estimated_minutes}${cyan} minutes)                    "
echo -e "║ Fast mode: ${yellow}$([ "$fast_mode" = true ] && echo "ON" || echo "OFF")${cyan}                                          "
echo -e "║ Debug mode: ${yellow}$([ "$debug_mode" = true ] && echo "ON" || echo "OFF")${cyan}                                         "
echo -e "╚══════════════════════════════════════════════════════════════╝${reset}"

# Main Loop with better progress tracking
current=0
start_time=$(date +%s)
remaining_time=$estimated_time

while IFS= read -r domain || [[ -n "$domain" ]]; do
    # Clean domain name
    domain=$(echo "$domain" | tr -d '[:space:]' | tr -d '\r\n')

    # Skip empty lines and comments
    [[ -z "$domain" || "$domain" =~ ^[[:space:]]*# ]] && continue

    ((current++))
    progress=$((current * 100 / total_domains))

    # Calculate ETA
    eta_formatted=$(printf "%02d:%02d" $((remaining_time / 60)) $((remaining_time % 60)))

    echo -ne "${blue}[$current/$total_domains] ${yellow}${progress}%${blue} ETA: ${yellow}${eta_formatted}${reset} "
    check_domain "$domain"

    remaining_time=$((remaining_time - sleep_time - avg_request_whois_seconds))
done < "$input_file"

# Close JSON properly
if [ -n "$json_file" ]; then
    sed -i '$ s/,$//' "$json_file"  # remove last comma
    echo "]" >> "$json_file"
fi

# Final Stats with better formatting
end_time=$(date +%s)
total_time=$((end_time - start_time))
total_time_formatted=$(printf "%02d:%02d" $((total_time/60)) $((total_time%60)))

available_count=$(wc -l < "$available_file")
taken_count=$(wc -l < "$taken_file")

echo -e "\n${cyan}╔══════════════════════════════════════════════════════════════╗"
echo -e "║                       Final Results                          "
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║ ${green}Available domains: ${yellow}$available_count${cyan}                                 "
echo -e "║ ${red}Taken/Error domains: ${yellow}$taken_count${cyan}                                     "
echo -e "║ ${blue}Total time: ${yellow}${total_time_formatted}${cyan}                                      "
echo -e "╠══════════════════════════════════════════════════════════════╣"
if [ "$no_save_mode" = false ]; then
  echo -e "║ Results saved to:                                            "
  echo -e "║ - Main output: ${yellow}$output_file${cyan}                        "
  echo -e "║ - Available: ${yellow}$available_file${cyan}                          "
  echo -e "║ - Taken: ${yellow}$taken_file${cyan}                              "
  if [ -n "$json_file" ]; then
  echo -e "║ - JSON: ${yellow}$json_file${cyan}                                  "
  fi
  if [ "$debug_mode" = true ]; then
  echo -e "║ - Debug log: ${yellow}logs/whois_debug_$timestamp.log${cyan}                "
  fi
else
  echo -e "║ You selected no save                                            "
fi
echo -e "╚══════════════════════════════════════════════════════════════╝${reset}"

# Show available domains if any found
if [ "$available_count" -gt 0 ]; then
    echo -e "\n${green}🎉 Available domains found:${reset}"
    head -10 "$available_file"
    [ "$available_count" -gt 10 ] && echo -e "${yellow}... and $((available_count - 10)) more${reset}"
fi