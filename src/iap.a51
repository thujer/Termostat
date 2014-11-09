 ;-------------------------------------------------------------------------------;
                     $TT ('In Application Programming driver')
 ;                             Version: 1.03.080311                              ;
 ;                                                                               ;
 ;                               Thomas Hoodger                                  ;
 ;                            Copyright (c) 2006-2008                            ;
 ;                         thomas.hoodger(at)gmail.com                           ;
 ;-------------------------------------------------------------------------------;
 ;                                                                               ;
 ;  Version history                                                              ;
 ;  ---------------                                                              ;
 ;   1.03  Added target MCU support                                              ;
 ;                                                                               ;
 ;   1.04  Error on including module target.def                                  ;
 ;                                                                               ;
 ;-------------------------------------------------------------------------------;
 ;  In Application Programming Method                                            ;
 ;  Several In Application Programming (IAP) calls are available for use b       ;
 ;  an application program to permit selective erasing and programming o         ;
 ;  Flash sectors. All calls are made through a common interface,                ;
 ;  TARGET_IAP_ROUTINE. The programming functions are selected by setting up     ;
 ;  the microcontroller’s registers before making a call to PGM_MTP at           ;
 ;  FFF0H. The oscillator frequency is an integer number rounded down            ;
 ;  to the nearest megahertz. For example, set R0 to 11 for 11.0592 MHz          ;
 ;  Results are returned in the registers. The IAP calls are shown in            ; 
 ;  Table 8.                                                                     ;
 ;                                                                               ;
 ;  Using the Watchdog Timer (WDT)                                               ;
 ;  The 89C51Rx2 devices support the use of the WDT in IAP. The user             ;
 ;  specifies that the WDT is to be fed by setting the most significant bit      ;
 ;  of the function parameter passed in R1 prior to calling PGM_MTP.             ;
 ;  The WDT function is only supported for Block Erase when using                ;
 ;  Quick Block Erase. The Quick Block Erase is specified by                     ;
 ;  performing a Block Erase with register R0 = 0. Requesting a WDT              ;
 ;  feed during IAP should only be performed in applications that use            ;
 ;  the WDT since the process of feeding the WDT will start the WDT if           ;
 ;  the WDT was not running.                                                     ;
 ;                                                                               ;
 ;-------------------------------------------------------------------------------;

NAME IAP_DRV

; $NOMOD51
$INCLUDE (target.def)
$INCLUDE (TARGET_SFR_INC)


IF TARGET_MCU == C51RD2
    ; 8xC51RD2 Extensions
    AUXR    DATA    08EH      ; By Thomas Hudger 06/07/26
    AUXR1   DATA    0A2H      ; By Thomas Hudger 06/07/26
ENDIF 

IF TARGET_MCU==LPC922
    //IEN0    DATA    0xA8      ; By Thomas Hoodger 29/12/2008
ENDIF 


; +---------------------------------------+
; |           Public routines             |
; +---------------------------------------+
    PUBLIC IAP_call_ISP_direct
IF TARGET_MCU==LPC922
    PUBLIC IAP_reset_boot_status
    PUBLIC IAP_reset_boot_vector
ELSEIF (TARGET_MCU==C51RD2 || TARGET_MCU==C51ED2)
    PUBLIC IAP_prog_data_byte;
    PUBLIC IAP_read_device_data;
    PUBLIC IAP_erase_block;
    PUBLIC IAP_read_mid;
    PUBLIC IAP_read_boot_vector;
    PUBLIC IAP_erase_boot_vector;
    PUBLIC _IAP_program_boot_vector;
    PUBLIC IAP_read_status_byte;
    PUBLIC _IAP_program_status_byte;
    PUBLIC IAP_read_security_bits;
    PUBLIC IAP_program_security_bits;
    PUBLIC IAP_read_device_id1;
    PUBLIC IAP_read_device_id2;
