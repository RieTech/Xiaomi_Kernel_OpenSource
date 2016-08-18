#!/bin/bash

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#### USAGE:
#### ./buildJerricaMI.sh [clean]
#### [clean] - clean is optional
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#####
### Prepared by:
### Prema Chand Alugu (premaca@gmail.com)
#####
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

### This script is to compile JERRICA kernel for MiUi7/8

### This is INLINE_KERNEL_COMPILATION

### Create a directory, and keep kernel code, example:
#### premaca@paluguUB:~/KERNEL_COMPILE$ ls
####    arm-eabi-4.8  kernel-code
####

JERRICA_POSTFIX=$(date +"%Y%m%d")

#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS BEGIN @@@@@@@@@@@@@@@@@@@@@@@@@@@#
##### Tool-chain, you should get it yourself which tool-chain 
##### you would like to use
KERNEL_TOOLCHAIN=/media/premaca/working/KERNEL_COMPILE/arm-eabi-4.8/bin/arm-eabi-

## This script should be inside the kernel-code directory
KERNEL_DIR=$PWD

## should be preset in arch/arm/configs of kernel-code
KERNEL_DEFCONFIG=wt88047_kernel_defconfig

## AnyKernel2 
AK2_DIR=$KERNEL_DIR/AnyKernel2

## boot image tools
##BOOTIMG_TOOLS_PATH=$PWD/mkbootimg_tools/

## release out directory
RELEASE_DIR=$PWD
JERRICA_MI_RELEASE=Jerrica-MK-v1.1-$JERRICA_POSTFIX.zip

## make jobs
MAKE_JOBS=10

## extracted directory from original target boot.img (MiUi8)
##BOOTIMG_EXTRACTED_DIR=$PWD/boot_miui8_extracted/

## platform specifics
export ARCH=arm
export SUBARCH=arm

## Give the path to the toolchain directory that you want kernel to compile with
## Not necessarily to be in the directory where kernel code is present
export CROSS_COMPILE=$KERNEL_TOOLCHAIN
#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS  END  @@@@@@@@@@@@@@@@@@@@@@@@@@@#


## command execution function, which exits if some command execution failed
function exec_command {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "********************************" >&2
        echo "!! FAIL !! executing command $1" >&2
        echo "********************************" >&2
    	exit
    fi
    return $status
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Prepare out directory
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
exec_command rm -rf $AK2_DIR/*.zip
exec_command rm -rf $AK2_DIR/dtb
exec_command rm -rf $AK2_DIR/dt.img
exec_command rm -rf $AK2_DIR/zImage
exec_command rm -rf $AK2_DIR/modules/*

echo "***** Tool chain is set to $KERNEL_TOOLCHAIN *****"
echo "***** Kernel defconfig is set to $KERNEL_DEFCONFIG *****"
exec_command make $KERNEL_DEFCONFIG

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Read [clean]
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
## $1 = clean
##
cleanC=0
if [ $# -ne 0 ]; then
cleanC=1
fi

if [ $cleanC -eq 1 ]
then
echo "***** Going for Clean Compilation *****"
exec_command make clean
exec_command make mrproper
make ARCH=arm CROSS_COMPILE=arm-eabi-  $KERNEL_DEFCONFIG
else
echo "***** Going for Dirty Compilation *****"
fi

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Do the JOB, make it
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
## you can tune the job number depends on the cores
exec_command make -j$MAKE_JOBS

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Generate DT.img and verify zImage/dt.img
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Generating DT.IMG *****"
exec_command $AK2_DIR/dtbToolCM -2 -o $KERNEL_DIR/arch/arm/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
echo "***** Verify zImage and dt.img *****"
exec_command ls $KERNEL_DIR/arch/arm/boot/zImage
exec_command ls $KERNEL_DIR/arch/arm/boot/dt.img

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# copy modules to AnyKernel2/modules/
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Copying Modules to $AK2_DIR *****"
exec_command cp `find . -name "*.ko"` $AK2_DIR/modules/

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# copy zImage and dt.img to boot_miui8_extracted
# for our boot.img preparation
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Copying zImage to $AK2_DIR/zImage *****"
echo "***** Copying dt.img to $AK2_DIR/dt.img *****"
exec_command cp $KERNEL_DIR/arch/arm/boot/zImage $KERNEL_DIR/arch/arm/boot/dt.img $AK2_DIR/

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
######## TIME FOR FINAL JOB
##
## Generate the Final Flashable Zip
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Verify what we got in $AK2_DIR *****"
exec_command ls $AK2_DIR
echo "***** MAKING the Final Flashable ZIP $JERRICA_MI_RELEASE from $AK2_DIR *****"
exec_command cd $AK2_DIR
exec_command mv dt.img dtb
exec_command zip -r9 $JERRICA_MI_RELEASE * -x README $JERRICA_MI_RELEASE

echo "***** Please Scroll up and verify for any Errors *****"
echo "***** Script exiting Successfully !! *****"

exec_command cd $KERNEL_DIR

echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "##                                                      ##"
echo "##     KERNEL BUILD IS SUCCESSFUL                       ##"
echo "##                                                      ##"
echo "##     Flash this $AK2_DIR/$JERRICA_MI_RELEASE          ##"
echo "##                                                      ##"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"

exit
