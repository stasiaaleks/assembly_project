.model tiny
.code
org 100h

init:
    mov ax, cs
    mov ds, ax
    call start
    jmp exit

start proc   
    mov dx, offset promptMessage
    mov ah, 09h
    int 21h

    mov ah, 0Ah
    mov dx, offset inputString
    int 21h

    mov al, '$'
    mov bl, [inputString+1]     
    mov [inputString+2+bx], al

    lea si, [inputString + 2] 
    lea di, [outputString + 2]

    mov cx, 0

    replace_loop:
    mov al, [si]
    cmp al, '$'
    je end_loop

    cmp al, '>'
    jne not_replace
    mov al, '+'

    not_replace:
    mov [di], al
    inc si 
    inc cx
    inc di
    jmp replace_loop

    end_loop:
    mov byte ptr [di], '$'

    mov dl, 10
    mov ah, 02h
    int 21h
    mov dl, 13
    mov ah, 02h
    int 21h
    
    lea dx, [outputString+2]
    mov ah, 09h
    int 21h

start endp

exit:
    mov ax, 4C00h
    int 21h
    ret

.data
promptMessage db "Please enter a string: $"
outputString db 20 dup(?)
inputString db 20, 20 dup(?)

end init