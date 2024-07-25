#include <or1k-support.h>
#include <or1k-sprs.h>

extern void _or1k_uart_write(char c);
extern uint32_t _or1k_board_clk_freq;
extern uint32_t or1k_timer_ticks;

static void myputs(const char *s)
{
  char c;
  while ((c = *s++)) {
    if (c == '\n')
      _or1k_uart_write('\r');
    _or1k_uart_write(c);
  }
}

static void myput08x(uint32_t v)
{
  for (unsigned i = 0; i < 8; i++) {
    _or1k_uart_write("0123456789ABCDEF"[v>>28]);
    v <<= 4;
  }
}

int main()
{
  /* Start timer with 5 microsecond ticks */
  or1k_mtspr(OR1K_SPR_TICK_TTMR_ADDR,
	     OR1K_SPR_TICK_TTMR_IE_SET
	     (OR1K_SPR_TICK_TTMR_MODE_SET(_or1k_board_clk_freq / 200000u,
					  OR1K_SPR_TICK_TTMR_MODE_RESTART),
	      1));
  or1k_mtspr(OR1K_SPR_SYS_SR_ADDR,
	     OR1K_SPR_SYS_SR_TEE_SET(or1k_mfspr(OR1K_SPR_SYS_SR_ADDR), 1));

  uint32_t last_tick = ~0;
  unsigned cnt = 3;
  for (;;) {
    uint32_t tick = or1k_timer_ticks;
    if (tick != last_tick) {
      uint32_t ttcr = or1k_mfspr(OR1K_SPR_TICK_TTCR_ADDR);
      last_tick = tick;
      myputs("or1k_timer ticks = ");
      myput08x(or1k_timer_ticks);
      myputs(", TTCR = ");
      myput08x(ttcr);
      myputs("\n");
      if (!--cnt)
	break;
    }
  }

  return 0;
}
