SECTIONS {
	. = 0x200000;  
	. = ALIGN(8);
    .text : 
	{ 
	    __image_copy_start = .;
		start.o(.text)
		main.o(.text)
		led.o(.text)
		*(.text) 
	}
    .rodata ALIGN(8) : {*(.rodata*)} 
    .data   ALIGN(8) : { *(.data) }
	
    . = ALIGN(8);	
	__image_copy_end = .;

    . = ALIGN(8);
	__rel_dyn_start = .;
	__rel_dyn_end = .;

	_end = .;

    . = ALIGN(8);
    __bss_start = .;
    .bss   ALIGN(8)  : { *(.bss)  *(COMMON) }
    __bss_end = .;
}

