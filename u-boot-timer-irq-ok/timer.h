#ifndef   __TIMER_H__
#define   __TIMER_H__

//timer0 to timer5 base addr
/* Rockchip RK3399TRM V1.3 Part1.pdf
 * GRF(P29) FF85_0000(IMER0~5(6ch)) && FF85_8000(IMER6~11(6ch))
 * Chapter 2 System Overview (Address Mapping)
 */

#define  TIMER0_5_BASE              0xFF850000
#define  TIMER6_11_BASE             0xFF858000

//timer0 to timer5 base addr
/* Rockchip RK3399TRM V1.3 Part1.pdf
 * GRF(P958)
 * Chapter 13 Timer
 * 13.4.1 Registers Summary
 */

typedef volatile struct timer_reg
{
    unsigned int LOAD_COUNT0;      	      //0x0000
    unsigned int LOAD_COUNT1;    	      //0x0004
    unsigned int CURRENT_VALUE0;      	  //0x0008
    unsigned int CURRENT_VALUE1	;         //0x000C
    unsigned int LOAD_COUNT2;      	      //0x0010
    unsigned int LOAD_COUNT3;    	      //0x0014
    unsigned int INTSTATUS;          	  //0x0018
    unsigned int CONTROL_REG;             //0x001C
} timer_reg, *p_timer;

#define      TIMER0           ((p_timer)(TIMER0_5_BASE + 0x20 * 0))
#define      TIMER1           ((p_timer)(TIMER0_5_BASE + 0x20 * 1))
#define      TIMER2           ((p_timer)(TIMER0_5_BASE + 0x20 * 2))
#define      TIMER3           ((p_timer)(TIMER0_5_BASE + 0x20 * 3)) //for irq test
#define      TIMER4           ((p_timer)(TIMER0_5_BASE + 0x20 * 4)) //for delay
#define      TIMER5           ((p_timer)(TIMER0_5_BASE + 0x20 * 5))

#define      TIMER6           ((p_timer)(TIMER6_11_BASE + 0x20 * 0))
#define      TIMER7           ((p_timer)(TIMER6_11_BASE + 0x20 * 1))
#define      TIMER8           ((p_timer)(TIMER6_11_BASE + 0x20 * 2))
#define      TIMER9           ((p_timer)(TIMER6_11_BASE + 0x20 * 3))
#define      TIMER10          ((p_timer)(TIMER6_11_BASE + 0x20 * 4))
#define      TIMER11          ((p_timer)(TIMER6_11_BASE + 0x20 * 5))

extern void delay_us(volatile unsigned long int  i);
extern void delay_ms(volatile unsigned long int  i);
extern void delay_s(volatile unsigned long int i);

#endif

