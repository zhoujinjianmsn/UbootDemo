/*
 * (C) Copyright 2013
 * David Feng <fenghua@phytium.com.cn>
 * F:\Rock4Plus_Android10\u-boot\arch\arm\cpu\armv8\start.S
 * SPDX-License-Identifier:	GPL-2.0+
 */

//#include <asm-offsets.h>
#define GENERATED_GBL_DATA_SIZE 464 /* (sizeof(struct global_data) + 15) & ~15	// */
#define GENERATED_BD_INFO_SIZE 336 /* (sizeof(struct bd_info) + 15) & ~15	// */
#define GD_SIZE 456 /* sizeof(struct global_data)	// */
#define GD_BD 0 /* offsetof(struct global_data, bd)	// */
#define GD_MALLOC_BASE 280 /* offsetof(struct global_data, malloc_base)	// */
#define GD_RELOCADDR 96 /* offsetof(struct global_data, relocaddr)	// */
#define GD_RELOC_OFF 136 /* offsetof(struct global_data, reloc_off)	// */
#define GD_START_ADDR_SP 128 /* offsetof(struct global_data, start_addr_sp)	// */
#define PM_CTX_SIZE 136 /* sizeof(struct pm_ctx)	// */
#define PM_CTX_PHYS 408 /* offsetof(struct global_data, pm_ctx_phys)	// */
#define GD_NEW_GD 144 /* offsetof(struct global_data, new_gd)	// */


//#include <config.h>
/*F:\Rock4Plus_Android10\u-boot\include\configs\rk3399_common.h*/
#define CONFIG_SYS_TEXT_BASE		0x00200000
#define CONFIG_SYS_INIT_SP_ADDR		0x00400000

#define GICD_BASE			0xFEE00000
#define GICR_BASE			0xFEF00000



//#include <asm/macro.h>

/*F:\Rock4Plus_Android10\u-boot\arch\arm\include\asm\macro.h start*/

/*
 * These macros provide a convenient way to write 8, 16 and 32 bit data
 * to any address.
 * Registers r4 and r5 are used, any data in these registers are
 * overwritten by the macros.
 * The macros are valid for any ARM architecture, they do not implement
 * any memory barriers so caution is recommended when using these when the
 * caches are enabled or on a multi-core system.
 */

.macro	write32, addr, data
	ldr	r4, =\addr
	ldr	r5, =\data
	str	r5, [r4]
.endm

.macro	write16, addr, data
	ldr	r4, =\addr
	ldrh	r5, =\data
	strh	r5, [r4]
.endm

.macro	write8, addr, data
	ldr	r4, =\addr
	ldrb	r5, =\data
	strb	r5, [r4]
.endm

/*
 * This macro generates a loop that can be used for delays in the code.
 * Register r4 is used, any data in this register is overwritten by the
 * macro.
 * The macro is valid for any ARM architeture. The actual time spent in the
 * loop will vary from CPU to CPU though.
 */

.macro	wait_timer, time
	ldr	r4, =\time
1:
	nop
	subs	r4, r4, #1
	bcs	1b
.endm

/*
 * Register aliases.
 */
lr	.req	x30

/*
 * Branch according to exception level
 */
.macro	switch_el, xreg, el3_label, el2_label, el1_label
	mrs	\xreg, CurrentEL
	cmp	\xreg, 0xc
	b.eq	\el3_label
	cmp	\xreg, 0x8
	b.eq	\el2_label
	cmp	\xreg, 0x4
	b.eq	\el1_label
.endm

/*
 * Branch if current processor is a Cortex-A35 core.
 */
.macro	branch_if_a35_core, xreg, a35_label
	mrs	\xreg, midr_el1
	lsr	\xreg, \xreg, #4
	and	\xreg, \xreg, #0x00000FFF
	cmp	\xreg, #0xD04		/* Cortex-A35 MPCore processor. */
	b.eq	\a35_label
.endm

/*
 * Branch if current processor is a Cortex-A57 core.
 */
.macro	branch_if_a57_core, xreg, a57_label
	mrs	\xreg, midr_el1
	lsr	\xreg, \xreg, #4
	and	\xreg, \xreg, #0x00000FFF
	cmp	\xreg, #0xD07		/* Cortex-A57 MPCore processor. */
	b.eq	\a57_label
.endm

/*
 * Branch if current processor is a Cortex-A53 core.
 */
.macro	branch_if_a53_core, xreg, a53_label
	mrs	\xreg, midr_el1
	lsr	\xreg, \xreg, #4
	and	\xreg, \xreg, #0x00000FFF
	cmp	\xreg, #0xD03		/* Cortex-A53 MPCore processor. */
	b.eq	\a53_label
.endm

/*
 * Branch if current processor is a slave,
 * choose processor with all zero affinity value as the master.
 */
.macro	branch_if_slave, xreg, slave_label
.endm

/*
 * Branch if current processor is a master,
 * choose processor with all zero affinity value as the master.
 */
.macro	branch_if_master, xreg1, xreg2, master_label
	b 	\master_label
.endm

