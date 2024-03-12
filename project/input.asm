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

    ;output file contents
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

end init