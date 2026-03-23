;===================================================================
default rel
;===================================================================
section .data
    format db 'Poltorashka say %d %d \ntimes a week', 0x0
    string db 'Meow Meow', 0x0
    float_value dd 0x4048F5C3 ;3.14
    AMOUNT_STACK_ARG dq 0
    TEN_FLOAT dd 10.0
    TEN_DOUBLE dq 10.0

;===================================================================
section .text
    ; global _start
    global my_printf

;========W===========================================================
; _start:
    ; jmp end

my_printf:
    ; mov rdi, format
    ; mov rsi, -1
    ; mov rsi, string
    ; mov rdx, 1000
    ; mov rcx, 1
    ; mov r8, 2
    ; mov r9, 3
    ; movss xmm0, [float_value]
    ; push 0x10f
    ; push 4

    ; push rbx
    ; push rbp
    ; push r10
    ; push r11

    xor rax, rax
    xor r14, r14

    mov r12, rsp
    sub r12, 8
    sub rsp, 10

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
    push rcx
    push rdx

    mov rcx, 8
    rol r15b, 1

;-------------------
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

    pop rdx
    pop rcx
    jmp .next

;===================================================================
.spec__c_har:
    mov [r12 + rax], r15b
    dec rax
    jmp .next

;===================================================================
.spec__d_ecimal:
    call print_decimal
    jmp .next

;-------------------
.spec_d_zero:
    mov [r12 + rax], '0'
    dec rax
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

    mov rcx, 6

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
    push rbx
    push rcx
    push rdx

    mov rbx, 16
    xor rcx, rcx

;-------------------
.spec_h_main_circle:
    test r15, r15
    jz .end_spec_h

    push rax
    mov rax, r15
    xor rdx, rdx
    div rbx

    mov r15, rax
    pop rax

    push rdx
    inc rcx

    jmp .spec_h_main_circle

;-------------------
.end_spec_h:
    pop rdx

    mov rbx, 'a' - 10
    mov r15, '0'
    cmp dl, 9

    cmova r15, rbx
    add dl, r15b

    mov [r12 + rax], dl
    dec rax
    loop .end_spec_h

    pop rdx
    pop rcx
    pop rbx
    jmp .next

;===================================================================
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

    ; ret
    mov rax, 60
    xor rdi, rdi
    syscall



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
    mov r15, [r12 + 8*r14 + 8]
    inc r14
    mov qword [rel AMOUNT_STACK_ARG], r14
    pop r14

    push r13
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
    mov r14, [AMOUNT_STACK_ARG]
    movsd xmm8, [r12 + 8*r14 + 8]
    inc r14
    mov [AMOUNT_STACK_ARG], r14
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
    sub rsp, 20
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

    pop r8
    pop rdx
    pop rcx

    ret
