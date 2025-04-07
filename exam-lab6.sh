#!/bin/bash
# Grader script - Batch 6 (Based on Questions 52-61)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch6.txt"
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
echo "Starting Grade Evaluation Batch 6 - $(date)" | tee -a ${REPORT_FILE}
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

### TASK 52: Extend LV /dev/test0/testvolume1 by 200M Online
echo -e "${COLOR_INFO}Evaluating Task 52: Extend LV /dev/test0/testvolume1 by 200M Online${COLOR_RESET}" | tee -a ${REPORT_FILE}
T52_SCORE=0
T52_TOTAL=25
LV_PATH_52="/dev/test0/testvolume1" # Assuming vg=test0, lv=testvolume1

# Check if LV exists
if [[ -b "$LV_PATH_52" ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_PATH_52' found." | tee -a ${REPORT_FILE}
    T52_SCORE=$(( T52_SCORE + 5 ))
    # Get current size (approximate initial check)
    LV_SIZE_MB_BEFORE=$(lvs --noheadings --units m -o lv_size $LV_PATH_52 | sed 's/[^0-9.]*//g' | cut -d. -f1)

    # Check if size is approx Initial (100MB) + Added (200MB) = 300MB
    if [[ $LV_SIZE_MB_BEFORE -ge 290 ]] && [[ $LV_SIZE_MB_BEFORE -le 310 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_PATH_52' size is ${LV_SIZE_MB_BEFORE}M (approx 300MiB)." | tee -a ${REPORT_FILE}
        T52_SCORE=$(( T52_SCORE + 10 ))

        # Check filesystem size (should be close to LV size)
        MOUNT_POINT_52=$(findmnt -no TARGET ${LV_PATH_52})
        if [[ -n "$MOUNT_POINT_52" ]]; then
            FS_SIZE_MB_52=$(df -BM --output=size ${MOUNT_POINT_52} 2>/dev/null | tail -n 1 | sed 's/[^0-9]*//g')
            if [[ -n "$FS_SIZE_MB_52" ]] && [[ $FS_SIZE_MB_52 -ge $((LV_SIZE_MB_BEFORE - 20)) ]] && [[ $FS_SIZE_MB_52 -le $LV_SIZE_MB_BEFORE ]]; then
                 echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem on '$LV_PATH_52' appears resized (FS Size: ${FS_SIZE_MB_52}M)." | tee -a ${REPORT_FILE}
                 T52_SCORE=$(( T52_SCORE + 10 ))
            else
                 echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem on '$LV_PATH_52' does not appear resized (FS Size: ${FS_SIZE_MB_52}M vs LV Size: ${LV_SIZE_MB_BEFORE}M)." | tee -a ${REPORT_FILE}
            fi
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine mount point for '$LV_PATH_52' to check filesystem size. Was it mounted?" | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_PATH_52' size is ${LV_SIZE_MB_BEFORE}M (NOT approx 300MiB)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_PATH_52' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T52_SCORE ))
TOTAL=$(( TOTAL + T52_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 53: Extend LV /dev/test0/lvtestvolume by 5G (via VG Extend)
echo -e "${COLOR_INFO}Evaluating Task 53: Extend LV /dev/test0/lvtestvolume by 5G (via VG Extend)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T53_SCORE=0
T53_TOTAL=30
LV_PATH_53="/dev/test0/lvtestvolume" # Assuming vg=test0, lv=lvtestvolume
VG_NAME_53="test0"
# Check if VG test0 exists
if ! vgs $VG_NAME_53 &> /dev/null; then
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Volume Group '$VG_NAME_53' does not exist." | tee -a ${REPORT_FILE}
     TOTAL=$(( TOTAL + T53_TOTAL )) # Add total even if skipping
     echo -e "\n" | tee -a ${REPORT_FILE}
     continue
fi
# Check if LV exists
if [[ -b "$LV_PATH_53" ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_PATH_53' found." | tee -a ${REPORT_FILE}
    T53_SCORE=$(( T53_SCORE + 5 ))
    # Get size AFTER extension (approx Initial(2G) + Added(5G) = 7G)
    LV_SIZE_GB_AFTER=$(lvs --noheadings --units g -o lv_size $LV_PATH_53 | sed 's/[^0-9.]*//g' | cut -d. -f1)
    if [[ $LV_SIZE_GB_AFTER -ge 6 ]] && [[ $LV_SIZE_GB_AFTER -le 8 ]]; then # Allow range around 7GB
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_PATH_53' size is ${LV_SIZE_GB_AFTER}G (approx 7GiB)." | tee -a ${REPORT_FILE}
        T53_SCORE=$(( T53_SCORE + 15 )) # Points for correct final size

        # Check filesystem size on /data
        MOUNT_POINT_53="/data"
        if findmnt "$MOUNT_POINT_53" | grep -q "$LV_PATH_53"; then
            FS_SIZE_GB_53=$(df -BG --output=size ${MOUNT_POINT_53} 2>/dev/null | tail -n 1 | sed 's/[^0-9]*//g')
            if [[ -n "$FS_SIZE_GB_53" ]] && [[ $FS_SIZE_GB_53 -ge $((LV_SIZE_GB_AFTER - 1)) ]] && [[ $FS_SIZE_GB_53 -le $LV_SIZE_GB_AFTER ]]; then
                 echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem on '$MOUNT_POINT_53' appears resized (FS Size: ${FS_SIZE_GB_53}G)." | tee -a ${REPORT_FILE}
                 T53_SCORE=$(( T53_SCORE + 10 ))
            else
                 echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem on '$MOUNT_POINT_53' does not appear resized (FS Size: ${FS_SIZE_GB_53}G vs LV Size: ${LV_SIZE_GB_AFTER}G)." | tee -a ${REPORT_FILE}
            fi
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical volume '$LV_PATH_53' is not mounted on '$MOUNT_POINT_53'." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_PATH_53' size is ${LV_SIZE_GB_AFTER}G (NOT approx 7GiB)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_PATH_53' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T53_SCORE ))
TOTAL=$(( TOTAL + T53_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 54: NIS Client and Autofs /rhome/stationx
echo -e "${COLOR_INFO}Evaluating Task 54: NIS Client and Autofs /rhome/stationx${COLOR_RESET}" | tee -a ${REPORT_FILE}
T54_SCORE=0
T54_TOTAL=40
# Check if NIS is configured (modern check using authselect)
AUTHSELECT_PROFILE=$(authselect current -r 2>/dev/null | grep 'Profile ID:' | awk '{print $3}')
if [[ "$AUTHSELECT_PROFILE" == *"nis"* ]]; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found 'nis' in current authselect profile ($AUTHSELECT_PROFILE)." | tee -a ${REPORT_FILE}
     T54_SCORE=$(( T54_SCORE + 10 ))
     # Check ypbind service status (NIS client daemon)
     if systemctl is-active ypbind --quiet; then
           echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t ypbind service is running." | tee -a ${REPORT_FILE}
           T54_SCORE=$(( T54_SCORE + 5 ))
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t ypbind service is not running." | tee -a ${REPORT_FILE}
     fi
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Current authselect profile ($AUTHSELECT_PROFILE) does not include 'nis'." | tee -a ${REPORT_FILE}
     echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}\t Note: NIS is deprecated; modern systems use SSSD/LDAP." | tee -a ${REPORT_FILE}
fi
# Check autofs service status
if systemctl is-enabled autofs --quiet && systemctl is-active autofs --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs service is running and enabled." | tee -a ${REPORT_FILE}
    T54_SCORE=$(( T54_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check master map configuration for /rhome/stationx (assuming station 1)
AUTOFS_BASE_54="/rhome/station1" # Assuming station 1
AUTOFS_MAP_54="/etc/auto.home" # Based on answer
NFS_SERVER_54="192.168.0.254" # Based on answer
if grep -Eq "^\s*${AUTOFS_BASE_54}\s+${AUTOFS_MAP_54}" /etc/auto.master || grep -Eq "^\s*${AUTOFS_BASE_54}\s+${AUTOFS_MAP_54}" /etc/auto.master.d/*.conf &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs master map entry found for '$AUTOFS_BASE_54' pointing to '$AUTOFS_MAP_54'." | tee -a ${REPORT_FILE}
    T54_SCORE=$(( T54_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs master map entry for '$AUTOFS_BASE_54' -> '$AUTOFS_MAP_54' not found." | tee -a ${REPORT_FILE}
fi
# Check map file content for wildcard entry
if [ -f "$AUTOFS_MAP_54" ] && grep -Eq "^\s*\*\s+-rw,soft,intr\s+${NFS_SERVER_54}:${AUTOFS_BASE_54}/&" "$AUTOFS_MAP_54"; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Wildcard entry '*' configured correctly in '$AUTOFS_MAP_54'." | tee -a ${REPORT_FILE}
     T54_SCORE=$(( T54_SCORE + 10 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Wildcard entry '*' for server '${NFS_SERVER_54}:${AUTOFS_BASE_54}/&' not found or options incorrect in '$AUTOFS_MAP_54'." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T54_SCORE ))
TOTAL=$(( TOTAL + T54_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 55: Directory Permissions /data (770)
echo -e "${COLOR_INFO}Evaluating Task 55: Directory Permissions /data (770)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T55_SCORE=0
T55_TOTAL=10
DIR_55="/data"
# Check directory exists
if [ -d "$DIR_55" ]; then
    PERMS_55=$(stat -c %a "$DIR_55")
    PERMS_STR_55=$(stat -c %A "$DIR_55")
    # Check for exact 770 permissions (or 2770 if SGID also set from Q56)
    if [[ "$PERMS_55" == "770" ]] || [[ "$PERMS_55" == "2770" ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Permissions for '$DIR_55' are correctly set to allow only owner/group full access ($PERMS_STR_55)." | tee -a ${REPORT_FILE}
        T55_SCORE=$(( T55_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Permissions for '$DIR_55' are $PERMS_STR_55 ($PERMS_55), expected 770 or 2770." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_55' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T55_SCORE ))
TOTAL=$(( TOTAL + T55_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 56: Directory SGID on /data
echo -e "${COLOR_INFO}Evaluating Task 56: Directory SGID on /data${COLOR_RESET}" | tee -a ${REPORT_FILE}
T56_SCORE=0
T56_TOTAL=10
DIR_56="/data"
# Check directory exists
if [ -d "$DIR_56" ]; then
    # Check if SGID bit is set ('s' or 'S' in group execute position)
    if stat -c %A "$DIR_56" | grep -q '^d.......s..'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t SGID bit is set on directory '$DIR_56'." | tee -a ${REPORT_FILE}
        T56_SCORE=$(( T56_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t SGID bit is NOT set on directory '$DIR_56' (Permissions: $(stat -c %A "$DIR_56"))." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Directory '$DIR_56' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T56_SCORE ))
TOTAL=$(( TOTAL + T56_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 57: Enable IP Forwarding (Rehash)
echo -e "${COLOR_INFO}Evaluating Task 57: Enable IP Forwarding (Rehash)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T57_SCORE=0
T57_TOTAL=15
# Check running kernel value
if [[ $(sysctl -n net.ipv4.ip_forward) == 1 ]]; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t net.ipv4.ip_forward is currently active (1)." | tee -a ${REPORT_FILE}
     T57_SCORE=$(( T57_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t net.ipv4.ip_forward is not currently active (running value != 1)." | tee -a ${REPORT_FILE}
fi
# Check persistent configuration
if grep -Eqs '^\s*net\.ipv4\.ip_forward\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent setting net.ipv4.ip_forward = 1 found in sysctl configuration files." | tee -a ${REPORT_FILE}
    T57_SCORE=$(( T57_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent setting net.ipv4.ip_forward = 1 NOT found in /etc/sysctl.conf or /etc/sysctl.d/." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T57_SCORE ))
TOTAL=$(( TOTAL + T57_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 58: User eric (no login)
echo -e "${COLOR_INFO}Evaluating Task 58: User eric (no login)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T58_SCORE=0
T58_TOTAL=15
if id eric &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'eric' exists." | tee -a ${REPORT_FILE}
    T58_SCORE=$(( T58_SCORE + 5 ))
    # Check shell
    if getent passwd eric | cut -d: -f7 | grep -q '/sbin/nologin'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t User 'eric' shell is /sbin/nologin." | tee -a ${REPORT_FILE}
        T58_SCORE=$(( T58_SCORE + 10 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'eric' shell is not /sbin/nologin (Found: $(getent passwd eric | cut -d: -f7))." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t User 'eric' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T58_SCORE ))
TOTAL=$(( TOTAL + T58_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 59: Autofs mount /mnt/data from server1.example.com:/data
echo -e "${COLOR_INFO}Evaluating Task 59: Autofs mount /mnt/data from server1.example.com:/data${COLOR_RESET}" | tee -a ${REPORT_FILE}
T59_SCORE=0
T59_TOTAL=30
AUTOFS_BASE_59="/mnt" # Based on answer
AUTOFS_MAP_59="/etc/auto.misc" # Based on answer
MOUNT_KEY_59="data" # Subdir under /mnt
NFS_TARGET_59="server1.example.com:/data"
OPTIONS_59="-rw,soft,intr" # Check options match

# Check autofs service status
if systemctl is-enabled autofs --quiet && systemctl is-active autofs --quiet; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs service is running and enabled." | tee -a ${REPORT_FILE}
    T59_SCORE=$(( T59_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs service is not running or not enabled." | tee -a ${REPORT_FILE}
fi
# Check master map configuration for /mnt -> /etc/auto.misc
if grep -Eq "^\s*${AUTOFS_BASE_59}\s+${AUTOFS_MAP_59}" /etc/auto.master || grep -Eq "^\s*${AUTOFS_BASE_59}\s+${AUTOFS_MAP_59}" /etc/auto.master.d/*.conf &>/dev/null; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t autofs master map entry found for '$AUTOFS_BASE_59' pointing to '$AUTOFS_MAP_59'." | tee -a ${REPORT_FILE}
    T59_SCORE=$(( T59_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t autofs master map entry for '$AUTOFS_BASE_59' -> '$AUTOFS_MAP_59' not found." | tee -a ${REPORT_FILE}
fi
# Check map file entry for 'data'
if [ -f "$AUTOFS_MAP_59" ]; then
    # Use more flexible grep to match key, options, target in any order within options
    if grep -Eq "^\s*${MOUNT_KEY_59}\s+.*\s+${NFS_TARGET_59}\b" "$AUTOFS_MAP_59" && \
       grep -E "^\s*${MOUNT_KEY_59}\s+-.*rw.*soft.*intr.*\s+${NFS_TARGET_59}\b" "$AUTOFS_MAP_59"; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Map entry '$MOUNT_KEY_59' found in '$AUTOFS_MAP_59' with target '$NFS_TARGET_59' and options rw,soft,intr." | tee -a ${REPORT_FILE}
         T59_SCORE=$(( T59_SCORE + 15 ))
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Map entry '$MOUNT_KEY_59' not found or options/target incorrect in '$AUTOFS_MAP_59'." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Map file '$AUTOFS_MAP_59' does not exist." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T59_SCORE ))
TOTAL=$(( TOTAL + T59_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 60: Extend LV /dev/vg0/lv1 to 500M Online
echo -e "${COLOR_INFO}Evaluating Task 60: Extend LV /dev/vg0/lv1 to 500M Online${COLOR_RESET}" | tee -a ${REPORT_FILE}
T60_SCORE=0
T60_TOTAL=25
LV_PATH_60="/dev/vg0/lv1" # Assuming vg=vg0, lv=lv1

# Check if LV exists
if [[ -b "$LV_PATH_60" ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_PATH_60' found." | tee -a ${REPORT_FILE}
    T60_SCORE=$(( T60_SCORE + 5 ))
    # Check LV size is approx 500MB (e.g., 490-510)
    LV_SIZE_MB_60=$(lvs --noheadings --units m -o lv_size $LV_PATH_60 | sed 's/[^0-9.]*//g' | cut -d. -f1)
    if [[ $LV_SIZE_MB_60 -ge 490 ]] && [[ $LV_SIZE_MB_60 -le 510 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_PATH_60' size is ${LV_SIZE_MB_60}M (approx 500MiB)." | tee -a ${REPORT_FILE}
        T60_SCORE=$(( T60_SCORE + 10 ))

        # Check filesystem size (should be close to LV size)
        MOUNT_POINT_60=$(findmnt -no TARGET ${LV_PATH_60})
        if [[ -n "$MOUNT_POINT_60" ]]; then
            FS_SIZE_MB_60=$(df -BM --output=size ${MOUNT_POINT_60} 2>/dev/null | tail -n 1 | sed 's/[^0-9]*//g')
            if [[ -n "$FS_SIZE_MB_60" ]] && [[ $FS_SIZE_MB_60 -ge $((LV_SIZE_MB_60 - 20)) ]] && [[ $FS_SIZE_MB_60 -le $LV_SIZE_MB_60 ]]; then
                 echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem on '$LV_PATH_60' appears resized (FS Size: ${FS_SIZE_MB_60}M)." | tee -a ${REPORT_FILE}
                 T60_SCORE=$(( T60_SCORE + 10 ))
            else
                 echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem on '$LV_PATH_60' does not appear resized (FS Size: ${FS_SIZE_MB_60}M vs LV Size: ${LV_SIZE_MB_60}M)." | tee -a ${REPORT_FILE}
            fi
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine mount point for '$LV_PATH_60' to check filesystem size. Was it mounted?" | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_PATH_60' size is ${LV_SIZE_MB_60}M (NOT approx 500MiB)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_PATH_60' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T60_SCORE ))
TOTAL=$(( TOTAL + T60_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 61: New 100M Partition, ext3, Mount /data
echo -e "${COLOR_INFO}Evaluating Task 61: New 100M Partition, ext3, Mount /data${COLOR_RESET}" | tee -a ${REPORT_FILE}
T61_SCORE=0
T61_TOTAL=30
MOUNT_POINT_61="/data" # Note conflict with Q55/56
echo -e "${COLOR_INFO}[WARN]${COLOR_RESET}\t Task 61 uses mount point '$MOUNT_POINT_61' which conflicts with Tasks 55/56. Grading assumes Task 61 was last." | tee -a ${REPORT_FILE}
PART_FOUND_61=false
PART_SIZE_OK_61=false
FS_OK_61=false
FSTAB_OK_61=false
MOUNT_OK_61=false

# Check If Currently Mounted on /data
if findmnt "$MOUNT_POINT_61" &>/dev/null; then
     SOURCE_DEV_61=$(findmnt -no SOURCE "$MOUNT_POINT_61")
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Device '$SOURCE_DEV_61' is currently mounted on '$MOUNT_POINT_61'." | tee -a ${REPORT_FILE}
     T61_SCORE=$(( T61_SCORE + 5 ))
     MOUNT_OK_61=true
     # Check if source is a partition (not LVM etc)
     if lsblk -no TYPE "$SOURCE_DEV_61" 2>/dev/null | grep -q 'part'; then
         PART_FOUND_61=true
          # Check size approx 100M (90-110 MiB)
         SIZE_MB_61=$(lsblk -bno SIZE "$SOURCE_DEV_61" 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
         if [[ "$SIZE_MB_61" -ge 90 ]] && [[ "$SIZE_MB_61" -le 110 ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Partition '$SOURCE_DEV_61' size is correct (~100M)." | tee -a ${REPORT_FILE}
              T61_SCORE=$(( T61_SCORE + 5 ))
              PART_SIZE_OK_61=true
         else
              echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Partition '$SOURCE_DEV_61' size ($SIZE_MB_61 MiB) is incorrect (expected ~100M)." | tee -a ${REPORT_FILE}
         fi
     else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Device mounted on '$MOUNT_POINT_61' is not a partition ($SOURCE_DEV_61)." | tee -a ${REPORT_FILE}
     fi
     # Check Filesystem Format (ext3 requested, allow ext4)
     if findmnt -no FSTYPE "$MOUNT_POINT_61" | grep -qE 'ext3|ext4'; then
         FS_TYPE_61=$(findmnt -no FSTYPE "$MOUNT_POINT_61")
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem mounted at '$MOUNT_POINT_61' is $FS_TYPE_61." | tee -a ${REPORT_FILE}
         T61_SCORE=$(( T61_SCORE + 5 ))
         FS_OK_61=true
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem mounted at '$MOUNT_POINT_61' is NOT ext3 or ext4." | tee -a ${REPORT_FILE}
     fi
     # Check Persistent Mount (fstab required by answer)
     if grep -Fw "$MOUNT_POINT_61" /etc/fstab | grep -Eq 'ext3|ext4' | grep -v "^#" &>/dev/null; then
          echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent mount entry found in /etc/fstab for '$MOUNT_POINT_61'." | tee -a ${REPORT_FILE}
          T61_SCORE=$(( T61_SCORE + 10 ))
          FSTAB_OK_61=true
     else
          echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent mount entry not found in /etc/fstab for '$MOUNT_POINT_61'." | tee -a ${REPORT_FILE}
     fi
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Nothing is currently mounted on '$MOUNT_POINT_61'." | tee -a ${REPORT_FILE}
fi

# Add points for intermediate steps if final mount failed but parts were ok
if ! $MOUNT_OK_61; then
    if $PART_FOUND_61 && $PART_SIZE_OK_61; then T61_SCORE=$(( T61_SCORE + 5)); fi
    if $FS_OK_61; then T61_SCORE=$(( T61_SCORE + 5)); fi
    if $FSTAB_OK_61; then T61_SCORE=$(( T61_SCORE + 5)); fi
fi


SCORE=$(( SCORE + T61_SCORE ))
TOTAL=$(( TOTAL + T61_TOTAL ))
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
echo -e "${COLOR_INFO}Your total score for Batch 6 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"