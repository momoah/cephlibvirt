# How to install

## Ensure you have DNS records:
```bash
# cat /var/named/local.momolab.io.db | grep ceph
; ceph nodes
cephadmin	IN A 	192.168.1.210
ceph-01		IN A 	192.168.1.211
ceph-02		IN A 	192.168.1.212
ceph-03		IN A 	192.168.1.213
```
and
```bash
# cat /var/named/192.168.1.db |grep ceph
210	IN 	PTR	cephadmin.local.momolab.io.
211	IN 	PTR	ceph-01.local.momolab.io.
212	IN 	PTR	ceph-02.local.momolab.io.
213	IN 	PTR	ceph-03.local.momolab.io.
```


```bash
ansible-playbook playbooks/01_terraform.yml # Creates the libvirt infrastructure
ansible-playbook playbooks/02_rhel_updates.yml# Setup repos and update OS
ansible-playbook playbooks/03_ceph_updates.yml# Sets up all the ceph repos, and installs software
# The above can be grouped, but the next one demands user input once (registry username and password.)
ansible-playbook playbooks/04_cephadmin_bootstrap.yml # User interaction required (enter your quay.io username and password) then it installs ceph
ansible-playbook playbooks/05_cephadmin_post_bootstrap.yml # Adds all hosts into the cluster and assigns roles

```

To create a ceph pool (if using OpenShift ODF):

Login to the ceph admin node, and sudo to root, then run:

```bash
ceph osd pool create openshift replicated
rbd pool init openshift
# If using ODF, run script:
python3 ceph-external-cluster-details-exporter.py --rbd-data-pool-name openshift
```

## Bridge Installation

https://major.io/p/creating-a-bridge-for-virtual-machines-using-systemd-networkd/




## Author(s)
  * Mohammad Ahmad 
