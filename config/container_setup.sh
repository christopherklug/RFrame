#!/bin/bash

### DONT EXECUTE THIS ON YOUR HOST ###

function info() {
	i="${1:-$(</dev/stdin)}"
	LOG_INFO='\033[1;33m'
	if [[ $(echo -n "$i" | wc -m) -gt 0 ]]; then
		echo -e "\033[2K${LOG_INFO}[[ $i ]]\e[0m "
	fi
}

function info_inline() {
	i="${1:-$(</dev/stdin)}"
	LOG_INFO='\033[1;33m'
	if [[ $(echo -n "$i" | wc -m) -gt 0 ]]; then
		echo -en "\r\033[2K${LOG_INFO}[[ $i ]]\e[0m"
	fi
}

function err() {
	i="${1:-$(</dev/stdin)}"
	LOG_ERR='\033[1m\033[31m'
	if [[ $(echo -n "$i" | wc -m) -gt 0 ]]; then
		echo -e "\r\033[2K${LOG_ERR}{{ $i }}\e[0m" >&2
	fi
}

function suc() {
	i="${1:-$(</dev/stdin)}"
	LOG_SUC='\033[32m'
	if [[ $(echo -n "$i" | wc -m) -gt 0 ]]; then
		echo -e "\r\033[2K${LOG_SUC}[[ $i ]]\e[0m"
	fi
}

export DIALOGRC="/config/.dialogrc"
#exec 3>/dev/null # quiet
exec 3>&1

info_inline "waiting for network connection ..."

while true; do
	if [[ $(curl -s christopherklug.de | wc -l) -gt 0 ]]; then
		sleep 1
		break
	fi
	sleep 1
done

suc "waiting for network connection [\\u2713]"

export DEBIAN_FRONTEND="noninteractive" TZ="Europe/Berlin"

info_inline "upgrading system ..."

apt-get >&3 -qq update && apt-get >&3 upgrade -qy

suc "upgrading system [\\u2713]"

info_inline "installing common packages ..."

apt-get >&3 -qq update && apt-get >&3 install -qy dialog git make gcc vim build-essential swig cmake python3 python3-pip gedit firefox wget
apt-get >&3 install -qy apt-transport-https ca-certificates curl gnupg2 software-properties-common

suc "installing common packages [\\u2713]"

info_inline "setting up connectivity ..."

touch /root/.Xauthority
apt-get >&3 install -qy xauth xterm openssh-server ufw
gw=$(ip route show | grep default | awk '{print $3}')
{ 	echo -e "Match Address $gw";
	echo -e "\t PermitRootLogin yes";
	echo -e "\t PasswordAuthentication yes";
	echo -e "\t X11Forwarding yes"; } >>/etc/ssh/sshd_config
echo "export LIBGL_ALWAYS_INDIRECT=1" >>~/.bashrc
systemctl >&3 restart sshd

sysctl >&3 -w net.ipv6.conf.all.disable_ipv6=1
sysctl >&3 -w net.ipv6.conf.default.disable_ipv6=1

echo "$(sed 's/IPV6=yes/IPV6=no/g' /etc/default/ufw)" > /etc/default/ufw

ufw >&3 allow ssh
ufw >&3 \enable
ufw >&3 reload



if dialog --stdout --keep-tite --backtitle RFrame --yesno "Do you want to use an graphical interface (vnc) to attach to the container?" 6 80; then
	apt-get >&3 install -qy xorg lxde-core tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer
	mkdir -p ~/.vnc
	echo "#!/bin/sh" >~/.vnc/xstartup
	echo "/etc/X11/xinit/xinitrc & /etc/X11/Xsession & lxterm & /usr/bin/lxsession -s LXDE &" >>~/.vnc/xstartup
	chmod 755 ~/.vnc/xstartup
	echo "${RANDOM}" | vncpasswd -f >~/.vnc/passwd
	chmod 600 ~/.vnc/passwd
fi

(
	echo "rframe"
	echo "rframe"
) | sudo passwd root 2>&3 >&3

ln -s /shared ~/shared

suc "setting up connectivity [\\u2713]"

info_inline "installing additional software ..."

add-apt-repository >&3 -y ppa:myriadrf/drivers && apt-get >&3 -qq update

additional_software=("GNU Radio" "Universal Radio Hacker (URH)" "rtl_433" "inspectrum")
_additional_software=""
dialog='dialog --stdout --keep-tite --backtitle RFrame --checklist "Please choose additional software, which you want to install:" 0 0 0'

for ((i = 0; i < ${#additional_software[@]}; i++)); do
	_additional_software+="$i \"$(echo -e "${additional_software[$i]}")\" off "
done

eval chosen_additional_software="\$(${dialog} ${_additional_software})"

for i in ${chosen_additional_software[@]}; do
	case $i in
	0)
		add-apt-repository >&3 -y ppa:myriadrf/gnuradio && apt-get >&3 -qq update
		apt-get >&3 install -qy gnuradio
		apt-get >&3 install -qy gr-limesdr gr-iqbal gr-osmosdr

		/config/scripts/pythonpath-fix.sh >&3
		/config/scripts/gr-correctiq >&3
		;;
	1)
		pip3 >&3 install urh
		;;
	2)
		apt-get >&3 install -qy rtl-433
		;;
	3)
		apt-get >&3 install -qy inspectrum
		;;
	*) ;;

	esac
done

#fix for current armhf ubuntu image (state 03/01/2021)
if [[ "$(arch | grep -io arm)" == "arm" ]]; then
	rm >&3 -rf "/var/lib/dpkg/info/libfprint-2-2:armhf.postinst"
	dpkg >&3 --configure libfprint-2-2:armhf
fi

suc "installing additional software [\\u2713]"

info_inline "installing sdr specific software ..."

sdr_software=("LimeSDR" "RTL-SDR" "bladeRF" "HackRF" "Ubertooth" "OsmoSDR")
_sdr_software=""
dialog='dialog --stdout --keep-tite --backtitle RFrame --checklist "Please choose additional software, which you want to install:" 0 0 0'

for ((i = 0; i < ${#sdr_software[@]}; i++)); do
	_sdr_software+="$i \"$(echo -e "${sdr_software[$i]}")\" off "
done

eval chosen_sdr_software="\$(${dialog} ${_sdr_software})"

for i in ${chosen_sdr_software[@]}; do
	case $i in
	0)
		add-apt-repository >&3 -y ppa:myriadrf/drivers && apt-get >&3 -qq update
		apt-get >&3 install -qy limesuite liblimesuite-dev limesuite-udev limesuite-images
		;;
	1)
		apt-get >&3 install -qy rtl-sdr
		;;
	2)
		apt-get >&3 install -qy bladerf
		;;
	3)
		apt-get >&3 install -qy hackrf
		;;
	4)
		apt-get >&3 install -qy ubertooth
		;;
	5)
		apt-get >&3 install -qy osmo-sdr
		;;
	*) ;;

	esac
done

suc "installing sdr specific software [\\u2713]"

info "Please set a password for your new container:"
passwd root || exit 0
