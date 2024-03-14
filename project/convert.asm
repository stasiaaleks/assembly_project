    .model tiny
    .code
    org 100h

    ; turn from string to hex and if negative, to complementary binary (hex). integer is stored in cx 

    .data
        inputStr db "-16", 0       ; Input string, null-terminated

    .data?
        num dw ?                    

    init:
        mov ax, cs
        mov ds, ax
        call start
        jmp exit

    start proc
        push ax ;for other procedures
        push dx

        xor ax,ax
        mov bx, 1 ; multiplier
        mov cx, 10 ; base
        lea si, inputStr
        mov dx, [si] 

    ;find where string ends to iterate backwards later
    findEndOfString:          
        cmp byte ptr [si], 0
        jne stringNotEnd
        dec si                  
        jmp parseLoop           
    stringNotEnd:
        inc si                  
        jmp findEndOfString


    parseLoop:
    mov al, [si]            
    cmp al, '0'              ; is current char a digit
    jb isNegative            ; if it is before 0 it is not a digit
    sub al, '0'             
    mul bx
    add [num], ax            

    mov ax, bx
    mul cx        ; multiplier*10
    mov bx, ax     

    dec si                   
    cmp si, offset inputStr        
    jae parseLoop            ; if si >= input start, continue parsing

    jmp parseDone

    isNegative:
        neg [num]   

    parseDone:
        mov cx, [num]
        pop dx ;for other procedures
        pop ax

    start endp
    jmp exit

    exit:
        mov ax, 4C00h
        int 21h
        ret

    end init