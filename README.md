# u_boot_demo for rockpi4b_plus_v1.6

# 0、Env(NO) && Download Source Code

$ curl https://storage.googleapis.com/git-repo-downloads/repo-1 > ~/bin/repo

$ chmod a+x ~/bin/repo

$ python3 ~/bin/repo init -u https://github.com/radxa/manifests.git -b rockchip-android-10 -m rockchip-q-release.xml

$ cd u-boot 

$ rm -rf *

$ cp u-boot-xxx-ok/* to u-boot 


# 1、ROCKPI 4A/B（编译u-boot）

$ cd u-boot

$ ./make.sh rockpi4b

$ cd -


# 2、ROCKPI 4A/B（编译kernel）

$ cd kernel

$ make ARCH=arm64 rockchip_defconfig android-10.config rockpi_4b.config

$ make ARCH=arm64 rk3399-rockpi-4b.img -j8

$ cd -


# 3、ROCKPI 4A/B（编译Android）

$ source build/envsetup.sh

$ lunch RockPi4B-userdebug

$ make -j8


# 4、ROCKPI 4A/B（mkimage）

$ ln -s RKTools/linux/Linux_Pack_Firmware/rockdev/ rockdev

$ ./mkimage.sh


# 5、ROCKPI 4A/B（编译update.img）

$ cd rockdev

$ ln -s Image-RockPi4B Image

$ ./mkupdate_rk3399.sh


Please burn rockdev/update.img

https://wiki.radxa.com/Android/android_tool
