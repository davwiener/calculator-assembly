;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .rodata
    prompt:
            DB  ">>calc: ",0    ; Format string
            
    prompt_p:
            DB  ">>",0  ; Format string
            
    layout:
            DB  "%02hx",10,0
            
    layout2:
            DB  "%hx",0
            
    layout_decimal:
            DB  "%d",10,0
            
    layout_link:
            DB  "%02hx",0
            
    newLine:
            DB  10,0
    
    format_string:
            DB "%s",10,0
    
    error_msg_exp:
            DB  ">>Error: exponent too large",10,0    ; Format string
            
    error_msg_arg:
            DB  ">>Error: Insufficient Number of Arguments on Stack",10,0   ; Format string
            
    error_msg_overflow:
            DB  ">>Error: Operand Stack Overflow",10,0  ; Format string
            
    debug_message:
            DB  "**DebugMode** Stack Status (new number in the bottom):",; Format string
            
    debug_message2:
            DB  "**DebugMode** New number was pushed into stack (link goes from LSB to MSB, two digits per byte):"; Format string
        
    my_stack_size equ 5;
    link_size equ 5;
    EOL equ 0xA; '/n' represnation in hexa, end of line
    buffer_size equ 80; '/n' represnation in hexa
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .bss

    my_stack:
            RESB    4*my_stack_size;
            
    buffer:
            RESB    82;
   
    debug_mode:
            resb 32; 
    stack_index_counter:
            resb 32
      counter:
            resb 32      

    extern exit
    extern printf
    extern fprintf
    extern malloc
    extern free
    extern fgets
    extern stderr
    extern stdin
    extern stdout 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .data

    number_of_operations:
            DW	0;
       
    %macro pushr 0 
        push ebx
        push ecx
        push edx
    %endmacro
    
    %macro popr 0 
        pop edx
        pop ecx
        pop ebx
    %endmacro
        
    
    %macro printLink 0 
        pushad
        %%loop:
            mov ecx, 0
            mov cl, [edi]
            push ecx
            push layout_link
            call printf
            add esp, 8
            cmp dword [edi+1], 0
            je %%finish_loop
            mov edi, [edi+1]
            jmp %%loop
        %%finish_loop:
            pushad
            push newLine
            call printf
            add esp,4
            popad
        popad
     %endmacro
     
     
     
     %macro special_print 1
            mov ecx, 0
            mov byte cl, [eax]
            pushad
            push ecx
            push %1
            call printf
            add esp, 8
            popad
            inc eax
            
     %endmacro
     
     
     
     
        %macro printLinkReverse 1 
        
        pushad
        mov ebx,[debug_mode]
        add edx, %1
        mov edi, 0
        mov edi, [my_stack+4*edx]
        mov eax, buffer
        add eax, 80
        mov byte [eax+1], 0xA
        mov byte [eax+2], 0
        

        %%loop:
            mov ecx, 0
            mov cl, [edi]
            mov byte [eax], cl
            cmp dword [edi+1], 0
            je %%print
            dec eax
            mov edi, [edi+1]
            jmp %%loop
            
        %%print:
            %%first:
                cmp byte [eax], 0xA
                jg %%all
                special_print layout2
                cmp byte [eax], EOL
                je  %%finish_loop
            
            %%all:
                special_print layout_link
                cmp byte [eax], EOL
                je  %%finish_loop
                jmp %%all
        
        
        %%finish_loop:
            mov [debug_mode],ebx
            pushad
            push newLine
            call printf
            add esp,4
            popad
            popad
     %endmacro
     
     
     
          %macro free_linkedlist 0
            %%loop:
                mov edx, [edi+1]
                pushad
                push dword edi
                call free
                add esp, 4
                popad
                mov edi, edx
                cmp edi, 0
                je %%end_loop
                jmp %%loop
            %%end_loop:
     %endmacro
     
     
    %macro addLink 0
            pushr 
            mov eax, link_size
            push eax
            call malloc
            cmp eax, 0
            je return
            add esp, 4
            popr
            mov [eax], cl
            mov [eax+1], edi
            mov edi, eax
    %endmacro
     
     
     %macro print_inserted_byte 0
            pushad
            push ecx
            push layout
            call printf
            add esp, 8
            popad
     %endmacro
     
     
    %macro malloc_link 1-3
        pushr 
        mov eax, link_size
        push eax
        call malloc
        cmp eax, 0
        je return
        add esp, 4
        popr
        mov %1, eax
        mov edi, %2
        mov ecx, 0
        mov cl, [esi]
        mov [edi], cl
        cmp dword [esi+1], 0
        jne %%finishdd
        finishss %3
    %%finishdd:
       mov esi, [esi+1]
     %endmacro


     %macro finishss 1 
             mov edx, [stack_index_counter]
             inc edx
             mov [stack_index_counter], edx
             mov eax,%1
             cmp eax,1
             je back_from_dupliacate
             jmp read_input
        %endmacro
     
     
     %macro pop_may_print 1
        pushad
        mov ebx,[stack_index_counter]
        dec ebx
        mov [stack_index_counter],ebx
        mov edi,[my_stack+ebx*4]
        mov edx ,%1
        cmp edx ,1
        je %%no_print
        printLinkReverse [stack_index_counter]
    %%no_print:
        mov eax,0
        mov [my_stack+ebx*4], eax
        cmp edx ,1
        je %%no_read ;no need to return yet
        jmp read_input
    %%no_read:
        popad
    %endmacro
     
        %macro check_fix 0 
                cmp esi, 0
                jne %%here
                mov byte [done_esi], 1
                jmp %%nothere
                
                %%here:
                mov esi, [esi+1]
                
                %%nothere:
                
               
                
                cmp edx, 0
                jne %%here2
    
                mov byte [done_edx], 1
                
                jmp %%nothere2
                %%here2:
                mov edx, [edx+1]
                
                
                
                %%nothere2:
                mov eax,0
                add eax, [done_esi]
                add eax, [done_edx]
                cmp eax, 2
        %endmacro
     
     
     %macro print_eror 1 
            pushad
            push %1
            call printf
            add esp, 4
            popad
            popad
            jmp read_input
     %endmacro

     %macro change_to_binary 0
          
            mov ecx,0
            mov eax ,0
            mov ebx ,0
            mov byte al ,[esi];; asarot
            shr al ,4
            mov bl,10
            mul bl
            mov byte bl ,[esi];;ahadot
            shl bl,4
            shr bl,4
            add al,bl
            mov cl ,al
    %endmacro
            



    %macro add_may_shiftl 1
        pushad
        clc
        mov edx,[stack_index_counter]
        mov edi,dword [my_stack+edx*4-4];;first--edi
        mov esi,dword [my_stack+edx*4-8];;sec--esi
        mov ecx ,0
        mov edx,0
        pushfd
        %%add:
            mov eax, 0
            mov ebx, 0
            mov byte al, [esi]
            mov byte bl, [edi]
            popfd
            adc al, bl
            daa
            pushfd 
            mov [esi],byte al
            cmp dword [edi+1], 0
            je %%firstisamaller;; fisrt argument may is smaller
            mov edi,[edi+1]
            cmp dword [esi+1], 0
            je %%secunedissmaller ;; secuned argument may is smaller
            mov esi,[esi+1]
            jmp %%add
        %%firstisamaller:
            mov eax,0
            mov ebx,0
            cmp dword [esi+1], 0
            je %%finish_add
            mov esi,[esi+1]
            mov byte al ,[esi]
            mov byte bl,0
            popfd
            adc al, bl
            daa
            pushfd 
            mov [esi],byte al
            mov ebx, 0
            cmp dword [esi+1], 0
            je %%finish_add
            jmp %%firstisamaller
        %%secunedissmaller:
            mov eax, link_size
            push eax
            call malloc
            cmp eax, 0
            je return
            add esp, 4
            mov ecx,eax ;;save the address
            mov eax,0
            mov ebx,0
            mov byte bl ,[edi]
            popfd
            adc al, bl
            daa
            pushfd
            mov [ecx],byte bl
            mov [esi+1],ecx
            mov esi,[esi+1]
            mov ebx, 0
            cmp dword [edi+1], 0
            je %%finish_add
            mov edi,[edi+1]
            jmp %%secunedissmaller
        %%finish_add: 
            pop_may_print 1;;pop and not print 
            popfd
            jnc %%no_carry
            pushr
            mov eax, link_size
            push eax
            call malloc
            cmp eax, 0
            je return
            add esp, 4
            mov byte [eax], 1b
            mov [esi+1], eax
            popr
        %%no_carry: 
            mov eax, %1
            cmp eax, 0
            je %%back_to_read_input 
            jmp back_from_addition   
        %%back_to_read_input:
            popad
            jmp read_input
    %endmacro

    %macro inc_number_of_operations 0
        mov ecx, 0
        mov ecx, [number_of_operations]
        inc ecx
        mov [number_of_operations], ecx
    %endmacro

    %macro check_num_size 0
        mov esi , [my_stack+edx*4-4];;get the counter
        cmp [esi+1],dword 0
        je %%end
        print_eror  error_msg_exp
        %%end:
    %endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .text

    align 16
    global main
    global my_calc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



