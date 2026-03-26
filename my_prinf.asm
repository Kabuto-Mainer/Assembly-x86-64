;===================================================================
default rel

struc BUFFER
    .rax:   resq 1
    .rbx:   resq 1
    .rcx:   resq 1
    .rdx:   resq 1
    .rsi:   resq 1
    .rdi:   resq 1
    .rbp:   resq 1
    .rsp:   resq 1
    .r8:   resq 1
    .r9:   resq 1
    .r10:   resq 1
    .r11:   resq 1
    .r12:   resq 1
    .r13:   resq 1
    .r14:   resq 1
    .r15:   resq 1

endstruc
;===================================================================
section .data
    BIT_SYSTEM db '01'
    OCTA_SYSTEM db '01234567'
    HEX_SYSTEM db '0123456789ABCDEF'
    AMOUNT_STACK_ARG dq 0
    TEN_FLOAT dd 10.0
    TEN_DOUBLE dq 10.0

;===================================================================
section .bss
REGISTER_SAVE_BUFFER resb BUFFER_size

;===================================================================
section .text
    ; global _start
    global my_printf
    extern printf

;========W===========================================================
my_printf:
    mov [REGISTER_SAVE_BUFFER + BUFFER.rax], rax
    mov [REGISTER_SAVE_BUFFER + BUFFER.rbx], rbx
    mov [REGISTER_SAVE_BUFFER + BUFFER.rcx], rcx
    mov [REGISTER_SAVE_BUFFER + BUFFER.rdx], rdx
    mov [REGISTER_SAVE_BUFFER + BUFFER.rsi], rsi
    mov [REGISTER_SAVE_BUFFER + BUFFER.rdi], rdi
    mov [REGISTER_SAVE_BUFFER + BUFFER.rbp], rbp
    mov [REGISTER_SAVE_BUFFER + BUFFER.rsp], rsp
    mov  [REGISTER_SAVE_BUFFER + BUFFER.r8], r8
    mov  [REGISTER_SAVE_BUFFER + BUFFER.r9], r9
    mov [REGISTER_SAVE_BUFFER + BUFFER.r10], r10
    mov [REGISTER_SAVE_BUFFER + BUFFER.r11], r11
    mov [REGISTER_SAVE_BUFFER + BUFFER.r12], r12
    mov [REGISTER_SAVE_BUFFER + BUFFER.r13], r13
    mov [REGISTER_SAVE_BUFFER + BUFFER.r14], r14
    mov [REGISTER_SAVE_BUFFER + BUFFER.r15], r15

    xor rax, rax
    mov [AMOUNT_STACK_ARG], rax
    xor r14, r14

    mov r12, rsp
    sub r12, 8
    sub rsp, 40

;===================================================================
;rax - количество символов в буфере (стеке)
;r14 - счетчик дополнительных аргументов (т.к. 5 передадутся через sрегистры, а остальные через стек)
;r13 - буфер для обработки символов
;r12 - инициализируется rsp и является указателем на начало буфера, куда будет записываться строка, которая будет выводиться
;rdi - первый аргумент, являющийся адресом строки формата
;===================================================================

;===================================================================
.next:
    call buffer_control

    mov r13b, [rdi]
    inc rdi     ;Сразу прибавляем, что бы потом не прописывать для каждого случая

    cmp r13b, '%'
    je .specific
    cmp r13b, '\'
    je .slesh
    cmp r13b, 0h
    je end

    mov [r12 + rax], r13b
    dec rax
    jmp .next

;===================================================================
.slesh:
    xor r13, r13
    mov r13b, [rdi]
    inc rdi

    cmp r13b, 'n'
    je .slesh_n

    cmp r13b, 'r'
    je .slesh_r

    cmp r13b, '\'
    je .slesh_slesh

    jmp .next

.slesh_n:
    mov [r12 + rax], 10
    dec rax
    jmp .next

.slesh_r:
    mov [r12 + rax], 15
    dec rax
    jmp .next

.slesh_slesh:
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

    call get_standard_argument
