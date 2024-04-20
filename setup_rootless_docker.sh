#!/bin/bash
#https://du.nkel.dev/blog/2023-12-12_mastodon-docker-rootless/#docker-rootless-setup
#The following is a note from the docs with additional information.
#The location of systemd configuration files are different when running Docker in rootless mode. When running in rootless mode, Docker is started as a user-mode systemd service, and uses files stored in each users' home directory in ~/.config/systemd/user/docker.service.d/. In addition, systemctl must be executed without sudo and with the --user flag.

user=docker_keycloak

# Help: https://linuxhandbook.com/rootless-docker/
sudo apt update
sudo apt install dbus-user-session fuse-overlayfs uidmap

# Install apt-add-repo utility
sudo wget -qO /usr/bin/apt-add-repo https://raw.githubusercontent.com/devd4n/apt-add-repo/main/apt-add-repo.sh
sudo chmod +x /usr/bin/apt-add-repo

# Add Repo to trusted Repos / Repos Sources
apt-add-repo docker-ce https://download.docker.com/linux/ubuntu https://download.docker.com/linux/ubuntu/gpg $(lsb_release -cs) stable
sudo apt install docker-ce docker-ce-cli containerd.io docker-ce-rootless-extras -y

# for machinectl command used later
sudo apt install systemd-container -y

# Disable Docker Service as root user
sudo systemctl disable --now docker.service docker.socket

sudo useradd -r -s /bin/bash -m -d /srv/$user -U $user

# su $user
#cat /etc/subuid
#    opc:100000:65536
#    ubuntu:165536:65536

#I already have two users here (you may spot that this is from the Oracle cloud).

#The syntax is <user>:<start_id>:<how-many-ids>

#What you now need to do is define the <start_id> for the new user subuids so that ranges don't overlap.

#Info: If you have no users in /etc/subuid or /etc/subgid, the common <start_id> would be 100000.

start_id=100000
sudo usermod \
    --add-subuids $((start_id))-$((start_id+65535)) \
    --add-subgids $((start_id))-$((start_id+65535)) $user

#login to user
machinectl shell $user@

dockerd-rootless-setuptool.sh install

mkdir ~/docker

if [ ! -f ~/.bashrc.bkp ]; then
  cp ~/.bashrc .bashrc.bkp
else
  cp ~/.bashrc.bkp ~/.bashrc
fi
echo "export PATH=/usr/bin:$PATH" >> ~/.bashrc
echo "export DOCKER_HOST=unix:///run/user/998/docker.sock" >> ~/.bashrc
echo "cd ~/docker" >> ~/.bashrc

source ~/.bashrc

systemctl --user start docker
systemctl --user status docker
docker ps

docker info | grep -A 7 "Storage Driver:"

#Output
#
#    Storage Driver: overlay2
#    WARNING: No cpu cfs quota support
#    WARNING: No cpu cfs period support
#    [...]
#    Backing Filesystem: xfs
#    Supports d_type: true
#    Using metacopy: false
#    Native Overlay Diff: false
#    userxattr: true
#    Logging Driver: json-file
#    Cgroup Driver: systemd

#Info

#You can see a number of warnings that indicate that you are running docker without root privileges. Unless you are using Docker images that require special permissions, this will not have an effect.

#Enable the docker service on startup:

systemctl --user enable docker

#We also need to enable lingering to make this work with rootless docker. Logout from the $user user first, then check with the second command afterwards.

# CTRL+D
sudo loginctl enable-linger $user
sudo loginctl show-user $user

