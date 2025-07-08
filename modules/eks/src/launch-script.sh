Content-Type: multipart/mixed; boundary="===============6032913095595459405=="
MIME-Version: 1.0
Number-Attachments: 2

--===============6032913095595459405==
Content-Type: text/cloud-boothook; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="part-001"

#!/bin/bash

#
# Note: this script performs the following operations
# * Look for a single NVME device (multiple attached NVME not supported)
# * If none found, exit
# * Format drive as XFS and mount at /var/lib/kubelet/pods
#

DEVICE=/dev/nvme1n1
FS=xfs
MOUNT_PATH=/var/lib/kubelet/pods

if ! fdisk -l $DEVICE > /dev/null 2>&1; then
  echo No NVME drive detected
  exit 0
fi

mkfs -t $FS $DEVICE       # no-op if it's already formatted
mkdir -p $MOUNT_PATH      # no-op if mount path already exists
mount $DEVICE $MOUNT_PATH # no-op if it's already  mounted
--===============6032913095595459405==
