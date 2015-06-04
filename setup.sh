#!/bin/bash

D_R=`cd \`dirname $0\` ; pwd -P`

TMP="/tmp/.feedbin-coreos-on-vagrant-$$"

if [ ! -d $TMP ]; then
  mkdir -p $TMP
fi

if [ ! -d $TMP/coreos-vagrant ]; then
  git clone https://github.com/coreos/coreos-vagrant $TMP/coreos-vagrant || exit $?
fi

cd $TMP/coreos-vagrant || exit $?

if [ ! -f config.rb ]; then
  cp config.rb.sample config.rb || exit $?
fi

if [ ! -f user-data ]; then
  cp user-data.sample user-data
fi

if [ ! -f config.rb.patched ]; then
  echo "42c42
< #\$update_channel='alpha'
---
> \$update_channel='stable'
63,65c63,65
< #\$vm_gui = false
< #\$vm_memory = 1024
< #\$vm_cpus = 1
---
> \$vm_gui = false
> \$vm_memory = 2048
> \$vm_cpus = 2" | patch config.rb || exit $?
  touch config.rb.patched || exit $?
fi

if [ ! -f docker_id_url ]; then
  curl https://discovery.etcd.io/new > docker_id_url || rm -f docker_id_url
fi

DOCKER_ID_URL=`cat docker_id_url` || exit $?

if [ ! -f user-data.patched ]; then
  echo "7c7
<     #discovery: https://discovery.etcd.io/<token>
---
>     discovery: $DOCKER_ID_URL" | patch user-data || exit $?
  touch user-data.patched || exit $?
fi

if [ ! -f Vagrantfile.patched ]; then
  echo "13c13
< \$instance_name_prefix = \"core\"
---
> \$instance_name_prefix = \"feedbin-coreos\"" | patch Vagrantfile || exit $?
  touch Vagrantfile.patched
fi

if [ ! -f vagrant_up.done ]; then
  vagrant up || exit $?
  vagrant status || exit $?
  touch vagrant_up.done || exit $?
fi



vagrant destroy -f || exit $?

cd
rm -rf $TMP || exit $?
