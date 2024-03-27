.model tiny
.code
org 100h


init:
    mov ax, cs
    mov ds, ax
    mov es, ax
    call readLoop
    jmp exit

readLoop proc
    ;read line by line
    readLoop:
    ; read byte by byte
    mov ah, 3Fh         
    mov bx, 0 ;CHANGE TO BX = 1 TO STDIN! (now 0 for settings in tasm json)
    lea dx, charRead    
    mov cx, 1          
    int 21h             

    ;check for eof
    cmp ax, 0           
    jne not_eof
    call lineFound
    call calculateAverage
    call parseToPointersArray
    call bubbleSort
    call printToFile
    call exit

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
    mov bx, 1 ;multiplier
    mov cx, 10 ;base
    lea si, value
    mov dx, [si] 

    findEndOfString:   ;find where string ends to iterate backwards later      
    cmp byte ptr [si], 0
    jne stringNotEnd
    dec si                  
    jmp parseLoop   

    stringNotEnd:
    inc si                  
    jmp findEndOfString

    parseLoop:
    mov al, [si]            
    cmp al, '0' ; is current char a digit
    jb isNegative ; if it is before 0 it is not a digit
    sub al, '0'  
    cbw           
    mul bx
    add [num], ax            

    mov ax, bx
    mul cx ; multiplier*10
    mov bx, ax     

    dec si                   
    cmp si, offset value        
    jae parseLoop ; if si >= input start, continue parsing

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
    lea di, key
    mov cx, [len] ;works, but later CHECK the behaviour for adding val to [di] and incrementing [di+1]
    rep cmpsb 
    je key_found 

    cmp byte ptr [si], 0
    je not_found

    next_space:
    cmp byte ptr [si], 20h ; check if current character is a space
    je next_struct  
    inc si  
    jmp next_space ; continue searching for the space

    next_struct:
    inc si
    dec di
    jmp search_key

    key_found:
    ; here we add value to sum and incrementing counter

    mov di, si ; di - destination index - address of the end of array we got previously  
    mov cx, [num]
    mov ax, [di]
    add ax,cx 

    inc_sum:
    mov [si], al
    movsb
    mov [si], ah
    movsb 

    inc_counter:
    mov ax, [si]
    inc ax
    mov [si], al
    movsb
    mov [si], ah
    movsb

    ret

    not_found:
    ; here we add a new struct: key$, sum, counter
    mov di, si ; di - destination index - address of the end of array we got previously 
    dec di 
    mov si, offset key

    mov cx, [len]
    rep movsb ;copy from si to di len (in cx) times

    ;add di, 3
    mov ax, [num]      ; Load the value into AX
    mov [si], al       ; Move the lower byte (78h) into memory at SI
    movsb           ; Move SI to the next byte
    mov [si], ah     
    movsb 
    ;AL IS STORED BEFORE AH 

    mov ax, 1
    mov [si], al       
    movsb           
    mov [si], ah      
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
    mov bx, 0  
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
    cmp byte ptr [bx], 0 
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

    push ax ;0 for eof
    mov si, offset linesArray
    mov di, offset key
    inc [len] 
    call findKeyInArray
   
    end_of_line:
    ;prepare everything for next line processing
    pop ax 
    cmp ax, 0        
    jne not_end_of_file 
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

    cmp [si], 0 ;end of file
    je end_of_file

    inc si
    jmp to_end_of_key

        calc:
        xor ax,ax
        xor bx,bx
        xor dx,dx

        inc si
        mov ax, [si]
        inc si
        inc si
        mov bx, [si]
        cwd 

        divide:
        idiv bx ;ax has the quotient, dx has the remainder

        dec si
        dec si
        mov [si], ax
        
        inc si
        inc si
        mov [si], 0

        inc si
        
        mov ax, [si] ;for debug
        jmp to_end_of_key

    end_of_file:
    ret
