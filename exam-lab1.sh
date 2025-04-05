#!/bin/bash
# Grader script based on user-provided tasks and format
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report.txt"
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
echo "Starting Grade Evaluation - $(date)" | tee -a ${REPORT_FILE}
echo "-------------------------------------" | tee -a ${REPORT_FILE}

# Initialize score variables
SCORE=0
TOTAL=0

# --- Pre-check: SELinux ---
echo -e "${COLOR_INFO}Pre-check: SELinux Status${COLOR_RESET}" | tee -a ${REPORT_FILE}
if getenforce | grep -iq enforcing &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t SELinux is in Enforcing mode." | tee -a ${REPORT_FILE}
else
    echo -e "${COLOR_FAIL}[FATAL]${COLOR_RESET}\t\t You will likely FAIL the exam because SELinux is not in enforcing mode. Set SELinux to enforcing mode ('setenforce 1' and check /etc/selinux/config) and try again." | tee -a ${REPORT_FILE}
    # In a real exam context, stopping might be harsh, but for this script:
    exit 666
fi
echo -e "\n" | tee -a ${REPORT_FILE}
# --- Task Evaluation ---

### TASK 1: Network Configuration
echo -e "${COLOR_INFO}Evaluating Task 1: Network Configuration${COLOR_RESET}" | tee -a ${REPORT_FILE}
T1_SCORE=0
T1_TOTAL=40
# Check Hostname
if hostnamectl status | grep -q 'Static hostname: station\.domain40\.example\.com'; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Hostname is set correctly." | tee -a ${REPORT_FILE}
    T1_SCORE=$(( T1_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Hostname is not 'station.domain40.example.com'." | tee -a ${REPORT_FILE}
fi
# Check IP (Checking primary interface's active connection - this is more robust than guessing eth0)
PRIMARY_CONN=$(nmcli -g NAME,DEVICE,STATE c show --active | grep -v ':lo:' | head -n 1 | cut -d: -f1)
if [[ -n "$PRIMARY_CONN" ]] && nmcli con show "$PRIMARY_CONN" | grep -q 'ipv4.addresses:\s*172\.24\.40\.40/24'; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t IP Address 172.24.40.40/24 found on primary active connection '$PRIMARY_CONN'." | tee -a ${REPORT_FILE}
     T1_SCORE=$(( T1_SCORE + 10 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t IP Address 172.24.40.40/24 not found correctly configured on primary active connection '$PRIMARY_CONN'." | tee -a ${REPORT_FILE}
fi
# Check Gateway
if ip route show default | grep -q 'via 172\.24\.40\.1'; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default gateway 172.24.40.1 found." | tee -a ${REPORT_FILE}
    T1_SCORE=$(( T1_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default gateway 172.24.40.1 not found." | tee -a ${REPORT_FILE}
fi
# Check DNS (Checking resolv.conf is sufficient for basic test)
if grep -q '^nameserver 172\.24\.40\.1' /etc/resolv.conf; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t DNS server 172.24.40.1 found in /etc/resolv.conf." | tee -a ${REPORT_FILE}
     T1_SCORE=$(( T1_SCORE + 10 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t DNS server 172.24.40.1 not found in /etc/resolv.conf." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T1_SCORE ))
TOTAL=$(( TOTAL + T1_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 2: User Creation
echo -e "${COLOR_INFO}Evaluating Task 2: User Creation${COLOR_RESET}" | tee -a ${REPORT_FILE}
T2_SCORE=0
T2_TOTAL=30
# Check users exist
USERS_EXIST=true
for user in harry natasha tom; do
  if ! id "$user" &>/dev/null; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' does not exist." | tee -a ${REPORT_FILE}
    USERS_EXIST=false
  fi
done
if $USERS_EXIST; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users harry, natasha, and tom exist." | tee -a ${REPORT_FILE}
    T2_SCORE=$(( T2_SCORE + 10 ))
    # Check admin group membership
    ADMIN_GROUP_OK=true
    if ! id -nG harry | grep -qw admin; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'harry' is not in supplementary group 'admin'." | tee -a ${REPORT_FILE}
        ADMIN_GROUP_OK=false
    fi
    if ! id -nG natasha | grep -qw admin; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'natasha' is not in supplementary group 'admin'." | tee -a ${REPORT_FILE}
        ADMIN_GROUP_OK=false
    fi
    if $ADMIN_GROUP_OK; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users harry and natasha are in group 'admin'." | tee -a ${REPORT_FILE}
        T2_SCORE=$(( T2_SCORE + 10 ))
    fi
    # Check tom's shell
    if getent passwd tom | cut -d: -f7 | grep -q '/sbin/nologin'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'tom' shell is /sbin/nologin." | tee -a ${REPORT_FILE}
        T2_SCORE=$(( T2_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'tom' shell is not /sbin/nologin." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot check group membership or shell because not all users exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T2_SCORE ))
TOTAL=$(( TOTAL + T2_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 3: Shared Directory
echo -e "${COLOR_INFO}Evaluating Task 3: Shared Directory (/home/admins)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T3_SCORE=0
T3_TOTAL=30
ADMINS_DIR="/home/admins"
# Check group 'admin' exists first (needed for other checks)
if ! getent group admin &>/dev/null; then
    groupadd admin # Create if missing to avoid later errors, but don't give points
    echo -e "${COLOR_FAIL}[INFO]${COLOR_RESET}\t Group 'admin' did not exist, created for further checks (no points)." | tee -a ${REPORT_FILE}
fi

if [ -d "$ADMINS_DIR" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$ADMINS_DIR' exists." | tee -a ${REPORT_FILE}
    T3_SCORE=$(( T3_SCORE + 10 ))
    # Check group owner
    if [[ $(stat -c %G "$ADMINS_DIR") == "admin" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$ADMINS_DIR' is group-owned by 'admin'." | tee -a ${REPORT_FILE}
        T3_SCORE=$(( T3_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR' is not group-owned by 'admin'." | tee -a ${REPORT_FILE}
    fi
    # Check permissions (rwxrws---) and SGID bit
    PERMS=$(stat -c %A "$ADMINS_DIR")
    if [[ "$PERMS" == "drwxrws---"* ]]; then # Allow potential ACL '+'
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$ADMINS_DIR' has correct permissions and SGID bit set (drwxrws---)." | tee -a ${REPORT_FILE}
        T3_SCORE=$(( T3_SCORE + 10 ))
    elif [[ -g "$ADMINS_DIR" ]]; then
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR' has SGID but permissions are not rwxrws--- (Found: $PERMS)." | tee -a ${REPORT_FILE}
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR' does not have SGID set or permissions incorrect (Found: $PERMS)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T3_SCORE ))
TOTAL=$(( TOTAL + T3_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 4: Cron Job
echo -e "${COLOR_INFO}Evaluating Task 4: Cron Job${COLOR_RESET}" | tee -a ${REPORT_FILE}
T4_SCORE=0
T4_TOTAL=10
CRON_CMD="/bin/echo hello"
CRON_SCHED="23 14 * * *"
# Check root's crontab for the entry
if crontab -l -u root 2>/dev/null | grep -Fq "$CRON_SCHED $CRON_CMD"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found scheduled task for root: '$CRON_SCHED $CRON_CMD'" | tee -a ${REPORT_FILE}
    T4_SCORE=$(( T4_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find '$CRON_SCHED $CRON_CMD' in root's crontab." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T4_SCORE ))
TOTAL=$(( TOTAL + T4_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 5: Find and Copy Files
echo -e "${COLOR_INFO}Evaluating Task 5: Find and Copy Files${COLOR_RESET}" | tee -a ${REPORT_FILE}
T5_SCORE=0
T5_TOTAL=10
TARGET_DIR="/opt/dir"
# Simple check: does the directory exist and is it non-empty?
# Creating a dummy file is too complex for this context.
if [ -d "$TARGET_DIR" ]; then
    if [ -n "$(ls -A $TARGET_DIR)" ]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target directory '$TARGET_DIR' exists and contains files (assuming copy worked)." | tee -a ${REPORT_FILE}
        T5_SCORE=$(( T5_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target directory '$TARGET_DIR' exists but is empty." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target directory '$TARGET_DIR' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T5_SCORE ))
TOTAL=$(( TOTAL + T5_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 6: Grep Lines
echo -e "${COLOR_INFO}Evaluating Task 6: Grep Lines${COLOR_RESET}" | tee -a ${REPORT_FILE}
T6_SCORE=0
T6_TOTAL=10
SOURCE_FILE="/etc/testfile"
TARGET_FILE="/tmp/testfile"
SEARCH_TERM="abcde"
# Create a dummy source file for verification
echo "Line without term" > "$SOURCE_FILE"
echo "Line with abcde here" >> "$SOURCE_FILE"
echo "Another line without" >> "$SOURCE_FILE"
echo "Final abcde line" >> "$SOURCE_FILE"

# Check if target file exists (assume user ran the grep command)
if [ -f "$TARGET_FILE" ]; then
     # Basic content check: Does it contain the term and not contain a non-term line?
     if grep -q "$SEARCH_TERM" "$TARGET_FILE" && ! grep -q "Line without term" "$TARGET_FILE"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target file '$TARGET_FILE' exists and seems to contain correct lines." | tee -a ${REPORT_FILE}
        T6_SCORE=$(( T6_SCORE + 10 ))
     else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE' exists but content seems incorrect." | tee -a ${REPORT_FILE}
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE' does not exist." | tee -a ${REPORT_FILE}
fi
# Clean up dummy source file
rm -f "$SOURCE_FILE" &>/dev/null
SCORE=$(( SCORE + T6_SCORE ))
TOTAL=$(( TOTAL + T6_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 7: Add Swap Partition
echo -e "${COLOR_INFO}Evaluating Task 7: Add Swap Partition${COLOR_RESET}" | tee -a ${REPORT_FILE}
T7_SCORE=0
T7_TOTAL=20
SWAP_COUNT=$(swapon -s | sed '1d' | wc -l) # Count active swap spaces (excluding header)
ORIG_SWAP_DEVICE=$(swapon -s | sed '1d' | awk '{print $1}' | head -n 1) # Get the first (likely original) swap device

# Check if more than one swap space is active
if [[ $SWAP_COUNT -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found more than one active swap space." | tee -a ${REPORT_FILE}
    T7_SCORE=$(( T7_SCORE + 10 ))
    # Check /etc/fstab for a swap entry that is NOT the original one
    if grep -w swap /etc/fstab | grep -v "$ORIG_SWAP_DEVICE" | grep -v "^#" | grep -q swap; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found a persistent swap entry in /etc/fstab (different from original)." | tee -a ${REPORT_FILE}
        T7_SCORE=$(( T7_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not find a persistent swap entry in /etc/fstab for the additional swap space." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find more than one active swap space (expected original + new 2G)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T7_SCORE ))
TOTAL=$(( TOTAL + T7_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 8: User Alex
echo -e "${COLOR_INFO}Evaluating Task 8: User Alex${COLOR_RESET}" | tee -a ${REPORT_FILE}
T8_SCORE=0
T8_TOTAL=20
if id alex &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'alex' exists." | tee -a ${REPORT_FILE}
    T8_SCORE=$(( T8_SCORE + 5 ))
    # Check UID
    if [[ $(id -u alex) == 1234 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'alex' UID is 1234." | tee -a ${REPORT_FILE}
        T8_SCORE=$(( T8_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'alex' UID is not 1234 (Found: $(id -u alex))." | tee -a ${REPORT_FILE}
    fi
    # Check if password is set (cannot check actual password value)
    if grep '^alex:' /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'alex' password appears to be set." | tee -a ${REPORT_FILE}
        T8_SCORE=$(( T8_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'alex' password does not appear to be set in /etc/shadow." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'alex' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T8_SCORE ))
TOTAL=$(( TOTAL + T8_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 9: Local Repo and vsftpd
echo -e "${COLOR_INFO}Evaluating Task 9: Local Repo and vsftpd${COLOR_RESET}" | tee -a ${REPORT_FILE}
T9_SCORE=0
T9_TOTAL=40
# Check repo file configuration
if [ -f /etc/yum.repos.d/local.repo ] && grep -Eq 'baseurl\s*=\s*file:///mnt' /etc/yum.repos.d/local.repo; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t /etc/yum.repos.d/local.repo found with correct baseurl." | tee -a ${REPORT_FILE}
    T9_SCORE=$(( T9_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t /etc/yum.repos.d/local.repo not found or baseurl incorrect." | tee -a ${REPORT_FILE}
fi
# Check vsftpd installed
if rpm -q vsftpd &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t vsftpd package is installed." | tee -a ${REPORT_FILE}
    T9_SCORE=$(( T9_SCORE + 10 ))
    # Check vsftpd service status
    if systemctl is-enabled vsftpd --quiet && systemctl is-active vsftpd --quiet; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t vsftpd service is running and enabled." | tee -a ${REPORT_FILE}
        T9_SCORE=$(( T9_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t vsftpd service is not running or not enabled." | tee -a ${REPORT_FILE}
    fi
    # Check anonymous enable setting
    if grep -Eq '^\s*anonymous_enable\s*=\s*YES' /etc/vsftpd/vsftpd.conf; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t anonymous_enable=YES found in vsftpd.conf." | tee -a ${REPORT_FILE}
        T9_SCORE=$(( T9_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t anonymous_enable=YES not found or not set correctly in /etc/vsftpd/vsftpd.conf." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t vsftpd package is not installed." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T9_SCORE ))
TOTAL=$(( TOTAL + T9_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 10: httpd Basic Config
echo -e "${COLOR_INFO}Evaluating Task 10: httpd Basic Config${COLOR_RESET}" | tee -a ${REPORT_FILE}
T10_SCORE=0
T10_TOTAL=30
# Check httpd installed
if rpm -q httpd &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t httpd package is installed." | tee -a ${REPORT_FILE}
    T10_SCORE=$(( T10_SCORE + 5 ))
    # Check index.html exists
    if [ -f /var/www/html/index.html ]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t /var/www/html/index.html exists." | tee -a ${REPORT_FILE}
        T10_SCORE=$(( T10_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t /var/www/html/index.html does not exist." | tee -a ${REPORT_FILE}
    fi
    # Check httpd service status
    if systemctl is-enabled httpd --quiet && systemctl is-active httpd --quiet; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t httpd service is running and enabled." | tee -a ${REPORT_FILE}
        T10_SCORE=$(( T10_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t httpd service is not running or not enabled." | tee -a ${REPORT_FILE}
    fi
     # Check firewall allows http
    if firewall-cmd --list-services --permanent 2>/dev/null | grep -qw http || firewall-cmd --list-ports --permanent 2>/dev/null | grep -qw 80/tcp ; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Firewall permanently allows http service or port 80/tcp." | tee -a ${REPORT_FILE}
        T10_SCORE=$(( T10_SCORE + 10 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Firewall does not appear to allow http service or port 80/tcp permanently." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t httpd package is not installed." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T10_SCORE ))
TOTAL=$(( TOTAL + T10_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


# --- Final Grading ---
echo "-------------------------------------" | tee -a ${REPORT_FILE}
echo "Evaluation Complete. Press Enter for results overview."
read
clear
grep FAIL ${REPORT_FILE} &>/dev/null || echo -e "\nNo FAIL messages recorded." >> ${REPORT_FILE}
cat ${REPORT_FILE}
echo "Press Enter for final score."
read
clear
echo -e "\n"
echo -e "${COLOR_INFO}Your total score is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"
