
#ifndef __STDOUT_H__
    #define __STDOUT_H__

    extern char putchar(char c);

    extern int  stdout_printf(char (* which_putchar_fp)(char), const char *format, ...);
    extern int stdout_init(char (* which_putchar_fp)(char));

#endif


