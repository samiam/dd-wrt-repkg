#!/bin/sh -
# $Id: get_images.sh,v 1.2 2009/07/24 22:06:36 sam Exp $
# Obtain binaries for dd-wrt

# Additional packages I install on dd-wrt
get_ipkgs () {

  BINARIES="libpcap_0.9.4-1_mipsel.ipk
            microperl_5.8.6-1_mipsel.ipk
            libreadline_5.0-1_mipsel.ipk
	    tcpdump_3.9.4-1_mipsel.ipk"

  for f in $BINARIES;
  do
    wget -N http://downloads.openwrt.org/whiterussian/newest/packages/$f
    if [ $? != 0 ]; then
       echo "Unable to wget $f"
       exit 1
    fi
  done
}

get_ipkgs
