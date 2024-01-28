#!/bin/bash
# customize install

update_configuration_files() {
	echo "Log: (chroot): running update_configuration_files"
	if [ -f /etc/nanorc ]; then
		echo "Log: (chroot): updating nanorc"
		sed -i "s|# set tabsize 8|set tabsize 4|" /etc/nanorc
	fi
	if [ -f /etc/ssh/sshd_config ]; then
		echo "Log: (chroot): update sshd_config"
		sed -i "s|#Port 22|Port 2222|" /etc/ssh/sshd_config
		sed -i "s|#PubkeyAuthentication|PubkeyAuthentication|" /etc/ssh/sshd_config
		sed -i "s|#AuthorizedKeysFile|AuthorizedKeysFile|" /etc/ssh/sshd_config
	fi
}

update_samba_configuration_file() {
	if [ -f /etc/samba/smb.conf ]; then
		echo "Log: (chroot): update samba shares"
		# add to samba
		echo "# netbios name so it appears in host name" >> /etc/samba/smb.conf
		echo "netbios name =  ${rfs_hostname}" >> /etc/samba/smb.conf
		echo " " >> /etc/samba/smb.conf
		echo " " >> /etc/samba/smb.conf
		echo "# remote shares" >> /etc/samba/smb.conf
		echo "[${rfs_hostname}]" >> /etc/samba/smb.conf
		echo "  comment=${rfs_hostname}" >> /etc/samba/smb.conf
		echo "  path=/" >> /etc/samba/smb.conf
		echo "  browseable=yes" >> /etc/samba/smb.conf
		echo "  guest ok=yes" >> /etc/samba/smb.conf
		echo "  read only=no" >> /etc/samba/smb.conf
		echo "  create mask=0755" >> /etc/samba/smb.conf
		echo "  directory mask=0755" >> /etc/samba/smb.conf
		echo " " >> /etc/samba/smb.conf
		echo "[shared]" >> /etc/samba/smb.conf
		echo "  comment=Shared" >> /etc/samba/smb.conf
		echo "  path=/home/shared" >> /etc/samba/smb.conf
		echo "  browseable=yes" >> /etc/samba/smb.conf
		echo "  guest ok=yes" >> /etc/samba/smb.conf
		echo "  read only=no" >> /etc/samba/smb.conf
		echo "  create mask=0777" >> /etc/samba/smb.conf
		echo "  directory mask=0777" >> /etc/samba/smb.conf
	fi		
}

create_shared_directories(){
	echo "Log: (chroot): create_shared_directories"
	mkdir -p /home/shared
    mkdir -p /home/shared/backup
    mkdir -p /mnt/linux
    mkdir -p /mnt/scripts

    # set permissions
    chmod -R 777 /home/shared
    chown -R nobody:nogroup /home/shared
    chmod -R 777 /mnt/linux
    chown -R nobody:nogroup /mnt/linux
    chmod -R 777 /mnt/scripts
    chown -R nobody:nogroup /mnt/scripts

    if [ -f /home/${rfs_username} ]; then
	    mkdir -p /home/${rfs_username}/projects/beaglebone
	fi
}

download_files() {
	echo "Log: (chroot): download_files"
	if [ -e /home/${rfs_username}/.ssh ]; then
        echo "Log: (chroot): downloading authorized keys to .ssh and setting permissions"
		# download keys
		wget -P /home/${rfs_username}/.ssh http://192.168.1.25/downloads/files/authorized_keys
		# set permissions to activate ssh keys
		chmod 600 /home/${rfs_username}/.ssh/authorized_keys
		chmod 700 /home/${rfs_username}/.ssh
		chown -R ${rfs_username}:${rfs_username} /home/${rfs_username}/.ssh
	else
		echo "Log: (chroot): downloading authorized keys to shared folder"
		wget -P /home/shared http://192.168.1.25/downloads/files/authorized_keys
	fi
	echo "Log: (chroot): downloading credentials to /etc for remote sharing"
	wget -P /etc http://192.168.1.25/downloads/files/cred-andromeda
	wget -P /etc http://192.168.1.25/downloads/files/cred-ildico
	echo "Log: (chroot): downloading .mount files to systemd"
	wget -P /etc/systemd/system/ http://192.168.1.25/downloads/files/mnt-linux.mount
	wget -P /etc/systemd/system/ http://192.168.1.25/downloads/files/mnt-scripts.mount
}

enable_system_mount() {
	echo "Log: (chroot): enable_system_mount"
	if [ -f /etc/systemd/system/mnt-linux.mount ]; then
		echo "Log: (chroot): enabling linux folder mounting service."
		systemctl enable mnt-linux.mount || true
	fi
	if [ -f /etc/systemd/system/mnt-scripts.mount ]; then
		echo "Log: (chroot): enabling and starting script mounting service."
		systemctl enable mnt-scripts.mount || true
	fi
}

download_script_repo() {
	echo "Log: (chroot): download_script_repo"
	if [ -e /mnt/scripts/general ]; then
		echo "Log: (chroot): [cp /mnt/scripts/general/* /usr/local/bin/]"
		cp /mnt/scripts/general/* /usr/local/bin/
        if [ -e /usr/local/bin/ssh_welcome ]; then
            echo "Log: (chroot): scripts added successfully"
            chown -R  ${rfs_username}:${rfs_username} /usr/local/bin/
            chmod -R 777 /usr/local/bin/
            echo "Log: (chroot): copy ssh_welcome to /etc/profile"
            echo "# ssh welcome banner" >> /etc/profile
            echo "ssh_welcome" >> /etc/profile
        else
            echo "Log: (chroot): scripts did not copy successfully"
        fi
    else
        echo "Log: (chroot): script repo was not available"
	fi
}

# run
update_configuration_files
update_samba_configuration_file
create_shared_directories
if ping -c 1 192.168.1.25 &> /dev/null; then
	download_files
	enable_system_mount
	download_script_repo
fi	