/*
 * Switch from EL3 to EL2 for ARMv8
 * @ep:     kernel entry point
 * @flag:   The execution state flag for lower exception
 *          level, ES_TO_AARCH64 or ES_TO_AARCH32
 * @tmp:    temporary register
 *
 * For loading 32-bit OS, x1 is machine nr and x2 is ftaddr.
 * For loading 64-bit OS, x0 is physical address to the FDT blob.
 * They will be passed to the guest.
 */
.macro armv8_switch_to_el2_m, ep, flag, tmp
	msr	cptr_el3, xzr		/* Disable coprocessor traps to EL3 */
	mov	\tmp, #CPTR_EL2_RES1
	msr	cptr_el2, \tmp		/* Disable coprocessor traps to EL2 */

	/* Initialize Generic Timers */
	msr	cntvoff_el2, xzr

	/* Initialize SCTLR_EL2
	 *
	 * setting RES1 bits (29,28,23,22,18,16,11,5,4) to 1
	 * and RES0 bits (31,30,27,26,24,21,20,17,15-13,10-6) +
	 * EE,WXN,I,SA,C,A,M to 0
	 */
	ldr	\tmp, =(SCTLR_EL2_RES1 | SCTLR_EL2_EE_LE |\
			SCTLR_EL2_WXN_DIS | SCTLR_EL2_ICACHE_DIS |\
			SCTLR_EL2_SA_DIS | SCTLR_EL2_DCACHE_DIS |\
			SCTLR_EL2_ALIGN_DIS | SCTLR_EL2_MMU_DIS)
	msr	sctlr_el2, \tmp

	mov	\tmp, sp
	msr	sp_el2, \tmp		/* Migrate SP */
	mrs	\tmp, vbar_el3
	msr	vbar_el2, \tmp		/* Migrate VBAR */

	/* Check switch to AArch64 EL2 or AArch32 Hypervisor mode */
	cmp	\flag, #ES_TO_AARCH32
	b.eq	1f

	/*
	 * The next lower exception level is AArch64, 64bit EL2 | HCE |
	 * RES1 (Bits[5:4]) | Non-secure EL0/EL1.
	 * and the SMD depends on requirements.
	 */
	ldr	\tmp, =(SCR_EL3_RW_AARCH64 | SCR_EL3_HCE_EN |\
			SCR_EL3_SMD_DIS | SCR_EL3_RES1 |\
			SCR_EL3_NS_EN)
	msr	scr_el3, \tmp

	/* Return to the EL2_SP2 mode from EL3 */
	ldr	\tmp, =(SPSR_EL_DEBUG_MASK | SPSR_EL_SERR_MASK |\
			SPSR_EL_IRQ_MASK | SPSR_EL_FIQ_MASK |\
			SPSR_EL_M_AARCH64 | SPSR_EL_M_EL2H)
	msr	spsr_el3, \tmp
	msr	elr_el3, \ep
	eret

1:
	/*
	 * The next lower exception level is AArch32, 32bit EL2 | HCE |
	 * SMD | RES1 (Bits[5:4]) | Non-secure EL0/EL1.
	 */
	ldr	\tmp, =(SCR_EL3_RW_AARCH32 | SCR_EL3_HCE_EN |\
			SCR_EL3_SMD_DIS | SCR_EL3_RES1 |\
			SCR_EL3_NS_EN)
	msr	scr_el3, \tmp

	/* Return to AArch32 Hypervisor mode */
	ldr     \tmp, =(SPSR_EL_END_LE | SPSR_EL_ASYN_MASK |\
			SPSR_EL_IRQ_MASK | SPSR_EL_FIQ_MASK |\
			SPSR_EL_T_A32 | SPSR_EL_M_AARCH32 |\
			SPSR_EL_M_HYP)
	msr	spsr_el3, \tmp
	msr     elr_el3, \ep
	eret
.endm

/*
 * Switch from EL2 to EL1 for ARMv8
 * @ep:     kernel entry point
 * @flag:   The execution state flag for lower exception
 *          level, ES_TO_AARCH64 or ES_TO_AARCH32
 * @tmp:    temporary register
 *
 * For loading 32-bit OS, x1 is machine nr and x2 is ftaddr.
 * For loading 64-bit OS, x0 is physical address to the FDT blob.
 * They will be passed to the guest.
 */
