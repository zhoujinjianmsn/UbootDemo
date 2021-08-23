
#include "led.h"
#include "uart.h"
#include "printf.h"
#include "timer.h"
#include "irq.h"
#include "adc.h"
#include "i2c.h"
#include "spi.h"

void uart_test(void) {
    uart_init();
	printf_test();
    my_printf("uart_init ok. \n\r");
}

void i2c_test(void){
	int i;
	i2c_init();
	
	//write eeprom.
	for(i=0; i<5; i++)
    {
        //eeprom_write(i,2*i);
        delay_ms(4);//Must be delayed more than 4ms.
    }
	
	my_printf("write eeprom ok\n\r");
	delay_ms(10);
	
	//read eeprom.
    for(i=0; i<10; i++)
    {
        my_printf("read_data%d = %d\n\r", i, eeprom_read(i));
        delay_ms(4);
    }
}

int main(void)
{
    led_init();
	led_ctl(0);

	unsigned int i, j;
	char str[20];
	unsigned int mid, pid; 
	
	uart_init();
	my_printf("uart_init ok.\n\r");

    spi_init();
	
	spi_flash_read_ID(&mid, &pid);
	my_printf("SPI Flash : MID = 0x%02x, PID = 0x%02x\n\r", mid, pid);	

    spi_flash_init();
    while(1)
	{
        spi_flash_erase_sector(4096);
        spi_flash_program(4096, "zjj", 7);
        spi_flash_read(4096, str, 7);
        my_printf("SPI Flash read from 4096: %s\n\r", str);
        
        delay_s(2);
    }

	return 0;

}

