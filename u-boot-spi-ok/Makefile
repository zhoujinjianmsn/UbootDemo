PREFIX=../prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
#PREFIX=aarch64-linux-android-
CC=$(PREFIX)gcc
LD=$(PREFIX)ld
AR=$(PREFIX)ar
OBJCOPY=$(PREFIX)objcopy
OBJDUMP=$(PREFIX)objdump

# Add GCC lib
PLATFORM_LIBS += -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc

u_boot.bin : start.o led.c main.c
	$(CC) -nostdlib -fno-builtin -g -c -o led.o led.c		
	$(CC) -nostdlib -fno-builtin -g -c -o uart.o uart.c	
	$(CC) -nostdlib -fno-builtin -g -c -o printf.o printf.c	
	$(CC) -nostdlib -fno-builtin -g -c -o timer.o timer.c	
	$(CC) -nostdlib -fno-builtin -g -c -o irq.o irq.c	
	$(CC) -nostdlib -fno-builtin -g -c -o adc.o adc.c	
	$(CC) -nostdlib -fno-builtin -g -c -o i2c.o i2c.c	
	$(CC) -nostdlib -fno-builtin -g -c -o spi.o spi.c	

	$(CC) -nostdlib -fno-builtin -g -c -o main.o main.c	
	$(LD) -Tu_boot.lds -g start.o led.o uart.o printf.o timer.o irq.o adc.o i2c.o spi.o main.o -o u_boot_elf  $(PLATFORM_LIBS)
	
	$(OBJCOPY) -O binary -S u_boot_elf u-boot.bin
	$(OBJDUMP) -D  u_boot_elf > u_boot.dis	
clean:
	rm -f u_boot.dis u-boot.bin u_boot_elf *.o u-boot.img trust.img