.macro armv8_switch_to_el1_m, ep, flag, tmp
	/* Initialize Generic Timers */
	mrs	\tmp, cnthctl_el2
	/* Enable EL1 access to timers */
	orr	\tmp, \tmp, #(CNTHCTL_EL2_EL1PCEN_EN |\
		CNTHCTL_EL2_EL1PCTEN_EN)
	msr	cnthctl_el2, \tmp
	msr	cntvoff_el2, xzr

	/* Initilize MPID/MPIDR registers */
	mrs	\tmp, midr_el1
	msr	vpidr_el2, \tmp
	mrs	\tmp, mpidr_el1
	msr	vmpidr_el2, \tmp

	/* Disable coprocessor traps */
	mov	\tmp, #CPTR_EL2_RES1
	msr	cptr_el2, \tmp		/* Disable coprocessor traps to EL2 */
	msr	hstr_el2, xzr		/* Disable coprocessor traps to EL2 */
	mov	\tmp, #CPACR_EL1_FPEN_EN
	msr	cpacr_el1, \tmp		/* Enable FP/SIMD at EL1 */

	/* SCTLR_EL1 initialization
	 *
	 * setting RES1 bits (29,28,23,22,20,11) to 1
	 * and RES0 bits (31,30,27,21,17,13,10,6) +
	 * UCI,EE,EOE,WXN,nTWE,nTWI,UCT,DZE,I,UMA,SED,ITD,
	 * CP15BEN,SA0,SA,C,A,M to 0
	 */
	ldr	\tmp, =(SCTLR_EL1_RES1 | SCTLR_EL1_UCI_DIS |\
			SCTLR_EL1_EE_LE | SCTLR_EL1_WXN_DIS |\
			SCTLR_EL1_NTWE_DIS | SCTLR_EL1_NTWI_DIS |\
			SCTLR_EL1_UCT_DIS | SCTLR_EL1_DZE_DIS |\
			SCTLR_EL1_ICACHE_DIS | SCTLR_EL1_UMA_DIS |\
			SCTLR_EL1_SED_EN | SCTLR_EL1_ITD_EN |\
			SCTLR_EL1_CP15BEN_DIS | SCTLR_EL1_SA0_DIS |\
			SCTLR_EL1_SA_DIS | SCTLR_EL1_DCACHE_DIS |\
			SCTLR_EL1_ALIGN_DIS | SCTLR_EL1_MMU_DIS)
	msr	sctlr_el1, \tmp

	mov	\tmp, sp
	msr	sp_el1, \tmp		/* Migrate SP */
	mrs	\tmp, vbar_el2
	msr	vbar_el1, \tmp		/* Migrate VBAR */

	/* Check switch to AArch64 EL1 or AArch32 Supervisor mode */
	cmp	\flag, #ES_TO_AARCH32
	b.eq	1f

	/* Initialize HCR_EL2 */
	ldr	\tmp, =(HCR_EL2_RW_AARCH64 | HCR_EL2_HCD_DIS)
	msr	hcr_el2, \tmp

	/* Return to the EL1_SP1 mode from EL2 */
	ldr	\tmp, =(SPSR_EL_DEBUG_MASK | SPSR_EL_SERR_MASK |\
			SPSR_EL_IRQ_MASK | SPSR_EL_FIQ_MASK |\
			SPSR_EL_M_AARCH64 | SPSR_EL_M_EL1H)
	msr	spsr_el2, \tmp
	msr     elr_el2, \ep
	eret

1:
	/* Initialize HCR_EL2 */
	ldr	\tmp, =(HCR_EL2_RW_AARCH32 | HCR_EL2_HCD_DIS)
	msr	hcr_el2, \tmp

	/* Return to AArch32 Supervisor mode from EL2 */
	ldr	\tmp, =(SPSR_EL_END_LE | SPSR_EL_ASYN_MASK |\
			SPSR_EL_IRQ_MASK | SPSR_EL_FIQ_MASK |\
			SPSR_EL_T_A32 | SPSR_EL_M_AARCH32 |\
			SPSR_EL_M_SVC)
	msr     spsr_el2, \tmp
	msr     elr_el2, \ep
	eret
.endm

.macro gic_wait_for_interrupt_m xreg1
0 :	wfi
	mrs     \xreg1, ICC_IAR1_EL1
	msr     ICC_EOIR1_EL1, \xreg1
	cbnz    \xreg1, 0b
.endm


/*F:\Rock4Plus_Android10\u-boot\arch\arm\include\asm\macro.h end*/

//#include <asm/armv8/mmu.h>

/* #include <linux/linkage.h> start*/

#define STT_FUNC 2 /* elf.h */

#define ASM_NL ;

#define SYMBOL_NAME(X)		X
#define SYMBOL_NAME_LABEL(X)	X:
#define __ALIGN .align 0
#define __ALIGN_STR ".align 0"
#define ALIGN			__ALIGN
#define ALIGN_STR		__ALIGN_STR

#define LENTRY(name) \
	ALIGN ASM_NL \
	SYMBOL_NAME_LABEL(name)

#define ENTRY(name) \
	.globl SYMBOL_NAME(name) ASM_NL \
	LENTRY(name)

#define WEAK(name) \
	.weak SYMBOL_NAME(name) ASM_NL \
	LENTRY(name)

#define END(name) \
	.size name, .-name

#define ENDPROC(name) \
	.type name STT_FUNC ASM_NL \
	END(name)

/* #include <linux/linkage.h> end*/


/*************************************************************************
 *
 * Startup Code (reset vector)
 *
 *************************************************************************/

.globl	_start
_start:
	b	reset
	.align 3

.globl	_TEXT_BASE
_TEXT_BASE:
	.quad	CONFIG_SYS_TEXT_BASE

/*
 * These are defined in the linker script.
 */
.globl	_end_ofs
_end_ofs:
	.quad	_end - _start

.globl	_bss_start_ofs
_bss_start_ofs:
	.quad	__bss_start - _start

.globl	_bss_end_ofs
_bss_end_ofs:
	.quad	__bss_end - _start

