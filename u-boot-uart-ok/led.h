#ifndef   __X_LED_H__
#define   __X_LED_H__

/* Rockchip RK3399TRM V1.3 Part1.pdf
 * GRF(P29)
 * FF76_0000 && FF77_0000
 * Chapter 2 System Overview (Address Mapping)
 */

//#define    CRU_BASE                  0xFF760000
//#define    GRF_BASE                  0xFF770000

/* Rockchip RK3399TRM V1.3 Part1.pdf
 * GRF(P29)
 * GPIOX
 * Chapter 2 System Overview (Address Mapping)
 */

//#define    GPIO0_BASE                0xFF720000
//#define    GPIO1_BASE                0xFF730000
//#define    GPIO2_BASE                0xFF780000
//#define    GPIO3_BASE                0xFF788000
//#define    GPIO4_BASE                0xFF790000

void led_init(void);
/* 
 * status 0 : off
 * status 1 : on
 */
void led_ctl(int status);

void led_delay(void);

#endif