; ;!!! in r15 - argument to spec

    cmp r13b, 's'
    je .spec_string

    cmp r13b, 'p'
    je .spec__h_ex

    cmp r13b, 'x'
    je .spec__h_ex

    sub r13b, 'b'
    cmp r13b, 6
    ja .spec_error

    lea rbp, [rel .jump_table_b_h]
    jmp qword [rbp + r13*8]

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

;-------------------
.next_spec_string:
    mov r13b, [r15]
    cmp r13b, 0
    je .next        ;!! end circle

    mov [r12 + rax], r13b
    dec rax

    inc r15
    call buffer_control
    jmp .next_spec_string

;===================================================================
.spec__b_yte:
    ; movsxd r15, r15d
    mov r15d, r15d
    mov r8, 1
    lea r9, [rel BIT_SYSTEM]
    call print_two_system
    jmp .next

;===================================================================
.spec__c_har:
    mov [r12 + rax], r15b
    dec rax
    jmp .next

;===================================================================
.spec__d_ecimal:
    movsxd r15, r15d
    call print_decimal
    jmp .next

;===================================================================
.spec__f_loat:
    call get_avx_argument

    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11

    xor r8, r8
    movd r8d, xmm8
    mov r9d, r8d
    shr r9d, 31
    cmp r9d, 0
    je .spec_f_without_sign

    mov byte [r12 + rax], '-'
    dec rax

    and r8d, ~0x80000000 ;clear sign bit

.spec_f_without_sign:

    movd xmm8, r8d
    mov r9d, r8d
    and r9d, 0x7F800000
    shr r9d, 23

    mov r10d, r8d
    and r10d, 0x007FFFFF

    cmp r9d, 255
    je .spec_f_inf_nan

    cvttss2si r15, xmm8
    mov r8, r15
    call print_decimal

    cvtsi2ss xmm9, r8
    subss xmm8, xmm9

    mov byte [r12 + rax], '.'
    dec rax

    mov rcx, 10

.spec_f_circle:
    mulss xmm8, [rel TEN_FLOAT]
    cvttss2si r8, xmm8
    cvtsi2ss xmm9, r8

    add r8b, '0'
    mov [r12 + rax], r8b
    dec rax

    subss xmm8, xmm9
    loop .spec_f_circle

    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx

    jmp .next

.spec_f_inf_nan:
    cmp r10d, 0

    mov r8d, 'nano'
    mov r9d, 'info'
    cmove r8d, r9d
    mov dword [r12 + rax], r8d
    sub rax, 3

    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx

    jmp .next

;===================================================================
.spec__g_float:
    call get_avx_argument

    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11

    xor r8, r8
    movq r8, xmm8
    mov r9, r8
    shr r9, 63
    cmp r9, 0
    je .spec_g_without_sign

    mov byte [r12 + rax], '-'
    dec rax

    mov r11, 0x8000000000000000
    neg r11
    and r8, r11 ;clear sign bit

.spec_g_without_sign:

    movq xmm8, r8
    mov r9, r8

    ;аналогично
    mov r11, 0x7FF0000000000000
    and r9, r11
    shr r9, 52

    mov r10, r8
    mov r11, 0x000FFFFFFFFFFFFF
    and r10, r11

    cmp r9, 2047
    je .spec_g_inf_nan

    cvttsd2si r15, xmm8
    mov r8, r15
    call print_decimal

    cvtsi2sd xmm9, r8
    subsd xmm8, xmm9

    mov byte [r12 + rax], '.'
    dec rax

    mov rcx, 6

.spec_g_circle:
    mulsd xmm8, [rel TEN_DOUBLE]
    cvttsd2si r8, xmm8
    cvtsi2sd xmm9, r8

    add r8b, '0'
    mov [r12 + rax], r8b
    dec rax

    subsd xmm8, xmm9
    loop .spec_g_circle

    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx

    jmp .next

.spec_g_inf_nan:
    cmp r10, 0

    mov r8d, 'onan'
    mov r9d, 'ofni'
    cmove r8d, r9d
    mov dword [r12 + rax], r8d
    sub rax, 3

    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx

    jmp .next

