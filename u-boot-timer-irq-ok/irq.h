#ifndef   __IRQ_H__
#define   __IRQ_H__

#define __stringify_1(x...)	 #x
#define __stringify(x...)	 __stringify_1(x)

#define isb()                ({asm volatile(	"isb" : : : "memory");})

/* total irq */
#define NR_GIC_IRQS          (6 * 32)
#define NR_GPIO_IRQS         (5 * 32)
#define NR_IRQS              (NR_GIC_IRQS + NR_GPIO_IRQS)

/* Interrupt ID */
#define GPIO4_INTR 		     50  // Rockchip RK3399TRM V1.3 Part1.pdf P31
#define TIMER_INTR3 		 116 // Rockchip RK3399TRM V1.3 Part1.pdf P33
#define TSADC_INT  		     129 // Rockchip RK3399TRM V1.3 Part1.pdf P33

/* irq handler struct and hander table */
struct s_irq_handler
{
    void (*m_func)(void *data);
};


typedef void (interrupt_handler_t)(void *);


#define RKIO_GICD_PHYS			0xFEE00000 //GIC DIST //GIC500_BASE

/*DDI0516B_gic5000_r0p0_trm.pdf P42
 *3.3 Distributor register summary
 */
 
/*********************************************************************************************
* 0x00000-0x0FFFF         Distributor registers (GICD_*)
* 0x10000-0x1FFFF         Distributor registers for message-based SPIs (GICD_*)
* 0x20000-0x2FFFF         Interrupt Translation Service control registers (GITS_*)
* 0x30000-0x3FFFF         Interrupt Translation Service register (GITS_TRANSLATER)
*********************************************************************************************/
/* Distributor Registers */
typedef volatile struct gicd_reg
{
    unsigned int CTLR;      	  //0x0000
    unsigned int TYPER;    	      //0x0004
    unsigned int IIDR;      	  //0x0008
    unsigned int RESERVED0[1];    //0x000C
    unsigned int STATUSR;	      //0x0010
    unsigned int RESERVED1[11];   //0x0014 (0x0040 - 0x0014 == 2C(11*4byte))
    unsigned int SETSPI_NSR;      //0x0040
    unsigned int RESERVED2[1];    //0x0044
    unsigned int CLRSPI_NSR;	  //0x0048
    unsigned int RESERVED3[1];    //0x004C
    unsigned int SETSPI_SR;       //0x0050
    unsigned int RESERVED4[1];    //0x0054
    unsigned int CLRSPI_SR;       //0x0058
    unsigned int RESERVED5[3];    //0x005C
    unsigned int SEIR;            //0x0068
    unsigned int RESERVED6[5];    //0x006C
    unsigned int IGROUPR[31];     //0x0080
    unsigned int RESERVED7[1];    //0x00FC
    unsigned int ISENABLER[32];   //0x0100
    unsigned int ICENABLER[32];   //0x0180
    unsigned int ISPENDR[32];     //0x0200
    unsigned int ICPENDR[32];     //0x0280
    unsigned int ISACTIVER[32];   //0x0300
    unsigned int ICACTIVER[32];   //0x0380
    unsigned int IPRIORITYR[256]; //0x0400
    unsigned int ITARGETSR[256];  //0x0800
    unsigned int ICFGR[64];       //0x0c00
    unsigned int IGROUPMODR[64];  //0x0d00
    unsigned int NSACR[64];       //0x0e00
    unsigned int SGIR;            //0x0f00
    unsigned int RESERVED8[3];    //0x0f04
    unsigned int CPENDSGIR[4];    //0x0f10
    unsigned int SPENDSGIR[4];    //0x0f20
    unsigned int RESERVED9[5236]; //0x0f30
    unsigned int IROUTER[1918];   //0x6100
} gicd_reg, *p_gicd;

#define GICD       ((p_gicd)RKIO_GICD_PHYS)

extern void enable_interrupts(void);
extern void irq_install_handler(int irq, interrupt_handler_t *handler, void *data);
extern int irq_handler_enable(int irq);
//F:\Rock4Plus_Android10\u-boot\arch\arm\cpu\armv8\start.S
/*bl	do_irq*/
extern void my_do_irq(void);

extern void test_timer_irq(void);

#endif
