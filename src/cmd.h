#define uchar unsigned char
#define uint unsigned int

#ifndef __CMD_H__
    #define __CMD_H__

    #define uchar unsigned char

    // Command detector sessions
    typedef enum {
        CMD_SESSION_ID_TERMINAL = 0,
    
        CMD_SESSIONS_COUNT
    };

    extern void  cmd_init(uchar session_id, char *cmd_tab, int tab_size, char *par_buf, char par_buf_size);
    extern char *cmd_getpar(uchar session_id, uchar index);
    extern int   cmd_getparnum(uchar session_id, uchar index, uchar omez);
    extern char  cmd_par_count(uchar session_id);
    extern char  cmd_detect(uchar session_id, uchar get_char);
    extern bit   cmd_validate_test(uchar session_id);
    extern void  cmd_command_list(uchar session_id);

    extern bit   cmd_get_par_save_state(uchar session_id);
    extern bit   cmd_char_print_allowed(uchar session_id);
#endif
