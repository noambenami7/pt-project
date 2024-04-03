#!/bin/bash

BLUE='\033[0;34m'
NC='\033[0m'

password_list=(
    "password"
    "123456"
    "qwerty"
    "abc123"
    "letmein"
    "monkey"
    "1234567890"
    "12345678"
    "1234"
    "password1"
    "iloveyou"
    "admin"
    "123123"
    "welcome"
    "login"
    "passw0rd"
    "123"
    "12345"
    "test"
    "password123"
    "kali"
)
start_time=$(date +"%Y-%m-%d %H:%M:%S")
found_files=0
echo -e "${BLUE} [#] Analysis started at: $start_time ${NC}"

function nba1() {
  if ! command -v nmap &>/dev/null; then
    sudo apt-get install nmap -qq -y > /dev/null 2>&1 
  fi

  if ! command -v hydra &>/dev/null; then
    sudo apt-get install hydra -qq -y > /dev/null 2>&1
  fi

  if ! command -v medusa &>/dev/null; then
    sudo apt-get install medusa -qq -y > /dev/null 2>&1
  fi

  if ! command -v searchsploit &>/dev/null; then
    sudo apt-get install exploitdb -qq -y > /dev/null 2>&1
  fi
  
  if ! command -v masscan &>/dev/null; then
    sudo apt-get install masscan -qq -y > /dev/null 2>&1
  fi
  
  echo -e "${BLUE} [#] All the tools we will need have been downloaded or are already in the system ${NC}"
}

function well() {
  nmap $net -sL 2> .out 1> .out2
  if [ ! -z "$(cat .out)" ]; then
    echo "[#] not valid!"
    exit
  else 
    echo " [#] valid net!"
  fi   
}

function basic_scan() {
  read -rp " [#] Enter name for the output directory: " output_dir
  sudo mkdir -p "$output_dir"
  read -rp " [#]Enter network to scan: " net
  well
  echo -e "${BLUE} [#] Scanning for open TCP ports with service version detection...${NC}"
  sudo nmap -p 21 -sS -sV -oN "$output_dir/tcp_scan.txt" "$net" > /dev/null 2>&1

  echo -e "${BLUE} [#] Scanning for open UDP ports with service version detection...${NC}"
  sudo nmap -p53 -sU -sV -oN "$output_dir/udp_scan.txt" "$net" > /dev/null 2>&1

  echo -e "${BLUE} [#!] Basic scan completed. Results saved in $output_dir directory.${NC}"
}


function full_scan() {
  read -rp " [#] Enter name for the output directory:" output_dir
  sudo rm -r "$output_dir" > /dev/null 2>&1
  sudo mkdir -p "$output_dir"
  read -rp " [#] Enter network to scan: " net
  well
  echo -e "${BLUE} [#] Scanning for open TCP ports with service version detection...${NC}"
  sudo nmap "$net" -sS -sV -oN "$output_dir/tcp_scan.txt" > /dev/null 2>&1
  echo -e "${BLUE} [#] TCP scan saved into $output_dir/tcp_scan.txt ${NC}"
  echo " "
  echo -e "${BLUE} [#] Scanning for open UDP ports with service version detection...${NC}"
  sudo nmap "$net" -p53 -sU -sV -oN "$output_dir/udp_scan.txt" > /dev/null 2>&1
  echo -e "${BLUE} [#] udp scan saved into $output_dir/udp_scan.txt ${NC}"
}

function run_NSE() {          
  echo -e "${BLUE} [#] searching for vulnerability ${NC}"
  sudo nmap "$net" --script=default,vuln -oN "$output_dir/vulnerability_scan.txt" > /dev/null 2>&1
  echo -e "${BLUE} [#] searching for vulnerability saved into $output_dir/vulnerability_scan.txt  ${NC}"
}
  
function run_weekpass() {
  echo -e "${BLUE} [#] searching for weak passwords used in the network for login services ${NC}"
  sudo nmap -p 139,445 --script smb-brute "$net" -oN "$output_dir/weekpass_scan.txt" > /dev/null 2>&1
  echo -e "${BLUE} [#] searching for weak passwords saved into $output_dir/weekpass_scan.txt  ${NC}"
}
  
  
function password_brute() {
  echo -e "${BLUE} [#] Starting password brute-force scan...${NC}"

  read -rp " [#] Do you want to use the built-in password list? (yes/no): " use_builtin

  if [[ $use_builtin == "yes" ]]; then
    password_list_used=("${password_list[@]}")
  else
    while true; do
      read -rp " [#] Enter the path to your custom password list file:  " custom_password_list
      if [ -f "$custom_password_list" ]; then
        password_list_used=($(<"$custom_password_list"))
        break
      else
        read -rp " [#] Custom password list file not found. Do you want to try again? (yes/no): " try_again
        if [[ $try_again == "no" ]]; then
          echo -e " [#] Continuing without custom password list..."
          password_list_used=()  # Using an empty list
          break
        fi
      fi
    done
  fi

  read -rp " [#] Enter the username for brute-force attack: " username
  

  # Iterate through the selected password list and perform brute-force attacks
  for password in "${password_list_used[@]}"; do

      
        hydra -L "$username" -P "$password" ssh://"$net" > "$output_dir/hydra_ssh_scan.txt" > /dev/null 2>&1
        # RDP brute-force with Hydra
        hydra -L "$username" -P "$password" rdp://"$net" > "$output_dir/hydra_rdp_brute.txt" > /dev/null 2>&1
        # FTP brute-force with Hydra
        hydra -L "$username" -P "$password" ftp://"$net" > "$output_dir/hydra_ftp_brute.txt" > /dev/null 2>&1
        # Telnet brute-force with Hydra
        hydra -L "$username" -P "$password" telnet://"$net" > "$output_dir/hydra_telnet_brute.txt" > /dev/null 2>&1
  done
  cd
  echo -e "${BLUE} [#] Full scan completed. Results saved in $output_dir directory.${NC}"
}


function compress_results() {
  read -rp "Do you want to compress the results into a zip file? (yes/no): " compress_choice

  if [[ $compress_choice == "yes" ]]; then
    read -rp "Enter the name for the zip file: " zip_filename
    # Compress the directory into a zip file
    zip -r "$zip_filename.zip" "$output_dir"
    echo "Results compressed and saved as $zip_filename.zip"
  else
    echo "Results were not compressed."
  fi
}


  
function netscan() {
  read -rp " [#] Choose scan type ('basic' or 'full'): " scan_type 
  
  case $scan_type in
    basic)
      echo " [#] Basic type was chosen"
      basic_scan
      compress_results
      ;;
    full)
      echo " [#] Full type was chosen"
      full_scan
      echo " "
      run_NSE
      echo " "
      run_weekpass
      echo " "
      password_brute
      echo " "
      compress_results
      # Add additional commands for full scan if needed
      ;;
    *)
      echo "[#] Invalid scan type. Exiting."
      exit 1
      ;;
  esac
}

nba1
netscan
