#!/bin/bash
#
############################################################################
#
# gdowngrade.sh
#
############################################################################
#
# Author: Videonauth
# Date: 04.05.2016
# Purpose:
#     Script for downgrading gedit
#     from version 3.18.3 (ubuntu 16.04 LTS version)
#     to version 3.10.4 (ubuntu 15.10 version)
# Written for: http://askubuntu.com/a/766056/522934
# Tested on: Ubuntu 16.04 LTS
#
############################################################################
#
# Copyright: Videonauth , 2016
#
#     Permission to use, copy, modify, and distribute this
#     software is hereby granted without fee, provided that
#     the copyright notice above and this permission statement
#     appear in all copies.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
#     ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
#     TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
#     PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#     THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
#     DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
#     CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#     CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#     IN THE SOFTWARE.
#
############################################################################
#
#    Changelog:
#        - 04.05.2016 <--> rev 0.00.01 
#                Initial script release
#
#        - 05.05.2016 <--> rev 0.00.02
#                Added language settings for subshell
#                Added confirmation of already installed dependencies
#                Added output for generating gupgrade.sh
#                Changed genration of temp directory
#
############################################################################

#setting language variables for subshell
LC_ALL=C
LANG=C

# creating a variable for the path the script is in
pushd "$(dirname "$0")" > /dev/null
SCRIPTPATH="$(pwd)"
popd > /dev/null

# making a copy of the users original sources.list file
cp -v /etc/apt/sources.list /etc/apt/sources.list.orig &&

# writing a custom sources.list file
cat > /etc/apt/sources.list << "EOF"
deb-src http://archive.ubuntu.com/ubuntu xenial main restricted
deb http://de.archive.ubuntu.com/ubuntu/ xenial main restricted
deb-src http://de.archive.ubuntu.com/ubuntu/ xenial multiverse main universe restricted
deb http://de.archive.ubuntu.com/ubuntu/ xenial-updates main restricted
deb-src http://de.archive.ubuntu.com/ubuntu/ xenial-updates multiverse main universe restricted
deb http://de.archive.ubuntu.com/ubuntu/ xenial universe
deb http://de.archive.ubuntu.com/ubuntu/ xenial-updates universe
deb http://de.archive.ubuntu.com/ubuntu/ xenial multiverse
deb http://de.archive.ubuntu.com/ubuntu/ xenial-updates multiverse
deb http://de.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://de.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu xenial partner
deb-src http://archive.canonical.com/ubuntu xenial partner
deb http://security.ubuntu.com/ubuntu xenial-security main restricted
deb-src http://security.ubuntu.com/ubuntu xenial-security multiverse main universe restricted
deb http://security.ubuntu.com/ubuntu xenial-security universe
deb http://security.ubuntu.com/ubuntu xenial-security multiverse
EOF

# running an update
apt-get update &&
apt-get -y dist-upgrade &&

# making a directory in /tmp/ to work in
temp="$(mktemp -d)"
cd "$temp"

# testing and installing dependencies and tools if not already there
if [ "$(apt-get build-dep -s gedit gedit-plugins | grep "Inst")" != "" ]
then
	echo "Installing build dependencies ..."
	apt-get build-dep -y gedit gedit-plugins &&
	echo "Installation of build dependencies done ..."
else
	echo "Build dependencies already installed ..."
fi

#if [ "$(apt-cache policy moreutils | grep Installed)" != "  Installed: 0.57-1" ]
if [ "$(dpkg-query -f '${binary:package} ${version}\n' -W | awk '$1=="moreutils" {print $2}')" != "0.57-1" ]
then
	echo "Installing moreutils ..."
	apt-get install -y moreutils &&
	echo "Installation of moreutils done ..."
else
	echo "moreutils already installed ..."
fi

