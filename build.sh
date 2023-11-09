#!/bin/sh

ZEROTIER_VERSION=1.12.2

echo "Step 1: Enable community repository"

cat > /etc/apk/repositories << EOF; $(echo)

https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/main/
https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community/
https://dl-cdn.alpinelinux.org/alpine/edge/testing/

EOF

echo "Step 2: Download apk packages"
apk add --update alpine-sdk cargo linux-headers openssl-dev

echo "Step 3: Clone and build ZeroTier ${ZEROTIER_VERSION}"
git clone --quiet https://github.com/zerotier/ZeroTierOne.git /src/zt \
&& git -C /src/zt reset --quiet --hard ${ZEROTIER_VERSION} \
&& cd /src/zt \
&& make -f make-linux.mk && make install

mkdir -p /var/lib/zerotier-one; \
    ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool; \
    ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli;
rm -rf /src/zt

echo "Step 4: Configure /etc/issue"
cat <<EOF >/etc/issue
ZeroTier Layer 2 Bridge
-----------------------

Default credentials: root/root

EOF

echo "Step 5: Configure /etc/motd"
cat <<EOF >/etc/motd
ZeroTier Bridge
===============

To join a network (only needed on initial boot):
    join <ZeroTier Network ID>

To leave a network gracefully:
    zerotier-cli leave <ZeroTierNetwork ID>

Bridge is automatically configured between eth1 and
the ZeroTier interface (network).

See /etc/network/interfaces for details after join.

EOF

echo "Step 6: Configure join script"
cat <<EOF >/usr/sbin/join
#!/bin/sh

ZT_NET_ID=$1
ZT_INT=$(ip link show | grep zt | awk '{print $2}' | tr -d ':')
BRIDGE_TO_INT=eth1


if [ -z "$ZT_INT" ]
then

  if [ -z "$1" ]
  then
    read -p "Enter ZeroTier Network ID: " ZT_NET_ID
  fi

  if zerotier-cli join $ZT_NET_ID;
  then
    ZT_INT=$(ip link show | grep zt | awk '{print $2}' | tr -d ':')
  else
    echo "Unable to join ZeroTier network. Exiting."
    exit
  fi

else
  echo "ZeroTier network already joined"
  exit
fi

echo "Writing bridge configuration"
cat <<EOT>> /etc/network/interfaces

auto br0
iface br0 inet static
        bridge-ports $ZT_INT $BRIDGE_TO_INT
        bridge-stp 0
        pre-up /etc/init.d/zerotier-one start && sleep 2

EOT

echo "Renabling bridge interface"
ifup br0
EOF

chmod +x /usr/sbin/join

echo "Step 7: Remove build script"

echo "Finished"
