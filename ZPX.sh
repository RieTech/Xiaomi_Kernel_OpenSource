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

## platform specifics
export KBUILD_BUILD_USER="Team_Cangkuls"
export KBUILD_BUILD_HOST="Zero_ProjectX"
export ARCH=arm
export SUBARCH=arm
TOOL_CHAIN_ARM=arm-eabi-

#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS BEGIN @@@@@@@@@@@@@@@@@@@@@@@@@@@#
##### Tool-chain, you should get it yourself which tool-chain 
##### you would like to use
KERNEL_TOOLCHAIN=/root/arm-eabi-4.7/bin/$TOOL_CHAIN_ARM

## This script should be inside the kernel-code directory
KERNEL_DIR=$PWD

## should be preset in arch/arm/configs of kernel-code
KERNEL_DEFCONFIG=wt88047_kernel_defconfig

## boot image tools
BOOTIMG_TOOLS_PATH=$PWD/mkbootimg_tools/

## AnyKernel2 
AK2_DIR=$PWD/AnyKernel2

## make jobs
MAKE_JOBS=10

## extracted directory from original target boot.img (MiUi8)
BIT_OUT_DIR=$KERNEL_DIR/out
BOOTIMG_EXTRACTED_DIR=$PWD/boot_miui8_extracted/
AK2_OUT_DIR=$AK2_DIR

## Give the path to the toolchain directory that you want kernel to compile with
## Not necessarily to be in the directory where kernel code is present
export CROSS_COMPILE=$KERNEL_TOOLCHAIN
#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS  END  @@@@@@@@@@@@@@@@@@@@@@@@@@@#


# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    ak)
    	BUILD_WITH_AK2=YES
	## release out directory
	RELEASE_DIR=$AK2_DIR
    	#shift # past argument
    ;;
    bit)
    	BUILD_WITH_BIT=YES
	## release out directory
	RELEASE_DIR=$KERNEL_DIR/out/
    	#shift # past argument
    ;;
    clean)
    CLEAN_BUILD=YES
    #shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ "$BUILD_WITH_BIT" != 'YES' ] && [ "$BUILD_WITH_AK2" != 'YES' ]
    then echo;
    	echo "***************************************************************"
	echo "**********!!!!!  CHOSE BUILD TYPE (ak/bit)  !!!!!**************"
	echo "***************************************************************"
	echo;
	exit;