# determining if gedit 3.18.3 is installed and needs to be uninstalled
#if [ "$(apt-cache policy gedit | grep Installed)" == "  Installed: 3.18.3-0ubuntu4" ]
if [ "$(dpkg-query -f '${binary:package} ${version}\n' -W | awk '$1=="gedit" {print $2}')" == "3.18.3-0ubuntu4" ]
then
	echo "Removing Gedit 3.18.3 ..."
	apt-get remove -y gedit-dev gedit gedit-common &&
	echo "Removal of Gedit 3.18.3 done ..."
fi

# writing wget-list
cat > wget-list << "EOF"
http://mirrors.kernel.org/ubuntu/pool/main/g/gedit/gedit-common_3.10.4-0ubuntu13_all.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/gedit/gedit_3.10.4-0ubuntu13_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/gedit/gedit-dev_3.10.4-0ubuntu13_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/universe/g/gedit-developer-plugins/gedit-developer-plugins_0.5.15-0ubuntu1_all.deb
http://mirrors.kernel.org/ubuntu/pool/universe/g/gedit-latex-plugin/gedit-latex-plugin_3.8.0-3build1_all.deb
http://mirrors.kernel.org/ubuntu/pool/universe/g/gedit-plugins/gedit-plugins_3.10.1-1ubuntu3_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/universe/g/gedit-r-plugin/gedit-r-plugin_0.8.0.2-Gtk3-Python3-1ubuntu1_all.deb
http://mirrors.kernel.org/ubuntu/pool/universe/g/gedit-source-code-browser-plugin/gedit-source-code-browser-plugin_3.0.3-3_all.deb
http://mirrors.kernel.org/ubuntu/pool/universe/g/gedit-valencia-plugin/gedit-valencia-plugin_0.8.0-0ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/universe/r/rabbitvcs/rabbitvcs-gedit_0.16-1_all.deb
http://mirrors.kernel.org/ubuntu/pool/universe/s/supercollider/supercollider-gedit_3.6.6~repack-2-1build1_all.deb
EOF

# downloading packages
echo "Downloading packages ..."
wget -i wget-list &&
echo "Download of packages done ..."

# installing the basics
# install gedit-common
dpkg -i gedit-common_3.10.4-0ubuntu13_all.deb &&

# install gedit
dpkg -i gedit_3.10.4-0ubuntu13_amd64.deb &&

# install gedit-dev
dpkg -i gedit-dev_3.10.4-0ubuntu13_amd64.deb  &&

# install gedit-plugins
	# unpacking the .deb file
	dpkg-deb -R gedit-plugins_3.10.1-1ubuntu3_amd64.deb tmp &&

	# editing tmp/DEBIAN/control:
	# change 'python3 (<< 3.5), python3 (>= 3.4~), python3.4' to 'python3 (>= 3.5~), python3.5'
	sed 's/python3 (<< 3\.5), python3 (>= 3\.4~), python3\.4/python3 (>= 3.5~), python3.5/' tmp/DEBIAN/control | sponge tmp/DEBIAN/control &&

	# editing tmp/DEBIAN/postinst
	# change 'py3compile -p gedit-plugins /usr/lib/x86_64-linux-gnu/gedit/plugins -V 3.4' to
	# 'py3compile -p gedit-plugins /usr/lib/x86_64-linux-gnu/gedit/plugins -V 3.5'
	sed 's/3\.4/3.5/' tmp/DEBIAN/postinst | sponge tmp/DEBIAN/postinst &&

	# packing a new .deb file
	dpkg-deb -b tmp gedit-plugins_3.10.1-1ubuntu4_amd64.deb &&

	# removing tmp
	rm -rfv tmp &&

	# installing it
	dpkg -i gedit-plugins_3.10.1-1ubuntu4_amd64.deb &&

hold="gedit-common gedit gedit-dev gedit-plugins "

# begin determining which extra packages to install for the user

