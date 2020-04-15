#!/bin/bash

# Teal Dulcet
# Outputs system usage information
# wget https://raw.github.com/tdulcet/System-Usage-Information/master/usage.sh -qO - | bash -s --
# ./usage.sh

# Set the variables below

# CPU usage percentage
CPU_CRITICAL=90
CPU_WARNING=70

# Load average (multiplied by number of CPU threads)
LOAD_CRITICAL=5
LOAD_WARNING=1

# PSI average percentage
PRESSURE_CRITICAL=10
PRESSURE_WARNING=0

# RAM usage percentage
RAM_CRITICAL=90
RAM_WARNING=70

# Swap space usage percentage
SWAP_CRITICAL=90
SWAP_WARNING=70

# Disk space usage percentage
DISK_SPACE_CRITICAL=90 # 85
DISK_SPACE_WARNING=70

# Disk IO usage percentage
DISK_CRITICAL=90
DISK_WARNING=80

# Network usage percentage
NET_CRITICAL=90
NET_WARNING=80

# GPU usage percentage
GPU_CRITICAL=90
GPU_WARNING=70

# GPU RAM usage percentage
GPU_RAM_CRITICAL=90
GPU_RAM_WARNING=70

# CPU Temperature °C
CPU_TEMP_CRITICAL=80
CPU_TEMP_WARNING=70

# CPU Temperature °C
GPU_TEMP_CRITICAL=105
GPU_TEMP_WARNING=95

# Battery percentage
BATTERY_LOW=10
BATTERY_CRITICAL=5

bar_length=40

# Public DNS servers that validate responses DNS Security Extensions (DNSSEC) to use with the dig and delv commands
# Use if your ISP does not support DNSSEC and you are not running a local DNSSEC validating recursive resolver, such as bind9 (https://www.perfacilis.com/blog/systeembeheer/linux/setup-a-public-dns-server.html)

# IPv4 DNS server
DNS="1.1.1.1" # Cloudflare
# DNS="8.8.8.8" # Google Public DNS

# IPv6 DNS server
# DNS="2606:4700:4700::1111" # Cloudflare
# DNS="2001:4860:4860::8888" # Google Public DNS

# Public IP address service URL
# To find the service with the best HTTPS response times on your network, run this script: wget https://raw.github.com/tdulcet/System-Usage-Information/master/ipinfo.sh -qO - | bash -s
PUBLIC_IP_URL="https://icanhazip.com/"

# Do not change anything below this

RED='\e[0;31m'
YELLOW='\e[0;33m'
GREEN='\e[0;32m'
BOLD='\e[1m'
DIM='\e[2m'
NC='\e[m' # No Color

suffix_power_char=("" "K" "M" "G" "T" "P" "E" "Z" "Y")

# Check if on Linux
if ! echo "$OSTYPE" | grep -iq "linux"; then
	echo "Error: This script must be run on Linux." >&2
	exit 1
fi

# Output usage
# usage <programname>
usage() {
	echo "Usage:  $1 [OPTION(S)]...

Options:
    -p              Show Public IP addresses and hostnames
                        Requires internet connection.
    -w              Show current Weather
                        Requires internet connection.
    -s              Shorten output
                        Do not show CPU Thread usage and PSI averages. Useful for displaying a message of the day (motd).
    -u              Use Unicode usage bars

    -h              Display this help and exit
    -v              Output version information and exit

Examples:
    Output everything
    $ $1 -pw
" >&2
}

while getopts "hpsuvwW" c; do
	case ${c} in
	h )
		usage "$0"
		exit 0
	;;
	p )
		PUBLIC_IP=1
	;;
	s )
		SHORT=1
	;;
	u )
		UNICODE=1
	;;
	v )
		echo -e "System Usage Information 1.0\n"
		exit 0
	;;
	w )
		WEATHER=1
	;;
	W )
		WATCH=1
	;;
	\? )
		echo -e "Try '$0 -h' for more information.\n" >&2
		exit 1
	;;
	esac
done
shift $((OPTIND - 1))

if [[ "$#" -ne 0 ]]; then
	usage "$0"
	exit 1
fi

# Adapted from: https://github.com/tdulcet/Remote-Servers-Status/blob/master/status.sh
# getSecondsAsDigitalClock <seconds>
getSecondsAsDigitalClock() {
	local sec_num=$1
	local d=$(( sec_num / 86400 ))
	local h=$(( (sec_num % 86400) / 3600 ))
	local m=$(( (sec_num % 86400 % 3600) / 60 ))
	local s=$(( sec_num % 86400 % 3600 % 60 ))
	local text=''
	if [[ $d -ne 0 ]]; then
		text+="$(printf "%'d" "$d") days "
	fi
	if [[ $d -ne 0 || $h -ne 0 ]]; then
		text+="$h hours "
	fi
	if [[ $d -ne 0 || $h -ne 0 || $m -ne 0 ]]; then
		text+="$m minutes "
	fi
	text+="$s seconds"
	echo "$text"
}