fi


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
echo "***************!!!!!  CLEAN  $BIT_OUT_DIR !!!!!********************"
if [ "$BUILD_WITH_BIT" == 'YES' ]; then
exec_command rm -f $BIT_OUT_DIR/*.zip
fi
exec_command rm -f $BIT_OUT_DIR/boot.img
exec_command rm -rf $BIT_OUT_DIR/system/lib
exec_command rm -f $BIT_OUT_DIR/arch/arm/boot/zImage
exec_command rm -f $BIT_OUT_DIR/arch/arm/boot/dt.img
exec_command rm -f  $BOOTIMG_EXTRACTED_DIR/kernel $BOOTIMG_EXTRACTED_DIR/dt.img

echo "***************!!!!!  CLEAN  $AK2_OUT_DIR !!!!!********************"
if [ "$BUILD_WITH_AK2" == 'YES' ]; then
exec_command rm -f $AK2_OUT_DIR/*.zip
fi
exec_command rm -rf $AK2_OUT_DIR/dtb
exec_command rm -rf $AK2_OUT_DIR/dt.img
exec_command rm -rf $AK2_OUT_DIR/zImage
exec_command rm -rf $AK2_OUT_DIR/modules/*

echo "***** Tool chain is set to $KERNEL_TOOLCHAIN *****"
echo "***** Kernel defconfig is set to $KERNEL_DEFCONFIG *****"
exec_command make $KERNEL_DEFCONFIG

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Read [clean]
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
if [ "$CLEAN_BUILD" == 'YES' ]
	then echo;
	echo "***************************************************************"
	echo "***************!!!!!  BUILDING CLEAN  !!!!!********************"
	echo "***************************************************************"
	echo;
	exec_command make clean
	exec_command make mrproper
	make ARCH=$ARCH CROSS_COMPILE=$TOOL_CHAIN_ARM  $KERNEL_DEFCONFIG
fi

## FINAL ZIP
JERRICA_MI_RELEASE=Ken_Arok-$z-$JERRICA_POSTFIX.zip

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Do the JOB, make it
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
## you can tune the job number depends on the cores
   v=`cat .extraversion`;
EV=EXTRAVERSION=$v;
exec_command make $EV -j$MAKE_JOBS

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Generate DT.img and verify zImage/dt.img
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Generating DT.IMG *****"
if [ "$BUILD_WITH_BIT" == 'YES' ]; then
	exec_command $BOOTIMG_TOOLS_PATH/dtbToolCM -2 -o $KERNEL_DIR/arch/arm/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
else
	exec_command $AK2_DIR/dtbToolCM -2 -o $KERNEL_DIR/arch/arm/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
fi
echo "***** Verify zImage and dt.img *****"
exec_command ls $KERNEL_DIR/arch/arm/boot/zImage
exec_command ls $KERNEL_DIR/arch/arm/boot/dt.img

if [ "$BUILD_WITH_BIT" == 'YES' ]; then
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	# copy wlan.ko to out/system/lib/modules/pronto
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	echo "***** Copying wlan.ko to $RELEASE_DIR *****"
	exec_command mkdir -p $RELEASE_DIR/system/lib/modules/pronto/
	exec_command cp $KERNEL_DIR/drivers/staging/prima/wlan.ko $RELEASE_DIR/system/lib/modules/pronto/pronto_wlan.ko

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	# copy radio-iris-transport.ko to out/system/lib/modules/
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	echo "***** Copying radio-iris-transport.ko to $RELEASE_DIR *****"
	exec_command mkdir -p $RELEASE_DIR/system/lib/modules/
	exec_command cp $KERNEL_DIR/drivers/media/radio/radio-iris-transport.ko $RELEASE_DIR/system/lib/modules/radio-iris-transport.ko

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	# copy zImage and dt.img to boot_miui8_extracted
	# for our boot.img preparation
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	echo "***** Copying zImage to $BOOTIMG_EXTRACTED_DIR/kernel *****"
	echo "***** Copying dt.img to $BOOTIMG_EXTRACTED_DIR/dt.img *****"
	exec_command cp $KERNEL_DIR/arch/arm/boot/zImage $BOOTIMG_EXTRACTED_DIR/kernel
	exec_command cp $KERNEL_DIR/arch/arm/boot/dt.img $BOOTIMG_EXTRACTED_DIR/dt.img

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	# Generate our boot.img and verify we got it
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
	echo "***** Moving to directory $BOOTIMG_TOOLS_PATH *****"
	exec_command cd $BOOTIMG_TOOLS_PATH
	echo "***** Generating boot.img into $RELEASE_DIR *****"
	exec_command ./mkboot $BOOTIMG_EXTRACTED_DIR $RELEASE_DIR/boot.img
	echo "***** Check the existence of boot.img in $RELEASE_DIR *****"
	exec_command ls $RELEASE_DIR/boot.img
else
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
fi

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
######## TIME FOR FINAL JOB
##
## Generate the Final Flashable Zip
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Verify what we got in $RELEASE_DIR *****"
exec_command ls $RELEASE_DIR
echo "***** MAKING the Final Flashable ZIP $JERRICA_MI_RELEASE from $RELEASE_DIR *****"
exec_command cd $RELEASE_DIR
if [ "$BUILD_WITH_BIT" == 'YES' ]; then
	exec_command zip -r9 $JERRICA_MI_RELEASE *
else
	exec_command cd $AK2_DIR
	exec_command mv dt.img dtb
	exec_command zip -r9 $JERRICA_MI_RELEASE * -x README $JERRICA_MI_RELEASE
fi

echo "***** Please Scroll up and verify for any Errors *****"
echo "***** Script exiting Successfully !! *****"
curl -F chat_id="195698670" -F document=@"$RELEASE_DIR/$JERRICA_MI_RELEASE" -F caption="Love You !" https://api.telegram.org/bot341370978:AAHNAQa340-t2heNRxftBxlOY5j8PvvjBDE/sendDocument


exec_command cd $KERNEL_DIR

echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "##                                                      ##"
echo "##     KERNEL BUILD IS SUCCESSFUL                       ##"
echo "##                                                      ##"
echo "##     Flash this $RELEASE_DIR/$JERRICA_MI_RELEASE      ##"
echo "##                                                      ##"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"

exit