echo
echo "Do you want to install the 'gedit-developer-plugins' package (y/n)?"
read -n 1 answer
echo
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]
then
	# install gedit-developer-plugins
	if [ "$(dpkg-query -f '${binary:package} ${version}\n' -W | awk '$1=="python-pocket-lint" {print $2}')" != "0.5.31-0ubuntu1" ]
	then
		echo "Installing 'phyton-pocket-lint' ..."
		sudo apt-get -y install python-pocket-lint &&
		echo "Installation of 'phyton-pocket-lint' done ..."
	fi
	sudo dpkg -i gedit-developer-plugins_0.5.15-0ubuntu1_all.deb &&
	echo "Installed 'gedit-developer-plugins' ..."
	hold=$hold"gedit-developer-plugins "
fi

echo
echo "Do you want to install the 'gedit-latex-plugin' package (y/n)?"
read -n 1 answer
echo
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]
then
	# install gedit-latex-plugin
	if [ "$(dpkg-query -f '${binary:package} ${version}\n' -W | awk '$1=="rubber" {print $2}')" != "1.4-2" ]
	then
		echo "Installing 'rubber' ..."
		sudo apt-get -y install rubber &&
		echo "Installation of 'rubber' done ..."
	fi
	sudo dpkg -i gedit-latex-plugin_3.8.0-3build1_all.deb &&
	echo "Installed 'gedit-latex-plugin' ..."
	hold=$hold"gedit-latex-plugin "
fi

echo
echo "Do you want to install the 'gedit-r-plugin' package (y/n)?"
read -n 1 answer
echo
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]
then
	# install gedit-r-plugin
	sudo dpkg -i gedit-r-plugin_0.8.0.2-Gtk3-Python3-1ubuntu1_all.deb  &&
	echo "Installed 'gedit-r-plugin' ..."
	hold=$hold"gedit-r-plugin "
fi

echo
echo "Do you want to install the 'gedit-source-code-browser-plugin' package (y/n)?"
read -n 1 answer
echo
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]
then
	# install gedit-source-code-browser-plugin
	if [ "$(dpkg-query -f '${binary:package} ${version}\n' -W | awk '$1=="exuberant-ctags" {print $2}')" != "1:5.9~svn20110310-11" ]
	then
		echo "Installing 'ctags' ..."
		sudo apt-get -y install ctags &&
		echo "Installation of 'ctags' done ..."
	fi
	sudo dpkg -i gedit-source-code-browser-plugin_3.0.3-3_all.deb &&
	echo "Installed 'gedit-source-code-browser-plugin' ..."
	hold=$hold"gedit-source-code-browser-plugin "
fi

echo
echo "Do you want to install the 'gedit-valencia-plugin' package (y/n)?"
read -n 1 answer
echo
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]
then
# install gedit-valencia-plugin
	# unpacking .deb file
	sudo dpkg-deb -R gedit-valencia-plugin_0.8.0-0ubuntu2_amd64.deb tmp &&

	# edit tmp/DEBIAN/control
	# change 'libvala-0.28-0 (>= 0.15.1)' to 'libvala-0.30-0 (>= 0.15.1)'
	# change 'libvte-2.90-9 (>= 1:0.27.2)' to 'libvte-2.91-0 (>= 0.27.2)'
	sed -e 's/libvala-0\.28-0 (>= 0\.15\.1)/libvala-0.30-0 (>= 0.15.1)/' -e 's/libvte-2\.90-9 (>= 1:0\.27\.2)/libvte-2.91-0 (>= 0.27.2)/' tmp/DEBIAN/control | sponge tmp/DEBIAN/control &&

	# packing a new .deb file
	sudo dpkg-deb -b tmp gedit-valencia-plugin_0.8.0-0ubuntu3_amd64.deb &&

	# removing tmp
	sudo rm -rfv tmp &&

	# installing it
	sudo dpkg -i gedit-valencia-plugin_0.8.0-0ubuntu3_amd64.deb &&
	echo "Installed 'gedit-valencia-plugin' ..."
	hold=$hold"gedit-valencia-plugin "
fi

