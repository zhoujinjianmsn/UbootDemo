
#include "led.h"

int main(void)
{
    led_init();

    while(1)
    {
	    led_ctl(1);
	    led_delay();

	    led_ctl(0);
	    led_delay();
    }

    return 0;
}

