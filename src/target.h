

#ifndef __TARGET__H
    #define __TARGET__H

    #include "target.def"

    extern char code *target_mcu_str[];
    extern void       target_init();
    extern void       target_interrupt_enable();

    // macro for sbit defines
    #define SBIT(x, y, z)   sbit x = y^z    

    // High bits - interrupt priority mask (low bits are bit addressable)
    #if (TARGET_MCU == C51ED2) || (TARGET_MCU == C51RD2)
    	#define PPCH 0x40
        #define PT2H 0x20
        #define PSH  0x10
        #define PT1H 0x08
        #define PX1H 0x04
        #define PT0H 0x02
        #define PX0H 0x01

        // IPL0
        #ifndef PPCL
        SBIT (PPCL, 0xB8, 6);
        SBIT (PT2L, 0xB8, 5);
        SBIT (PSL , 0xB8, 4);
        SBIT (PT1L, 0xB8, 3);
        SBIT (PX1L, 0xB8, 2);
        SBIT (PT0L, 0xB8, 1);
        SBIT (PX0L, 0xB8, 0);
        #endif
    #endif

#endif


