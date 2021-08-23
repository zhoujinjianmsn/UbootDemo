
#include "led.h"
#include "uart.h"
#include "printf.h"

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

    while(1)
    {
	    led_ctl(1);
	    led_delay();

	    led_ctl(0);
	    led_delay();
    }

    return 0;
}

