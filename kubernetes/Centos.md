## Centos

### Prepare

```bash
yum install centos-release-openstack-newton
yum upgrade

yum install openstack-packstack
```


### Configure openstack using packstack - AllinOne
 

```
vim /etc/selinux/config
SELINUX=disabled1
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl mask NetworkManager
/sbin/chkconfig network on
systemctl restart network

ssh-keygen -t rsa
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
 