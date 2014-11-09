
#ifndef __STR_H__
    #define __STR_H__

    #define uchar unsigned char
    #define uint  unsigned int

    extern uchar  str_up_char(uchar ch);
    extern void   str_reset_buffer(uchar *buf, uint bytes);
    extern uchar  str_is_num(uchar Char);
    //extern bit    str_is_hex(char byte);
    extern bit    str_cmp(uchar *ptr1, uchar *ptr2);

#endif
