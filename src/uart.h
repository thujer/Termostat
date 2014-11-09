
#ifndef __UART_H__

    #define __UART_H__

    //#ifndef __TARGET_DEF__
    #include "target.def"
    //#endif

    extern bit              uart_ribuf;
    extern char TARGET_MMEM uart_rbyte;
    
    extern bit              uart_rb_overflow;
    
    extern void             uart_proc();
    extern void             uart_init(ulong cpu_xtal, uchar tact, ulong uart_speed);
    extern char             uart_putchar(char c);              // putchar compatible

    #if TARGET_MCU == LPC922
    extern bit              uart_detected_break;               // flag detekce prichoziho break
    extern bit              uart_detected_framing_error;       // flag detekce chybneho ramce
    extern bit              uart_detected_overrun;             // flag detekce prepsani znaku
    #endif

    
#endif