;===================================================================
.spec__h_ex:
    ; movsxd r15, r15d
    mov r15d, r15d
    mov r8, 4
    lea r9, [rel HEX_SYSTEM]
    call print_two_system
    jmp .next

;===================================================================
.spec__o_cta:
    ; movsxd r15, r15d
    mov r15d, r15d
    mov r8, 3
    lea r9, [rel OCTA_SYSTEM]
    call print_two_system
    jmp .next

;===================================================================
.spec_error:

;===================================================================
end:
    call change_strait

    push r12
    mov rsi, r12
    add rsi, rax
    ; mov rsp, rsi

    neg rax
    mov rdx, rax
    ; inc rdx

    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, [REGISTER_SAVE_BUFFER + BUFFER.rax]
    mov rbx, [REGISTER_SAVE_BUFFER + BUFFER.rbx]
    mov rcx, [REGISTER_SAVE_BUFFER + BUFFER.rcx]
    mov rdx, [REGISTER_SAVE_BUFFER + BUFFER.rdx]
    mov rsi, [REGISTER_SAVE_BUFFER + BUFFER.rsi]
    mov rdi, [REGISTER_SAVE_BUFFER + BUFFER.rdi]
    mov rbp, [REGISTER_SAVE_BUFFER + BUFFER.rbp]
    mov rsp, [REGISTER_SAVE_BUFFER + BUFFER.rsp]
    mov  r8, [REGISTER_SAVE_BUFFER + BUFFER.r8]
    mov  r9, [REGISTER_SAVE_BUFFER + BUFFER.r9]
    mov r10, [REGISTER_SAVE_BUFFER + BUFFER.r10]
    mov r11, [REGISTER_SAVE_BUFFER + BUFFER.r11]
    mov r12, [REGISTER_SAVE_BUFFER + BUFFER.r12]
    mov r13, [REGISTER_SAVE_BUFFER + BUFFER.r13]
    mov r14, [REGISTER_SAVE_BUFFER + BUFFER.r14]
    mov r15, [REGISTER_SAVE_BUFFER + BUFFER.r15]

    pop rbx
    ; call printf WRT ..plt

    push rbx
    mov rbx, [REGISTER_SAVE_BUFFER + BUFFER.rbx]

    ret


;===================================================================
; get_argument

; get argument to r15
; Entry:
;       r14 - amount given arguments
;       r12 - not used stack pointer
; Return:
;       r15 - argument
;       r14 ++
;===================================================================
get_standard_argument:
    cmp r14d, 5
    jae .get_from_stack

    push r13
    xor r13, r13
    mov r13d, r14d
    lea rbp, [rel .jump_table]
    jmp qword [rbp + r13*8]

.get_from_stack:
    push r14
    mov r14, qword [rel AMOUNT_STACK_ARG]
    mov r15, [r12 + 8*r14 + 16]
    inc r14
    mov qword [rel AMOUNT_STACK_ARG], r14
    pop r14

    push r13
    jmp .end

.arg_1:
    mov r15, [REGISTER_SAVE_BUFFER + BUFFER.rsi]
    jmp .end

.arg_2:
    mov r15, [REGISTER_SAVE_BUFFER + BUFFER.rdx]
    jmp .end

.arg_3:
    mov r15, [REGISTER_SAVE_BUFFER + BUFFER.rcx]
    jmp .end

.arg_4:
    mov r15, [REGISTER_SAVE_BUFFER + BUFFER.r8]
    jmp .end

.arg_5:
    mov r15, [REGISTER_SAVE_BUFFER + BUFFER.r9]

.end:
    pop r13
    inc r14
    ret

section .rodata
    align 8

.jump_table:
    dq   .arg_1
    dq   .arg_2
    dq   .arg_3
    dq   .arg_4
    dq   .arg_5

section .text


