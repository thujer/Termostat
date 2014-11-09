
#ifndef __LED_H__

    #define __LED_H__

    #define uchar unsigned char

    #include "led.def"

    extern void led_blink(uchar led_id);
    extern void led_proc();
    extern void led_init();

#endif

