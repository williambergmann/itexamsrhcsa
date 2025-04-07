#!/bin/bash
# Grader script - Batch 4 (Questions 31-40)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch4.txt"
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
echo "Starting Grade Evaluation Batch 4 - $(date)" | tee -a ${REPORT_FILE}
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

### TASK 31: Kernel Update and Default Boot
echo -e "${COLOR_INFO}Evaluating Task 31: Kernel Update and Default Boot${COLOR_RESET}" | tee -a ${REPORT_FILE}
T31_SCORE=0
T31_TOTAL=15 # Reduced points due to external dependency/version check difficulty
# Check if multiple kernel packages are installed
KERNEL_COUNT=$(rpm -q kernel kernel-core | wc -l) # Check both kernel and kernel-core
if [[ $KERNEL_COUNT -gt 1 ]]; then # Check for at least 2 kernel-related packages
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Multiple kernel packages found (Count: $KERNEL_COUNT)." | tee -a ${REPORT_FILE}
    T31_SCORE=$(( T31_SCORE + 5 ))
    # Get default kernel path and current running kernel path
    DEFAULT_KERNEL=$(grubby --default-kernel 2>/dev/null)
    RUNNING_KERNEL="/boot/vmlinuz-$(uname -r)"
    LATEST_KERNEL=$(ls -t /boot/vmlinuz-* | head -n 1) # Assuming latest by time is newest installed

    if [[ -n "$DEFAULT_KERNEL" ]]; then
         echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t Default kernel path is $DEFAULT_KERNEL" | tee -a ${REPORT_FILE}
         # Simple check: is default different from running (implies update happened and maybe default changed?)
         # More reliable: Check if default matches the *latest installed* kernel path
         if [[ "$DEFAULT_KERNEL" == "$LATEST_KERNEL" ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default kernel appears to be the latest installed kernel." | tee -a ${REPORT_FILE}
              T31_SCORE=$(( T31_SCORE + 10 ))
         elif [[ "$DEFAULT_KERNEL" != "$RUNNING_KERNEL" ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default kernel is different from currently running kernel (suggests change)." | tee -a ${REPORT_FILE}
              T31_SCORE=$(( T31_SCORE + 5 )) # Partial credit
         else
              echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default kernel ($DEFAULT_KERNEL) appears unchanged or doesn't match latest ($LATEST_KERNEL)." | tee -a ${REPORT_FILE}
         fi
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not determine default kernel using grubby." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Only one kernel package seems installed. Cannot verify update/default change." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T31_SCORE ))
TOTAL=$(( TOTAL + T31_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 32: LDAP Authentication Client Config (v2)
echo -e "${COLOR_INFO}Evaluating Task 32: LDAP Authentication Client Config (v2)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T32_SCORE=0
T32_TOTAL=20
# Check if user ldapuser1 can be resolved via NSS
if getent passwd ldapuser1 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'ldapuser1' found via getent (NSS likely configured)." | tee -a ${REPORT_FILE}
    T32_SCORE=$(( T32_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'ldapuser1' not found via getent. Check LDAP client config (authselect/sssd/nsswitch/pam)." | tee -a ${REPORT_FILE}
fi
# Check if sssd is running and enabled (common implementation method)
if systemctl is-enabled sssd --quiet && systemctl is-active sssd --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t sssd service is running and enabled." | tee -a ${REPORT_FILE}
    T32_SCORE=$(( T32_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t sssd service is not running or not enabled (check if used)." | tee -a ${REPORT_FILE}
fi
# Rough check for Base DN in sssd config (adjust path if needed)
if [ -f /etc/sssd/sssd.conf ] && grep -iq 'ldap_search_base\s*=\s*dc=example,dc=com' /etc/sssd/sssd.conf; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Base DN found in sssd.conf." | tee -a ${REPORT_FILE}
    T32_SCORE=$(( T32_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Base DN 'dc=example,dc=com' not found in /etc/sssd/sssd.conf (check config method)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T32_SCORE ))
TOTAL=$(( TOTAL + T32_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 33: NTP Client Configuration (chrony)
echo -e "${COLOR_INFO}Evaluating Task 33: NTP Client Configuration (chrony)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T33_SCORE=0
T33_TOTAL=15
NTP_SERVER="classroom.example.com"
# Check chronyd service status
if systemctl is-enabled chronyd --quiet && systemctl is-active chronyd --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t chronyd service is running and enabled." | tee -a ${REPORT_FILE}
    T33_SCORE=$(( T33_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t chronyd service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check configuration for the specified server
if grep -Eq "^\s*(server|pool)\s+${NTP_SERVER}" /etc/chrony.conf || chronyc sources 2>/dev/null | grep -q "$NTP_SERVER"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Time server '$NTP_SERVER' found in chrony configuration or sources." | tee -a ${REPORT_FILE}
    T33_SCORE=$(( T33_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Time server '$NTP_SERVER' not found in /etc/chrony.conf or active sources." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T33_SCORE ))
TOTAL=$(( TOTAL + T33_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 34: Autofs for NFS Home Directories (/home/guests)
echo -e "${COLOR_INFO}Evaluating Task 34: Autofs for NFS Home Directories (/home/guests)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T34_SCORE=0
T34_TOTAL=40
AUTOFS_BASE="/home/guests" # Based on question description, despite answer variations
AUTOFS_MAP="/etc/auto.ldap" # Assumed map name based on commonality with Q12 answer
NFS_SERVER="server.domain11.example.com"

# Check autofs package installed
if ! rpm -q autofs &>/dev/null; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs package not found." | tee -a ${REPORT_FILE}
    TOTAL=$(( TOTAL + T34_TOTAL )) # Need to add total even if skipping
    echo -e "\n" | tee -a ${REPORT_FILE}
    # Skip further checks if package missing
    continue
fi
# Check autofs service status
if systemctl is-enabled autofs --quiet && systemctl is-active autofs --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs service is running and enabled." | tee -a ${REPORT_FILE}
    T34_SCORE=$(( T34_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check master map configuration for the base directory
if grep -Eq "^\s*${AUTOFS_BASE}\s+${AUTOFS_MAP}" /etc/auto.master || grep -Eq "^\s*${AUTOFS_BASE}\s+${AUTOFS_MAP}" /etc/auto.master.d/*.conf &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs master map entry found for '$AUTOFS_BASE' pointing to '$AUTOFS_MAP'." | tee -a ${REPORT_FILE}
    T34_SCORE=$(( T34_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs master map entry for '$AUTOFS_BASE' -> '$AUTOFS_MAP' not found." | tee -a ${REPORT_FILE}
fi
# Check map file existence
if [ -f "$AUTOFS_MAP" ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Map file '$AUTOFS_MAP' exists." | tee -a ${REPORT_FILE}
    T34_SCORE=$(( T34_SCORE + 5 ))
    # Check map file content for wildcard entry
    # Needs fstype=nfs, rw, and correct server:/path/& structure
    # Regex allows for options variations, requires fstype, rw
    if grep -Eq "^\s*\*\s+-fstype=nfs.*,rw.*${NFS_SERVER}:/home/guests/&" "$AUTOFS_MAP" || \
       grep -Eq "^\s*\*\s+-rw.*,fstype=nfs.*${NFS_SERVER}:/home/guests/&" "$AUTOFS_MAP"; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Wildcard entry '*' configured correctly in '$AUTOFS_MAP' for '${NFS_SERVER}:/home/guests/&' with rw,fstype=nfs." | tee -a ${REPORT_FILE}
         T34_SCORE=$(( T34_SCORE + 15 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Wildcard entry '*' for server '${NFS_SERVER}:/home/guests/&' not found or options incorrect (need rw, fstype=nfs) in '$AUTOFS_MAP'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Map file '$AUTOFS_MAP' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T34_SCORE ))
TOTAL=$(( TOTAL + T34_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 35: User iar
echo -e "${COLOR_INFO}Evaluating Task 35: User iar${COLOR_RESET}" | tee -a ${REPORT_FILE}
T35_SCORE=0
T35_TOTAL=20
if id iar &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'iar' exists." | tee -a ${REPORT_FILE}
    T35_SCORE=$(( T35_SCORE + 5 ))
    # Check UID
    if [[ $(id -u iar) == 3400 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'iar' UID is 3400." | tee -a ${REPORT_FILE}
        T35_SCORE=$(( T35_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'iar' UID is not 3400 (Found: $(id -u iar))." | tee -a ${REPORT_FILE}
    fi
    # Check if password is set
    if grep '^iar:' /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'iar' password appears to be set." | tee -a ${REPORT_FILE}
        T35_SCORE=$(( T35_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'iar' password does not appear to be set in /etc/shadow." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'iar' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T35_SCORE ))
TOTAL=$(( TOTAL + T35_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 36: Add 500M Swap Partition
echo -e "${COLOR_INFO}Evaluating Task 36: Add 500M Swap Partition${COLOR_RESET}" | tee -a ${REPORT_FILE}
T36_SCORE=0
T36_TOTAL=20
SWAP_COUNT_36=$(swapon -s | sed '1d' | wc -l)
ORIG_SWAP_DEVICE_36=$(swapon -s | sed '1d' | awk '{print $1}' | head -n 1)

# Check if more than one swap space is active
if [[ $SWAP_COUNT_36 -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found more than one active swap space." | tee -a ${REPORT_FILE}
    T36_SCORE=$(( T36_SCORE + 10 ))
    # Check /etc/fstab for a persistent swap entry (different from original)
    if grep -w swap /etc/fstab | grep -v "$ORIG_SWAP_DEVICE_36" | grep -v "^#" | grep -q swap; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found a persistent swap entry in /etc/fstab (different from original)." | tee -a ${REPORT_FILE}
        T36_SCORE=$(( T36_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not find a persistent swap entry in /etc/fstab for the additional swap space." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find more than one active swap space (expected original + new ~500M)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T36_SCORE ))
TOTAL=$(( TOTAL + T36_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 37: Find and Copy jack's Files
echo -e "${COLOR_INFO}Evaluating Task 37: Find and Copy jack's Files${COLOR_RESET}" | tee -a ${REPORT_FILE}
T37_SCORE=0
T37_TOTAL=10
TARGET_DIR_37="/root/findresults"
# Ensure user jack exists for test, create dummy file
id jack &>/dev/null || useradd jack
touch /tmp/jack_test_file.tmp && chown jack:jack /tmp/jack_test_file.tmp

# Simple check: does the directory exist and is it non-empty?
if [ -d "$TARGET_DIR_37" ]; then
    if [ -n "$(ls -A $TARGET_DIR_37)" ]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target directory '$TARGET_DIR_37' exists and contains files (assuming copy worked)." | tee -a ${REPORT_FILE}
        T37_SCORE=$(( T37_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target directory '$TARGET_DIR_37' exists but is empty." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target directory '$TARGET_DIR_37' does not exist." | tee -a ${REPORT_FILE}
fi
# Cleanup dummy file
rm -f /tmp/jack_test_file.tmp
SCORE=$(( SCORE + T37_SCORE ))
TOTAL=$(( TOTAL + T37_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 38: Grep 'seismic'
echo -e "${COLOR_INFO}Evaluating Task 38: Grep 'seismic'${COLOR_RESET}" | tee -a ${REPORT_FILE}
T38_SCORE=0
T38_TOTAL=10
SOURCE_FILE_38="/usr/share/dict/words"
TARGET_FILE_38="/root/lines.txt"
SEARCH_TERM_38="seismic"
NON_TERM="apple" # Assumed non-match word

# Check if target file exists
if [ -f "$TARGET_FILE_38" ]; then
     # Check content: contains term, does not contain non-term, is not empty
     if grep -q "$SEARCH_TERM_38" "$TARGET_FILE_38" && ! grep -qw "$NON_TERM" "$TARGET_FILE_38" && [ -s "$TARGET_FILE_38" ] ; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target file '$TARGET_FILE_38' exists and seems to contain correct lines." | tee -a ${REPORT_FILE}
        T38_SCORE=$(( T38_SCORE + 10 ))
     else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE_38' exists but content seems incorrect or empty." | tee -a ${REPORT_FILE}
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE_38' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T38_SCORE ))
TOTAL=$(( TOTAL + T38_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 39: Tar Backup
echo -e "${COLOR_INFO}Evaluating Task 39: Tar Backup${COLOR_RESET}" | tee -a ${REPORT_FILE}
T39_SCORE=0
T39_TOTAL=10
ARCHIVE_FILE_39="/root/backup.tar.bz2"
SOURCE_DIR_39="/usr/local"
# Ensure source exists for testing listing
mkdir -p ${SOURCE_DIR_39}/bin ${SOURCE_DIR_39}/lib
touch ${SOURCE_DIR_39}/bin/dummy_exec

# Check if archive file exists
if [ -f "$ARCHIVE_FILE_39" ]; then
     # Check if it's a valid bzip2 tarball and contains expected path structure
     if tar tfj "$ARCHIVE_FILE_39" &>/dev/null && tar tfj "$ARCHIVE_FILE_39" | grep -q 'usr/local/bin'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Archive '$ARCHIVE_FILE_39' exists, is valid bzip2 tar, and contains expected paths." | tee -a ${REPORT_FILE}
        T39_SCORE=$(( T39_SCORE + 10 ))
     else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Archive '$ARCHIVE_FILE_39' exists but is not valid bzip2 tar or content structure is wrong." | tee -a ${REPORT_FILE}
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Archive file '$ARCHIVE_FILE_39' does not exist." | tee -a ${REPORT_FILE}
fi
# Cleanup dummy dirs/files
rm -rf ${SOURCE_DIR_39}/bin ${SOURCE_DIR_39}/lib
SCORE=$(( SCORE + T39_SCORE ))
TOTAL=$(( TOTAL + T39_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 40: LVM 'database' in VG 'datastore' (PE 16M), ext3, Mount /mnt/database
echo -e "${COLOR_INFO}Evaluating Task 40: LVM 'database' in VG 'datastore' (PE 16M), ext3, Mount /mnt/database${COLOR_RESET}" | tee -a ${REPORT_FILE}
T40_SCORE=0
T40_TOTAL=50
VG_NAME_40="datastore"
LV_NAME_40="database"
MOUNT_POINT_40="/mnt/database"
# Check VG exists
if vgs $VG_NAME_40 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Volume Group '$VG_NAME_40' exists." | tee -a ${REPORT_FILE}
    T40_SCORE=$(( T40_SCORE + 5 ))
    # Check PE Size
    if vgdisplay $VG_NAME_40 | grep -q "PE Size .* 16\.00 MiB"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t VG '$VG_NAME_40' PE Size is 16 MiB." | tee -a ${REPORT_FILE}
        T40_SCORE=$(( T40_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t VG '$VG_NAME_40' PE Size is NOT 16 MiB." | tee -a ${REPORT_FILE}
    fi
    # Check LV exists
    LV_PATH_40="/dev/${VG_NAME_40}/${LV_NAME_40}"
    if lvs $LV_PATH_40 &>/dev/null; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_40' exists." | tee -a ${REPORT_FILE}
        T40_SCORE=$(( T40_SCORE + 5 ))
        # Check LV Extent Size
        if [[ $(lvdisplay $LV_PATH_40 | awk '/Current LE/ {print $3}') == 50 ]]; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_40' size is 50 extents." | tee -a ${REPORT_FILE}
            T40_SCORE=$(( T40_SCORE + 5 ))
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_40' size is not 50 extents." | tee -a ${REPORT_FILE}
        fi
        # Check Filesystem Format
        if blkid $LV_PATH_40 | grep -q 'TYPE="ext3"'; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_40' is formatted with ext3." | tee -a ${REPORT_FILE}
            T40_SCORE=$(( T40_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_40' is not formatted with ext3." | tee -a ${REPORT_FILE}
        fi
        # Check Mount Point directory
        if [ -d "$MOUNT_POINT_40" ]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Mount point '$MOUNT_POINT_40' exists." | tee -a ${REPORT_FILE}
             T40_SCORE=$(( T40_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Mount point '$MOUNT_POINT_40' does not exist." | tee -a ${REPORT_FILE}
        fi
         # Check Persistent Mount (fstab required by answer)
        if grep -Fw "$MOUNT_POINT_40" /etc/fstab | grep -w ext3 | grep -v "^#" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_40'." | tee -a ${REPORT_FILE}
             T40_SCORE=$(( T40_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_40'." | tee -a ${REPORT_FILE}
        fi
         # Check If Currently Mounted
        if findmnt "$MOUNT_POINT_40" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t '$LV_NAME_40' is currently mounted on '$MOUNT_POINT_40'." | tee -a ${REPORT_FILE}
             T40_SCORE=$(( T40_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t '$LV_NAME_40' is not currently mounted on '$MOUNT_POINT_40'." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME_40' not found in VG '$VG_NAME_40'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Volume Group '$VG_NAME_40' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T40_SCORE ))
TOTAL=$(( TOTAL + T40_TOTAL ))
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
echo -e "${COLOR_INFO}Your total score for Batch 4 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"