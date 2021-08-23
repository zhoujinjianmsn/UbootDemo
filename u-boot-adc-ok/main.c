
#include "led.h"
#include "uart.h"
#include "printf.h"
#include "timer.h"
#include "irq.h"

void uart_test(void) {
    uart_init();
	printf_test();
    my_printf("uart_init ok. \n\r");
}

int main(void)
{
    led_init();
	led_ctl(0);

	uart_test();

    //test_timer_irq();	

    while(1)
    {
	    led_ctl(1);
	    delay_ms(2);

		get_tsadc_temp(0);
		my_printf("get_saradc_val = %d.\n\r", get_saradc_val(0));

	    led_ctl(0);
	    delay_ms(2);
    }

    return 0;
}

