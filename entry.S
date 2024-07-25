	.section .vectors,"ax"

	.globl or1k_interrupt_handler_add
	.globl or1k_interrupt_enable
	.globl or1k_interrupt_disable
	.globl or1k_timer_ticks

	.word 0 // No exception vector 0
	.word 0

	// Reset vector
	l.j _or1k_reset
	l.movhi r0, 0
	
	// Bus Error exception
	l.j _exception_handler
	l.ori r3, r0, 0x2

	// Data Page Fault exception
	l.j _exception_handler
	l.ori r3, r0, 0x3
	
	// Instruction Page Fault exception
	l.j _exception_handler
	l.ori r3, r0, 0x4
	
	// Tick Timer exception
	l.j _timer_tick_handler
	l.mfspr r3, r0, 0x5000

	// Alignment exception
	l.j _exception_handler
	l.ori r3, r0, 0x6

	// Illegal Instruction exception
	l.j _exception_handler
	l.ori r3, r0, 0x7

	// External Interrupt
	l.j _interrupt_handler
	l.mfspr r10, r0, 0x4802

	// D-TLB Miss exception
	l.j _exception_handler
	l.ori r3, r0, 0x9

	// I-TLB Miss exception
	l.j _exception_handler
	l.ori r3, r0, 0xa

	// Range exception
	l.j _exception_handler
	l.ori r3, r0, 0xb

	// System Call exception
	l.j _exception_handler
	l.ori r3, r0, 0xc

	// Floating Point exception
	l.j _exception_handler
	l.ori r3, r0, 0xd

	// Trap exception
	l.j _exception_handler
	l.ori r3, r0, 0xe


_or1k_reset:
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

	/* Set exception stack to 0x80 beyond normal stack */
	l.addi r3, r1, 0x80
	l.mtspr r0, r3, 0x421
	
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


_exception_handler:
	/* Loop forever */
1:
	l.j 1b
	l.nop 0xc


_timer_tick_handler:
	l.rori r3, r3, 29 /* IP bit to sign bit */
	l.sfltsi r3, 0
	l.slli r3, r3, 1  /* Clear IP */
	l.bnf 1f          /* Skip if IP wasn't set */
	l.rori r3, r3, 36 /* Move IP back to original position */

	/* Write back TTMR, and increment ticks */
	l.mtspr r0, r3, 0x5000
	l.movhi r3, ha(or1k_timer_ticks)
	l.lwz r4, lo(or1k_timer_ticks)(r3)
	l.addi r4, r4, 1
	l.sw lo(or1k_timer_ticks)(r3), r4
1:
	/* Return */
	l.rfe


_interrupt_handler:
	l.movhi r3, ha(_or1k_board_uart_IRQ)
	l.lwz r3, lo(_or1k_board_uart_IRQ)(r3)
	/* Move status bit for UART IRQ to the LSB and mask it out */
	l.srl r3, r10, r3
	l.andi r3, r3, 0x1
	/* Check if nonzero */
	l.sfeq r3, r0
	l.bf 1f
	/* Clear pending IRQs before calling handler to avoid races */
	l.mtspr r0, r10, 0x4802
	/* If status bit for UART IRQ was nonzero then call the handler */
	l.jal _or1k_uart_interrupt_handler
	l.ori r3, r0, 0
1:
	/* Return */
	l.rfe


	/* Stub; the uart irq handler is hardcoded */
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
	

	.bss

or1k_timer_ticks:
	.ds.l 1

	
	.end
