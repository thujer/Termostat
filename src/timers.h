
#ifndef __TIMERS_H
    #define __TIMERS_H

    #define uchar unsigned char
    #define uint  unsigned int

    #include "timers.def"
    #include "target.def"

    #if SYSTEM_TIME_INCLUDE == INCLUDE_SYSTIME
    extern void  time_set_time(uchar hour, uchar min, uchar sec);
    extern void  time_set_date(uint  year, uchar month, uchar day);

    extern void  time_set_hour(uchar hour);
    extern void  time_set_minute(uchar minute);
    extern void  time_set_second(uchar second);
    extern void  time_set_year(uint year);
    extern void  time_set_month(uchar month);
    extern void  time_set_day(uchar day);

    extern char *time_string();
    extern char *date_string();
    #endif

    extern void  timers_init();
    //extern void  timer_set(uchar counter, uint time);
    //extern bit   timer(uchar counter);
    //extern uint  timer_value(uchar counter);

    //extern char *timer_get_name_str(uint timer_id);

    extern uint TARGET_SMEM timers[TIMERS_COUNT];   // Definice pro obsluhu casoveho limitu

#endif