ENDIF
    
    
    ; +---------------------------------------+
    ; |           Program DATA                |
    ; +---------------------------------------+
    IAP_DATA        SEGMENT DATA
    RSEG            IAP_DATA
    
    IAP_BYTE:       DS      1
    
    
    ; +---------------------------------------+
    ; |           Program CODE                |
    ; +---------------------------------------+
    IAP_CODE        SEGMENT CODE
    RSEG            IAP_CODE
    
    
    ; +---------------------------------------+
    ; |        Register bank select           |
    ; +---------------------------------------+
    USING 0
    
    ; +-----------------------------+
    ; | Call ISP code directly      |
    ; +-----------------------------+
    IAP_call_ISP_direct:
        SAVE_ALL_INTERRUPT_STATE
        push    IEN0
        clr     EA                  ; disable int's
        lcall   TARGET_IAP_ROUTINE
        RECOVERY_ALL_INTERRUPT_STATE
        RET

IF TARGET_MCU == LPC922
    
    ; AUXR1 = 8 ... sw reset

    ;------------------------------;
    ; set boot status for the ISP  ;
    ;------------------------------;
    IAP_reset_boot_status:
        push    IEN0            ; save EA Status
        clr     EA              ; disable int's

        mov     R0,     #0FFH   ; IAP authourisation key first
        mov     @R0,    #96H
        mov     A,      #02
        mov     R5,     #01     ; write bootstat with 01H
        mov     R7,     #03

        lcall   TARGET_IAP_ROUTINE
        pop     IEN0            ; restore EA status
        RET
            

    ;-----------------------------;
    ; set boot vector for the ISP ;
    ;-----------------------------;
    IAP_reset_boot_vector:
        push    IEN0            ; save EA Status
        clr     EA              ; disable int's

        mov     R0,     #0FFH   ; IAP authorisation key first
        mov     @R0,    #96H
        mov     A,      #02
        mov     R5,     #1FH    ; write bootvec with 1FH
        mov     R7,     #02

        lcall   TARGET_IAP_ROUTINE
        pop     IEN0            ; restore EA status
        RET

      
