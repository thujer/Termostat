

#ifndef __PIN_H
    #define __PIN_H

    #define uchar unsigned char
    #define uint  unsigned int 

    typedef enum {
                    PORT_ID_P0,
                    PORT_ID_P1,
                    PORT_ID_P2,
                    PORT_ID_P3
    };
    
    
    typedef enum {
                    PIN_TYPE_QUASI_BIDIRECTIONAL,
                    PIN_TYPE_PUSH_PULL,
                    PIN_TYPE_INPUT_ONLY,
                    PIN_TYPE_OPEN_DRAIN
    };


    extern void pin_change(uchar port_id, uchar pin_id, uchar state);
    extern bit  pin_get_state(uchar port_id, uchar pin_id);
    extern void pin_set(uchar port_id, uchar pin_id, uchar pin_type);

#endif