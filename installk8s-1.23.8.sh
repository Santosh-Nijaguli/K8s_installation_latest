#!/bin/bash

echo "     Running script with $(whoami)"

echo "     STEP 1: Disabling Swap"
        # First diasbale swap
        sudo swapoff -a
        # And then to disable swap on startup in /etc/fstab
        sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "            -> Done"

echo "     STEP 2: Adding Kernel parameters "
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
echo "     Configure the critical kernel parameters for Kubernetes"
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

        sudo sysctl --system

echo "  STEP 3: Install Containerd Runtime"
        sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

echo "  Enabling the Docker repository"
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        sudo apt update 1>/dev/null

echo "  Updating the package list and install containerd"
        sudo apt install -y containerd.io

echo "     STEP 4:Configure containerd to start using systemd as cgroup"
        containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
        sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

echo "  Restarting & enabling containerd services"
        sudo systemctl restart containerd
        sudo systemctl enable containerd


echo "  STEP 5:Add Apt Repository for Kubernetes"
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list


echo "     STEP 6: Updating apt"
        apt-get update 1>/dev/null

echo "     STEP 7: Installing kubenetes master components"
        echo "            -> Installing kubelet"
                apt-get install -y kubelet 1>/dev/null
        echo "            -> Installing kubeadm"
                apt-get install -y kubeadm 1>/dev/null
        echo "            -> Installing kubectl"
                apt-get install -y kubectl 1>/dev/null
        echo "            -> Installing kubernetes-cni"
                apt-get install -y kubernetes-cni 1>/dev/null


echo "-----------------------------------------------------------"
echo "  Kubernetes node template is now created "
echo "  Create AMI form this node to create worker nodes"
echo "  Action --> Image --> Create Image"
echo "      Note: This node will be your master node "
echo "-----------------------------------------------------------"
exit
