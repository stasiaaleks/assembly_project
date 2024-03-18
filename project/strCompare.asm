    .model tiny
    .code
    org 100h

    ; compare two strings by pointers to address

    .data
    string1 db "hello", 0
    string2 db "helo", 0
                        
    init:
        mov ax, cs
        mov ds, ax
        call start
        jmp exit

    start proc

    push ax ; save registers
    push di
    push si
    cld ; auto-increment si

    mov di, offset string1  
    mov si, offset string2  

    compare:
    lodsb ; mov si to al, increment si
    scasb ; compare al and di, increment di
    jne end_comparing ; if not equal, end procedure 

    or al, al ; is this the end of string?
    jne compare ; string is not terminated, compare next

    end_comparing:
    pop si ; restore
    pop di
    pop ax
    ret

    start endp

    exit:
        mov ax, 4C00h
        int 21h
        ret

    end init