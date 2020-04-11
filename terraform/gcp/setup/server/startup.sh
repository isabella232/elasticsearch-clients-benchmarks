#!/usr/bin/env bash

sudo su -

# ----- Add the "elasticsearch" user
useradd -d /home/elasticsearch -k /etc/skel -m -s /bin/bash -U elasticsearch
echo "Defaults:elasticsearch !requiretty" > /etc/sudoers.d/elasticsearch
echo "elasticsearch ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers.d/elasticsearch

# ----- Mount and format the local disk
lsblk
mkfs.ext4 -F /dev/nvme0n1
mkdir -p /mnt/disks/data
mount /dev/nvme0n1 /mnt/disks/data
chmod a+w /mnt/disks/data/
chown -R elasticsearch:elasticsearch /mnt/disks/data/
echo UUID=$(blkid -s UUID -o value /dev/disk/by-id/google-local-ssd-0) /mnt/disks/data ext4 discard,defaults,nofail,nobarrier 0 2 | tee -a /etc/fstab
mkdir -p /mnt/disks/data/elasticsearch
chown -R elasticsearch:elasticsearch /mnt/disks/data/elasticsearch

# ----- Configure system limits
swapoff -a
sysctl -w vm.swappiness=1
sysctl -w fs.file-max=262144
sysctl -w vm.max_map_count=262144
cat >> /etc/security/limits.conf <<EOF
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
elasticsearch soft nofile 65535
elasticsearch hard nofile 65535
elasticsearch soft nproc 4096
elasticsearch hard nproc 4096
EOF

# ----- Prune the SSH welcome messages
chmod -x /etc/update-motd.d/*
chmod +x /etc/update-motd.d/00*

# ----- Install Docker
apt-get install --yes apt-transport-https ca-certificates gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get install --yes docker-ce docker-ce-cli containerd.io

# ----- Install, configure and start Metricbeat
curl -fsSL -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-${elasticsearch_version}-amd64.deb
dpkg -i metricbeat-${elasticsearch_version}-amd64.deb
rm -f metricbeat-${elasticsearch_version}-amd64.deb

cat > /etc/metricbeat/metricbeat.yml <<EOF
${metricbeat_config}
EOF

service metricbeat start

# ----- Install, configure and start Filebeat
curl -fsSL -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${elasticsearch_version}-amd64.deb
dpkg -i filebeat-${elasticsearch_version}-amd64.deb
rm -f filebeat-${elasticsearch_version}-amd64.deb

cat > /etc/filebeat/filebeat.yml <<EOF
${filebeat_config}
EOF

service filebeat start

# ----- Install Elasticsearch from tar.gz
cd /home/elasticsearch/
curl -fsSL -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${elasticsearch_version}-linux-x86_64.tar.gz
tar -xf elasticsearch-${elasticsearch_version}-linux-x86_64.tar.gz
rm -f elasticsearch-${elasticsearch_version}-linux-x86_64.tar.gz
chown -R elasticsearch:elasticsearch /home/elasticsearch/*

# ----- Start Elasticsearch
su - elasticsearch -c '
  ES_JAVA_OPTS="-Xms4g -Xmx4g -Des.enforce.bootstrap.checks=true" \
    /home/elasticsearch/elasticsearch-${elasticsearch_version}/bin/elasticsearch \
      -E node.name=es-${format("%03d", server_nr)} \
      -E cluster.name=bench-${build_id} \
      -E cluster.initial_master_nodes=${master_ip} \
      -E discovery.seed_hosts=${master_ip} \
      -E network.host=_local_,_site_ \
      -E path.data=/mnt/disks/data/elasticsearch/ \
      -E bootstrap.memory_lock=true \
      --pidfile=/home/elasticsearch/es-${format("%03d", server_nr)}.pid
      --daemonize'

