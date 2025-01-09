; Build and run with:
;   nasm -f elf64 thread.asm && gcc -pthread thread.o -o thread && ./thread

extern pthread_create
extern pthread_join
extern write
extern sleep
extern exit

section .data
    msg1 db "Thread 1 running...", 10, 0
    msg1_len equ $ - msg1

    msg2 db "Thread 2 running...", 10, 0
    msg2_len equ $ - msg2

    msg_main db "Main thread waiting...", 10, 0
    msg_main_len equ $ - msg_main

section .bss
    thread1_id resq 1
    thread2_id resq 1

section .text
    global _start

; Thread functions need to preserve registers according to C ABI
thread1:
    push    rbp
    mov     rbp, rsp

    mov     rax, 1          ; write syscall
    mov     rdi, 1          ; stdout
    mov     rsi, msg1       ; message
    mov     rdx, msg1_len   ; length
    syscall

    mov     rsp, rbp
    pop     rbp
    xor     rax, rax       ; return 0
    ret

thread2:
    push    rbp
    mov     rbp, rsp

    mov     rax, 1          ; write syscall
    mov     rdi, 1          ; stdout
    mov     rsi, msg2       ; message
    mov     rdx, msg2_len   ; length
    syscall

    mov     rsp, rbp
    pop     rbp
    xor     rax, rax       ; return 0
    ret

_start:
    push    rbp
    mov     rbp, rsp

    ; Create thread 1
    mov     rdi, thread1_id    ; pthread_t *thread
    xor     rsi, rsi          ; pthread_attr_t *attr (NULL)
    mov     rdx, thread1      ; start_routine
    xor     rcx, rcx          ; arg
    call    pthread_create

    ; Create thread 2
    mov     rdi, thread2_id    ; pthread_t *thread
    xor     rsi, rsi          ; pthread_attr_t *attr (NULL)
    mov     rdx, thread2      ; start_routine
    xor     rcx, rcx          ; arg
    call    pthread_create

    ; Print main thread message
    mov     rax, 1             ; write syscall
; -------------
; Thread 2
; -------------
thread2:
    ; Print message
    mov     rax, 1             ; sys_write
    mov     rdi, 1             ; stdout
    mov     rsi, msg2          ; address of message
    mov     rdx, msg2_len      ; length
    syscall

    ; Exit thread
    mov     rax, 60            ; sys_exit
    xor     rdi, rdi           ; exit status = 0
    syscall

; -------------
; _start
; -------------
_start:
    ;------------------------------------------------------------------
    ; 1) Clone Thread 1
    ;------------------------------------------------------------------
    lea     rsi, [stack1 + 4096]  ; RSI = new stack pointer top
    mov     rax, 56               ; rax = sys_clone
    mov     rdi, 0x00000100       ; CLONE_VM
    or      rdi, 0x00000800       ; CLONE_FILES
    or      rdi, 0x00010000       ; CLONE_SIGHAND
    or      rdi, 0x02000000       ; CLONE_THREAD
    xor     rdx, rdx              ; parent_tid = NULL
    xor     r10, r10              ; child_tid = NULL
    lea     r8, [tls1]            ; TLS pointer
    syscall

    ; After clone, rax = 0 in the child, rax > 0 in the parent
    cmp     rax, 0
    jne     create_thread2   ; If not zero, we are the parent -> jump

    ; CHILD THREAD #1:
    ; Jump to (or call) thread1
    call    thread1
    ; never returns, but just in case:
    jmp     exit_all

create_thread2:
    ;------------------------------------------------------------------
    ; 2) Clone Thread 2
    ;------------------------------------------------------------------
    lea     rsi, [stack2 + 4096]  ; RSI = new stack pointer top
    mov     rax, 56               ; rax = sys_clone
    mov     rdi, 0x00000100       ; CLONE_VM
    or      rdi, 0x00000800       ; CLONE_FILES
    or      rdi, 0x00010000       ; CLONE_SIGHAND
    or      rdi, 0x02000000       ; CLONE_THREAD
    xor     rdx, rdx              ; parent_tid = NULL
    xor     r10, r10              ; child_tid = NULL
    lea     r8, [tls2]            ; TLS pointer
    syscall

    cmp     rax, 0
    jne     main_thread           ; If not zero, we are the parent -> jump

    ; CHILD THREAD #2:
    call    thread2
    jmp     exit_all

main_thread:
    ;------------------------------------------------------------------
    ; 3) We are the main (original) thread
    ;------------------------------------------------------------------
    mov     rax, 1             ; sys_write
    mov     rdi, 1             ; stdout
    mov     rsi, msg_main
    mov     rdx, msg_main_len
    syscall

    ; Sleep 1 second so we can see the threads print
    mov     rax, 35            ; nanosleep
    push    qword 0            ; nanoseconds
    push    qword 1            ; seconds
    mov     rdi, rsp           ; pointer to timespec
    xor     rsi, rsi           ; no remaining time
    syscall
    add     rsp, 16            ; pop timespec

exit_all:
    ; Exit everything
    mov     rax, 60            ; sys_exit
    xor     rdi, rdi           ; status = 0
    syscall
