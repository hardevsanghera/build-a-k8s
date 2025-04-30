# build-a-k8s
Scripts to build a Kubernetes cluster from Ubuntu 22.04 servers (VMs or otherwiae)

## Files
| Filename | Description | 
| -------- | ----------- |
| set-hname-ip.sh | Set the hostname, static IP and add to /etc/hosts |
| setup-ubu22-k8s-node.sh | Install Docker, Kubernetes and Flannel, initilize a master-node or a worker node |

## Network Setup 
master-node (control plane: 192.168.4.110
worker01: 192.168.4.111
worker02: 192.168.4.112

## Base Ubuntu 22.04 build
This has:
1. Admin user ubuadmin
2. ssh server with "PasswordAuthentication yes"
3. NOPASSWD sudo for ubuadmin

## Execution
1. Set the hostname and static IP for a base installed Ubunto 22.04 server, the target would have been booted with a DHCP IP on the 192.168.4.0/24 subnet - you can use what you like but will need to edit the script/provide different paramters:
```sh  
 $ ssh ubuadmin@192.168.4.5 'sudo bash -s' master-node < setup-ubu22-k8s-node.sh
```
2. Once the VM has rebooted point the main build script at the new static IP:
```sh
 $ ssh -p 22006 ubuadmin@192.168.0.19 'sudo bash -s worker02 192.168.4.112' < set-hname-ip.sh
 ```
3. Repeat for worker1 and worker 2 - you will need to execute the kubeadm join command output from the initialisation of the master-node on every worker node, the script will not do it fpr you.
