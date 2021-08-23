/* Rockchip RK3399TRM V1.3 Part1.pdf
 * GRF_GPIO3D_IOMUX(P323)
 * Address: Operational Base + offset (0x0e01c) 
 * GPIO3D iomux control
 */

/* rockpi4_v13_sch_20181112.pdf
 * USER_LED1 GPIO3_D4 High_level_on
 * USER_LED2 GPIO3_D5 High_level_on
 */

#include "led.h"

/* Rockchip RK3399TRM V1.3 Part1.pdf
 * CRU_CLKGATE_CON31 
 * Address: Operational Base + offset (0x037c) 
 * Internal clock gating register31 
*/
static volatile unsigned int *CRU_CLKGATE_CON31;

/* Rockchip RK3399TRM V1.3 Part1.pdf
 * GRF_GPIO3D_IOMUX(P323)
 * Address: Operational Base + offset (0x0e01c) 
 * GPIO3D iomux control
 */
static volatile unsigned int *GRF_GPIO3D_IOMUX;

static volatile unsigned int *GPIO3_SWPORTA_DR;

static volatile unsigned int *GPIO3_SWPORTA_DDR;


void led_init()
{
	CRU_CLKGATE_CON31 = (volatile unsigned int *)(0xFF760000 + 0x037c);
	GRF_GPIO3D_IOMUX  = (volatile unsigned int *)(0xFF770000 + 0x0e01c);
	GPIO3_SWPORTA_DR  = (volatile unsigned int *)(0xFF788000 + 0x0000);
	GPIO3_SWPORTA_DDR = (volatile unsigned int *)(0xFF788000 + 0x0004);

	/* a. 使能GPIO3
	 * set CRU to enable GPIO3
	 * CRU_CLKGATE_CON31 0xFF760000 + 0x037c
	 * (1<<(4+16)) | (0<<4)
	 */
	*CRU_CLKGATE_CON31 = (1<<(4+16)) | (0<<4);

	/* b. 设置GPIO3_D4用于GPIO
	 * set PMU/GRF to configure GPIO3_D4 as GPIO
	 * GRF_GPIO3D_IOMUX 0xFF770000 + 0x0e01c
	 * bit[9:8] = 0b00
	 * (3<<(8+16)) | (0<<8)
	 */
	//*GRF_GPIO3D_IOMUX = (3<<(8+16)) | (0<<8);

	/* b. 设置GPIO3_D5用于GPIO
	 * set PMU/GRF to configure GPIO3_D5 as GPIO
	 * GRF_GPIO3D_IOMUX 0xFF770000 + 0x0e01c
	 * bit[11:10] = 0b00
	 * (3<<(10+16)) | (0<<10)
	 */
	*GRF_GPIO3D_IOMUX = (3<<(10+16)) | (0<<10);

	/* c. 设置GPIO3_D4作为output引脚(3*8+4)
	 * set GPIO_SWPORTA_DDR to configure GPIO3_D4 as output
	 * GPIO_SWPORTA_DDR 0xFF788000 + 0x0004
	 * bit[28] = 0b1
	 */ 
	//*GPIO3_SWPORTA_DDR |= (1<<28);

	/* c. 设置GPIO3_D5作为output引脚(3*8+5)
	 * set GPIO_SWPORTA_DDR to configure GPIO3_D5 as output
	 * GPIO3_SWPORTA_DDR 0xFF788000 + 0x0004
	 * bit[29] = 0b1
	 */
	*GPIO3_SWPORTA_DDR |= (1<<29);

}

/* 
 * mode 0 : off
 * mode 1 : on
 */
void led_ctl(int status)
{
	if(status) 
	{
		/* d. 设置GPIO3_D4/GPIO3_D5输出高电平
		 * set GPIO3_SWPORTA_DR to configure GPIO3_D4/GPIO3_D5 output 1
		 * GPIO3_SWPORTA_DR 0xFF780000 + 0x0000
		 * bit[28] = 0b1
		 * bit[29] = 0b1
		 */ 
		//*GPIO3_SWPORTA_DR |= (1<<28);
		*GPIO3_SWPORTA_DR |= (1<<29);		
	} 
	else
	{
		/* e. 设置GPIO3_D4/GPIO3_D5输出低电平
		 * set GPIO3_SWPORTA_DR to configure GPIO3_D4/GPIO3_D5 output 0
		 * GPIO3_SWPORTA_DR 0xFF780000 + 0x0000
		 * bit[28] = 0b0
		 * bit[29] = 0b0
		 */ 	
		//*GPIO3_SWPORTA_DR &= ~(1<<28);
		*GPIO3_SWPORTA_DR &= ~(1<<29);	
	}
}

void led_delay(void)
{
    volatile unsigned long int i, j;
    for(i = 0; i < 10; i++) 
	{
	    for(j = 0; j < 100000; j++);
	}
}