# cpuusage [CPU number]
cpuusage() {
	local diff_idle diff_total
	local previous_cpu=( $(echo "$PREVIOUS_STATS" | sed -n "s/^cpu$1 \+//p") )
	local cpu=( $(echo "$STATS" | sed -n "s/^cpu$1 \+//p") )

	local previous_total=0
	for i in "${previous_cpu[@]::8}"; do
		((previous_total+=i))
	done

	local total=0
	for i in "${cpu[@]::8}"; do
		((total+=i))
	done

	diff_idle=$(( cpu[3] - previous_cpu[3] ))
	diff_total=$(( total - previous_total ))

	echo "$diff_idle $diff_total" | awk '{ printf "%g", ($2 - $1) / $2 * 100 }'
}

# Usage bar
# Adapted from: https://github.com/dylanaraps/pure-bash-bible#progress-bars
# bar <usage percentage (0-100)> [color] [label]
bar() {
	if [[ -z "$UNICODE" ]]; then
		local label usage prog total output
		label="$(printf "%.1f" "$1")%${3:+ $3}"
		# ((usage=$1 * bar_length / 100))
		usage=$(echo "$1 $bar_length" | awk '{ printf "%d", $1 * $2 / 100 }')

		# Create the bar with spaces.
		if [[ ${#label} -gt $((bar_length - usage)) ]]; then
			printf -v prog  "%$(( bar_length - ${#label} ))s"
			total=''
		else
			printf -v prog  "%${usage}s"
			printf -v total "%$(( bar_length - usage - ${#label} ))s"
		fi

		output="${prog// /|}${total}${label}"
		echo -e -n "[${2}${output::$usage}${NC}${output:$usage}]"
	else
		local label abar_length usage prog total
		label="$(printf "%.1f" "$1")%"
		((abar_length=bar_length*8))
		usage=$(echo "$1 $abar_length" | awk '{ printf "%d", $1 * $2 / 100 }')

		# Create the bar with spaces.
		printf -v prog  "%$(( usage / 8 ))s"
		printf -v total "%$(( (abar_length - usage) / 8 ))s"

		blocks=( "" "▏" "▎" "▍" "▌" "▋" "▊" "▉" )
		echo -e -n "${label} [${2}${prog// /█}${blocks[usage % 8]}${NC}${total}]${3:+ $3}"
	fi
}

# Auto-scale number to unit
# Adapted from: https://github.com/tdulcet/Numbers-Tool/blob/master/numbers.cpp
# outputunit <number> [scale_base]
# scale_base:
	# 0=scale_IEC_I
	# 1=scale_SI
outputunit() {
	local number=$1
	local str scale_base anumber length prec
	
	if (( $2 )); then
		scale_base=1000
	else
		scale_base=1024
	fi

	local power=0
	while (( $(echo "$number $scale_base" | awk 'function abs(x) { return x<0 ? -x : x } { print (abs($1)>=$2) }') )); do
		((++power))
		number=$(echo "$number $scale_base" | awk '{ printf "%g", $1 / $2 }')
	done

	anumber=$(echo "$number" | awk 'function abs(x) { return x<0 ? -x : x } { printf "%g", abs($1) + 0.5 }')

	if (( $(echo "$number $anumber" | awk '{ print $1!=0 && $2<1000 }') )) && [[ $power -gt 0 ]]; then
		str=$(printf '%g' "$number")

		((length=5 + ($(echo "$number" | awk '{ print $1<0 }') ? 1 : 0)))
		if [[ ${#str} -gt $length ]]; then
			prec=$(echo "$anumber" | awk '{ print $1<10 ? 3 : ($1<100 ? 2 : ($1<1000 ? 1 : 0)) }')
			str=$(printf "%'.*f" "$prec" "$number")
		fi
	else
		str=$(printf "%'.0f" "$number")
	fi
	
	if [[ $power -lt 9 ]]; then
		str+=${suffix_power_char[power]}
	else
		str+="(error)"
	fi
	
	if ! (( $2 )) && [[ $power -gt 0 ]]; then
		str+="i"
	fi

	echo "$str"
	# echo "$1: $str"
}

# outputusage <used KiB> <total KiB> <critical percentage> <warning percentage>
outputusage() {
	local usage
	local used=$(( $1 * 1024 ))
	local total=$(( $2 * 1024 ))
	usage=$([[ $2 -gt 0 ]] && echo "$1 $2" | awk '{ printf "%g", $1 / $2 * 100 }' || echo "0")
	if (( $(echo "$usage $3" | awk '{ print ($1>=$2) }') )); then
		bar "$usage" "${RED}"
	elif (( $(echo "$usage $4" | awk '{ print ($1>=$2) }') )); then
		bar "$usage" "${YELLOW}"
	else
		bar "$usage" "${GREEN}"
	fi
	echo "  $(outputunit "$used" 0)B/$(outputunit "$total" 0)B$([[ $2 -gt 0 ]] && echo " ($(outputunit "$used" 1)B/$(outputunit "$total" 1)B)")"
}

# BtoKiB <B>
BtoKiB() {
	echo "$(printf "%'d" $(( $1 / 1024 )))KiB/s"
}

# BtoKB <B>
BtoKB() {
	echo "$(printf "%'d" $(( $1 / 1000 )))KB/s"
}

# BtoKib <B>
BtoKib() {
	echo "$(printf "%'d" $(( $1 / 128 )))Kib/s"
}

# BtoKb <B>
BtoKb() {
	echo "$(printf "%'d" $(( $1 / 125 )))Kbps"
}

# outputcpuusage <usage percentage> [label]
outputcpuusage() {
	if (( $(echo "$1 $CPU_CRITICAL" | awk '{ print ($1>=$2) }') )); then
		bar "$1" "${RED}" "$2"
	elif (( $(echo "$1 $CPU_WARNING" | awk '{ print ($1>=$2) }') )); then
		bar "$1" "${YELLOW}" "$2"
	else
		bar "$1" "${GREEN}" "$2"
	fi
}

# outputloadavg <load average>
outputloadavg() {
	if (( $(echo "$1 $LOAD_CRITICAL $CPU_THREADS" | awk '{ print ($1>$2 * $3) }') )); then
		echo -e "${RED}$1${NC}"
	elif (( $(echo "$1 $LOAD_WARNING $CPU_THREADS" | awk '{ print ($1>$2 * $3) }') )); then
		echo -e "${YELLOW}$1${NC}"
	else
		echo -e "${GREEN}$1${NC}"
	fi
}

# outputpressure <PSI average>
outputpressure() {
	if (( $(echo "$1 $PRESSURE_CRITICAL" | awk '{ print ($1>$2) }') )); then
		echo -e "${RED}$1${NC}%"
	elif (( $(echo "$1 $PRESSURE_WARNING" | awk '{ print ($1>$2) }') )); then
		echo -e "${YELLOW}$1${NC}%"
	else
		echo -e "${GREEN}$1${NC}%"
	fi
}

# Celsius to Fahrenheit
# ctof <temperature>
ctof() {
	echo "$1" | awk '{ printf "%g", ($1 * (9 / 5)) + 32 }'
}

# outputcputemp <temperature>
outputcputemp() {
	local temp
	temp=$(echo "$1" | awk '{ printf "%g", $1 / 1000 }')
	if [[ $1 -ge ${2:-$((CPU_TEMP_CRITICAL * 1000))} ]]; then
		echo -e "${RED}$(printf "%.1f" "$temp")${NC}°C (${RED}$(printf "%.1f" "$(ctof "$temp")")${NC}°F)"
	elif [[ $1 -ge ${3:-$((CPU_TEMP_WARNING * 1000))} ]]; then
		echo -e "${YELLOW}$(printf "%.1f" "$temp")${NC}°C (${YELLOW}$(printf "%.1f" "$(ctof "$temp")")${NC}°F)"
	else
		echo -e "${GREEN}$(printf "%.1f" "$temp")${NC}°C (${GREEN}$(printf "%.1f" "$(ctof "$temp")")${NC}°F)"
	fi
}

# outputgputemp <temperature>
outputgputemp() {
	if (( $(echo "$1 $GPU_TEMP_CRITICAL" | awk '{ print ($1>=$2) }') )); then
		echo -e "${RED}$(printf "%.1f" "$1")${NC}°C (${RED}$(printf "%.1f" "$(ctof "$1")")${NC}°F)"
	elif (( $(echo "$1 $GPU_TEMP_WARNING" | awk '{ print ($1>=$2) }') )); then
		echo -e "${YELLOW}$(printf "%.1f" "$1")${NC}°C (${YELLOW}$(printf "%.1f" "$(ctof "$1")")${NC}°F)"
	else
		echo -e "${GREEN}$(printf "%.1f" "$1")${NC}°C (${GREEN}$(printf "%.1f" "$(ctof "$1")")${NC}°F)"
	fi
}

if [[ -n "$WATCH" ]]; then
	tput smcup
	# echo -e -n "\e7\e[?47h"
	trap 'tput rmcup' EXIT
	# trap 'echo -e -n "\e[2J\e[?47l\e8"' EXIT
fi

CPU_THREADS=$(nproc --all) # $(lscpu | grep -i '^cpu(s)' | sed -n 's/^.\+:[[:blank:]]*//p')
CPU_CORES=$(( CPU_THREADS / $(lscpu | grep -i '^thread(s) per core' | sed -n 's/^.\+:[[:blank:]]*//p') ))
DISKS=$(lsblk -dbn 2>/dev/null | awk '$6=="disk"')
NAMES=( $(echo "$DISKS" | awk '{print $1}') )
INERFACES=( $(ip -o a show up primary scope global | awk '{print $2}' | uniq) )
PREVIOUS_STATS=$(</proc/stat)
DISK_NAMES=()
PREVIOUS_DISK_STATS=()
for name in "${NAMES[@]}"; do
	file="/sys/block/$name/stat"
	if [[ -r "$file" ]]; then
		DISK_NAMES+=( "$name" )
		PREVIOUS_DISK_STATS+=( "$(<"$file")" )
	fi
done
NET_INERFACES=()
PREVIOUS_NETR=()
PREVIOUS_NETT=()
for inerface in "${INERFACES[@]}"; do
	file="/sys/class/net/$inerface"
	if [[ -d "$file/statistics" ]]; then
		NET_INERFACES+=( "$inerface" )
		PREVIOUS_NETR+=( "$(<"$file/statistics/rx_bytes")" )
		PREVIOUS_NETT+=( "$(<"$file/statistics/tx_bytes")" )
	fi
done

while true; do
	sleep 1
	STATS=$(</proc/stat)
	DISK_STATS=()
	for name in "${DISK_NAMES[@]}"; do
		file="/sys/block/$name/stat"
		if [[ -r "$file" ]]; then
			DISK_STATS+=( "$(<"$file")" )
		fi
	done
	NETR=()
	NETT=()
	NET_SPEED=()
	for inerface in "${NET_INERFACES[@]}"; do
		file="/sys/class/net/$inerface"
		if [[ -d "$file/statistics" ]]; then
			NETR+=( "$(<"$file/statistics/rx_bytes")" )
			NETT+=( "$(<"$file/statistics/tx_bytes")" )
			if [[ -r "$file/speed" ]]; then
				NET_SPEED+=( "$(<"$file/speed")" )
			else
				NET_SPEED+=( "" )
			fi
		fi
	done
	LOADAVG=( $(</proc/loadavg) )
	file=/proc/pressure
	if [[ -z "$SHORT" && -d "$file" ]]; then
		CPU_PRESSURE=( $(awk -F'[ =]' '/^some/ {print $3,$5,$7}' "$file/cpu") )
		MEM_PRESSURE=( $(awk -F'[ =]' '/^some/ {print $3,$5,$7}' "$file/memory") )
		IO_PRESSURE=( $(awk -F'[ =]' '/^some/ {print $3,$5,$7}' "$file/io") )
	fi
	CPU_FREQ=( $(sed -n 's/^cpu MHz[[:space:]]*: *//p' /proc/cpuinfo) )
	if [[ -z "$CPU_FREQ" ]] || [[ $CPU_THREADS -gt 1 && $(printf '%s\n' "${CPU_FREQ[@]}" | sort -nu | wc -l) -eq 1 ]]; then
		for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
			if [[ -r "$file" ]]; then
				CPU_FREQ=()
				# CPU_FREQ=( $(awk '{ printf "%g\n", $1 / 1000 }' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq) )
				for (( i=0; ; ++i )); do
					file="/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq"
					if [[ -r "$file" ]]; then
						CPU_FREQ+=( "$(awk '{ printf "%g", $1 / 1000 }' "$file")" )
					else
						break
					fi
				done
			fi
			break
		done
	fi
	TEMP=()
	TEMP_LABEL=()
	TEMP_HIGH=()
	TEMP_CRITICAL=()
	for file in /sys/class/hwmon/hwmon*/temp*_input; do
		if [[ -r "$file" ]]; then
			TEMP+=( "$(<"$file")" )
			file=${file%_*}
			if [[ -r "${file}_label" ]]; then
				TEMP_LABEL+=( "$(<"${file}_label")" )
			else
				TEMP_LABEL+=( "" )
			fi
			if [[ -r "${file}_max" ]]; then
				TEMP_HIGH+=( "$(<"${file}_max")" )
			else
				TEMP_HIGH+=( "" )
			fi
			if [[ -r "${file}_crit" ]]; then
				TEMP_CRITICAL+=( "$(<"${file}_crit")" )
			else
				TEMP_CRITICAL+=( "" )
			fi
		fi
	done
	if [[ -z "$TEMP" ]]; then
		for file in /sys/class/thermal/thermal_zone*/temp; do
			if [[ -r "$file" ]]; then
				TEMP+=( "$(<"$file")" )
				file=${file%/*}
				TEMP_LABEL+=( "$(<"$file/type")" )
				high=''
				critical=''
				for afile in "$file"/trip_point_*_type; do
					if [[ -r "$afile" ]]; then
						type=$(<"$afile")
						if [[ $type == "hot" ]]; then
							high=$(<"${afile%_*}_temp")
						elif [[ $type == "critical" ]]; then
							critical=$(<"${afile%_*}_temp")
						fi
					fi
				done
				TEMP_HIGH+=( "$high" )
				TEMP_CRITICAL+=( "$critical" )
			fi
		done
	fi
	MEMINFO=$(</proc/meminfo)
	PROCESSES=0
	ZOMBIES=0
	THREADS=0
	for process in /proc/[0-9]*; do
		((++PROCESSES))
		if [[ $(awk '/^State:/ {print $2}' "$process/status" 2>/dev/null) == "Z" ]]; then
			((++ZOMBIES))
		fi
		# for thread in "$process"/task/[0-9]*; do
			# ((++THREADS))
		# done
		threads=( "$process"/task/[0-9]* )
		((THREADS+=${#threads[*]}))
	done
	for file in /sys/class/power_supply/[B,b]*; do
		if [[ -d "$file" ]]; then
			if [[ -r "$file/energy_now" && -r "$file/energy_full" ]]; then
				BATTERY_CAPACITY=$(echo "$(<"$file/energy_now") $(<"$file/energy_full")" | awk '{ printf "%g", $1 / $2 * 100 }')
			elif [[ -r "$file/charge_now" && -r "$file/charge_full" ]]; then
				BATTERY_CAPACITY=$(echo "$(<"$file/charge_now") $(<"$file/charge_full")" | awk '{ printf "%g", $1 / $2 * 100 }')
			elif [[ -r "$file/capacity" ]]; then
				BATTERY_CAPACITY=$(<"$file/capacity")
			fi
			if [[ -r "$file/status" ]]; then
				BATTERY_STATUS=$(<"$file/status")
			fi
			break
		fi
	done
	UPTIME=$(awk '{print int($1)}' /proc/uptime)
	
	if [[ -n "$WATCH" ]]; then
		# tput cup 0 0
		echo -e -n "\e[1;1H" # "\e[2J"
	fi

	echo "System usage information as of $(date)"

	CPU_USAGE=$(cpuusage)
	echo -e "\n${BOLD}Processor (CPU) usage${NC}:\t\t$(outputcpuusage "$CPU_USAGE" "${CPU_FREQ:+$(printf "%'.0f" "$(printf '%s\n' "${CPU_FREQ[@]}" | sort -nr | head -n 1)") MHz}")"

	echo -e "\t${BOLD}CPU Cores/Threads${NC}:\t$CPU_CORES/$CPU_THREADS"

	if [[ -z "$SHORT" ]]; then
		CPUS_USAGE=()
		for (( i=0; ; ++i )); do
			if echo "$STATS" | grep -q "^cpu$i "; then
				CPUS_USAGE+=( "$(cpuusage "$i")" )
			else
				break
			fi
		done
		if [[ $CPU_THREADS -gt 1 ]]; then
			echo -e "\t${BOLD}CPU Thread usage${NC}:"
			for i in "${!CPUS_USAGE[@]}"; do
				echo -e "${BOLD}$(printf "%'3d" $(( i + 1 )))${NC}: $(outputcpuusage "${CPUS_USAGE[i]}" "${CPU_FREQ:+$(printf "%'0.f" "${CPU_FREQ[i]}") MHz}")"
			done | column
		fi
	fi

	echo -e "${BOLD}Load average${NC} (1, 5, 15 minutes):$(outputloadavg "${LOADAVG[0]}"), $(outputloadavg "${LOADAVG[1]}"), $(outputloadavg "${LOADAVG[2]}")"

	if [[ -z "$SHORT" && -n "$CPU_PRESSURE" && -n "$MEM_PRESSURE" && -n "$IO_PRESSURE" ]]; then
		echo -e "${BOLD}Pressure Stall (PSI) average${NC} (10 seconds, 1, 5 minutes)"
		echo -e "\t${BOLD}PSI Some CPU${NC}:\t\t$(outputpressure "${CPU_PRESSURE[0]}"), $(outputpressure "${CPU_PRESSURE[1]}"), $(outputpressure "${CPU_PRESSURE[2]}")"
		echo -e "\t${BOLD}PSI Some RAM${NC}:\t\t$(outputpressure "${MEM_PRESSURE[0]}"), $(outputpressure "${MEM_PRESSURE[1]}"), $(outputpressure "${MEM_PRESSURE[2]}")"
		echo -e "\t${BOLD}PSI Some IO${NC}:\t\t$(outputpressure "${IO_PRESSURE[0]}"), $(outputpressure "${IO_PRESSURE[1]}"), $(outputpressure "${IO_PRESSURE[2]}")"
	fi

	if [[ -n "$TEMP" ]]; then
		echo -e -n "${BOLD}Temperature$([[ ${#TEMP[*]} -gt 1 ]] && echo "s")${NC}:\t\t\t"
		for i in "${!TEMP[@]}"; do
			echo -e -n "$([[ $i -gt 0 ]] && echo ", ")$([[ -n "${TEMP_LABEL[i]}" ]] && echo "${BOLD}${TEMP_LABEL[i]}${NC}: ")$(outputcputemp "${TEMP[i]}" "${TEMP_HIGH[i]}" "${TEMP_CRITICAL[i]}")"
		done
		echo
	fi

	TOTAL_PHYSICAL_MEM=$(echo "$MEMINFO" | awk '/^MemTotal:/ {print $2}')
	USED_PHYSICAL_MEM=$(( TOTAL_PHYSICAL_MEM + $(echo "$MEMINFO" | awk '/^MemFree:|^Buffers:|^Cached:|^SReclaimable:/ {printf " - "$2}') ))
	echo -e "${BOLD}Memory (RAM) usage${NC}:\t\t$(outputusage "$USED_PHYSICAL_MEM" "$TOTAL_PHYSICAL_MEM" "$RAM_CRITICAL" "$RAM_WARNING")"

	TOTAL_SWAP=$(echo "$MEMINFO" | awk '/^SwapTotal:/ {print $2}')
	USED_SWAP=$(( TOTAL_SWAP - $(echo "$MEMINFO" | awk '/^SwapFree:/ {print $2}') ))
	echo -e "${BOLD}Swap space usage${NC}:\t\t$(outputusage "$USED_SWAP" "$TOTAL_SWAP" "$SWAP_CRITICAL" "$SWAP_WARNING")"

	USERS=$(who -s | awk '{print $1}' | sort -u | wc -l)
	echo -e "${BOLD}Users logged in${NC}:\t\t$USERS"

	# awk '{if ($1!="'"$USER"'") { print $2 }}'
	IDLE=$(who -s | awk '{ print $2 }' | (cd /dev && xargs -r stat -c '%U %X' 2>/dev/null) | awk '{ print '"${EPOCHSECONDS:-$(date +%s)}"'-$2"\t"$1 }' | sort -n)
	if [[ -n "$IDLE" ]]; then
		echo -e "${BOLD}Idle time (last activity)${NC}:\t$(getSecondsAsDigitalClock "$(echo "$IDLE" | head -n 1 | awk '{print $1}')")"
	fi

	echo -e "${BOLD}Processes/Threads${NC}:\t\t$PROCESSES/$THREADS$([[ $ZOMBIES -gt 0 ]] && echo " (${RED}$ZOMBIES zombie process$([[ $ZOMBIES -gt 1 ]] && echo "es")${NC})")"

	DISK_USAGE=$(df -k / /home ~ | tail -n +2 | uniq)
	if [[ -n "$DISK_USAGE" ]]; then
		DISK_MOUNT=( $(echo "$DISK_USAGE" | awk '{print $6}') )
		TOTAL_DISK=( $(echo "$DISK_USAGE" | awk '{print $2}') )
		USED_DISK=( $(echo "$DISK_USAGE" | awk '{print $3}') )
		echo -e -n "${BOLD}Disk space usage${NC}:\t\t"
		for i in "${!DISK_MOUNT[@]}"; do
			if [[ ${TOTAL_DISK[i]} -gt 0 ]]; then
				echo -e "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${BOLD}${DISK_MOUNT[i]}${NC}: $(outputusage "${USED_DISK[i]}" "${TOTAL_DISK[i]}" "$DISK_SPACE_CRITICAL" "$DISK_SPACE_WARNING")"
			fi
		done
	fi

	DISK_READS=()
	DISK_WRITES=()
	DISK_TIMES=()
	for i in "${!DISK_NAMES[@]}"; do
		previous_disk_stat=( ${PREVIOUS_DISK_STATS[i]} )
		disk_stat=( ${DISK_STATS[i]} )
		DISK_READS+=( "$(( (disk_stat[2] - previous_disk_stat[2]) * 512 ))" )
		DISK_WRITES+=( "$(( (disk_stat[6] - previous_disk_stat[6]) * 512 ))" )
		DISK_TIMES+=( "$(( disk_stat[9] - previous_disk_stat[9] ))" )
	done
	if [[ -n "$DISK_NAMES" ]]; then
		echo -e -n "${BOLD}Disk IO usage${NC} (read/write):\t"
		for i in "${!DISK_NAMES[@]}"; do
			usage=$(echo "${DISK_TIMES[i]}" | awk '{ printf "%g", $1 / 10 }')
			echo -e -n "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${BOLD}${DISK_NAMES[i]}${NC}: "
			if (( $(echo "$usage $DISK_CRITICAL" | awk '{ print ($1>=$2) }') )); then
				bar "$usage" "${RED}"
			elif (( $(echo "$usage $DISK_WARNING" | awk '{ print ($1>=$2) }') )); then
				bar "$usage" "${YELLOW}"
			else
				bar "$usage" "${GREEN}"
			fi
			echo -e "  ${DIM}R${NC}: $(BtoKiB "${DISK_READS[i]}") ($(BtoKB "${DISK_READS[i]}")) ${DIM}W${NC}: $(BtoKiB "${DISK_WRITES[i]}") ($(BtoKB "${DISK_WRITES[i]}"))"
		done
	fi

	NETR_USAGE=()
	NETT_USAGE=()
	for i in "${!NET_INERFACES[@]}"; do
		NETR_USAGE+=( "$(( NETR[i] - PREVIOUS_NETR[i] ))" )
		NETT_USAGE+=( "$(( NETT[i] - PREVIOUS_NETT[i] ))" )
	done
	if [[ -n "$NET_INERFACES" ]]; then
		echo -e -n "${BOLD}Network usage${NC} (receive/transmit):"
		for i in "${!NET_INERFACES[@]}"; do
			echo -e -n "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${BOLD}${NET_INERFACES[i]}${NC}: "
			if [[ -n "${NET_SPEED[i]}" && ${NET_SPEED[i]} -gt 0 ]]; then
				usage=$(echo "$(( NETR_USAGE[i] + NETT_USAGE[i] )) $(( NET_SPEED[i] * 125000 ))" | awk '{ printf "%g", $1 / $2 * 100 }')
				if (( $(echo "$usage $NET_CRITICAL" | awk '{ print ($1>=$2) }') )); then
					bar "$usage" "${RED}"
				elif (( $(echo "$usage $NET_WARNING" | awk '{ print ($1>=$2) }') )); then
					bar "$usage" "${YELLOW}"
				else
					bar "$usage" "${GREEN}"
				fi
				echo -e "  ${DIM}↓R${NC}: $(BtoKib "${NETR_USAGE[i]}") ($(BtoKb "${NETR_USAGE[i]}")) ${DIM}↑T${NC}: $(BtoKib "${NETT_USAGE[i]}") ($(BtoKb "${NETT_USAGE[i]}")) / $(printf "%'d" $(( ((NET_SPEED[i] * 1000000) / 1024) / 1024 )))Mib/s ($(printf "%'d" "${NET_SPEED[i]}")Mbps)"
			else
				echo -e "${DIM}↓R${NC}: $(BtoKib "${NETR_USAGE[i]}") ($(BtoKb "${NETR_USAGE[i]}")) ${DIM}↑T${NC}: $(BtoKib "${NETT_USAGE[i]}") ($(BtoKb "${NETT_USAGE[i]}"))"
			fi
		done
	fi

	# nvidia-smi --query-gpu=gpu_name --format=csv,noheader
	if command -v nvidia-smi >/dev/null && nvidia-smi >/dev/null; then
		mapfile -t GPU_USAGE < <(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | grep -iv 'not supported')
		mapfile -t GPU_FREQ < <(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader | grep -iv 'not supported')
		if [[ -n "$GPU_USAGE" ]]; then
			echo -e -n "${BOLD}Graphics Processor (GPU) usage${NC}:\t"
			for i in "${!GPU_USAGE[@]}"; do
				echo -n "$([[ $i -gt 0 ]] && echo ", ")"
				if (( $(echo "${GPU_USAGE[i]} $GPU_CRITICAL" | awk '{ print ($1>=$2) }') )); then
					bar "${GPU_USAGE[i]}" "${RED}" "${GPU_FREQ[i]}"
				elif (( $(echo "${GPU_USAGE[i]} $GPU_WARNING" | awk '{ print ($1>=$2) }') )); then
					bar "${GPU_USAGE[i]}" "${YELLOW}" "${GPU_FREQ[i]}"
				else
					bar "${GPU_USAGE[i]}" "${GREEN}" "${GPU_FREQ[i]}"
				fi
			done
			echo
		else
			echo -e "${BOLD}Graphics Processor (GPU)${NC}"
		fi
		
		mapfile -t TOTAL_GPU_MEM < <(nvidia-smi --query-gpu=memory.total --format=csv,noheader | grep -iv 'not supported')
		mapfile -t USED_GPU_MEM < <(nvidia-smi --query-gpu=memory.used --format=csv,noheader | grep -iv 'not supported')
		if [[ -n "$TOTAL_GPU_MEM" && -n "$USED_GPU_MEM" ]]; then
			echo -e -n "\t${BOLD}GPU Memory (RAM) usage${NC}:\t"
			for i in "${!TOTAL_GPU_MEM[@]}"; do
				total=$(echo "${TOTAL_GPU_MEM[i]}" | awk '{print $1}')
				used=$(echo "${USED_GPU_MEM[i]}" | awk '{print $1}')
				usage=$([[ $total -gt 0 ]] && echo "$used $total" | awk '{ printf "%g", $1 / $2 * 100 }' || echo "0")
				echo -n "$([[ $i -gt 0 ]] && echo ", ")"
				if (( $(echo "$usage $GPU_RAM_CRITICAL" | awk '{ print ($1>=$2) }') )); then
					bar "$usage" "${RED}"
				elif (( $(echo "$usage $GPU_RAM_WARNING" | awk '{ print ($1>=$2) }') )); then
					bar "$usage" "${YELLOW}"
				else
					bar "$usage" "${GREEN}"
				fi
				echo -n "  ${USED_GPU_MEM[i]}/${TOTAL_GPU_MEM[i]}"
			done
			echo
		fi
		
		mapfile -t GPU_TEMP < <(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader | grep -iv 'not supported')
		if [[ -n "$GPU_TEMP" ]]; then
			echo -e -n "\t${BOLD}GPU Temperature$([[ ${#GPU_TEMP[*]} -gt 1 ]] && echo "s")${NC}:\t"
			for i in "${!GPU_TEMP[@]}"; do
				echo -n "$([[ $i -gt 0 ]] && echo ", ")$(outputgputemp "${GPU_TEMP[i]}")"
			done
			echo
		fi
	fi

	if [[ -n "$BATTERY_CAPACITY" ]]; then
		echo -e -n "${BOLD}Battery${NC}:\t\t\t"
		if (( $(echo "$BATTERY_CAPACITY $BATTERY_CRITICAL" | awk '{ print ($1<=$2) }') )); then
			bar "$BATTERY_CAPACITY" "${RED}"
		elif (( $(echo "$BATTERY_CAPACITY $BATTERY_LOW" | awk '{ print ($1<=$2) }') )); then
			bar "$BATTERY_CAPACITY" "${YELLOW}"
		else
			bar "$BATTERY_CAPACITY" "${GREEN}"
		fi
		echo "${BATTERY_STATUS:+ ($BATTERY_STATUS)}"
	fi

	echo -e "${BOLD}Uptime${NC}:\t\t\t\t$(getSecondsAsDigitalClock "$UPTIME")"

	HOSTNAME_FQDN=$(hostname -f) # hostname -A
	echo -e "${BOLD}Private Hostname${NC}:\t\t$HOSTNAME_FQDN"

	mapfile -t IPv4_ADDRESS < <(ip -o -4 a show up scope global | awk '{print $2,$4}')
	if [[ -n "$IPv4_ADDRESS" ]]; then
		IPv4_INERFACES=( $(printf '%s\n' "${IPv4_ADDRESS[@]}" | awk '{print $1}') )
		IPv4_ADDRESS=( $(printf '%s\n' "${IPv4_ADDRESS[@]}" | awk '{print $2}') )
		echo -e -n "${BOLD}Private IPv4 address$([[ ${#IPv4_ADDRESS[*]} -gt 1 ]] && echo "es")${NC}:\t\t"
		for i in "${!IPv4_INERFACES[@]}"; do
			echo -e "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${BOLD}${IPv4_INERFACES[i]}${NC}: ${IPv4_ADDRESS[i]%/*}"
		done
	fi
	mapfile -t IPv6_ADDRESS < <(ip -o -6 a show up scope global | awk '{print $2,$4}')
	if [[ -n "$IPv6_ADDRESS" ]]; then
		IPv6_INERFACES=( $(printf '%s\n' "${IPv6_ADDRESS[@]}" | awk '{print $1}') )
		IPv6_ADDRESS=( $(printf '%s\n' "${IPv6_ADDRESS[@]}" | awk '{print $2}') )
		echo -e -n "${BOLD}Private IPv6 address$([[ ${#IPv6_ADDRESS[*]} -gt 1 ]] && echo "es")${NC}:\t\t"
		for i in "${!IPv6_INERFACES[@]}"; do
			echo -e "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${BOLD}${IPv6_INERFACES[i]}${NC}: ${IPv6_ADDRESS[i]%/*}"
		done
	fi

	if [[ -n "$PUBLIC_IP" ]]; then
		if PUBLIC_IPV4_ADDRESS=$(curl -4 -sS "$PUBLIC_IP_URL" 2>&1); then
			if command -v delv >/dev/null; then
				if if [[ -n "$DNS" ]]; then output=$(delv +short -x "$PUBLIC_IPV4_ADDRESS" "@$DNS" 2>&1); else output=$(delv +short -x "$PUBLIC_IPV4_ADDRESS" 2>&1); fi && [[ -n "$output" ]]; then
					PUBLIC_IPV4_HOSTNAME=$(echo "$output" | grep -v '^;')
				elif output=$(echo "$output" | grep -i '^;; resolution failed') && ! echo "$output" | grep -iq 'ncache'; then
					echo "Error: Could not get reverse DNS (PTR) resource record: ${output#*: }"
				fi
			elif command -v dig >/dev/null; then
				if if [[ -n "$DNS" ]]; then output=$(dig +short -x "$PUBLIC_IPV4_ADDRESS" "@$DNS"); else output=$(dig +short -x "$PUBLIC_IPV4_ADDRESS"); fi && [[ -n "$output" ]]; then
					PUBLIC_IPV4_HOSTNAME=$output
				elif [[ -n "$output" ]]; then
					echo "Error: Could not get reverse DNS (PTR) resource record: $(echo "$output" | grep '^;;')"
				fi
			fi
			if [[ -n "$PUBLIC_IPV4_HOSTNAME" ]]; then
				echo -e "${BOLD}Public Hostname${NC}:\t\t$PUBLIC_IPV4_HOSTNAME"
			fi
			echo -e "${BOLD}Public IPv4 address${NC}:\t\t$PUBLIC_IPV4_ADDRESS"
		# else
			# echo "Error getting the public IPv4 address: $(echo "$PUBLIC_IPV4_ADDRESS" | head -n 1 | sed -n 's/^[^:]\+: ([^)]\+) //p')" >&2
		fi
		if PUBLIC_IPV6_ADDRESS=$(curl -6 -sS "$PUBLIC_IP_URL" 2>&1); then
			if command -v delv >/dev/null; then
				if if [[ -n "$DNS" ]]; then output=$(delv +short -x "$PUBLIC_IPV6_ADDRESS" "@$DNS" 2>&1); else output=$(delv +short -x "$PUBLIC_IPV6_ADDRESS" 2>&1); fi && [[ -n "$output" ]]; then
					PUBLIC_IPV6_HOSTNAME=$(echo "$output" | grep -v '^;')
				elif output=$(echo "$output" | grep -i '^;; resolution failed') && ! echo "$output" | grep -iq 'ncache'; then
					echo "Error: Could not get reverse DNS (PTR) resource record: ${output#*: }"
				fi
			elif command -v dig >/dev/null; then
				if if [[ -n "$DNS" ]]; then output=$(dig +short -x "$PUBLIC_IPV6_ADDRESS" "@$DNS"); else output=$(dig +short -x "$PUBLIC_IPV6_ADDRESS"); fi && [[ -n "$output" ]]; then
					PUBLIC_IPV6_HOSTNAME=$output
				elif [[ -n "$output" ]]; then
					echo "Error: Could not get reverse DNS (PTR) resource record: $(echo "$output" | grep '^;;')"
				fi
			fi
			if [[ -n "$PUBLIC_IPV6_HOSTNAME" ]]; then
				echo -e "${BOLD}Public Hostname${NC}:\t\t$PUBLIC_IPV6_HOSTNAME"
			fi
			echo -e "${BOLD}Public IPv6 address${NC}:\t\t$PUBLIC_IPV6_ADDRESS"
		# else
			# echo "Error getting the public IPv6 address: $(echo "$PUBLIC_IPV6_ADDRESS" | head -n 1 | sed -n 's/^[^:]\+: ([^)]\+) //p')" >&2
		fi
	fi

	if [[ -z "$WATCH" ]]; then
		if [[ -z "$SHORT" ]]; then
			echo -e "${BOLD}Language${NC}:\t\t\t$LANG"
		fi

		# echo -e "Bash Version:\t\t\t$BASH_VERSION"

		if [[ -n "$WEATHER" ]]; then
			if WEATHER=$(curl -sS https://wttr.in/?format=2 2>&1); then
				echo -e "${BOLD}Weather${NC}:\t\t\t$WEATHER"
			else
				echo "Error getting the weather: $(echo "$WEATHER" | head -n 1 | sed -n 's/^[^:]\+: ([^)]\+) //p')" >&2
			fi
		fi

		echo

		if [[ -z "$SHORT" ]]; then
			echo "For system information, run: wget https://web.cecs.pdx.edu/tdulcet/info.sh -qO - | bash -s"
		fi
		
		break
	else
		PREVIOUS_STATS=$STATS
		PREVIOUS_DISK_STATS=( "${DISK_STATS[@]}" )
		PREVIOUS_NETR=( "${NETR[@]}" )
		PREVIOUS_NETT=( "${NETT[@]}" )
	fi
done
