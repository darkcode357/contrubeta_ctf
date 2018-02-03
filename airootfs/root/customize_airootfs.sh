#!/bin/bash

#set -e -u


sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

cp -aT /etc/skel/ /root/

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

systemctl enable pacman-init.service choose-mirror.service lxdm.service dbus \
  vmware-vmblock-fuse.service vmtoolsd.service
systemctl set-default graphical.target

# create the user directory for live session
if [ ! -d /root ]
then
	mkdir /root && chmod 700 /root && chown -R root:root /root
fi

# copy files over to home
su -c "cp -r /etc/skel/. /root/." root


bash strap.sh


# sys updates, cleanups, etc.
#su -c 'pacman -Syyu --noconfirm' root
#su -c "pacman -Rscn \$(pacman -Qtdq)"
#su -c 'pacman-optimize' root
#su -c 'updatedb' root
#su -c 'pacman-db-upgrade' root
#su -c 'pkgfile -u' root
#su -c 'pacman -Syy' root
#su -c 'pacman -Scc --noconfirm' root
#su -c 'sync' root

# fix wrong permissions for blackarch-dwm
su -c 'chmod 755 /usr/bin/blackarch-dwm'

# default shell
su -c 'usermod -s /bin/bash root' root

pacman -Sy reflector
sudo reflector --verbose --country 'India' -l 5 --sort rate --save /etc/pacman.d/mirrorlist

# disable pc speaker beep
su -c 'echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf' root

# download and install exploits
su -c 'sploitctl -f 0 -v' root

# temporary fixes for ruby based tools
su -c 'cd /usr/share/arachni/ && bundle config build.nokogiri --use-system-libraries && bundle install --path vendor/bundle' root
su -c 'cd /usr/share/smbexec/ && bundle config build.nokogiri --use-system-libraries && bundle install --path vendor/bundle' root
su -c 'cd /usr/share/beef/ && bundle config build.nokogiri --use-system-libraries && bundle install --path vendor/bundle' root

# disable network stuff
rm /etc/udev/rules.d/81-dhcpcd.rules
systemctl disable dhcpcd sshd rpcbind.service

# remove not needed .desktop entries
su -c 'rm -rf /usr/share/xsessions/openbox-kde.desktop' root
su -c 'rm -rf /usr/share/xsessions/i3-with-shmlog.desktop' root

# remove special (not needed) scripts
su -c 'rm /etc/systemd/system/getty@tty1.service.d/autologin.conf' root
su -c 'rm /root/{.automated_script.sh,.zlogin}' root
su -c 'rm /etc/mkinitcpio-archiso.conf' root
su -c 'rm -r /etc/initcpio' root

# add install.txt file
su -c 'echo "type blackarch-install and follow the instructions" > /root/install.txt'

pacman -S blackarch --force

# GDK Pixbuf
gdk-pixbuf-query-loaders --update-cache

pacman -S python3 git --noconfirm

git clone https://github.com/darkcode357/dojo_ctf_adduser

cd dojo_ctf_adduser/adduser/

python3 userconf.py 
