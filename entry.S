	.section .vectors,"ax"

	.globl or1k_interrupt_handler_add
	.globl or1k_interrupt_enable
	.globl or1k_interrupt_disnable
	
	.org 0x100
_or1k_reset:
	l.movhi r0, 0
	/* Clear status register, set supervisor mode */
	l.ori r1, r0, 0x1
	l.mtspr r0, r1, 0x11
	/* Clear timer mode register*/
	l.mtspr r0, r0, 0x5000
	l.jal _or1k_cache_init
	l.nop
	l.jal _or1k_board_init_early
	l.nop
	/* Clear BSS */
	l.movhi r3, hi(__bss_start)
	l.ori r3, r3, lo(__bss_start)
	l.movhi r4, hi(end)
	l.ori r4, r4, lo(end)
	l.addi r1, r4, 0x100 /* Set stack 0x100 beyond end */
1:	
	l.sw 0(r3), r0
	l.sfltu r3, r4
	l.bf 1b
	l.addi r3, r3, 4

	/* UART initialization */
	l.jal _or1k_uart_init
	l.nop
	/* Board initialization */
	l.jal _or1k_board_init
	l.nop

	/* Jump to main program entry point (argc = argv = envp = 0) */
	l.or r3, r0, r0
	l.or r4, r0, r0
	l.jal main
	l.or r5, r0, r0

	l.jal _or1k_board_exit
	l.nop
	
	/* Loop forever */
1:
	l.j 1b
	l.nop 0xc


	/* Stub */
or1k_interrupt_handler_add:	
	l.jr r9
	l.nop


	/* Function to enable an interrupt handler in the PICMR */
or1k_interrupt_enable:
	l.ori r4, r0, 0x1
	l.sll r4, r4, r3
	l.mfspr	r3, r0, 0x4800
	l.or r3, r3, r4
	l.jr r9
	l.mtspr	r0, r3, 0x4800

	/* Function to disable an interrupt handler in the PICMR */
or1k_interrupt_disable:
	l.ori r4, r0, 0x1
	l.sll r4, r4, r3
	l.xori r4, r4, 0xffff
	l.mfspr	r3, r0, 0x4800
	l.and r3, r3, r4
	l.jr r9
	l.mtspr	r0, r3, 0x4800
	

	.end
