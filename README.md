# EVE-NG ZeroTier Bridge

Creates an Alpine Linux based image for bridging
ZeroTier networks into EVE-NG labs at Layer 2

## Installation

1. Install the image template

        scp zerotier-bridge.yml root@eve-ng:/opt/unetlab/html/templates/intel/

2. Copy the image

        scp virtioa.qcow2 root@eve-ng:/opt/unetlab/zerotier-bridge-<version>/virtioa.qcow2

3. Fix permissions

        /opt/unetlab/wrappers/unl_wrapper -a fixpermissions

## Building an Image

1. Install Alpine somewhere

    a. Download [virtual ISO](https://alpinelinux.org/downloads/)

    b. Create disk image:
        
        /opt/qemu/bin/qemu-img create -f qcow2 virtioa.qcow2 2G

    c. Run `setup-alpine` and select `sys` disk mode

2. Upload the `build.sh` script and run it

3. Commit and Save the image
