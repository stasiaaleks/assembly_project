    .model tiny
    .code
    org 100h

    ; compare two strings by pointers to address

    .data
    string1 db "helo", 0
    string2 db "helo", 0
                        
    init:
        mov ax, cs
        mov ds, ax
        mov es, ax
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
    scasb ; compare al and [di], increment di
    jne end_comparing ; if not equal, end procedure 

    cmp al, 0       ; check if the string is terminated
    je equal        
    jmp compare

    equal:
    mov cx, 1 ; marker that strings are equal

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