reset:
	/* Allow the board to save important registers */
	b	save_boot_params
.globl	save_boot_params_ret
save_boot_params_ret:
	/*
	 * Could be EL3/EL2/EL1, Initial State:
	 * Little Endian, MMU Disabled, i/dCache Disabled
	 */
	adr	x0, vectors
	switch_el x1, 3f, 2f, 1f
3:	msr	vbar_el3, x0
	mrs	x0, scr_el3
	orr	x0, x0, #0xf			/* SCR_EL3.NS|IRQ|FIQ|EA */
	msr	scr_el3, x0
	msr	cptr_el3, xzr			/* Enable FP/SIMD */
	/* COUNTER_FREQUENCY 24000000 \u-boot\include\configs\rockchip-common.h */
	ldr	x0, =24000000
	msr	cntfrq_el0, x0			/* Initialize CNTFRQ */
	b	0f
2:	msr	vbar_el2, x0
	mov	x0, #0x33ff
	msr	cptr_el2, x0			/* Enable FP/SIMD */
	b	0f
1:	msr	vbar_el1, x0
	mov	x0, #3 << 20
	msr	cpacr_el1, x0			/* Enable FP/SIMD */
0:

	/*
	 * Enable SMPEN bit for coherency.
	 * This register is not architectural but at the moment
	 * this bit should be set for A53/A57/A72.
	 */
	switch_el x1, 3f, 1f, 1f
3:
	mrs     x0, S3_1_c15_c2_1               /* cpuectlr_el1 */
	orr     x0, x0, #0x40
	msr     S3_1_c15_c2_1, x0
1:

	/* Apply ARM core specific erratas */
	bl	apply_core_errata

	/*
	 * Cache/BPB/TLB Invalidate
	 * i-cache is invalidated before enabled in icache_enable()
	 * tlb is invalidated before mmu is enabled in dcache_enable()
	 * d-cache is invalidated before enabled in dcache_enable()
	 */

	/* Processor specific initialization */
	bl	lowlevel_init 
master_cpu:
	bl	_main
 
/*-----------------------------------------------------------------------*/

WEAK(apply_core_errata)

	mov	x29, lr			/* Save LR */
	/* For now, we support Cortex-A57 specific errata only */

	/* Check if we are running on a Cortex-A57 core */
	branch_if_a57_core x0, apply_a57_core_errata
0:
	mov	lr, x29			/* Restore LR */
	ret

apply_a57_core_errata:
	b 0b
ENDPROC(apply_core_errata)

/*-----------------------------------------------------------------------*/

WEAK(lowlevel_init)
	mov	x29, lr			/* Save LR */
 	branch_if_slave x0, 1f
	ldr	x0, =GICD_BASE
	bl	gic_init_secure
1:
 	ldr	x0, =GICR_BASE
	bl	gic_init_secure_percpu
 
 	/*
	 * Setting HCR_EL2.TGE AMO IMO FMO for exception rounting to EL2
	 */
	mrs	x0, CurrentEL		/* check currentEL */
	cmp	x0, 0x8
	b.ne	end			/* currentEL != EL2 */

	mrs	x9, hcr_el2
	orr	x9, x9, #(7 << 3)	/* HCR_EL2.AMO IMO FMO set */
	orr	x9, x9, #(1 << 27)	/* HCR_EL2.TGE set */
	msr	hcr_el2, x9

end:
	nop

2:
	mov	lr, x29			/* Restore LR */
	ret
ENDPROC(lowlevel_init)

WEAK(smp_kick_all_cpus)
	/* Kick secondary cpus up by SGI 0 interrupt */
 	ldr	x0, =GICD_BASE
	b	gic_kick_secondary_cpus
 	ret
ENDPROC(smp_kick_all_cpus)

/*-----------------------------------------------------------------------*/

ENTRY(c_runtime_cpu_setup)
	/* Relocate vBAR */
	adr	x0, vectors
	switch_el x1, 3f, 2f, 1f
3:	msr	vbar_el3, x0
	b	0f
2:	msr	vbar_el2, x0
	b	0f
1:	msr	vbar_el1, x0
0:

	ret
ENDPROC(c_runtime_cpu_setup)

WEAK(save_boot_params)
	b	save_boot_params_ret	/* back to my caller */
ENDPROC(save_boot_params) 

/*F:\Rock4Plus_Android10\u-boot\arch\arm\lib\gic_64.S*/
/*F:\Rock4Plus_Android10\u-boot\arch\arm\include\asm\gic.h*/
/* Register offsets for the ARM generic interrupt controller (GIC) */

#define GIC_DIST_OFFSET		0x1000
#define GIC_CPU_OFFSET_A9	0x0100
#define GIC_CPU_OFFSET_A15	0x2000

