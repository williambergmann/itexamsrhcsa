#!/bin/bash
# Grader script - Batch 5 (Based on Questions 42-51)
# Version: 2024-03-10

# --- Configuration ---
REPORT_FILE="/tmp/exam-report-batch5.txt"
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
echo "Starting Grade Evaluation Batch 5 - $(date)" | tee -a ${REPORT_FILE}
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

### TASK 42: Add 2G Swap Partition
echo -e "${COLOR_INFO}Evaluating Task 42: Add 2G Swap Partition${COLOR_RESET}" | tee -a ${REPORT_FILE}
T42_SCORE=0
T42_TOTAL=20
SWAP_COUNT_42=$(swapon -s | sed '1d' | wc -l)
ORIG_SWAP_DEVICE_42=$(swapon -s | sed '1d' | awk '{print $1}' | head -n 1)
FOUND_NEW_SWAP=false
NEW_SWAP_SIZE_OK=false

# Check if more than one swap space is active
if [[ $SWAP_COUNT_42 -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found more than one active swap space." | tee -a ${REPORT_FILE}
    T42_SCORE=$(( T42_SCORE + 5 ))
    # Check /etc/fstab for a persistent swap entry (different from original)
    while IFS= read -r line; do
        [[ "$line" =~ ^\# ]] && continue # Skip comments
        [[ "$line" =~ ^\s*$ ]] && continue # Skip empty lines
        FS_SPEC=$(echo "$line" | awk '{print $1}')
        FS_TYPE=$(echo "$line" | awk '{print $3}')
        # Skip original swap and check if it's swap type
        if [[ "$FS_SPEC" != "$ORIG_SWAP_DEVICE_42" ]] && [[ "$FS_TYPE" == "swap" ]]; then
            FOUND_NEW_SWAP=true
            # Check size of the underlying block device (approx 2G = 1900-2100 MiB)
            BLOCK_DEV=$(blkid -t UUID=$(echo $FS_SPEC | sed 's/UUID=//; s/"//g') -o device || echo $FS_SPEC)
            if [[ -b "$BLOCK_DEV" ]]; then
                SIZE_MB=$(lsblk -bno SIZE "$BLOCK_DEV" 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
                if [[ "$SIZE_MB" -ge 1900 ]] && [[ "$SIZE_MB" -le 2100 ]]; then
                    NEW_SWAP_SIZE_OK=true
                fi
            fi
            break # Found a likely candidate
        fi
    done < /etc/fstab

    if $FOUND_NEW_SWAP; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found a persistent swap entry in /etc/fstab (different from original)." | tee -a ${REPORT_FILE}
        T42_SCORE=$(( T42_SCORE + 10 ))
        if $NEW_SWAP_SIZE_OK; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t The new swap partition size seems correct (~2G)." | tee -a ${REPORT_FILE}
             T42_SCORE=$(( T42_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t The size of the new swap partition could not be verified or is incorrect." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not find a persistent swap entry in /etc/fstab for the additional swap space." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find more than one active swap space (expected original + new 2G)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T42_SCORE ))
TOTAL=$(( TOTAL + T42_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 43: Enable IP Forwarding
echo -e "${COLOR_INFO}Evaluating Task 43: Enable IP Forwarding${COLOR_RESET}" | tee -a ${REPORT_FILE}
T43_SCORE=0
T43_TOTAL=15
# Check running kernel value
if [[ $(sysctl -n net.ipv4.ip_forward) == 1 ]]; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t net.ipv4.ip_forward is currently active (1)." | tee -a ${REPORT_FILE}
     T43_SCORE=$(( T43_SCORE + 5 ))
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t net.ipv4.ip_forward is not currently active (running value != 1)." | tee -a ${REPORT_FILE}
fi
# Check persistent configuration (any file in /etc/sysctl.d/ or /etc/sysctl.conf)
if grep -Eqs '^\s*net\.ipv4\.ip_forward\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Persistent setting net.ipv4.ip_forward = 1 found in sysctl configuration files." | tee -a ${REPORT_FILE}
    T43_SCORE=$(( T43_SCORE + 10 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Persistent setting net.ipv4.ip_forward = 1 NOT found in /etc/sysctl.conf or /etc/sysctl.d/." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T43_SCORE ))
TOTAL=$(( TOTAL + T43_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 44: Add Kernel Parameter 'kmcrl=5'
echo -e "${COLOR_INFO}Evaluating Task 44: Add Kernel Parameter 'kmcrl=5'${COLOR_RESET}" | tee -a ${REPORT_FILE}
T44_SCORE=0
T44_TOTAL=10
# Check current running kernel command line
if grep -q '\bkmcrl=5\b' /proc/cmdline; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Parameter 'kmcrl=5' found in currently running kernel cmdline." | tee -a ${REPORT_FILE}
     # Partial credit even if not persistent, as reboot is needed
     T44_SCORE=$(( T44_SCORE + 5 ))
fi
# Check persistent config using grubby
DEFAULT_KERNEL_PATH=$(grubby --default-kernel 2>/dev/null)
if [[ -n "$DEFAULT_KERNEL_PATH" ]] && grubby --info="$DEFAULT_KERNEL_PATH" 2>/dev/null | grep -q '\bkmcrl=5\b'; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Parameter 'kmcrl=5' found persistently configured for default kernel via grubby." | tee -a ${REPORT_FILE}
    T44_SCORE=10 # Full credit if persistent
elif grep 'GRUB_CMDLINE_LINUX.*kmcrl=5' /etc/default/grub &>/dev/null; then
    echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t Parameter 'kmcrl=5' found in GRUB_CMDLINE_LINUX. Ensure grub2-mkconfig was run." | tee -a ${REPORT_FILE}
    # Assume mkconfig was run if setting is there
    T44_SCORE=10 # Full credit
elif [[ $T44_SCORE -eq 0 ]]; then # Only show fail if not found running or persistently
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Parameter 'kmcrl=5' not found in running cmdline or persistent default kernel config." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T44_SCORE ))
TOTAL=$(( TOTAL + T44_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 45: Kernel Upgrade and Default (Rehash)
echo -e "${COLOR_INFO}Evaluating Task 45: Kernel Upgrade and Default (Rehash)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T45_SCORE=0
T45_TOTAL=15 # Same scoring as T31
KERNEL_COUNT_45=$(rpm -q kernel kernel-core | wc -l)
if [[ $KERNEL_COUNT_45 -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Multiple kernel packages found (Count: $KERNEL_COUNT_45)." | tee -a ${REPORT_FILE}
    T45_SCORE=$(( T45_SCORE + 5 ))
    DEFAULT_KERNEL_45=$(grubby --default-kernel 2>/dev/null)
    RUNNING_KERNEL_45="/boot/vmlinuz-$(uname -r)"
    LATEST_KERNEL_45=$(ls -t /boot/vmlinuz-* | head -n 1)

    if [[ -n "$DEFAULT_KERNEL_45" ]]; then
         echo -e "${COLOR_OK}[INFO]${COLOR_RESET}\t Default kernel path is $DEFAULT_KERNEL_45" | tee -a ${REPORT_FILE}
         if [[ "$DEFAULT_KERNEL_45" == "$LATEST_KERNEL_45" ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default kernel appears to be the latest installed kernel." | tee -a ${REPORT_FILE}
              T45_SCORE=$(( T45_SCORE + 10 ))
         elif [[ "$DEFAULT_KERNEL_45" != "$RUNNING_KERNEL_45" ]]; then
              echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default kernel is different from currently running kernel (suggests change)." | tee -a ${REPORT_FILE}
              T45_SCORE=$(( T45_SCORE + 5 )) # Partial credit
         else
              echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default kernel ($DEFAULT_KERNEL_45) appears unchanged or doesn't match latest ($LATEST_KERNEL_45)." | tee -a ${REPORT_FILE}
         fi
    else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not determine default kernel using grubby." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Only one kernel package seems installed. Cannot verify update/default change." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T45_SCORE ))
TOTAL=$(( TOTAL + T45_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 46: Firewall REJECT Rule
echo -e "${COLOR_INFO}Evaluating Task 46: Firewall REJECT Rule (172.25.0.0/16)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T46_SCORE=0
T46_TOTAL=15
REJECT_RULE_FOUND=false
# Check permanent rich rules for the reject
if firewall-cmd --list-rich-rules --permanent 2>/dev/null | grep -q 'rule family="ipv4" source address="172.25.0.0/16".*reject'; then
     REJECT_RULE_FOUND=true
fi

if $REJECT_RULE_FOUND; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found permanent firewalld rich rule to reject source 172.25.0.0/16." | tee -a ${REPORT_FILE}
    T46_SCORE=$(( T46_SCORE + 10 ))
    # Check if rule is active in runtime (implies reload happened)
    if firewall-cmd --list-rich-rules 2>/dev/null | grep -q 'rule family="ipv4" source address="172.25.0.0/16".*reject'; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Reject rule is active in runtime configuration." | tee -a ${REPORT_FILE}
        T46_SCORE=$(( T46_SCORE + 5 ))
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Reject rule found in permanent config, but not active (was 'firewall-cmd --reload' run?)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Permanent firewalld rich rule to reject source 172.25.0.0/16 not found." | tee -a ${REPORT_FILE}
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}\t Note: Using legacy iptables is not the standard RHEL 8/9 method." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T46_SCORE ))
TOTAL=$(( TOTAL + T46_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 47: YUM/DNF Repo (RHEL6 URL)
echo -e "${COLOR_INFO}Evaluating Task 47: YUM/DNF Repo (RHEL6 URL)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T47_SCORE=0
T47_TOTAL=20
REPO_URL_47="http://instructor.example.com/pub/rhel6/dvd"
REPO_FILE_GLOB_47="/etc/yum.repos.d/*.repo"
FOUND_REPO_47=false
FOUND_GPG_47=false

for repo_file in $REPO_FILE_GLOB_47; do
    if [ -f "$repo_file" ] && grep -Eq "baseurl\s*=\s*${REPO_URL_47}" "$repo_file"; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Repository file '$repo_file' found with correct baseurl." | tee -a ${REPORT_FILE}
        T47_SCORE=$(( T47_SCORE + 10 ))
        FOUND_REPO_47=true
        if grep -Eq '^\s*gpgcheck\s*=\s*0' "$repo_file"; then
            echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t gpgcheck=0 found in '$repo_file'." | tee -a ${REPORT_FILE}
            T47_SCORE=$(( T47_SCORE + 10 ))
            FOUND_GPG_47=true
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t gpgcheck=0 not found in '$repo_file'." | tee -a ${REPORT_FILE}
        fi
        break # Found matching repo file
    fi
done

if ! $FOUND_REPO_47; then
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t No repository file found in /etc/yum.repos.d/ with baseurl '$REPO_URL_47'." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T47_SCORE ))
TOTAL=$(( TOTAL + T47_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 48: Configure Default Gateway
echo -e "${COLOR_INFO}Evaluating Task 48: Configure Default Gateway (192.168.0.254)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T48_SCORE=0
T48_TOTAL=15
GATEWAY_IP="192.168.0.254"
# Check running configuration
if ip route show default | grep -q "via ${GATEWAY_IP}"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default gateway ${GATEWAY_IP} found in current routing table." | tee -a ${REPORT_FILE}
    T48_SCORE=$(( T48_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default gateway ${GATEWAY_IP} not found in current routing table." | tee -a ${REPORT_FILE}
fi
# Check persistent configuration (primary connection)
PRIMARY_CONN_48=$(nmcli -g NAME,DEVICE,STATE c show --active | grep -v ':lo:' | head -n 1 | cut -d: -f1)
if [[ -n "$PRIMARY_CONN_48" ]] && nmcli con show "$PRIMARY_CONN_48" | grep -q "ipv4\.gateway:\s*${GATEWAY_IP}"; then
     echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Gateway ${GATEWAY_IP} configured persistently on connection '$PRIMARY_CONN_48'." | tee -a ${REPORT_FILE}
     T48_SCORE=$(( T48_SCORE + 10 ))
elif [[ -n "$PRIMARY_CONN_48" ]]; then
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Gateway ${GATEWAY_IP} NOT configured persistently on connection '$PRIMARY_CONN_48'." | tee -a ${REPORT_FILE}
     echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}\t Note: Checking deprecated /etc/sysconfig/network GATEWAY is less reliable." | tee -a ${REPORT_FILE}
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine primary active connection to check persistent gateway." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T48_SCORE ))
TOTAL=$(( TOTAL + T48_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 49: Add 100M Swap Partition
echo -e "${COLOR_INFO}Evaluating Task 49: Add 100M Swap Partition${COLOR_RESET}" | tee -a ${REPORT_FILE}
T49_SCORE=0
T49_TOTAL=20
SWAP_COUNT_49=$(swapon -s | sed '1d' | wc -l)
ORIG_SWAP_DEVICE_49=$(swapon -s | sed '1d' | awk '{print $1}' | head -n 1)
FOUND_NEW_SWAP_49=false
NEW_SWAP_SIZE_OK_49=false

if [[ $SWAP_COUNT_49 -gt 1 ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found more than one active swap space." | tee -a ${REPORT_FILE}
    T49_SCORE=$(( T49_SCORE + 5 ))
    while IFS= read -r line; do
        [[ "$line" =~ ^\# ]] && continue
        [[ "$line" =~ ^\s*$ ]] && continue
        FS_SPEC=$(echo "$line" | awk '{print $1}')
        FS_TYPE=$(echo "$line" | awk '{print $3}')
        if [[ "$FS_SPEC" != "$ORIG_SWAP_DEVICE_49" ]] && [[ "$FS_TYPE" == "swap" ]]; then
            FOUND_NEW_SWAP_49=true
            BLOCK_DEV=$(blkid -t UUID=$(echo $FS_SPEC | sed 's/UUID=//; s/"//g') -o device || echo $FS_SPEC)
            if [[ -b "$BLOCK_DEV" ]]; then
                SIZE_MB=$(lsblk -bno SIZE "$BLOCK_DEV" 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
                # Check size approx 100M (e.g., 90-110)
                if [[ "$SIZE_MB" -ge 90 ]] && [[ "$SIZE_MB" -le 110 ]]; then
                    NEW_SWAP_SIZE_OK_49=true
                fi
            fi
            break
        fi
    done < /etc/fstab

    if $FOUND_NEW_SWAP_49; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Found a persistent swap entry in /etc/fstab (different from original)." | tee -a ${REPORT_FILE}
        T49_SCORE=$(( T49_SCORE + 10 ))
        if $NEW_SWAP_SIZE_OK_49; then
             echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t The new swap partition size seems correct (~100M)." | tee -a ${REPORT_FILE}
             T49_SCORE=$(( T49_SCORE + 5 ))
        else
             echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t The size of the new swap partition could not be verified or is incorrect (Expected ~100M)." | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Could not find a persistent swap entry in /etc/fstab for the additional swap space." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Did not find more than one active swap space (expected original + new 100M)." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T49_SCORE ))
TOTAL=$(( TOTAL + T49_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}

### TASK 50: Static Network Config with Gateway (Rehash)
echo -e "${COLOR_INFO}Evaluating Task 50: Static Network Config with Gateway (Rehash)${COLOR_RESET}" | tee -a ${REPORT_FILE}
T50_SCORE=0
T50_TOTAL=15 # Focus on gateway persistence check
GATEWAY_IP_50="192.168.0.254"
# Check running configuration
if ip route show default | grep -q "via ${GATEWAY_IP_50}"; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Default gateway ${GATEWAY_IP_50} found in current routing table." | tee -a ${REPORT_FILE}
    T50_SCORE=$(( T50_SCORE + 5 ))
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Default gateway ${GATEWAY_IP_50} not found in current routing table." | tee -a ${REPORT_FILE}
fi
# Check persistent configuration (primary connection)
PRIMARY_CONN_50=$(nmcli -g NAME,DEVICE,STATE c show --active | grep -v ':lo:' | head -n 1 | cut -d: -f1)
if [[ -n "$PRIMARY_CONN_50" ]]; then
     CONN_METHOD=$(nmcli -g ipv4.method con show "$PRIMARY_CONN_50")
     CONN_GW=$(nmcli -g ipv4.gateway con show "$PRIMARY_CONN_50")
     if [[ "$CONN_METHOD" == "manual" ]] && [[ "$CONN_GW" == "$GATEWAY_IP_50" ]]; then
         echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Gateway ${GATEWAY_IP_50} configured persistently (manual method) on connection '$PRIMARY_CONN_50'." | tee -a ${REPORT_FILE}
         T50_SCORE=$(( T50_SCORE + 10 ))
     else
         echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Gateway ${GATEWAY_IP_50} NOT configured persistently (or method not manual) on connection '$PRIMARY_CONN_50'." | tee -a ${REPORT_FILE}
     fi
else
     echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine primary active connection to check persistent gateway." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T50_SCORE ))
TOTAL=$(( TOTAL + T50_TOTAL ))
echo -e "\n" | tee -a ${REPORT_FILE}


### TASK 51: LVM Shrink 'vo/myvol'
echo -e "${COLOR_INFO}Evaluating Task 51: LVM Shrink 'vo/myvol' to ~200MiB${COLOR_RESET}" | tee -a ${REPORT_FILE}
T51_SCORE=0
T51_TOTAL=25
LV_NAME_51="myvol"
VG_NAME_51="vo" # Assuming VG name based on path /dev/vo/myvol
LV_PATH_51="/dev/${VG_NAME_51}/${LV_NAME_51}"

# Check if LV exists
if [[ -b "$LV_PATH_51" ]]; then
    echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Logical Volume '$LV_NAME_51' in VG '$VG_NAME_51' found." | tee -a ${REPORT_FILE}
    T51_SCORE=$(( T51_SCORE + 5 ))
    # Check LV size (between 200M and 210M)
    LV_SIZE_MB_51=$(lvs --noheadings --units m -o lv_size $LV_PATH_51 | sed 's/[^0-9.]*//g' | cut -d. -f1)
    if [[ $LV_SIZE_MB_51 -ge 200 ]] && [[ $LV_SIZE_MB_51 -le 210 ]]; then
        echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t LV '$LV_NAME_51' size is ${LV_SIZE_MB_51}M (within 200-210 MiB range)." | tee -a ${REPORT_FILE}
        T51_SCORE=$(( T51_SCORE + 10 ))

        # Check filesystem size (should be slightly smaller than LV)
        MOUNT_POINT_51=$(findmnt -no TARGET ${LV_PATH_51})
        if [[ -n "$MOUNT_POINT_51" ]]; then
            FS_TYPE_51=$(findmnt -no FSTYPE ${LV_PATH_51})
            # Check FS type supports shrink (ext4) - XFS check
             if [[ "$FS_TYPE_51" == "xfs" ]]; then
                  echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem type is XFS, which cannot be shrunk. Task likely impossible." | tee -a ${REPORT_FILE}
             else
                 FS_SIZE_MB_51=$(df -BM --output=size ${MOUNT_POINT_51} 2>/dev/null | tail -n 1 | sed 's/[^0-9]*//g')
                 if [[ -n "$FS_SIZE_MB_51" ]] && [[ $FS_SIZE_MB_51 -ge $((LV_SIZE_MB_51 - 20)) ]] && [[ $FS_SIZE_MB_51 -le $LV_SIZE_MB_51 ]]; then
                      echo -e "${COLOR_OK}[OK]${COLOR_RESET}\t\t Filesystem on '$LV_NAME_51' appears shrunk (FS Size: ${FS_SIZE_MB_51}M)." | tee -a ${REPORT_FILE}
                      T51_SCORE=$(( T51_SCORE + 10 ))
                 else
                      echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Filesystem on '$LV_NAME_51' does not appear shrunk (FS Size: ${FS_SIZE_MB_51}M vs LV Size: ${LV_SIZE_MB_51}M)." | tee -a ${REPORT_FILE}
                 fi
             fi
        else
            echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Cannot determine mount point for '$LV_NAME_51' to check filesystem size. Is it mounted?" | tee -a ${REPORT_FILE}
        fi
    else
        echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t LV '$LV_NAME_51' size is ${LV_SIZE_MB_51}M (NOT within 200-210 MiB range)." | tee -a ${REPORT_FILE}
    fi
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t Logical Volume '$LV_PATH_51' not found." | tee -a ${REPORT_FILE}
fi
SCORE=$(( SCORE + T51_SCORE ))
TOTAL=$(( TOTAL + T51_TOTAL ))
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
echo -e "${COLOR_INFO}Your total score for Batch 5 is $SCORE out of a total of $TOTAL${COLOR_RESET}"

PASS_SCORE=$(( TOTAL * PASS_THRESHOLD / 100 ))

if [[ $SCORE -ge $PASS_SCORE ]]; then
    echo -e "${COLOR_OK}CONGRATULATIONS!!${COLOR_RESET}\t You passed this practice test (Score >= ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Remember, this is practice; the real exam may differ."
else
    echo -e "${COLOR_FAIL}[FAIL]${COLOR_RESET}\t\t You did NOT pass this practice test (Score < ${PASS_THRESHOLD}%)."
    echo -e "\t\t\t Review the [FAIL] messages in ${REPORT_FILE} and study the corresponding topics."
fi
echo -e "\nFull report saved to ${REPORT_FILE}"