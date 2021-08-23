#include "irq.h"
#include "led.h"
#include "timer.h"
#include "printf.h"
#include "uart.h"


/* Cpu Interface System Registers */
#define ICC_IAR0_EL1		S3_0_C12_C8_0
#define ICC_IAR1_EL1		S3_0_C12_C12_0
#define ICC_EOIR0_EL1		S3_0_C12_C8_1
#define ICC_EOIR1_EL1		S3_0_C12_C12_1
#define ICC_HPPIR0_EL1		S3_0_C12_C8_2
#define ICC_HPPIR1_EL1		S3_0_C12_C12_2
#define ICC_BPR0_EL1		S3_0_C12_C8_3
#define ICC_BPR1_EL1		S3_0_C12_C12_3
#define ICC_DIR_EL1			S3_0_C12_C11_1
#define ICC_PMR_EL1			S3_0_C4_C6_0
#define ICC_RPR_EL1			S3_0_C12_C11_3
#define ICC_CTLR_EL1		S3_0_C12_C12_4
#define ICC_CTLR_EL3		S3_6_C12_C12_4
#define ICC_SRE_EL1			S3_0_C12_C12_5
#define ICC_SRE_EL2			S3_4_C12_C9_5
#define ICC_SRE_EL3			S3_6_C12_C12_5
#define ICC_IGRPEN0_EL1		S3_0_C12_C12_6
#define ICC_IGRPEN1_EL1		S3_0_C12_C12_7
#define ICC_IGRPEN1_EL3		S3_6_C12_C12_7
#define ICC_SEIEN_EL1		S3_0_C12_C13_0
#define ICC_SGI0R_EL1		S3_0_C12_C11_7
#define ICC_SGI1R_EL1		S3_0_C12_C11_5
#define ICC_ASGI1R_EL1		S3_0_C12_C11_6


static struct s_irq_handler g_irq_handler[NR_IRQS];

void irq_init(void)
{
    /* gic has been init in Start.S */
}

void enable_interrupts(void)
{
    my_printf("enable_interrupts \n\r");

    asm volatile("msr	daifclr, #0x03");
}

/* irq interrupt install handle */
void irq_install_handler(int irq, interrupt_handler_t *handler, void *data)
{
    my_printf("irq_install_handler \n\r");

    if (g_irq_handler[irq].m_func != handler)
        g_irq_handler[irq].m_func = handler;
}

/* enable irq handler */
int irq_handler_enable(int irq)
{
    my_printf("irq_handler_enable start \n\r");

    unsigned long M, N;

    if (irq >= NR_GIC_IRQS)
        return -1;

    M = irq / 32;
    N = irq % 32;

    GICD->ISENABLER[M]  = (0x1 << N);
    my_printf("irq_handler_enable end \n\r");

    return 0;
}
/*do_irq*/
void my_do_irq(void)
{
    my_printf("do_irq start \n\r");

    unsigned long nintid;
    unsigned long long irqstat;

    asm volatile("mrs %0, " __stringify(ICC_IAR1_EL1) : "=r" (irqstat));

    nintid = (unsigned long)irqstat & 0x3FF;

    /* here we use gic id checking, not include gpio pin irq */
    if (nintid < NR_GIC_IRQS)
        g_irq_handler[nintid].m_func((void *)(unsigned long)nintid);

    asm volatile("msr " __stringify(ICC_EOIR1_EL1) ", %0" : : "r" ((unsigned long long)nintid));
    asm volatile("msr " __stringify(ICC_DIR_EL1) ", %0" : : "r" ((unsigned long long)nintid));
    isb();
    my_printf("do_irq end \n\r");
	
}

static void board_timer_isr(void)
{
    my_printf("board_timer_isr start \n\r");

    static unsigned char led_flag = 0;
	/* Rockchip RK3399TRM V1.3 Part1.pdf P959
	 * TIMER_n_INTSTATUS 
	 * bit[0] int_pd 
	 * This register contains the interrupt status for timer n. 
	 * Write 1 to this register will clear the interrupt. 
	 */

    TIMER3->INTSTATUS = 0x01;  //clrear interrupt

    if(led_flag == 0)
        led_ctl(0);
    else
        led_ctl(1);

    led_flag = !led_flag;
    my_printf("board_timer_isr end \n\r");
	
}

/* Rockchip RK3399TRM V1.3 Part1.pdf P960
 * TIMER_n_CONTROLREG 
 * Address: Operational Base + offset (0x1c) 
 * Timer n Control Register 
 * bit[2] int_en Timer interrupt mask, 0: mask 1: not mask
 * bit[1] timer_mode Timer mode. 0: free-running mode 1: user-defined count mode 
 * bit[0] timer_en Timer enable. 0: disable 1: enable 
 * (1<<0) + (1<<1) + (1<<2) = 5
 */
 
void test_timer_irq(void)
{
    my_printf("test_timer_irq start \n\r");

    /* enable exceptions */
    enable_interrupts();

    /* timer set */
	
    TIMER3->CURRENT_VALUE0 = 0x0FFFFFF;
    TIMER3->LOAD_COUNT0    = 0x0FFFFFF;
    TIMER3->CONTROL_REG    = 0x05; //auto reload & enable the timer

    /* register and enable */
    irq_install_handler(TIMER_INTR3, (interrupt_handler_t *)board_timer_isr, (void *)(0));
    irq_handler_enable(TIMER_INTR3);
    my_printf("test_timer_irq end \n\r");

}


