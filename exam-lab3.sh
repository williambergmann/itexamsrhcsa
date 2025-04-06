#!/bin/bash
# Grader script - Batch 3 (Questions 21-30)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch3.txt"
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
echo "Starting Grade Evaluation Batch 3 - $(date)" | tee -a ${REPORT_FILE}
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

### TASK 21: User user1
echo -e "${COLOR_INFO}Evaluating Task 21: User user1${COLOR_RESET}" | tee -a ${REPORT_FILE}
T21_SCORE=0
T21_TOTAL=30
if id user1 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'user1' exists." | tee -a ${REPORT_FILE}
    T21_SCORE=$(( T21_SCORE + 10 ))
    # Check UID
    if [[ $(id -u user1) == 601 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'user1' UID is 601." | tee -a ${REPORT_FILE}
        T21_SCORE=$(( T21_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user1' UID is not 601 (Found: $(id -u user1))." | tee -a ${REPORT_FILE}
    fi
     # Check shell
    if getent passwd user1 | cut -d: -f7 | grep -q '/sbin/nologin'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'user1' shell is /sbin/nologin." | tee -a ${REPORT_FILE}
        T21_SCORE=$(( T21_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user1' shell is not /sbin/nologin." | tee -a ${REPORT_FILE}
    fi
    # Check if password is set
    if grep '^user1:' /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'user1' password appears to be set." | tee -a ${REPORT_FILE}
        T21_SCORE=$(( T21_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user1' password does not appear to be set in /etc/shadow." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user1' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T21_SCORE ))
TOTAL=$(( TOTAL + T21_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 22: Users user2, user3
echo -e "${COLOR_INFO}Evaluating Task 22: Users user2, user3${COLOR_RESET}" | tee -a ${REPORT_FILE}
T22_SCORE=0
T22_TOTAL=30
# Check users exist
USERS_EXIST_22=true
for user in user2 user3; do
  if ! id "$user" &>/dev/null; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' does not exist." | tee -a ${REPORT_FILE}
    USERS_EXIST_22=false
  fi
done
if $USERS_EXIST_22; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users user2 and user3 exist." | tee -a ${REPORT_FILE}
    T22_SCORE=$(( T22_SCORE + 10 ))
    # Check admin group membership
    ADMIN_GROUP_OK_22=true
    # Ensure admin group exists for checks
    getent group admin &>/dev/null || groupadd admin
    if ! id -nG user2 | grep -qw admin; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user2' is not in supplementary group 'admin'." | tee -a ${REPORT_FILE}
        ADMIN_GROUP_OK_22=false
    fi
    if ! id -nG user3 | grep -qw admin; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user3' is not in supplementary group 'admin'." | tee -a ${REPORT_FILE}
        ADMIN_GROUP_OK_22=false
    fi
    if $ADMIN_GROUP_OK_22; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users user2 and user3 are in group 'admin'." | tee -a ${REPORT_FILE}
        T22_SCORE=$(( T22_SCORE + 10 ))
    fi
     # Check if passwords are set
    PW_SET_OK=true
    if ! grep '^user2:' /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user2' password does not appear to be set." | tee -a ${REPORT_FILE}
         PW_SET_OK=false
    fi
    if ! grep '^user3:' /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'user3' password does not appear to be set." | tee -a ${REPORT_FILE}
         PW_SET_OK=false
    fi
     if $PW_SET_OK; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Passwords for user2 and user3 appear to be set." | tee -a ${REPORT_FILE}
         T22_SCORE=$(( T22_SCORE + 10 ))
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot check group membership or passwords because not all users exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T22_SCORE ))
TOTAL=$(( TOTAL + T22_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 23: ACL Permissions on /var/tmp/fstab
echo -e "${COLOR_INFO}Evaluating Task 23: ACL Permissions on /var/tmp/fstab${COLOR_RESET}" | tee -a ${REPORT_FILE}
T23_SCORE=0
T23_TOTAL=20
TARGET_FILE_23="/var/tmp/fstab"
# Ensure source /etc/fstab exists for copy, create dummy if needed
[ -f /etc/fstab ] || echo "Defaults" > /etc/fstab

# Check target exists
if [ -f "$TARGET_FILE_23" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t File '$TARGET_FILE_23' exists." | tee -a ${REPORT_FILE}
    T23_SCORE=$(( T23_SCORE + 5 ))
    # Check ACLs using getfacl
    ACL_OUTPUT=$(getfacl "$TARGET_FILE_23" 2>/dev/null)
    USER1_ACL_OK=false
    USER2_ACL_OK=false
    if echo "$ACL_OUTPUT" | grep -q "^user:user1:rwx"; then
        USER1_ACL_OK=true
    fi
    if echo "$ACL_OUTPUT" | grep -q "^user:user2:---"; then
        USER2_ACL_OK=true
    fi

    if $USER1_ACL_OK && $USER2_ACL_OK; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Correct ACLs found for user1 (rwx) and user2 (---)." | tee -a ${REPORT_FILE}
         T23_SCORE=$(( T23_SCORE + 15 ))
    elif $USER1_ACL_OK; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for user1 correct, but incorrect/missing for user2." | tee -a ${REPORT_FILE}
    elif $USER2_ACL_OK; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for user2 correct, but incorrect/missing for user1." | tee -a ${REPORT_FILE}
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACLs for user1 and user2 are incorrect or missing." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t File '$TARGET_FILE_23' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T23_SCORE ))
TOTAL=$(( TOTAL + T23_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 24: Cron Job for Natasha (echo file)
echo -e "${COLOR_INFO}Evaluating Task 24: Cron Job for Natasha (echo file)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T24_SCORE=0
T24_TOTAL=10
CRON_CMD_24='/bin/echo "file"' # Note quotes around file
CRON_SCHED_24="23 14 \* \* \*"
# Ensure user natasha exists
id natasha &>/dev/null || useradd natasha

# Check natasha's crontab for the entry
if crontab -l -u natasha 2>/dev/null | grep -Fq "$CRON_SCHED_24 $CRON_CMD_24"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found scheduled task for natasha: '$CRON_SCHED_24 $CRON_CMD_24'" | tee -a ${REPORT_FILE}
    T24_SCORE=$(( T24_SCORE + 10 ))
else
    # Check without quotes as a common mistake
    CRON_CMD_ALT='/bin/echo file'
    if crontab -l -u natasha 2>/dev/null | grep -Fq "$CRON_SCHED_24 $CRON_CMD_ALT"; then
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Found task for natasha, but command missed quotes: '$CRON_CMD_ALT' instead of '$CRON_CMD_24'." | tee -a ${REPORT_FILE}
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find '$CRON_SCHED_24 $CRON_CMD_24' in natasha's crontab." | tee -a ${REPORT_FILE}
    fi
fi
SCORE=$(( SCORE + T24_SCORE ))
TOTAL=$(( TOTAL + T24_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 25: YUM/DNF Repository Configuration
echo -e "${COLOR_INFO}Evaluating Task 25: YUM/DNF Repository Configuration${COLOR_RESET}" | tee -a ${REPORT_FILE}
T25_SCORE=0
T25_TOTAL=20
REPO_URL="http://server.domain11.example.com/pub/x86_64/Server"
REPO_FILE_GLOB="/etc/yum.repos.d/*.repo"
FOUND_REPO=false
FOUND_GPG=false

for repo_file in $REPO_FILE_GLOB; do
    if [ -f "$repo_file" ] && grep -Eq "baseurl\s*=\s*${REPO_URL}" "$repo_file"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Repository file '$repo_file' found with correct baseurl." | tee -a ${REPORT_FILE}
        T25_SCORE=$(( T25_SCORE + 10 ))
        FOUND_REPO=true
        if grep -Eq '^\s*gpgcheck\s*=\s*0' "$repo_file"; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t gpgcheck=0 found in '$repo_file'." | tee -a ${REPORT_FILE}
            T25_SCORE=$(( T25_SCORE + 10 ))
            FOUND_GPG=true
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t gpgcheck=0 not found in '$repo_file'." | tee -a ${REPORT_FILE}
        fi
        break # Found matching repo file
    fi
done

if ! $FOUND_REPO; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t No repository file found in /etc/yum.repos.d/ with baseurl '$REPO_URL'." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T25_SCORE ))
TOTAL=$(( TOTAL + T25_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 26: LVM Resize 'vo' Filesystem
echo -e "${COLOR_INFO}Evaluating Task 26: LVM Resize 'vo' Filesystem to ~290MiB${COLOR_RESET}" | tee -a ${REPORT_FILE}
T26_SCORE=0
T26_TOTAL=20 # Points focus on filesystem size check
LV_NAME_26="vo" # Assuming the name from the question
# Check if LV exists
LV_PATH_26=$(lvs --noheadings -o lv_path,lv_name | awk -v name="$LV_NAME_26" '$2 == name {print $1; exit}')
if [[ -n "$LV_PATH_26" ]] && [[ -b "$LV_PATH_26" ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_26' found at $LV_PATH_26." | tee -a ${REPORT_FILE}
    # Check if filesystem size is within range (270M to 320M)
    MOUNT_POINT_26=$(findmnt -no TARGET ${LV_PATH_26})
    if [[ -n "$MOUNT_POINT_26" ]]; then
        FS_SIZE_MB_26=$(df -BM --output=size ${MOUNT_POINT_26} 2>/dev/null | tail -n 1 | sed 's/[^0-9]*//g')
        if [[ -n "$FS_SIZE_MB_26" ]] && [[ $FS_SIZE_MB_26 -ge 270 ]] && [[ $FS_SIZE_MB_26 -le 320 ]]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem on '$LV_NAME_26' has size ${FS_SIZE_MB_26}M (within 270-320 MiB range)." | tee -a ${REPORT_FILE}
             T26_SCORE=$(( T26_SCORE + 20 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem on '$LV_NAME_26' size is ${FS_SIZE_MB_26}M (NOT within 270-320 MiB range)." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine mount point for '$LV_NAME_26' to check filesystem size. Was it mounted?" | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME_26' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T26_SCORE ))
TOTAL=$(( TOTAL + T26_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 27: Users natasha, harry, sarah; Group adminuser
echo -e "${COLOR_INFO}Evaluating Task 27: Users natasha, harry, sarah; Group adminuser${COLOR_RESET}" | tee -a ${REPORT_FILE}
T27_SCORE=0
T27_TOTAL=40
# Check group exists
if getent group adminuser &>/dev/null; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Group 'adminuser' exists." | tee -a ${REPORT_FILE}
     T27_SCORE=$(( T27_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Group 'adminuser' does not exist." | tee -a ${REPORT_FILE}
     groupadd adminuser # Create for subsequent checks
fi
# Check users exist
USERS_EXIST_27=true
for user in natasha harry sarah; do
  if ! id "$user" &>/dev/null; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' does not exist." | tee -a ${REPORT_FILE}
    USERS_EXIST_27=false
  fi
done
if $USERS_EXIST_27; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users natasha, harry, and sarah exist." | tee -a ${REPORT_FILE}
    T27_SCORE=$(( T27_SCORE + 10 ))
    # Check natasha/harry group membership
    MEMBERSHIP_OK=true
    if ! id -nG natasha | grep -qw adminuser; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'natasha' is not in supplementary group 'adminuser'." | tee -a ${REPORT_FILE}
        MEMBERSHIP_OK=false
    fi
    if ! id -nG harry | grep -qw adminuser; then # Typo in question 'haryy' vs 'harry', checking 'harry'
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'harry' is not in supplementary group 'adminuser'." | tee -a ${REPORT_FILE}
        MEMBERSHIP_OK=false
    fi
    if $MEMBERSHIP_OK; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users natasha and harry are in group 'adminuser'." | tee -a ${REPORT_FILE}
        T27_SCORE=$(( T27_SCORE + 10 ))
    fi
    # Check sarah shell and group membership
    SARAH_OK=true
    if ! getent passwd sarah | cut -d: -f7 | grep -q '/sbin/nologin'; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'sarah' shell is not /sbin/nologin." | tee -a ${REPORT_FILE}
        SARAH_OK=false
    fi
    if id -nG sarah | grep -qw adminuser; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'sarah' IS incorrectly a member of 'adminuser'." | tee -a ${REPORT_FILE}
        SARAH_OK=false
    fi
    if $SARAH_OK; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'sarah' has shell /sbin/nologin and is not in 'adminuser'." | tee -a ${REPORT_FILE}
        T27_SCORE=$(( T27_SCORE + 5 ))
    fi
    # Check passwords set
    PW_SET_OK_27=true
    for user in natasha harry sarah; do
        if ! grep "^${user}:" /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' password does not appear to be set." | tee -a ${REPORT_FILE}
             PW_SET_OK_27=false
        fi
    done
     if $PW_SET_OK_27; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Passwords for natasha, harry, sarah appear to be set." | tee -a ${REPORT_FILE}
         T27_SCORE=$(( T27_SCORE + 10 ))
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot perform checks because not all users exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T27_SCORE ))
TOTAL=$(( TOTAL + T27_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 28: Permissions/ACLs on /var/tmp/fstab
echo -e "${COLOR_INFO}Evaluating Task 28: Permissions/ACLs on /var/tmp/fstab${COLOR_RESET}" | tee -a ${REPORT_FILE}
T28_SCORE=0
T28_TOTAL=40
TARGET_FILE_28="/var/tmp/fstab"
# Check target exists
if [ -f "$TARGET_FILE_28" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t File '$TARGET_FILE_28' exists." | tee -a ${REPORT_FILE}
    T28_SCORE=$(( T28_SCORE + 5 ))
    # Check owner/group
    OWNER=$(stat -c %U "$TARGET_FILE_28")
    GROUP=$(stat -c %G "$TARGET_FILE_28")
    if [[ "$OWNER" == "root" ]] && [[ "$GROUP" == "root" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t File owner ($OWNER) and group ($GROUP) are correct." | tee -a ${REPORT_FILE}
        T28_SCORE=$(( T28_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t File owner ($OWNER) or group ($GROUP) is incorrect (expected root:root)." | tee -a ${REPORT_FILE}
    fi
    # Check no execute bits set
    PERMS_28=$(stat -c %A "$TARGET_FILE_28")
    if [[ "$PERMS_28" != *x* ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t No execute permissions found ($PERMS_28)." | tee -a ${REPORT_FILE}
         T28_SCORE=$(( T28_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Execute permission found ($PERMS_28)." | tee -a ${REPORT_FILE}
    fi
    # Check ACLs
    ACL_OUTPUT_28=$(getfacl "$TARGET_FILE_28" 2>/dev/null)
    NATASHA_ACL_OK=false
    HARRY_ACL_OK=false
    OTHER_ACL_OK=false
    if echo "$ACL_OUTPUT_28" | grep -Eq "^user:natasha:rw-"; then
        NATASHA_ACL_OK=true
    fi
    if echo "$ACL_OUTPUT_28" | grep -Eq "^user:harry:---"; then
        HARRY_ACL_OK=true
    fi
    # Check effective other permissions via getfacl output (accounts for mask)
    if echo "$ACL_OUTPUT_28" | grep -Eq "^other::r--"; then
        OTHER_ACL_OK=true
    fi

    if $NATASHA_ACL_OK; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ACL for natasha (rw-) found." | tee -a ${REPORT_FILE}
        T28_SCORE=$(( T28_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for natasha (rw-) incorrect or missing." | tee -a ${REPORT_FILE}
    fi
    if $HARRY_ACL_OK; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ACL for harry (---) found." | tee -a ${REPORT_FILE}
        T28_SCORE=$(( T28_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for harry (---) incorrect or missing." | tee -a ${REPORT_FILE}
    fi
     if $OTHER_ACL_OK; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Effective other permissions (r--) found via getfacl." | tee -a ${REPORT_FILE}
        T28_SCORE=$(( T28_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Effective other permissions (r--) incorrect or missing via getfacl." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t File '$TARGET_FILE_28' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T28_SCORE ))
TOTAL=$(( TOTAL + T28_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 29: Cron Job for Natasha (echo hiya) + crond status
echo -e "${COLOR_INFO}Evaluating Task 29: Cron Job for Natasha (echo hiya) + crond status${COLOR_RESET}" | tee -a ${REPORT_FILE}
T29_SCORE=0
T29_TOTAL=20
CRON_CMD_29="/bin/echo hiya"
CRON_SCHED_29="23 14 \* \* \*"
# Ensure user natasha exists
id natasha &>/dev/null || useradd natasha

# Check natasha's crontab for the entry
if crontab -l -u natasha 2>/dev/null | grep -Fq "$CRON_SCHED_29 $CRON_CMD_29"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found scheduled task for natasha: '$CRON_SCHED_29 $CRON_CMD_29'" | tee -a ${REPORT_FILE}
    T29_SCORE=$(( T29_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find '$CRON_SCHED_29 $CRON_CMD_29' in natasha's crontab." | tee -a ${REPORT_FILE}
fi
# Check crond service status
if systemctl is-enabled crond --quiet && systemctl is-active crond --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t crond service is running and enabled." | tee -a ${REPORT_FILE}
    T29_SCORE=$(( T29_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t crond service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T29_SCORE ))
TOTAL=$(( TOTAL + T29_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 30: Shared Directory /home/admins (adminuser)
echo -e "${COLOR_INFO}Evaluating Task 30: Shared Directory /home/admins (adminuser)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T30_SCORE=0
T30_TOTAL=30
ADMINS_DIR_30="/home/admins"
GROUP_NAME_30="adminuser"
# Check group exists
if ! getent group $GROUP_NAME_30 &>/dev/null; then
    groupadd $GROUP_NAME_30 # Create if missing for checks
    echo -e "${COLOR_FAIL}[INFO]${COLOR_RESET}\t Group '$GROUP_NAME_30' did not exist, created for further checks (no points)." | tee -a ${REPORT_FILE}
fi

if [ -d "$ADMINS_DIR_30" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$ADMINS_DIR_30' exists." | tee -a ${REPORT_FILE}
    T30_SCORE=$(( T30_SCORE + 10 ))
    # Check group owner
    if [[ $(stat -c %G "$ADMINS_DIR_30") == "$GROUP_NAME_30" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$ADMINS_DIR_30' is group-owned by '$GROUP_NAME_30'." | tee -a ${REPORT_FILE}
        T30_SCORE=$(( T30_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR_30' is not group-owned by '$GROUP_NAME_30'." | tee -a ${REPORT_FILE}
    fi
    # Check permissions (rwxrws--- assuming group needs rwx) and SGID bit
    PERMS_30=$(stat -c %A "$ADMINS_DIR_30")
    # Check for group write and SGID explicitly
    if [[ -g "$ADMINS_DIR_30" ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$ADMINS_DIR_30' has the SGID permission set." | tee -a ${REPORT_FILE}
         T30_SCORE=$(( T30_SCORE + 5 ))
         if [[ "${PERMS_30:5:1}" == "w" ]]; then # Check 6th char (group write)
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$ADMINS_DIR_30' has group write permission." | tee -a ${REPORT_FILE}
            T30_SCORE=$(( T30_SCORE + 5 ))
         else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR_30' has SGID but lacks group write permission ($PERMS_30)." | tee -a ${REPORT_FILE}
         fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR_30' does not have SGID set ($PERMS_30)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$ADMINS_DIR_30' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T30_SCORE ))
TOTAL=$(( TOTAL + T30_TOTAL ))
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
echo -e "${COLOR_INFO}Your total score for Batch 3 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"