/* Distributor Registers */
#define GICD_CTLR		0x0000
#define GICD_TYPER		0x0004
#define GICD_IIDR		0x0008
#define GICD_STATUSR		0x0010
#define GICD_SETSPI_NSR		0x0040
#define GICD_CLRSPI_NSR		0x0048
#define GICD_SETSPI_SR		0x0050
#define GICD_CLRSPI_SR		0x0058
#define GICD_SEIR		0x0068
#define GICD_IGROUPRn		0x0080
#define GICD_ISENABLERn		0x0100
#define GICD_ICENABLERn		0x0180
#define GICD_ISPENDRn		0x0200
#define GICD_ICPENDRn		0x0280
#define GICD_ISACTIVERn		0x0300
#define GICD_ICACTIVERn		0x0380
#define GICD_IPRIORITYRn	0x0400
#define GICD_ITARGETSRn		0x0800
#define GICD_ICFGR		0x0c00
#define GICD_IGROUPMODRn	0x0d00
#define GICD_NSACRn		0x0e00
#define GICD_SGIR		0x0f00
#define GICD_CPENDSGIRn		0x0f10
#define GICD_SPENDSGIRn		0x0f20
#define GICD_IROUTERn		0x6000

/* Cpu Interface Memory Mapped Registers */
#define GICC_CTLR		0x0000
#define GICC_PMR		0x0004
#define GICC_BPR		0x0008
#define GICC_IAR		0x000C
#define GICC_EOIR		0x0010
#define GICC_RPR		0x0014
#define GICC_HPPIR		0x0018
#define GICC_ABPR		0x001c
#define GICC_AIAR		0x0020
#define GICC_AEOIR		0x0024
#define GICC_AHPPIR		0x0028
#define GICC_APRn		0x00d0
#define GICC_NSAPRn		0x00e0
#define GICC_IIDR		0x00fc
#define GICC_DIR		0x1000

/* ReDistributor Registers for Control and Physical LPIs */
#define GICR_CTLR		0x0000
#define GICR_IIDR		0x0004
#define GICR_TYPER		0x0008
#define GICR_STATUSR		0x0010
#define GICR_WAKER		0x0014
#define GICR_SETLPIR		0x0040
#define GICR_CLRLPIR		0x0048
#define GICR_SEIR		0x0068
#define GICR_PROPBASER		0x0070
#define GICR_PENDBASER		0x0078
#define GICR_INVLPIR		0x00a0
#define GICR_INVALLR		0x00b0
#define GICR_SYNCR		0x00c0
#define GICR_MOVLPIR		0x0100
#define GICR_MOVALLR		0x0110

/* ReDistributor Registers for SGIs and PPIs */
#define GICR_IGROUPRn		0x0080
#define GICR_ISENABLERn		0x0100
#define GICR_ICENABLERn		0x0180
#define GICR_ISPENDRn		0x0200
#define GICR_ICPENDRn		0x0280
#define GICR_ISACTIVERn		0x0300
#define GICR_ICACTIVERn		0x0380
#define GICR_IPRIORITYRn	0x0400
#define GICR_ICFGR0		0x0c00
#define GICR_ICFGR1		0x0c04
#define GICR_IGROUPMODRn	0x0d00
#define GICR_NSACRn		0x0e00

/* Cpu Interface System Registers */
#define ICC_IAR0_EL1		S3_0_C12_C8_0
#define ICC_IAR1_EL1		S3_0_C12_C12_0
#define ICC_EOIR0_EL1		S3_0_C12_C8_1
#define ICC_EOIR1_EL1		S3_0_C12_C12_1
#define ICC_HPPIR0_EL1		S3_0_C12_C8_2
#define ICC_HPPIR1_EL1		S3_0_C12_C12_2
#define ICC_BPR0_EL1		S3_0_C12_C8_3
#define ICC_BPR1_EL1		S3_0_C12_C12_3
#define ICC_DIR_EL1		S3_0_C12_C11_1
#define ICC_PMR_EL1		S3_0_C4_C6_0
#define ICC_RPR_EL1		S3_0_C12_C11_3
#define ICC_CTLR_EL1		S3_0_C12_C12_4
#define ICC_CTLR_EL3		S3_6_C12_C12_4
#define ICC_SRE_EL1		S3_0_C12_C12_5
#define ICC_SRE_EL2		S3_4_C12_C9_5
#define ICC_SRE_EL3		S3_6_C12_C12_5
#define ICC_IGRPEN0_EL1		S3_0_C12_C12_6
#define ICC_IGRPEN1_EL1		S3_0_C12_C12_7
#define ICC_IGRPEN1_EL3		S3_6_C12_C12_7
#define ICC_SEIEN_EL1		S3_0_C12_C13_0
#define ICC_SGI0R_EL1		S3_0_C12_C11_7
#define ICC_SGI1R_EL1		S3_0_C12_C11_5
#define ICC_ASGI1R_EL1		S3_0_C12_C11_6


/*************************************************************************
 *
 * void gic_init_secure(DistributorBase);
 *
 * Initialize secure copy of GIC at EL3.
 *
 *************************************************************************/
ENTRY(gic_init_secure)
	/*
	 * Initialize Distributor
	 * x0: Distributor Base
	 */
 	mov	w9, #0x37		/* EnableGrp0 | EnableGrp1NS */
					/* EnableGrp1S | ARE_S | ARE_NS */
	str	w9, [x0, GICD_CTLR]	/* Secure GICD_CTLR */
	ldr	w9, [x0, GICD_TYPER]
	and	w10, w9, #0x1f		/* ITLinesNumber */
	cbz	w10, 1f			/* No SPIs */
	add	x11, x0, (GICD_IGROUPRn + 4)
	add	x12, x0, (GICD_IGROUPMODRn + 4)
	mov	w9, #~0
