;===================================================================
section .data
    format db '123456789 %d %%', 0x0
    string db 'Meow Meow', 0x0

;===================================================================
section .text
    global _start

;===================================================================
_start:
    ; jmp end

.real_start:

    mov rdi, format
    ; mov rdx, string
    mov rsi, 10

    ; push rbx
    ; push rbp
    ; push r10
    ; push r11

    xor rax, rax
    xor r14, r14

    mov r12, rsp
    sub rsp, 200

;===================================================================
;rax - количество символов в буфере (стеке)
;r14 - счетчик дополнительных аргументов (т.к. 5 передадутся через регистры, а остальные через стек)
;r13 - буфер для обработки символов
;r12 - инициализируется rsp и является указателем на начало буфера, куда будет записываться строка, которая будет выводиться
;rdi - первый аргумент, являющийся адресом строки формата
;===================================================================

;===================================================================
.next:
    ; call buffer_control

    mov r13b, [rdi]
    inc rdi     ;Сразу прибавляем, что бы потом не прописывать для каждого случая

    cmp r13b, '%'
    je .specific
    cmp r13b, 0h
    je end

    mov [r12 + rax], r13b
    dec rax
    jmp .next

;===================================================================
.specific:
    xor r13, r13
    mov r13b, [rdi]
    inc rdi

    cmp r13b, '%'
    je .spec_plus_spec

    call get_argument
; ;!!! in r15 - argument to spec

    cmp r13b, 's'
    je .spec_string

    cmp r13b, 'p'
    je .spec__h_ex

    sub r13b, 'b'
    cmp r13b, 6
    ja .spec_error
    jmp [.jump_table_b_h + r13*8]

; ;===================================================================
section .rodata
    align 8

.jump_table_b_h:
    dq   .spec__b_yte
    dq   .spec__c_har
    dq   .spec__d_ecimal
    dq   .spec_error
    dq   .spec__f_loat
    dq   .spec__g_float
    dq   .spec__h_ex

section .text

;===================================================================
.spec_plus_spec:
    mov byte [r12 + rax], '%'
    dec rax
    jmp .next

;===================================================================
.spec_string:

.next_spec_string:
    mov bl, [r15]
    cmp bl, 0
    je .next        ;!! end circle

    mov [r12 + rax], bl
    dec rax

    inc r15
    ; call buffer_control
    jmp .next_spec_string

;===================================================================
.spec__b_yte:
    push rcx
    mov rcx, 8
    rol r15b, 1

.next_spec_byte:
    push r15

    and r15b, 0x1
    cmp r15b, 0

    pop r15
    rol r15b, 1

    mov bx, '1'
    mov dx, '0'
    cmove bx, dx
    mov byte [r12 + rax], bl

    dec rax
    loop .next_spec_byte

    pop rcx
    jmp .next

;===================================================================
.spec__c_har:
    mov [r12 + rax], r15b
    dec rax
    jmp .next

;===================================================================
.spec__d_ecimal:
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    xor rcx, rcx

    test r15, r15
    js .spec_d_convert
    jmp .spec_d_main_circle

.spec_d_convert:
    neg r15
    mov rdx, '-'
    push rdx
    inc rcx

.spec_d_main_circle:
    test r15, r15
    jz .end_spec_d

    push rax
    mov rax, r15
    xor rdx, rdx
    div rbx

    add dl, '0'
    mov r15, rax
    pop rax

    push rdx
    inc rcx

    jmp .spec_d_main_circle

.end_spec_d:
    pop rdx
    mov [r12 + rax], dl
    dec rax
    loop .end_spec_d

    pop rdx
    pop rcx
    pop rbx
    jmp .next

;===================================================================
.spec__f_loat:

.spec__g_float:

.spec__h_ex:

.spec_error:

;===================================================================
end:
    call change_strait

    mov rsi, r12
    add rsi, rax
    mov rsp, rsi

    neg rax
    mov rdx, rax
    inc rdx

    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall



;===================================================================
; get_argument

; get argument to r15
; Entry:
;       r14 - amount given arguments
;       r12 - not used stack pointer (with address to ret)
; Return:
;       r15 - argument
;       r14 ++
;===================================================================
get_argument:
    cmp r14, 5
    ja .get_from_stack
    jmp [.jump_table + r14*8]

section .rodata
    align 8

.jump_table:
    dq   .arg_1
    dq   .arg_2
    dq   .arg_3
    dq   .arg_4
    dq   .arg_5

section .text

.get_from_stack:
    mov r15, [r12 + 8*(1 + r14 - 5)]
    jmp .end

.arg_1:
    mov r15, rsi
    jmp .end

.arg_2:
    mov r15, rdx
    jmp .end

.arg_3:
    mov r15, rcx
    jmp .end

.arg_4:
    mov r15, r8
    jmp .end

.arg_5:
    mov r15, r9

.end:
    inc r14
    ret


;===================================================================
; buffer_control
;
; Check len buffer in stack and resize it
; Entry:
;       rax - used size buffer
;       r12 - start buffer
;       rsp-8 - end buffer
; Destroy:
;       rsp - end of new buffer
;       rbx
;===================================================================
buffer_control:

    mov rbx, rsp
    sub rbx, r12
    sub rbx, rax
    add rbx, 32 ;16 - (ret_address); 16 - (add size)
    cmp rbx, 0

    ja .add_capacity
    ret

.add_capacity:
    pop rbx
    sub rsp, 100
    jmp rbx


; ;===================================================================
; ; strlen
; ;
; ; Entry:
; ;       r15 - start address
; ; Return:
; ;       rbx - len
; ;===================================================================
; strlen:
;     xor rbx, rbx
;
; .next:
;     cmp [r15 + rbx], 0
;     inc rbx
;     je .end
;     jmp .next
;
; .end:
;     ret

;===================================================================
; change_strait
;
; Entry:
;       r12 - start memory buffer
;       rax - len of buffer
;===================================================================
change_strait:
    push rcx
    push rdx
    push rsi
    push r8
    push r9
    push r10
    push r11

    xor r8, r8
    dec r8
    mov r9, rax
    neg r9
    sub r9, 2

    mov rcx, rax
    neg rcx

    inc rcx
    shr rcx, 1


.next:
    mov r10, r12
    sub r10, r8
    mov r11, r12
    sub r11, r9

    dec r10
    dec r11

    mov dl, byte [r10]
    mov sil, byte [r11]
    mov byte [r11], dl
    mov byte [r10], sil
    inc r8
    dec r9

    loop .next

    pop r11
    pop r10
    pop r8
    pop r9
    pop rsi
    pop rdx
    pop rcx
    ret
