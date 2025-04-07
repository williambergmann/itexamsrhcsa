#!/bin/bash
# Grader script - Batch 10 (Based on Questions 102-111)
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

### TASK 102: Kernel Update and Default (Rehash 3)
echo -e "${COLOR_INFO}Evaluating Task 102: Kernel Update and Default (Rehash 3)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T102_SCORE=0
T102_TOTAL=15
KERNEL_COUNT_102=$(rpm -q kernel kernel-core | wc -l)
if [[ $KERNEL_COUNT_102 -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Multiple kernel packages found (Count: $KERNEL_COUNT_102)." | tee -a ${REPORT_FILE}
    T102_SCORE=$(( T102_SCORE + 5 ))
    DEFAULT_KERNEL_102=$(grubby --default-kernel 2>/dev/null)
    LATEST_KERNEL_102=$(ls -t /boot/vmlinuz-* | head -n 1)
    if [[ -n "$DEFAULT_KERNEL_102" ]]; then
         echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t Default kernel path is $DEFAULT_KERNEL_102" | tee -a ${REPORT_FILE}
         if [[ "$DEFAULT_KERNEL_102" == "$LATEST_KERNEL_102" ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default kernel appears to be the latest installed kernel." | tee -a ${REPORT_FILE}
              T102_SCORE=$(( T102_SCORE + 10 ))
         else
              echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default kernel ($DEFAULT_KERNEL_102) does not appear to match latest ($LATEST_KERNEL_102)." | tee -a ${REPORT_FILE}
         fi
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not determine default kernel using grubby." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Only one kernel package seems installed. Cannot verify update/default change." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T102_SCORE ))
TOTAL=$(( TOTAL + T102_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 103: LDAP Client Config (domain11)
echo -e "${COLOR_INFO}Evaluating Task 103: LDAP Client Config (domain11)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T103_SCORE=0
T103_TOTAL=25
LDAP_USER="ldapuser11"
LDAP_BASE_DN="dc=domain11,dc=example,dc=com"
LDAP_SERVER="ldap.example.com" # Derived from DN typically
# Check if user can be resolved via NSS
if getent passwd "$LDAP_USER" &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User '$LDAP_USER' found via getent (NSS likely configured)." | tee -a ${REPORT_FILE}
    T103_SCORE=$(( T103_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User '$LDAP_USER' not found via getent. Check LDAP client config (authselect/sssd/nsswitch/pam)." | tee -a ${REPORT_FILE}
fi
# Check if sssd is running and enabled
if systemctl is-enabled sssd --quiet && systemctl is-active sssd --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t sssd service is running and enabled." | tee -a ${REPORT_FILE}
    T103_SCORE=$(( T103_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t sssd service is not running or not enabled (check if used)." | tee -a ${REPORT_FILE}
fi
# Rough check for Base DN and Server in sssd config (adjust path if needed)
SSSD_CONF="/etc/sssd/sssd.conf"
FOUND_DN=false
FOUND_SERVER=false
if [ -f "$SSSD_CONF" ]; then
    if grep -iq "ldap_search_base\s*=\s*${LDAP_BASE_DN}" "$SSSD_CONF"; then
        FOUND_DN=true
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Base DN '$LDAP_BASE_DN' found in sssd.conf." | tee -a ${REPORT_FILE}
        T103_SCORE=$(( T103_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Base DN '$LDAP_BASE_DN' not found in $SSSD_CONF." | tee -a ${REPORT_FILE}
    fi
    # Check for server URI (allow ldap:// prefix)
    if grep -iq "ldap_uri\s*=\s*ldap://${LDAP_SERVER}" "$SSSD_CONF"; then
        FOUND_SERVER=true
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LDAP Server URI 'ldap://${LDAP_SERVER}' found in sssd.conf." | tee -a ${REPORT_FILE}
        T103_SCORE=$(( T103_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LDAP Server URI 'ldap://${LDAP_SERVER}' not found in $SSSD_CONF." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t sssd config file $SSSD_CONF not found. Cannot verify details." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T103_SCORE ))
TOTAL=$(( TOTAL + T103_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 104: NTP Client Configuration (server.domain11)
echo -e "${COLOR_INFO}Evaluating Task 104: NTP Client Configuration (server.domain11)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T104_SCORE=0
T104_TOTAL=15
NTP_SERVER_104="server.domain11.example.com"
# Check chronyd service status
if systemctl is-enabled chronyd --quiet && systemctl is-active chronyd --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t chronyd service is running and enabled." | tee -a ${REPORT_FILE}
    T104_SCORE=$(( T104_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t chronyd service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check configuration for the specified server
if grep -Eq "^\s*(server|pool)\s+${NTP_SERVER_104}" /etc/chrony.conf || chronyc sources 2>/dev/null | grep -q "$NTP_SERVER_104"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Time server '$NTP_SERVER_104' found in chrony configuration or sources." | tee -a ${REPORT_FILE}
    T104_SCORE=$(( T104_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Time server '$NTP_SERVER_104' not found in /etc/chrony.conf or active sources." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T104_SCORE ))
TOTAL=$(( TOTAL + T104_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 105: Autofs /rhome (host.domain11)
echo -e "${COLOR_INFO}Evaluating Task 105: Autofs /rhome (host.domain11)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T105_SCORE=0
T105_TOTAL=30 # Reduced points, similar task
AUTOFS_BASE_105="/rhome"
# Using auto.misc from answer, though auto.ldap or similar might be better named
AUTOFS_MAP_105="/etc/auto.misc"
NFS_SERVER_105="host.domain11.example.com"

# Check autofs service status
if systemctl is-enabled autofs --quiet && systemctl is-active autofs --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs service is running and enabled." | tee -a ${REPORT_FILE}
    T105_SCORE=$(( T105_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check master map configuration
if grep -Eq "^\s*${AUTOFS_BASE_105}\s+${AUTOFS_MAP_105}" /etc/auto.master || grep -Eq "^\s*${AUTOFS_BASE_105}\s+${AUTOFS_MAP_105}" /etc/auto.master.d/*.conf &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs master map entry found for '$AUTOFS_BASE_105' pointing to '$AUTOFS_MAP_105'." | tee -a ${REPORT_FILE}
    T105_SCORE=$(( T105_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs master map entry for '$AUTOFS_BASE_105' -> '$AUTOFS_MAP_105' not found." | tee -a ${REPORT_FILE}
fi
# Check map file entry for 'ldapuser11' or wildcard
if [ -f "$AUTOFS_MAP_105" ]; then
    # Check for specific user entry OR wildcard with correct server/path/options
    if grep -Eq "^\s*ldapuser11\s+-.*rw.*\s+${NFS_SERVER_105}:/rhome/ldapuser11\b" "$AUTOFS_MAP_105" || \
       grep -Eq "^\s*\*\s+-.*rw.*\s+${NFS_SERVER_105}:/rhome/&" "$AUTOFS_MAP_105" ; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Map entry found in '$AUTOFS_MAP_105' for '${NFS_SERVER_105}:/rhome/...' with rw option (checked specific user or wildcard)." | tee -a ${REPORT_FILE}
         T105_SCORE=$(( T105_SCORE + 15 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Map entry for ldapuser11 or wildcard pointing to '${NFS_SERVER_105}:/rhome/...' with rw option not found or incorrect in '$AUTOFS_MAP_105'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Map file '$AUTOFS_MAP_105' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T105_SCORE ))
TOTAL=$(( TOTAL + T105_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 106: User alex UID 3400
echo -e "${COLOR_INFO}Evaluating Task 106: User alex UID 3400${COLOR_RESET}" | tee -a ${REPORT_FILE}
T106_SCORE=0
T106_TOTAL=20
if id alex &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'alex' exists." | tee -a ${REPORT_FILE}
    T106_SCORE=$(( T106_SCORE + 5 ))
    # Check UID
    if [[ $(id -u alex) == 3400 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'alex' UID is 3400." | tee -a ${REPORT_FILE}
        T106_SCORE=$(( T106_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'alex' UID is not 3400 (Found: $(id -u alex))." | tee -a ${REPORT_FILE}
    fi
    # Check if password is set
    if grep '^alex:' /etc/shadow | cut -d: -f2 | grep -q '^\$.*'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'alex' password appears to be set." | tee -a ${REPORT_FILE}
        T106_SCORE=$(( T106_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'alex' password does not appear to be set in /etc/shadow." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'alex' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T106_SCORE ))
TOTAL=$(( TOTAL + T106_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 107: Add 754M Swap Partition
echo -e "${COLOR_INFO}Evaluating Task 107: Add 754M Swap Partition${COLOR_RESET}" | tee -a ${REPORT_FILE}
T107_SCORE=0
T107_TOTAL=20
SWAP_COUNT_107=$(swapon -s | sed '1d' | wc -l)
ORIG_SWAP_DEVICE_107=$(swapon -s | sed '1d' | awk '{print $1}' | head -n 1)
FOUND_NEW_SWAP_107=false
NEW_SWAP_SIZE_OK_107=false

if [[ $SWAP_COUNT_107 -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found more than one active swap space." | tee -a ${REPORT_FILE}
    T107_SCORE=$(( T107_SCORE + 5 ))
    while IFS= read -r line; do
        [[ "$line" =~ ^\# ]] && continue
        [[ "$line" =~ ^\s*$ ]] && continue
        FS_SPEC=$(echo "$line" | awk '{print $1}')
        FS_TYPE=$(echo "$line" | awk '{print $3}')
        if [[ "$FS_SPEC" != "$ORIG_SWAP_DEVICE_107" ]] && [[ "$FS_TYPE" == "swap" ]]; then
            FOUND_NEW_SWAP_107=true
            BLOCK_DEV=$(blkid -t UUID=$(echo $FS_SPEC | sed 's/UUID=//; s/"//g') -o device || echo $FS_SPEC)
            if [[ -b "$BLOCK_DEV" ]]; then
                SIZE_MB=$(lsblk -bno SIZE "$BLOCK_DEV" 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
                # Check size approx 754M (e.g., 730-770 MiB)
                if [[ "$SIZE_MB" -ge 730 ]] && [[ "$SIZE_MB" -le 770 ]]; then
                    NEW_SWAP_SIZE_OK_107=true
                fi
            fi
            break
        fi
    done < /etc/fstab

    if $FOUND_NEW_SWAP_107; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found a persistent swap entry in /etc/fstab (different from original)." | tee -a ${REPORT_FILE}
        T107_SCORE=$(( T107_SCORE + 10 ))
        if $NEW_SWAP_SIZE_OK_107; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t The new swap partition size seems correct (~754M)." | tee -a ${REPORT_FILE}
             T107_SCORE=$(( T107_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t The size of the new swap partition could not be verified or is incorrect (Expected ~754M)." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not find a persistent swap entry in /etc/fstab for the additional swap space." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find more than one active swap space (expected original + new ~754M)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T107_SCORE ))
TOTAL=$(( TOTAL + T107_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 108: Find and Copy ira's Files
echo -e "${COLOR_INFO}Evaluating Task 108: Find and Copy ira's Files${COLOR_RESET}" | tee -a ${REPORT_FILE}
T108_SCORE=0
T108_TOTAL=10
TARGET_DIR_108="/root/findresults"
# Ensure user ira exists for test, create dummy file
id ira &>/dev/null || useradd ira
touch /tmp/ira_test_file.tmp && chown ira:ira /tmp/ira_test_file.tmp

if [ -d "$TARGET_DIR_108" ]; then
    if [ -f "${TARGET_DIR_108}/ira_test_file.tmp" ]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target directory '$TARGET_DIR_108' exists and contains dummy ira file (copy likely worked)." | tee -a ${REPORT_FILE}
        T108_SCORE=$(( T108_SCORE + 10 ))
    elif [ -n "$(ls -A $TARGET_DIR_108)" ]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target directory '$TARGET_DIR_108' exists and contains files (basic check)." | tee -a ${REPORT_FILE}
         T108_SCORE=$(( T108_SCORE + 5 )) # Partial credit
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target directory '$TARGET_DIR_108' exists but is empty or missing dummy file." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target directory '$TARGET_DIR_108' does not exist." | tee -a ${REPORT_FILE}
fi
# Cleanup dummy file
rm -f /tmp/ira_test_file.tmp
SCORE=$(( SCORE + T108_SCORE ))
TOTAL=$(( TOTAL + T108_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 109: Grep 'seismic' to /root/wordlist
echo -e "${COLOR_INFO}Evaluating Task 109: Grep 'seismic' to /root/wordlist${COLOR_RESET}" | tee -a ${REPORT_FILE}
T109_SCORE=0
T109_TOTAL=10
SOURCE_FILE_109="/usr/share/dict/words"
TARGET_FILE_109="/root/wordlist"
SEARCH_TERM_109="seismic"
NON_TERM_109="globefish" # Assumed non-match word

if [ -f "$TARGET_FILE_109" ]; then
     # Check content: contains term, does not contain non-term, is not empty
     if grep -q "$SEARCH_TERM_109" "$TARGET_FILE_109" && ! grep -qw "$NON_TERM_109" "$TARGET_FILE_109" && [ -s "$TARGET_FILE_109" ] ; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Target file '$TARGET_FILE_109' exists and seems to contain correct lines." | tee -a ${REPORT_FILE}
        T109_SCORE=$(( T109_SCORE + 10 ))
     else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE_109' exists but content seems incorrect or empty." | tee -a ${REPORT_FILE}
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Target file '$TARGET_FILE_109' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T109_SCORE ))
TOTAL=$(( TOTAL + T109_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 110: Tar Backup /usr/local
echo -e "${COLOR_INFO}Evaluating Task 110: Tar Backup /usr/local${COLOR_RESET}" | tee -a ${REPORT_FILE}
T110_SCORE=0
T110_TOTAL=10
ARCHIVE_FILE_110="/root/backup.tar.bz2"
SOURCE_DIR_110="/usr/local"
# Ensure source exists for testing listing
mkdir -p ${SOURCE_DIR_110}/games ${SOURCE_DIR_110}/libexec
touch ${SOURCE_DIR_110}/games/dummy_game

if [ -f "$ARCHIVE_FILE_110" ]; then
     if tar tfj "$ARCHIVE_FILE_110" &>/dev/null && tar tfj "$ARCHIVE_FILE_110" | grep -q 'usr/local/games'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Archive '$ARCHIVE_FILE_110' exists, is valid bzip2 tar, and contains expected paths." | tee -a ${REPORT_FILE}
        T110_SCORE=$(( T110_SCORE + 10 ))
     else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Archive '$ARCHIVE_FILE_110' exists but is not valid bzip2 tar or content structure is wrong." | tee -a ${REPORT_FILE}
     fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Archive file '$ARCHIVE_FILE_110' does not exist." | tee -a ${REPORT_FILE}
fi
# Cleanup dummy dirs/files
rm -rf ${SOURCE_DIR_110}/games ${SOURCE_DIR_110}/libexec
SCORE=$(( SCORE + T110_SCORE ))
TOTAL=$(( TOTAL + T110_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 111: LVM 'database' in VG 'datastore' (PE 16M), ext3, Mount /mnt/database
echo -e "${COLOR_INFO}Evaluating Task 111: LVM 'database' in VG 'datastore' (PE 16M), ext3, Mount /mnt/database${COLOR_RESET}" | tee -a ${REPORT_FILE}
T111_SCORE=0
T111_TOTAL=50
VG_NAME_111="datastore"
LV_NAME_111="database"
MOUNT_POINT_111="/mnt/database"
echo -e "${COLOR_INFO}[WARN]${COLOR_RESET}\t Task 111 uses mount point '$MOUNT_POINT_111'. Grading assumes this task was performed last for this mount point." | tee -a ${REPORT_FILE}

# Check VG exists
if vgs $VG_NAME_111 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Volume Group '$VG_NAME_111' exists." | tee -a ${REPORT_FILE}
    T111_SCORE=$(( T111_SCORE + 5 ))
    # Check PE Size
    if vgdisplay $VG_NAME_111 | grep -q "PE Size .* 16\.00 MiB"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t VG '$VG_NAME_111' PE Size is 16 MiB." | tee -a ${REPORT_FILE}
        T111_SCORE=$(( T111_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t VG '$VG_NAME_111' PE Size is NOT 16 MiB." | tee -a ${REPORT_FILE}
    fi
    # Check LV exists
    LV_PATH_111="/dev/${VG_NAME_111}/${LV_NAME_111}"
    if lvs $LV_PATH_111 &>/dev/null; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_111' exists." | tee -a ${REPORT_FILE}
        T111_SCORE=$(( T111_SCORE + 5 ))
        # Check LV Extent Size
        if [[ $(lvdisplay $LV_PATH_111 | awk '/Current LE/ {print $3}') == 50 ]]; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_111' size is 50 extents." | tee -a ${REPORT_FILE}
            T111_SCORE=$(( T111_SCORE + 5 ))
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_111' size is not 50 extents." | tee -a ${REPORT_FILE}
        fi
        # Check Filesystem Format (ext3 requested, allow ext4)
        if blkid $LV_PATH_111 | grep -qE 'TYPE="ext3"|TYPE="ext4"'; then
            FS_TYPE_111=$(blkid -s TYPE -o value $LV_PATH_111)
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_111' is formatted with $FS_TYPE_111." | tee -a ${REPORT_FILE}
            T111_SCORE=$(( T111_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_111' is not formatted with ext3 (or ext4)." | tee -a ${REPORT_FILE}
        fi
        # Check Mount Point directory
        if [ -d "$MOUNT_POINT_111" ]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Mount point '$MOUNT_POINT_111' exists." | tee -a ${REPORT_FILE}
             T111_SCORE=$(( T111_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Mount point '$MOUNT_POINT_111' does not exist." | tee -a ${REPORT_FILE}
        fi
         # Check Persistent Mount (fstab required by answer)
        if grep -Fw "$MOUNT_POINT_111" /etc/fstab | grep -Eq 'ext3|ext4' | grep -v "^#" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_111'." | tee -a ${REPORT_FILE}
             T111_SCORE=$(( T111_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_111'." | tee -a ${REPORT_FILE}
        fi
         # Check If Currently Mounted
        if findmnt "$MOUNT_POINT_111" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t '$LV_NAME_111' is currently mounted on '$MOUNT_POINT_111'." | tee -a ${REPORT_FILE}
             T111_SCORE=$(( T111_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t '$LV_NAME_111' is not currently mounted on '$MOUNT_POINT_111'." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME_111' not found in VG '$VG_NAME_111'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Volume Group '$VG_NAME_111' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T111_SCORE ))
TOTAL=$(( TOTAL + T111_TOTAL ))
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