0:	str	w9, [x11], #0x4
	str	wzr, [x12], #0x4	/* Config SPIs as Group1NS */
	sub	w10, w10, #0x1
	cbnz	w10, 0b
 
1:
	ret
ENDPROC(gic_init_secure)


/************************************************************************* 
 * For Gicv3:
 * void gic_init_secure_percpu(ReDistributorBase);
 *
 * Initialize secure copy of GIC at EL3.
 *
 *************************************************************************/
ENTRY(gic_init_secure_percpu)
 	/*
	 * Initialize ReDistributor
	 * x0: ReDistributor Base
	 */
	mrs	x10, mpidr_el1
	lsr	x9, x10, #32
	bfi	x10, x9, #24, #8	/* w10 is aff3:aff2:aff1:aff0 */
	mov	x9, x0
1:	ldr	x11, [x9, GICR_TYPER]
	lsr	x11, x11, #32		/* w11 is aff3:aff2:aff1:aff0 */
	cmp	w10, w11
	b.eq	2f
	add	x9, x9, #(2 << 16)
	b	1b

	/* x9: ReDistributor Base Address of Current CPU */
2:	mov	w10, #~0x2
	ldr	w11, [x9, GICR_WAKER]
	and	w11, w11, w10		/* Clear ProcessorSleep */
	str	w11, [x9, GICR_WAKER]
	dsb	st
	isb
3:	ldr	w10, [x9, GICR_WAKER]
	tbnz	w10, #2, 3b		/* Wait Children be Alive */

	add	x10, x9, #(1 << 16)	/* SGI_Base */
	mov	w11, #~0
	str	w11, [x10, GICR_IGROUPRn]
	str	wzr, [x10, GICR_IGROUPMODRn]	/* SGIs|PPIs Group1NS */
	mov	w11, #0x1		/* Enable SGI 0 */
	str	w11, [x10, GICR_ISENABLERn]

 	/* Rockchip: check elx */
	switch_el x0, el3_sre, el2_sre, el1_sre

	/* Initialize Cpu Interface */
el3_sre:
	mrs	x10, ICC_SRE_EL3
	orr	x10, x10, #0xf		/* SRE & Disable IRQ/FIQ Bypass & */
					/* Allow EL2 access to ICC_SRE_EL2 */
	msr	ICC_SRE_EL3, x10
	isb

el2_sre:
	mrs	x10, ICC_SRE_EL2
	orr	x10, x10, #0xf		/* SRE & Disable IRQ/FIQ Bypass & */
					/* Allow EL1 access to ICC_SRE_EL1 */
	msr	ICC_SRE_EL2, x10
	isb

el1_sre:
	mrs	x0, CurrentEL		/* check currentEL */
	cmp	x0, 0xC
	b.ne	el1_ctlr		/* currentEL != EL3 */

el3_ctlr:
	mov	x10, #0x3		/* EnableGrp1NS | EnableGrp1S */
	msr	ICC_IGRPEN1_EL3, x10
	isb

	msr	ICC_CTLR_EL3, xzr
	isb

el1_ctlr:
	mov	x10, #0x3		/* EnableGrp1NS | EnableGrp1S */
	msr	ICC_IGRPEN1_EL1, x10
	isb

	msr	ICC_CTLR_EL1, xzr	/* NonSecure ICC_CTLR_EL1 */
	isb

	mov	x10, #0xf0		/* Non-Secure access to ICC_PMR_EL1 */
	msr	ICC_PMR_EL1, x10
	isb
 
	ret
ENDPROC(gic_init_secure_percpu)


/************************************************************************* 
 * For Gicv3:
 * void gic_kick_secondary_cpus(void);
 *
 *************************************************************************/
ENTRY(gic_kick_secondary_cpus)
 	mov	x9, #(1 << 40)
	msr	ICC_ASGI1R_EL1, x9
	isb
	ret
ENDPROC(gic_kick_secondary_cpus)

 
/*F:\Rock4Plus_Android10\u-boot\arch\arm\cpu\armv8\exceptions.S*/

/*
 * Exception vectors.
 */
	.align	11
	.globl	vectors
