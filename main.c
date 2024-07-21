extern void _or1k_uart_write(char c);

static void myputs(const char *s)
{
  char c;
  while ((c = *s++)) {
    if (c == '\n')
      _or1k_uart_write('\r');
    _or1k_uart_write(c);
  }
}

int main()
{
  myputs("Hello, world!\n");
  return 0;
}
