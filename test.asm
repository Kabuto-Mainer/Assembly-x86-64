section .data
    msg db 'Hello from NASM!', 0xA
    len equ $ - msg

section .text
    global _start

_start:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg        ; текст
    mov rdx, len        ; длина
    syscall

    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; статус 0
    syscall
