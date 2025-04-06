#!/bin/bash
# Grader script - Batch 2 (Questions 11-20)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch2.txt"
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
echo "Starting Grade Evaluation Batch 2 - $(date)" | tee -a ${REPORT_FILE}
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

### TASK 11: LDAP Authentication Client Config
echo -e "${COLOR_INFO}Evaluating Task 11: LDAP Authentication Client Config${COLOR_RESET}" | tee -a ${REPORT_FILE}
T11_SCORE=0
T11_TOTAL=10
# Check if user ldapuser40 can be resolved via NSS (implies LDAP is configured in nsswitch)
if getent passwd ldapuser40 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'ldapuser40' found via getent (NSS configured)." | tee -a ${REPORT_FILE}
    T11_SCORE=$(( T11_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'ldapuser40' not found via getent. Check LDAP client config (authselect/sssd/nsswitch/pam)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T11_SCORE ))
TOTAL=$(( TOTAL + T11_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 12: Autofs for NFS Home Directories
echo -e "${COLOR_INFO}Evaluating Task 12: Autofs for NFS Home Directories${COLOR_RESET}" | tee -a ${REPORT_FILE}
T12_SCORE=0
T12_TOTAL=40
# Check autofs package installed
if rpm -q autofs &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs package is installed." | tee -a ${REPORT_FILE}
    T12_SCORE=$(( T12_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs package not found." | tee -a ${REPORT_FILE}
    # Skip further checks if package missing
    SCORE=$(( SCORE + T12_SCORE ))
    TOTAL=$(( TOTAL + T12_TOTAL ))
    echo -e "\n" | tee -a ${REPORT_FILE}
    continue # Skip to next task in script
fi
# Check autofs service status
if systemctl is-enabled autofs --quiet && systemctl is-active autofs --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs service is running and enabled." | tee -a ${REPORT_FILE}
    T12_SCORE=$(( T12_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check master map configuration for /rhome
if grep -Eq '^\s*/rhome\s+/etc/auto.ldap' /etc/auto.master || grep -Eq '^\s*/rhome\s+/etc/auto.ldap' /etc/auto.master.d/*.conf &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs master map entry found for /rhome pointing to /etc/auto.ldap." | tee -a ${REPORT_FILE}
    T12_SCORE=$(( T12_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs master map entry for /rhome -> /etc/auto.ldap not found." | tee -a ${REPORT_FILE}
fi
# Check map file existence
if [ -f /etc/auto.ldap ]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Map file /etc/auto.ldap exists." | tee -a ${REPORT_FILE}
    T12_SCORE=$(( T12_SCORE + 5 ))
    # Check map file content for wildcard entry (more robust than checking specific user)
    # Regex allows for options variations
    if grep -Eq '^\s*\*\s+-.*(rw|soft|intr).*\s+172\.24\.40\.10:/rhome/&' /etc/auto.ldap; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Wildcard entry '*' configured correctly in /etc/auto.ldap for 172.24.40.10." | tee -a ${REPORT_FILE}
         T12_SCORE=$(( T12_SCORE + 15 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Wildcard entry '*' for server 172.24.40.10:/rhome/& not found or options incorrect in /etc/auto.ldap." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Map file /etc/auto.ldap does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T12_SCORE ))
TOTAL=$(( TOTAL + T12_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 13: Time Synchronization
echo -e "${COLOR_INFO}Evaluating Task 13: Time Synchronization (NTP Client)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T13_SCORE=0
T13_TOTAL=15
# Check chronyd service status
if systemctl is-enabled chronyd --quiet && systemctl is-active chronyd --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t chronyd service is running and enabled." | tee -a ${REPORT_FILE}
    T13_SCORE=$(( T13_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t chronyd service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check configuration for the specified server
if grep -Eq '^\s*(server|pool)\s+172\.24\.40\.10' /etc/chrony.conf || chronyc sources 2>/dev/null | grep -q '172\.24\.40\.10'; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Time server 172.24.40.10 found in chrony configuration or sources." | tee -a ${REPORT_FILE}
    T13_SCORE=$(( T13_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Time server 172.24.40.10 not found in /etc/chrony.conf or active sources." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T13_SCORE ))
TOTAL=$(( TOTAL + T13_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 14: LVM Resize 'vo'
echo -e "${COLOR_INFO}Evaluating Task 14: LVM Resize 'vo' to ~300MiB${COLOR_RESET}" | tee -a ${REPORT_FILE}
T14_SCORE=0
T14_TOTAL=30
LV_NAME="vo" # Assuming the name from the question
# Check if LV exists (need to find its path)
LV_PATH=$(lvs --noheadings -o lv_path,lv_name | awk -v name="$LV_NAME" '$2 == name {print $1; exit}')
if [[ -n "$LV_PATH" ]] && [[ -b "$LV_PATH" ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME' found at $LV_PATH." | tee -a ${REPORT_FILE}
    T14_SCORE=$(( T14_SCORE + 10 ))
    # Check LV size (between 280M and 320M)
    LV_SIZE_MB=$(lvs --noheadings --units m -o lv_size $LV_PATH | sed 's/[^0-9.]*//g' | cut -d. -f1)
    if [[ $LV_SIZE_MB -ge 280 ]] && [[ $LV_SIZE_MB -le 320 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME' size is ${LV_SIZE_MB}M (within 280-320 MiB range)." | tee -a ${REPORT_FILE}
        T14_SCORE=$(( T14_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME' size is ${LV_SIZE_MB}M (NOT within 280-320 MiB range)." | tee -a ${REPORT_FILE}
    fi
    # Check if filesystem was resized (approximate check: FS size vs LV size)
    MOUNT_POINT=$(findmnt -no TARGET ${LV_PATH})
    if [[ -n "$MOUNT_POINT" ]]; then
        FS_SIZE_MB=$(df -BM --output=size ${MOUNT_POINT} | tail -n 1 | sed 's/[^0-9]*//g')
        # Allow some tolerance for filesystem overhead
        if [[ $FS_SIZE_MB -ge $((LV_SIZE_MB - 20)) ]] && [[ $FS_SIZE_MB -le $LV_SIZE_MB ]]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem on '$LV_NAME' appears resized (FS Size: ${FS_SIZE_MB}M)." | tee -a ${REPORT_FILE}
             T14_SCORE=$(( T14_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem on '$LV_NAME' does not appear resized (FS Size: ${FS_SIZE_MB}M vs LV Size: ${LV_SIZE_MB}M)." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine mount point for '$LV_NAME' to check filesystem size." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T14_SCORE ))
TOTAL=$(( TOTAL + T14_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 15: New VG 'vg1' (PE 16M), LV 'lvm02' (50 LE), ext4, Mount /mnt/data
echo -e "${COLOR_INFO}Evaluating Task 15: New VG 'vg1' (PE 16M), LV 'lvm02' (50 LE), ext4, Mount /mnt/data${COLOR_RESET}" | tee -a ${REPORT_FILE}
T15_SCORE=0
T15_TOTAL=50
VG_NAME_15="vg1"
LV_NAME_15="lvm02"
MOUNT_POINT_15="/mnt/data"
# Check VG exists
if vgs $VG_NAME_15 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Volume Group '$VG_NAME_15' exists." | tee -a ${REPORT_FILE}
    T15_SCORE=$(( T15_SCORE + 5 ))
    # Check PE Size
    if vgdisplay $VG_NAME_15 | grep -q "PE Size .* 16\.00 MiB"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t VG '$VG_NAME_15' PE Size is 16 MiB." | tee -a ${REPORT_FILE}
        T15_SCORE=$(( T15_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t VG '$VG_NAME_15' PE Size is NOT 16 MiB." | tee -a ${REPORT_FILE}
    fi
    # Check LV exists
    LV_PATH_15="/dev/${VG_NAME_15}/${LV_NAME_15}"
    if lvs $LV_PATH_15 &>/dev/null; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_15' exists." | tee -a ${REPORT_FILE}
        T15_SCORE=$(( T15_SCORE + 5 ))
        # Check LV Extent Size
        if [[ $(lvdisplay $LV_PATH_15 | awk '/Current LE/ {print $3}') == 50 ]]; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_15' size is 50 extents." | tee -a ${REPORT_FILE}
            T15_SCORE=$(( T15_SCORE + 5 ))
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_15' size is not 50 extents." | tee -a ${REPORT_FILE}
        fi
        # Check Filesystem Format
        if blkid $LV_PATH_15 | grep -q 'TYPE="ext4"'; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_15' is formatted with ext4." | tee -a ${REPORT_FILE}
            T15_SCORE=$(( T15_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_15' is not formatted with ext4." | tee -a ${REPORT_FILE}
        fi
        # Check Mount Point directory
        if [ -d "$MOUNT_POINT_15" ]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Mount point '$MOUNT_POINT_15' exists." | tee -a ${REPORT_FILE}
             T15_SCORE=$(( T15_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Mount point '$MOUNT_POINT_15' does not exist." | tee -a ${REPORT_FILE}
        fi
         # Check Persistent Mount (fstab required by answer)
        if grep -Fw "$MOUNT_POINT_15" /etc/fstab | grep -w ext4 | grep -v "^#" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_15'." | tee -a ${REPORT_FILE}
             T15_SCORE=$(( T15_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_15'." | tee -a ${REPORT_FILE}
        fi
         # Check If Currently Mounted
        if findmnt "$MOUNT_POINT_15" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t '$LV_NAME_15' is currently mounted on '$MOUNT_POINT_15'." | tee -a ${REPORT_FILE}
             T15_SCORE=$(( T15_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t '$LV_NAME_15' is not currently mounted on '$MOUNT_POINT_15'." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME_15' not found in VG '$VG_NAME_15'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Volume Group '$VG_NAME_15' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T15_SCORE ))
TOTAL=$(( TOTAL + T15_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 16: Kernel Upgrade and Default Boot
echo -e "${COLOR_INFO}Evaluating Task 16: Kernel Upgrade and Default Boot${COLOR_RESET}" | tee -a ${REPORT_FILE}
T16_SCORE=0
T16_TOTAL=10 # Reduced points due to ambiguity/outdated version
# Check if multiple kernel packages are installed
KERNEL_COUNT=$(rpm -q kernel kernel-core | wc -l) # Check both kernel and kernel-core
if [[ $KERNEL_COUNT -gt 1 ]]; then # Check for at least 2 kernel-related packages
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Multiple kernel packages found (Count: $KERNEL_COUNT)." | tee -a ${REPORT_FILE}
    T16_SCORE=$(( T16_SCORE + 5 ))
    # Check default boot index (assuming newest kernel is index 0)
    if [[ $(grubby --default-index 2>/dev/null) == 0 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default boot kernel index is 0 (assuming newest)." | tee -a ${REPORT_FILE}
        T16_SCORE=$(( T16_SCORE + 5 ))
    # Check GRUB_DEFAULT=0 (less reliable if saved is used)
    elif grep -Eq '^\s*GRUB_DEFAULT\s*=\s*0' /etc/default/grub; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t GRUB_DEFAULT=0 found in /etc/default/grub." | tee -a ${REPORT_FILE}
         T16_SCORE=$(( T16_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default boot kernel index is not 0 or GRUB_DEFAULT is not 0. Check grubby --default-kernel." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Only one kernel package seems installed. Cannot verify default change." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T16_SCORE ))
TOTAL=$(( TOTAL + T16_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 17: New 512M Partition, ext4, Mount /mnt/data2
echo -e "${COLOR_INFO}Evaluating Task 17: New 512M Partition, ext4, Mount /mnt/data2${COLOR_RESET}" | tee -a ${REPORT_FILE}
T17_SCORE=0
T17_TOTAL=30
MOUNT_POINT_17="/mnt/data2" # Using different mount point to avoid conflict
# Check Mount Point directory
if [ -d "$MOUNT_POINT_17" ]; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Mount point '$MOUNT_POINT_17' exists." | tee -a ${REPORT_FILE}
     T17_SCORE=$(( T17_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Mount point '$MOUNT_POINT_17' does not exist." | tee -a ${REPORT_FILE}
fi
# Check If Currently Mounted
if findmnt "$MOUNT_POINT_17" &>/dev/null; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t A device is currently mounted on '$MOUNT_POINT_17'." | tee -a ${REPORT_FILE}
     T17_SCORE=$(( T17_SCORE + 10 ))
     # Check Filesystem Format
     if findmnt -no FSTYPE "$MOUNT_POINT_17" | grep -q 'ext4'; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem mounted at '$MOUNT_POINT_17' is ext4." | tee -a ${REPORT_FILE}
         T17_SCORE=$(( T17_SCORE + 5 ))
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem mounted at '$MOUNT_POINT_17' is NOT ext4." | tee -a ${REPORT_FILE}
     fi
     # Check Persistent Mount (fstab required by answer)
     if grep -Fw "$MOUNT_POINT_17" /etc/fstab | grep -w ext4 | grep -v "^#" &>/dev/null; then
          echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_17'." | tee -a ${REPORT_FILE}
          T17_SCORE=$(( T17_SCORE + 10 ))
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_17'." | tee -a ${REPORT_FILE}
     fi
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Nothing is currently mounted on '$MOUNT_POINT_17'." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T17_SCORE ))
TOTAL=$(( TOTAL + T17_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 18: New VG 'vg1' (PE 8M), LV 'lvshare' (50 LE), ext4, Mount /mnt/data
echo -e "${COLOR_INFO}Evaluating Task 18: New VG 'vg1' (PE 8M), LV 'lvshare' (50 LE), ext4, Mount /mnt/data${COLOR_RESET}" | tee -a ${REPORT_FILE}
T18_SCORE=0
T18_TOTAL=50
VG_NAME_18="vg1" # Note: Same name as Q15 - might cause conflict if run together
LV_NAME_18="lvshare"
MOUNT_POINT_18="/mnt/data" # Note: Same name as Q15/Q17
echo -e "${COLOR_INFO}[WARN]${COLOR_RESET}\t Tasks 15, 17, 18 use overlapping names/mounts. Grading assumes Task 18 was the last one performed." | tee -a ${REPORT_FILE}

# Check VG exists
if vgs $VG_NAME_18 &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Volume Group '$VG_NAME_18' exists." | tee -a ${REPORT_FILE}
    T18_SCORE=$(( T18_SCORE + 5 ))
    # Check PE Size
    if vgdisplay $VG_NAME_18 | grep -q "PE Size .* 8\.00 MiB"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t VG '$VG_NAME_18' PE Size is 8 MiB." | tee -a ${REPORT_FILE}
        T18_SCORE=$(( T18_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t VG '$VG_NAME_18' PE Size is NOT 8 MiB." | tee -a ${REPORT_FILE}
    fi
    # Check LV exists
    LV_PATH_18="/dev/${VG_NAME_18}/${LV_NAME_18}"
    if lvs $LV_PATH_18 &>/dev/null; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_18' exists." | tee -a ${REPORT_FILE}
        T18_SCORE=$(( T18_SCORE + 5 ))
        # Check LV Extent Size
        if [[ $(lvdisplay $LV_PATH_18 | awk '/Current LE/ {print $3}') == 50 ]]; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_18' size is 50 extents." | tee -a ${REPORT_FILE}
            T18_SCORE=$(( T18_SCORE + 5 ))
            # Check Actual Size (50 * 8M = 400M)
             LV_SIZE_MB_18=$(lvs --noheadings --units m -o lv_size $LV_PATH_18 | sed 's/[^0-9.]*//g' | cut -d. -f1)
             if [[ $LV_SIZE_MB_18 -ge 380 ]] && [[ $LV_SIZE_MB_18 -le 400 ]]; then
                 echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_18' actual size is ${LV_SIZE_MB_18}M (correct for 50x8M PE)." | tee -a ${REPORT_FILE}
                 T18_SCORE=$(( T18_SCORE + 5 ))
             else
                 echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_18' actual size is ${LV_SIZE_MB_18}M (incorrect for 50x8M PE)." | tee -a ${REPORT_FILE}
             fi
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_18' size is not 50 extents." | tee -a ${REPORT_FILE}
        fi
        # Check Filesystem Format
        if blkid $LV_PATH_18 | grep -q 'TYPE="ext4"'; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_18' is formatted with ext4." | tee -a ${REPORT_FILE}
            T18_SCORE=$(( T18_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_18' is not formatted with ext4." | tee -a ${REPORT_FILE}
        fi
        # Check Mount Point directory
        if [ -d "$MOUNT_POINT_18" ]; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Mount point '$MOUNT_POINT_18' exists." | tee -a ${REPORT_FILE}
             T18_SCORE=$(( T18_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Mount point '$MOUNT_POINT_18' does not exist." | tee -a ${REPORT_FILE}
        fi
         # Check Persistent Mount (fstab required by answer)
        if grep -Fw "$MOUNT_POINT_18" /etc/fstab | grep -w ext4 | grep -v "^#" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_18'." | tee -a ${REPORT_FILE}
             T18_SCORE=$(( T18_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_18'." | tee -a ${REPORT_FILE}
        fi
         # Check If Currently Mounted
        if findmnt "$MOUNT_POINT_18" &>/dev/null; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t A device is currently mounted on '$MOUNT_POINT_18'." | tee -a ${REPORT_FILE}
             T18_SCORE=$(( T18_SCORE + 10 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Nothing is currently mounted on '$MOUNT_POINT_18'." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_NAME_18' not found in VG '$VG_NAME_18'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Volume Group '$VG_NAME_18' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T18_SCORE ))
TOTAL=$(( TOTAL + T18_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 19: Download and Mount ISO
echo -e "${COLOR_INFO}Evaluating Task 19: Download and Mount ISO${COLOR_RESET}" | tee -a ${REPORT_FILE}
T19_SCORE=0
T19_TOTAL=30
ISO_FILE="/root/boot.iso"
MOUNT_POINT_19="/media/cdrom"
# Check if ISO file exists
if [ -f "$ISO_FILE" ]; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ISO file '$ISO_FILE' exists." | tee -a ${REPORT_FILE}
     T19_SCORE=$(( T19_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ISO file '$ISO_FILE' does not exist." | tee -a ${REPORT_FILE}
fi
# Check if mount point exists
if [ -d "$MOUNT_POINT_19" ]; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Mount point '$MOUNT_POINT_19' exists." | tee -a ${REPORT_FILE}
     T19_SCORE=$(( T19_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Mount point '$MOUNT_POINT_19' does not exist." | tee -a ${REPORT_FILE}
fi
# Check fstab for loop mount entry
if grep -Fw "$MOUNT_POINT_19" /etc/fstab | grep -w iso9660 | grep -w loop | grep -v "^#" &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent loop mount entry found in /etc/fstab for '$MOUNT_POINT_19'." | tee -a ${REPORT_FILE}
    T19_SCORE=$(( T19_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent loop mount entry not found in /etc/fstab for '$MOUNT_POINT_19'." | tee -a ${REPORT_FILE}
fi
# Check if currently mounted
if findmnt "$MOUNT_POINT_19" | grep -q iso9660; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ISO '$ISO_FILE' is currently mounted on '$MOUNT_POINT_19'." | tee -a ${REPORT_FILE}
    T19_SCORE=$(( T19_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ISO '$ISO_FILE' is not currently mounted on '$MOUNT_POINT_19'." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T19_SCORE ))
TOTAL=$(( TOTAL + T19_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 20: Group 'admin' with GID 600
echo -e "${COLOR_INFO}Evaluating Task 20: Group 'admin' with GID 600${COLOR_RESET}" | tee -a ${REPORT_FILE}
T20_SCORE=0
T20_TOTAL=10
# Check if group admin exists
if getent group admin &>/dev/null; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Group 'admin' exists." | tee -a ${REPORT_FILE}
     T20_SCORE=$(( T20_SCORE + 5 ))
     # Check GID
     if [[ $(getent group admin | cut -d: -f3) == 600 ]]; then
          echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Group 'admin' has GID 600." | tee -a ${REPORT_FILE}
          T20_SCORE=$(( T20_SCORE + 5 ))
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Group 'admin' does not have GID 600 (Found: $(getent group admin | cut -d: -f3))." | tee -a ${REPORT_FILE}
     fi
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Group 'admin' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T20_SCORE ))
TOTAL=$(( TOTAL + T20_TOTAL ))
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
echo -e "${COLOR_INFO}Your total score for Batch 2 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"