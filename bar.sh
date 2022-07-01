#!/bin/bash

while true; do

	# Battery stuff
	CH=$(acpi -b |tr -d ',' |awk '/^Battery 0:/ {print $3}')
	bat_color="#FFFFFF"

	case $CH in
		"Full"|"Not"|"Unknown") 
			perc=$(acpi -b |awk '/^Battery 0:/ {print $5}')
			battery_status="FULL";;
		"Discharging")
			read perc tm <<< $(acpi -b |tr -d ',' |awk '/^Battery 0:/ {print $4 " " $5}')
			battery_status="DIS $perc ($tm)"

			val=${perc::-1}

			if [ $val -le 10 ]; then
				bat_color="#FF0000"
				if [ $val -le 5 ]; then
					notify-send -u critical "LOW BATTERY! SOON GONNA DIE  : $perc"
				fi
			elif [ $val -le 25 ]; then
				bat_color="#FFA500"
			fi;;

		"Charging")
			read perc tm <<< $(acpi -b |tr -d ',' |awk '/^Battery 0:/ {print $4 " " $5}')
			battery_status="CHAR $perc ($tm)" ;;
		*);;
	esac

	# RAM stuff	
	read mem max <<< $(free -h | awk '/^Mem:/ {print $3 " " $2}')
	ram_status="$mem/$max"
	
	read memd maxd <<< $(free free  | awk '/^Mem:/ {print $3 " " $2}')
	
	if [ $memd -ge $((($maxd * 90) / 100)) ]; then
		ram_color="#FF0000"
	elif [ $memd -ge $((($maxd * 80) / 100)) ]; then
		ram_color="#FFA500"
	else
		ram_color="#FFFFFF"
	fi

	# Wlan stuff

	WLAN=$(ip --brief a show wlp1s0 | awk '{print $2}')

	case $WLAN in 
		"DOWN")
			wlan_status="wl DOWN";;
		"UP")

			SSID=$(iw wlp1s0 info |awk '/^\tssid/ {print $2}')
			if [ -z $SSID ]; then
				wlan_status="wl UP"
			else
				wlan_status=$(echo "WL $SSID" |cut -c 1-10)
			fi
		;;
	esac

	# Volume stuff
	muted=$(pulsemixer --get-mute)
	vol=$(pulsemixer --get-volume | awk '{print $1}')

	if [ $muted -eq 1 ]; then
		volume_status="MUTE-$vol%"
	else
		volume_status="$vol%"
	fi

	# Ethernet stuff

	ETH=$(ip --brief a show enp0s25 | awk '{print $2}')

	case $ETH in 
		"DOWN")
			eth_status="eth DOWN";;
		"UP")
			eth_status="eth UP";;
	esac

	# Time
	time_status=$(date "+%a %d/%m/%y - %T")


	# Banwidth stff

	INLABEL="IN"
	OUTLABEL="OUT"

	INTERFACE=$(ip route | awk '/^default/ { print $5 ; exit }')

	if [ -z "$INTERFACE" ]; then
		bw_status="wl DOWN"
	else

		# path to store the old results in
		path="/dev/shm/$(basename $0)-${INTERFACE}"

		# grabbing data for each adapter.
		read rx < "/sys/class/net/${INTERFACE}/statistics/rx_bytes"
		read tx < "/sys/class/net/${INTERFACE}/statistics/tx_bytes"

		# get time
		time=$(date +%s)

		# write current data if file does not exist. Do not exit, this will cause
		# problems if this file is sourced instead of executed as another process.
		if ! [[ -f "${path}" ]]; then
		  echo "${time} ${rx} ${tx}" > "${path}"
		  chmod 0666 "${path}"
		fi

		# read previous state and update data storage
		read old < "${path}"
		echo "${time} ${rx} ${tx}" > "${path}"

		# parse old data and calc time passed
		old=(${old//;/ })
		time_diff=$(( $time - ${old[0]} ))

		# sanity check: has a positive amount of time passed
		[[ "${time_diff}" -gt 0 ]] || exit

		# calc bytes transferred, and their rate in byte/s
		rx_diff=$(( $rx - ${old[1]} ))
		tx_diff=$(( $tx - ${old[2]} ))
		rx_rate=$(( $rx_diff / $time_diff ))
		tx_rate=$(( $tx_diff / $time_diff ))

		# shift by 10 bytes to get KiB/s. If the value is larger than
		# 1024^2 = 1048576, then display MiB/s instead

		# incoming
		rx_kib=$(( $rx_rate >> 10 ))
		if hash bc 2>/dev/null && [[ "$rx_rate" -gt 1048576 ]]; then
			in_status=$(printf '%sM' "`echo "scale=1; $rx_kib / 1024" | bc`")
		else
			in_status="${rx_kib}K"
		fi

		# outgoing
		tx_kib=$(( $tx_rate >> 10 ))
		if hash bc 2>/dev/null && [[ "$tx_rate" -gt 1048576 ]]; then
			out_status=$(printf '%sM\n' "`echo "scale=1; $tx_kib / 1024" | bc`")
		else
			out_status="${tx_kib}K"
		fi

		bw_status="$INLABEL $in_status, $OUTLABEL $out_status"
	fi

	# Final output
	#echo -n ",["
	#echo -n "{ \"full_text\": \"[$volume_status]\", \"name\" : \"volume\"},"
	#echo -n "{ \"full_text\": \"[$bw_status, $wlan_status, $eth_status]\", \"name\" : \"network\"},"
	#echo -n "{ \"full_text\": \"[$ram_status]\", \"name\": \"memory\", \"color\": \"$ram_color\"},"
	#echo -n "{ \"full_text\": \"[$battery_status]\", \"name\" : \"battery\", \"color\":\"$bat_color\"},"
	#echo -n "{ \"full_text\": \"[$time_status]\", \"name\" : \"time\"}"
	#echo "]"

	echo "\"\[$volume_status\] \[$bw_status, $wlan_status, $eth_status\] \[$ram_status\] \[$battery_status\] \[$time_status\]\""

	sleep 1
done

echo "]"