echo
echo "Do you want to install the 'rabbitvcs-gedit' package (y/n)?"
read -n 1 answer
echo
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]
then
	# install rabbitvcs-gedit
	if [ "$(dpkg-query -f '${binary:package} ${version}\n' -W | awk '$1=="rabbitvcs-core" {print $2}')" != "0.16-1" ]
	then
		echo "Installing 'rabbitvcs-core' ..."
		sudo apt-get -y install rabbitvcs-core &&
		echo "Installation of 'rabbitvcs-core' done ..."
	fi
	sudo dpkg -i rabbitvcs-gedit_0.16-1_all.deb &&
	echo "Installed 'rabbitvcs-gedit' ..."
	hold=$hold"rabbitvcs-gedit "
fi

echo
echo "Do you want to install the 'supercollider-gedit' package (y/n)?"
read -n 1 answer
echo
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]
then
	# install supercollider-gedit
	if [ "$(dpkg-query -f '${binary:package} ${version}\n' -W | awk '$1=="supercollider-language" {print $2}')" != "1:3.6.6~repack-2-2" ]
	then
		echo "Installing 'supercollider-language' ..."
		sudo apt-get -y install supercollider-language &&
		echo "Installation of 'supercollider-language' done ..."
	fi
	sudo dpkg -i supercollider-gedit_3.6.6~repack-2-1build1_all.deb &&
	echo "Installed 'supercollider-gedit' ..."
	hold=$hold"supercollider-gedit "
fi

# now protecting this all from upgrading
apt-mark hold $hold &&

# removing a maybe previous existing gupgrade.sh
if [ -e "$SCRIPTPATH"/gupgrade.sh ]
then
	rm -rfv "$SCRIPTPATH"/gupgrade.sh
fi

# creating gupgrade.sh
touch "$SCRIPTPATH"/gupgrade.sh &&
echo "apt-mark unhold $hold &&" >> "$SCRIPTPATH"/gupgrade.sh
if [ "$(grep "supercollider-gedit" <<<"$hold")" != "" ]
then
	echo "dpkg -r supercollider-gedit &&" >> "$SCRIPTPATH"/gupgrade.sh
fi
if [ "$(grep "rabbitvcs-gedit" <<<"$hold")" != "" ]
then
	echo "dpkg -r rabbitvcs-gedit &&" >> "$SCRIPTPATH"/gupgrade.sh
fi
if [ "$(grep "gedit-valencia-plugin" <<<"$hold")" != "" ]
then
	echo "dpkg -r gedit-valencia-plugin &&" >> "$SCRIPTPATH"/gupgrade.sh
fi
if [ "$(grep "gedit-source-code-browser-plugin" <<<"$hold")" != "" ]
then
	echo "dpkg -r gedit-source-code-browser-plugin &&" >> "$SCRIPTPATH"/gupgrade.sh
fi
if [ "$(grep "gedit-r-plugin" <<<"$hold")" != "" ]
then
	echo "dpkg -r gedit-r-plugin &&" >> "$SCRIPTPATH"/gupgrade.sh
fi
if [ "$(grep "gedit-latex-plugin" <<<"$hold")" != "" ]
then
	echo "dpkg -r gedit-latex-plugin &&" >> "$SCRIPTPATH"/gupgrade.sh
fi
if [ "$(grep "gedit-developer-plugins" <<<"$hold")" != "" ]
then
	echo "dpkg -r gedit-developer-plugins &&" >> "$SCRIPTPATH"/gupgrade.sh
fi
echo -e "apt-get update &&\napt-get -y dist-upgrade" >> "$SCRIPTPATH"/gupgrade.sh

# setting executable permissions on gupgrade.sh
chmod -v 755 "$SCRIPTPATH"/gupgrade.sh

#giving the SUDO_USER ownership
chown -v "$SUDO_USER":"$SUDO_USER" "$SCRIPTPATH"/gupgrade.sh

# cleaning up
rm -rfv "$temp" &&

# putting back the original sources.list
mv -v /etc/apt/sources.list /etc/apt/sources.list.gdowngrade &&
cp -v /etc/apt/sources.list.orig /etc/apt/sources.list &&

# removing backup files
rm -rfv /etc/apt/sources.list.gdowngrade &&
rm -rfv /etc/apt/sources.list.orig
