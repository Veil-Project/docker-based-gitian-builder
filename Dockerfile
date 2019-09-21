FROM ubuntu:bionic
MAINTAINER codeofalltrades <codeofalltrades@outlook.com>
ENV DEBIAN_FRONTEND noninteractive
WORKDIR /shared
RUN apt-get update && \
apt-get --no-install-recommends -yq install \
locales \
git-core \
sudo \
build-essential \
ca-certificates \
python3 \
ruby \
rsync && \
apt-get -yq purge grub > /dev/null 2>&1 || true && \
apt-get -y dist-upgrade && \
locale-gen en_US.UTF-8 && \
update-locale LANG=en_US.UTF-8 && \
bash -c '[[ -d /shared/gitian-builder ]] || git clone https://github.com/Veil-Project/gitian-builder /shared/gitian-builder' && \
useradd -d /home/ubuntu -m -s /bin/bash ubuntu && \
chown -R ubuntu.ubuntu /shared/ && \
chown root.root /shared/gitian-builder/target-bin/grab-packages.sh && \
chmod 755 /shared/gitian-builder/target-bin/grab-packages.sh && \
echo 'ubuntu ALL=(root) NOPASSWD:/usr/bin/apt-get,/shared/gitian-builder/target-bin/grab-packages.sh' > /etc/sudoers.d/ubuntu && \
chown root.root /etc/sudoers.d/ubuntu && \
chmod 0400 /etc/sudoers.d/ubuntu && \
chown -R ubuntu.ubuntu /home/ubuntu
USER ubuntu
RUN printf "[[ -d /shared/veil ]] || \
git clone -b \$1 --depth 1 \$2 /shared/veil && \
cd /shared/gitian-builder; \
./bin/gbuild -j\$4 -m\$5 --skip-image --commit veil=\$1 --url veil=\$2 \$3" > /home/ubuntu/runit.sh
CMD ["master","https://github.com/Veil-Project/veil.git","../veil/contrib/gitian-descriptors/gitian-linux.yml", "4", "4096"]
ENTRYPOINT ["bash", "/home/ubuntu/runit.sh"]
