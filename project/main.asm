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
    mov ax, [num]
    mov cx, [di+3]
    add cx,ax
    mov al, cl
    or al, 10h
    test al, 80h
    jz highest_bit_zero   ; jump if the highest bit is zero
    highest_bit_one:
    mov ch, 0FFh  ; if highest bit is 1, set all bits in CH to 1
    jmp inc_sum
    highest_bit_zero:
    xor ch, ch    ; if highest bit is 0, set all bits in CH to 0
    inc_sum:
    mov [di+2],ch
    mov [di+3],cl

    add di, 4
    mov al, [di+1]
    mov ah, [di]
    inc ax
    mov [di], ah
    mov [di+1],al

    jmp end_of_line

    not_found:
    ; here we add a new struct: key$, sum, counter
    mov di, si ;di - destination index - address of the end of array we got previously 
    dec di 
    mov si, offset key

    mov cx, [len]
    rep movsb ;copy from si to di len (in cx) times

    add di, 3
    mov ax, [num]
    mov [si], ax
    movsb
    
    inc di
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
    je end_of_file

    inc si
    jmp to_end_of_key

        calc:
        xor ax,ax
        xor bx,bx
        xor dx,dx
        mov dh, [si+1]
        mov dl, [si+2]
        mov ah, [si+3]
        mov al, [si+4]

        mov bh, [si+5]
        mov bl, [si+6]

        div bx ;ax has the quotient
        mov byte ptr [si+4],al
        mov byte ptr [si+3],ah

        mov byte ptr [si+5],0 ; clear counter
        mov byte ptr [si+6],0 ; clear counter
        add si,8
        jmp to_end_of_key

    end_of_file:
    ret
calculateAverage endp
parseToPointersArray proc ;creating an array of pairs <offset, average> 

    mov di, offset pointersArray ;adding first struct
    xor cx,cx ;here will be an offset counter
    mov si, offset linesArray

    findAverage:
    cmp byte ptr [si],'$'   
    je extract_average
    inc si
    inc cx
    jmp findAverage

    extract_average:
    add di,2
    add si, 3
    mov ax, [si]
    mov [di], ax
    inc di
    add cx, 3
    inc structs_num

    findEndOfStruct:
    add si, 4
    add cx, 4
    cmp byte ptr[si+1],0 ;means eof 
    je end_of_linesArray

    cmp byte ptr [si],20h
    je addOffset
    jmp findEndOfStruct

    addOffset:
    inc si
    inc cx
    inc di
    mov al, cl
    mov ah, ch
    mov [di], ch
    mov [di+1], cl ;to save endianness here

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
        jng no_swap ;TO MAKE IT SORT IN A DESCENDING WAY, CHANGE HERE TO "JUMP IF GREATER" and that`s all
        lea di, [pointersArray+si+4]
        lea si, [pointersArray+si]
        push si

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
        add di, 2 ;TODO: fix this sizing
        loop swap_loop

    pop cx
    ret 
swap endp

exit proc
    mov ax, 4C00h
    int 21h
    ret
exit endp

.data
    ;filename db 'input.txt',0                  
    buffer db 255 dup(0)       
    errorMessage db "Error in reading file$"
    linesArray db 10000 dup(0)
    pointersArray db 1000 dup(0) ;pairs <offset to struct, average>
    linesArrayOffset dw 0
    key db 16 dup(0)
    value db 255 dup(0) 
    len dw 0
    structs_num dw 0

.data?
    ;file_handle dw ? 
    charRead db ?  
    num dw ?  

end init