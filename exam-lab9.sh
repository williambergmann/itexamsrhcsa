#!/bin/bash
# Grader script - Batch 9 (Based on Questions 82-91)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch9.txt"
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
echo "Starting Grade Evaluation Batch 9 - $(date)" | tee -a ${REPORT_FILE}
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

### TASK 82: Create 600M Swap File
echo -e "${COLOR_INFO}Evaluating Task 82: Create 600M Swap File${COLOR_RESET}" | tee -a ${REPORT_FILE}
T82_SCORE=0
T82_TOTAL=20
SWAP_FILE="/swapfile"
# Check if swap file exists and has roughly correct size
if [ -f "$SWAP_FILE" ]; then
    SIZE_MB_82=$(ls -l --block-size=M "$SWAP_FILE" | awk '{print $5}' | sed 's/M//')
    if [[ $SIZE_MB_82 -ge 580 ]] && [[ $SIZE_MB_82 -le 620 ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Swap file '$SWAP_FILE' exists with correct size (~600M)." | tee -a ${REPORT_FILE}
         T82_SCORE=$(( T82_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Swap file '$SWAP_FILE' exists but size ($SIZE_MB_82 MiB) is incorrect (expected ~600M)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Swap file '$SWAP_FILE' does not exist." | tee -a ${REPORT_FILE}
fi
# Check if active in swapon -s
if swapon -s | grep -Fq "$SWAP_FILE"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Swap file '$SWAP_FILE' is currently active." | tee -a ${REPORT_FILE}
    T82_SCORE=$(( T82_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Swap file '$SWAP_FILE' is not currently active." | tee -a ${REPORT_FILE}
fi
# Check /etc/fstab for persistent entry
if grep -Fw "$SWAP_FILE" /etc/fstab | grep -w swap | grep -v "^#" &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent entry found in /etc/fstab for '$SWAP_FILE'." | tee -a ${REPORT_FILE}
    T82_SCORE=$(( T82_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent entry not found in /etc/fstab for '$SWAP_FILE'." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T82_SCORE ))
TOTAL=$(( TOTAL + T82_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 83: Users mary, alice, bobby; Group admin
echo -e "${COLOR_INFO}Evaluating Task 83: Users mary, alice, bobby; Group admin${COLOR_RESET}" | tee -a ${REPORT_FILE}
T83_SCORE=0
T83_TOTAL=40
# Check group exists
if getent group admin &>/dev/null; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Group 'admin' exists." | tee -a ${REPORT_FILE}
     T83_SCORE=$(( T83_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Group 'admin' does not exist." | tee -a ${REPORT_FILE}
     groupadd admin # Create for subsequent checks
fi
# Check users exist
USERS_EXIST_83=true
for user in mary alice bobby; do
  if ! id "$user" &>/dev/null; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' does not exist." | tee -a ${REPORT_FILE}
    USERS_EXIST_83=false
  fi
done
if $USERS_EXIST_83; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users mary, alice, and bobby exist." | tee -a ${REPORT_FILE}
    T83_SCORE=$(( T83_SCORE + 10 ))
    # Check mary/alice group membership
    MEMBERSHIP_OK_83=true
    if ! id -nG mary | grep -qw admin; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'mary' is not in supplementary group 'admin'." | tee -a ${REPORT_FILE}
        MEMBERSHIP_OK_83=false
    fi
    if ! id -nG alice | grep -qw admin; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'alice' is not in supplementary group 'admin'." | tee -a ${REPORT_FILE}
        MEMBERSHIP_OK_83=false
    fi
    if $MEMBERSHIP_OK_83; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users mary and alice are in group 'admin'." | tee -a ${REPORT_FILE}
        T83_SCORE=$(( T83_SCORE + 10 ))
    fi
    # Check bobby shell and group membership
    BOBBY_OK=true
    if ! getent passwd bobby | cut -d: -f7 | grep -q '/sbin/nologin'; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'bobby' shell is not /sbin/nologin." | tee -a ${REPORT_FILE}
        BOBBY_OK=false
    fi
    if id -nG bobby | grep -qw admin; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'bobby' IS incorrectly a member of 'admin'." | tee -a ${REPORT_FILE}
        BOBBY_OK=false
    fi
    if $BOBBY_OK; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'bobby' has shell /sbin/nologin and is not in 'admin'." | tee -a ${REPORT_FILE}
        T83_SCORE=$(( T83_SCORE + 5 ))
    fi
    # Check passwords set
    PW_SET_OK_83=true
    for user in mary alice bobby; do
        if ! grep "^${user}:" /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' password does not appear to be set." | tee -a ${REPORT_FILE}
             PW_SET_OK_83=false
        fi
    done
     if $PW_SET_OK_83; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Passwords for mary, alice, bobby appear to be set." | tee -a ${REPORT_FILE}
         T83_SCORE=$(( T83_SCORE + 10 ))
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot perform checks because not all users exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T83_SCORE ))
TOTAL=$(( TOTAL + T83_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 84: Shared Directory /common/admin
echo -e "${COLOR_INFO}Evaluating Task 84: Shared Directory /common/admin${COLOR_RESET}" | tee -a ${REPORT_FILE}
T84_SCORE=0
T84_TOTAL=30
DIR_84="/common/admin"
GROUP_NAME_84="admin"
# Check group exists
if ! getent group $GROUP_NAME_84 &>/dev/null; then
    groupadd $GROUP_NAME_84
    echo -e "${COLOR_FAIL}[INFO]${COLOR_RESET}\t Group '$GROUP_NAME_84' did not exist, created for further checks (no points)." | tee -a ${REPORT_FILE}
fi
# Check directory exists
if [ -d "$DIR_84" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$DIR_84' exists." | tee -a ${REPORT_FILE}
    T84_SCORE=$(( T84_SCORE + 5 ))
    # Check group owner
    if [[ $(stat -c %G "$DIR_84") == "$GROUP_NAME_84" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$DIR_84' is group-owned by '$GROUP_NAME_84'." | tee -a ${REPORT_FILE}
        T84_SCORE=$(( T84_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_84' is not group-owned by '$GROUP_NAME_84'." | tee -a ${REPORT_FILE}
    fi
    # Check permissions (rwxrws--- : 2770)
    PERMS_84=$(stat -c %A "$DIR_84")
    PERMS_OCT_84=$(stat -c %a "$DIR_84")
    if [[ "$PERMS_OCT_84" == "2770" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$DIR_84' has correct permissions (2770 -> drwxrws---)." | tee -a ${REPORT_FILE}
        T84_SCORE=$(( T84_SCORE + 10 )) # Permissions check
        T84_SCORE=$(( T84_SCORE + 10 )) # SGID check included
    elif [[ -g "$DIR_84" ]]; then # Check if SGID set but perms wrong
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_84' has SGID bit but permissions are $PERMS_STR_84 ($PERMS_OCT_84), expected 2770 (drwxrws---)." | tee -a ${REPORT_FILE}
         T84_SCORE=$(( T84_SCORE + 5 )) # Partial credit for SGID
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_84' does not have correct permissions or SGID bit set ($PERMS_STR_84 / $PERMS_OCT_84), expected 2770." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_84' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T84_SCORE ))
TOTAL=$(( TOTAL + T84_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 85: Kernel Update and Default (Rehash 2)
echo -e "${COLOR_INFO}Evaluating Task 85: Kernel Update and Default (Rehash 2)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T85_SCORE=0
T85_TOTAL=15 # Same scoring as T31/T45
KERNEL_COUNT_85=$(rpm -q kernel kernel-core | wc -l)
if [[ $KERNEL_COUNT_85 -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Multiple kernel packages found (Count: $KERNEL_COUNT_85)." | tee -a ${REPORT_FILE}
    T85_SCORE=$(( T85_SCORE + 5 ))
    DEFAULT_KERNEL_85=$(grubby --default-kernel 2>/dev/null)
    RUNNING_KERNEL_85="/boot/vmlinuz-$(uname -r)"
    LATEST_KERNEL_85=$(ls -t /boot/vmlinuz-* | head -n 1)

    if [[ -n "$DEFAULT_KERNEL_85" ]]; then
         echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t Default kernel path is $DEFAULT_KERNEL_85" | tee -a ${REPORT_FILE}
         if [[ "$DEFAULT_KERNEL_85" == "$LATEST_KERNEL_85" ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default kernel appears to be the latest installed kernel." | tee -a ${REPORT_FILE}
              T85_SCORE=$(( T85_SCORE + 10 ))
         elif [[ "$DEFAULT_KERNEL_85" != "$RUNNING_KERNEL_85" ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default kernel is different from currently running kernel (suggests change)." | tee -a ${REPORT_FILE}
              T85_SCORE=$(( T85_SCORE + 5 )) # Partial credit
         else
              echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default kernel ($DEFAULT_KERNEL_85) appears unchanged or doesn't match latest ($LATEST_KERNEL_85)." | tee -a ${REPORT_FILE}
         fi
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not determine default kernel using grubby." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Only one kernel package seems installed. Cannot verify update/default change." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T85_SCORE ))
TOTAL=$(( TOTAL + T85_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 86: Cron Job for Mary (echo Hello World)
echo -e "${COLOR_INFO}Evaluating Task 86: Cron Job for Mary (echo Hello World)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T86_SCORE=0
T86_TOTAL=10
CRON_CMD_86='echo "Hello World."' # Note quotes and period
CRON_SCHED_86="23 14 \* \* \*"
# Ensure user mary exists
id mary &>/dev/null || useradd mary

# Check mary's crontab for the entry
if crontab -l -u mary 2>/dev/null | grep -Fq "$CRON_SCHED_86 $CRON_CMD_86"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found scheduled task for mary: '$CRON_SCHED_86 $CRON_CMD_86'" | tee -a ${REPORT_FILE}
    T86_SCORE=$(( T86_SCORE + 10 ))
else
    # Check without quotes as a common mistake
    CRON_CMD_ALT='echo Hello World.'
    if crontab -l -u mary 2>/dev/null | grep -Fq "$CRON_SCHED_86 $CRON_CMD_ALT"; then
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Found task for mary, but command may have missed quotes: '$CRON_CMD_ALT' instead of '$CRON_CMD_86'." | tee -a ${REPORT_FILE}
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find '$CRON_SCHED_86 $CRON_CMD_86' in mary's crontab." | tee -a ${REPORT_FILE}
    fi
fi
SCORE=$(( SCORE + T86_SCORE ))
TOTAL=$(( TOTAL + T86_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 87: LDAP Client Configuration Check
echo -e "${COLOR_INFO}Evaluating Task 87: LDAP Client Configuration Check${COLOR_RESET}" | tee -a ${REPORT_FILE}
T87_SCORE=0
T87_TOTAL=10
# Check if an example ldap user (ldapuser1 assumed) can be resolved
if getent passwd ldapuser1 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'ldapuser1' found via getent (implies LDAP configured in NSS)." | tee -a ${REPORT_FILE}
    T87_SCORE=$(( T87_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'ldapuser1' not found via getent. Check LDAP client config (authselect/sssd/nsswitch/pam)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T87_SCORE ))
TOTAL=$(( TOTAL + T87_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 88: Autofs for NFS Home Directories (/home/guests - rehash)
echo -e "${COLOR_INFO}Evaluating Task 88: Autofs for NFS Home Directories (/home/guests - rehash)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T88_SCORE=0
T88_TOTAL=30 # Reduced points as very similar to Q34/54
AUTOFS_BASE_88="/home/guests"
AUTOFS_MAP_88="/etc/auto.ldap" # Assumed map name based on answer
NFS_SERVER_88="instructor.example.com" # Use name from question
# Note: Answer uses specific user line AND wildcard, grading wildcard is more robust

# Check autofs service status
if systemctl is-enabled autofs --quiet && systemctl is-active autofs --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs service is running and enabled." | tee -a ${REPORT_FILE}
    T88_SCORE=$(( T88_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check master map configuration
if grep -Eq "^\s*${AUTOFS_BASE_88}\s+${AUTOFS_MAP_88}" /etc/auto.master || grep -Eq "^\s*${AUTOFS_BASE_88}\s+${AUTOFS_MAP_88}" /etc/auto.master.d/*.conf &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs master map entry found for '$AUTOFS_BASE_88' pointing to '$AUTOFS_MAP_88'." | tee -a ${REPORT_FILE}
    T88_SCORE=$(( T88_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs master map entry for '$AUTOFS_BASE_88' -> '$AUTOFS_MAP_88' not found." | tee -a ${REPORT_FILE}
fi
# Check map file wildcard entry
if [ -f "$AUTOFS_MAP_88" ]; then
    # Check for wildcard, rw option, and correct server/path structure
    if grep -Eq "^\s*\*\s+-.*rw.*\s+${NFS_SERVER_88}:/home/guests/&" "$AUTOFS_MAP_88"; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Wildcard entry '*' configured correctly in '$AUTOFS_MAP_88' for '${NFS_SERVER_88}:/home/guests/&' with rw option." | tee -a ${REPORT_FILE}
         T88_SCORE=$(( T88_SCORE + 15 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Wildcard entry '*' for server '${NFS_SERVER_88}:/home/guests/&' not found or options incorrect (need rw) in '$AUTOFS_MAP_88'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Map file '$AUTOFS_MAP_88' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T88_SCORE ))
TOTAL=$(( TOTAL + T88_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 89: ACLs on /var/tmp/fstab (Rehash with bob)
echo -e "${COLOR_INFO}Evaluating Task 89: ACLs on /var/tmp/fstab (Rehash with bob)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T89_SCORE=0
T89_TOTAL=45 # Added points for bob
TARGET_FILE_89="/var/tmp/fstab"
# Ensure users exist for checks
id mary &>/dev/null || useradd mary
id alice &>/dev/null || useradd alice
# Create bob with UID 1000 if needed, check existing user UID if bob exists
if id bob &>/dev/null; then
   if [[ $(id -u bob) != 1000 ]]; then
        echo -e "${COLOR_FAIL}[WARN]${COLOR_RESET}\t User 'bob' exists but UID is not 1000. Cannot fulfill task exactly. Checking perms for existing bob." | tee -a ${REPORT_FILE}
   fi
else
    useradd -u 1000 bob
fi

# Check target exists
if [ -f "$TARGET_FILE_89" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t File '$TARGET_FILE_89' exists." | tee -a ${REPORT_FILE}
    T89_SCORE=$(( T89_SCORE + 5 ))
    # Check owner/group
    OWNER_89=$(stat -c %U "$TARGET_FILE_89")
    GROUP_89=$(stat -c %G "$TARGET_FILE_89")
    if [[ "$OWNER_89" == "root" ]] && [[ "$GROUP_89" == "root" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t File owner ($OWNER_89) and group ($GROUP_89) are correct (root:root)." | tee -a ${REPORT_FILE}
        T89_SCORE=$(( T89_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t File owner ($OWNER_89) or group ($GROUP_89) is incorrect (expected root:root)." | tee -a ${REPORT_FILE}
    fi
    # Check no standard execute bits set (basic perms)
    PERMS_89=$(stat -c %A "$TARGET_FILE_89")
    if [[ "$PERMS_89" != *"x"* ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t No standard execute permissions found ($PERMS_89)." | tee -a ${REPORT_FILE}
         T89_SCORE=$(( T89_SCORE + 5 ))
    else # Allow if only ACL grants execute, e.g. for alice
         if [[ "${PERMS_89:2:1}" == "x" ]] || [[ "${PERMS_89:5:1}" == "x" ]] || [[ "${PERMS_89:8:1}" == "x" ]]; then
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Standard Unix execute permission found ($PERMS_89)." | tee -a ${REPORT_FILE}
         else
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t No standard execute permissions found ($PERMS_89)." | tee -a ${REPORT_FILE}
            T89_SCORE=$(( T89_SCORE + 5 ))
        fi
    fi
    # Check ACLs
    ACL_OUTPUT_89=$(getfacl "$TARGET_FILE_89" 2>/dev/null)
    MARY_ACL_OK=false
    ALICE_ACL_OK=false
    BOB_ACL_OK=false
    OTHER_ACL_OK=false
    if echo "$ACL_OUTPUT_89" | grep -Eq "^user:mary:rw-"; then MARY_ACL_OK=true; fi
    if echo "$ACL_OUTPUT_89" | grep -Eq "^user:alice:r-x"; then ALICE_ACL_OK=true; fi # Note: Execute granted via ACL
    if echo "$ACL_OUTPUT_89" | grep -Eq "^user:bob:rw-"; then BOB_ACL_OK=true; fi
    if echo "$ACL_OUTPUT_89" | grep -Eq "^other::r--"; then OTHER_ACL_OK=true; fi

    if $MARY_ACL_OK; then echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ACL for mary (rw-) found."; T89_SCORE=$(( T89_SCORE + 5 )); else echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for mary (rw-) incorrect/missing."; fi
    if $ALICE_ACL_OK; then echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ACL for alice (r-x) found."; T89_SCORE=$(( T89_SCORE + 5 )); else echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for alice (r-x) incorrect/missing."; fi
    if $BOB_ACL_OK; then echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ACL for bob (rw-) found."; T89_SCORE=$(( T89_SCORE + 10 )); else echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for bob (rw-) incorrect/missing."; fi
    if $OTHER_ACL_OK; then echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Effective other permissions (r--) found via getfacl."; T89_SCORE=$(( T89_SCORE + 5 )); else echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Effective other permissions (r--) incorrect/missing."; fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t File '$TARGET_FILE_89' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T89_SCORE ))
TOTAL=$(( TOTAL + T89_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 90: Configure NTP Service (Generic Check)
echo -e "${COLOR_INFO}Evaluating Task 90: Configure NTP Service (Generic Check)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T90_SCORE=0
T90_TOTAL=10
# Check chronyd service status
if systemctl is-enabled chronyd --quiet && systemctl is-active chronyd --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t chronyd service is running and enabled." | tee -a ${REPORT_FILE}
    T90_SCORE=$(( T90_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t chronyd service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check if synchronized or has sources configured
if chronyc sources &>/dev/null && [[ $(chronyc tracking | awk '/^Stratum/ {print $2}') -gt 0 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t chronyd appears to have sources configured and is potentially synchronized (Stratum > 0)." | tee -a ${REPORT_FILE}
    T90_SCORE=$(( T90_SCORE + 5 ))
elif chronyc sources &>/dev/null; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t chronyd has sources but stratum is 0 or could not be determined (not synchronized)." | tee -a ${REPORT_FILE}
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t chronyd does not appear to have active sources configured." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T90_SCORE ))
TOTAL=$(( TOTAL + T90_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 91: Configure vsftpd for Anonymous Download
echo -e "${COLOR_INFO}Evaluating Task 91: Configure vsftpd for Anonymous Download${COLOR_RESET}" | tee -a ${REPORT_FILE}
T91_SCORE=0
T91_TOTAL=25
# Check vsftpd installed
if rpm -q vsftpd &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t vsftpd package is installed." | tee -a ${REPORT_FILE}
    T91_SCORE=$(( T91_SCORE + 5 ))
    # Check vsftpd service status
    if systemctl is-enabled vsftpd --quiet && systemctl is-active vsftpd --quiet; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t vsftpd service is running and enabled." | tee -a ${REPORT_FILE}
        T91_SCORE=$(( T91_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t vsftpd service is not running or not enabled." | tee -a ${REPORT_FILE}
    fi
    # Check anonymous enable setting
    if grep -Eq '^\s*anonymous_enable\s*=\s*YES' /etc/vsftpd/vsftpd.conf; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t anonymous_enable=YES found in vsftpd.conf." | tee -a ${REPORT_FILE}
        T91_SCORE=$(( T91_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t anonymous_enable=YES not found or not set correctly in /etc/vsftpd/vsftpd.conf." | tee -a ${REPORT_FILE}
    fi
     # Check firewall allows ftp service
    if firewall-cmd --list-services --permanent 2>/dev/null | grep -qw ftp ; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Firewall permanently allows 'ftp' service." | tee -a ${REPORT_FILE}
        T91_SCORE=$(( T91_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Firewall does not appear to allow 'ftp' service permanently." | tee -a ${REPORT_FILE}
         echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}\t Note: Passive ports might also need configuration/opening depending on setup." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t vsftpd package is not installed." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T91_SCORE ))
TOTAL=$(( TOTAL + T91_TOTAL ))
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
echo -e "${COLOR_INFO}Your total score for Batch 9 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"