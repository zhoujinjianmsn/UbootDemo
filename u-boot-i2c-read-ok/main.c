
#include "led.h"
#include "uart.h"
#include "printf.h"
#include "timer.h"
#include "irq.h"
#include "adc.h"
#include "i2c.h"

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

	uart_test();

	i2c_test();

    test_timer_irq();	

    while(1)
    {
	    led_ctl(1);
	    delay_s(3);

		get_tsadc_temp(0);
		my_printf("get_saradc_val = %d.\n\r", get_saradc_val(0));

	    led_ctl(0);
	    delay_s(3);
    }

    return 0;
}

