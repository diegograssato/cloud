## Ubuntu
https://marc.xn--wckerlin-0za.ch/computer/kubernetes-on-ubuntu-16-04



### Prepare

```bash
https://gist.github.com/alexellis/7315e75635623667c32199368aa11e95#file-kube-sh


 kubeadm config images pull
kubeadm init --pod-network-cidr 192.168.2.0/24

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

```

## Centos

http://www.paulinomreyes.com/?p=225

### Network framework
 

```
vi /etc/selinux/config
SELINUX=disabled
SELINUXTYPE=targeted
SETLOCALDEFS=0

/etc/systemd/network/99-default.link
[Link]
MACAddressPolicy=none


systemctl restart systemd-udevd


 kubeadm join 192.168.2.20:6443 --token sxpft2.dztmn7nijuf3mxgl --discovery-token-ca-cert-hash sha256:14f014c8172430066990dcf1d88dd156073237ea4c41610cda4709b3e6459b22

kubectl apply -f https://git.io/weave-kube


 

curl -SL "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=192.168.2.0/24" \
| kubectl apply -f -

```

### Gerando o arquivo de configuração para instalação do Openstack Newton

packstack --allinone  --provision-demo=n  --os-heat-install=y - 
Additional information:
 * A new answerfile was created in: /root/packstack-answers-20180404-003517.txt
 * Time synchronization installation was skipped. Please note that unsynchronized time on server instances might be problem for some OpenStack components.
 * File /root/keystonerc_admin has been created on OpenStack client host 192.168.10.2. To use the command line tools you need to source the file.
 * To access the OpenStack Dashboard browse to http://192.168.10.2/dashboard .
Please, find your login credentials stored in the keystonerc_admin in your home directory.
 * To use Nagios, browse to http://192.168.10.2/nagios username: nagiosadmin, password: 03c7f9239d7c4472
 * The installation log file is available at: /var/tmp/packstack/20180404-003517-KPH_4C/openstack-setup.log
 * The generated manifests are available at: /var/tmp/packstack/20180404-003517-KPH_4C/manifests


 9C|G\OlQeFbR8|R
 