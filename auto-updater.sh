#!/bin/bash

# vCenter/PSC SSL Certificate Updater.
# For more information see
#  https://wiki.9r.com.au/display/9R/LetsEncrypt+Certificates+for+vCenter+and+PSC

# Copyright (c) 2018 - Rob Thomas - xrobau@linux.com


# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# UPDATES:
# 2024-11-11 - Patrick T. Rutledge III - rut31337:
#       Installation and setup README.md updates
# 2024-11-11 - John Apple II - 9strands:
#       Certificate generation errors due to order

# You need to create a file called /root/.acme.sh/update.conf with the
# following lines in it:

CERTNAME='my.certificate.name'
ADMINACCOUNT='admin@vcenter.local'
ADMINPASS='admin'

# Replacing the values, obviously. 
if [ ! -e /root/.acme.sh/update.conf ]; then
        echo "No update.conf file configured, can not update. Read the update script for instructions!"
        exit 1
fi

. /root/.acme.sh/update.conf

# This is the sample file we compare against the latest file from acme.sh,
# and is present on both a PSC and a vCenter server.
CURRENTLIVE=/etc/vmware-rhttpproxy/ssl/rui.crt

# These environment variables are needed by vCenter
eval $(awk '{ print "export " $1 }' /etc/sysconfig/vmware-environment)

# Nothing should need to be touched below here
CERT=/root/.acme.sh/$CERTNAME/$CERTNAME.cer

if [ ! -e $CERT ]; then
        echo "Can't find cert $CERT - is update.conf correct?"
        exit 1
fi

# Compare the MD5sums of the running cert and the current LE cert
LIVEMD5=$(md5sum $CURRENTLIVE | cut -d\  -f1)
CURRENTMD5=$(md5sum $CERT | cut -d\  -f1)

if [ "$LIVEMD5" == "$CURRENTMD5" ]; then
        # Nothing to be done. Current certificate is correct
        exit 0
fi

# We need to update this machine with the new certificate.
KEY=/root/.acme.sh/$CERTNAME/$CERTNAME.key
MYCERT=/root/.acme.sh/$CERTNAME/$CERTNAME.cer
CHAIN=/root/.acme.sh/$CERTNAME/fullchain.cer
CA=/root/.acme.sh/$CERTNAME/ca.cer
COMBINED_CERT=/root/.acme.sh/$CERTNAME/combined-cert.cer

# Add Self-Signed to combined cert as required by certificate-manager

cat ${MYCERT} > ${COMBINED_CERT}
cat ${CHAIN} >> ${COMBINED_CERT}

# We delay briefly between account and password, as it's trying to open /dev/tty
# which has the potential to lose characters. To be on the safe side, we sleep
# between important bits. I feel that adding a 3 second delay to the upgrade that
# takes 10 minutes to run is not a big deal!

(
  printf '1\n%s\n' "$ADMINACCOUNT"
  sleep 1
  printf '%s\n' "$ADMINPASS"
  sleep 1
  printf '2\n'
  sleep 1
  printf '%s\n%s\n%s\ny\n\n' "$COMBINED_CERT" "$KEY" "$CA"
) | setsid /usr/lib/vmware-vmca/bin/certificate-manager

# 'setsid' detatches certman from /dev/tty, so it's forced to use stdin.
