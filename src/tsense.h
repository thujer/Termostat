

#ifndef __TSENSE_H__
    #define __TSENSE_H__

    #include "tsense.def"

    extern bit  tsense_add_task(uchar sensor_id, uchar event_id);
    extern void tsense_init();
    extern void tsense_proc();

    extern uchar TARGET_SMEM  tsense_interrupt_counter;
    extern float TARGET_SMEM  tsense_temperature;                        // Calculated temperature
    extern uint  TARGET_SMEM  tsense_timer_value_H;                      // Measure value high level
    extern uint  TARGET_SMEM  tsense_timer_value_L;                      // Measure value low level

    #ifdef TSENSE_DEBUG_LOG
    extern uint  TARGET_MMEM  tsense_timer_H_array[];   // debug - timer values
    extern uchar TARGET_SMEM  tsense_timer_H_array_ix;

    extern uint  TARGET_MMEM  tsense_timer_L_array[];   // debug - timer values
    extern uchar TARGET_SMEM  tsense_timer_L_array_ix;
    #endif

    #if TSENSE_COMPILE_COMPENSATION == 1
    extern uint  TARGET_MMEM  tsense_timer_L_value_min[TSENSE_PERIODS_SKIPPED]; // Measure value high level
    extern uint  TARGET_MMEM  tsense_timer_L_value_max[TSENSE_PERIODS_SKIPPED]; // Measure value low level
    extern uint  TARGET_MMEM  tsense_timer_H_value_min[TSENSE_PERIODS_SKIPPED]; // Measure value high level
    extern uint  TARGET_MMEM  tsense_timer_H_value_max[TSENSE_PERIODS_SKIPPED]; // Measure value low level
    #endif

#endif