ELSEIF (TARGET_MCU==C51RD2 || TARGET_MCU==C51ED2)
    ; +----------------------------------------------------------------------+
    ; |                       PROGRAM DATA BYTE                              |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_ProgDataByte( uchar *DataPtr, uchar Bytes );
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 02h
    ;    R1 = 82h (WDT feed)
    ;    DPTR = address of byte to program
    ;    ACC = byte to program
    ;  Return Parameter
    ;    ACC = 00 if pass, !00 if fail
    
    IAP_prog_data_byte:
    
            ;  Vstupy:
            ;  R1 ... #LOW  Buf
            ;  R2 ... #HIGH Buf
            ;  R3 ... Typ pameti Buf
            ;  R5 ... Zapisovany byte
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
    
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   A,   R5                       ; Zkopiruj z parametru zapisovany byte
            MOV   DPL, R1                       ; Dolni byte cilove adresy dat
            MOV   DPH, R2                       ; Horni byte cilove adresy dat
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #02h                     ; Nastav ID prikazu (API)
            CALL  TARGET_IAP_ROUTINE            ; Zavolej rutinu bootloaderu PGM_MTP
            MOV   R7,  Acc                      ; Zapis status do vracene hodnoty
    
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Status
    
    
    ; +----------------------------------------------------------------------+
    ; |                        READ DEVICE DATA                              |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_ReadDeviceData( uchar *DataPtr, uchar Bytes );
    ; 
    ;  Input Parameters:
    ;    R1 = 03h
    ;    R1 = 83h (WDT feed)
    ;    DPTR = address of byte to read
    ;  Return Parameter
    ;    ACC = value of byte read
    
    IAP_read_device_data:
    
            ;  Vstupy:
            ;  R1 ... #LOW  source
            ;  R2 ... #HIGH source
            ;  R3 ... Typ pameti
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
    
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #03h                     ; Nastav ID prikazu (API)
            MOV   DPL, R1                       ; Dolni byte cilove adresy dat
            MOV   DPH, R2                       ; Horni byte cilove adresy dat
            CALL  TARGET_IAP_ROUTINE            ; Zavolej rutinu bootloaderu PGM_MTP
            MOV   R7,  Acc                      ; Zapis vracenou hodnoty
    
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Nacteny byte
    
    
    
    ; +----------------------------------------------------------------------+
    ; |                            ERASE BLOCK                               |
    ; +----------------------------------------------------------------------+
    ;  void IAP_erase_block( uchar BlockID );
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R0 = 0 (Quick Erase)
    ;    R1 = 01h
    ;    R1 = 81h (WDT feed)
    ;    DPH = block code as shown below:
    ;          block 0,  0k to  8k, 00H
    ;          block 1,  8k to 16k, 20H
    ;          block 2, 16k to 32k, 40H
    ;          block 3, 32k to 48k, 80H
    ;          block 4, 48k to 64k, C0H
    ;    DPL = 00h
    ;  Return Parameter
    ;    none
    
    IAP_erase_block:
    
            ;  Vstupy:
            ;  R7 ... ID bloku dat
    
            SAVE_ALL_INTERRUPT_STATE              ; Uloz stav vsech preruseni
            CLR   EA                              ; Zakaz vsech preruseni
            PUSH  DPH
            PUSH  DPL
    
            ORL   AUXR1, #20h                     ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,    #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,    #01h                     ; Nastav ID prikazu (API)
            MOV   DPH,   R7                       ; ID bloku dat
            MOV   DPL,   #00                      ;
            CALL  TARGET_IAP_ROUTINE              ; Zavolej rutinu bootloaderu PGM_MTP
    
            POP   DPL
            POP   DPH
            RECOVERY_ALL_INTERRUPT_STATE          ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
    
    
    
    ; +----------------------------------------------------------------------+
    ; |                       READ MANUFACTURER ID                           |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_read_mid();
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 00h
    ;    DPH = 00h
    ;    DPL = 00h (manufacturer ID)
    ;  Return Parameter
    ;    ACC = value of byte read
    
    IAP_read_mid:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #00H                     ; read misc function
            MOV   DPTR,#0000H                   ; specify MID
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... ID (15h = Philips)
    
    
    ; +----------------------------------------------------------------------+
    ; |                          READ BOOT VECTOR                            |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_ReadBootVector();
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 07h
    ;    R1 = 87h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 02h (boot vector)
    ;  Return Parameter
    ;    ACC = value of byte read
    
    IAP_read_boot_vector:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #07h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #02h                     ; ID pro Boot vector
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Boot vector
    
    
    ; +----------------------------------------------------------------------+
    ; |                         ERASE BOOT VECTOR                            |
    ; +----------------------------------------------------------------------+
    ;  void IAP_EraseBootVector();
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 04h
    ;    R1 = 84h (WDT feed)
    ;    DPH = 00h
    ;    DPL = don’t care
    ;  Return Parameter
    ;    none
    
    IAP_erase_boot_vector:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #04h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #00h                     ; ID pro Boot vector
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Boot vector
    
    
    
    ; +----------------------------------------------------------------------+
    ; |                       PROGRAM BOOT VECTOR                            |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_ProgramBootVector(uchar BootVector);
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 06h
    ;    R1 = 86h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 01h – program boot vector
    ;    ACC = boot vector
    ;  Return Parameter
    ;    ACC = boot vector
    
    _IAP_program_boot_vector:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #06h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #01h                     ; ID pro Boot vector
            MOV   Acc, R7                       ; Zkopiruj hodnotu z parametru do Acc
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Boot vector
    
    
    ; +----------------------------------------------------------------------+
    ; |                          READ STATUS BYTE                            |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_ReadStatusByte();
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 07h
    ;    R1 = 87h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 01h (status byte)
    ;  Return Parameter
    ;    ACC = value of byte read
    
    IAP_read_status_byte:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #07h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #01h                     ; ID pro Status byte
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Status byte
    
    
    ; +----------------------------------------------------------------------+
    ; |                       PROGRAM STATUS BYTE                            |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_ProgramStatusByte(uchar StatusByte);
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 06h
    ;    R1 = 86h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 00h – program status byte
    ;    ACC = status byte
    ;  Return Parameter
    ;    ACC = status byte
    
    _IAP_program_status_byte:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #06h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #00h                     ; ID pro Status byte
            MOV   Acc, R7                       ; Zkopiruj hodnotu z parametru do Acc
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Status byte
    
    
    
    ; +----------------------------------------------------------------------+
    ; |                         READ SECURITY BITS                           |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_ReadSecurityBits();
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 07h
    ;    R1 = 87h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 00h (security bits)
    ;  Return Parameter
    ;    ACC = value of byte read
    
    IAP_read_security_bits:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #07h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #00h                     ; ID pro Security bits
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Security bits
    
    
    ; +----------------------------------------------------------------------+
    ; |                      PROGRAM SECURITY BITS                           |
    ; +----------------------------------------------------------------------+
    ;  void IAP_ProgramSecurityBits(uchar SecurityBits);
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 05h
    ;    R1 = 85h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 00h – security bit # 1 (inhibit writing to Flash)
    ;          01h – security bit # 2 (inhibit Flash verify)
    ;          02h – security bit # 3 (disable external memory)
    ;  Return Parameter
    ;    none
    
    IAP_program_security_bits:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #05h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, R7                       ; Zkopiruj hodnotu Security bits z R7
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
    
    
    
    ; +----------------------------------------------------------------------+
    ; |                         READ DEVICE ID # 1                           |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_read_device_id1();
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 00h
    ;    R1 = 80h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 01h (device ID # 1)
    ;  Return Parameter
    ;    ACC = value of byte read
    
    IAP_read_device_id1:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #00h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #01h                     ; Device ID #1
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Status byte
    
    
    ; +----------------------------------------------------------------------+
    ; |                         READ DEVICE ID # 2                           |
    ; +----------------------------------------------------------------------+
    ;  uchar IAP_read_device_id2();
    ; 
    ;  Input Parameters:
    ;    R0 = osc freq (integer)
    ;    R1 = 00h
    ;    R1 = 80h (WDT feed)
    ;    DPH = 00h
    ;    DPL = 02h (device ID # 1)
    ;  Return Parameter
    ;    ACC = value of byte read
    
    IAP_read_device_id2:
            ;  Vstupy:
    
            SAVE_ALL_INTERRUPT_STATE            ; Uloz stav vsech preruseni
            CLR   EA                            ; Zakaz vsech preruseni
            PUSH  Acc                           ; Uloz akumulator
            PUSH  DPH
            PUSH  DPL
            ORL   AUXR1, #20h                   ; Aktivace bitu ENDBOOT (Enable shadowed BOOTROM)
            MOV   R0,  #TARGET_FREQUENCY        ; Zapis frekvenci oscilatoru
            MOV   R1,  #00h                     ; Nastav ID prikazu (API)
            MOV   DPH, #00h                     ;
            MOV   DPL, #02h                     ; Device ID #2
            CALL  TARGET_IAP_ROUTINE            ; execute the function
            MOV   R7,  Acc                      ; Zkopiruj vystup do R7
            POP   DPL
            POP   DPH
            POP   Acc                           ; Obnov akumulator
            RECOVERY_ALL_INTERRUPT_STATE        ; Obnov stav vsech preruseni
            RET
    
            ;  Vystupy:
            ;  R7 ... Status byte
    
    
    
ENDIF
END
