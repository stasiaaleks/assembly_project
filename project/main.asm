.model tiny
.code
org 100h

; rewrite as procedures +
; extract key and value +
; turn value to complementary binary (hex) +
; TODO: compare two strings (values) (ready in other file)

.data
    filename db 'input.txt',0                  
    buffer db 255 dup(0)       
    errorMessage db "Error in reading file$"
    linesArray db 10000 dup(0)
    linesArrayOffset dw 0
    key db 16 dup(0)
    value db 255 dup(0) 

.data?
    file_handle dw ? 
    charRead db ?  
    num dw ?               

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
    jnc no_error
    call error

    no_error:    
    mov file_handle, ax
    mov di, offset buffer

    call readLoop

start endp

readLoop proc
    ;read line by line
readLoop:
    ; read byte by byte
    mov ah, 3Fh         
    mov bx, file_handle  
    lea dx, charRead    
    mov cx, 1          
    int 21h             

    ;check for eof
    cmp ax, 0           
    jne not_eof
    call exit 

    not_eof:
    mov al, [charRead]

    cmp al, 0Ah ; new line line feed
    je  readLoop  

    cmp al, 20h  ; encountered space, which means we extracted the key
    jne not_split  
    call extract_val 

    not_split:
    call extract_key
    jmp readLoop

readLoop endp

stringToInt proc
        push ax ;for other procedures
        push dx

        xor ax,ax
        mov bx, 1 ; multiplier
        mov cx, 10 ; base
        lea si, value
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
    cmp si, offset value        
    jae parseLoop            ; if si >= input start, continue parsing

    jmp parseDone

    isNegative:
        neg [num]   

    parseDone:
        mov cx, [num]
        pop dx ;for other procedures
        pop ax
        ret

stringToInt endp

extract_key proc
    ;extracting key
    lea bx, key

    find_end_of_key:
    cmp byte ptr [bx], 0
    je add_char_to_key
    inc bx
    jmp find_end_of_key

    add_char_to_key:
    mov [bx], al

    stosb  ; store al at es:di and increment di
    ret
extract_key endp

extract_val proc
extract_value:
    ; encountered space, now extracting value
    mov ah, 3Fh         
    mov bx, file_handle  
    lea dx, charRead    
    mov cx, 1          
    int 21h             
    
    ;check for eof
    cmp ax, 0           
    jne not_end
    call stringToInt
    call readLoop 

    not_end:
    ; check for CR LF
    mov al, [charRead]

    cmp al, 0Dh         ; encountered end of the string 
    jne not_new_line
    mov si, offset value
    call stringToInt
    call lineFound

    not_new_line:
    lea bx, value

    find_end_of_value_str:
    cmp byte ptr [bx], 0 ;FIX FOR VALUES that end with 0
    je add_char_to_value_str
    inc bx
    jmp find_end_of_value_str 

    add_char_to_value_str:
    mov [bx], al

    stosb               ; store al at es:di and increment di
    jmp extract_value 
extract_val endp

clear_string proc
    mov di, si               ; copy string address to di too

clear_loop:
    mov al, [di]             
    test al, al ; check if a char is zero
    jz end_of_string 
    mov byte ptr [di], 0  ; null a character
    inc di  
    jmp clear_loop  

end_of_string:
    ret

clear_string endp

error proc
    mov dx, offset errorMessage
    mov ah, 09h
    int 21h
error endp

lineFound proc
    ;here we will compare key to excisting array and create an array of three-elements structs, key sum counter

    ;prepare everything for next line processing
    mov si, offset key
    push ax
    call clear_string
    pop ax

    push ax
    mov si, offset value
    call clear_string
    pop ax

    mov [num],0

    mov di, offset buffer
    jmp readLoop

lineFound endp

exit proc
    mov ax, 4C00h
    int 21h
    ret
exit endp

end init