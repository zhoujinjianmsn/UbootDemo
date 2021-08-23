# u_boot_demo
u_boot_demo for rockpi4b_plus_v1.6

#1、ROCKPI 4A/B（编译u-boot）

$ cd u-boot
$ ./make.sh rockpi4b
$ cd -

#2、ROCKPI 4A/B（编译kernel）

$ cd kernel
$ make ARCH=arm64 rockchip_defconfig android-10.config rockpi_4b.config
$ make ARCH=arm64 rk3399-rockpi-4b.img -j8
$ cd -

#3、ROCKPI 4A/B（编译Android）

$ source build/envsetup.sh
$ lunch RockPi4B-userdebug
$ make -j8

#4、ROCKPI 4A/B（mkimage）

$ ln -s RKTools/linux/Linux_Pack_Firmware/rockdev/ rockdev
$ ./mkimage.sh

#5、ROCKPI 4A/B（编译update.img）

$ cd rockdev
$ ln -s Image-RockPi4B Image
$ ./mkupdate_rk3399.sh

Please burn rockdev/update.img
