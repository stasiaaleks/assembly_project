.model tiny
.code
org 100h

init:
    mov ax, cs
    mov ds, ax
    call start
    jmp exit

start proc   
    ;mov dx, offset promptMessage
    ;mov ah, 09h
    ;int 21h

    ;mov ah, 0Ah
    ;mov dx, offset filename
    ;int 21h

    ;mov al, '0'
    ;mov bl, [filename+1]     
    ;mov [filename+2+bx], al

    ;open file
    mov ah, 3Dh
    mov al, 0
    lea dx, filename
    int 21h
    jc error
    mov file_handle, ax

    ;read file
    mov ah, 3Fh
    mov bx, file_handle
    lea dx, bufferString
    mov cx, 255
    int 21h

    ;adding $ to terminate string
    mov di, ax          
    add di, offset bufferString  
    mov al, '$'          
    mov [di], al  

    ;TODO: copy symbols to structs
    access_elements:
    xor cx,cx              ; initialize counter
    mov si, offset bufferString

    next_element:
    mov bx, si
    add bx, cx
    mov al, [bx]

    mov bx, si
    add bx, cx
    add bx, 1
    mov ah, [bx]
 
    mov struct_key, ax     

    mov ah, 0
    mov al, [bx+2]   
    mov struct_value, bx   ; TODO: how to handle 2,3 digit numbers

    push cx
    mov di, ax
    repne scasb             ; check if '$' encountered
    je exit                 ; if yes exit

    pop cx
    add cx, 6               ; incrementing counter to next 6 elements

    jmp next_element        

    ;output file contents
    output:
    mov ah, 09h
    mov bx, 1
    lea dx, bufferString
    int 21h
    jmp exit

    ;if error while opening file occured
    error:
    mov dx, offset errorMessage
    mov ah, 09h
    int 21h

start endp

exit:
    mov ax, 4C00h
    int 21h
    ret

.data
filename db "input.txt", 0
;promptMessage db "Enter file path: $" 
errorMessage db "Error in reading file$"
;filename db 255, 0, 255 dup(0)
bufferString db 255 dup(?)
file_handle dw ?
bytes_read dw ?

struct_key dw ? ; future var for key
struct_value dw ? ; future var for value

end init