calculateAverage endp
parseToPointersArray proc ;creating an array of pairs <offset, average> 

    mov di, offset pointersArray ;adding first struct
    xor cx,cx ;here will be an offset counter
    mov si, offset linesArray
    inc di

    findAverage:
    cmp byte ptr [si],'$'   
    je extract_average
    inc si
    inc cx
    jmp findAverage

    extract_average:
    inc di
    inc si

    mov ax, [si]
    mov [di], ax
    inc di
    inc structs_num

    findEndOfStruct:
    add si, 4
    add cx, 6 
    cmp byte ptr[si+1],0 ;means eof 
    je end_of_linesArray

    cmp byte ptr [si],20h
    je addOffset
    jmp findEndOfStruct

    addOffset:
    inc si
    inc di

    mov ax, cx
    mov [di], ax
    inc di

    jmp findAverage

    end_of_linesArray:
    ret

parseToPointersArray endp

bubbleSort proc ; struct size - 4 bytes
    mov bx, structs_num
    dec bx

    outer_loop:
    push bx
    xor si,si
    mov cx, structs_num
    dec cx

        inner_loop: 
        
        lea bx, pointersArray
        add bx, si
        add bx, 2
        mov ax, [bx]

        lea bx, pointersArray
        add bx, si
        add bx, 6
        mov dx, [bx]
        xor bx,bx

        cmp ax,dx
        jng no_swap 
        push si
        lea di, [pointersArray+si+4]
        lea si, [pointersArray+si]
        
        call swap
        pop si

        no_swap:
        add si, 4 ; struct size
        loop inner_loop
        pop bx
        dec bx
        jnz outer_loop
    ret

bubbleSort endp

swap proc
    push cx
    mov cx, 2 ; struct fields

        swap_loop:
        mov ax, [si]
        mov bx, [di]
        mov [di], ax
        mov [si], bx
        add si, 2
        add di, 2 
        loop swap_loop

    pop cx
    ret 
swap endp

printToFile proc
mov si, offset pointersArray
mov bl, [di]; for debug
mov cx, structs_num 

    next_char:
    push cx
    xor ax,ax
    mov ax, [si] ;dl offset
    mov di, offset linesArray
    add di, ax ;adding offset
    
    check_end_of_string:
    mov dl, [di]
    cmp dl, '$'
    je end_of_str
    call printChar 

    inc di
    jmp check_end_of_string

    end_of_str:
    ;print a space + average + Dh + Ah
    mov dl, 20h
    call printChar

    ;add si, 3 
    push si
    add si, 2
    call printNumber
    pop si

    mov dl, 0Dh 
    call printChar

    mov dl, 0Ah  
    call printChar

    ;prep for next iteration
    add si, 4

    pop cx
    loop next_char
    ret

printToFile endp

printChar proc
    mov ah, 02h 
    int 21h
    ret
printChar endp

printNumber proc ;num is in si
    mov bx, 10
    mov ax, [si]
    cmp ax,0
    jg not_neg

    mov isNeg, 1
    neg ax
    mov si, offset numStr + 5 + 1 + 1 + 1
    mov byte ptr [si],'$'
    jmp convertLoop

    not_neg:
    mov isNeg, 0
    mov si, offset numStr + 5 + 1 + 1
    mov byte ptr [si],'$'
    
    convertLoop:
    dec si
    xor dx,dx
    div bx
    add dl,'0'
    mov [si],dl
    test ax,ax
    jnz convertLoop

    cmp isNeg, 0
    je is_positive
    dec si
    mov byte ptr [si],'-'

    is_positive:

    printDec:
    mov dx,si
    mov ah, 09h
    int 21h

    call clear_string

    ret
printNumber endp

exit proc
    mov ax, 4C00h
    int 21h
    ret
exit endp

.data
    buffer db 255 dup(0)       
    errorMessage db "Error in reading file$"
    linesArray db 10000 dup(0)
    pointersArray db 1000 dup(0) ;pairs <offset to struct, average>
    linesArrayOffset dw 0
    key db 16 dup(0)
    value db 255 dup(0)
    numStr db 16 dup(0) 
    len dw 0
    structs_num dw 0
    isNeg db 1 dup(0)

.data?
    charRead db ?  
    num dw ?  

end init