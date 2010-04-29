#!/bin/sh -
# $Id: installv24.sh,v 1.7 2010/04/20 02:10:43 sam Exp sam $
#
# Script to build dd-wrt images.
#
# The process:
#   * obtain binaries from Internet
#   * checkout firwaremodkit
#   * extract base wrt image
#   * add packages to system, modify scripts/layout, etc.
#   * rebuild image
#
# Notes:
#   * No need to be root
#   * Everything occurs within SANDBOX
#   * See firmware_mod_kit doc howto_modify_firmware.htm
# 
# Bugs:
#   * I ASSume I'll always have internet access to download images.
#     If I don't have internet access due to the router be hosed, I'll
#     be hosed and have to go the library or something.
#################################################################

#
# Config
#
HOMEDIR="`pwd`"                    # ro

# helper script used to retrieve images
DOWNLOAD_SCRIPT="$HOMEDIR/get_images.sh"

# where all output occurs
SANDBOX="/var/tmp/dd-wrt.install"  # rw

# ipk(s) and binaries
BINARY_DIR="$SANDBOX/images"       # rw

# image install dir
FIRMWARE_DIR="$SANDBOX/trunk"                      # rw

# extracted image (filesystem) of dd-wrt (must be subdir of FIRMWARE_DIR)
EXTRACT_DIR="$FIRMWARE_DIR/extract_dir"            # rw

# where resulting imgs stored
IMAGE_DIR="$SANDBOX/`date +%F`"                    # rw

#########################################################################

die () {
    echo "$*"
    exit 1;
}

case "$1" in
    vint)  VINT=1 ;;
    newd)  VINT=0 ;;
       *)  die "Usage: $0 vint|newd" ;;
esac


# Check svn installed
svn help > /dev/null 2>&1
if [ $? != 0 ]; then
   die "svn is not installed.  Please install first."
fi


# Checkout fresh tree of firmware mod kit
mkdir $SANDBOX 2> /dev/null
cd $SANDBOX || die "Unable to chdir $SANDBOX"
cmd="checkout"
if [ -d $FIRMWARE_DIR ]; then
   cmd="update"
fi
svn $cmd http://firmware-mod-kit.googlecode.com/svn/trunk $FIRMWARE_DIR


# Retrieve additional images
if [ ! -x $DOWNLOAD_SCRIPT ]; then
   die "No such script $DOWNLOAD_SCRIPT"
fi
mkdir $BINARY_DIR 2> /dev/null
cd $BINARY_DIR
$DOWNLOAD_SCRIPT


# Retrieve dd-wrt image - sadly this is a hack
# Router is a Linksys WRT54GS v1.0.
get_vint () {
  # Version v24 SP1 should use vintage builds.
  # See http://www.dd-wrt.com/phpBB2/viewtopic.php?t=31978 or wiki
  WRT_IMAGE="dd-wrt.v24-13064_VINT_std.bin"
  wget -N "http://www.dd-wrt.com/routerdb/de/download/Linksys/WRT54GS/v1.0/dd-wrt.v24-13064_VINT_std.bin/2180" -O $WRT_IMAGE
}

get_latest () {
  WRT_IMAGE="dd-wrt.v24_std_generic.bin"
  wget -N "http://www.dd-wrt.com/dd-wrtv2/downloads/others/eko/BrainSlayer-V24-preSP2/07-21-09-r12533/broadcom/dd-wrt.v24_std_generic.bin"
}

if [ $VINT -eq 1 ]; then
    get_vint
else
    get_latest
fi
if [ ! -s "$WRT_IMAGE" ]; then
   die "It appears the dd-wrt image did not download.  Check for $WRT_IMAGE"
fi
IMAGE_DIR="$SANDBOX/$WRT_IMAGE/`date +%F`"         # rw


# Extract dd-wrt binary
cd $FIRMWARE_DIR || die "Unable to cd $FIRMWARE_DIR"
./extract_firmware.sh $BINARY_DIR/$WRT_IMAGE $EXTRACT_DIR


# Install IPKs into EXTRACT_DIR
# http://downloads.openwrt.org/whiterussian/newest/packages/
# Should manually check to see if there's newer versions avail.
#
cd $FIRMWARE_DIR || die "Unable to cd $FIRMWARE_DIR"
for f in $BINARY_DIR/*.ipk;
do
    ./ipkg_install.sh "$f" $EXTRACT_DIR
    sleep 2                                   # scan for errors
done


# Finally, make local modifications to the image; the whole point of 
# these charades.
# Overlay my copies into place.
#
cd $HOMEDIR || die "Unable to cd $HOMEDIR"
if [ $VINT -eq 1 ]; then
  cp -p S60nas         $EXTRACT_DIR/rootfs/etc/init.d/S60nas
fi
cp -p S30wireless    $EXTRACT_DIR/rootfs/etc/init.d/S30wireless 
cp -p S80profile     $EXTRACT_DIR/rootfs/etc/init.d/S80profile 
cp -p firewall-cmds  $EXTRACT_DIR/rootfs/etc/init.d/firewall-cmds 


# Lastly build image
cd $FIRMWARE_DIR || die "Unable to cd $FIRMWARE_DIR"
./build_firmware.sh $IMAGE_DIR $EXTRACT_DIR

echo "*** Build complete ***"
echo "See $IMAGE_DIR for images"
echo "If installing on a WRT54G[S], use the custom_image-wrt54* images."

exit 0