;===================================================================
; get_avx_argument
;
; get avx argument to xmm8
; Entry:
;       r14 - amount given argument
;       r12 - not used stack pointer
; Return:
;       xmm8 - avx argument
;===================================================================
get_avx_argument:
    dec r14

    push r15
    cmp r14d, 5
    jnae .not_added_argument

    mov r15, [rel AMOUNT_STACK_ARG]
    cmp r15, 0
    je .not_added_argument
    dec r15
    mov [rel AMOUNT_STACK_ARG], r15

.not_added_argument:
    pop r15

    rol r14, 32

    cmp r14d, 8
    jae .get_from_stack

    lea rbp, [rel .jump_table]

    push r13
    xor r13, r13
    mov r13d, r14d
    jmp qword [rbp + r13*8]

.arg_1:
    movaps xmm8, xmm0
    jmp .end

.arg_2:
    movaps xmm8, xmm1
    jmp .end

.arg_3:
    movaps xmm8, xmm2
    jmp .end

.arg_4:
    movaps xmm8, xmm3
    jmp .end

.arg_5:
    movaps xmm8, xmm4
    jmp .end

.arg_6:
    movaps xmm8, xmm5
    jmp .end

.arg_7:
    movaps xmm8, xmm6
    jmp .end

.arg_8:
    movaps xmm8, xmm7
    jmp .end

.get_from_stack:
    push r14
    mov r14, [rel AMOUNT_STACK_ARG]
    movsd xmm8, [r12 + 8*r14 + 16]
    inc r14
    mov [rel AMOUNT_STACK_ARG], r14
    pop r14
    push r13

.end:
    pop r13
    inc r14
    rol r14, 32
    ret

section .rodata
    align 8

.jump_table:
    dq   .arg_1
    dq   .arg_2
    dq   .arg_3
    dq   .arg_4
    dq   .arg_5
    dq   .arg_6
    dq   .arg_7
    dq   .arg_8

section .text

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

    mov rbx, r12
    add rbx, rax

    sub rbx, rsp
    sub rbx, 32 ;8 - (ret_address); 24 - (add size)
    test rbx, rbx

    js .add_capacity
    ret

.add_capacity:
    pop rbx
    sub rsp, 1600
    jmp rbx
    ret


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
    sub r9, 1

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


;===================================================================
;
;===================================================================
print_decimal:
    push rcx
    push rdx
    push r8
    push r9

    mov r9, r15

    mov r8, 10
    xor rcx, rcx

    test r15, r15
    js .convert
    jz .zero
    jmp .main_circle

.convert:
    neg r15

.main_circle:
    test r15, r15
    jz .end

    push rax
    mov rax, r15
    xor rdx, rdx
    div r8

    add dl, '0'
    mov r15, rax
    pop rax

    push rdx
    inc rcx

    jmp .main_circle

;-------------------
.end:
    test r9, r9
    jns .not_add_minus

    mov rdx, '-'
    push rdx
    inc rcx
.not_add_minus:

.circle:

    pop rdx
    mov [r12 + rax], dl
    dec rax
    loop .circle

    pop r9
    pop r8
    pop rdx
    pop rcx

    ret
;-------------------
.zero:
    mov [r12 + rax], '0'
    dec rax

    pop r9
    pop r8
    pop rdx
    pop rcx

    ret

;===================================================================
; print number in system pow(2)
;
; r8 - pow system (1, 3, 4)
; r9 - address string with format ('01', '01234567', '0123456789ABCDEF')
;===================================================================
print_two_system:
    push rbx
    push rcx
    push rdx
    push r10
    push r11

    test r15, r15
    jz .zero

    mov r10, r15
    mov rcx, r8
    mov r8, 1
    shl r8, cl
    dec r8
    xor rdx, rdx

    jmp .main_circle

.main_circle:
    test r10, r10
    jz .end

    mov rbx, r10
    and rbx, r8 ;get value % system

    mov r11b, [r9 + rbx]
    push r11
    shr r10, cl
    inc rdx

    jmp .main_circle

;-------------------
.end:
    mov rcx, rdx

.circle:
    pop rdx

    mov [r12 + rax], dl
    dec rax
    loop .circle

    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rbx

    ret
;-------------------
.zero:
    mov [r12 + rax], '0'
    dec rax

    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rbx

    ret
