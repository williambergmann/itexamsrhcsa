#!/bin/bash
# Grader script - Batch 7 (Based on Questions 62-71)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch7.txt"
PASS_THRESHOLD=70 # Percentage required to pass

# --- Color Codes ---
COLOR_OK="\033[32m"
COLOR_FAIL="\033[31m"
COLOR_INFO="\033[1m"
COLOR_RESET="\033[0m"
COLOR_AWESOME="\e[5m\033[32m"

# --- Initialization ---
clear
# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${COLOR_FAIL}This script must be run as root.${COLOR_RESET}"
   exit 1
fi

# Clean up previous report
rm -f ${REPORT_FILE} &>/dev/null
touch ${REPORT_FILE} &>/dev/null
echo "Starting Grade Evaluation Batch 7 - $(date)" | tee -a ${REPORT_FILE}
echo "-----------------------------------------" | tee -a ${REPORT_FILE}

# Initialize score variables
SCORE=0
TOTAL=0

# --- Pre-check: SELinux ---
echo -e "${COLOR_INFO}Pre-check: SELinux Status${COLOR_RESET}" | tee -a ${REPORT_FILE}
if getenforce | grep -iq enforcing &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t SELinux is in Enforcing mode." | tee -a ${REPORT_FILE}
else
    echo -e "${COLOR_FAIL}[FATAL]${COLOR_RESET}\t You will likely FAIL the exam because SELinux is not in enforcing mode. Set SELinux to enforcing mode ('setenforce 1' and check /etc/selinux/config) and try again." | tee -a ${REPORT_FILE}
    exit 666
fi
echo -e "\n" | tee -a ${REPORT_FILE}
# --- Task Evaluation ---

