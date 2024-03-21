.model tiny
.code
org 100h

.data
    filename db 'input.txt',0                  
    buffer db 255 dup(0)       
    errorMessage db "Error in reading file$"
    linesArray db 10000 dup(0)
    linesArrayOffset dw 0

.data?
    file_handle dw ? 
    charRead db ?                


init:
    mov ax, cs
    mov ds, ax
    mov es, ax
    call start
    jmp exit

start proc

    ;open file
    mov ah, 3Dh
    mov al, 0
    lea dx, filename
    int 21h
    jc error
    mov file_handle, ax

    mov di, offset buffer

    ;read line by line
readLoop:
    ; read byte by byte
    mov ah, 3Fh         
    mov bx, file_handle  
    lea dx, charRead    
    mov cx, 1          
    int 21h             
    jc  error        

    ;check for eof
    cmp ax, 0           
    je lineFound

    ; check for CR LF
    mov al, [charRead]
    cmp al, 0Dh         ; carriage return
    je  lineFound
    cmp al, 0Ah         ; new line line feed
    je  readLoop        

    mov al, [charRead]
    stosb               ; store al at es:di and increment di
    jmp readLoop

lineFound:
    ; line is in the buffer ending at DS:DI

    push ax    ; save ax value

    mov ax, di
    sub ax, offset buffer ; lenght of line
    mov cx, ax
    push cx

    lea si, buffer
    mov ax, [linesArrayOffset] 
    lea di, linesArray
    add di,ax
    
    rep movsb            ; copy cx bytes to memory from si to di

    pop cx
    add ax, cx
    mov [linesArrayOffset], ax

    pop ax    ; restore ax

    ; check for EOF
    cmp ax, 0
    je exit

    ; pred di for next line
    mov di, offset buffer
    jmp readLoop

error:
    mov dx, offset errorMessage
    mov ah, 09h
    int 21h

start endp

exit:
    mov ax, 4C00h
    int 21h
    ret

end init