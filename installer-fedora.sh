#!/bin/bash

# Caution! I have only tested this script on Fedora 32.
# This script will install Cisco Packettracer 7.3.1 in your /opt directory.
# Idea to make this script from https://ask.fedoraproject.org/t/how-to-install-new-cisco-packet-tracer-7-3-on-fedora-31-workstation/6047/8

# Welcome message
echo '
##################################################
#                                                #
#  Welcome to PacketTracer 7.3 Fedora Installer  #
#                                                #
##################################################
'
sleep 2

# Do not run as root
if [ "$EUID" -ne 1000 ]; then
    echo ""
    echo "This script must be ran as a regular user, NOT root."
    echo ""
    exit 1
fi

# Check for and require Fedora
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unable to detect operating system."
    exit 1
fi
if [ "$OS" != "rhel" ] && [ "$OS" != "fedora" ] && [ "$OS" != "centos" ]; then
    echo "You must be on a RHEL based operating system to use this."
    exit 1
fi

# Check the user is sure about installation
echo ""
echo "Things to be aware of: "
echo ""
echo "This script has only been tested on Fedora 32. "
echo ""
echo "If you have an old install of packettracer it will be removed permanantly! "
echo ""
echo "This script will update your system. "
echo ""
echo "ALWAYS back up your system before making changes! "
echo ""
sleep 1
read -p "Are you sure you want to allow this script to make changes to your computer? y/N: " ANSWER
case "$ANSWER" in
    [yY] | [yY][eE][sS])
        echo "YAY!"
        echo ""
        ;;
    [nN] | [nN][oO])
        echo ""
        echo "Cancelling installation... "
        echo ""
        sleep 2
        exit 1
        ;;
    *)
        echo ""
        echo "Cancelling installation... "
        echo ""
        sleep 2
        exit 1
    ;;
esac

# Ask if the user is signed up for Netacad
read -p "Have you signed up for a Packet Tracer account at netacad.com? Y/n: " ANSWER
case "$ANSWER" in
    [yY] | [yY][eE][sS])
        echo "Good, you may continue."
        ;;
    [nN] | [nN][oO])
        echo ""
        echo "Please sign up for an account at www.netacad.com "
        sleep 1
        echo ""
        echo "After signup, please download the .deb installer to your Downloads directory and run this again. "
        sleep 4
        echo ""
        firefox www.netacad.com/courses/packet-tracer
        firefox www.netacad.com
        sleep 2
        exit 1
        ;;
    *)
        echo "Please answer yes or no. "
        exit 1
    ;;
esac

# Check for PacketTracer_731_amd64.deb file in user's Downloads directory
cd ~/Downloads
FILE="PacketTracer_731_amd64.deb"
if [ -e "$FILE" ]
then
    echo "$FILE exists. "
    sleep 1
else
    echo "$FILE does NOT exist. "
    echo "Please place your packettracer file on your Downloads directory!"
    sleep 5
    exit 1
fi

# Update the system
sudo yum update -y

# Make sure dependencies are installed
sudo yum install make cmake wget git -y

# Remove old Packettracer
sudo rm -rf /opt/pt
sudo rm -rf /usr/share/applications/cisco-pt7.desktop
sudo rm -rf /usr/share/applications/cisco-ptsa7.desktop
sudo rm -rf /usr/share/icons/hicolor/48x48/apps/pt7.png

# Make setup directory (can be deleted later)
cd ~/
mkdir -p tmp1/pt731/

# Copy PT files
cd ~/tmp1/pt731/
cp ~/Downloads/PacketTracer_731_amd64.deb ~/tmp1/pt731/

# Extract the deb file
cd ~/tmp1/pt731/
ar -xv PacketTracer_731_amd64.deb
mkdir ~/tmp1/pt731/control/
tar -C control -Jxf control.tar.xz
mkdir ~/tmp1/pt731/data/
tar -C data -Jxf data.tar.xz

# Copy PacketTracer files to install it
cd ~/tmp1/pt731/data/
sudo cp -r usr /
sudo cp -r opt /

# Configure Gnome environment
sudo xdg-desktop-menu install /usr/share/applications/cisco-pt7.desktop
sudo xdg-desktop-menu install /usr/share/applications/cisco-ptsa7.desktop
sudo update-mime-database /usr/share/mime
sudo gtk-update-icon-cache --force --ignore-theme-index /usr/share/icons/gnome
sudo xdg-mime default cisco-ptsa7.desktop x-scheme-handler/pttp
sudo ln -sf /opt/pt/packettracer /usr/local/bin/packettracer

# We have a problem with libjpeg.so.8. So, we’re going to compile a version of this library with the right option
cd ~/tmp1/
mkdir ~/tmp1/libjpeg/
cd ~/tmp1/libjpeg/
git clone https://github.com/libjpeg-turbo/libjpeg-turbo ./
mkdir ./build
cmake -DWITH_JPEG8=1 -B ./build/
cd build/
make
sudo cp ~/tmp1/libjpeg/build/libjpeg.so.8.2.2 /opt/pt/bin
sudo ln -s /opt/pt/bin/libjpeg.so.8.2.2 /opt/pt/bin/libjpeg.so.8
sleep 2

# Remove orphan packages
sudo dnf autoremove -y

# Check for successful install
cd /opt/pt/bin/
FILE="Cisco-PacketTracer.desktop"
if [ -e "$FILE" ]
then
    echo ""
    echo "Cisco Packet Tracer was installed successfully! "
    echo ""
    sleep 1
else
    echo ""
    echo "Packet Tracer did not seem to install correctly :( "
    echo ""
    sleep 1
fi

# Ask user if they want to run Packet Tracer
read -p "Do you want to try and launch Packet Tracer now? Y/n: " ANSWER
case "$ANSWER" in
    [yY] | [yY][eE][sS])
        /opt/pt/packettracer %f
        ;;
    [nN] | [nN][oO])
        echo ""
        ;;
    *)
        /opt/pt/packettracer %f   
    ;;
esac

# Ask user if they want to reboot
echo ""
read -p "Would you like to reboot your computer now? y/N: " ANSWER
echo ""
case "$ANSWER" in
    [yY] | [yY][eE][sS])
        sleep 3
        sudo reboot
        ;;
    [nN] | [nN][oO])
        echo ""
        echo "Remember to reboot later. "
        echo ""
        ;;
    *)     
        echo ""       
        echo "Remember to reboot later. "   
        echo ""
    ;;
esac
