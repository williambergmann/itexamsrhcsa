#!/bin/bash
# Grader script - Batch 10 (Based on Questions 92-101)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch10.txt"
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
echo "Starting Grade Evaluation Batch 10 - $(date)" | tee -a ${REPORT_FILE}
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

### TASK 92: Configure httpd with index page
echo -e "${COLOR_INFO}Evaluating Task 92: Configure httpd with index page${COLOR_RESET}" | tee -a ${REPORT_FILE}
T92_SCORE=0
T92_TOTAL=25
# Check httpd installed
if rpm -q httpd &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t httpd package is installed." | tee -a ${REPORT_FILE}
    T92_SCORE=$(( T92_SCORE + 5 ))
    # Check index.html exists (basic check)
    if [ -f /var/www/html/index.html ]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t /var/www/html/index.html exists." | tee -a ${REPORT_FILE}
        T92_SCORE=$(( T92_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t /var/www/html/index.html does not exist." | tee -a ${REPORT_FILE}
    fi
    # Check httpd service status
    if systemctl is-enabled httpd --quiet && systemctl is-active httpd --quiet; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t httpd service is running and enabled." | tee -a ${REPORT_FILE}
        T92_SCORE=$(( T92_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t httpd service is not running or not enabled." | tee -a ${REPORT_FILE}
    fi
     # Check firewall allows http
    if firewall-cmd --list-services --permanent 2>/dev/null | grep -qw http || firewall-cmd --list-ports --permanent 2>/dev/null | grep -qw 80/tcp ; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Firewall permanently allows http service or port 80/tcp." | tee -a ${REPORT_FILE}
        T92_SCORE=$(( T92_SCORE + 10 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Firewall does not appear to allow http service or port 80/tcp permanently." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t httpd package is not installed." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T92_SCORE ))
TOTAL=$(( TOTAL + T92_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 93: LVM vg0 (PE 16M), LV lv0 (20 LE), ext3, Mount /data
echo -e "${COLOR_INFO}Evaluating Task 93: LVM vg0 (PE 16M), LV lv0 (20 LE), ext3, Mount /data${COLOR_RESET}" | tee -a ${REPORT_FILE}
T93_SCORE=0
T93_TOTAL=50
VG_NAME_93="vg0"
LV_NAME_93="lv0"
MOUNT_POINT_93="/data"
echo -e "${COLOR_INFO}[WARN]${COLOR_RESET}\t Task 93 uses mount point '$MOUNT_POINT_93'. Grading assumes this task was performed last for this mount point." | tee -a ${REPORT_FILE}

# Check VG exists
if vgs $VG_NAME_93 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Volume Group '$VG_NAME_93' exists." | tee -a ${REPORT_FILE}
    T93_SCORE=$(( T93_SCORE + 5 ))
    # Check PE Size
    if vgdisplay $VG_NAME_93 | grep -q "PE Size .* 16\.00 MiB"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t VG '$VG_NAME_93' PE Size is 16 MiB." | tee -a ${REPORT_FILE}
        T93_SCORE=$(( T93_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t VG '$VG_NAME_93' PE Size is NOT 16 MiB." | tee -a ${REPORT_FILE}
    fi
    # Check LV exists
    LV_PATH_93="/dev/${VG_NAME_93}/${LV_NAME_93}"
    if lvs $LV_PATH_93 &>/dev/null; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_93' exists." | tee -a ${REPORT_FILE}
        T93_SCORE=$(( T93_SCORE + 5 ))
        # Check LV Extent Size
        if [[ $(lvdisplay $LV_PATH_93 | awk '/Current LE/ {print $3}') == 20 ]]; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_93' size is 20 extents." | tee -a ${REPORT_FILE}
            T93_SCORE=$(( T93_SCORE + 5 ))
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_93' size is not 20 extents." | tee -a ${REPORT_FILE}
        fi
        # Check Filesystem Format (ext3 requested, allow ext4)
        if blkid $LV_PATH_93 | grep -qE 'TYPE="ext3"|TYPE="ext4"'; then
            FS_TYPE_93=$(blkid -s TYPE -o value $LV_PATH_93)
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_93' is formatted with $FS_TYPE_93." | tee -a ${REPORT_FILE}
            T93_SCORE=$(( T93_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_93' is not formatted with ext3 (or ext4)." | tee -a ${REPORT_FILE}
        fi
        # Check Mount Point directory
        if [ -d "$MOUNT_POINT_93" ]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Mount point '$MOUNT_POINT_93' exists." | tee -a ${REPORT_FILE}
             T93_SCORE=$(( T93_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Mount point '$MOUNT_POINT_93' does not exist." | tee -a ${REPORT_FILE}
        fi
         # Check Persistent Mount (fstab required by answer)
        if grep -Fw "$MOUNT_POINT_93" /etc/fstab | grep -Eq 'ext3|ext4' | grep -v "^#" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_93'." | tee -a ${REPORT_FILE}
             T93_SCORE=$(( T93_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_93'." | tee -a ${REPORT_FILE}
        fi
         # Check If Currently Mounted
        if findmnt "$MOUNT_POINT_93" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t '$LV_NAME_93' is currently mounted on '$MOUNT_POINT_93'." | tee -a ${REPORT_FILE}
             T93_SCORE=$(( T93_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t '$LV_NAME_93' is not currently mounted on '$MOUNT_POINT_93'." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME_93' not found in VG '$VG_NAME_93'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Volume Group '$VG_NAME_93' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T93_SCORE ))
TOTAL=$(( TOTAL + T93_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 94: Grep [abcde]
echo -e "${COLOR_INFO}Evaluating Task 94: Grep [abcde]${COLOR_RESET}" | tee -a ${REPORT_FILE}
T94_SCORE=0
T94_TOTAL=10
# Source file assumed downloaded/created as /tmp/testfile
SOURCE_FILE_94="/tmp/testfile"
TARGET_FILE_94="/mnt/answer"
SEARCH_PATTERN_94="[abcde]" # This regex matches lines containing a, b, c, d, OR e
mkdir -p /mnt # Ensure mount base exists
# Create dummy source
echo "Line with a vowel" > "$SOURCE_FILE_94"
echo "Line with numbers 123" >> "$SOURCE_FILE_94"
echo "Line with d" >> "$SOURCE_FILE_94"
echo "xylophone" >> "$SOURCE_FILE_94"

# Check if target file exists
if [ -f "$TARGET_FILE_94" ]; then
     # Basic content check: Does it contain lines expected and not lines unexpected?
     if grep -q "vowel" "$TARGET_FILE_94" && grep -q "Line with d" "$TARGET_FILE_94" && grep -q "xylophone" "$TARGET_FILE_94" && ! grep -q "numbers" "$TARGET_FILE_94" ; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target file '$TARGET_FILE_94' exists and seems to contain correct lines." | tee -a ${REPORT_FILE}
        T94_SCORE=$(( T94_SCORE + 10 ))
     else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE_94' exists but content seems incorrect based on '[abcde]' pattern." | tee -a ${REPORT_FILE}
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE_94' does not exist." | tee -a ${REPORT_FILE}
fi
# Clean up dummy source file
rm -f "$SOURCE_FILE_94" &>/dev/null
SCORE=$(( SCORE + T94_SCORE ))
TOTAL=$(( TOTAL + T94_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 95: SELinux Persistent Enforcing Mode (Rehash)
echo -e "${COLOR_INFO}Evaluating Task 95: SELinux Persistent Enforcing Mode (Rehash)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T95_SCORE=0
T95_TOTAL=5
# Check configuration file /etc/selinux/config
if grep -Eq '^\s*SELINUX\s*=\s*enforcing' /etc/selinux/config; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t SELINUX=enforcing found in /etc/selinux/config." | tee -a ${REPORT_FILE}
    T95_SCORE=$(( T95_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t SELINUX=enforcing NOT found or commented out in /etc/selinux/config." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T95_SCORE ))
TOTAL=$(( TOTAL + T95_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 96: YUM/DNF Repository (server.domain11)
echo -e "${COLOR_INFO}Evaluating Task 96: YUM/DNF Repository (server.domain11)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T96_SCORE=0
T96_TOTAL=20
REPO_URL_96="http://server.domain11.example.com/pub/x86_64/Server"
REPO_FILE_GLOB_96="/etc/yum.repos.d/*.repo"
FOUND_REPO_96=false
FOUND_GPG_96=false
FOUND_ENABLED_96=false

for repo_file in $REPO_FILE_GLOB_96; do
    if [ -f "$repo_file" ] && grep -Eq "baseurl\s*=\s*${REPO_URL_96}" "$repo_file"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Repository file '$repo_file' found with correct baseurl." | tee -a ${REPORT_FILE}
        T96_SCORE=$(( T96_SCORE + 5 ))
        FOUND_REPO_96=true
        if grep -Eq '^\s*gpgcheck\s*=\s*0' "$repo_file"; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t gpgcheck=0 found in '$repo_file'." | tee -a ${REPORT_FILE}
            T96_SCORE=$(( T96_SCORE + 10 ))
            FOUND_GPG_96=true
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t gpgcheck=0 not found in '$repo_file'." | tee -a ${REPORT_FILE}
        fi
        if grep -Eq '^\s*enabled\s*=\s*1' "$repo_file"; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t enabled=1 found in '$repo_file'." | tee -a ${REPORT_FILE}
            T96_SCORE=$(( T96_SCORE + 5 ))
            FOUND_ENABLED_96=true
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t enabled=1 not found in '$repo_file'." | tee -a ${REPORT_FILE}
        fi
        break # Found matching repo file
    fi
done

if ! $FOUND_REPO_96; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t No repository file found in /etc/yum.repos.d/ with baseurl '$REPO_URL_96'." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T96_SCORE ))
TOTAL=$(( TOTAL + T96_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 97: LVM Resize 'vo' Filesystem (Rehash 2)
echo -e "${COLOR_INFO}Evaluating Task 97: LVM Resize 'vo' Filesystem to ~290MiB (Rehash 2)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T97_SCORE=0
T97_TOTAL=20
LV_NAME_97="vo" # Assuming the name from the question
LV_PATH_97=$(lvs --noheadings -o lv_path,lv_name | awk -v name="$LV_NAME_97" '$2 == name {print $1; exit}')
if [[ -n "$LV_PATH_97" ]] && [[ -b "$LV_PATH_97" ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_97' found." | tee -a ${REPORT_FILE}
    MOUNT_POINT_97=$(findmnt -no TARGET ${LV_PATH_97})
    if [[ -n "$MOUNT_POINT_97" ]]; then
        FS_SIZE_MB_97=$(df -BM --output=size ${MOUNT_POINT_97} 2>/dev/null | tail -n 1 | sed 's/[^0-9]*//g')
        if [[ -n "$FS_SIZE_MB_97" ]] && [[ $FS_SIZE_MB_97 -ge 260 ]] && [[ $FS_SIZE_MB_97 -le 320 ]]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem on '$LV_NAME_97' has size ${FS_SIZE_MB_97}M (within 260-320 MiB range)." | tee -a ${REPORT_FILE}
             T97_SCORE=$(( T97_SCORE + 20 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem on '$LV_NAME_97' size is ${FS_SIZE_MB_97}M (NOT within 260-320 MiB range)." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine mount point for '$LV_NAME_97' to check filesystem size. Was it mounted?" | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME_97' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T97_SCORE ))
TOTAL=$(( TOTAL + T97_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 98: Users/Group adminuser (Rehash 2)
echo -e "${COLOR_INFO}Evaluating Task 98: Users/Group adminuser (Rehash 2)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T98_SCORE=0
T98_TOTAL=40
GROUP_NAME_98="adminuser"
# Check group exists
if getent group $GROUP_NAME_98 &>/dev/null; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Group '$GROUP_NAME_98' exists." | tee -a ${REPORT_FILE}
     T98_SCORE=$(( T98_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Group '$GROUP_NAME_98' does not exist." | tee -a ${REPORT_FILE}
     groupadd $GROUP_NAME_98
fi
# Check users exist
USERS_EXIST_98=true
for user in natasha harry sarah; do
  if ! id "$user" &>/dev/null; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' does not exist." | tee -a ${REPORT_FILE}
    USERS_EXIST_98=false
  fi
done
if $USERS_EXIST_98; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users natasha, harry, and sarah exist." | tee -a ${REPORT_FILE}
    T98_SCORE=$(( T98_SCORE + 10 ))
    # Check natasha/harry group membership
    MEMBERSHIP_OK_98=true
    if ! id -nG natasha | grep -qw $GROUP_NAME_98; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'natasha' is not in supplementary group '$GROUP_NAME_98'." | tee -a ${REPORT_FILE}
        MEMBERSHIP_OK_98=false
    fi
    if ! id -nG harry | grep -qw $GROUP_NAME_98; then # Using 'harry' consistently
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'harry' is not in supplementary group '$GROUP_NAME_98'." | tee -a ${REPORT_FILE}
        MEMBERSHIP_OK_98=false
    fi
    if $MEMBERSHIP_OK_98; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Users natasha and harry are in group '$GROUP_NAME_98'." | tee -a ${REPORT_FILE}
        T98_SCORE=$(( T98_SCORE + 10 ))
    fi
    # Check sarah shell and group membership
    SARAH_OK_98=true
    if ! getent passwd sarah | cut -d: -f7 | grep -q '/sbin/nologin'; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'sarah' shell is not /sbin/nologin." | tee -a ${REPORT_FILE}
        SARAH_OK_98=false
    fi
    if id -nG sarah | grep -qw $GROUP_NAME_98; then
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'sarah' IS incorrectly a member of '$GROUP_NAME_98'." | tee -a ${REPORT_FILE}
        SARAH_OK_98=false
    fi
    if $SARAH_OK_98; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'sarah' has shell /sbin/nologin and is not in '$GROUP_NAME_98'." | tee -a ${REPORT_FILE}
        T98_SCORE=$(( T98_SCORE + 5 ))
    fi
    # Check passwords set
    PW_SET_OK_98=true
    for user in natasha harry sarah; do
        if ! grep "^${user}:" /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$user' password does not appear to be set." | tee -a ${REPORT_FILE}
             PW_SET_OK_98=false
        fi
    done
     if $PW_SET_OK_98; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Passwords for natasha, harry, sarah appear to be set." | tee -a ${REPORT_FILE}
         T98_SCORE=$(( T98_SCORE + 10 ))
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot perform checks because not all users exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T98_SCORE ))
TOTAL=$(( TOTAL + T98_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 99: ACLs on /var/tmp/fstab (Rehash 2)
echo -e "${COLOR_INFO}Evaluating Task 99: ACLs on /var/tmp/fstab (Rehash 2)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T99_SCORE=0
T99_TOTAL=35 # Adjusted scoring slightly
TARGET_FILE_99="/var/tmp/fstab"
# Ensure users exist
id natasha &>/dev/null || useradd natasha
id harry &>/dev/null || useradd harry

# Check target exists
if [ -f "$TARGET_FILE_99" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t File '$TARGET_FILE_99' exists." | tee -a ${REPORT_FILE}
    T99_SCORE=$(( T99_SCORE + 5 ))
    # Check owner/group
    OWNER_99=$(stat -c %U "$TARGET_FILE_99")
    GROUP_99=$(stat -c %G "$TARGET_FILE_99")
    if [[ "$OWNER_99" == "root" ]] && [[ "$GROUP_99" == "root" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t File owner ($OWNER_99) and group ($GROUP_99) are correct (root:root)." | tee -a ${REPORT_FILE}
        T99_SCORE=$(( T99_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t File owner ($OWNER_99) or group ($GROUP_99) is incorrect (expected root:root)." | tee -a ${REPORT_FILE}
    fi
    # Check no standard execute bits set
    PERMS_99=$(stat -c %A "$TARGET_FILE_99")
    if [[ "$PERMS_99" != *x* ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t No standard execute permissions found ($PERMS_99)." | tee -a ${REPORT_FILE}
         T99_SCORE=$(( T99_SCORE + 5 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Standard Unix execute permission found ($PERMS_99)." | tee -a ${REPORT_FILE}
    fi
    # Check ACLs
    ACL_OUTPUT_99=$(getfacl "$TARGET_FILE_99" 2>/dev/null)
    NATASHA_ACL_OK=false
    HARRY_ACL_OK=false
    OTHER_ACL_OK=false
    if echo "$ACL_OUTPUT_99" | grep -Eq "^user:natasha:rw-"; then NATASHA_ACL_OK=true; fi
    if echo "$ACL_OUTPUT_99" | grep -Eq "^user:harry:---"; then HARRY_ACL_OK=true; fi
    if echo "$ACL_OUTPUT_99" | grep -Eq "^other::r--"; then OTHER_ACL_OK=true; fi

    if $NATASHA_ACL_OK; then echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ACL for natasha (rw-) found."; T99_SCORE=$(( T99_SCORE + 10 )); else echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for natasha (rw-) incorrect/missing."; fi
    if $HARRY_ACL_OK; then echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ACL for harry (---) found."; T99_SCORE=$(( T99_SCORE + 5 )); else echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ACL for harry (---) incorrect/missing."; fi
    if $OTHER_ACL_OK; then echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Effective other permissions (r--) found via getfacl."; T99_SCORE=$(( T99_SCORE + 5 )); else echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Effective other permissions (r--) incorrect/missing."; fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t File '$TARGET_FILE_99' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T99_SCORE ))
TOTAL=$(( TOTAL + T99_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 100: Cron Job for Natasha (echo hiya - Rehash)
echo -e "${COLOR_INFO}Evaluating Task 100: Cron Job for Natasha (echo hiya - Rehash)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T100_SCORE=0
T100_TOTAL=10
CRON_CMD_100="/bin/echo hiya"
CRON_SCHED_100="23 14 \* \* \*"
# Ensure user natasha exists
id natasha &>/dev/null || useradd natasha

# Check natasha's crontab for the entry
if crontab -l -u natasha 2>/dev/null | grep -Fq "$CRON_SCHED_100 $CRON_CMD_100"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found scheduled task for natasha: '$CRON_SCHED_100 $CRON_CMD_100'" | tee -a ${REPORT_FILE}
    T100_SCORE=$(( T100_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find '$CRON_SCHED_100 $CRON_CMD_100' in natasha's crontab." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T100_SCORE ))
TOTAL=$(( TOTAL + T100_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 101: Shared Directory /home/admins adminuser (Rehash 2)
echo -e "${COLOR_INFO}Evaluating Task 101: Shared Directory /home/admins adminuser (Rehash 2)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T101_SCORE=0
T101_TOTAL=30
DIR_101="/home/admins"
GROUP_NAME_101="adminuser"
# Check group exists
if ! getent group $GROUP_NAME_101 &>/dev/null; then
    groupadd $GROUP_NAME_101
    echo -e "${COLOR_FAIL}[INFO]${COLOR_RESET}\t Group '$GROUP_NAME_101' did not exist, created for further checks (no points)." | tee -a ${REPORT_FILE}
fi
# Check directory exists
if [ -d "$DIR_101" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$DIR_101' exists." | tee -a ${REPORT_FILE}
    T101_SCORE=$(( T101_SCORE + 10 ))
    # Check group owner
    if [[ $(stat -c %G "$DIR_101") == "$GROUP_NAME_101" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$DIR_101' is group-owned by '$GROUP_NAME_101'." | tee -a ${REPORT_FILE}
        T101_SCORE=$(( T101_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_101' is not group-owned by '$GROUP_NAME_101'." | tee -a ${REPORT_FILE}
    fi
    # Check permissions (rwxrws--- : 2770 expected for group RWX + SGID, others no access)
    PERMS_101=$(stat -c %A "$DIR_101")
    PERMS_OCT_101=$(stat -c %a "$DIR_101")
    if [[ "$PERMS_OCT_101" == "2770" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Directory '$DIR_101' has correct permissions (2770 -> drwxrws---)." | tee -a ${REPORT_FILE}
        T101_SCORE=$(( T101_SCORE + 15 )) # Points for perms and SGID
    elif [[ -g "$DIR_101" ]]; then
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_101' has SGID bit but permissions are $PERMS_STR_101 ($PERMS_OCT_101), expected 2770 (drwxrws---)." | tee -a ${REPORT_FILE}
         T101_SCORE=$(( T101_SCORE + 5 )) # Partial for SGID
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_101' does not have correct permissions or SGID bit set ($PERMS_STR_101 / $PERMS_OCT_101), expected 2770." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_101' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T101_SCORE ))
TOTAL=$(( TOTAL + T101_TOTAL ))
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
echo -e "${COLOR_INFO}Your total score for Batch 10 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"