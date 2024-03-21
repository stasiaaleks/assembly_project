.model tiny
.code
org 100h

init:
    mov ax, cs
    mov ds, ax
    mov es, ax
    call start
    jmp exit

start proc
    call readLoop
start endp

readLoop proc
    ;read line by line
readLoop:
    ; read byte by byte
    mov ah, 3Fh         
    mov bx, 0h  
    lea dx, charRead    
    mov cx, 1          
    int 21h             

    ;check for eof
    cmp ax, 0           
    jne not_eof
    call lineFound
    call calculateAverage

    not_eof:
    mov al, [charRead]

    cmp al, 0Ah ; new line line feed
    je  readLoop  

    cmp al, 20h  ; encountered space, which means we extracted the key
    jne not_split  
    mov si, offset key      
    add si, [len]           
    mov byte ptr [si], '$' ;adding terminator to key (maybe fix later

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

findKeyInArray proc
 search_key:
    mov cx, [len] ;works, but later CHECK the behaviour for adding val to [di] and incrementing [di+1]
    ;mov al, [si];for debug
    ;mov bl, [di];for debug
    rep cmpsb 
    je key_found 

    cmp byte ptr [si], 0
    je not_found

    next_space:
    ;mov al, [si];for debug
    ;mov bl, [di];for debug
    cmp byte ptr [si], 20h ; Check if current character is a space
    je next_struct  
    inc si  
    jmp next_space ; Continue searching for the space

    next_struct:
    inc si
    dec di
    jmp search_key

key_found:
    ; here we add value to sum and incrementing counter
    mov di, si ; di - destination index - address of the end of array we got previously  
    mov ax, [num]
    xor ah,ah
    add [di], al
    mov al, [di+1]
    inc al
    mov [di+1],al

    jmp end_of_line

    not_found:
    ; here we add a new struct: key$, sum, counter
    mov di, si ;di - destination index - address of the end of array we got previously 
    dec di 
    mov si, offset key

    mov cx, [len]
    rep movsb ;copy from si to di len (in cx) times

    mov ax, [num]
    mov [si], ax
    movsb
    mov ax, 1
    mov [si], ax
    movsb
    mov ax, 20h
    mov [si], ax
    movsb

    ret
findKeyInArray endp

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
    inc [len]

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
compareStr proc
    ;assuming in di there is a key, in si there is a linesArray


    cld ; auto-increment si

    ;mov di, offset string1  
    ;mov si, offset string2  

    compare:
    lodsb ; mov si to al, increment si
    scasb ; compare al and [di], increment di
    jne end_comparing ; if not equal, end procedure 

    cmp al, '$'       ; check if the string is terminated
    je equal        
    jmp compare

    equal:
    mov cx, 1 ; marker that strings are equal

    end_comparing:
    pop si ; restore
    pop di
    pop ax
    ret

compareStr endp
lineFound proc
    ;here we will compare key to excisting array and create an array of three-elements structs, key sum counter

    push ax ;0 for eof
    mov si, offset linesArray
    mov di, offset key
    inc [len] 
    call findKeyInArray
   
    end_of_line:
    ;prepare everything for next line processing
    pop ax
    cmp ax, 0           
    jne not_end_of_file ;rewrite this later
    ret  

    not_end_of_file:
    mov si, offset key
    push ax
    call clear_string
    pop ax

    push ax
    mov si, offset value
    call clear_string
    pop ax

    mov [num],0
    mov [len],0
    mov di, offset buffer

    jmp readLoop

lineFound endp

calculateAverage proc

mov si, offset linesArray

to_end_of_key:
mov bl,[si]
cmp byte ptr [si], '$'
je calc

cmp byte ptr [si], 0 ;end of file
je exit

inc si
jmp to_end_of_key

calc:
xor ax,ax
xor bx,bx
mov al, [si+1]
mov bl, [si+2]
;xor dx, dx ;for remainder  
div bl ;ax has the quotient
mov byte ptr [si+1],al
mov byte ptr [si+2],0 ; clear counter
add si,4
jmp to_end_of_key

calculateAverage endp

exit proc
    mov ax, 4C00h
    int 21h
    ret
exit endp

.data
    filename db 'input.txt',0                  
    buffer db 255 dup(0)       
    errorMessage db "Error in reading file$"
    linesArray db 10000 dup(0)
    linesArrayOffset dw 0
    key db 16 dup(0)
    value db 255 dup(0) 
    len dw 0

.data?
    file_handle dw ? 
    charRead db ?  
    num dw ?       

end init