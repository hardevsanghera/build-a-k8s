# build-a-k8s
Scripts to build a Kubernetes cluster from Ubuntu 22.04 servers (VMs or otherwiae)

##Files
| Filename | Description | 
| -------- | ----------- |
| .env.dist |                      Copy and edit as .env for your requirements |
| requirements.txt |               Python modules to use for ProdTasksProj |
| Dockerfile  |                    Build the image for the application part of ProdTasksProj |


 ssh -p 22112 ubuadmin@192.168.0.19 'sudo bash -s' worker02 < setup-ubu22-k8s-node.sh
 ssh -p 22006 ubuadmin@192.168.0.19 'sudo bash -s worker02 192.168.4.112' < set-hname-ip.sh

 ```sh
   $ docker compose -f docker-compose-deploy.yml up
```
