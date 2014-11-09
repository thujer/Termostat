

#ifndef __ISP_RECOVERY__
    #define __ISP_RECOVERY__

    extern void isp_recovery();
    extern void isp_security_check();
    extern void isp_security_loop();
    extern bit  isp_found();
    extern void isp_call_bootloader();

#endif