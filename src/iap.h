
#ifndef __IAP_H
    #define __IAP_H

    #include "target.def"

    #define uchar unsigned char
    #define uint  unsigned int

    extern void  IAP_call_ISP_direct();

    #if TARGET_MCU == LPC922
        extern bit   IAP_reset_boot_status();
        extern bit   IAP_reset_boot_vector();
    #else
        extern uchar IAP_prog_data_byte( uchar *DataPtr, uchar Bytes );
        extern uchar IAP_read_device_data( uchar *DataPtr, uchar Bytes );
        extern void  IAP_erase_block( uchar BlockID );
        extern uchar IAP_read_mid();
        extern uchar IAP_read_boot_vector();
        extern void  IAP_erase_boot_vector();
        extern uchar IAP_program_boot_vector(uchar boot_vector);
        extern uchar IAP_read_status_byte();
        extern uchar IAP_program_status_byte(uchar status_byte);
        extern uchar IAP_read_security_bits();
        extern void  IAP_program_security_bits(uchar security_bits);
        extern uchar IAP_read_device_id1();
        extern uchar IAP_read_device_id2();
        extern uchar PGM_MTP();
    #endif

#endif