main: 

    push ebp
    mov dword [debug_mode] ,0
    mov dword [stack_index_counter],0
    mov dword [counter],0
    mov ebp, esp
    mov edx, 0
    mov ebx, dword [ebp+8]  ; Get first argument - x   argc   
    cmp ebx, 1
    je .continue
    mov ebx, dword [ebp+12]
    add ebx, 4
    mov ebx, [ebx]
    mov ecx,0
    mov byte cl, [ebx]
    cmp cl, '-'
    jne .continue
    mov byte cl, [ebx+1]
    cmp cl, 'd'
    jne .continue
    mov dword [debug_mode], 1

    
    .continue:
    pushad
    call my_calc
    push eax
    push layout_decimal
    call printf
    add esp, 8
    popad               ; Restore registers
    mov eax, 1
    push eax
    call exit
        
        
my_calc:

    push ebp
    mov ebp, esp	        ; Entry code - set up ebp and esp
    
     read_input:
    
        mov al, [debug_mode]
        cmp al, 1
        jne .continue
        
        jmp print_stack

        .continue:
        ;;;print prompt;;;
        push prompt
        call printf
        add esp,4
        
        ;;;reading to buffer from stdin;;;;
        push dword [stdin];
        push buffer_size;
        push buffer;
        call fgets
        add esp, 12

        ;;;setting a pointer to buffer and checking the type of the input;;;;
        mov esi, buffer
        cmp byte [esi], 'q'
        je return
        cmp byte [esi], '9'
        jg command
        cmp byte [esi], '+'
        je addition
        jl read_input
        cmp byte [esi], '0'
        jl read_input
        jmp found_number

    
     found_number:
    
    
         mov edi, 0
         mov edx, esi
         jmp check_overflow
        
      
        .remove_zero:
            
            cmp byte [esi],'0'
            jne .check_valid
            inc esi
            mov edx, esi
            jmp .remove_zero
            
            
        .check_valid:
            cmp byte [esi], EOL
            jne .loop
            dec esi
            mov edx, esi
            
            
        .loop: 
        
            cmp byte [esi],EOL
            je .end_loop
            inc esi
            jmp .loop
            
        .end_loop:
        
            pushad
            mov eax, esi
            mov esi, edx
            sub eax, esi
            shr eax, 1
            popad
            mov esi, edx
            jc .odd_length
            jnc .even_length
            
            
        .odd_length:
                        mov ecx, 0
            mov byte cl, byte [esi]
            sub cl, 48
            ;print_inserted_byte
            addLink
            inc esi
            jmp .cont
            
            
        .even_length:
            jmp .cont

        .cont:  
  

        
            cmp byte [esi], EOL
            je set_next
            
            ;;;calculate 2nd digit;;;;
            mov ecx, 0
            mov byte cl, byte [esi+1]
            sub cl, 48
            ror cl, 4
            
            
            ;;;calculate 1st digit;;;;
            mov eax,0
            mov byte al, byte[esi]
            sub al, 48
            add byte cl, al
            ror cl,4
            
            ;print_inserted_byte
            addLink
            add esi,2
            jmp .cont        
            

    check_overflow:
        mov eax, 0
        mov al, [stack_index_counter]
        cmp al, 4
        jle found_number.remove_zero
        pushad
        push error_msg_overflow
        call printf
        add esp, 4
        popad
        jmp read_input
        
        
    addition:
       
        mov edx,[stack_index_counter]
        cmp edx,1
        jg ok_to_add
        pushad
        print_eror error_msg_arg 
    ok_to_add:
        inc_number_of_operations
        add_may_shiftl 0
       
            
            
    command:;;finding the right command
        cmp byte [esi], 'p'
        je pop_and_print
        cmp byte [esi], 'd'
        je duplicate
        cmp byte [esi], 'r'
        je shfr
        cmp byte [esi], 'l'
        je shfl
        jmp read_input

    shfr:
            pushad
            mov edx ,[stack_index_counter]
            cmp edx, 1
            jg ok_to_shiftr
            print_eror error_msg_arg
    ok_to_shiftr:
        check_num_size
        inc_number_of_operations
        change_to_binary
        cmp cl,0
        je finish_n_add
            loop_shiftingr:
                mov edx ,[stack_index_counter]   
                mov eax,0 
                mov edi , [my_stack+edx*4-8]
                mov edx,0  
                shifting:
                    mov eax ,0
                    mov ebx ,0
                    mov byte al ,[edi];; asarot
                    shr al ,4
                    mov bl,10
                    mul bl
                    shr al,1
                    mov byte bl ,[edi];;ahadot
                    shl bl,4
                    shr bl,4
                    cmp edx,0  
                  je first_time 
                    mov bh,bl
                    shr bh,1
                  jnc first_time
                    mov byte bh ,[esi]
                    add bh,80
                    mov [esi],byte bh
                first_time:
                    inc edx
                    shr bl,1
                    add al,bl
                    jmp back_to_bcd
                ready_to_insert:
                    mov [edi],byte al
                    cmp [edi+1],dword 0
                    je end_shift
                    mov esi,edi
                    mov edi,[edi+1]
                    jmp shifting
                end_shift:
                    cmp [edi] ,byte 0
                    jne ready_for_next_link ;;delete the last ling if its 0;
                delete_last_link:
                    mov [esi+1],dword 0
                ready_for_next_link:
                    loop loop_shiftingr, ecx
                finish_n_add: 
                    pop_may_print 1      
                    popad
                    jmp read_input

             back_to_bcd:
                    cmp al,10
                    jl ready_to_insert
                add6:
                   cmp al, 20
                    JAE add12
                    add al,6
                    jmp ready_to_insert
                add12:
                    cmp al,30
                    JAE add18
                    add al,12
                    jmp ready_to_insert
                add18:
                    cmp al, 40
                    JAE add24
                    add al,18
                    jmp ready_to_insert
                add24:
                    add al,24
                    jmp ready_to_insert
    

    shfl:
            pushad
            mov edx ,[stack_index_counter]
            cmp edx,1
            jg LALALA
            print_eror error_msg_arg
    LALALA: 
            check_num_size
            inc_number_of_operations
            change_to_binary
            mov [counter],cl
            and edx , 0xff
            mov [stack_index_counter],edx
            cmp edx, 1
            jg ok_to_shiftl
            print_eror error_msg_arg
            
        ok_to_shiftl: 
            pop_may_print 1 
            loop_shiftingl:
            mov edx,[stack_index_counter]
                cmp ecx,0
                je finishd_shftl
                mov esi, [my_stack+(edx-1)*4]  
                malloc_link  [my_stack+(edx)*4], eax,1
            continue2:
                malloc_link  [edi+1], [edi+1],1
                jmp continue2
            back_from_dupliacate:
                add_may_shiftl 1;; add the num to itself
            
            back_from_addition:
        
                mov cl,[counter]
                dec ecx
                mov [counter],cl
                jmp loop_shiftingl
            finishd_shftl:
                popad
                jmp read_input


    pop_and_print:
        pushad
        mov edx, [stack_index_counter]
        cmp edx ,0
        je .Error
        inc_number_of_operations
        push prompt_p
        call printf
        add esp,4
        pop_may_print 0
    .Error:
        pushad
        print_eror error_msg_arg;;">>Error: Insufficient Number of Arguments on Stack"
    
    
    
    duplicate:
        pushad
        mov edx, [stack_index_counter]
        cmp edx, 0
        je .error1
        mov edx, [stack_index_counter]
        cmp edx, 5
        je .error2
        inc_number_of_operations
        mov esi, [my_stack+(edx-1)*4]  
        malloc_link  [my_stack+(edx)*4], eax,0
        
        .continue:
        malloc_link  [edi+1], [edi+1],0
        jmp .continue
    
        .error1:
        print_eror  error_msg_arg
        .error2:
        print_eror error_msg_overflow

    
    set_next:

        ;printLink
        mov edx, 0
        mov dl, [stack_index_counter]
        mov eax, 0
        mov eax, my_stack
        mov [eax+edx*4], edi
        
        
        mov ecx, 0
        mov byte cl, [debug_mode]
        cmp cl, 1
        jne .continue


        pushad
        push debug_message2
        push format_string
        push dword [stderr]
        call fprintf
        add esp, 12
        popad
        printLink
      
        .continue:
        inc dl  
        mov byte [stack_index_counter], dl
        jmp read_input
    
            
    ;;;quit my_calc;;;
    
    return:
       
        
        mov eax, 0
        mov al, [number_of_operations]
        mov esp, ebp    ; Function exit code
        pop ebp
        ret

    print_stack:
    
        mov ebx, 0
        mov bl ,[stack_index_counter]
        cmp bl, 0
        je read_input.continue
        mov edx, 0
        pushad
        push debug_message
        call printf
        add esp,4
        popad
        
        printing:
          
            printLinkReverse 0
            inc edx
            cmp edx ,ebx
            je read_input.continue
            jmp printing
        