vectors:
	.align	7		/* Current EL Synchronous Thread */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	/*bl	do_bad_sync*/
	b	exception_exit

	.align	7		/* Current EL IRQ Thread */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	/*bl	do_bad_irq*/
	b	exception_exit

	.align	7		/* Current EL FIQ Thread */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	/*bl	do_bad_fiq*/
	b	exception_exit

	.align	7		/* Current EL Error Thread */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	/*bl	do_bad_error*/
	b	exception_exit

	.align	7		 /* Current EL Synchronous Handler */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	/*bl	do_sync*/
	b	exception_exit

	.align	7		 /* Current EL IRQ Handler */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	//bl	do_irq
	//bl	board_init_f_init_reserve
	b	exception_exit

	.align	7		 /* Current EL FIQ Handler */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	/*bl	do_fiq*/
	b	exception_exit

	.align	7		 /* Current EL Error Handler */
	stp	x29, x30, [sp, #-16]!
	bl	_exception_entry
	/*bl	do_error*/
	b	exception_exit

/*
 * Enter Exception.
 * This will save the processor state that is ELR/X0~X30
 * to the stack frame.
 */
_exception_entry:
	stp	x27, x28, [sp, #-16]!
	stp	x25, x26, [sp, #-16]!
	stp	x23, x24, [sp, #-16]!
	stp	x21, x22, [sp, #-16]!
	stp	x19, x20, [sp, #-16]!
	stp	x17, x18, [sp, #-16]!
	stp	x15, x16, [sp, #-16]!
	stp	x13, x14, [sp, #-16]!
	stp	x11, x12, [sp, #-16]!
	stp	x9, x10, [sp, #-16]!
	stp	x7, x8, [sp, #-16]!
	stp	x5, x6, [sp, #-16]!
	stp	x3, x4, [sp, #-16]!
	stp	x1, x2, [sp, #-16]!

	/* Could be running at EL3/EL2/EL1 */
	switch_el x11, 3f, 2f, 1f
3:	mrs	x1, esr_el3
	mrs	x2, elr_el3
	mrs	x3, daif
	mrs	x4, vbar_el3
	mrs	x5, spsr_el3
	sub	x6, sp, #(8*30)
	mrs	x7, sctlr_el3
	mrs	x8, scr_el3
	mrs	x9, ttbr0_el3
	b	0f
2:	mrs	x1, esr_el2
	mrs	x2, elr_el2
	mrs	x3, daif
	mrs	x4, vbar_el2
	mrs	x5, spsr_el2
	sub	x6, sp, #(8*30)
	mrs	x7, sctlr_el2
	mrs	x8, hcr_el2
	mrs	x9, ttbr0_el2
	b	0f

1:	mrs	x1, esr_el1
	mrs	x2, elr_el1
	mrs	x3, daif
	mrs	x4, vbar_el1
	mrs	x5, spsr_el1
	sub	x6, sp, #(8*30)
	mrs	x7, sctlr_el1
	mov	x8, #0
	mrs	x9, ttbr0_el1
0:
	stp     x2, x0, [sp, #-16]!
	stp	x3, x1, [sp, #-16]!
	stp	x5, x4, [sp, #-16]!
	stp	x7, x6, [sp, #-16]!
	stp	x9, x8, [sp, #-16]!
	mov	x0, sp
	ret


exception_exit:
	add	sp, sp, #(8*8)
	ldp	x2, x0, [sp],#16
	switch_el x11, 3f, 2f, 1f
3:	msr	elr_el3, x2
	b	0f
2:	msr	elr_el2, x2
	b	0f
1:	msr	elr_el1, x2
0:
	ldp	x1, x2, [sp],#16
	ldp	x3, x4, [sp],#16
	ldp	x5, x6, [sp],#16
	ldp	x7, x8, [sp],#16
	ldp	x9, x10, [sp],#16
	ldp	x11, x12, [sp],#16
	ldp	x13, x14, [sp],#16
	ldp	x15, x16, [sp],#16
	ldp	x17, x18, [sp],#16
	ldp	x19, x20, [sp],#16
	ldp	x21, x22, [sp],#16
	ldp	x23, x24, [sp],#16
	ldp	x25, x26, [sp],#16
	ldp	x27, x28, [sp],#16
	ldp	x29, x30, [sp],#16
	eret

/*F:\Rock4Plus_Android10\u-boot\arch\arm\lib\crt0_64.S*/

/*F:\Rock4Plus_Android10\u-boot\include\generated\generic-asm-offsets.h*/


ENTRY(_main)
	.equ SCTLR_A_BIT,		(1 << 1)
	.equ SCTLR_SA_BIT,		(1 << 3)
	.equ SCTLR_I_BIT,		(1 << 12)

/*
 * Set up initial C runtime environment and call board_init_f(0).
 */

	ldr	x0, =(CONFIG_SYS_INIT_SP_ADDR)
	bic	sp, x0, #0xf	/* 16-byte alignment for ABI compliance */
	//mov	x0, sp
	//bl	board_init_f_alloc_reserve
	//mov	sp, x0
	/* set up gd here, outside any C code */
	//mov	x18, x0
	//bl	board_init_f_init_reserve
	//bl	board_init_f_init_serial

	//mov	x0, #0
	bl	main

/*
 * Set up intermediate environment (new sp and gd) and call
 * relocate_code(addr_moni). Trick here is that we.ll return
 * here but relocated.
 */
	ldr	x0, [x18, #GD_START_ADDR_SP]	/* x0 <- gd->start_addr_sp */
	bic	sp, x0, #0xf	/* 16-byte alignment for ABI compliance */
	ldr	x18, [x18, #GD_NEW_GD]		/* x18 <- gd->new_gd */

	adr	lr, relocation_return

	/* Add in link-vs-relocation offset */
	ldr	x9, [x18, #GD_RELOC_OFF]	/* x9 <- gd->reloc_off */
	add	lr, lr, x9	/* new return address after relocation */
	ldr	x0, [x18, #GD_RELOCADDR]	/* x0 <- gd->relocaddr */
	b	relocate_code

relocation_return:

/*
 * Set up final (full) environment
 */
	bl	c_runtime_cpu_setup		/* still call old routine */


/*
 * Clear BSS section
 */
	ldr	x0, =__bss_start		/* this is auto-relocated! */
	ldr	x1, =__bss_end			/* this is auto-relocated! */
clear_loop:
	str	xzr, [x0], #8
	cmp	x0, x1
	b.lo	clear_loop

	/* call board_init_r(gd_t *id, ulong dest_addr) */
	//mov	x0, x18				/* gd_t */
	//ldr	x1, [x18, #GD_RELOCADDR]	/* dest_addr */
	//b	board_init_r			/* PC relative jump */

	/* NOTREACHED - board_init_r() does not return */

ENDPROC(_main)

/*F:\Rock4Plus_Android10\u-boot\arch\arm\lib\relocate_64.S*/
#define R_AARCH64_RELATIVE	1027

/*
 * void relocate_code (addr_moni)
 *
 * This function relocates the monitor code.
 * x0 holds the destination address.
 */
ENTRY(relocate_code)
	stp	x29, x30, [sp, #-32]!	/* create a stack frame */
	mov	x29, sp
	str	x0, [sp, #16]
	/*
	 * Copy u-boot from flash to RAM
	 */
	adr	x1, __image_copy_start	/* x1 <- Run &__image_copy_start */
	subs	x9, x0, x1		/* x8 <- Run to copy offset */
	b.eq	relocate_done		/* skip relocation */
	/*
	 * Dont ldr x1, __image_copy_start here, since if the code is already
	 * running at an address other than it was linked to, that instruction
	 * will load the relocated value of __image_copy_start. To
	 * correctly apply relocations, we need to know the linked value.
	 *
	 * Linked &__image_copy_start, which we know was at
	 * CONFIG_SYS_TEXT_BASE, which is stored in _TEXT_BASE, as a non-
	 * relocated value, since it isnt a symbol reference.
	 */
	ldr	x1, _TEXT_BASE		/* x1 <- Linked &__image_copy_start */
	subs	x9, x0, x1		/* x9 <- Link to copy offset */

	adr	x1, __image_copy_start	/* x1 <- Run &__image_copy_start */
	adr	x2, __image_copy_end	/* x2 <- Run &__image_copy_end */
copy_loop:
	ldp	x10, x11, [x1], #16	/* copy from source address [x1] */
	stp	x10, x11, [x0], #16	/* copy to   target address [x0] */
	cmp	x1, x2			/* until source end address [x2] */
	b.lo	copy_loop
	str	x0, [sp, #24]

	/*
	 * Fix .rela.dyn relocations
	 */
	adr	x2, __rel_dyn_start	/* x2 <- Run &__rel_dyn_start */
	adr	x3, __rel_dyn_end	/* x3 <- Run &__rel_dyn_end */
fixloop:
	ldp	x0, x1, [x2], #16	/* (x0,x1) <- (SRC location, fixup) */
	ldr	x4, [x2], #8		/* x4 <- addend */
	and	x1, x1, #0xffffffff
	cmp	x1, #R_AARCH64_RELATIVE
	bne	fixnext

	/* relative fix: store addend plus offset at dest location */
	add	x0, x0, x9
	add	x4, x4, x9
	str	x4, [x0]
fixnext:
	cmp	x2, x3
	b.lo	fixloop

relocate_done:
	switch_el x1, 3f, 2f, 1f
	bl	hang
3:	mrs	x0, sctlr_el3
	b	0f
2:	mrs	x0, sctlr_el2
	b	0f
1:	mrs	x0, sctlr_el1
0:	tbz	w0, #2, 5f	/* skip flushing cache if disabled */
	tbz	w0, #12, 4f	/* skip invalidating i-cache if disabled */
	ic	iallu		/* i-cache invalidate all */
	isb	sy
4:	ldp	x0, x1, [sp, #16]
	bl	__asm_flush_dcache_range
5:	ldp	x29, x30, [sp],#32
	ret
ENDPROC(relocate_code)

//.popsection

/*
 * void __asm_flush_dcache_range(start, end)
 *
 * clean & invalidate data cache in the range
 *
 * x0: start address
 * x1: end address
 */
//.pushsection .text.__asm_flush_dcache_range, "ax"
ENTRY(__asm_flush_dcache_range)
	mrs	x3, ctr_el0
	lsr	x3, x3, #16
	and	x3, x3, #0xf
	mov	x2, #4
	lsl	x2, x2, x3		/* cache line size */

	/* x2 <- minimal cache line size in cache system */
	sub	x3, x2, #1
	bic	x0, x0, x3
1:	dc	civac, x0	/* clean & invalidate data or unified cache */
	add	x0, x0, x2
	cmp	x0, x1
	b.lo	1b
	dsb	sy
	ret
ENDPROC(__asm_flush_dcache_range)

ENTRY(hang)
	bl hang
ENDPROC(hang)