### TASK 62: Root Password Reset Process
echo -e "${COLOR_INFO}Evaluating Task 62: Root Password Reset Process${COLOR_RESET}" | tee -a ${REPORT_FILE}
T62_SCORE=0
T62_TOTAL=0 # Cannot reliably grade this without interaction/known state
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}\t Task describes a procedure (boot interrupt). Direct grading not applicable." | tee -a ${REPORT_FILE}
echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}\t Ensure you know how to use 'rd.break' or 'init=/bin/bash' and 'touch /.autorelabel'." | tee -a ${REPORT_FILE}
# SCORE=$(( SCORE + T62_SCORE ))
# TOTAL=$(( TOTAL + T62_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 63: Configure Remote Syslog Reception (rsyslog)
echo -e "${COLOR_INFO}Evaluating Task 63: Configure Remote Syslog Reception (rsyslog)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T63_SCORE=0
T63_TOTAL=15
RSYSLOG_CONF="/etc/rsyslog.conf"
# Check if rsyslog is active
if systemctl is-active rsyslog --quiet; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t rsyslog service is active." | tee -a ${REPORT_FILE}
     T63_SCORE=$(( T63_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t rsyslog service is not active." | tee -a ${REPORT_FILE}
fi
# Check if UDP or TCP input modules are enabled in config (basic check)
if grep -Eq '^\s*module\s*\(\s*load\s*=\s*"imudp"\s*\)' "$RSYSLOG_CONF" || \
   grep -Eq '^\s*module\s*\(\s*load\s*=\s*"imptcp"\s*\)' "$RSYSLOG_CONF" || \
   grep -Eq '^\s*module\s*\(\s*load\s*=\s*"imtcp"\s*\)' "$RSYSLOG_CONF"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found imudp/imptcp/imtcp module loaded in '$RSYSLOG_CONF'." | tee -a ${REPORT_FILE}
    T63_SCORE=$(( T63_SCORE + 5 ))
    # Check if listening on port 514 (UDP or TCP)
    if ss -ulnp | grep -q ':514\s' || ss -tlnp | grep -q ':514\s'; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t A process (likely rsyslogd) is listening on port 514 (UDP or TCP)." | tee -a ${REPORT_FILE}
         T63_SCORE=$(( T63_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t No process found listening on port 514 (UDP or TCP)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not find imudp or imptcp/imtcp module load directive uncommented in '$RSYSLOG_CONF'." | tee -a ${REPORT_FILE}
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}\t Check for '$ModLoad imudp' / '$InputUDPServerRun 514' or similar directives." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T63_SCORE ))
TOTAL=$(( TOTAL + T63_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 64: DNS Client Configuration (Rehash)
echo -e "${COLOR_INFO}Evaluating Task 64: DNS Client Configuration (192.168.0.254)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T64_SCORE=0
T64_TOTAL=10
DNS_SERVER_64="192.168.0.254"
# Check /etc/resolv.conf first
RESOLV_OK=false
if grep -Eq "^\s*nameserver\s+${DNS_SERVER_64}" /etc/resolv.conf; then
    echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t DNS server ${DNS_SERVER_64} found in /etc/resolv.conf (may be temporary)." | tee -a ${REPORT_FILE}
    RESOLV_OK=true
fi
# Check NetworkManager persistent config (more reliable)
PRIMARY_CONN_64=$(nmcli -g NAME,DEVICE,STATE c show --active | grep -v ':lo:' | head -n 1 | cut -d: -f1)
if [[ -n "$PRIMARY_CONN_64" ]] && nmcli -g ipv4.dns,ipv6.dns con show "$PRIMARY_CONN_64" | grep -q "$DNS_SERVER_64"; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t DNS server ${DNS_SERVER_64} found in persistent config for connection '$PRIMARY_CONN_64'." | tee -a ${REPORT_FILE}
     T64_SCORE=$(( T64_SCORE + 10 ))
elif $RESOLV_OK; then
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t DNS server ${DNS_SERVER_64} found in /etc/resolv.conf, but not in persistent NM config for '$PRIMARY_CONN_64'." | tee -a ${REPORT_FILE}
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t DNS server ${DNS_SERVER_64} not found in /etc/resolv.conf or persistent NM config." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T64_SCORE ))
TOTAL=$(( TOTAL + T64_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 65: Install zsh package (from FTP/local)
echo -e "${COLOR_INFO}Evaluating Task 65: Install zsh package${COLOR_RESET}" | tee -a ${REPORT_FILE}
T65_SCORE=0
T65_TOTAL=10
# Check if zsh package is installed
if rpm -q zsh &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Package 'zsh' is installed." | tee -a ${REPORT_FILE}
    T65_SCORE=$(( T65_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Package 'zsh' is not installed." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T65_SCORE ))
TOTAL=$(( TOTAL + T65_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 66: NFS Server Status and Verification
echo -e "${COLOR_INFO}Evaluating Task 66: NFS Server Status and Verification${COLOR_RESET}" | tee -a ${REPORT_FILE}
T66_SCORE=0
T66_TOTAL=25
# Check nfs-server service status
if systemctl is-enabled nfs-server --quiet && systemctl is-active nfs-server --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t nfs-server service is running and enabled." | tee -a ${REPORT_FILE}
    T66_SCORE=$(( T66_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t nfs-server service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check rpcbind service status
if systemctl is-enabled rpcbind.socket --quiet && systemctl is-active rpcbind.socket --quiet || \
   systemctl is-enabled rpcbind --quiet && systemctl is-active rpcbind --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t rpcbind service/socket is running and enabled." | tee -a ${REPORT_FILE}
    T66_SCORE=$(( T66_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t rpcbind service/socket is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check showmount output (only works if exports are actually configured)
if showmount -e localhost &>/dev/null; then
    # Cannot easily verify *specific* shares without knowing them, just check if command succeeds
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t 'showmount -e localhost' command succeeded (implies NFS server responding)." | tee -a ${REPORT_FILE}
    T66_SCORE=$(( T66_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t 'showmount -e localhost' command failed or showed no exports." | tee -a ${REPORT_FILE}
fi
 # Check firewall allows nfs service
if firewall-cmd --list-services --permanent 2>/dev/null | grep -qw nfs ; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Firewall permanently allows 'nfs' service." | tee -a ${REPORT_FILE}
    T66_SCORE=$(( T66_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Firewall does not appear to allow 'nfs' service permanently." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T66_SCORE ))
TOTAL=$(( TOTAL + T66_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 67: New 100M Partition, ext3, Mount /data (Rehash)
echo -e "${COLOR_INFO}Evaluating Task 67: New 100M Partition, ext3, Mount /data (Rehash)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T67_SCORE=0
T67_TOTAL=30
MOUNT_POINT_67="/data" # Note conflict with Q55/56/61
echo -e "${COLOR_INFO}[WARN]${COLOR_RESET}\t Task 67 uses mount point '$MOUNT_POINT_67' which conflicts with Tasks 55/56/61. Grading assumes Task 67 was last." | tee -a ${REPORT_FILE}
PART_FOUND_67=false
PART_SIZE_OK_67=false
FS_OK_67=false
FSTAB_OK_67=false
MOUNT_OK_67=false

if findmnt "$MOUNT_POINT_67" &>/dev/null; then
     SOURCE_DEV_67=$(findmnt -no SOURCE "$MOUNT_POINT_67")
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Device '$SOURCE_DEV_67' is currently mounted on '$MOUNT_POINT_67'." | tee -a ${REPORT_FILE}
     T67_SCORE=$(( T67_SCORE + 5 ))
     MOUNT_OK_67=true
     if lsblk -no TYPE "$SOURCE_DEV_67" 2>/dev/null | grep -q 'part'; then
         PART_FOUND_67=true
         SIZE_MB_67=$(lsblk -bno SIZE "$SOURCE_DEV_67" 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
         if [[ "$SIZE_MB_67" -ge 90 ]] && [[ "$SIZE_MB_67" -le 110 ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Partition '$SOURCE_DEV_67' size is correct (~100M)." | tee -a ${REPORT_FILE}
              T67_SCORE=$(( T67_SCORE + 5 ))
              PART_SIZE_OK_67=true
         else
              echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Partition '$SOURCE_DEV_67' size ($SIZE_MB_67 MiB) is incorrect (expected ~100M)." | tee -a ${REPORT_FILE}
         fi
     else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Device mounted on '$MOUNT_POINT_67' is not a partition ($SOURCE_DEV_67)." | tee -a ${REPORT_FILE}
     fi
     if findmnt -no FSTYPE "$MOUNT_POINT_67" | grep -qE 'ext3|ext4'; then # Allow ext4 as modern substitute
         FS_TYPE_67=$(findmnt -no FSTYPE "$MOUNT_POINT_67")
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem mounted at '$MOUNT_POINT_67' is $FS_TYPE_67." | tee -a ${REPORT_FILE}
         T67_SCORE=$(( T67_SCORE + 5 ))
         FS_OK_67=true
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem mounted at '$MOUNT_POINT_67' is NOT ext3 (or ext4)." | tee -a ${REPORT_FILE}
     fi
     if grep -Fw "$MOUNT_POINT_67" /etc/fstab | grep -Eq 'ext3|ext4' | grep -v "^#" &>/dev/null; then
          echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_67'." | tee -a ${REPORT_FILE}
          T67_SCORE=$(( T67_SCORE + 10 ))
          FSTAB_OK_67=true
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_67'." | tee -a ${REPORT_FILE}
     fi
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Nothing is currently mounted on '$MOUNT_POINT_67'." | tee -a ${REPORT_FILE}
fi
# Add points for intermediate steps if final mount failed
if ! $MOUNT_OK_67; then
    if $PART_FOUND_67 && $PART_SIZE_OK_67; then T67_SCORE=$(( T67_SCORE + 5)); fi
    if $FS_OK_67; then T67_SCORE=$(( T67_SCORE + 5)); fi
    if $FSTAB_OK_67; then T67_SCORE=$(( T67_SCORE + 5)); fi
fi
SCORE=$(( SCORE + T67_SCORE ))
TOTAL=$(( TOTAL + T67_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 68: Apache SSL Configuration (Basic Checks)
echo -e "${COLOR_INFO}Evaluating Task 68: Apache SSL Configuration (Basic Checks)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T68_SCORE=0
T68_TOTAL=25
# Check mod_ssl installed
if rpm -q mod_ssl &>/dev/null; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t mod_ssl package is installed." | tee -a ${REPORT_FILE}
     T68_SCORE=$(( T68_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t mod_ssl package not installed." | tee -a ${REPORT_FILE}
fi
# Check httpd service status
if systemctl is-enabled httpd --quiet && systemctl is-active httpd --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t httpd service is running and enabled." | tee -a ${REPORT_FILE}
    T68_SCORE=$(( T68_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t httpd service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check if listening on port 443
if ss -tlnp | grep -q ':443\s'; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t A process (likely httpd) is listening on TCP port 443." | tee -a ${REPORT_FILE}
     T68_SCORE=$(( T68_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t No process found listening on TCP port 443." | tee -a ${REPORT_FILE}
fi
# Check firewall allows https
if firewall-cmd --list-services --permanent 2>/dev/null | grep -qw https || firewall-cmd --list-ports --permanent 2>/dev/null | grep -qw 443/tcp ; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Firewall permanently allows https service or port 443/tcp." | tee -a ${REPORT_FILE}
    T68_SCORE=$(( T68_SCORE + 10 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Firewall does not appear to allow https service or port 443/tcp permanently." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T68_SCORE ))
TOTAL=$(( TOTAL + T68_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 69: Static IP and Gateway (172.24.0.x / 172.25.254.254)
echo -e "${COLOR_INFO}Evaluating Task 69: Static IP and Gateway (172.24.0.x / 172.25.254.254)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T69_SCORE=0
T69_TOTAL=20
GATEWAY_IP_69="172.25.254.254" # Based on Q text, not Q48 answer
NETWORK_PREFIX="172.24.0." # Based on Q text

PRIMARY_CONN_69=$(nmcli -g NAME,DEVICE,STATE c show --active | grep -v ':lo:' | head -n 1 | cut -d: -f1)
if [[ -n "$PRIMARY_CONN_69" ]]; then
     echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t Checking active connection '$PRIMARY_CONN_69'." | tee -a ${REPORT_FILE}
     CONN_METHOD_69=$(nmcli -g ipv4.method con show "$PRIMARY_CONN_69")
     CONN_GW_69=$(nmcli -g ipv4.gateway con show "$PRIMARY_CONN_69")
     CONN_IP_69=$(nmcli -g ipv4.addresses con show "$PRIMARY_CONN_69" | cut -d/ -f1 | head -n 1) # Get first IP

     # Check static config method
     if [[ "$CONN_METHOD_69" == "manual" ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Connection '$PRIMARY_CONN_69' method is manual." | tee -a ${REPORT_FILE}
         T69_SCORE=$(( T69_SCORE + 5 ))
     else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Connection '$PRIMARY_CONN_69' method is not manual ($CONN_METHOD_69)." | tee -a ${REPORT_FILE}
     fi
     # Check gateway
     if [[ "$CONN_GW_69" == "$GATEWAY_IP_69" ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Gateway ${GATEWAY_IP_69} configured persistently on connection '$PRIMARY_CONN_69'." | tee -a ${REPORT_FILE}
         T69_SCORE=$(( T69_SCORE + 10 ))
     else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Gateway ${GATEWAY_IP_69} NOT configured persistently on connection '$PRIMARY_CONN_69' (Found: $CONN_GW_69)." | tee -a ${REPORT_FILE}
     fi
     # Check IP prefix
      if [[ "$CONN_IP_69" == ${NETWORK_PREFIX}* ]]; then
          echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t IP address ${CONN_IP_69} starts with correct prefix ${NETWORK_PREFIX}." | tee -a ${REPORT_FILE}
          T69_SCORE=$(( T69_SCORE + 5 ))
      else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t IP address ${CONN_IP_69} does not start with correct prefix ${NETWORK_PREFIX}." | tee -a ${REPORT_FILE}
      fi
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine primary active connection to check persistent settings." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T69_SCORE ))
TOTAL=$(( TOTAL + T69_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 70: DNS Client Configuration (Rehash 2)
echo -e "${COLOR_INFO}Evaluating Task 70: DNS Client Configuration (172.24.254.254)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T70_SCORE=0
T70_TOTAL=10
DNS_SERVER_70="172.24.254.254"
RESOLV_OK_70=false
if grep -Eq "^\s*nameserver\s+${DNS_SERVER_70}" /etc/resolv.conf; then
    echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t DNS server ${DNS_SERVER_70} found in /etc/resolv.conf (may be temporary)." | tee -a ${REPORT_FILE}
    RESOLV_OK_70=true
fi
PRIMARY_CONN_70=$(nmcli -g NAME,DEVICE,STATE c show --active | grep -v ':lo:' | head -n 1 | cut -d: -f1)
if [[ -n "$PRIMARY_CONN_70" ]] && nmcli -g ipv4.dns,ipv6.dns con show "$PRIMARY_CONN_70" | grep -q "$DNS_SERVER_70"; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t DNS server ${DNS_SERVER_70} found in persistent config for connection '$PRIMARY_CONN_70'." | tee -a ${REPORT_FILE}
     T70_SCORE=$(( T70_SCORE + 10 ))
elif $RESOLV_OK_70; then
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t DNS server ${DNS_SERVER_70} found in /etc/resolv.conf, but not in persistent NM config for '$PRIMARY_CONN_70'." | tee -a ${REPORT_FILE}
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t DNS server ${DNS_SERVER_70} not found in /etc/resolv.conf or persistent NM config." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T70_SCORE ))
TOTAL=$(( TOTAL + T70_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 71: Enable IP Forwarding (Rehash 2)
echo -e "${COLOR_INFO}Evaluating Task 71: Enable IP Forwarding (Rehash 2)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T71_SCORE=0
T71_TOTAL=15
if [[ $(sysctl -n net.ipv4.ip_forward) == 1 ]]; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t net.ipv4.ip_forward is currently active (1)." | tee -a ${REPORT_FILE}
     T71_SCORE=$(( T71_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t net.ipv4.ip_forward is not currently active (running value != 1)." | tee -a ${REPORT_FILE}
fi
if grep -Eqs '^\s*net\.ipv4\.ip_forward\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent setting net.ipv4.ip_forward = 1 found in sysctl configuration files." | tee -a ${REPORT_FILE}
    T71_SCORE=$(( T71_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent setting net.ipv4.ip_forward = 1 NOT found in /etc/sysctl.conf or /etc/sysctl.d/." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T71_SCORE ))
TOTAL=$(( TOTAL + T71_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


# --- Final Grading ---
echo "-----------------------------------------" | tee -a ${REPORT_FILE}
echo "Evaluation Complete. Press Enter for results overview."
read
clear
grep FAIL ${REPORT_FILE} &>/dev/null || echo -e "\nNo FAIL messages recorded." >> ${REPORT_FILE}
cat ${REPORT_FILE}
echo "Press Enter for final score."
read
clear
echo -e "\n"
echo -e "${COLOR_INFO}Your total score for Batch 7 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"